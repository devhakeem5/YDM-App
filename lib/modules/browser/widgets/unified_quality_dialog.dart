import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ydm/core/values/app_colors.dart';
import 'package:ydm/core/values/app_strings.dart';
import 'package:ydm/data/models/video_quality_entity.dart';

class UnifiedQualityDialog extends StatefulWidget {
  final String title;
  final Future<List<VideoQualityEntity>?> Function() fetchQualities;
  final Function(VideoQualityEntity selection) onConfirm;

  const UnifiedQualityDialog({
    super.key,
    required this.title,
    required this.fetchQualities,
    required this.onConfirm,
  });

  @override
  State<UnifiedQualityDialog> createState() => _UnifiedQualityDialogState();
}

class _UnifiedQualityDialogState extends State<UnifiedQualityDialog> {
  bool _isLoading = true;
  String? _error;
  List<VideoQualityEntity> _qualities = [];
  VideoQualityEntity? _selected;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await widget.fetchQualities();
      if (result == null || result.isEmpty) {
        setState(() {
          _isLoading = false;
          _error = 'No qualities found or content is not downloadable.';
        });
      } else {
        setState(() {
          _isLoading = false;
          _qualities = result;
          // Default selection: first video quality, or first available
          final videoQualities = result.where((q) => !q.isAudio).toList();
          _selected = videoQualities.isNotEmpty ? videoQualities.first : result.first;
        });
      }
    } catch (e) {
      await Future.delayed(const Duration(seconds: 1));

      try {
        setState(() {
          _isLoading = false;
          _error = 'Error loading qualities: $e';
        });
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    // Separate audio and video qualities
    final audioQualities = _qualities.where((q) => q.isAudio).toList();
    final videoQualities = _qualities.where((q) => !q.isAudio).toList();

    return AlertDialog(
      title: Text(AppStrings.selectQuality.tr),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.title,
              style: Theme.of(context).textTheme.bodySmall,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            if (_isLoading)
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 8),
                    Text(AppStrings.analyzing.tr),
                  ],
                ),
              )
            else if (_error != null)
              Center(
                child: Text(
                  _error!,
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              )
            else
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    // Audio Section
                    if (audioQualities.isNotEmpty) ...[
                      _buildSectionHeader(AppStrings.audioQuality.tr, Icons.audiotrack),
                      const SizedBox(height: 8),
                      ...audioQualities.map((item) => _buildQualityTile(item)),
                      const SizedBox(height: 16),
                    ],

                    // Video Section
                    if (videoQualities.isNotEmpty) ...[
                      _buildSectionHeader(AppStrings.videoQuality.tr, Icons.videocam),
                      const SizedBox(height: 8),
                      ...videoQualities.map((item) => _buildQualityTile(item)),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Get.back(), child: Text(AppStrings.cancel.tr)),
        if (!_isLoading && _error == null)
          ElevatedButton(
            onPressed: () {
              if (_selected != null) {
                Get.back();
                widget.onConfirm(_selected!);
              }
            },
            child: Text(AppStrings.continueText.tr),
          ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildQualityTile(VideoQualityEntity item) {
    return RadioListTile<VideoQualityEntity>(
      value: item,
      groupValue: _selected,
      onChanged: (val) {
        setState(() {
          _selected = val;
        });
      },
      title: Text(item.getDisplayLabel()),
      subtitle: item.fileSize != null ? Text(item.fileSize!) : null,
      secondary: Icon(item.isAudio ? Icons.audiotrack : Icons.videocam, color: AppColors.primary),
    );
  }
}
