import 'package:dio/dio.dart';
import 'package:html/parser.dart' as parser;
import 'package:ydm/core/utils/logger.dart';
import 'package:ydm/data/models/video_quality_entity.dart';

class FacebookVideo {
  final String title;
  final String? thumbnail;
  final List<VideoQualityEntity> qualities;

  FacebookVideo({required this.title, required this.qualities, this.thumbnail});
}

class FacebookService {
  final Dio _dio = Dio();

  // Mimic browser user agent to get full HTML
  static const String _userAgent =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36';

  Future<FacebookVideo?> getVideoInfo(String url) async {
    try {
      // Basic validation
      if (!url.contains('facebook.com') && !url.contains('fb.watch')) {
        return null;
      }

      final response = await _dio.get(
        url,
        options: Options(
          headers: {
            'User-Agent': _userAgent,
            'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
          },
        ),
      );

      if (response.statusCode != 200) {
        LogService.error("Facebook returned ${response.statusCode}");
        return null;
      }

      final document = parser.parse(response.data);

      // Extract Title
      String title = 'Facebook Video';
      var ogTitle = document.querySelector('meta[property="og:title"]');
      if (ogTitle != null) {
        title = ogTitle.attributes['content'] ?? title;
      }

      // Extract Thumbnail
      String? thumbnail;
      var ogImage = document.querySelector('meta[property="og:image"]');
      if (ogImage != null) {
        thumbnail = ogImage.attributes['content'];
      }

      // Extract Video URLs (SD/HD)
      // Facebook often puts sources in standard meta tags or inside script/JSON blocks.
      // 1. Check meta tags first (sometimes available for public videos)
      // 2. Regex search in scripts for "sd_src" or "hd_src"

      final qualities = <VideoQualityEntity>[];
      final html = response.data.toString();

      // Regex approach is often more reliable for FB's dynamic delivery
      final hdSrcMatch = RegExp(r'"hd_src":"([^"]+)"').firstMatch(html);
      final sdSrcMatch = RegExp(r'"sd_src":"([^"]+)"').firstMatch(html);

      // Also checking no-quotes variant sometimes used
      // Or looking for `playable_url_quality_hd`

      String? hdUrl = hdSrcMatch?.group(1);
      String? sdUrl = sdSrcMatch?.group(1);

      // Decode unicode escapes (e.g. \u0025)
      if (hdUrl != null) hdUrl = _decodeUrl(hdUrl);
      if (sdUrl != null) sdUrl = _decodeUrl(sdUrl);

      if (hdUrl != null) {
        qualities.add(
          VideoQualityEntity(label: 'HD', url: hdUrl, format: 'mp4', source: VideoSource.facebook),
        );
      }

      if (sdUrl != null) {
        qualities.add(
          VideoQualityEntity(label: 'SD', url: sdUrl, format: 'mp4', source: VideoSource.facebook),
        );
      }

      if (qualities.isEmpty) {
        // Fallback: look for other patterns?
        // e.g. og:video
        var ogVideo = document.querySelector('meta[property="og:video"]');
        if (ogVideo != null) {
          var secureUrl = ogVideo.attributes['content'];
          if (secureUrl != null) {
            qualities.add(
              VideoQualityEntity(
                label: 'Standard',
                url: secureUrl,
                format: 'mp4',
                source: VideoSource.facebook,
              ),
            );
          }
        }
      }

      if (qualities.isEmpty) return null;

      return FacebookVideo(title: title, thumbnail: thumbnail, qualities: qualities);
    } catch (e) {
      LogService.error("Error fetching Facebook video", e);
      return null;
    }
  }

  String _decodeUrl(String url) {
    return url.replaceAll(r'\/', '/').replaceAll(r'\u0025', '%');
  }
}
