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
          // Default selection: HD or highest video, or whatever
          // Simple logic: first one
          _selected = result.first;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Error loading qualities: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
              const Center(child: CircularProgressIndicator())
            else if (_error != null)
              Center(
                child: Text(
                  _error!,
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              )
            else
              // Quality List
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _qualities.length,
                  itemBuilder: (context, index) {
                    final item = _qualities[index];
                    return RadioListTile<VideoQualityEntity>(
                      value: item,
                      groupValue: _selected,
                      onChanged: (val) {
                        setState(() {
                          _selected = val;
                        });
                      },
                      title: Text(item.label),
                      subtitle: Text(
                        '${item.format.toUpperCase()} ${item.fileSize != null ? "• ${item.fileSize}" : ""}',
                      ),
                      secondary: Icon(
                        item.isAudio ? Icons.audiotrack : Icons.videocam,
                        color: AppColors.primary,
                      ),
                    );
                  },
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
}
