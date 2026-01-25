import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ydm/core/values/app_strings.dart';
import 'package:ydm/modules/downloads/controller.dart';
import 'package:ydm/modules/downloads/widgets/download_item_widget.dart';
import 'package:ydm/modules/settings/view.dart';
import 'package:ydm/routes/app_routes.dart';

class DownloadsView extends GetView<DownloadsController> {
  const DownloadsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final currentIndex = controller.currentTabIndex.value;

      return Scaffold(
        appBar: AppBar(
          title: Text(currentIndex == 0 ? AppStrings.downloads.tr : AppStrings.settings.tr),
          actions: currentIndex == 0
              ? [
                  IconButton(
                    icon: const Icon(Icons.public),
                    tooltip: AppStrings.browser.tr,
                    onPressed: () => Get.toNamed(AppRoutes.browser),
                  ),
                ]
              : null,
        ),
        body: IndexedStack(
          index: currentIndex,
          children: [_buildDownloadsList(context), const SettingsView()],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: currentIndex,
          onDestinationSelected: controller.changeTab,
          destinations: [
            NavigationDestination(icon: const Icon(Icons.download), label: AppStrings.downloads.tr),
            NavigationDestination(icon: const Icon(Icons.settings), label: AppStrings.settings.tr),
          ],
        ),
      );
    });
  }

  Widget _buildDownloadsList(BuildContext context) {
    return Obx(() {
      final tasks = controller.tasks;

      if (tasks.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.download_outlined, size: 80, color: Theme.of(context).colorScheme.outline),
              const SizedBox(height: 16),
              Text(
                AppStrings.noDownloads.tr,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(color: Theme.of(context).colorScheme.outline),
              ),
            ],
          ),
        );
      }

      return ListView.builder(
        itemCount: tasks.length,
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemBuilder: (context, index) {
          final task = tasks[index];
          final progress = controller.progressMap[task.id];

          return DownloadItemWidget(
            task: task,
            progress: progress,
            onPause: () => controller.pauseDownload(task.id),
            onResume: () => controller.resumeDownload(task.id),
            onCancel: () => _showCancelDialog(context, task.id),
            onRetry: () => controller.retryDownload(task.id),
            onUpdateLink: null,
          );
        },
      );
    });
  }

  void _showCancelDialog(BuildContext context, String taskId) {
    Get.dialog(
      AlertDialog(
        title: Text(AppStrings.cancel.tr),
        content: const Text('Are you sure you want to cancel this download?'),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('No')),
          TextButton(
            onPressed: () {
              controller.cancelDownload(taskId);
              Get.back();
            },
            child: Text(AppStrings.cancel.tr, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
