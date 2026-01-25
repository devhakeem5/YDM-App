import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:get/get.dart';
import 'package:path/path.dart' as p;
import 'package:share_plus/share_plus.dart';
import 'package:ydm/core/utils/logger.dart';
import 'package:ydm/data/models/backup_data.dart';
import 'package:ydm/data/models/download_status.dart';
import 'package:ydm/data/models/download_task.dart';
import 'package:ydm/data/services/download_manager.dart';
import 'package:ydm/data/services/settings_service.dart';
import 'package:ydm/data/services/storage_service.dart';

class ImportAnalysis {
  final List<DownloadTask> validTasks;
  final List<DownloadTask> missingFileTasks;
  final BackupData backupData;

  ImportAnalysis({
    required this.validTasks,
    required this.missingFileTasks,
    required this.backupData,
  });

  bool get hasMissingFiles => missingFileTasks.isNotEmpty;
}

class BackupService extends GetxService {
  late DownloadManager _downloadManager;
  late SettingsService _settingsService;
  late StorageService _storageService;

  @override
  void onInit() {
    super.onInit();
    _downloadManager = Get.find<DownloadManager>();
    _settingsService = Get.find<SettingsService>();
    _storageService = Get.find<StorageService>();
  }

  Future<void> exportData() async {
    try {
      final settings = {
        'maxRetries': _settingsService.maxRetries.value,
        'retryDelay': _settingsService.retryDelay.value,
        'maxConcurrentDownloads': _settingsService.maxConcurrentDownloads.value,
        'wifiOnly': _settingsService.wifiOnly.value,
        'autoResume': _settingsService.autoResume.value,
        'themeMode': _settingsService.themeMode.value.index,
        'locale': _settingsService.locale.value,
      };

      final backup = BackupData(
        version: 1,
        timestamp: DateTime.now(),
        settings: settings,
        downloads: _downloadManager.tasks.toList(),
      );

      final jsonString = json.encode(backup.toJson());
      final fileName = 'ydm_backup_${DateTime.now().millisecondsSinceEpoch}.json';
      final path = '${_storageService.appDirectory.path}/$fileName';

      final file = File(path);
      await file.writeAsString(jsonString);

      await Share.shareXFiles([XFile(path)], text: 'YDM Backup');
      LogService.info("Backup exported successfully.");
    } catch (e, stack) {
      LogService.error("Export failed", e, stack);
      Get.snackbar('Error', 'Export failed: $e');
    }
  }

  Future<ImportAnalysis?> pickAndAnalyzeBackup() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final content = await file.readAsString();
        final Map<String, dynamic> jsonMap = json.decode(content);
        final backupData = BackupData.fromJson(jsonMap);

