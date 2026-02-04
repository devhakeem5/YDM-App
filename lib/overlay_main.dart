import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:ydm/core/theme/app_theme.dart';
import 'package:ydm/core/values/app_colors.dart';
import 'package:ydm/data/models/video_quality_entity.dart';
import 'package:ydm/data/services/facebook_service.dart';
import 'package:ydm/data/services/youtube_service.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

/// Overlay entry point - called when overlay window is shown
@pragma("vm:entry-point")
void overlayMain() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const OverlayApp());
}

class OverlayApp extends StatelessWidget {
  const OverlayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const OverlayQualitySheet(),
    );
  }
}

class OverlayQualitySheet extends StatefulWidget {
  const OverlayQualitySheet({super.key});

  @override
  State<OverlayQualitySheet> createState() => _OverlayQualitySheetState();
}

class _OverlayQualitySheetState extends State<OverlayQualitySheet> {
  bool _isLoading = true;
  String? _error;
  List<VideoQualityEntity> _qualities = [];
  VideoQualityEntity? _selected;
  String _videoTitle = '';
  String _sharedUrl = '';

  @override
  void initState() {
    super.initState();
    _initAndLoad();
  }

  Future<void> _initAndLoad() async {
    try {
      // Listen for shared data from main app
      FlutterOverlayWindow.overlayListener.listen((data) {
        if (data is Map) {
          _sharedUrl = data['url'] ?? '';
          _videoTitle = data['title'] ?? 'Video';
          _loadQualities();
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Error initializing overlay';
      });
    }
  }

  Future<void> _loadQualities() async {
    if (_sharedUrl.isEmpty) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final youtubeService = YouTubeService();
      final facebookService = FacebookService();

      final isYouTube = youtubeService.isYouTubeUrl(_sharedUrl);
      final isFacebook = _sharedUrl.contains('facebook.com') || _sharedUrl.contains('fb.watch');

      List<VideoQualityEntity>? qualities;

      if (isYouTube) {
        qualities = await _fetchYouTubeQualities(youtubeService, _sharedUrl);
      } else if (isFacebook) {
        final video = await facebookService.getVideoInfo(_sharedUrl);
        qualities = video?.qualities;
        _videoTitle = video?.title ?? 'Facebook Video';
      }

      if (qualities == null || qualities.isEmpty) {
        setState(() {
          _isLoading = false;
          _error = 'No qualities found';
        });
      } else {
        setState(() {
          _isLoading = false;
          _qualities = qualities!;
          final videoQualities = qualities.where((q) => !q.isAudio).toList();
          _selected = videoQualities.isNotEmpty ? videoQualities.first : qualities.first;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Error: $e';
      });
    }
  }

  Future<List<VideoQualityEntity>> _fetchYouTubeQualities(
    YouTubeService service,
    String url,
  ) async {
    final info = await service.getVideoInfo(url);
    if (info == null) return [];

    _videoTitle = info.video.title;
    final entities = <VideoQualityEntity>[];

    // Add audio
    final audio = service.getBestAudioStream(info.manifest);
    if (audio != null) {
      final size = audio.size;
      final sizeStr = size.totalMegaBytes >= 1024
          ? '${size.totalGigaBytes.toStringAsFixed(2)} GB'
          : '${size.totalMegaBytes.toStringAsFixed(1)} MB';

      entities.add(
        VideoQualityEntity(
          label: 'mp3 – 128K',
          url: audio.url.toString(),
          format: audio.container.name, // Use actual container
          isAudio: true,
          fileSize: sizeStr,
          source: VideoSource.youtube,
        ),
      );
    }

    final qualityMap = <int, VideoQualityEntity>{};

    void processStream(StreamInfo stream, {required bool isMuxed}) {
      final qualityStr = stream.qualityLabel;
      final match = RegExp(r'(\d+)').firstMatch(qualityStr);
      if (match == null) return;

      final resolution = int.tryParse(match.group(1) ?? '0') ?? 0;
      if (resolution == 0) return;

      if (qualityMap.containsKey(resolution)) {
        return;
      }

      final size = stream.size;
      final sizeStr = size.totalMegaBytes >= 1024
          ? '${size.totalGigaBytes.toStringAsFixed(2)} GB'
          : '${size.totalMegaBytes.toStringAsFixed(1)} MB';

      qualityMap[resolution] = VideoQualityEntity(
        label: '${resolution}p',
        url: stream.url.toString(),
        format: stream.container.name,
        fileSize: sizeStr,
        source: VideoSource.youtube,
      );
    }

    // 1. Process Muxed (Standard Quality - Safe from 403)
    for (var stream in info.streams.whereType<MuxedStreamInfo>()) {
      processStream(stream, isMuxed: true);
    }

    // Note: Video-Only streams (High Quality) are enabled again
    for (var stream in info.streams.whereType<VideoStreamInfo>()) {
      processStream(stream, isMuxed: false);
    }

    entities.addAll(qualityMap.values);

    entities.sort((a, b) {
      if (a.isAudio && !b.isAudio) return -1;
      if (!a.isAudio && b.isAudio) return 1;

      final resA = int.tryParse(a.label.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
      final resB = int.tryParse(b.label.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
      return resB.compareTo(resA);
    });

    return entities;
  }

  void _onConfirm() async {
    if (_selected == null) return;

    // Send selection back to main app
    await FlutterOverlayWindow.shareData({
      'action': 'download',
      'url': _selected!.url,
      'title': _videoTitle,
      'format': _selected!.format,
      'isAudio': _selected!.isAudio,
    });

    // Close overlay
    await FlutterOverlayWindow.closeOverlay();
  }

  void _onCancel() async {
    await FlutterOverlayWindow.closeOverlay();
  }

  @override
  Widget build(BuildContext context) {
    final audioQualities = _qualities.where((q) => q.isAudio).toList();
    final videoQualities = _qualities.where((q) => !q.isAudio).toList();

    return Material(
      color: Colors.transparent,
      child: SafeArea(
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceDark,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 20, spreadRadius: 5),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.download, color: AppColors.primary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _videoTitle,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),

                // Content
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: _isLoading
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(32),
                              child: CircularProgressIndicator(),
                            ),
                          )
                        : _error != null
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32),
                              child: Text(
                                _error!,
                                style: const TextStyle(color: Colors.red),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          )
                        : Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Audio Section
                              if (audioQualities.isNotEmpty) ...[
                                _buildSectionHeader('صوت', Icons.audiotrack),
                                const SizedBox(height: 8),
                                ...audioQualities.map(_buildQualityTile),
                                const SizedBox(height: 16),
                              ],

                              // Video Section
                              if (videoQualities.isNotEmpty) ...[
                                _buildSectionHeader('فيديو', Icons.videocam),
                                const SizedBox(height: 8),
                                ...videoQualities.map(_buildQualityTile),
                              ],
                            ],
                          ),
                  ),
                ),

                // Actions
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(onPressed: _onCancel, child: const Text('إلغاء')),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _selected != null ? _onConfirm : null,
                          child: const Text('تنزيل'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
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
    final isSelected = _selected == item;
    return InkWell(
      onTap: () => setState(() => _selected = item),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected ? AppColors.primary : Colors.grey,
            ),
            const SizedBox(width: 12),
            Icon(
              item.isAudio ? Icons.audiotrack : Icons.videocam,
              color: AppColors.primary,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.getDisplayLabel(),
                    style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
                  ),
                  if (item.fileSize != null)
                    Text(
                      item.fileSize!,
                      style: TextStyle(fontSize: 12, color: Colors.grey.withOpacity(0.8)),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
