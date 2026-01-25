import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import 'package:ydm/core/utils/logger.dart';
import 'package:ydm/data/models/download_status.dart';
import 'package:ydm/data/models/download_task.dart';
import 'package:ydm/data/repositories/download_repository.dart';
import 'package:ydm/data/services/download_worker.dart';
import 'package:ydm/data/services/network_service.dart';
import 'package:ydm/data/services/settings_service.dart';
import 'package:ydm/data/services/storage_service.dart';

class DownloadManager extends GetxService {
  final DownloadRepository _repository = DownloadRepository();
  final Map<String, DownloadWorker> _activeWorkers = {};
  final Map<String, Timer> _retryTimers = {};

  final RxList<DownloadTask> tasks = <DownloadTask>[].obs;
  final RxMap<String, DownloadProgress> progressMap = <String, DownloadProgress>{}.obs;

  late NetworkService _networkService;
  late StorageService _storageService;
  late SettingsService _settingsService;

  int get maxConcurrentDownloads => _settingsService.maxConcurrentDownloads.value;
  int get maxRetryCount => _settingsService.maxRetries.value;
  Duration get retryDelay => Duration(seconds: _settingsService.retryDelay.value);

  @override
  void onInit() {
    super.onInit();
    _networkService = Get.find<NetworkService>();
    _storageService = Get.find<StorageService>();
    _settingsService = Get.find<SettingsService>();
    _loadTasks();
    _listenToNetworkChanges();
  }

  Future<void> _loadTasks() async {
    final loadedTasks = await _repository.loadAll();
    tasks.assignAll(loadedTasks);
    LogService.info("Loaded ${tasks.length} tasks from storage.");

    // Auto-resume downloads that were in progress
    for (final task in tasks) {
      if (task.status == DownloadStatus.downloading ||
          task.status == DownloadStatus.waitingForRetry) {
        _updateTaskStatus(task.id, DownloadStatus.queued);
      }
    }
    _processQueue();
  }

  void _listenToNetworkChanges() {
    ever(_networkService.connectionStatus, (ConnectivityResult status) {
      if (status == ConnectivityResult.none) {
        LogService.warning("Network lost. Pausing all active downloads.");
        _pauseAllForNetwork();
      } else {
        LogService.info("Network restored. Resuming waiting downloads.");
        _resumeNetworkWaiting();
      }
    });
  }

  void _pauseAllForNetwork() {
    for (final task in tasks.where((t) => t.status == DownloadStatus.downloading)) {
      _activeWorkers[task.id]?.pause();
      _updateTaskStatus(task.id, DownloadStatus.waitingForNetwork);
    }
  }

  void _resumeNetworkWaiting() {
    for (final task in tasks.where((t) => t.status == DownloadStatus.waitingForNetwork)) {
      _updateTaskStatus(task.id, DownloadStatus.queued);
    }
    _processQueue();
  }

  Future<String> addDownload(String url, String filename) async {
    final id = const Uuid().v4();
    final savePath = _storageService.getFilePath(filename);

    final task = DownloadTask(
      id: id,
      url: url,
      filename: filename,
      savePath: savePath,
      status: DownloadStatus.queued,
    );

    tasks.add(task);
    await _saveTasks();
    LogService.info("Added download: $filename ($id)");

    _processQueue();
    return id;
  }

  void pauseDownload(String id) {
    final worker = _activeWorkers[id];
    if (worker != null) {
      worker.pause();
      _activeWorkers.remove(id);
    }
    _updateTaskStatus(id, DownloadStatus.paused);
    _cancelRetryTimer(id);
    LogService.info("Paused download: $id");
  }

  void resumeDownload(String id) {
    final task = tasks.firstWhereOrNull((t) => t.id == id);
    if (task != null && task.status.canResume) {
      _updateTaskStatus(id, DownloadStatus.queued);
      _processQueue();
      LogService.info("Resumed download: $id");
    }
  }

  void cancelDownload(String id, {bool deleteFile = false}) {
    final worker = _activeWorkers[id];
    if (worker != null) {
      worker.cancel();
      _activeWorkers.remove(id);
    }
    _cancelRetryTimer(id);

    final task = tasks.firstWhereOrNull((t) => t.id == id);
    if (task != null && deleteFile) {
      _storageService.deleteIncompleteFile(task.filename);
      _storageService.deleteFile(task.savePath);
    }

    tasks.removeWhere((t) => t.id == id);
    progressMap.remove(id);
    _saveTasks();
    LogService.info("Cancelled download: $id");
    _processQueue();
  }

