import 'package:get/get.dart';
import 'package:ydm/data/services/permission_service.dart';
import 'package:ydm/routes/app_routes.dart';

class SplashController extends GetxController {
  final _permissionService = Get.find<PermissionService>();

  @override
  void onReady() {
    super.onReady();
    _init();
  }

  Future<void> _init() async {
    await Future.delayed(const Duration(seconds: 2));

    final hasPermissions = await _permissionService.checkAllPermissions();
    if (hasPermissions) {
      Get.offNamed(AppRoutes.home);
    } else {
      Get.offNamed(AppRoutes.permissions);
    }
  }
}
