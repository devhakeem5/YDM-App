import 'package:get/get.dart';
import 'package:ydm/data/services/permission_service.dart';
import 'package:ydm/routes/app_routes.dart';

class PermissionController extends GetxController {
  final PermissionService _permissionService = Get.find<PermissionService>();

  final RxBool hasStorage = false.obs;
  final RxBool hasBattery = false.obs;
  final RxBool hasNotification = false.obs;

  @override
  void onInit() {
    super.onInit();
    checkPermissions();
  }

  Future<void> checkPermissions() async {
    hasStorage.value = await _permissionService.isStorageGranted();
    hasBattery.value = await _permissionService.isBatteryOptimizationIgnored();
    hasNotification.value = await _permissionService.isNotificationGranted();

    if (hasStorage.value && hasBattery.value) {
      Get.offAllNamed(AppRoutes.home);
    }
  }

  Future<void> requestStorage() async {
    final granted = await _permissionService.requestStoragePermission();
    if (granted) await checkPermissions();
  }

  Future<void> requestBattery() async {
    final granted = await _permissionService.requestBatteryOptimization();
    if (granted) await checkPermissions();
  }

  Future<void> requestNotification() async {
    final granted = await _permissionService.requestNotificationPermission();
    if (granted) await checkPermissions();
  }
}
