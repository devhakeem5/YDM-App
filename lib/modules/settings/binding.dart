import 'package:get/get.dart';
import 'package:ydm/modules/settings/controller.dart';

class SettingsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SettingsController>(() => SettingsController());
  }
}
