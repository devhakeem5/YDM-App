import 'package:ydm/data/models/download_status.dart';

class DownloadTask {
  final String id;
  final String url;
  final String filename;
  final String savePath;
  final int totalBytes;
  final int downloadedBytes;
  final DownloadStatus status;
  final int retryCount;
  final bool supportsResume;
  final DateTime createdAt;
  final String? errorMessage;
  final int connectionCount;

  DownloadTask({
    required this.id,
    required this.url,
    required this.filename,
    required this.savePath,
    this.totalBytes = 0,
    this.downloadedBytes = 0,
    this.status = DownloadStatus.queued,
    this.retryCount = 0,
    this.supportsResume = false,
    DateTime? createdAt,
    this.errorMessage,
    this.connectionCount = 1,
  }) : createdAt = createdAt ?? DateTime.now();

  double get progress => totalBytes > 0 ? downloadedBytes / totalBytes : 0.0;

  DownloadTask copyWith({
    String? id,
    String? url,
    String? filename,
    String? savePath,
    int? totalBytes,
    int? downloadedBytes,
    DownloadStatus? status,
    int? retryCount,
    bool? supportsResume,
    DateTime? createdAt,
    String? errorMessage,
    int? connectionCount,
  }) {
    return DownloadTask(
      id: id ?? this.id,
      url: url ?? this.url,
      filename: filename ?? this.filename,
      savePath: savePath ?? this.savePath,
      totalBytes: totalBytes ?? this.totalBytes,
      downloadedBytes: downloadedBytes ?? this.downloadedBytes,
      status: status ?? this.status,
      retryCount: retryCount ?? this.retryCount,
      supportsResume: supportsResume ?? this.supportsResume,
      createdAt: createdAt ?? this.createdAt,
      errorMessage: errorMessage ?? this.errorMessage,
      connectionCount: connectionCount ?? this.connectionCount,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'url': url,
      'filename': filename,
      'savePath': savePath,
      'totalBytes': totalBytes,
      'downloadedBytes': downloadedBytes,
      'status': status.index,
      'retryCount': retryCount,
      'supportsResume': supportsResume,
      'createdAt': createdAt.toIso8601String(),
      'errorMessage': errorMessage,
      'connectionCount': connectionCount,
    };
  }

  factory DownloadTask.fromJson(Map<String, dynamic> json) {
    return DownloadTask(
      id: json['id'] as String,
      url: json['url'] as String,
      filename: json['filename'] as String,
      savePath: json['savePath'] as String,
      totalBytes: json['totalBytes'] as int? ?? 0,
      downloadedBytes: json['downloadedBytes'] as int? ?? 0,
      status: DownloadStatus.values[json['status'] as int? ?? 0],
      retryCount: json['retryCount'] as int? ?? 0,
      supportsResume: json['supportsResume'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      errorMessage: json['errorMessage'] as String?,
      connectionCount: json['connectionCount'] as int? ?? 1,
    );
  }
}