        return _analyzeImport(backupData);
      }
    } catch (e, stack) {
      LogService.error("Import analysis failed", e, stack);
      Get.snackbar('Error', 'Invalid backup file');
    }
    return null;
  }

  ImportAnalysis _analyzeImport(BackupData data) {
    final validTasks = <DownloadTask>[];
    final missingFileTasks = <DownloadTask>[];

    for (final task in data.downloads) {
      if (task.status == DownloadStatus.completed) {
        if (File(task.savePath).existsSync()) {
          validTasks.add(task);
        } else {
          // Completed but file missing -> treat as valid (history only) or missing?
          // User request implies checking for files for RESUME.
          // Completed files missing might just be "redownload".
          // Let's treat completed-missing as missingFileTasks to warn user.
          missingFileTasks.add(task);
        }
      } else {
        // Incomplete
        final partFile = File('${task.savePath}.part');
        if (partFile.existsSync()) {
          validTasks.add(task);
        } else {
          missingFileTasks.add(task);
        }
      }
    }

    return ImportAnalysis(
      validTasks: validTasks,
      missingFileTasks: missingFileTasks,
      backupData: data,
    );
  }

  Future<void> performImport(ImportAnalysis analysis, {bool resetMissing = false}) async {
    try {
      // Restore Settings
      final s = analysis.backupData.settings;
      if (s.containsKey('maxRetries')) _settingsService.setMaxRetries(s['maxRetries']);
      if (s.containsKey('retryDelay')) _settingsService.setRetryDelay(s['retryDelay']);
      if (s.containsKey('maxConcurrentDownloads'))
        _settingsService.setMaxConcurrentDownloads(s['maxConcurrentDownloads']);
      if (s.containsKey('wifiOnly')) _settingsService.setWifiOnly(s['wifiOnly']);
      if (s.containsKey('autoResume')) _settingsService.setAutoResume(s['autoResume']);
      if (s.containsKey('themeMode'))
        _settingsService.setThemeMode(ThemeMode.values[s['themeMode']]);
      if (s.containsKey('locale')) _settingsService.setLocale(s['locale']);

      // Restore Downloads
      final tasksToImport = <DownloadTask>[];
      tasksToImport.addAll(analysis.validTasks);

      if (resetMissing) {
        for (final task in analysis.missingFileTasks) {
          tasksToImport.add(
            task.copyWith(
              status: DownloadStatus.paused,
              downloadedBytes: 0, // Reset progress
              errorMessage: 'File missing, reset to 0%',
            ),
          );
        }
      } else {
        // If user didn't want to reset, we import as is?
        // Logic says "If check fails, warn user. If continue, reset to 0".
        // So resetMissing=true is the "continue" path.
        // What if valid? valid are joined.
        // We will assume "performImport" is called when ready.
        // For missing ones, we ALWAYS reset if we import them, as per requirements.
        // Or we might skip them? Requirement: "If continue, import ... reset to 0%".
        // So yes, add them as reset.
        for (final task in analysis.missingFileTasks) {
          tasksToImport.add(
            task.copyWith(
              status: DownloadStatus.paused,
              downloadedBytes: 0,
              errorMessage: 'File missing, reset to 0%',
            ),
          );
        }
      }

      // Merge with existing? Or replace?
      // Requirement: "Importing...". Usually implies merging or replacing.
      // Let's merge by ID, overwriting existing.
      for (final task in tasksToImport) {
        // Check if path is valid on THIS device?
        // Paths might be different if user moved folder but path text in JSON is absolute?
        // JSON path: "/storage/emulated/0/YDM/file.ext"
        // On new device, base path might be same or different.
        // We should probably attempt to fix path based on current StorageService root?
        // StorageService uses `getExternalStorageDirectory`.
        // We should fix the path to match current device's YDM folder.

        final fileName = p.basename(task.savePath);
        final newPath = _storageService.getFilePath(fileName);

        final fixedTask = task.copyWith(savePath: newPath);

        final index = _downloadManager.tasks.indexWhere((t) => t.id == fixedTask.id);
        if (index != -1) {
          _downloadManager.tasks[index] = fixedTask;
        } else {
          _downloadManager.tasks.add(fixedTask);
        }
      }

      // Save
      // Trigger a save in manager (we need to access private method or just rely on manager to save later?
      // DownloadManager doesn't expose save. But we can trigger a status update or just add.
      // Actually `tasks` is RxList. modifying it triggers listeners?
      // We need to persist.
      // DownloadRepository is used by Manager.
      // We should probably add a method `importTasks` to DownloadManager to handle persistence properly.
      // For now, let's just trigger a dummy update or assume Manager auto-saves?
      // Review DownloadManager: `tasks.add` calls `_saveTasks`. `tasks[index]=` also.
      // So direct modification of RxList might NOT trigger `_saveTasks` automatically unless we use methods.
      // `DownloadManager` has `_saveTasks` called in `addDownload`, `updateLink`, etc.
      // But we are modifying the list directly here? No, we should use a method in Manager.
      // I will add `importTasks` to DownloadManager to be safe.

      Get.find<DownloadManager>().importTasks(tasksToImport);

      Get.snackbar('Success', 'Backup imported successfully');
    } catch (e, stack) {
      LogService.error("Import failed", e, stack);
      Get.snackbar('Error', 'Import execution failed: $e');
    }
  }
}
