import 'package:get/get.dart';
import 'package:ydm/modules/downloads/controller.dart';

class DownloadsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<DownloadsController>(() => DownloadsController());
  }
}
