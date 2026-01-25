import 'package:get/get.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:ydm/core/utils/logger.dart';
import 'package:ydm/data/models/download_task.dart';
import 'package:ydm/data/services/download_manager.dart';
import 'package:ydm/data/services/download_worker.dart';
import 'package:ydm/data/services/youtube_service.dart';
import 'package:ydm/modules/browser/widgets/quality_selection_dialog.dart';

class DownloadsController extends GetxController {
  late DownloadManager _downloadManager;
  late YouTubeService _youTubeService;

  final RxInt currentTabIndex = 0.obs;

  List<DownloadTask> get tasks => _downloadManager.tasks;
  Map<String, DownloadProgress> get progressMap => _downloadManager.progressMap;

  @override
  void onInit() {
    super.onInit();
    _downloadManager = Get.put(DownloadManager());
    _youTubeService = Get.put(YouTubeService()); // Ensure it's available
    _initShareIntent();
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
    if (_youTubeService.isYouTubeUrl(text)) {
      final info = await _youTubeService.getVideoInfo(text);
      if (info != null) {
        Get.dialog(
          QualitySelectionDialog(
            video: info.video,
            streams: info.streams,
            onConfirm: (streamInfo, isAudio) {
              if (isAudio) {
                final audioStream = _youTubeService.getBestAudioStream(info.manifest);
                if (audioStream != null) {
                  final streamUrl = audioStream.url.toString();
                  final filename = '${info.video.title} [Audio].mp3'.replaceAll(
                    RegExp(r'[\\/:*?"<>|]'),
                    '_',
                  );
                  _startNewDownload(streamUrl, filename);
                }
              } else {
                final streamUrl = streamInfo.url.toString();
                // Simpler label for shared
                final filename = '${info.video.title}.mp4'.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
                _startNewDownload(streamUrl, filename);
              }
            },
          ),
        );
      }
    } else {
      _startNewDownload(text, 'Shared_Download_${DateTime.now().millisecondsSinceEpoch}');
    }
  }

  void _startNewDownload(String url, String filename) {
    _downloadManager.addDownload(url, filename);
    Get.snackbar("Download Started", filename, snackPosition: SnackPosition.BOTTOM);
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
