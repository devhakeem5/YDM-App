import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ydm/core/values/app_colors.dart';
import 'package:ydm/core/values/app_strings.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class QualitySelectionDialog extends StatefulWidget {
  final Video video;
  final List<StreamInfo> streams;
  final Function(StreamInfo stream, bool isAudio) onConfirm;

  const QualitySelectionDialog({
    super.key,
    required this.video,
    required this.streams,
    required this.onConfirm,
  });

  @override
  State<QualitySelectionDialog> createState() => _QualitySelectionDialogState();
}

class _QualitySelectionDialogState extends State<QualitySelectionDialog> {
  StreamInfo? _selectedStream;
  bool _isAudioSelected = false;

  @override
  void initState() {
    super.initState();
    // Default to video if available, best quality
    if (widget.streams.isNotEmpty) {
      _selectedStream = widget.streams.withHighestBitrate();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Separate streams
    final videoStreams = widget.streams.whereType<MuxedStreamInfo>().toList();
    // Sort videos by quality descending
    videoStreams.sort((a, b) => b.videoQuality.index.compareTo(a.videoQuality.index));

    return AlertDialog(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(AppStrings.selectQuality.tr),
          const SizedBox(height: 8),
          Text(
            widget.video.title,
            style: Theme.of(context).textTheme.bodySmall,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView(
          shrinkWrap: true,
          children: [
            // Video Section
            if (videoStreams.isNotEmpty) ...[
              Text(
                AppStrings.videoQuality.tr,
                style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
              ),
              const SizedBox(height: 8),
              ...videoStreams.map(
                (stream) => RadioListTile<StreamInfo>(
                  value: stream,
                  groupValue: _isAudioSelected ? null : _selectedStream,
                  onChanged: (val) {
                    setState(() {
                      _selectedStream = val;
                      _isAudioSelected = false;
                    });
                  },
                  title: Text(stream.videoQuality.qualityString),
                  subtitle: Text(
                    '${stream.container.name.toUpperCase()} • ${_formatSize(stream.size)}',
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Audio Section
            Text(
              AppStrings.audioQuality.tr,
              style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
            ),
            const SizedBox(height: 8),
            RadioListTile<bool>(
              value: true,
              groupValue: _isAudioSelected ? true : null,
              onChanged: (val) {
                // For audio, we usually pick the best audio stream or convert whatever we have.
                // Requirement: "mp3 - 128K".
                // youtube_explode gives us audio streams.
                // We will pass a flag or a specific stream for audio.
                // Here just selecting "Audio Mode".
                setState(() {
                  _isAudioSelected = true;
                  _selectedStream = null; // Will be handled by logic
                });
              },
              title: Text(AppStrings.audioOnly.tr),
              subtitle: const Text('MP3 • 128 kbps'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Get.back(), child: Text(AppStrings.cancel.tr)),
        ElevatedButton(
          onPressed: (_selectedStream != null || _isAudioSelected)
              ? () {
                  // If audio selected, we might pass a 'dummy' or specific stream logic
                  // Ideally we pass back the selection to the caller.
                  // If Video: pass stream. If Audio: pass null stream + isAudio=true?
                  // Caller needs stream/url.
                  // For audio valid stream is needed for youtube_explode to download?
                  // Or we download video and convert? YoutubeExplode has audioOnly streams.
                  // We should probably select an audio stream here if audio is selected.

                  StreamInfo? streamToPass = _selectedStream;
                  if (_isAudioSelected) {
                    // We don't have audio streams in the list passed to dialog?
                    // Plan said "Muxed streams (video opt)".
                    // We should fetch audio stream or use video stream to extract?
                    // YoutubeExplode has `manifest.audioOnly`.
                    // The caller should handle "Get best audio" if isAudio is true.
                  }

                  Get.back();
                  widget.onConfirm(streamToPass ?? widget.streams.first, _isAudioSelected);
                }
              : null,
          child: Text(AppStrings.continueText.tr),
        ),
      ],
    );
  }

  String _formatSize(FileSize size) {
    if (size.totalBytes <= 0) return AppStrings.unknownSize.tr;
    if (size.totalMegaBytes >= 1024) {
      return '${size.totalGigaBytes.toStringAsFixed(2)} GB';
    }
    return '${size.totalMegaBytes.toStringAsFixed(1)} MB';
  }
}
