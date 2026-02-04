import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:ydm/core/utils/logger.dart';

class PermissionService extends GetxService {
  Future<bool> checkAllPermissions() async {
    final storage = await isStorageGranted();
    final battery = await isBatteryOptimizationIgnored();
    return storage && battery;
  }

  Future<bool> isStorageGranted() async {
    if (!Platform.isAndroid) return true;
    final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    final AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
    final int sdkInt = androidInfo.version.sdkInt;

    if (sdkInt >= 30) {
      return await Permission.manageExternalStorage.isGranted;
    } else {
      return await Permission.storage.isGranted;
    }
  }

  Future<bool> isBatteryOptimizationIgnored() async {
    if (!Platform.isAndroid) return true;
    return await Permission.ignoreBatteryOptimizations.isGranted;
  }

  Future<bool> isNotificationGranted() async {
    if (!Platform.isAndroid) return true;
    return await Permission.notification.isGranted;
  }

  Future<void> openSettings() async {
    await openAppSettings();
  }

  Future<bool> requestStoragePermission() async {
    LogService.info("Requesting Storage Permission...");

    if (!Platform.isAndroid) return true;

    final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    final AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
    final int sdkInt = androidInfo.version.sdkInt;

    if (sdkInt >= 30) {
      final status = await Permission.manageExternalStorage.request();
      return status.isGranted;
    } else {
      final status = await Permission.storage.request();
      return status.isGranted;
    }
  }

  Future<bool> requestBatteryOptimization() async {
    if (!Platform.isAndroid) return true;
    final status = await Permission.ignoreBatteryOptimizations.request();
    return status.isGranted;
  }

  Future<bool> requestNotificationPermission() async {
    if (!Platform.isAndroid) return true;
    final status = await Permission.notification.request();
    return status.isGranted;
  }

  Future<bool> isOverlayGranted() async {
    if (!Platform.isAndroid) return true;
    return await Permission.systemAlertWindow.isGranted;
  }

  Future<bool> requestOverlayPermission() async {
    if (!Platform.isAndroid) return true;
    final status = await Permission.systemAlertWindow.request();
    return status.isGranted;
  }
}
