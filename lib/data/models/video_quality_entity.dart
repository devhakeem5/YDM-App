class VideoQualityEntity {
  final String label;
  final String url;
  final String? fileSize;
  final bool isAudio;
  final String format;

  const VideoQualityEntity({
    required this.label,
    required this.url,
    this.fileSize,
    this.isAudio = false,
    this.format = 'mp4',
  });

  @override
  String toString() => '$label ($format) ${fileSize ?? ''}';
}
