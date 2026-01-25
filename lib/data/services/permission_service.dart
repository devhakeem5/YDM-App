import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:ydm/core/utils/logger.dart';

class PermissionService extends GetxService {
  Future<bool> requestStoragePermission() async {
    LogService.info("Requesting Storage Permission...");

    if (!Platform.isAndroid) {
      LogService.warning("Not Android platform, skipping permission request.");
      return true;
    }

    final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    final AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
    final int sdkInt = androidInfo.version.sdkInt;

    LogService.debug("Android SDK Version: $sdkInt");

    if (sdkInt >= 30) {
      // Android 11+
      var status = await Permission.manageExternalStorage.status;
      if (status.isGranted) {
        LogService.info("Manage External Storage Permission already granted.");
        return true;
      }

      LogService.info("Requesting Manage External Storage Permission...");
      status = await Permission.manageExternalStorage.request();

      if (status.isGranted) {
        LogService.info("Manage External Storage Permission granted.");
        return true;
      } else {
        LogService.error("Manage External Storage Permission denied.");
        return false;
      }
    } else {
      // Android 10 and below
      var status = await Permission.storage.status;
      if (status.isGranted) {
        LogService.info("Storage Permission already granted.");
        return true;
      }

      LogService.info("Requesting Storage Permission...");
      status = await Permission.storage.request();

      if (status.isGranted) {
        LogService.info("Storage Permission granted.");
        return true;
      } else {
        LogService.error("Storage Permission denied.");
        return false;
      }
    }
  }
}
