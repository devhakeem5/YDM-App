import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:ydm/core/utils/logger.dart';
import 'package:ydm/core/values/app_strings.dart';
import 'package:ydm/data/models/download_status.dart';
import 'package:ydm/data/models/video_quality_entity.dart';
import 'package:ydm/data/services/download_manager.dart';
import 'package:ydm/data/services/facebook_service.dart';
import 'package:ydm/data/services/youtube_service.dart';
import 'package:ydm/modules/browser/widgets/unified_quality_dialog.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class HistoryItem {
  final String url;
  final String title;
  final DateTime visitedAt;

  HistoryItem({required this.url, required this.title, required this.visitedAt});

  Map<String, dynamic> toJson() => {
    'url': url,
    'title': title,
    'visitedAt': visitedAt.toIso8601String(),
  };

  factory HistoryItem.fromJson(Map<String, dynamic> json) => HistoryItem(
    url: json['url'],
    title: json['title'] ?? '',
    visitedAt: DateTime.parse(json['visitedAt']),
  );
}

class BrowserController extends GetxController {
  late WebViewController webViewController;
  final TextEditingController urlController = TextEditingController();
  final TextEditingController historySearchController = TextEditingController();

  final RxString currentUrl = 'https://www.google.com'.obs;
  final RxBool isLoading = true.obs;
  final RxDouble loadingProgress = 0.0.obs;
  final RxList<HistoryItem> history = <HistoryItem>[].obs;
  final RxString historyFilter = ''.obs;

  // YouTube & Facebook
  final RxBool isYouTubePage = false.obs;
  final RxBool isFacebookPage = false.obs;

  late DownloadManager _downloadManager;
  late YouTubeService _youTubeService;
  late FacebookService _facebookService;

  static const List<String> _downloadExtensions = [
    '.zip',
    '.rar',
    '.7z',
    '.tar',
    '.gz',
    '.apk',
    '.exe',
    '.msi',
    '.dmg',
    '.pdf',
    '.doc',
    '.docx',
    '.xls',
    '.xlsx',
    '.ppt',
    '.pptx',
    '.mp3',
    '.mp4',
    '.avi',
    '.mkv',
    '.mov',
    '.wmv',
    '.flv',
    '.webm',
    '.jpg',
    '.jpeg',
    '.png',
    '.gif',
    '.bmp',
    '.svg',
    '.webp',
    '.iso',
    '.img',
    '.bin',
  ];

  List<HistoryItem> get filteredHistory {
    if (historyFilter.value.isEmpty) return history;
    final filter = historyFilter.value.toLowerCase();
    return history
        .where(
          (h) => h.url.toLowerCase().contains(filter) || h.title.toLowerCase().contains(filter),
        )
        .toList();
  }

  @override
  void onInit() {
    super.onInit();
    _downloadManager = Get.find<DownloadManager>();
    _youTubeService = Get.find<YouTubeService>();
    _facebookService = Get.find<FacebookService>();
    _loadHistory();

    // Check for shared URL
    final sharedUrl = Get.parameters['url'];
    if (sharedUrl != null && sharedUrl.isNotEmpty) {
      currentUrl.value = sharedUrl;
    }

    _initWebView();
    historySearchController.addListener(() {
      historyFilter.value = historySearchController.text;
    });
  }

