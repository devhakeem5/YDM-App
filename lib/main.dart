import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ydm/core/theme/app_theme.dart';
import 'package:ydm/core/translations/app_translations.dart';
import 'package:ydm/core/utils/logger.dart';
import 'package:ydm/data/services/download_manager.dart';
import 'package:ydm/data/services/facebook_service.dart';
import 'package:ydm/data/services/network_service.dart';
import 'package:ydm/data/services/notification_service.dart';
import 'package:ydm/data/services/permission_service.dart';
import 'package:ydm/data/services/settings_service.dart';
import 'package:ydm/data/services/storage_service.dart';
import 'package:ydm/data/services/youtube_service.dart';
import 'package:ydm/routes/app_pages.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  LogService.info("YDM Application Starting...");

  // Initialize Services
  Get.put<PermissionService>(PermissionService());
  Get.put<NetworkService>(NetworkService());
  await Get.putAsync<StorageService>(() async => await StorageService().init());
  await Get.putAsync<NotificationService>(() async => await NotificationService().init());
  await Get.putAsync<SettingsService>(() async => await SettingsService().init());
  Get.put<DownloadManager>(DownloadManager());
  Get.put<YouTubeService>(YouTubeService());
  Get.put<FacebookService>(FacebookService());

  LogService.info("Services Initialized.");

  runApp(const YdmApp());
}

class YdmApp extends StatelessWidget {
  const YdmApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'YDM',
      debugShowCheckedModeBanner: false,

      // Theme
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,

      // Localization
      translations: AppTranslations(),
      locale: const Locale('ar', 'SA'), // Default Arabic
      fallbackLocale: const Locale('en', 'US'),

      // Navigation
      initialRoute: AppPages.initial,
      getPages: AppPages.routes,
      defaultTransition: Transition.cupertino,
    );
  }
}
