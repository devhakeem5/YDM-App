import 'package:get/get.dart';
import 'package:ydm/core/utils/logger.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class VideoInfo {
  final Video video;
  final List<StreamInfo> streams;
  final StreamManifest manifest;

  VideoInfo(this.video, this.streams, this.manifest);
}

class YouTubeService extends GetxService {
  final _yt = YoutubeExplode();

  /// Check if url is a valid YouTube URL
  bool isYouTubeUrl(String url) {
    // Check main domains
    if (url.contains('youtube.com') || url.contains('youtu.be')) {
      return true;
    }
    return false;
  }

  /// Get video metadata and available streams
  Future<VideoInfo?> getVideoInfo(String url) async {
    try {
      var video = await _yt.videos.get(url);
      var manifest = await _yt.videos.streamsClient.getManifest(video.id);

      // Collect video streams (muxed or video-only that we can merge?
      // Requirement says: "Video qualities 240p...".
      // Muxed streams usually go up to 720p.
      // Adaptive streams go higher (1080p, 4k) but are video-only requiring merging with audio.
      // Current requirement: "Use current download core".
      // Our core downloads a single URL. Combining video+audio needs ffmpeg or logic.
      // Restriction: "No complex background downloads outside current core".
      // Implication: We might be limited to Muxed streams (up to 720p) OR
      // we implement a simple merge if we can download both?
      // "Download core" downloads a file.
      // To support 1080p, we'd need to download two files and merge them (requiring ffmpeg_kit or similar).
      // Constraint: "No export/import... No complex features".
      // Let's stick to Muxed streams for simplicity first (up to 720p).
      // If higher quality is needed (adaptive), we would list them but can we download them?
      // For this plan, let's expose Muxed streams + Audio-only.

      var streams = <StreamInfo>[];
      streams.addAll(manifest.muxed);
      // streams.addAll(manifest.audioOnly); // We handle audio separately in dialog logic

      // If we want 1080p, we need to handle adaptive.
      // For now, let's return Muxed for video options.

      return VideoInfo(video, streams, manifest);
    } catch (e) {
      LogService.error("Error getting YouTube info", e);
      return null;
    }
  }

  /// Get audio stream info (highest bitrate mp3/m4a)
  AudioOnlyStreamInfo? getBestAudioStream(StreamManifest manifest) {
    try {
      var audio = manifest.audioOnly.withHighestBitrate();
      return audio;
    } catch (e) {
      return null;
    }
  }

  /// Get stream URL for standard download
  Future<String?> getStreamUrl(StreamInfo streamInfo) async {
    // The URL in StreamInfo is valid for a short time.
    // We can just use it directly.
    return streamInfo.url.toString();
  }

  @override
  void onClose() {
    _yt.close();
    super.onClose();
  }
}
