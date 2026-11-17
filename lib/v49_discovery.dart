import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

/// Reuses the existing 24-hour video stories; no new media collection or
/// upload permission is introduced by the V49 short-video feed.
class V49VideoFeedFilter {
  static bool isVisible(Map<String, dynamic> data, DateTime now) {
    if (data['mediaType'] != 'video') return false;
    final expiresAt = data['expiresAt'];
    if (expiresAt is Timestamp && !expiresAt.toDate().isAfter(now)) {
      return false;
    }
    return (data['mediaUrl'] as String?)?.startsWith('https://') ?? false;
  }
}

class V49ShortVideoFeedPage extends StatefulWidget {
  const V49ShortVideoFeedPage({super.key});

  @override
  State<V49ShortVideoFeedPage> createState() => _V49ShortVideoFeedPageState();
}

class _V49ShortVideoFeedPageState extends State<V49ShortVideoFeedPage>
    with WidgetsBindingObserver {
  final PageController _pages = PageController();
  VideoPlayerController? _video;
  String? _activeUrl;
  bool _loadingVideo = false;
  String? _videoError;
  int _loadToken = 0;
  bool _muted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      _video?.pause();
    }
  }

  Future<void> _loadVideo(String url) async {
    if (_activeUrl == url && _video?.value.isInitialized == true) return;
    final token = ++_loadToken;
    final old = _video;
    _video = null;
    _activeUrl = url;
    _videoError = null;
    _loadingVideo = true;
    if (mounted) setState(() {});
    await old?.dispose();

    final next = VideoPlayerController.networkUrl(Uri.parse(url));
    try {
      await next.initialize().timeout(const Duration(seconds: 25));
      if (!mounted || token != _loadToken) {
        await next.dispose();
        return;
      }
      await next.setLooping(true);
      await next.setVolume(_muted ? 0 : 1);
      _video = next;
      _loadingVideo = false;
      setState(() {});
      await next.play();
    } catch (_) {
      await next.dispose();
      if (!mounted || token != _loadToken) return;
      _loadingVideo = false;
      _videoError = 'تعذر تشغيل هذا الفيديو. جرّب المقطع التالي.';
      setState(() {});
    }
  }

  void _scheduleLoad(String url) {
    if (_activeUrl == url) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _activeUrl != url) _loadVideo(url);
    });
  }

  Future<void> _togglePlayback() async {
    final video = _video;
    if (video == null || !video.value.isInitialized) return;
    if (video.value.isPlaying) {
      await video.pause();
    } else {
      await video.play();
    }
    if (mounted) setState(() {});
  }

  Future<void> _toggleMute() async {
    _muted = !_muted;
    await _video?.setVolume(_muted ? 0 : 1);
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _loadToken++;
    _pages.dispose();
    _video?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          title: const Text('مقاطع الملتقى'),
          actions: [
            IconButton(
              tooltip: _muted ? 'تشغيل الصوت' : 'كتم الصوت',
              onPressed: _toggleMute,
              icon: Icon(_muted ? Icons.volume_off : Icons.volume_up),
            ),
          ],
        ),
        body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('stories')
              .orderBy('createdAt', descending: true)
              .limit(100)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const Center(
                child: Text(
                  'تعذر تحميل المقاطع. تحقق من اتصالك وقواعد Firestore.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70),
                ),
              );
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final now = DateTime.now();
            final clips = snapshot.data!.docs
                .where((doc) => V49VideoFeedFilter.isVisible(doc.data(), now))
                .toList();
            if (clips.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.video_library_outlined,
                          color: Colors.white54, size: 58),
                      SizedBox(height: 14),
                      Text(
                        'ماكو مقاطع فيديو متاحة حالياً',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'الفيديوهات المنشورة ضمن القصص تظهر هنا تلقائياً.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white60),
                      ),
                    ],
                  ),
                ),
              );
            }
            final firstUrl = clips.first.data()['mediaUrl'] as String;
            _scheduleLoad(firstUrl);
            return PageView.builder(
              controller: _pages,
              scrollDirection: Axis.vertical,
              itemCount: clips.length,
              onPageChanged: (index) {
                final url = clips[index].data()['mediaUrl'] as String;
                _loadVideo(url);
              },
              itemBuilder: (context, index) {
                final data = clips[index].data();
                final url = data['mediaUrl'] as String;
                final author = (data['authorName'] ?? 'عضو').toString();
                final authorId = (data['authorId'] ?? '').toString();
                final isCurrent = _activeUrl == url;
                final controller = isCurrent ? _video : null;
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    const ColoredBox(color: Colors.black),
                    if (controller?.value.isInitialized == true)
                      Center(
                        child: AspectRatio(
                          aspectRatio: controller!.value.aspectRatio,
                          child: VideoPlayer(controller),
                        ),
                      )
                    else if (_loadingVideo && isCurrent)
                      const Center(
                          child: CircularProgressIndicator(color: Colors.white))
                    else if (_videoError != null && isCurrent)
                      Center(
                        child: Text(_videoError!,
                            style: const TextStyle(color: Colors.white70)),
                      )
                    else
                      const Center(
                        child: Icon(Icons.play_circle_outline,
                            color: Colors.white54, size: 68),
                      ),
                    GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTap: isCurrent ? _togglePlayback : null,
                      child: const SizedBox.expand(),
                    ),
                    Positioned(
                      right: 16,
                      left: 16,
                      bottom: 28,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              Colors.black.withValues(alpha: .82),
                              Colors.transparent,
                            ],
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(10, 38, 10, 12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Row(
                                      children: [
                                        const CircleAvatar(
                                          radius: 15,
                                          child: Icon(Icons.person, size: 18),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            author,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    const Text(
                                      'فيديو من قصص مجتمع ملتقى شباب المستقبل',
                                      style: TextStyle(
                                          color: Colors.white70, fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                tooltip: 'نسخ رابط الفيديو',
                                color: Colors.white,
                                onPressed: () async {
                                  await Clipboard.setData(
                                      ClipboardData(text: url));
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text('تم نسخ رابط الفيديو')),
                                    );
                                  }
                                },
                                icon: const Icon(Icons.link),
                              ),
                              if (isCurrent &&
                                  controller?.value.isInitialized == true)
                                IconButton(
                                  tooltip: controller!.value.isPlaying
                                      ? 'إيقاف مؤقت'
                                      : 'تشغيل',
                                  color: Colors.white,
                                  onPressed: _togglePlayback,
                                  icon: Icon(controller.value.isPlaying
                                      ? Icons.pause_circle
                                      : Icons.play_circle),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (authorId.isEmpty)
                      const SizedBox.shrink(),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}
