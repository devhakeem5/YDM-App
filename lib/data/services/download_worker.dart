import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:ydm/core/utils/logger.dart';
import 'package:ydm/data/models/download_status.dart';
import 'package:ydm/data/models/download_task.dart';

class DownloadProgress {
  final String taskId;
  final int downloadedBytes;
  final int totalBytes;
  final double speed;

  DownloadProgress({
    required this.taskId,
    required this.downloadedBytes,
    required this.totalBytes,
    this.speed = 0,
  });

  double get progress => totalBytes > 0 ? downloadedBytes / totalBytes : 0;
}

class DownloadResult {
  final String taskId;
  final DownloadStatus status;
  final String? errorMessage;
  final int downloadedBytes;
  final bool supportsResume;

  DownloadResult({
    required this.taskId,
    required this.status,
    this.errorMessage,
    this.downloadedBytes = 0,
    this.supportsResume = false,
  });
}

class DownloadWorker {
  final Dio _dio;
  CancelToken? _cancelToken;
  bool _isPaused = false;
  bool _isCancelled = false;

  DownloadWorker()
    : _dio = Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(minutes: 30),
        ),
      );

  Future<DownloadResult> download({
    required DownloadTask task,
    required Function(DownloadProgress) onProgress,
  }) async {
    _cancelToken = CancelToken();
    _isPaused = false;
    _isCancelled = false;

    final filePath = task.savePath;
    final partFilePath = '$filePath.part';

    try {
      // Check if server supports resume
      final headResponse = await _dio.head(task.url);
      final acceptRanges = headResponse.headers.value('accept-ranges');
      final supportsResume = acceptRanges != null && acceptRanges.toLowerCase() == 'bytes';
      final contentLength = int.tryParse(headResponse.headers.value('content-length') ?? '0') ?? 0;

      LogService.info(
        "Download starting: ${task.filename}, Size: $contentLength, Resume: $supportsResume",
      );

      // Check existing file for resume
      int existingBytes = 0;
      final partFile = File(partFilePath);
      if (await partFile.exists() && supportsResume) {
        existingBytes = await partFile.length();
        LogService.info("Resuming from byte: $existingBytes");
      }

      if (existingBytes >= contentLength && contentLength > 0) {
        // File already complete
        await _finalizeDownload(partFilePath, filePath);
        return DownloadResult(
          taskId: task.id,
          status: DownloadStatus.completed,
          downloadedBytes: contentLength,
          supportsResume: supportsResume,
        );
      }

      // Prepare request options
      final options = Options(
        responseType: ResponseType.stream,
        headers: supportsResume && existingBytes > 0 ? {'Range': 'bytes=$existingBytes-'} : null,
      );

      final response = await _dio.get<ResponseBody>(
        task.url,
        options: options,
        cancelToken: _cancelToken,
      );

      if (response.statusCode == 401 || response.statusCode == 403 || response.statusCode == 410) {
        LogService.warning("Link expired or unauthorized: ${task.url}");
        return DownloadResult(
          taskId: task.id,
          status: DownloadStatus.needsLinkUpdate,
          errorMessage: 'Link expired or unauthorized',
          downloadedBytes: existingBytes,
          supportsResume: supportsResume,
        );
      }

      final file = File(partFilePath);
      final sink = file.openWrite(mode: existingBytes > 0 ? FileMode.append : FileMode.write);

      int received = existingBytes;
      DateTime lastProgressUpdate = DateTime.now();
      int lastBytes = received;

      try {
        await for (final chunk in response.data!.stream) {
          if (_isCancelled) {
            await sink.close();
            return DownloadResult(
              taskId: task.id,
              status: DownloadStatus.paused,
              downloadedBytes: received,
              supportsResume: supportsResume,
            );
          }

          if (_isPaused) {
            await sink.close();
            return DownloadResult(
              taskId: task.id,
              status: DownloadStatus.paused,
              downloadedBytes: received,
              supportsResume: supportsResume,
            );
          }

          sink.add(chunk);
          received += chunk.length;

          // Calculate speed and report progress
          final now = DateTime.now();
          final elapsed = now.difference(lastProgressUpdate).inMilliseconds;
          if (elapsed >= 500) {
            final speed = (received - lastBytes) / (elapsed / 1000);
            onProgress(
              DownloadProgress(
                taskId: task.id,
                downloadedBytes: received,
                totalBytes: contentLength,
                speed: speed,
              ),
            );
            lastProgressUpdate = now;
            lastBytes = received;
          }
        }
      } finally {
        await sink.close();
      }

      // Finalize download
      await _finalizeDownload(partFilePath, filePath);

      LogService.info("Download completed: ${task.filename}");
      return DownloadResult(
        taskId: task.id,
        status: DownloadStatus.completed,
        downloadedBytes: received,
        supportsResume: supportsResume,
      );
    } on DioException catch (e) {
      LogService.error("Download error: ${e.type}", e);

      if (e.type == DioExceptionType.cancel) {
        return DownloadResult(
          taskId: task.id,
          status: DownloadStatus.paused,
          downloadedBytes: task.downloadedBytes,
          supportsResume: task.supportsResume,
        );
      }

      if (e.response?.statusCode == 401 ||
          e.response?.statusCode == 403 ||
          e.response?.statusCode == 410) {
        return DownloadResult(
          taskId: task.id,
          status: DownloadStatus.needsLinkUpdate,
          errorMessage: 'Link expired',
          downloadedBytes: task.downloadedBytes,
          supportsResume: task.supportsResume,
        );
      }

      return DownloadResult(
        taskId: task.id,
        status: DownloadStatus.failed,
        errorMessage: e.message,
        downloadedBytes: task.downloadedBytes,
        supportsResume: task.supportsResume,
      );
    } catch (e, stackTrace) {
      LogService.error("Download failed unexpectedly", e, stackTrace);
      return DownloadResult(
        taskId: task.id,
        status: DownloadStatus.failed,
        errorMessage: e.toString(),
        downloadedBytes: task.downloadedBytes,
        supportsResume: task.supportsResume,
      );
    }
  }

  Future<void> _finalizeDownload(String partPath, String finalPath) async {
    final partFile = File(partPath);
    if (await partFile.exists()) {
      await partFile.rename(finalPath);
      LogService.info("File finalized: $finalPath");
    }
  }

  void pause() {
    _isPaused = true;
    _cancelToken?.cancel('Paused by user');
  }

  void cancel() {
    _isCancelled = true;
    _cancelToken?.cancel('Cancelled by user');
  }
}
