import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ydm/core/values/app_colors.dart';
import 'package:ydm/core/values/app_strings.dart';
import 'package:ydm/modules/splash/controller.dart';

class SplashView extends GetView<SplashController> {
  const SplashView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Placeholder for Logo
            Icon(Icons.download_for_offline, size: 100, color: Colors.white),
            const SizedBox(height: 20),
            Text(
              AppStrings.appName.tr,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
