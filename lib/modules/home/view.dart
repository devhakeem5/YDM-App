import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ydm/core/values/app_strings.dart';
import 'package:ydm/modules/browser/view.dart';
import 'package:ydm/modules/downloads/view.dart';
import 'package:ydm/modules/home/controller.dart';
import 'package:ydm/modules/settings/view.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Obx(
        () => IndexedStack(
          index: controller.currentIndex,
          children: const [BrowserView(), DownloadsView(), SettingsView()],
        ),
      ),
      bottomNavigationBar: Obx(
        () => NavigationBar(
          selectedIndex: controller.currentIndex,
          onDestinationSelected: controller.changeTab,
          destinations: [
            NavigationDestination(icon: const Icon(Icons.public), label: AppStrings.browser.tr),
            NavigationDestination(icon: const Icon(Icons.download), label: AppStrings.downloads.tr),
            NavigationDestination(icon: const Icon(Icons.settings), label: AppStrings.settings.tr),
          ],
        ),
      ),
    );
  }
}
