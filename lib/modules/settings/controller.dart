import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ydm/data/services/settings_service.dart';

class SettingsController extends GetxController {
  late SettingsService _settingsService;

  // Settings getters
  int get maxRetries => _settingsService.maxRetries.value;
  int get retryDelay => _settingsService.retryDelay.value;
  int get maxConcurrentDownloads => _settingsService.maxConcurrentDownloads.value;
  bool get wifiOnly => _settingsService.wifiOnly.value;
  bool get autoResume => _settingsService.autoResume.value;
  ThemeMode get themeMode => _settingsService.themeMode.value;
  String get locale => _settingsService.locale.value;

  @override
  void onInit() {
    super.onInit();
    _settingsService = Get.find<SettingsService>();
  }

  void setMaxRetries(int value) {
    _settingsService.setMaxRetries(value);
  }

  void setRetryDelay(int value) {
    _settingsService.setRetryDelay(value);
  }

  void setMaxConcurrentDownloads(int value) {
    _settingsService.setMaxConcurrentDownloads(value);
  }

  void setWifiOnly(bool value) {
    _settingsService.setWifiOnly(value);
  }

  void setAutoResume(bool value) {
    _settingsService.setAutoResume(value);
  }

  void setThemeMode(ThemeMode mode) {
    _settingsService.setThemeMode(mode);
  }

  void setLocale(String langCode) {
    _settingsService.setLocale(langCode);
  }
}
