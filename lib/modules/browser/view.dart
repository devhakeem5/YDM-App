import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:ydm/core/values/app_colors.dart';
import 'package:ydm/core/values/app_strings.dart';
import 'package:ydm/modules/browser/controller.dart';

class BrowserView extends GetView<BrowserController> {
  const BrowserView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: SafeArea(child: _buildUrlBar(context)),
      ),
      endDrawer: _buildHistoryDrawer(context),
      body: Column(
        children: [
          // Loading indicator
          Obx(
            () => controller.isLoading.value
                ? LinearProgressIndicator(
                    value: controller.loadingProgress.value > 0
                        ? controller.loadingProgress.value
                        : null,
                    backgroundColor: Colors.grey[300],
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                  )
                : const SizedBox.shrink(),
          ),

          // WebView
          Expanded(child: WebViewWidget(controller: controller.webViewController)),
        ],
      ),
      floatingActionButton: Obx(
        () => (controller.isYouTubePage.value || controller.isFacebookPage.value)
            ? FloatingActionButton.extended(
                onPressed: controller.onVideoDownload,
                icon: const Icon(Icons.download),
                label: Text(AppStrings.downloadVideo.tr),
              )
            : const SizedBox.shrink(),
      ),
      bottomNavigationBar: _buildNavigationBar(context),
    );
  }

  Widget _buildUrlBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(15), blurRadius: 4, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          // Back button
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Get.back(),
            tooltip: 'Back to Downloads',
          ),
          // URL/Search field
          Expanded(
            child: TextField(
              controller: controller.urlController,
              decoration: InputDecoration(
                hintText: AppStrings.enterUrl.tr,
                filled: true,
                fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.arrow_forward),
                  onPressed: () => controller.handleInput(controller.urlController.text),
                ),
              ),
              keyboardType: TextInputType.url,
              textInputAction: TextInputAction.go,
              onSubmitted: controller.handleInput,
            ),
          ),
          const SizedBox(width: 4),
          // History button
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.history),
              onPressed: () => Scaffold.of(context).openEndDrawer(),
              tooltip: AppStrings.history.tr,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryDrawer(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            // Header with search
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        AppStrings.history.tr,
                        style: Theme.of(
                          context,
                        ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => _showClearHistoryDialog(context),
                        tooltip: AppStrings.clearHistory.tr,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: controller.historySearchController,
                    decoration: InputDecoration(
                      hintText: AppStrings.searchHistory.tr,
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      prefixIcon: const Icon(Icons.search, size: 20),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // History list
            Expanded(
              child: Obx(() {
                final items = controller.filteredHistory;
                if (items.isEmpty) {
                  return Center(
                    child: Text(
                      AppStrings.noHistory.tr,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                  );
                }
                return ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return ListTile(
                      leading: const Icon(Icons.language, size: 20),
                      title: Text(item.url, maxLines: 1, overflow: TextOverflow.ellipsis),
                      subtitle: Text(
                        _formatDate(item.visitedAt),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      onTap: () => controller.loadFromHistory(item),
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationBar(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(25), blurRadius: 8, offset: const Offset(0, -2)),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                onPressed: controller.goBack,
                icon: const Icon(Icons.arrow_back_ios),
                tooltip: 'Back',
              ),
              IconButton(
                onPressed: controller.goForward,
                icon: const Icon(Icons.arrow_forward_ios),
                tooltip: 'Forward',
              ),
              IconButton(
                onPressed: controller.reload,
                icon: const Icon(Icons.refresh),
                tooltip: 'Refresh',
              ),
              IconButton(
                onPressed: () => controller.goToUrl('https://www.google.com'),
                icon: const Icon(Icons.home),
                tooltip: 'Home',
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  void _showClearHistoryDialog(BuildContext context) {
    Get.dialog(
      AlertDialog(
        title: Text(AppStrings.clearHistory.tr),
        content: Text(AppStrings.clearHistoryConfirm.tr),
        actions: [
          TextButton(onPressed: () => Get.back(), child: Text(AppStrings.cancel.tr)),
          TextButton(
            onPressed: () {
              controller.clearHistory();
              Get.back();
            },
            child: Text(AppStrings.clearHistory.tr, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
