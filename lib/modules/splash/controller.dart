import 'package:get/get.dart';
import 'package:ydm/routes/app_routes.dart';

class SplashController extends GetxController {
  @override
  void onReady() {
    super.onReady();
    Future.delayed(const Duration(seconds: 2), () {
      Get.offNamed(AppRoutes.downloads);
    });
  }
}
