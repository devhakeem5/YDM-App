import 'package:get/get.dart';
import 'package:ydm/data/models/download_task.dart';
import 'package:ydm/data/services/download_manager.dart';
import 'package:ydm/data/services/download_worker.dart';

class DownloadsController extends GetxController {
  late DownloadManager _downloadManager;

  final RxInt currentTabIndex = 0.obs;

  List<DownloadTask> get tasks => _downloadManager.tasks;
  Map<String, DownloadProgress> get progressMap => _downloadManager.progressMap;

  @override
  void onInit() {
    super.onInit();
    _downloadManager = Get.find<DownloadManager>();
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
