import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
import 'package:webview_flutter/webview_flutter.dart';

String? youtubeEmbedUrl(String raw) {
  final uri = Uri.tryParse(raw.trim());
  if (uri == null || !['https', 'http'].contains(uri.scheme)) return null;
  final host = uri.host.toLowerCase().replaceFirst(RegExp(r'^www\.'), '');
  const hosts = ['youtube.com', 'm.youtube.com', 'music.youtube.com', 'youtu.be', 'youtube-nocookie.com'];
  if (!hosts.contains(host)) return null;
  String? validId(String value) => RegExp(r'^[A-Za-z0-9_-]{11}$').hasMatch(value) ? value : null;
  final playlist = uri.queryParameters['list'];
  final validPlaylist = playlist != null && RegExp(r'^[A-Za-z0-9_-]{10,}$').hasMatch(playlist);
  String? id;
  if (host == 'youtu.be') {
    if (uri.pathSegments.isNotEmpty) id = validId(uri.pathSegments.first);
  } else if (uri.path == '/watch') {
    id = validId(uri.queryParameters['v'] ?? '');
  } else if (uri.path == '/playlist') {
    if (validPlaylist) return 'https://www.youtube-nocookie.com/embed/videoseries?list=$playlist&playsinline=1&rel=0';
  } else if (uri.pathSegments.length >= 2 &&
      ['embed', 'shorts', 'live', 'v', 'e'].contains(uri.pathSegments.first)) {
    id = validId(uri.pathSegments[1]);
  }
  if (id == null) {
    if (validPlaylist) return 'https://www.youtube-nocookie.com/embed/videoseries?list=$playlist&playsinline=1&rel=0';
    return null;
  }
  final listParam = validPlaylist ? '&list=$playlist' : '';
  return 'https://www.youtube-nocookie.com/embed/$id?playsinline=1&rel=0$listParam';
}

bool isSupportedYoutubeUrl(String raw) => youtubeEmbedUrl(raw) != null;

bool _isDirectVideoUrl(Uri uri) =>
    RegExp(r'\.(mp4|m4v|mov|webm|m3u8)$', caseSensitive: false).hasMatch(uri.path);

class YouTubeVideoPlayer extends StatefulWidget {
  final String url;
  const YouTubeVideoPlayer({super.key, required this.url});
  @override State<YouTubeVideoPlayer> createState() => _YouTubeVideoPlayerState();
}

class _YouTubeVideoPlayerState extends State<YouTubeVideoPlayer> {
  WebViewController? _web;
  VideoPlayerController? _direct;
  bool _loading = true;
  bool _failed = false;
  bool _isDirect = false;

  @override void initState() { super.initState(); _load(); }

  @override void didUpdateWidget(covariant YouTubeVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) _load();
  }

  Future<void> _load() async {
    await _direct?.dispose();
    _direct = null;
    _web = null;
    _loading = true;
    _failed = false;
    final embed = youtubeEmbedUrl(widget.url);
    if (embed != null) {
      final controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(const Color(0xFF000000))
        ..setNavigationDelegate(NavigationDelegate(
          onPageFinished: (_) { if (mounted) setState(() => _loading = false); },
          onWebResourceError: (error) {
            if (error.isForMainFrame == true && mounted) {
              setState(() { _loading = false; _failed = true; });
            }
          },
        ));
      _web = controller;
      await controller.loadHtmlString('''<!doctype html><html><head><meta name="viewport" content="width=device-width,initial-scale=1,maximum-scale=1"><style>html,body{margin:0;padding:0;background:#000;width:100%;height:100%;overflow:hidden}iframe{position:absolute;inset:0;width:100%;height:100%;border:0}</style></head><body><iframe src="$embed" title="YouTube player" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share" referrerpolicy="strict-origin-when-cross-origin" allowfullscreen></iframe></body></html>''',
        baseUrl: 'https://www.youtube-nocookie.com');
      return;
    }
    final uri = Uri.tryParse(widget.url.trim());
    if (uri != null && uri.scheme == 'https' && uri.host.isNotEmpty && _isDirectVideoUrl(uri)) {
      try {
        final player = VideoPlayerController.networkUrl(uri);
        _direct = player;
        await player.initialize();
        if (!mounted) return;
        setState(() { _isDirect = true; _loading = false; });
        return;
      } catch (_) {}
    }
    if (mounted) setState(() { _loading = false; _failed = true; });
  }

  Future<void> _openExternal() async {
    final uri = Uri.tryParse(widget.url.trim());
    if (uri != null && ['https', 'http'].contains(uri.scheme) && uri.host.isNotEmpty) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override void dispose() { _direct?.dispose(); super.dispose(); }

  @override Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(12),
    child: AspectRatio(aspectRatio: 16 / 9, child: Stack(fit: StackFit.expand, children: [
      if (_web != null && !_failed) WebViewWidget(controller: _web!)
      else if (_direct != null && _isDirect)
        GestureDetector(
          onTap: () {
            final p = _direct!;
            if (p.value.isPlaying) { p.pause(); } else { p.play(); }
            setState(() {});
          },
          child: ColoredBox(color: Colors.black, child: Stack(alignment: Alignment.center, children: [
            VideoPlayer(_direct!),
            ValueListenableBuilder<VideoPlayerValue>(valueListenable: _direct!, builder: (context, value, child) =>
              Icon(value.isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill, color: Colors.white, size: 54)),
            Positioned(left: 8, right: 8, bottom: 0, child: VideoProgressIndicator(_direct!, allowScrubbing: true, colors: const VideoProgressColors(playedColor: Colors.deepPurple, bufferedColor: Colors.white54, backgroundColor: Colors.white24))),
          ])),
        )
      else
        ColoredBox(color: Colors.black87, child: Center(child: TextButton.icon(
          onPressed: _openExternal,
          icon: const Icon(Icons.open_in_new, color: Colors.white),
          label: const Text('افتح الفيديو خارج التطبيق', style: TextStyle(color: Colors.white)),
        ))),
      if (_loading) const ColoredBox(color: Colors.black45, child: Center(child: CircularProgressIndicator(color: Colors.white))),
      if (_failed && !_loading) ColoredBox(color: Colors.black54, child: Center(child: TextButton.icon(
        onPressed: _openExternal,
        icon: const Icon(Icons.play_circle_fill, color: Colors.white),
        label: const Text('تعذر التشغيل؟ افتحه خارج التطبيق', style: TextStyle(color: Colors.white)),
      ))),
    ])),
  );
}

class YouTubeWatchPage extends StatelessWidget {
  final String url;
  final String title;
  const YouTubeWatchPage({super.key, required this.url, required this.title});
  @override Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.rtl,
    child: Scaffold(
      appBar: AppBar(title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis)),
      body: ListView(padding: const EdgeInsets.all(12), children: [
        YouTubeVideoPlayer(url: url),
        const SizedBox(height: 12),
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ]),
    ),
  );
}
