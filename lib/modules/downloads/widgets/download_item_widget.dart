import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ydm/core/values/app_colors.dart';
import 'package:ydm/core/values/app_strings.dart';
import 'package:ydm/data/models/download_status.dart';
import 'package:ydm/data/models/download_task.dart';
import 'package:ydm/data/services/download_worker.dart';

class DownloadItemWidget extends StatelessWidget {
  final DownloadTask task;
  final DownloadProgress? progress;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onCancel;
  final VoidCallback onRetry;
  final VoidCallback? onUpdateLink;

  const DownloadItemWidget({
    super.key,
    required this.task,
    this.progress,
    required this.onPause,
    required this.onResume,
    required this.onCancel,
    required this.onRetry,
    this.onUpdateLink,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Filename and status
            Row(
              children: [
                Expanded(
                  child: Text(
                    task.filename,
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                _buildStatusChip(context),
              ],
            ),
            const SizedBox(height: 12),

            // Progress bar
            if (task.status == DownloadStatus.downloading ||
                task.status == DownloadStatus.paused ||
                task.status == DownloadStatus.queued)
              Column(
                children: [
                  LinearProgressIndicator(
                    value: task.progress,
                    backgroundColor: isDark ? Colors.grey[800] : Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      task.status == DownloadStatus.paused ? Colors.orange : AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),

            // Progress info
            Row(
              children: [
                Text(_formatBytes(task.downloadedBytes), style: theme.textTheme.bodySmall),
                if (task.totalBytes > 0) ...[
                  Text(' / ', style: theme.textTheme.bodySmall),
                  Text(_formatBytes(task.totalBytes), style: theme.textTheme.bodySmall),
                ],
                const Spacer(),
                if (progress != null && task.status == DownloadStatus.downloading)
                  Text(
                    '${_formatBytes(progress!.speed.toInt())}/s',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // Action buttons
            Row(mainAxisAlignment: MainAxisAlignment.end, children: _buildActions(context)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(BuildContext context) {
    Color color;
    String text;

    switch (task.status) {
      case DownloadStatus.queued:
        color = Colors.blue;
        text = AppStrings.queued.tr;
        break;
      case DownloadStatus.downloading:
        color = AppColors.primary;
        text = AppStrings.downloading.tr;
        break;
      case DownloadStatus.paused:
        color = Colors.orange;
        text = AppStrings.paused.tr;
        break;
      case DownloadStatus.completed:
        color = AppColors.success;
        text = AppStrings.completed.tr;
        break;
      case DownloadStatus.failed:
        color = AppColors.error;
        text = AppStrings.failed.tr;
        break;
      case DownloadStatus.waitingForNetwork:
        color = Colors.orange;
        text = AppStrings.waitingNetwork.tr;
        break;
      case DownloadStatus.waitingForRetry:
        color = Colors.orange;
        text = AppStrings.waitingRetry.tr;
        break;
      case DownloadStatus.needsLinkUpdate:
        color = AppColors.warning;
        text = AppStrings.linkExpired.tr;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Color.fromRGBO(color.r.toInt(), color.g.toInt(), color.b.toInt(), 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Color.fromRGBO(color.r.toInt(), color.g.toInt(), color.b.toInt(), 0.5),
        ),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }

  List<Widget> _buildActions(BuildContext context) {
    final actions = <Widget>[];

    if (task.status.canPause) {
      actions.add(
        IconButton(icon: const Icon(Icons.pause), onPressed: onPause, tooltip: AppStrings.pause.tr),
      );
    }

    if (task.status.canResume) {
      actions.add(
        IconButton(
          icon: const Icon(Icons.play_arrow),
          onPressed: onResume,
          tooltip: AppStrings.resume.tr,
        ),
      );
    }

    if (task.status == DownloadStatus.failed) {
      actions.add(
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: onRetry,
          tooltip: AppStrings.retry.tr,
        ),
      );
    }

    if (task.status == DownloadStatus.needsLinkUpdate && onUpdateLink != null) {
      actions.add(
        TextButton.icon(
          icon: const Icon(Icons.link),
          label: Text(AppStrings.updateLink.tr),
          onPressed: onUpdateLink,
        ),
      );
    }

    if (task.status != DownloadStatus.completed) {
      actions.add(
        IconButton(
          icon: const Icon(Icons.close),
          onPressed: onCancel,
          tooltip: AppStrings.cancel.tr,
          color: AppColors.error,
        ),
      );
    }

    return actions;
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }
}