  Future<void> _loadHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getString('browser_history');
      if (historyJson != null) {
        final List<dynamic> list = json.decode(historyJson);
        history.assignAll(list.map((e) => HistoryItem.fromJson(e)).toList());
      }
    } catch (e) {
      LogService.error("Failed to load history", e);
    }
  }

  Future<void> _saveHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = json.encode(history.map((h) => h.toJson()).toList());
      await prefs.setString('browser_history', historyJson);
    } catch (e) {
      LogService.error("Failed to save history", e);
    }
  }

  void _addToHistory(String url) {
    if (url.isEmpty || url == 'about:blank') return;
    history.removeWhere((h) => h.url == url);
    history.insert(0, HistoryItem(url: url, title: url, visitedAt: DateTime.now()));
    if (history.length > 100) history.removeRange(100, history.length);
    _saveHistory();
  }

  void _initWebView() {
    webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: _onNavigationRequest,
          onPageStarted: (url) {
            isLoading.value = true;
            currentUrl.value = url;
            urlController.text = url;
            _checkYouTube(url);
          },
          onPageFinished: (url) {
            isLoading.value = false;
            currentUrl.value = url;
            _addToHistory(url);
            _checkYouTube(url);
          },
          onProgress: (progress) {
            loadingProgress.value = progress / 100;
          },
        ),
      )
      ..loadRequest(Uri.parse(currentUrl.value));

    urlController.text = currentUrl.value;
  }

  void _checkYouTube(String url) {
    isYouTubePage.value = _youTubeService.isYouTubeUrl(url);
    if (!isYouTubePage.value) {
      _checkFacebook(url);
    } else {
      isFacebookPage.value = false;
    }
  }

  void _checkFacebook(String url) {
    isFacebookPage.value = url.contains('facebook.com') || url.contains('fb.watch');
  }

  // Unified Download Action
  void onVideoDownload() {
    final url = currentUrl.value;

    Get.dialog(
      UnifiedQualityDialog(
        title: 'Select Quality',
        fetchQualities: () async {
          if (isYouTubePage.value) {
            return await _fetchYouTubeQualities(url);
          } else if (isFacebookPage.value) {
            final video = await _facebookService.getVideoInfo(url);
            return video?.qualities;
          }
          return null;
        },
        onConfirm: (selection) {
          _startNewDownload(selection.url, _generateFilenameFromSelection(selection));
        },
      ),
    );
  }

  String? _currentYouTubeTitle;

  Future<List<VideoQualityEntity>> _fetchYouTubeQualities(String url) async {
    final info = await _youTubeService.getVideoInfo(url);
    if (info == null) return [];

    _currentYouTubeTitle = info.video.title;
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
          format: audio.container.name, // Use actual container to prevent download failure
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

      // Prefer muxed streams if already exists, otherwise add if new
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
    final title = _currentYouTubeTitle ?? 'video_${DateTime.now().millisecondsSinceEpoch}';
    final quality = selection.label.replaceAll(RegExp(r'[^a-zA-Z0-9 ]'), '');
    final sanitizedTitle = title.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
    return '$sanitizedTitle ($quality).${selection.format}';
  }

  NavigationDecision _onNavigationRequest(NavigationRequest request) {
    final url = request.url.toLowerCase();
    if (_isDownloadUrl(url)) {
      LogService.info("Download URL detected: ${request.url}");
      _handleDownloadUrl(request.url);
      return NavigationDecision.prevent;
    }
    return NavigationDecision.navigate;
  }

  bool _isDownloadUrl(String url) {
    for (final ext in _downloadExtensions) {
      if (url.contains(ext)) return true;
    }
    if (url.contains('download') && (url.contains('file') || url.contains('attachment'))) {
      return true;
    }
    return false;
  }

  void _handleDownloadUrl(String url) {
    final filename = _extractFilename(url);
    final existingTask = _downloadManager.tasks.firstWhereOrNull(
      (t) => t.filename == filename && t.status != DownloadStatus.completed,
    );
    if (existingTask != null) {
      _showConflictDialog(url, filename, existingTask.id);
    } else {
      _startNewDownload(url, filename);
    }
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

  void _showConflictDialog(String url, String filename, String existingTaskId) {
    Get.dialog(
      AlertDialog(
        title: Text(AppStrings.downloadDetected.tr),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(filename, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(AppStrings.fileExistsIncomplete.tr),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Get.back();
              _startNewDownload(url, _generateUniqueFilename(filename));
            },
            child: Text(AppStrings.newDownload.tr),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              _updateExistingDownload(existingTaskId, url);
            },
            child: Text(AppStrings.updateLink.tr),
          ),
        ],
      ),
    );
  }

  String _generateUniqueFilename(String filename) {
    final dotIndex = filename.lastIndexOf('.');
    if (dotIndex > 0) {
      return '${filename.substring(0, dotIndex)}_${DateTime.now().millisecondsSinceEpoch}${filename.substring(dotIndex)}';
    }
    return '${filename}_${DateTime.now().millisecondsSinceEpoch}';
  }

  void _startNewDownload(String url, String filename) {
    _downloadManager.addDownload(url, filename);
    Get.snackbar(AppStrings.downloadStarted.tr, filename, snackPosition: SnackPosition.BOTTOM);
  }

  void _updateExistingDownload(String taskId, String newUrl) {
    _downloadManager.updateLink(taskId, newUrl);
    Get.snackbar(
      AppStrings.updateLink.tr,
      AppStrings.resume.tr,
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void handleInput(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return;
    if (_isUrl(trimmed)) {
      goToUrl(trimmed);
    } else {
      final searchUrl = 'https://www.google.com/search?q=${Uri.encodeComponent(trimmed)}';
      goToUrl(searchUrl);
    }
  }

  bool _isUrl(String input) {
    if (input.startsWith('http://') || input.startsWith('https://')) return true;
    if (input.contains('.') && !input.contains(' ')) return true;
    return false;
  }

  void goToUrl(String url) {
    String formatted = url.trim();
    if (!formatted.startsWith('http://') && !formatted.startsWith('https://')) {
      formatted = 'https://$formatted';
    }
    urlController.text = formatted;
    webViewController.loadRequest(Uri.parse(formatted));
  }

  void goBack() => webViewController.goBack();
  void goForward() => webViewController.goForward();
  void reload() => webViewController.reload();

  void loadFromHistory(HistoryItem item) {
    goToUrl(item.url);
    Get.back();
  }

  void clearHistory() {
    history.clear();
    _saveHistory();
  }

  @override
  void onClose() {
    urlController.dispose();
    historySearchController.dispose();
    super.onClose();
  }
}
