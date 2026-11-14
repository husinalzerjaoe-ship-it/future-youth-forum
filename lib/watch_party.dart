import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

const _watchBrand = Color(0xFF6554D9);
final _watchDb = FirebaseFirestore.instance;

class WatchPartyLobbyPage extends StatefulWidget {
  const WatchPartyLobbyPage({super.key});
  @override State<WatchPartyLobbyPage> createState() => _WatchPartyLobbyPageState();
}

class _WatchPartyLobbyPageState extends State<WatchPartyLobbyPage> {
  final _url = TextEditingController();
  final _name = TextEditingController(text: 'غرفة مشاهدة');
  bool _creating = false;
  String? _error;
  String get _uid => FirebaseAuth.instance.currentUser!.uid;

  @override
  void dispose() { _url.dispose(); _name.dispose(); super.dispose(); }

  Future<void> _createRoom() async {
    final raw = _url.text.trim();
    final uri = Uri.tryParse(raw);
    if (uri == null || !uri.hasScheme || !['http', 'https'].contains(uri.scheme)) {
      setState(() => _error = 'أدخل رابط فيديو صحيح يبدأ بـ https://');
      return;
    }
    final videoId = YoutubePlayerController.convertUrlToId(raw);
    final path = uri.path.toLowerCase();
    final isDirect = path.endsWith('.mp4') || path.endsWith('.m3u8') ||
        path.endsWith('.m4v') || path.endsWith('.mov') || path.endsWith('.webm');
    if (videoId == null && !isDirect) {
      setState(() => _error = 'الرابط لازم يكون يوتيوب أو رابط فيديو مباشر MP4 / M3U8 / MOV / WEBM.');
      return;
    }
    setState(() { _creating = true; _error = null; });
    try {
      final ref = await _watchDb.collection('watchRooms').add({
        'name': _name.text.trim().isEmpty ? 'غرفة مشاهدة' : _name.text.trim(),
        'url': raw,
        'sourceType': videoId == null ? 'direct' : 'youtube',
        if (videoId != null) 'videoId': videoId,
        'hostUid': _uid,
        'status': 'paused',
        'positionSeconds': 0,
        'updatedAt': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
        'active': true,
      });
      if (!mounted) return;
      Navigator.push(context, MaterialPageRoute(builder: (_) => WatchPartyRoomPage(roomId: ref.id)));
    } catch (_) {
      if (mounted) setState(() => _error = 'تعذر إنشاء الغرفة. تأكد من نشر قواعد Firestore.');
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.rtl,
    child: Scaffold(
      appBar: AppBar(title: const Text('المشاهدة الجماعية')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const Text('أنشئ غرفة وشاهدوا معاً', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('يدعم روابط YouTube وروابط الفيديو المباشرة المصرّح بها مثل MP4 وM3U8.'),
            const SizedBox(height: 12),
            TextField(controller: _name, decoration: const InputDecoration(labelText: 'اسم الغرفة', border: OutlineInputBorder())),
            const SizedBox(height: 10),
            TextField(controller: _url, keyboardType: TextInputType.url, decoration: const InputDecoration(labelText: 'رابط يوتيوب أو رابط فيديو مباشر', hintText: 'https://', border: OutlineInputBorder())),
            if (_error != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(_error!, style: const TextStyle(color: Colors.red))),
            const SizedBox(height: 12),
            FilledButton.icon(onPressed: _creating ? null : _createRoom, icon: const Icon(Icons.play_circle_fill), label: Text(_creating ? 'جارٍ الإنشاء...' : 'إنشاء غرفة وتشغيل الفيديو')),
          ],
        ))),
        const SizedBox(height: 12),
        const Text('الغرف المباشرة', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _watchDb.collection('watchRooms').where('active', isEqualTo: true).limit(40).snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) return const Padding(padding: EdgeInsets.all(12), child: Text('تعذر تحميل الغرف. تحقق من قواعد Firestore.'));
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
            final docs = snapshot.data!.docs;
            if (docs.isEmpty) return const Padding(padding: EdgeInsets.all(12), child: Text('ماكو غرف حالياً. أنشئ أول غرفة مشاهدة.'));
            return Column(children: docs.map((doc) {
              final d = doc.data();
              return Card(child: ListTile(
                leading: const CircleAvatar(child: Icon(Icons.live_tv)),
                title: Text(d['name'] as String? ?? 'غرفة مشاهدة'),
                subtitle: Text((d['sourceType'] == 'youtube' ? 'YouTube' : 'بث مباشر / فيديو') + ' • ' + (d['status'] == 'playing' ? 'يعمل الآن' : 'متوقف')),
                trailing: const Icon(Icons.chevron_left),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => WatchPartyRoomPage(roomId: doc.id))),
              ));
            }).toList());
          },
        ),
      ]),
    ),
  );
}

