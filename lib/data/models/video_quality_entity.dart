import 'package:get/get.dart';
import 'package:ydm/core/values/app_strings.dart';

enum VideoSource { youtube, facebook, other }

class VideoQualityEntity {
  final String label;
  final String url;
  final String? fileSize;
  final bool isAudio;
  final String format;
  final VideoSource source;

  const VideoQualityEntity({
    required this.label,
    required this.url,
    this.fileSize,
    this.isAudio = false,
    this.format = 'mp4',
    this.source = VideoSource.other,
  });

  /// Get quality classification for YouTube videos based on resolution
  String getQualityClassification() {
    if (source != VideoSource.youtube || isAudio) return label;

    // Extract resolution number from label (e.g., "720p" -> 720)
    final match = RegExp(r'(\d+)p').firstMatch(label);
    if (match == null) return label;

    final resolution = int.tryParse(match.group(1) ?? '0') ?? 0;

    String classification;
    if (resolution <= 240) {
      classification = AppStrings.qualityLow.tr;
    } else if (resolution <= 360) {
      classification = AppStrings.qualityGood.tr;
    } else if (resolution <= 480) {
      classification = AppStrings.qualityHigh.tr;
    } else {
      classification = AppStrings.qualityVeryHigh.tr;
    }

    return '$classification $label';
  }

  /// Get display label based on source
  String getDisplayLabel() {
    if (source == VideoSource.youtube && !isAudio) {
      return getQualityClassification();
    }
    return label;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is VideoQualityEntity &&
        other.url == url &&
        other.label == label &&
        other.format == format;
  }

  @override
  int get hashCode => url.hashCode ^ label.hashCode ^ format.hashCode;

  @override
  String toString() => '$label ($format) ${fileSize ?? ''}';
}
