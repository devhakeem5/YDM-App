import 'package:get/get.dart';
import 'package:ydm/modules/browser/controller.dart';
import 'package:ydm/modules/downloads/controller.dart';
import 'package:ydm/modules/home/controller.dart';
import 'package:ydm/modules/settings/controller.dart';

class HomeBinding extends Bindings {
  @override
  void dependencies() {
    Get.put<HomeController>(HomeController());
    Get.lazyPut<BrowserController>(() => BrowserController());
    Get.lazyPut<DownloadsController>(() => DownloadsController());
    Get.lazyPut<SettingsController>(() => SettingsController());
  }
}