class WatchPartyRoomPage extends StatefulWidget {
  final String roomId;
  const WatchPartyRoomPage({super.key, required this.roomId});
  @override State<WatchPartyRoomPage> createState() => _WatchPartyRoomPageState();
}

class _WatchPartyRoomPageState extends State<WatchPartyRoomPage> {
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _roomSub;
  StreamSubscription<YoutubePlayerValue>? _ytSub;
  VideoPlayerController? _video;
  YoutubePlayerController? _youtube;
  Timer? _syncTimer;
  String? _loadedUrl;
  String? _error;
  bool _applyingRemote = false;
  bool _busy = false;
  Map<String, dynamic> _room = {};
  String get _uid => FirebaseAuth.instance.currentUser!.uid;
  bool get _isHost => _room['hostUid'] == _uid;
  bool get _isYoutube => _room['sourceType'] == 'youtube';

  @override
  void initState() {
    super.initState();
    _roomSub = _watchDb.collection('watchRooms').doc(widget.roomId).snapshots().listen((snap) {
      if (!snap.exists) { if (mounted) setState(() => _error = 'الغرفة لم تعد موجودة.'); return; }
      final data = snap.data()!;
      final changed = data['url'] != _loadedUrl;
      if (mounted) setState(() => _room = data);
      if (changed) _setupPlayer(data);
      else if (!_isHost) _applyRemoteState(data);
    }, onError: (_) { if (mounted) setState(() => _error = 'تعذر الاتصال بغرفة المشاهدة.'); });
  }

  Future<void> _setupPlayer(Map<String, dynamic> data) async {
    _syncTimer?.cancel();
    await _ytSub?.cancel();
    await _youtube?.close();
    await _video?.dispose();
    _youtube = null; _video = null;
    final url = data['url'] as String? ?? '';
    _loadedUrl = url;
    try {
      if (data['sourceType'] == 'youtube') {
        final id = data['videoId'] as String? ?? YoutubePlayerController.convertUrlToId(url);
        if (id == null) throw StateError('رابط يوتيوب غير صالح.');
        final controller = YoutubePlayerController.fromVideoId(
          videoId: id,
          autoPlay: false,
          params: const YoutubePlayerParams(showControls: false, showFullscreenButton: true, strictRelatedVideos: true),
        );
        _youtube = controller;
        _ytSub = controller.listen((value) {
          if (!_isHost || _applyingRemote) return;
          if (value.playerState == PlayerState.playing) _publish('playing');
          if (value.playerState == PlayerState.paused) _publish('paused');
        });
      } else {
        final controller = VideoPlayerController.networkUrl(Uri.parse(url));
        _video = controller;
        await controller.initialize();
        await controller.setLooping(false);
      }
      if (!mounted) return;
      setState(() { _error = null; });
      _applyRemoteState(data);
      _syncTimer = Timer.periodic(const Duration(seconds: 5), (_) => _publishCurrentPosition());
    } catch (_) {
      if (mounted) setState(() => _error = 'تعذر تشغيل الرابط. تأكد أنه فيديو مباشر أو أن ناشر YouTube يسمح بالتضمين.');
    }
  }

  double _targetPosition(Map<String, dynamic> data) {
    var position = (data['positionSeconds'] as num?)?.toDouble() ?? 0;
    if (data['status'] == 'playing' && data['updatedAt'] is Timestamp) {
      position += DateTime.now().difference((data['updatedAt'] as Timestamp).toDate()).inMilliseconds / 1000;
    }
    return position.clamp(0, 864000).toDouble();
  }

  Future<void> _applyRemoteState(Map<String, dynamic> data) async {
    if (_isHost || _loadedUrl != data['url']) return;
    _applyingRemote = true;
    try {
      final target = _targetPosition(data);
      if (data['sourceType'] == 'youtube' && _youtube != null) {
        final current = await _youtube!.currentTime;
        if ((current - target).abs() > 3) await _youtube!.seekTo(seconds: target, allowSeekAhead: true);
        if (data['status'] == 'playing') {
          if (_youtube!.value.playerState != PlayerState.playing) await _youtube!.playVideo();
        } else {
          if (_youtube!.value.playerState == PlayerState.playing) await _youtube!.pauseVideo();
        }
      } else if (_video?.value.isInitialized == true) {
        final current = _video!.value.position.inMilliseconds / 1000;
        if ((current - target).abs() > 3) await _video!.seekTo(Duration(milliseconds: (target * 1000).round()));
        if (data['status'] == 'playing' && !_video!.value.isPlaying) await _video!.play();
        if (data['status'] != 'playing' && _video!.value.isPlaying) await _video!.pause();
      }
    } catch (_) {
      // A temporary buffering/network error should not break the room listener.
    } finally {
      _applyingRemote = false;
    }
  }

  Future<double> _currentPosition() async {
    if (_isYoutube && _youtube != null) return await _youtube!.currentTime;
    if (_video?.value.isInitialized == true) return _video!.value.position.inMilliseconds / 1000;
    return (_room['positionSeconds'] as num?)?.toDouble() ?? 0;
  }

