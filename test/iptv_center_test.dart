import 'package:flutter_test/flutter_test.dart';
import 'package:future_youth_forum/iptv_center.dart';

void main() {
  group('IptvPlaylistParser', () {
    test('reads channel name, group, logo and id', () {
      const playlist = '''
#EXTM3U
#EXTINF:-1 tvg-id="iraq.one" tvg-logo="https://example.com/logo.png" group-title="العراق",قناة العراق
https://example.com/live/iraq.m3u8
''';
      final channels = IptvPlaylistParser.parse(playlist, source: 'اختبار');
      expect(channels, hasLength(1));
      expect(channels.single.name, 'قناة العراق');
      expect(channels.single.group, 'العراق');
      expect(channels.single.logo, 'https://example.com/logo.png');
      expect(channels.single.tvgId, 'iraq.one');
      expect(channels.single.source, 'اختبار');
    });

    test('resolves relative stream URLs against playlist address', () {
      const playlist = '#EXTM3U\n#EXTINF:-1,News\nstreams/news/index.m3u8';
      final channels = IptvPlaylistParser.parse(
        playlist,
        baseUri: Uri.parse('https://example.com/lists/main.m3u'),
      );
      expect(channels.single.url, 'https://example.com/lists/streams/news/index.m3u8');
    });

    test('ignores unsupported schemes and comments', () {
      const playlist = '''
#EXTM3U
#EXTINF:-1,Unsafe scheme
javascript:alert(1)
#EXTINF:-1,Valid channel
https://example.com/live.m3u8
''';
      final channels = IptvPlaylistParser.parse(playlist);
      expect(channels, hasLength(1));
      expect(channels.single.name, 'Valid channel');
    });

    test('returns empty list for non-playlist text', () {
      expect(IptvPlaylistParser.parse('not a playlist'), isEmpty);
    });
  });
}
