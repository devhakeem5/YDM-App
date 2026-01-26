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

      // Use alternative clients (TV and Android) which often bypass bot detection
      var manifest = await _yt.videos.streamsClient.getManifest(
        video.id,
        ytClients: [YoutubeApiClient.tv, YoutubeApiClient.android, YoutubeApiClient.mweb],
      );

      var streams = <StreamInfo>[];
      streams.addAll(manifest.muxed);
      // Also add video-only streams for higher resolutions
      // Note: These won't have audio unless merged.
      // User said they want more qualities. I'll include them and label them correctly.
      streams.addAll(manifest.videoOnly);

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
