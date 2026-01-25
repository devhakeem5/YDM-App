import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ydm/core/utils/logger.dart';

class SettingsService extends GetxService {
  static const String _keyMaxRetries = 'max_retries';
  static const String _keyRetryDelay = 'retry_delay';
  static const String _keyMaxConcurrent = 'max_concurrent';
  static const String _keyWifiOnly = 'wifi_only';
  static const String _keyAutoResume = 'auto_resume';
  static const String _keyThemeMode = 'theme_mode';
  static const String _keyLocale = 'locale';

  // Observable settings
  final RxInt maxRetries = 5.obs;
  final RxInt retryDelay = 15.obs; // seconds
  final RxInt maxConcurrentDownloads = 3.obs;
  final RxBool wifiOnly = false.obs;
  final RxBool autoResume = true.obs;
  final Rx<ThemeMode> themeMode = ThemeMode.system.obs;
  final RxString locale = 'ar'.obs;

  late SharedPreferences _prefs;

  Future<SettingsService> init() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadSettings();
    LogService.info("SettingsService initialized.");
    return this;
  }

  Future<void> _loadSettings() async {
    maxRetries.value = _prefs.getInt(_keyMaxRetries) ?? 5;
    retryDelay.value = _prefs.getInt(_keyRetryDelay) ?? 15;
    maxConcurrentDownloads.value = _prefs.getInt(_keyMaxConcurrent) ?? 3;
    wifiOnly.value = _prefs.getBool(_keyWifiOnly) ?? false;
    autoResume.value = _prefs.getBool(_keyAutoResume) ?? true;

    final themeModeIndex = _prefs.getInt(_keyThemeMode) ?? 0;
    themeMode.value = ThemeMode.values[themeModeIndex];

    locale.value = _prefs.getString(_keyLocale) ?? 'ar';

    LogService.debug(
      "Settings loaded: retryDelay=${retryDelay.value}, maxConcurrent=${maxConcurrentDownloads.value}",
    );
  }

  Future<void> setMaxRetries(int value) async {
    maxRetries.value = value;
    await _prefs.setInt(_keyMaxRetries, value);
  }

  Future<void> setRetryDelay(int value) async {
    retryDelay.value = value;
    await _prefs.setInt(_keyRetryDelay, value);
  }

  Future<void> setMaxConcurrentDownloads(int value) async {
    maxConcurrentDownloads.value = value;
    await _prefs.setInt(_keyMaxConcurrent, value);
  }

  Future<void> setWifiOnly(bool value) async {
    wifiOnly.value = value;
    await _prefs.setBool(_keyWifiOnly, value);
  }

  Future<void> setAutoResume(bool value) async {
    autoResume.value = value;
    await _prefs.setBool(_keyAutoResume, value);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    themeMode.value = mode;
    await _prefs.setInt(_keyThemeMode, mode.index);
    Get.changeThemeMode(mode);
  }

  Future<void> setLocale(String langCode) async {
    locale.value = langCode;
    await _prefs.setString(_keyLocale, langCode);
    Get.updateLocale(Locale(langCode));
  }
}
