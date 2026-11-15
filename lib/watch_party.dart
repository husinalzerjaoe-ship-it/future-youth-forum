import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:record/record.dart';
import 'package:just_audio/just_audio.dart' hide PlayerState;
import 'package:crypto/crypto.dart' as crypto;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import 'package:url_launcher/url_launcher.dart';
import 'media_upload_service.dart';

const _watchBrand = Color(0xFF6554D9);
final _watchDb = FirebaseFirestore.instance;

class WatchPartyLobbyPage extends StatefulWidget {
  const WatchPartyLobbyPage({super.key});
  @override State<WatchPartyLobbyPage> createState() => _WatchPartyLobbyPageState();
}

class _WatchPartyLobbyPageState extends State<WatchPartyLobbyPage> {
  final _url = TextEditingController();
  final _name = TextEditingController(text: 'غرفة مشاهدة');
  final _roomPassword = TextEditingController();
  bool _creating = false;
  bool _privateRoom = false;
  bool _passwordProtected = false;
  final Set<String> _invitedUids = <String>{};
  String? _error;
  String get _uid => FirebaseAuth.instance.currentUser!.uid;

  @override
  void dispose() { _url.dispose(); _name.dispose(); _roomPassword.dispose(); super.dispose(); }

  Future<void> _chooseFriends() async {
    final profiles = await _watchDb.collection('publicProfiles').limit(100).get();
    if (!mounted) return;
    final chosen = Set<String>.from(_invitedUids);
    await showModalBottomSheet<void>(
      context: context, isScrollControlled: true, showDragHandle: true,
      builder: (sheetContext) => StatefulBuilder(builder: (sheetContext, updateSheet) =>
        Directionality(textDirection: TextDirection.rtl, child: SafeArea(
          child: SizedBox(height: MediaQuery.of(sheetContext).size.height * .65,
            child: Column(children: [
              const Padding(padding: EdgeInsets.all(14), child: Text('اختَر أصدقاء الغرفة الخاصة', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
              Expanded(child: ListView(children: profiles.docs.where((p) => p.id != _uid).map((p) {
                final d = p.data();
                final selected = chosen.contains(p.id);
                final photo = (d['photoUrl'] ?? '').toString();
                return CheckboxListTile(
                  value: selected,
                  secondary: CircleAvatar(backgroundImage: photo.startsWith('http') ? NetworkImage(photo) : null,
                    child: !photo.startsWith('http') ? const Icon(Icons.person) : null),
                  title: Text((d['name'] ?? 'عضو').toString()),
                  onChanged: (value) => updateSheet(() {
                    if (value == true) chosen.add(p.id); else chosen.remove(p.id);
                  }),
                );
              }).toList())),
              Padding(padding: const EdgeInsets.all(12), child: FilledButton(
                onPressed: () { _invitedUids..clear()..addAll(chosen); Navigator.pop(sheetContext); if (mounted) setState(() {}); },
                child: Text('تأكيد الاختيار (${chosen.length})'),
              )),
            ]),
          ),
        )),
      ),
    );
  }

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
    final sourceType = videoId != null ? 'youtube' : isDirect ? 'direct' : 'web';
    if (_passwordProtected && _roomPassword.text.trim().length < 4) {
      setState(() => _error = 'كلمة المرور لازم تكون 4 أحرف على الأقل.');
      return;
    }
    final passwordSalt = _passwordProtected
        ? List<int>.generate(16, (_) => Random.secure().nextInt(256)).map((b) => b.toRadixString(16).padLeft(2, '0')).join()
        : null;
    final passwordHash = _passwordProtected
        ? crypto.sha256.convert(utf8.encode('$passwordSalt|${_roomPassword.text.trim()}')).toString()
        : null;
    setState(() { _creating = true; _error = null; });
    try {
      final ref = await _watchDb.collection('watchRooms').add({
        'name': _name.text.trim().isEmpty ? 'غرفة مشاهدة' : _name.text.trim(),
        'url': raw,
        'sourceType': sourceType,
        if (videoId != null) 'videoId': videoId,
        'hostUid': _uid,
        'visibility': _privateRoom ? 'private' : 'public',
        'invitedUids': _privateRoom ? <String>{_uid, ..._invitedUids}.toList() : <String>[],
        'passwordProtected': _passwordProtected && _privateRoom,
        if (_passwordProtected && _privateRoom) 'passwordSalt': passwordSalt,
        if (_passwordProtected && _privateRoom) 'passwordHash': passwordHash,
        'status': 'paused',
        'positionSeconds': 0,
        'updatedAt': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
        'active': true,
      });
      if (_privateRoom && _invitedUids.isNotEmpty) {
        final me = await _watchDb.collection('publicProfiles').doc(_uid).get();
        final actorName = (me.data()?['name'] ?? FirebaseAuth.instance.currentUser?.displayName ?? 'صديق').toString();
        for (final friendUid in _invitedUids) {
          await _watchDb.collection('notifications').add({
            'recipientId': friendUid, 'actorId': _uid, 'actorName': actorName,
            'type': 'message', 'text': 'دعاك إلى غرفة مشاهدة خاصة: ${_name.text.trim().isEmpty ? 'غرفة مشاهدة' : _name.text.trim()}',
            'read': false, 'targetType': 'watchRoom', 'targetId': ref.id,
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
      }
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
            const Text('يدعم YouTube وروابط MP4 / M3U8 والمواقع الخارجية. تشغيل المواقع الخارجية يكون بفتحها على كل جهاز وقد لا يتزامن الفيديو.'),
            const SizedBox(height: 12),
            TextField(controller: _name, decoration: const InputDecoration(labelText: 'اسم الغرفة', border: OutlineInputBorder())),
            const SizedBox(height: 10),
            TextField(controller: _url, keyboardType: TextInputType.url, decoration: const InputDecoration(labelText: 'رابط يوتيوب أو فيديو تملكه/مصرّح بمشاركته', hintText: 'https://', border: OutlineInputBorder())),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero, value: _privateRoom,
              title: const Text('غرفة خاصة للأصدقاء'),
              subtitle: const Text('لا تظهر للعامة؛ فقط أنت والأصدقاء الذين تختارهم'),
              onChanged: (value) => setState(() { _privateRoom = value; if (!value) { _invitedUids.clear(); _passwordProtected = false; _roomPassword.clear(); } }),
            ),
            if (_privateRoom) SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _passwordProtected,
              title: const Text('حماية الغرفة بكلمة مرور'),
              subtitle: const Text('الدخول للمدعوين فقط، ويحتاجون كلمة المرور أيضاً'),
              onChanged: (value) => setState(() { _passwordProtected = value; if (!value) _roomPassword.clear(); }),
            ),
            if (_privateRoom && _passwordProtected) Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: TextField(controller: _roomPassword, obscureText: true, maxLength: 64,
                decoration: const InputDecoration(labelText: 'كلمة مرور الغرفة (4 أحرف على الأقل)', border: OutlineInputBorder(), counterText: '')),
            ),
            if (_privateRoom) OutlinedButton.icon(
              onPressed: _chooseFriends, icon: const Icon(Icons.group_add),
              label: Text('اختيار الأصدقاء (${_invitedUids.length})'),
            ),
            if (_error != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(_error!, style: const TextStyle(color: Colors.red))),
            const SizedBox(height: 12),
            FilledButton.icon(onPressed: _creating ? null : _createRoom, icon: const Icon(Icons.play_circle_fill), label: Text(_creating ? 'جارٍ الإنشاء...' : 'إنشاء غرفة وتشغيل الفيديو')),
          ],
        ))),
        const SizedBox(height: 12),
        const Text('الغرف المباشرة', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _watchDb.collection('watchRooms').where('active', isEqualTo: true).where('visibility', isEqualTo: 'public').limit(40).snapshots(),
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
  bool _viewerPlaybackUnlocked = false;
  Map<String, dynamic> _room = {};
  final _chatText = TextEditingController();
  final _roomPicker = ImagePicker();
  final _roomRecorder = AudioRecorder();
  final _roomVoicePlayer = AudioPlayer();
  bool _recordingRoomVoice = false;
  DateTime? _roomVoiceStarted;
  String? _roomVoicePath;
  bool _sendingChat = false;
  bool _roomReady = false;
  double _playbackSpeed = 1.0;
  String get _uid => FirebaseAuth.instance.currentUser!.uid;
  bool get _isHost => _room['hostUid'] == _uid;
  bool get _isYoutube => _room['sourceType'] == 'youtube';

  @override
  void initState() {
    super.initState();
    _authorizeAndJoin();
  }

  Future<void> _authorizeAndJoin() async {
    try {
      final first = await _watchDb.collection('watchRooms').doc(widget.roomId).get();
      if (!first.exists) throw StateError('الغرفة غير موجودة.');
      final data = first.data() ?? <String, dynamic>{};
      if (data['active'] == false) throw StateError('الغرفة مغلقة.');
      if (data['passwordProtected'] == true && data['hostUid'] != _uid) {
        final passController = TextEditingController();
        final entered = await showDialog<String>(context: context, barrierDismissible: false,
          builder: (dialogContext) => Directionality(textDirection: TextDirection.rtl, child: AlertDialog(
            title: const Text('غرفة محمية بكلمة مرور'),
            content: TextField(controller: passController, obscureText: true, autofocus: true,
              decoration: const InputDecoration(labelText: 'أدخل كلمة المرور', border: OutlineInputBorder()),
              onSubmitted: (value) => Navigator.pop(dialogContext, value)),
            actions: [TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('إلغاء')),
              FilledButton(onPressed: () => Navigator.pop(dialogContext, passController.text), child: const Text('دخول'))],
          )));
        passController.dispose();
        if (entered == null) { if (mounted) Navigator.pop(context); return; }
        final salt = (data['passwordSalt'] ?? '').toString();
        final expected = (data['passwordHash'] ?? '').toString();
        final actual = crypto.sha256.convert(utf8.encode('$salt|${entered.trim()}')).toString();
        if (salt.isEmpty || expected.isEmpty || actual != expected) {
          if (mounted) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('كلمة المرور غير صحيحة.'))); Navigator.pop(context); }
          return;
        }
      }
      await _joinRoom();
      if (!mounted) return;
      setState(() { _room = data; _roomReady = true; });
      _roomSub = _watchDb.collection('watchRooms').doc(widget.roomId).snapshots().listen((snap) {
      if (!snap.exists) { if (mounted) setState(() => _error = 'الغرفة لم تعد موجودة.'); return; }
      final data = snap.data()!;
      final changed = data['url'] != _loadedUrl;
      if (mounted) setState(() => _room = data);
      if (changed) _setupPlayer(data);
      else _applyRemoteState(data);
      }, onError: (_) { if (mounted) setState(() => _error = 'تعذر الاتصال بغرفة المشاهدة.'); });
    } catch (_) {
      if (mounted) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ما عندك صلاحية دخول هذه الغرفة أو أن الغرفة مغلقة.'))); Navigator.pop(context); }
    }
  }

  Future<void> _joinRoom() async {
    try {
      final profile = await _watchDb.collection('publicProfiles').doc(_uid).get();
      final data = profile.data() ?? {};
      await _watchDb.collection('watchRooms').doc(widget.roomId)
          .collection('participants').doc(_uid).set({
        'uid': _uid,
        'name': data['name'] ?? FirebaseAuth.instance.currentUser?.displayName ?? 'عضو',
        'photoUrl': data['photoUrl'] ?? '',
        'joinedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {
      if (mounted) setState(() => _error = 'تعذر تسجيل حضورك في الغرفة. تحقق من قواعد Firestore.');
    }
  }

  Future<void> _setupPlayer(Map<String, dynamic> data) async {
    _syncTimer?.cancel();
    _viewerPlaybackUnlocked = false;
    await _ytSub?.cancel();
    await _youtube?.close();
    await _video?.dispose();
    _youtube = null; _video = null;
    final url = data['url'] as String? ?? '';
    _loadedUrl = url;
    if (data['sourceType'] == 'web') { if (mounted) setState(() => _error = null); return; }
    try {
      if (data['sourceType'] == 'youtube') {
        final id = data['videoId'] as String? ?? YoutubePlayerController.convertUrlToId(url);
        if (id == null) throw StateError('رابط يوتيوب غير صالح.');
        final controller = YoutubePlayerController.fromVideoId(
          videoId: id,
          autoPlay: false,
          params: const YoutubePlayerParams(showControls: true, showFullscreenButton: true, strictRelatedVideos: true),
        );
        _youtube = controller;
        _ytSub = controller.listen((value) {
          if (_applyingRemote) return;
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
      if (mounted) setState(() => _error = data['sourceType'] == 'youtube' ? 'تعذر تضمين هذا المقطع. قد يكون خاصاً أو مقيّداً أو أن صاحبه منع التشغيل داخل التطبيقات.' : 'تعذر تشغيل رابط الفيديو المباشر. تأكد من صلاحية الرابط واتصال الإنترنت.');
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
    if (data['controlUid'] == _uid || _loadedUrl != data['url']) return;
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
    if (_applyingRemote || _busy) return;
    _busy = true;
    try {
      final position = await _currentPosition();
      await _watchDb.collection('watchRooms').doc(widget.roomId).update({
        'status': status,
        'positionSeconds': position,
        'updatedAt': FieldValue.serverTimestamp(),
        'controlUid': _uid,
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

  // Embedded players on Android/WebView may block remote autoplay until the
  // viewer performs one local gesture. Unlock once, then remote room sync works.
  Future<void> _enableViewerPlayback() async {
    try {
      if (_isYoutube && _youtube != null) {
        await _youtube!.playVideo();
        await _youtube!.pauseVideo();
      } else if (_video?.value.isInitialized == true) {
        await _video!.play();
        await _video!.pause();
      }
      if (!mounted) return;
      setState(() => _viewerPlaybackUnlocked = true);
      await _applyRemoteState(_room);
    } catch (_) {
      if (mounted) setState(() => _error = 'تعذر تفعيل تشغيل الفيديو على جهازك. جرّب فتح المقطع في YouTube.');
    }
  }

  Future<void> _togglePlayback() async {
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
    final current = await _currentPosition();
    final next = (current + seconds).clamp(0, 864000).toDouble();
    if (_isYoutube && _youtube != null) {
      await _youtube!.seekTo(seconds: next, allowSeekAhead: true);
    } else if (_video?.value.isInitialized == true) {
      await _video!.seekTo(Duration(seconds: next.round()));
    }
    await _publish(_room['status'] == 'playing' ? 'playing' : 'paused');
  }




  bool _isDirectVideoUrl(Uri uri) {
    final p = uri.path.toLowerCase();
    return p.endsWith('.mp4') || p.endsWith('.m3u8') || p.endsWith('.m4v') || p.endsWith('.mov') || p.endsWith('.webm');
  }
  Future<void> _changeRoomUrl() async {
    if (!_isHost) return;
    final input = TextEditingController(text: _room['url'] as String? ?? '');
    String? error;
    final raw = await showDialog<String>(context: context, builder: (c) => StatefulBuilder(builder: (c, refresh) => Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(title: const Text('تغيير الحلقة أو رابط المشاهدة'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('ألصق رابط الحلقة الجديدة أو رابط موقع للمشاهدة.'),
          const SizedBox(height: 10),
          TextField(controller: input, keyboardType: TextInputType.url, decoration: const InputDecoration(hintText: 'https://', border: OutlineInputBorder())),
          if (error != null) Text(error!, style: const TextStyle(color: Colors.red)),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text('إلغاء')),
          FilledButton(onPressed: () {
            final u = Uri.tryParse(input.text.trim());
            if (u == null || !u.hasScheme || !['http','https'].contains(u.scheme)) { refresh(() => error = 'الرابط غير صحيح.'); return; }
            Navigator.pop(c, input.text.trim());
          }, child: const Text('تحديث للجميع')),
        ],
      ),
    )));
    input.dispose();
    if (raw == null) return;
    final uri = Uri.parse(raw);
    final id = YoutubePlayerController.convertUrlToId(raw);
    final type = id != null ? 'youtube' : _isDirectVideoUrl(uri) ? 'direct' : 'web';
    try {
      await _watchDb.collection('watchRooms').doc(widget.roomId).update({
        'url': raw, 'sourceType': type, 'videoId': id,
        'status': 'paused', 'positionSeconds': 0,
        'updatedAt': FieldValue.serverTimestamp(), 'controlUid': _uid,
      });
      if (mounted) setState(() => _error = null);
    } catch (_) { if (mounted) setState(() => _error = 'تعذر تغيير الرابط. تأكد من تحديث قواعد Firestore.'); }
  }
  Future<void> _openRoomWebsite() async {
    final uri = Uri.tryParse(_room['url'] as String? ?? '');
    if (uri != null && uri.hasScheme) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
  Future<void> _setPlaybackSpeed(double speed) async {
    try {
      if (_isYoutube && _youtube != null) { await _youtube!.setPlaybackRate(speed); }
      else if (_video?.value.isInitialized == true) { await _video!.setPlaybackSpeed(speed); }
      if (mounted) setState(() => _playbackSpeed = speed);
    } catch (_) { if (mounted) setState(() => _error = 'مصدر الفيديو لا يدعم تغيير السرعة.'); }
  }
  Future<void> _openFullscreen() async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => _WatchPartyFullscreenPage(
      youtube: _youtube, video: _video, isYoutube: _isYoutube,
      onSeek: _seekBy, onToggle: _togglePlayback, onSpeed: _setPlaybackSpeed, speed: _playbackSpeed,
    )));
  }

  Future<bool> _roomChatIsMuted() async {
    final mute = await _watchDb.collection('watchRooms').doc(widget.roomId).collection('roomMutes').doc(_uid).get();
    final d = mute.data() ?? {};
    if (d['permanent'] == true) return true;
    final until = d['until'];
    return until is Timestamp && until.toDate().isAfter(DateTime.now());
  }

  Future<void> _sendRoomMedia(String type, String url, {int? durationSeconds}) async {
    if (await _roomChatIsMuted()) { if (mounted) setState(() => _error = 'أنت مكتوم من دردشة هذه الغرفة فقط.'); return; }
    final p = await _watchDb.collection('publicProfiles').doc(_uid).get();
    final name = (p.data()?['name'] as String?) ?? FirebaseAuth.instance.currentUser?.displayName ?? 'عضو';
    await _watchDb.collection('watchRooms').doc(widget.roomId).collection('messages').add({
      'senderUid': _uid, 'senderName': name, 'text': type == 'image' ? 'صورة' : 'رسالة صوتية',
      'type': type, 'mediaUrl': url, if (durationSeconds != null) 'durationSeconds': durationSeconds,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _sendRoomImage() async {
    if (_sendingChat) return;
    try {
      if (await _roomChatIsMuted()) { if (mounted) setState(() => _error = 'أنت مكتوم من دردشة هذه الغرفة فقط.'); return; }
      final file = await _roomPicker.pickImage(source: ImageSource.gallery);
      if (file == null) return;
      if (mounted) setState(() { _sendingChat = true; _error = null; });
      final url = await uploadForumMedia(file, folder: 'watch-rooms', roomId: widget.roomId);
      await _sendRoomMedia('image', url);
    } catch (e) { if (mounted) setState(() => _error = 'تعذر إرسال الصورة: $e'); }
    finally { if (mounted) setState(() => _sendingChat = false); }
  }

  Future<void> _toggleRoomVoice() async {
    if (_sendingChat) return;
    if (!_recordingRoomVoice) {
      try {
        if (await _roomChatIsMuted()) { if (mounted) setState(() => _error = 'أنت مكتوم من دردشة هذه الغرفة فقط.'); return; }
        if (!await _roomRecorder.hasPermission()) { if (mounted) setState(() => _error = 'اسمح للتطبيق باستخدام المايك لتسجيل الفويس.'); return; }
        final dir = await Directory.systemTemp.createTemp('watch_room_voice_');
        final path = '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
        await _roomRecorder.start(const RecordConfig(encoder: AudioEncoder.aacLc, bitRate: 64000, sampleRate: 44100), path: path);
        if (mounted) setState(() { _recordingRoomVoice = true; _roomVoiceStarted = DateTime.now(); _roomVoicePath = path; _error = null; });
      } catch (e) { if (mounted) setState(() => _error = 'تعذر بدء تسجيل الفويس: $e'); }
      return;
    }
    try {
      final path = await _roomRecorder.stop();
      final started = _roomVoiceStarted;
      if (mounted) setState(() { _recordingRoomVoice = false; _roomVoiceStarted = null; });
      final fp = path ?? _roomVoicePath;
      if (fp == null || started == null) return;
      final seconds = DateTime.now().difference(started).inSeconds;
      if (seconds < 1 || seconds > 180) { if (mounted) setState(() => _error = 'مدة الفويس لازم تكون بين ثانية و3 دقائق.'); return; }
      final file = File(fp);
      if (!await file.exists() || await file.length() == 0) return;
      if (mounted) setState(() => _sendingChat = true);
      final url = await uploadForumMedia(XFile(fp, name: 'voice_${DateTime.now().millisecondsSinceEpoch}.m4a'), folder: 'watch-rooms', roomId: widget.roomId);
      await _sendRoomMedia('voice', url, durationSeconds: seconds);
      try { await file.delete(); } catch (_) {}
    } catch (e) { if (mounted) setState(() => _error = 'تعذر إرسال الفويس: $e'); }
    finally { if (mounted) setState(() { _sendingChat = false; _recordingRoomVoice = false; }); }
  }

  Future<void> _inviteMoreFriends() async {
    if (!_isHost) return;
    final profiles = await _watchDb.collection('publicProfiles').limit(100).get();
    if (!mounted) return;
    final existing = List<String>.from(_room['invitedUids'] ?? const <String>[]);
    final chosen = <String>{};
    await showModalBottomSheet<void>(context: context, isScrollControlled: true, showDragHandle: true,
      builder: (sheetContext) => StatefulBuilder(builder: (sheetContext, updateSheet) => Directionality(
        textDirection: TextDirection.rtl,
        child: SafeArea(child: SizedBox(height: MediaQuery.of(sheetContext).size.height * .65,
          child: Column(children: [
            const Padding(padding: EdgeInsets.all(14), child: Text('دعوة أصدقاء إلى الغرفة', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
            Expanded(child: ListView(children: profiles.docs.where((p) => p.id != _uid && !existing.contains(p.id)).map((p) {
              final d = p.data(); final selected = chosen.contains(p.id); final photo = (d['photoUrl'] ?? '').toString();
              return CheckboxListTile(value: selected,
                secondary: CircleAvatar(backgroundImage: photo.startsWith('http') ? NetworkImage(photo) : null, child: !photo.startsWith('http') ? const Icon(Icons.person) : null),
                title: Text((d['name'] ?? 'عضو').toString()),
                onChanged: (v) => updateSheet(() { if (v == true) chosen.add(p.id); else chosen.remove(p.id); }));
            }).toList())),
            Padding(padding: const EdgeInsets.all(12), child: FilledButton(onPressed: () => Navigator.pop(sheetContext), child: Text('إرسال الدعوات (${chosen.length})'))),
          ]),
        )),
      )),
    );
    if (chosen.isEmpty) return;
    final updated = <String>{...existing, ...chosen, _uid}.toList();
    try {
      await _watchDb.collection('watchRooms').doc(widget.roomId).update({'invitedUids': updated});
      final me = await _watchDb.collection('publicProfiles').doc(_uid).get();
      final actorName = (me.data()?['name'] ?? FirebaseAuth.instance.currentUser?.displayName ?? 'صديق').toString();
      for (final friendUid in chosen) {
        await _watchDb.collection('notifications').add({'recipientId': friendUid, 'actorId': _uid, 'actorName': actorName,
          'type': 'message', 'text': 'دعاك إلى غرفة مشاهدة: ${_room['name'] ?? 'غرفة مشاهدة'}',
          'read': false, 'targetType': 'watchRoom', 'targetId': widget.roomId, 'createdAt': FieldValue.serverTimestamp()});
      }
      if (mounted) setState(() { _room['invitedUids'] = updated; _error = 'تم إرسال الدعوات بنجاح.'; });
    } catch (_) { if (mounted) setState(() => _error = 'تعذر إرسال الدعوات. تحقق من قواعد Firestore.'); }
  }

  Future<void> _manageRoomMembers() async {
    if (!_isHost && FirebaseAuth.instance.currentUser?.email?.toLowerCase() != 'husinalzerjaoe@gmail.com') return;
    final people = await _watchDb.collection('watchRooms').doc(widget.roomId).collection('participants').get();
    if (!mounted) return;
    await showDialog<void>(context: context, builder: (c) => Directionality(textDirection: TextDirection.rtl, child: AlertDialog(
      title: const Text('إدارة أعضاء الغرفة'),
      content: SizedBox(width: 360, child: ListView(shrinkWrap: true, children: people.docs.where((p) => p.id != _uid).map((p) => ListTile(
        title: Text((p.data()['name'] ?? 'عضو').toString()), subtitle: const Text('كتم دردشة الغرفة فقط'),
        trailing: PopupMenuButton<int>(onSelected: (mins) async {
          final ref = _watchDb.collection('watchRooms').doc(widget.roomId).collection('roomMutes').doc(p.id);
          if (mins == -1) { await ref.delete(); }
          else { await ref.set({'uid': p.id, 'by': _uid, 'permanent': mins == 0, 'until': mins == 0 ? null : Timestamp.fromDate(DateTime.now().add(Duration(minutes: mins))), 'updatedAt': FieldValue.serverTimestamp()}); }
          if (mounted) setState(() => _error = mins == -1 ? 'تم إلغاء الكتم.' : 'تم تطبيق الكتم داخل هذه الغرفة.');
        }, itemBuilder: (_) => const [PopupMenuItem(value: 10, child: Text('10 دقائق')), PopupMenuItem(value: 60, child: Text('ساعة')), PopupMenuItem(value: 1440, child: Text('24 ساعة')), PopupMenuItem(value: 0, child: Text('دائم')), PopupMenuItem(value: -1, child: Text('إلغاء الكتم'))]),
      )).toList())),
      actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text('إغلاق'))],
    )));
  }

  Future<void> _deleteRoom() async {
    if (!_isHost && FirebaseAuth.instance.currentUser?.email?.toLowerCase() != 'husinalzerjaoe@gmail.com') return;
    final yes = await showDialog<bool>(context: context, builder: (c) => Directionality(textDirection: TextDirection.rtl, child: AlertDialog(
      title: const Text('حذف غرفة المشاهدة؟'), content: const Text('ستختفي الغرفة من القائمة ولن يستطيع الأعضاء الدخول إليها.'),
      actions: [TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('إلغاء')), FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('حذف'))],
    )));
    if (yes != true) return;
    await _watchDb.collection('watchRooms').doc(widget.roomId).update({'active': false, 'status': 'paused'});
    if (mounted) Navigator.pop(context);
  }

  Future<void> _sendRoomMessage() async {
    final text = _chatText.text.trim();
    if (text.isEmpty || _sendingChat) return;
    if (await _roomChatIsMuted()) { if (mounted) setState(() => _error = 'أنت مكتوم من دردشة هذه الغرفة فقط.'); return; }
    setState(() => _sendingChat = true);
    try {
      final profile = await _watchDb.collection('publicProfiles').doc(_uid).get();
      final name = (profile.data()?['name'] as String?) ??
          FirebaseAuth.instance.currentUser?.displayName ?? 'عضو';
      await _watchDb.collection('watchRooms').doc(widget.roomId)
          .collection('messages').add({
        'senderUid': _uid,
        'senderName': name,
        'type': 'text',
        'text': text,
        'createdAt': FieldValue.serverTimestamp(),
      });
      _chatText.clear();
    } catch (_) {
      if (mounted) setState(() => _error = 'تعذر إرسال رسالة الغرفة. تأكد من نشر قواعد Firestore المحدّثة.');
    } finally {
      if (mounted) setState(() => _sendingChat = false);
    }
  }

  @override
  void dispose() {
    _syncTimer?.cancel();
    _roomSub?.cancel();
    _chatText.dispose();
    _roomRecorder.dispose();
    _roomVoicePlayer.dispose();
    _watchDb.collection('watchRooms').doc(widget.roomId).collection('participants').doc(_uid).delete().catchError((_) {});
    _ytSub?.cancel();
    _youtube?.close();
    _video?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.rtl,
    child: Scaffold(
      appBar: AppBar(title: Text(_room['name'] as String? ?? 'غرفة مشاهدة'), actions: [if (_isHost) IconButton(tooltip: 'دعوة أصدقاء', onPressed: _inviteMoreFriends, icon: const Icon(Icons.group_add)), if (_isHost) IconButton(tooltip: 'تغيير رابط الحلقة', onPressed: _changeRoomUrl, icon: const Icon(Icons.link)), if (_isHost || FirebaseAuth.instance.currentUser?.email?.toLowerCase() == 'husinalzerjaoe@gmail.com') PopupMenuButton<String>(onSelected: (v) { if (v == 'members') _manageRoomMembers(); if (v == 'delete') _deleteRoom(); }, itemBuilder: (_) => const [PopupMenuItem(value: 'members', child: Text('إدارة الأعضاء والكتم')), PopupMenuItem(value: 'delete', child: Text('حذف الغرفة'))])]),
      body: !_roomReady ? const Center(child: CircularProgressIndicator()) : ListView(padding: const EdgeInsets.all(12), children: [
        if (_error != null) Card(
          color: Theme.of(context).colorScheme.errorContainer,
          child: Padding(padding: const EdgeInsets.all(12), child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(_error!),
              if (_isYoutube && (_room['url'] as String? ?? '').isNotEmpty)
                Align(alignment: AlignmentDirectional.centerStart, child: TextButton.icon(
                  onPressed: () async {
                    final uri = Uri.tryParse(_room['url'] as String? ?? '');
                    if (uri != null) await launchUrl(uri, mode: LaunchMode.externalApplication);
                  },
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('فتح المقطع في تطبيق YouTube'),
                )),
            ],
          )),
        ),
        if (_room['sourceType'] == 'web') Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(children: [const Icon(Icons.public, size: 42), const Text('موقع مشاهدة خارجي'), const SizedBox(height: 8), const Text('افتحوا الموقع على أجهزتكم. بعض المواقع لا تسمح بالمزامنة داخل التطبيقات.'), FilledButton.icon(onPressed: _openRoomWebsite, icon: const Icon(Icons.open_in_browser), label: const Text('فتح الموقع'))]))),
        if (_room['sourceType'] != 'web') Stack(children: [
          if (_youtube != null) YoutubePlayer(controller: _youtube!, aspectRatio: 16 / 9)
          else if (_video?.value.isInitialized == true)
            AspectRatio(aspectRatio: _video!.value.aspectRatio, child: VideoPlayer(_video!))
          else const AspectRatio(aspectRatio: 16 / 9, child: Center(child: CircularProgressIndicator())),
          Positioned(top: 8, left: 8, child: IconButton.filled(onPressed: _openFullscreen, tooltip: 'ملء الشاشة', icon: const Icon(Icons.fullscreen))),
          if (!_isHost && !_viewerPlaybackUnlocked && (_youtube != null || _video?.value.isInitialized == true))
            Positioned.fill(child: Material(
              color: Colors.black54,
              child: Center(child: FilledButton.icon(
                onPressed: _enableViewerPlayback,
                icon: const Icon(Icons.touch_app_rounded),
                label: const Text('اضغط لتفعيل المشاهدة المتزامنة'),
              )),
            )),
        ]),
        const SizedBox(height: 12),
        if (_room['sourceType'] == 'web') Align(alignment: AlignmentDirectional.centerStart, child: TextButton.icon(onPressed: _isHost ? _changeRoomUrl : null, icon: const Icon(Icons.link), label: const Text('تغيير رابط الموقع'))),
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _watchDb.collection('watchRooms').doc(widget.roomId).collection('participants').snapshots(),
          builder: (context, snapshot) {
            final people = snapshot.data?.docs ?? [];
            return Card(child: Padding(padding: const EdgeInsets.all(12), child: Row(children: [
              const Icon(Icons.groups_rounded, color: _watchBrand),
              const SizedBox(width: 8),
              Text('المشاهدون (' + people.length.toString() + ')', style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(width: 10),
              Expanded(child: SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: people.map((person) {
                final d = person.data();
                final photo = d['photoUrl'] as String? ?? '';
                final name = d['name'] as String? ?? 'عضو';
                return Padding(
                  padding: const EdgeInsetsDirectional.only(end: 9),
                  child: Tooltip(
                    message: name,
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      CircleAvatar(
                        radius: 19,
                        backgroundColor: _watchBrand.withValues(alpha: .12),
                        backgroundImage: photo.startsWith('https://') ? NetworkImage(photo) : null,
                        child: photo.startsWith('https://') ? null : Text(name.isEmpty ? '؟' : name.characters.first),
                      ),
                      const SizedBox(width: 5),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 88),
                        child: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      ),
                    ]),
                  ),
                );
              }).toList()))),
            ])));
          },
        ),
        Card(child: Padding(padding: const EdgeInsets.all(12), child: Column(children: [
          Row(children: [
            Icon(_room['status'] == 'playing' ? Icons.play_circle : Icons.pause_circle, color: _watchBrand),
            const SizedBox(width: 8),
            Expanded(child: Text(_isHost ? 'أنت مضيف الغرفة — تحكم بالتشغيل للجميع' : 'مشاهدة متزامنة مع المضيف', style: const TextStyle(fontWeight: FontWeight.bold))),
          ]),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            IconButton(onPressed: () => _seekBy(-30), icon: const Icon(Icons.replay_30), tooltip: 'رجوع 30 ثانية'),
            IconButton(onPressed: () => _seekBy(-10), icon: const Icon(Icons.replay_10), tooltip: 'رجوع 10 ثوانٍ'),
            FilledButton.icon(onPressed: _togglePlayback, icon: Icon(_room['status'] == 'playing' ? Icons.pause : Icons.play_arrow), label: Text(_room['status'] == 'playing' ? 'إيقاف مؤقت' : 'تشغيل للجميع')),
            IconButton(onPressed: () => _seekBy(10), icon: const Icon(Icons.forward_10), tooltip: 'تقديم 10 ثوانٍ'),
            IconButton(onPressed: () => _seekBy(30), icon: const Icon(Icons.forward_30), tooltip: 'تقديم 30 ثانية'),
           ]),
          const Padding(padding: EdgeInsets.only(top: 4), child: Text('التحكم بالتشغيل والتقديم متاح لكل أعضاء الغرفة.', style: TextStyle(fontSize: 11))),
          const SizedBox(height: 8),
          Wrap(alignment: WrapAlignment.center, spacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [const Text('سرعة التشغيل'), DropdownButton<double>(value: _playbackSpeed, items: const [0.5, 0.75, 1.0, 1.25, 1.5, 2.0].map((v) => DropdownMenuItem(value: v, child: Text('${v}x'))).toList(), onChanged: (v) { if (v != null) _setPlaybackSpeed(v); }), if (_isHost) TextButton.icon(onPressed: _changeRoomUrl, icon: const Icon(Icons.swap_horiz), label: const Text('الحلقة التالية'))]),
        ]))),
        const SizedBox(height: 8),
        Card(child: Padding(padding: const EdgeInsets.all(12), child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Row(children: [
              Icon(Icons.forum_rounded, color: _watchBrand),
              SizedBox(width: 8),
              Text('دردشة غرفة المشاهدة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ]),
            const SizedBox(height: 8),
            SizedBox(height: 280, child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _watchDb.collection('watchRooms').doc(widget.roomId)
                  .collection('messages').orderBy('createdAt', descending: true).limit(60).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) return const Center(child: Text('تعذر تحميل دردشة الغرفة.'));
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final messages = snapshot.data!.docs;
                if (messages.isEmpty) return const Center(child: Text('ابدأوا الحديث أثناء المشاهدة 🎬'));
                return ListView.builder(
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final item = messages[index].data();
                    final mine = item['senderUid'] == _uid;
                    return Align(
                      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 7),
                        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
                        constraints: const BoxConstraints(maxWidth: 280),
                        decoration: BoxDecoration(
                          color: mine ? Theme.of(context).colorScheme.primaryContainer : Theme.of(context).colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          if (!mine) Text(item['senderName'] as String? ?? 'عضو',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                          if (item['type'] == 'image' && (item['mediaUrl'] as String? ?? '').startsWith('https://')) ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.network(item['mediaUrl'] as String, width: 210, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Text('تعذر عرض الصورة')))
                          else if (item['type'] == 'voice' && (item['mediaUrl'] as String? ?? '').startsWith('https://')) Row(mainAxisSize: MainAxisSize.min, children: [IconButton(onPressed: () async { try { await _roomVoicePlayer.setUrl(item['mediaUrl'] as String); await _roomVoicePlayer.play(); } catch (_) { if (mounted) setState(() => _error = 'تعذر تشغيل الفويس.'); } }, icon: const Icon(Icons.play_circle_fill)), Text('فويس • ${item['durationSeconds'] ?? 0} ث')])
                          else Text(item['text'] as String? ?? ''),
                        ]),
                      ),
                    );
                  },
                );
              },
            )),
            const SizedBox(height: 8),
            Row(children: [
              IconButton(tooltip: 'إرسال صورة', onPressed: _sendingChat ? null : _sendRoomImage, icon: const Icon(Icons.image_outlined)),
              IconButton(tooltip: _recordingRoomVoice ? 'إيقاف وإرسال الفويس' : 'تسجيل فويس', onPressed: _sendingChat ? null : _toggleRoomVoice, color: _recordingRoomVoice ? Colors.red : null, icon: Icon(_recordingRoomVoice ? Icons.stop_circle : Icons.mic)),
              Expanded(child: TextField(
                controller: _chatText,
                minLines: 1,
                maxLines: 3,
                maxLength: 500,
                decoration: const InputDecoration(hintText: 'اكتب رسالة لأعضاء الغرفة...', counterText: '', border: OutlineInputBorder()),
                onSubmitted: (_) => _sendRoomMessage(),
              )),
              const SizedBox(width: 8),
              IconButton.filled(
                tooltip: 'إرسال الرسالة',
                onPressed: _sendingChat ? null : _sendRoomMessage,
                icon: _sendingChat
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.send_rounded),
              ),
            ]),
          ],
        ))),
        const Padding(padding: EdgeInsets.all(8), child: Text('ملاحظة: المزامنة تعتمد على سرعة الإنترنت، وقد يظهر فرق بسيط بين الأجهزة. بعض مقاطع YouTube تمنع التضمين، وروابط البث يجب أن تكون مباشرة ومصرّحاً بمشاركتها.', style: TextStyle(fontSize: 12))),
      ]),
    ),
  );
}