  Future<void> _publish(String status) async {
    if (!_isHost || _applyingRemote || _busy) return;
    _busy = true;
    try {
      final position = await _currentPosition();
      await _watchDb.collection('watchRooms').doc(widget.roomId).update({
        'status': status,
        'positionSeconds': position,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      if (mounted) setState(() => _error = 'تعذر مزامنة حالة المشاهدة.');
    } finally { _busy = false; }
  }

  Future<void> _publishCurrentPosition() async {
    if (!_isHost || _room['status'] != 'playing' || _busy) return;
    _busy = true;
    try {
      final position = await _currentPosition();
      await _watchDb.collection('watchRooms').doc(widget.roomId).update({
        'positionSeconds': position,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {} finally { _busy = false; }
  }

  Future<void> _togglePlayback() async {
    if (!_isHost) return;
    if (_isYoutube && _youtube != null) {
      if (_youtube!.value.playerState == PlayerState.playing) {
        await _youtube!.pauseVideo();
        await _publish('paused');
      } else {
        await _youtube!.playVideo();
        await _publish('playing');
      }
    } else if (_video?.value.isInitialized == true) {
      if (_video!.value.isPlaying) {
        await _video!.pause();
        await _publish('paused');
      } else {
        await _video!.play();
        await _publish('playing');
      }
    }
    if (mounted) setState(() {});
  }

  Future<void> _seekBy(int seconds) async {
    if (!_isHost) return;
    final next = ((_awaitPosition()) + seconds).clamp(0, 864000).toDouble();
    if (_isYoutube && _youtube != null) {
      await _youtube!.seekTo(seconds: next, allowSeekAhead: true);
    } else if (_video?.value.isInitialized == true) {
      await _video!.seekTo(Duration(seconds: next.round()));
    }
    await _publish(_room['status'] == 'playing' ? 'playing' : 'paused');
  }

  double _awaitPosition() {
    if (_isYoutube) return _room['positionSeconds'] is num ? (_room['positionSeconds'] as num).toDouble() : 0;
    return _video?.value.position.inSeconds.toDouble() ?? 0;
  }

  @override
  void dispose() {
    _syncTimer?.cancel();
    _roomSub?.cancel();
    _ytSub?.cancel();
    _youtube?.close();
    _video?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.rtl,
    child: Scaffold(
      appBar: AppBar(title: Text(_room['name'] as String? ?? 'غرفة مشاهدة')),
      body: ListView(padding: const EdgeInsets.all(12), children: [
        if (_error != null) Card(color: Theme.of(context).colorScheme.errorContainer, child: Padding(padding: const EdgeInsets.all(12), child: Text(_error!))),
        if (_youtube != null) YoutubePlayer(controller: _youtube!, aspectRatio: 16 / 9)
        else if (_video?.value.isInitialized == true)
          AspectRatio(aspectRatio: _video!.value.aspectRatio, child: VideoPlayer(_video!))
        else const AspectRatio(aspectRatio: 16 / 9, child: Center(child: CircularProgressIndicator())),
        const SizedBox(height: 12),
        Card(child: Padding(padding: const EdgeInsets.all(12), child: Column(children: [
          Row(children: [
            Icon(_room['status'] == 'playing' ? Icons.play_circle : Icons.pause_circle, color: _watchBrand),
            const SizedBox(width: 8),
            Expanded(child: Text(_isHost ? 'أنت مضيف الغرفة — تحكم بالتشغيل للجميع' : 'مشاهدة متزامنة مع المضيف', style: const TextStyle(fontWeight: FontWeight.bold))),
          ]),
          if (_isHost) Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            IconButton(onPressed: () => _seekBy(-10), icon: const Icon(Icons.replay_10), tooltip: 'رجوع 10 ثوانٍ'),
            FilledButton.icon(onPressed: _togglePlayback, icon: Icon(_room['status'] == 'playing' ? Icons.pause : Icons.play_arrow), label: Text(_room['status'] == 'playing' ? 'إيقاف مؤقت' : 'تشغيل للجميع')),
            IconButton(onPressed: () => _seekBy(10), icon: const Icon(Icons.forward_10), tooltip: 'تقديم 10 ثوانٍ'),
          ]) else const Padding(padding: EdgeInsets.only(top: 8), child: Text('المضيف وحده يتحكم بالتشغيل والتقديم حتى تبقون على نفس المقطع.')),
        ]))),
        const Padding(padding: EdgeInsets.all(8), child: Text('ملاحظة: المزامنة تعتمد على سرعة الإنترنت، وقد يظهر فرق بسيط بين الأجهزة. بعض مقاطع YouTube تمنع التضمين، وروابط البث يجب أن تكون مباشرة ومصرّحاً بمشاركتها.', style: TextStyle(fontSize: 12))),
      ]),
    ),
  );
}
