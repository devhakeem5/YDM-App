import 'package:get/get.dart';
import 'package:ydm/modules/browser/controller.dart';

class BrowserBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<BrowserController>(() => BrowserController());
  }
}
