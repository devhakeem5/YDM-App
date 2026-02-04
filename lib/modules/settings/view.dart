import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ydm/core/values/app_colors.dart';
import 'package:ydm/core/values/app_strings.dart';
import 'package:ydm/data/services/backup_service.dart';
import 'package:ydm/data/services/settings_service.dart';
import 'package:ydm/modules/settings/controller.dart';

class SettingsView extends GetView<SettingsController> {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsService = Get.put(SettingsService());
    final SettingsController _s  = Get.put(SettingsController());
    final backupService = Get.put(
      BackupService(),
    ); // Lazy put usually, but here we invoke it. Use Get.find if put in binding.
    // Actually BackupService is not yet bound in main, so Get.put here or bind in main.
    // Plan said "Implement BackupService". Controller could wrap it or we just use it here.
    // Better to use Get.find if we bind it globally or just put it in Controller.
    // Let's assume we bind it in main.dart as per habits.

    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.settings.tr)),
      body: Obx(
        () => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Download Settings
            _buildSectionHeader(context, AppStrings.downloadSettings.tr),
            _buildDropdownTile(
              context,
              title: AppStrings.maxRetries.tr,
              value: settingsService.maxRetries.value,
              items: [3, 5, 10, 15],
              onChanged: (v) => controller.setMaxRetries(v!),
            ),
            _buildDropdownTile(
              context,
              title: AppStrings.retryInterval.tr,
              value: settingsService.retryDelay.value,
              items: [5, 10, 15, 30, 60],
              suffix: AppStrings.seconds.tr,
              onChanged: (v) => controller.setRetryDelay(v!),
            ),
            const SizedBox(height: 16),

            // Connection Settings
            _buildSectionHeader(context, AppStrings.connectionSettings.tr),
            _buildDropdownTile(
              context,
              title: AppStrings.maxConnections.tr,
              value: settingsService.maxConcurrentDownloads.value,
              items: [1, 2, 3, 5, 8],
              onChanged: (v) => controller.setMaxConcurrentDownloads(v!),
            ),
            const SizedBox(height: 16),

            // Behavior Settings
            _buildSectionHeader(context, AppStrings.behaviorSettings.tr),
            _buildSwitchTile(
              context,
              title: AppStrings.wifiOnly.tr,
              value: settingsService.wifiOnly.value,
              onChanged: controller.setWifiOnly,
            ),
            _buildSwitchTile(
              context,
              title: AppStrings.autoResumeOnNetwork.tr,
              value: settingsService.autoResume.value,
              onChanged: controller.setAutoResume,
            ),
            const SizedBox(height: 16),

            // Backup & Restore
            _buildSectionHeader(context, AppStrings.backupRestore.tr),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.upload_file),
                    title: Text(AppStrings.exportData.tr),
                    subtitle: Text(AppStrings.exportDesc.tr),
                    onTap: () => backupService.exportData(),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.download),
                    title: Text(AppStrings.importData.tr),
                    subtitle: Text(AppStrings.importDesc.tr),
                    onTap: () async {
                      final analysis = await backupService.pickAndAnalyzeBackup();
                      if (analysis != null) {
                        if (analysis.hasMissingFiles) {
                          _showMissingFilesDialog(context, backupService, analysis);
                        } else {
                          backupService.performImport(analysis);
                        }
                      }
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // UI Settings
            _buildSectionHeader(context, AppStrings.uiSettings.tr),
            _buildThemeTile(context, settingsService),
            _buildLanguageTile(context, settingsService),
          ],
        ),
      ),
    );
  }

  void _showMissingFilesDialog(
    BuildContext context,
    BackupService service,
    ImportAnalysis analysis,
  ) {
    Get.dialog(
      AlertDialog(
        title: Text(AppStrings.warning.tr), // Needs translation
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppStrings.missingFilesWarning.tr),
            const SizedBox(height: 8),
            Text(
              '${analysis.missingFileTasks.length} ${AppStrings.filesMissing.tr}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(AppStrings.missingFilesAction.tr),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: Text(AppStrings.cancel.tr)),
          ElevatedButton(
            onPressed: () {
              Get.back();
              service.performImport(analysis, resetMissing: true);
            },
            child: Text(AppStrings.continueText.tr),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildDropdownTile<T>(
    BuildContext context, {
    required String title,
    required T value,
    required List<T> items,
    required ValueChanged<T?> onChanged,
    String? suffix,
  }) {
    return Card(
      child: ListTile(
        title: Text(title),
        trailing: DropdownButton<T>(
          value: value,
          underline: const SizedBox(),
          items: items
              .map(
                (item) => DropdownMenuItem<T>(
                  value: item,
                  child: Text(suffix != null ? '$item $suffix' : '$item'),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildSwitchTile(
    BuildContext context, {
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Card(
      child: SwitchListTile(
        title: Text(title),
        value: value,
        onChanged: onChanged,
        activeThumbColor: AppColors.primary,
      ),
    );
  }

  Widget _buildThemeTile(BuildContext context, SettingsService settings) {
    return Card(
      child: ListTile(
        title: Text(AppStrings.theme.tr),
        trailing: DropdownButton<ThemeMode>(
          value: settings.themeMode.value,
          underline: const SizedBox(),
          items: [
            DropdownMenuItem(value: ThemeMode.system, child: Text(AppStrings.systemMode.tr)),
            DropdownMenuItem(value: ThemeMode.light, child: Text(AppStrings.lightMode.tr)),
            DropdownMenuItem(value: ThemeMode.dark, child: Text(AppStrings.darkMode.tr)),
          ],
          onChanged: (mode) => controller.setThemeMode(mode!),
        ),
      ),
    );
  }

  Widget _buildLanguageTile(BuildContext context, SettingsService settings) {
    return Card(
      child: ListTile(
        title: Text(AppStrings.language.tr),
        trailing: DropdownButton<String>(
          value: settings.locale.value,
          underline: const SizedBox(),
          items: [
            DropdownMenuItem(value: 'ar', child: Text(AppStrings.arabic.tr)),
            DropdownMenuItem(value: 'en', child: Text(AppStrings.english.tr)),
          ],
          onChanged: (lang) => controller.setLocale(lang!),
        ),
      ),
    );
  }
}