  void updateLink(String id, String newUrl) {
    final index = tasks.indexWhere((t) => t.id == id);
    if (index != -1) {
      tasks[index] = tasks[index].copyWith(
        url: newUrl,
        status: DownloadStatus.queued,
        retryCount: 0,
        errorMessage: null,
      );
      _saveTasks();
      _processQueue();
      LogService.info("Updated link for download: $id");
    }
  }

  void _processQueue() {
    if (!_networkService.isConnected) {
      LogService.debug("No network, skipping queue processing.");
      return;
    }

    final activeCount = tasks.where((t) => t.status == DownloadStatus.downloading).length;
    final availableSlots = maxConcurrentDownloads - activeCount;

    if (availableSlots <= 0) return;

    final queuedTasks = tasks.where((t) => t.status == DownloadStatus.queued).take(availableSlots);

    for (final task in queuedTasks) {
      _startDownload(task);
    }
  }

  Future<void> _startDownload(DownloadTask task) async {
    _updateTaskStatus(task.id, DownloadStatus.downloading);

    final worker = DownloadWorker();
    _activeWorkers[task.id] = worker;

    final result = await worker.download(
      task: task,
      onProgress: (progress) {
        progressMap[task.id] = progress;
        _updateTaskProgress(task.id, progress.downloadedBytes, progress.totalBytes);
      },
    );

    _activeWorkers.remove(task.id);

    final updatedTask = tasks.firstWhereOrNull((t) => t.id == task.id);
    if (updatedTask == null) return; // Task was cancelled

    final newTask = updatedTask.copyWith(
      status: result.status,
      downloadedBytes: result.downloadedBytes,
      supportsResume: result.supportsResume,
      errorMessage: result.errorMessage,
    );

    _updateTask(newTask);

    if (result.status == DownloadStatus.failed && newTask.retryCount < maxRetryCount) {
      _scheduleRetry(newTask);
    } else if (result.status == DownloadStatus.completed) {
      progressMap.remove(task.id);
    }

    _processQueue();
  }

  void _scheduleRetry(DownloadTask task) {
    _updateTaskStatus(task.id, DownloadStatus.waitingForRetry);

    _retryTimers[task.id] = Timer(retryDelay, () {
      final currentTask = tasks.firstWhereOrNull((t) => t.id == task.id);
      if (currentTask != null && currentTask.status == DownloadStatus.waitingForRetry) {
        final updated = currentTask.copyWith(retryCount: currentTask.retryCount + 1);
        _updateTask(updated);
        _updateTaskStatus(task.id, DownloadStatus.queued);
        _processQueue();
      }
    });

    LogService.info("Scheduled retry for ${task.id} in ${retryDelay.inSeconds}s");
  }

  void _cancelRetryTimer(String id) {
    _retryTimers[id]?.cancel();
    _retryTimers.remove(id);
  }

  void _updateTaskStatus(String id, DownloadStatus status) {
    final index = tasks.indexWhere((t) => t.id == id);
    if (index != -1) {
      tasks[index] = tasks[index].copyWith(status: status);
      _saveTasks();
    }
  }

  void _updateTaskProgress(String id, int downloadedBytes, int totalBytes) {
    final index = tasks.indexWhere((t) => t.id == id);
    if (index != -1) {
      tasks[index] = tasks[index].copyWith(
        downloadedBytes: downloadedBytes,
        totalBytes: totalBytes,
      );
    }
  }

  void _updateTask(DownloadTask task) {
    final index = tasks.indexWhere((t) => t.id == task.id);
    if (index != -1) {
      tasks[index] = task;
      _saveTasks();
    }
  }

  Future<void> _saveTasks() async {
    await _repository.saveAll(tasks.toList());
  }

  Future<void> importTasks(List<DownloadTask> newTasks) async {
    for (final task in newTasks) {
      final index = tasks.indexWhere((t) => t.id == task.id);
      if (index != -1) {
        tasks[index] = task;
      } else {
        tasks.add(task);
      }
    }
    await _saveTasks();
    _processQueue();
    LogService.info("Imported ${newTasks.length} tasks.");
  }

  @override
  void onClose() {
    for (final timer in _retryTimers.values) {
      timer.cancel();
    }
    for (final worker in _activeWorkers.values) {
      worker.cancel();
    }
    super.onClose();
  }
}
