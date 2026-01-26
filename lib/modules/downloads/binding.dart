import 'package:get/get.dart';
import 'package:ydm/modules/downloads/controller.dart';
import 'package:ydm/modules/settings/controller.dart';

class DownloadsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<DownloadsController>(() => DownloadsController());
    Get.lazyPut<SettingsController>(() => SettingsController());
  }
}
