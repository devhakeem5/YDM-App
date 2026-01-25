import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:ydm/core/utils/logger.dart';
import 'package:ydm/data/models/download_task.dart';

class DownloadRepository {
  static const String _storageKey = 'download_tasks';

  Future<List<DownloadTask>> loadAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_storageKey);

      if (jsonString == null || jsonString.isEmpty) {
        return [];
      }

      final List<dynamic> jsonList = json.decode(jsonString);
      final tasks = jsonList
          .map((item) => DownloadTask.fromJson(item as Map<String, dynamic>))
          .toList();

      LogService.info("Loaded ${tasks.length} download tasks from storage.");
      return tasks;
    } catch (e, stackTrace) {
      LogService.error("Failed to load download tasks", e, stackTrace);
      return [];
    }
  }

  Future<bool> saveAll(List<DownloadTask> tasks) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = tasks.map((task) => task.toJson()).toList();
      final jsonString = json.encode(jsonList);

      await prefs.setString(_storageKey, jsonString);
      LogService.debug("Saved ${tasks.length} download tasks to storage.");
      return true;
    } catch (e, stackTrace) {
      LogService.error("Failed to save download tasks", e, stackTrace);
      return false;
    }
  }

  Future<bool> update(DownloadTask task, List<DownloadTask> allTasks) async {
    final index = allTasks.indexWhere((t) => t.id == task.id);
    if (index != -1) {
      allTasks[index] = task;
    } else {
      allTasks.add(task);
    }
    return await saveAll(allTasks);
  }

  Future<bool> delete(String id, List<DownloadTask> allTasks) async {
    allTasks.removeWhere((t) => t.id == id);
    return await saveAll(allTasks);
  }
}
