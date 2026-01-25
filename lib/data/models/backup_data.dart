import 'package:ydm/data/models/download_task.dart';

class BackupData {
  final int version;
  final DateTime timestamp;
  final Map<String, dynamic> settings;
  final List<DownloadTask> downloads;

  BackupData({
    required this.version,
    required this.timestamp,
    required this.settings,
    required this.downloads,
  });

  Map<String, dynamic> toJson() => {
    'version': version,
    'timestamp': timestamp.toIso8601String(),
    'settings': settings,
    'downloads': downloads.map((e) => e.toJson()).toList(),
  };

  factory BackupData.fromJson(Map<String, dynamic> json) => BackupData(
    version: json['version'] as int,
    timestamp: DateTime.parse(json['timestamp'] as String),
    settings: json['settings'] as Map<String, dynamic>,
    downloads: (json['downloads'] as List).map((e) => DownloadTask.fromJson(e)).toList(),
  );
}
