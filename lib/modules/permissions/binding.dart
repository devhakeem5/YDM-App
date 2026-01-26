import 'package:get/get.dart';
import 'package:ydm/modules/permissions/controller.dart';

class PermissionBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<PermissionController>(() => PermissionController());
  }
}