class _WatchPartyFullscreenPage extends StatefulWidget {
  final YoutubePlayerController? youtube;
  final VideoPlayerController? video;
  final bool isYoutube;
  final Future<void> Function(int) onSeek;
  final Future<void> Function() onToggle;
  final Future<void> Function(double) onSpeed;
  final double speed;
  const _WatchPartyFullscreenPage({required this.youtube, required this.video, required this.isYoutube, required this.onSeek, required this.onToggle, required this.onSpeed, required this.speed});
  @override State<_WatchPartyFullscreenPage> createState() => _WatchPartyFullscreenPageState();
}
class _WatchPartyFullscreenPageState extends State<_WatchPartyFullscreenPage> {
  @override
  void initState() { super.initState(); SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky); SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]); }
  @override
  void dispose() { SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge); SystemChrome.setPreferredOrientations(DeviceOrientation.values); super.dispose(); }
  @override
  Widget build(BuildContext context) => Scaffold(backgroundColor: Colors.black, body: SafeArea(child: Stack(children: [
    Positioned.fill(child: Center(child: widget.isYoutube && widget.youtube != null ? YoutubePlayer(controller: widget.youtube!, aspectRatio: 16/9) : widget.video?.value.isInitialized == true ? AspectRatio(aspectRatio: widget.video!.value.aspectRatio, child: VideoPlayer(widget.video!)) : const CircularProgressIndicator())),
    Positioned(top: 8, right: 8, child: IconButton.filledTonal(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.fullscreen_exit), tooltip: 'إغلاق ملء الشاشة')),
    Positioned(bottom: 12, left: 12, right: 12, child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      IconButton.filledTonal(onPressed: () => widget.onSeek(-30), icon: const Icon(Icons.replay_30)),
      IconButton.filled(onPressed: widget.onToggle, icon: const Icon(Icons.play_arrow)),
      IconButton.filledTonal(onPressed: () => widget.onSeek(30), icon: const Icon(Icons.forward_30)),
      const SizedBox(width: 14),
      DropdownButton<double>(value: widget.speed, dropdownColor: Colors.black87, style: const TextStyle(color: Colors.white), items: const [0.5,0.75,1.0,1.25,1.5,2.0].map((v) => DropdownMenuItem(value:v, child: Text('${v}x'))).toList(), onChanged: (v) { if(v!=null) widget.onSpeed(v); }),
    ])),
  ])));
}
