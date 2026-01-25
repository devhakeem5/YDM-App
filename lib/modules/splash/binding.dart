import 'package:get/get.dart';
import 'package:ydm/modules/splash/controller.dart';

class SplashBinding extends Bindings {
  @override
  void dependencies() {
    Get.put<SplashController>(SplashController());
  }
}
