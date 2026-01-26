import 'package:get/get.dart';
import 'package:ydm/modules/browser/binding.dart';
import 'package:ydm/modules/browser/view.dart';
import 'package:ydm/modules/downloads/binding.dart';
import 'package:ydm/modules/downloads/view.dart';
import 'package:ydm/modules/permissions/binding.dart';
import 'package:ydm/modules/permissions/view.dart';
import 'package:ydm/modules/settings/binding.dart';
import 'package:ydm/modules/settings/view.dart';
import 'package:ydm/modules/splash/binding.dart';
import 'package:ydm/modules/splash/view.dart';
import 'package:ydm/routes/app_routes.dart';

class AppPages {
  static const initial = AppRoutes.splash;

  static final routes = [
    GetPage(name: AppRoutes.splash, page: () => const SplashView(), binding: SplashBinding()),
    GetPage(name: AppRoutes.home, page: () => const DownloadsView(), binding: DownloadsBinding()),
    GetPage(name: AppRoutes.browser, page: () => const BrowserView(), binding: BrowserBinding()),
    GetPage(
      name: AppRoutes.downloads,
      page: () => const DownloadsView(),
      binding: DownloadsBinding(),
    ),
    GetPage(name: AppRoutes.settings, page: () => const SettingsView(), binding: SettingsBinding()),
    GetPage(
      name: AppRoutes.permissions,
      page: () => const PermissionView(),
      binding: PermissionBinding(),
    ),
  ];
}
