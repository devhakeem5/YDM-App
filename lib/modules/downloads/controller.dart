import 'package:flutter/services.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:get/get.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:ydm/core/utils/logger.dart';
import 'package:ydm/core/values/app_strings.dart';
import 'package:ydm/data/models/download_task.dart';
import 'package:ydm/data/models/video_quality_entity.dart';
import 'package:ydm/data/services/download_manager.dart';
import 'package:ydm/data/services/download_worker.dart';
import 'package:ydm/data/services/facebook_service.dart';
import 'package:ydm/data/services/permission_service.dart';
import 'package:ydm/data/services/youtube_service.dart';
import 'package:ydm/modules/browser/widgets/unified_quality_dialog.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class DownloadsController extends GetxController {
  late DownloadManager _downloadManager;
  late YouTubeService _youTubeService;
  late FacebookService _facebookService;
  late PermissionService _permissionService;

  final RxInt currentTabIndex = 0.obs;

  List<DownloadTask> get tasks => _downloadManager.tasks;
  Map<String, DownloadProgress> get progressMap => _downloadManager.progressMap;

  String? _currentVideoTitle;

  @override
  void onInit() {
    super.onInit();
    _downloadManager = Get.find<DownloadManager>();
    _youTubeService = Get.find<YouTubeService>();
    _facebookService = Get.find<FacebookService>();
    _permissionService = Get.find<PermissionService>();
    _initShareIntent();
    _listenToOverlayData();
  }

  void _initShareIntent() {
    // For shared content while running (text)
    ReceiveSharingIntent.instance.getMediaStream().listen(
      (List<SharedMediaFile> value) {
        if (value.isNotEmpty) _processSharedFiles(value);
      },
      onError: (err) {
        LogService.error("getMediaStream error: $err");
      },
    );

    // For shared content when starting (text)
    ReceiveSharingIntent.instance.getInitialMedia().then((List<SharedMediaFile> value) {
      if (value.isNotEmpty) _processSharedFiles(value);
    });
  }

  void _listenToOverlayData() {
    // Listen for download requests from overlay
    FlutterOverlayWindow.overlayListener.listen((data) {
      if (data is Map && data['action'] == 'download') {
        final url = data['url'] as String?;
        final title = data['title'] as String? ?? 'video';
        final format = data['format'] as String? ?? 'mp4';
        final isAudio = data['isAudio'] as bool? ?? false;

        if (url != null && url.isNotEmpty) {
          final sanitizedTitle = title.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
          final filename = '$sanitizedTitle.${isAudio ? 'mp3' : format}';
          _startNewDownload(url, filename);
        }
      }
    });
  }

  void _processSharedFiles(List<SharedMediaFile> files) {
    for (final file in files) {
      // Prioritize text sharing
      if (file.type == SharedMediaType.text) {
        _handleSharedText(file.path);
        return;
      }
      // Also check if path looks like URL even if type is not strictly text
      if (file.path.startsWith('http://') || file.path.startsWith('https://')) {
        _handleSharedText(file.path);
        return;
      }
    }
  }

  void _handleSharedText(String text) async {
    LogService.info("Received shared text: $text");
    if (text.isEmpty) return;

    final url = text.trim();

    // Check if URL is supported
    final isYouTube = _youTubeService.isYouTubeUrl(url);
    final isFacebook = url.contains('facebook.com') || url.contains('fb.watch');

    if (isYouTube || isFacebook) {
      // Try to show overlay first
      final hasOverlayPermission = await _permissionService.isOverlayGranted();

      if (hasOverlayPermission) {
        // Show overlay window
        await _showOverlay(url);
      } else {
        // Fallback to in-app dialog if no overlay permission
        _showQualityDialogForUrl(url, isYouTube: isYouTube, isFacebook: isFacebook);
      }
    } else {
      // For unsupported URLs, just start direct download
      final filename = _extractFilename(url);
      _startNewDownload(url, filename);
    }
  }

  Future<void> _showOverlay(String url) async {
    try {
      // Check if overlay is already active
      final isActive = await FlutterOverlayWindow.isActive();
      if (isActive) {
        await FlutterOverlayWindow.closeOverlay();
      }

      // Show overlay window
      await FlutterOverlayWindow.showOverlay(
        enableDrag: false,
        height: 500,
        width: WindowSize.matchParent,
        alignment: OverlayAlignment.bottomCenter,
        positionGravity: PositionGravity.auto,
      );

      // Send URL data to overlay
      await Future.delayed(const Duration(milliseconds: 500));
      await FlutterOverlayWindow.shareData({'url': url, 'title': 'Loading...'});

      // Minimize app after showing overlay to keep user in YouTube context
      try {
        await const MethodChannel('flutter/platform').invokeMethod('SystemNavigator.pop');
      } catch (e) {
        LogService.error("Error minimizing app", e);
      }
    } catch (e) {
      LogService.error("Error showing overlay", e);
      // Fallback to dialog
      final isYouTube = _youTubeService.isYouTubeUrl(url);
      final isFacebook = url.contains('facebook.com') || url.contains('fb.watch');
      _showQualityDialogForUrl(url, isYouTube: isYouTube, isFacebook: isFacebook);
    }
  }

  void _showQualityDialogForUrl(String url, {required bool isYouTube, required bool isFacebook}) {
    Get.dialog(
      UnifiedQualityDialog(
        title: url,
        fetchQualities: () async {
          if (isYouTube) {
            return await _fetchYouTubeQualities(url);
          } else if (isFacebook) {
            final video = await _facebookService.getVideoInfo(url);
            _currentVideoTitle = video?.title;
            return video?.qualities;
          }
          return null;
        },
        onConfirm: (selection) {
          _startNewDownload(selection.url, _generateFilenameFromSelection(selection));
        },
      ),
      barrierDismissible: false,
    );
  }

  Future<List<VideoQualityEntity>> _fetchYouTubeQualities(String url) async {
    final info = await _youTubeService.getVideoInfo(url);
    if (info == null) return [];

    _currentVideoTitle = info.video.title;
    final entities = <VideoQualityEntity>[];

    // Add best audio
    final audio = _youTubeService.getBestAudioStream(info.manifest);
    if (audio != null) {
      final size = audio.size;
      final sizeStr = size.totalMegaBytes >= 1024
          ? '${size.totalGigaBytes.toStringAsFixed(2)} GB'
          : '${size.totalMegaBytes.toStringAsFixed(1)} MB';

      entities.add(
        VideoQualityEntity(
          label: 'mp3 – 128K',
          url: audio.url.toString(),
          format: audio.container.name, // Use actual container
          isAudio: true,
          fileSize: sizeStr,
          source: VideoSource.youtube,
        ),
      );
    }

    final qualityMap = <int, VideoQualityEntity>{};

    void processStream(StreamInfo stream, {required bool isMuxed}) {
      final qualityStr = stream.qualityLabel;
      final match = RegExp(r'(\d+)').firstMatch(qualityStr);
      if (match == null) return;

      final resolution = int.tryParse(match.group(1) ?? '0') ?? 0;
      if (resolution == 0) return;

      if (qualityMap.containsKey(resolution)) {
        return;
      }

      final size = stream.size;
      final sizeStr = size.totalMegaBytes >= 1024
          ? '${size.totalGigaBytes.toStringAsFixed(2)} GB'
          : '${size.totalMegaBytes.toStringAsFixed(1)} MB';

      qualityMap[resolution] = VideoQualityEntity(
        label: '${resolution}p',
        url: stream.url.toString(),
        format: stream.container.name,
        fileSize: sizeStr,
        source: VideoSource.youtube,
      );
    }

    // 1. Process Muxed (Standard Quality - Safe from 403)
    for (var stream in info.streams.whereType<MuxedStreamInfo>()) {
      processStream(stream, isMuxed: true);
    }

    // Note: Video-Only streams (High Quality) are enabled again
    for (var stream in info.streams.whereType<VideoStreamInfo>()) {
      processStream(stream, isMuxed: false);
    }

    entities.addAll(qualityMap.values);

    // Sort: Audio first, then by resolution descending
    entities.sort((a, b) {
      if (a.isAudio && !b.isAudio) return -1;
      if (!a.isAudio && b.isAudio) return 1;

      final resA = int.tryParse(a.label.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
      final resB = int.tryParse(b.label.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
      return resB.compareTo(resA);
    });

    return entities;
  }

  String _generateFilenameFromSelection(VideoQualityEntity selection) {
    final title = _currentVideoTitle ?? 'video_${DateTime.now().millisecondsSinceEpoch}';
    final quality = selection.label.replaceAll(RegExp(r'[^a-zA-Z0-9 ]'), '');
    final sanitizedTitle = title.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
    return '$sanitizedTitle ($quality).${selection.format}';
  }

  String _extractFilename(String url) {
    try {
      final uri = Uri.parse(url);
      if (uri.pathSegments.isNotEmpty) {
        String filename = uri.pathSegments.last;
        if (filename.contains('?')) filename = filename.split('?').first;
        return filename.isNotEmpty ? filename : 'download_${DateTime.now().millisecondsSinceEpoch}';
      }
    } catch (e) {
      LogService.error("Error extracting filename", e);
    }
    return 'download_${DateTime.now().millisecondsSinceEpoch}';
  }

  void _startNewDownload(String url, String filename) {
    _downloadManager.addDownload(url, filename);
    Get.snackbar(AppStrings.downloadStarted.tr, filename, snackPosition: SnackPosition.BOTTOM);
  }

  void changeTab(int index) {
    currentTabIndex.value = index;
  }

  void pauseDownload(String id) {
    _downloadManager.pauseDownload(id);
  }

  void resumeDownload(String id) {
    _downloadManager.resumeDownload(id);
  }

  void cancelDownload(String id) {
    _downloadManager.cancelDownload(id, deleteFile: true);
  }

  void retryDownload(String id) {
    _downloadManager.resumeDownload(id);
  }

  void updateLink(String id, String newUrl) {
    _downloadManager.updateLink(id, newUrl);
  }
}
