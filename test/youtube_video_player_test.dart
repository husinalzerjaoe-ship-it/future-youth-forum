import 'package:flutter_test/flutter_test.dart';
import 'package:future_youth_forum/youtube_video_player.dart';

void main() {
  group('youtubeEmbedUrl', () {
    test('converts a standard watch URL', () {
      expect(
        youtubeEmbedUrl('https://www.youtube.com/watch?v=abcdefghijk'),
        'https://www.youtube-nocookie.com/embed/abcdefghijk?playsinline=1&rel=0',
      );
    });

    test('converts a short youtu.be URL', () {
      expect(
        youtubeEmbedUrl('https://youtu.be/abcdefghijk?t=12'),
        'https://www.youtube-nocookie.com/embed/abcdefghijk?playsinline=1&rel=0',
      );
    });

    test('converts Shorts and live URLs', () {
      expect(youtubeEmbedUrl('https://youtube.com/shorts/abcdefghijk'),
          contains('/embed/abcdefghijk?'));
      expect(youtubeEmbedUrl('https://youtube.com/live/abcdefghijk'),
          contains('/embed/abcdefghijk?'));
    });

    test('preserves valid playlist URLs for the external fallback path', () {
      expect(
        youtubeEmbedUrl('https://www.youtube.com/playlist?list=PL1234567890'),
        contains('/embed/videoseries?list=PL1234567890'),
      );
    });

    test('rejects non-YouTube hosts and insecure URLs', () {
      expect(youtubeEmbedUrl('https://example.com/watch?v=abcdefghijk'), isNull);
      expect(youtubeEmbedUrl('http://youtube.com/watch?v=abcdefghijk'), isNull);
      expect(youtubeEmbedUrl('https://youtube.com/watch?v=short'), isNull);
    });

    test('accepts supported YouTube links only', () {
      expect(isSupportedYoutubeUrl('https://youtu.be/abcdefghijk'), isTrue);
      expect(isSupportedYoutubeUrl('https://example.com/abcdefghijk'), isFalse);
    });
  });
}
