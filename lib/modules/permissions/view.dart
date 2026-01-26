import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ydm/core/values/app_strings.dart';
import 'package:ydm/modules/permissions/controller.dart';

class PermissionView extends GetView<PermissionController> {
  const PermissionView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.permissionsRequired.tr), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'To work correctly, YDM needs the following permissions. Please grant them one by one:'
                  .tr,
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 30),
            Expanded(
              child: Obx(
                () => ListView(
                  children: [
                    _buildPermissionCard(
                      title: AppStrings.storageAccess.tr,
                      description: AppStrings.storageDesc.tr,
                      icon: Icons.storage,
                      isGranted: controller.hasStorage.value,
                      onPressed: controller.requestStorage,
                    ),
                    const SizedBox(height: 16),
                    _buildPermissionCard(
                      title: AppStrings.batteryOptimization.tr,
                      description: AppStrings.batteryDesc.tr,
                      icon: Icons.battery_charging_full,
                      isGranted: controller.hasBattery.value,
                      onPressed: controller.requestBattery,
                    ),
                    const SizedBox(height: 16),
                    _buildPermissionCard(
                      title: AppStrings.notifications.tr,
                      description: 'To show you the progress of your downloads.'.tr,
                      icon: Icons.notifications,
                      isGranted: controller.hasNotification.value,
                      onPressed: controller.requestNotification,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionCard({
    required String title,
    required String description,
    required IconData icon,
    required bool isGranted,
    required VoidCallback onPressed,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isGranted ? Colors.green.withOpacity(0.5) : Colors.orange.withOpacity(0.5),
        ),
      ),
      color: isGranted ? Colors.green.withOpacity(0.05) : Colors.orange.withOpacity(0.05),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: isGranted ? Colors.green : Colors.orange,
              child: Icon(icon, color: Colors.white),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text(description, style: TextStyle(fontSize: 14, color: Colors.grey[700])),
                ],
              ),
            ),
            const SizedBox(width: 8),
            isGranted
                ? const Icon(Icons.check_circle, color: Colors.green)
                : ElevatedButton(
                    onPressed: onPressed,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Grant'),
                  ),
          ],
        ),
      ),
    );
  }
}
