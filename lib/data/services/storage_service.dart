import 'dart:io';

import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:ydm/core/utils/logger.dart';

class StorageService extends GetxService {
  static const String _ydmFolderName = 'YDM';
  static const String _incompleteExtension = '.part';

  Directory? _downloadDirectory;

  Directory? get downloadDirectory => _downloadDirectory;
  Directory? get _videosDir =>
      _downloadDirectory != null ? Directory('${_downloadDirectory!.path}/YDM-Videos') : null;
  Directory? get _audiosDir =>
      _downloadDirectory != null ? Directory('${_downloadDirectory!.path}/YDM-Audios') : null;
  Directory? get _docsDir =>
      _downloadDirectory != null ? Directory('${_downloadDirectory!.path}/YDM-Documents') : null;
  Directory? get _appsDir =>
      _downloadDirectory != null ? Directory('${_downloadDirectory!.path}/YDM-Apps') : null;
  Directory? get _othersDir =>
      _downloadDirectory != null ? Directory('${_downloadDirectory!.path}/YDM-Others') : null;

  Future<StorageService> init() async {
    await _initializeDownloadDirectory();
    return this;
  }

  Future<void> _initializeDownloadDirectory() async {
    try {
      Directory? baseDir;

      if (Platform.isAndroid) {
        baseDir = Directory('/storage/emulated/0');
        if (!await baseDir.exists()) {
          baseDir = await getExternalStorageDirectory();
        }
      } else {
        baseDir = await getApplicationDocumentsDirectory();
      }

      if (baseDir == null) {
        LogService.error("Could not find base storage directory.");
        return;
      }

      _downloadDirectory = Directory('${baseDir.path}/$_ydmFolderName');

      // Create main directory
      if (!await _downloadDirectory!.exists()) {
        await _downloadDirectory!.create(recursive: true);
        LogService.info("Created YDM directory at: ${_downloadDirectory!.path}");
      }

      // Create subdirectories
      await _createSubDir(_videosDir);
      await _createSubDir(_audiosDir);
      await _createSubDir(_docsDir);
      await _createSubDir(_appsDir);
      await _createSubDir(_othersDir);
    } catch (e, stackTrace) {
      LogService.error("Failed to initialize download directory", e, stackTrace);
    }
  }

  Future<void> _createSubDir(Directory? dir) async {
    if (dir != null && !await dir.exists()) {
      await dir.create(recursive: true);
    }
  }

  String getDownloadPath() {
    return _downloadDirectory?.path ?? '';
  }

  Directory _getCategoryDir(String filename) {
    final ext = filename.toLowerCase().split('.').last;

    if (['mp4', 'mkv', 'webm', 'mov', 'avi', 'flv', 'wmv'].contains(ext)) {
      return _videosDir!;
    } else if (['mp3', 'm4a', 'wav', 'aac', 'flac', 'ogg'].contains(ext)) {
      return _audiosDir!;
    } else if (['pdf', 'doc', 'docx', 'xls', 'xlsx', 'ppt', 'pptx', 'txt'].contains(ext)) {
      return _docsDir!;
    } else if (['apk', 'xapk', 'apkm'].contains(ext)) {
      return _appsDir!;
    } else {
      return _othersDir!;
    }
  }

  String getFilePath(String filename) {
    if (_downloadDirectory == null) return '';
    final dir = _getCategoryDir(filename);
    return '${dir.path}/$filename';
  }

  String getIncompleteFilePath(String filename) {
    if (_downloadDirectory == null) return '';
    // Incomplete files stay in categorised folder ? Or main?
    // Usually cleaner to keep them in separate or same.
    // Per request: "File type determines folder". So same.
    return '${getFilePath(filename)}$_incompleteExtension';
  }

  Future<bool> fileExists(String filename) async {
    try {
      final file = File(getFilePath(filename));
      return await file.exists();
    } catch (e) {
      LogService.error("Error checking file existence: $filename", e);
      return false;
    }
  }

  Future<bool> incompleteFileExists(String filename) async {
    try {
      final file = File(getIncompleteFilePath(filename));
      return await file.exists();
    } catch (e) {
      LogService.error("Error checking incomplete file existence: $filename", e);
      return false;
    }
  }

  Future<int> getFileSize(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        return await file.length();
      }
      return 0;
    } catch (e) {
      LogService.error("Error getting file size: $path", e);
      return 0;
    }
  }

  Future<File?> createFile(String filename) async {
    try {
      final file = File(getIncompleteFilePath(filename));
      await file.create(recursive: true);
      LogService.info("Created incomplete file: ${file.path}");
      return file;
    } catch (e, stackTrace) {
      LogService.error("Failed to create file: $filename", e, stackTrace);
      return null;
    }
  }

  Future<bool> completeFile(String filename) async {
    try {
      final incompletePath = getIncompleteFilePath(filename);
      final completePath = getFilePath(filename);
      final incompleteFile = File(incompletePath);

      if (await incompleteFile.exists()) {
        await incompleteFile.rename(completePath);
        LogService.info("Completed file: $completePath");
        return true;
      } else {
        LogService.warning("Incomplete file not found for completion: $incompletePath");
        return false;
      }
    } catch (e, stackTrace) {
      LogService.error("Failed to complete file: $filename", e, stackTrace);
      return false;
    }
  }

  Future<bool> deleteFile(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
        LogService.info("Deleted file: $path");
        return true;
      }
      return false;
    } catch (e, stackTrace) {
      LogService.error("Failed to delete file: $path", e, stackTrace);
      return false;
    }
  }

  Future<bool> deleteIncompleteFile(String filename) async {
    return await deleteFile(getIncompleteFilePath(filename));
  }
}
