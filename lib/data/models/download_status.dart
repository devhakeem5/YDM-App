enum DownloadStatus {
  queued,
  downloading,
  paused,
  failed,
  waitingForNetwork,
  waitingForRetry,
  needsLinkUpdate,
  completed,
}

extension DownloadStatusExtension on DownloadStatus {
  String get displayName {
    switch (this) {
      case DownloadStatus.queued:
        return 'Queued';
      case DownloadStatus.downloading:
        return 'Downloading';
      case DownloadStatus.paused:
        return 'Paused';
      case DownloadStatus.failed:
        return 'Failed';
      case DownloadStatus.waitingForNetwork:
        return 'Waiting for Network';
      case DownloadStatus.waitingForRetry:
        return 'Waiting to Retry';
      case DownloadStatus.needsLinkUpdate:
        return 'Link Expired';
      case DownloadStatus.completed:
        return 'Completed';
    }
  }

  bool get isActive => this == DownloadStatus.downloading;
  bool get canResume =>
      this == DownloadStatus.paused ||
      this == DownloadStatus.failed ||
      this == DownloadStatus.waitingForNetwork ||
      this == DownloadStatus.waitingForRetry;
  bool get canPause => this == DownloadStatus.downloading || this == DownloadStatus.queued;
}
