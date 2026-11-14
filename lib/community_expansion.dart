import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:webview_flutter/webview_flutter.dart';

const _interestNames = ['الأنمي والمانغا', 'كرة القدم', 'الشعر والأدب', 'الألعاب', 'التقنية', 'التصوير والفن'];
const _interestIcons = [Icons.movie_filter_outlined, Icons.sports_soccer, Icons.menu_book_outlined, Icons.sports_esports_outlined, Icons.memory_outlined, Icons.palette_outlined];

class CommunityExpansionPage extends StatelessWidget {
  const CommunityExpansionPage({super.key});
  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.rtl,
    child: DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(title: const Text('مجتمعنا وفعالياتنا'), bottom: const TabBar(isScrollable: true, tabs: [
          Tab(icon: Icon(Icons.stadium_outlined), text: 'استاد الأصدقاء'),
          Tab(icon: Icon(Icons.event_available_outlined), text: 'الفعاليات'),
          Tab(icon: Icon(Icons.question_answer_outlined), text: 'صندوق المجتمع'),
          Tab(icon: Icon(Icons.groups_2_outlined), text: 'المجتمعات'),
        ])),
        body: const TabBarView(children: [WatchPartiesPage(), CommunityEventsPage(), CommunityQuestionPage(), CommunityDirectoryPage()]),
      ),
    ),
  );
}

class WatchPartiesPage extends StatefulWidget {
  const WatchPartiesPage({super.key});
  @override
  State<WatchPartiesPage> createState() => _WatchPartiesPageState();
}
class _WatchPartiesPageState extends State<WatchPartiesPage> {
  final db = FirebaseFirestore.instance;
  String get uid => FirebaseAuth.instance.currentUser!.uid;
  Future<void> joinParty() async {
    final code = TextEditingController();
    final ok = await showDialog<bool>(context: context, builder: (ctx) => Directionality(textDirection: TextDirection.rtl, child: AlertDialog(
      title: const Text('الانضمام إلى جلسة'),
      content: TextField(controller: code, autofocus: true, decoration: const InputDecoration(labelText: 'رمز الجلسة', hintText: 'الصق الرمز الذي أرسله صديقك')),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')), FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('انضمام'))],
    )));
    if (ok != true) { code.dispose(); return; }
    try {
      final ref = db.collection('watchParties').doc(code.text.trim());
      final snapshot = await ref.get();
      if (!snapshot.exists || snapshot.data()?['status'] != 'open') throw Exception('رمز الجلسة غير صحيح أو انتهت');
      final data = snapshot.data()!;
      final members = List<String>.from(data['members'] ?? []);
      if (!members.contains(uid)) await ref.update({'members': FieldValue.arrayUnion([uid])});
      if (mounted) Navigator.push(context, MaterialPageRoute(builder: (_) => WatchPartyRoomPage(partyId: snapshot.id, party: {...data, 'members': {...members, uid}.toList()})));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تعذر الانضمام: $e')));
    } finally { code.dispose(); }
  }
  Future<void> createParty() async {
    final title = TextEditingController();
    final match = TextEditingController();
    final stream = TextEditingController();
    final form = GlobalKey<FormState>();
    final ok = await showDialog<bool>(context: context, builder: (ctx) => Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(title: const Text('إنشاء جلسة مشاهدة'),
        content: Form(key: form, child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextFormField(controller: title, maxLength: 60, decoration: const InputDecoration(labelText: 'اسم الجلسة'), validator: (v) => v == null || v.trim().length < 3 ? 'اكتب اسماً من 3 أحرف' : null),
          TextFormField(controller: match, maxLength: 100, decoration: const InputDecoration(labelText: 'المباراة')),
          TextFormField(controller: stream, keyboardType: TextInputType.url, decoration: const InputDecoration(labelText: 'رابط يوتيوب أو فيديو أو موقع', hintText: 'https://youtu.be/... أو رابط MP4 / M3U8 / موقع'), validator: (v) { final u = Uri.tryParse((v ?? '').trim()); return u == null || u.scheme != 'https' || u.host.isEmpty ? 'أدخل رابط HTTPS صالحاً' : null; }),
          const Text('يدعم روابط يوتيوب داخل مشغّل مضمّن، وصفحات الويب التي تسمح بالتشغيل داخل WebView، وملفات MP4 وHLS. بعض المواقع تمنع التضمين أو تتطلب تطبيقها أو اشتراكاً، ولا يمكن تجاوز DRM.', style: TextStyle(fontSize: 12, color: Colors.grey)),
        ]))),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')), FilledButton(onPressed: () { if (form.currentState?.validate() ?? false) Navigator.pop(ctx, true); }, child: const Text('إنشاء'))],
      ),
    ));
    if (ok == true) {
      try {
        await db.collection('watchParties').add({
          'title': title.text.trim(), 'match': match.text.trim().isEmpty ? title.text.trim() : match.text.trim(),
          'streamUrl': stream.text.trim(), 'hostId': uid, 'members': [uid],
        'playbackPlaying': false, 'playbackPositionMs': 0, 'playbackUpdatedBy': uid,
          'createdAt': FieldValue.serverTimestamp(), 'status': 'open',
        });
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إنشاء جلسة المشاهدة')));
      } catch (_) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تعذر الإنشاء. انشر قواعد Firestore أولاً.')));
      }
    }
    title.dispose(); match.dispose(); stream.dispose();
  }
  @override
  Widget build(BuildContext context) => Scaffold(
    floatingActionButton: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.end, children: [
      FloatingActionButton.extended(heroTag: 'join_watch_party', onPressed: joinParty, icon: const Icon(Icons.group_add), label: const Text('انضم برمز')),
      const SizedBox(height: 10),
      FloatingActionButton.extended(heroTag: 'create_watch_party', onPressed: createParty, icon: const Icon(Icons.add), label: const Text('جلسة جديدة')),
    ]),
    body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: db.collection('watchParties').where('status', isEqualTo: 'open').limit(50).snapshots(),
      builder: (context, s) {
        if (s.hasError) return const Center(child: Text('تعذر تحميل الجلسات. تحقق من قواعد Firestore.'));
        if (!s.hasData) return const Center(child: CircularProgressIndicator());
        if (s.data!.docs.isEmpty) return const _EmptyCommunity(icon: Icons.stadium_outlined, text: 'ماكو جلسات حالياً. أنشئ جلسة وادعُ أصدقاءك.');
        return ListView(padding: const EdgeInsets.all(12), children: [
          const Card(child: Padding(padding: EdgeInsets.all(14), child: Text('⚽ اجتمعوا على المباراة، افتحوا البث المرخّص، وتناقشوا مباشرة داخل غرفة الجلسة.'))),
          ...s.data!.docs.map((d) => Card(child: ListTile(
            leading: const CircleAvatar(child: Icon(Icons.live_tv_rounded)),
            title: Text(d.data()['title'] ?? 'جلسة مشاهدة'),
            subtitle: Text((d.data()['match'] ?? '') + ' • ' + (List<String>.from(d.data()['members'] ?? []).length.toString()) + ' مشارك'),
            trailing: const Icon(Icons.chevron_left),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => WatchPartyRoomPage(partyId: d.id, party: d.data()))),
          ))),
        ]);
      },
    ),
  );
}

class WatchPartyRoomPage extends StatefulWidget {
  const WatchPartyRoomPage({super.key, required this.partyId, required this.party});
  final String partyId;
  final Map<String, dynamic> party;
  @override
  State<WatchPartyRoomPage> createState() => _WatchPartyRoomPageState();
}
class _WatchPartyRoomPageState extends State<WatchPartyRoomPage> {
  final db = FirebaseFirestore.instance;
  final message = TextEditingController();
  bool busy = false;
  VideoPlayerController? _videoController;
  WebViewController? _webController;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _playbackSubscription;
  bool _usingWebView = false;
  bool _isYouTube = false;
  bool _videoLoading = true;
  bool _applyingRemotePlayback = false;
  String? _videoError;
  String get uid => FirebaseAuth.instance.currentUser!.uid;
  DocumentReference<Map<String, dynamic>> get party => db.collection('watchParties').doc(widget.partyId);
  @override
  void initState() {
    super.initState();
    party.update({'members': FieldValue.arrayUnion([uid])}).catchError((_) {});
    _initializeVideo();
    _playbackSubscription = party.snapshots().listen(_applyRemotePlayback);
  }
  String? _youtubeId(Uri uri) {
    final host = uri.host.toLowerCase();
    String? id;
    if (host == 'youtu.be' || host.endsWith('.youtu.be')) {
      id = uri.pathSegments.isEmpty ? null : uri.pathSegments.first;
    } else if (host.contains('youtube.com') || host.contains('youtube-nocookie.com')) {
      id = uri.queryParameters['v'];
      if (id == null && uri.pathSegments.length >= 2 &&
          ['embed', 'shorts', 'live'].contains(uri.pathSegments.first)) {
        id = uri.pathSegments[1];
      }
    }
    return id != null && id.length >= 6 && RegExp(r'^[A-Za-z0-9_-]+$').hasMatch(id) ? id : null;
  }

  bool _isDirectVideo(Uri uri) {
    final path = uri.path.toLowerCase();
    return path.endsWith('.mp4') || path.endsWith('.m4v') ||
        path.endsWith('.mov') || path.endsWith('.webm') || path.endsWith('.m3u8');
  }

  Future<void> _openWebSource(Uri uri, {String? youtubeId}) async {
    final target = uri;
    final controller = WebViewController();
    await controller.setJavaScriptMode(JavaScriptMode.unrestricted);
    await controller.setBackgroundColor(Colors.black);
    await controller.setNavigationDelegate(NavigationDelegate(
      onPageFinished: (_) async {
        try {
          await _applyRemotePlayback(await party.get());
        } catch (_) {}
      },
    ));
    if (!mounted) return;
    setState(() {
      _webController = controller;
      _usingWebView = true;
      _isYouTube = youtubeId != null;
      _videoLoading = false;
      _videoError = null;
    });
    if (youtubeId != null) {
      await controller.loadHtmlString(
        '''<!doctype html>
<html><head><meta name="viewport" content="width=device-width,initial-scale=1,maximum-scale=1">
<style>html,body,#player{margin:0;width:100%;height:100%;background:#000;overflow:hidden}iframe{width:100%;height:100%;border:0}</style>
</head><body><div id="player"></div>
<script>
var player;
function onYouTubeIframeAPIReady(){
 player=new YT.Player('player',{videoId:'$youtubeId',playerVars:{playsinline:1,rel:0,enablejsapi:1}});
}
</script><script src="https://www.youtube.com/iframe_api"></script></body></html>''',
        baseUrl: 'https://www.youtube.com',
      );
    } else {
      await controller.loadRequest(target);
    }
  }

  Future<void> _initializeVideo() async {
    final raw = (widget.party['streamUrl'] as String? ?? '').trim();
    final uri = Uri.tryParse(raw);
    if (uri == null || !['https', 'http'].contains(uri.scheme) || uri.host.isEmpty) {
      if (mounted) {
        setState(() {
          _videoLoading = false;
          _videoError = 'الرابط غير صالح. استخدم رابط https صالحاً.';
        });
      }
      return;
    }

    final youtubeId = _youtubeId(uri);
    if (youtubeId != null || !_isDirectVideo(uri)) {
      try {
        await _openWebSource(uri, youtubeId: youtubeId);
      } catch (e) {
        if (mounted) setState(() {
          _videoLoading = false;
          _videoError = 'تعذر فتح صفحة الفيديو داخل التطبيق: ' + e.toString();
        });
      }
      return;
    }

    final controller = VideoPlayerController.networkUrl(uri);
    _videoController = controller;
    try {
      await controller.initialize().timeout(const Duration(seconds: 35));
      await controller.setLooping(false);
      if (mounted) setState(() {
        _videoLoading = false;
        _videoError = null;
      });
      try {
        await _applyRemotePlayback(await party.get());
      } catch (_) {}
    } catch (e) {
      final description = controller.value.errorDescription;
      await controller.dispose();
      if (identical(_videoController, controller)) _videoController = null;
      try {
        await _openWebSource(uri);
      } catch (_) {
        if (mounted) setState(() {
          _videoLoading = false;
          _videoError = 'تعذر تشغيل الرابط: ' + (description ?? e.toString()) +
              '. جرّب رابط فيديو مباشر أو صفحة تسمح بالتضمين.';
        });
      }
    }
  }

  Future<void> _applyRemotePlayback(DocumentSnapshot<Map<String, dynamic>> snapshot) async {
    final data = snapshot.data();
    if (data == null || data['playbackUpdatedBy'] == uid || _applyingRemotePlayback) return;
    final playing = data['playbackPlaying'] == true;
    final position = (data['playbackPositionMs'] as num?)?.toInt() ?? 0;
    _applyingRemotePlayback = true;
    try {
      if (_usingWebView && _webController != null) {
        final seconds = (position / 1000).toStringAsFixed(2);
        if (_isYouTube) {
          await _webController!.runJavaScript("if(window.player){if($position>0)window.player.seekTo($seconds,true);if($playing)window.player.playVideo();else window.player.pauseVideo();}");
        } else {
          await _webController!.runJavaScript("(function(){var v=document.querySelector('video');if(v){if($position>0&&Math.abs(v.currentTime-$seconds)>2)v.currentTime=$seconds;if($playing){v.play().catch(function(){});}else{v.pause();}}})();");
        }
      } else if (_videoController?.value.isInitialized == true) {
        final current = _videoController!.value.position.inMilliseconds;
        if ((current - position).abs() > 2200) await _videoController!.seekTo(Duration(milliseconds: position));
        if (playing && !_videoController!.value.isPlaying) await _videoController!.play();
        if (!playing && _videoController!.value.isPlaying) await _videoController!.pause();
        if (mounted) setState(() {});
      }
    } catch (_) {} finally { _applyingRemotePlayback = false; }
  }
  Future<void> _publishPlayback(bool playing) async {
    var position = 0;
    if (_videoController?.value.isInitialized == true) position = _videoController!.value.position.inMilliseconds;
    try {
      if (_usingWebView && _webController != null) {
        if (_isYouTube) {
          final raw = await _webController!.runJavaScriptReturningResult('window.player ? window.player.getCurrentTime() : 0');
          final seconds = double.tryParse(raw.toString().replaceAll('"', '')) ?? 0;
          position = (seconds * 1000).round();
          await _webController!.runJavaScript('if(window.player){if($playing)window.player.playVideo();else window.player.pauseVideo();}');
        } else {
          await _webController!.runJavaScript("(function(){var v=document.querySelector('video');if(v){if($playing)v.play().catch(function(){});else v.pause();}})();");
        }
      } else if (_videoController?.value.isInitialized == true) {
        if (playing) await _videoController!.play(); else await _videoController!.pause();
      }
      if (mounted) setState(() {});
      await party.update({'playbackPlaying': playing, 'playbackPositionMs': position, 'playbackUpdatedAt': FieldValue.serverTimestamp(), 'playbackUpdatedBy': uid});
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('التشغيل المحلي يعمل، لكن مزامنة الأصدقاء تحتاج نشر قواعد Firestore المحدّثة: $e')));
    }
  }
  Future<void> _seekBy(int seconds) async {
    if (_usingWebView && _webController != null) {
      if (_isYouTube) {
        await _webController!.runJavaScript('if(window.player){window.player.seekTo(Math.max(0,window.player.getCurrentTime()+$seconds),true);}');
      } else {
        await _webController!.runJavaScript("(function(){var v=document.querySelector('video');if(v)v.currentTime=Math.max(0,v.currentTime+$seconds);})();");
      }
      return;
    }
    final controller = _videoController;
    if (controller == null || !controller.value.isInitialized) return;
    final next = controller.value.position + Duration(seconds: seconds);
    await controller.seekTo(next < Duration.zero ? Duration.zero : next);
    final position = controller.value.position.inMilliseconds;
    try { await party.update({'playbackPositionMs': position, 'playbackUpdatedAt': FieldValue.serverTimestamp(), 'playbackUpdatedBy': uid}); } catch (_) {}
  }
  @override
  void dispose() { _playbackSubscription?.cancel(); message.dispose(); _videoController?.dispose(); super.dispose(); }
  Future<void> send() async {
    final value = message.text.trim();
    if (value.isEmpty || busy) return;
    setState(() => busy = true);
    try {
      await party.collection('messages').add({
        'senderId': uid, 'senderName': FirebaseAuth.instance.currentUser?.displayName ?? 'عضو',
        'text': value, 'createdAt': FieldValue.serverTimestamp(),
      });
      message.clear();
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تعذر إرسال الرسالة.')));
    } finally { if (mounted) setState(() => busy = false); }
  }
  @override
  Widget build(BuildContext context) => Directionality(textDirection: TextDirection.rtl, child: Scaffold(
    appBar: AppBar(title: Text(widget.party['title'] ?? 'استاد الأصدقاء'), actions: [
      IconButton(tooltip: 'نسخ رمز الجلسة', icon: const Icon(Icons.copy), onPressed: () {
        Clipboard.setData(ClipboardData(text: widget.partyId));
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم نسخ رمز الجلسة')));
      }),
    ]),
    body: Column(children: [
      Card(margin: const EdgeInsets.fromLTRB(12, 12, 12, 6), clipBehavior: Clip.antiAlias, child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Padding(padding: const EdgeInsets.fromLTRB(14, 12, 14, 8), child: Text(widget.party['match'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
        AspectRatio(aspectRatio: 16 / 9, child: Container(color: Colors.black, alignment: Alignment.center, child: _videoLoading
          ? const CircularProgressIndicator(color: Colors.white)
          : _videoError != null
            ? Padding(padding: const EdgeInsets.all(16), child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text(_videoError!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white)),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: _videoLoading ? null : () {
                    final oldController = _videoController;
                    setState(() { _videoLoading = true; _videoError = null; _videoController = null; });
                    oldController?.dispose();
                    _initializeVideo();
                  },
                  icon: const Icon(Icons.refresh), label: const Text('إعادة المحاولة'),
                ),
              ]))
            : _usingWebView && _webController != null
              ? WebViewWidget(controller: _webController!)
            : _videoController != null && _videoController!.value.isInitialized
              ? Stack(alignment: Alignment.bottomCenter, children: [
                  Center(child: AspectRatio(aspectRatio: _videoController!.value.aspectRatio, child: VideoPlayer(_videoController!))),
                  VideoProgressIndicator(_videoController!, allowScrubbing: true, padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12), colors: const VideoProgressColors(playedColor: Colors.deepPurpleAccent, bufferedColor: Colors.white54, backgroundColor: Colors.white24)),
                  Positioned(right: 8, bottom: 12, child: IconButton.filledTonal(onPressed: () => _publishPlayback(!_videoController!.value.isPlaying), icon: Icon(_videoController!.value.isPlaying ? Icons.pause : Icons.play_arrow))),
                ])
              : const Text('البث غير متاح حالياً', style: TextStyle(color: Colors.white)))),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), child: Row(children: [
          IconButton(tooltip: 'رجوع 10 ثوانٍ', onPressed: () => _seekBy(-10), icon: const Icon(Icons.replay_10)),
          IconButton(tooltip: 'تشغيل أو إيقاف للجميع', onPressed: () => _publishPlayback(!(_videoController?.value.isPlaying ?? false)), icon: const Icon(Icons.sync)),
          IconButton(tooltip: 'تقديم 10 ثوانٍ', onPressed: () => _seekBy(10), icon: const Icon(Icons.forward_10)),
          const Expanded(child: Text('أزرار المزامنة ترسل التشغيل والإيقاف والتقديم إلى أعضاء الغرفة', style: TextStyle(fontSize: 11), textAlign: TextAlign.center)),
        ])),

      ])),
      Expanded(child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: party.collection('messages').orderBy('createdAt').limit(200).snapshots(),
        builder: (context, s) {
          if (s.hasError) return const Center(child: Text('تعذر تحميل دردشة الجلسة.'));
          if (!s.hasData) return const Center(child: CircularProgressIndicator());
          final docs = s.data!.docs;
          return ListView.builder(reverse: true, padding: const EdgeInsets.all(12), itemCount: docs.length, itemBuilder: (context, i) {
            final item = docs[docs.length - 1 - i].data();
            final mine = item['senderId'] == uid;
            return Align(alignment: mine ? Alignment.centerRight : Alignment.centerLeft, child: Container(
              margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(11),
              constraints: const BoxConstraints(maxWidth: 310),
              decoration: BoxDecoration(color: mine ? Theme.of(context).colorScheme.primaryContainer : Theme.of(context).colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(14)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                if (!mine) Text(item['senderName'] ?? 'عضو', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                Text(item['text'] ?? ''),
              ]),
            ));
          });
        },
      )),
      SafeArea(child: Padding(padding: const EdgeInsets.all(10), child: Row(children: [
        Expanded(child: TextField(controller: message, maxLength: 500, decoration: const InputDecoration(hintText: 'اكتب تعليقك على المباراة...', counterText: '', border: OutlineInputBorder()))),
        const SizedBox(width: 8),
        IconButton.filled(onPressed: busy ? null : send, icon: const Icon(Icons.send)),
      ]))),
    ]),
  ));
}

class CommunityEventsPage extends StatefulWidget {
  const CommunityEventsPage({super.key});
  @override
  State<CommunityEventsPage> createState() => _CommunityEventsPageState();
}
class _CommunityEventsPageState extends State<CommunityEventsPage> {
  final db = FirebaseFirestore.instance;
  String get uid => FirebaseAuth.instance.currentUser!.uid;
  Future<void> createEvent() async {
    final title = TextEditingController();
    final details = TextEditingController();
    DateTime when = DateTime.now().add(const Duration(days: 1));
    final ok = await showDialog<bool>(context: context, builder: (ctx) => Directionality(textDirection: TextDirection.rtl, child: StatefulBuilder(builder: (ctx, setD) => AlertDialog(
      title: const Text('إضافة فعالية'),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: title, maxLength: 80, decoration: const InputDecoration(labelText: 'عنوان الفعالية')),
        TextField(controller: details, maxLength: 500, maxLines: 3, decoration: const InputDecoration(labelText: 'التفاصيل')),
        OutlinedButton.icon(icon: const Icon(Icons.calendar_month), label: Text(when.year.toString() + '/' + when.month.toString() + '/' + when.day.toString()), onPressed: () async {
          final date = await showDatePicker(context: ctx, initialDate: when, firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)));
          if (date != null) setD(() => when = date);
        }),
      ])),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')), FilledButton(onPressed: () => Navigator.pop(ctx, title.text.trim().length >= 3), child: const Text('نشر'))],
    ))));
    if (ok == true) {
      try {
        await db.collection('communityEvents').add({
          'title': title.text.trim(), 'details': details.text.trim(), 'startsAt': Timestamp.fromDate(when),
          'createdBy': uid, 'attendees': [uid], 'createdAt': FieldValue.serverTimestamp(),
        });
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم نشر الفعالية')));
      } catch (_) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تعذر النشر. تحقق من قواعد Firestore.')));
      }
    }
    title.dispose(); details.dispose();
  }
  @override
  Widget build(BuildContext context) => Scaffold(
    floatingActionButton: FloatingActionButton.extended(onPressed: createEvent, icon: const Icon(Icons.add), label: const Text('فعالية جديدة')),
    body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: db.collection('communityEvents').orderBy('startsAt').limit(60).snapshots(),
      builder: (context, s) {
        if (s.hasError) return const Center(child: Text('تعذر تحميل الفعاليات.'));
        if (!s.hasData) return const Center(child: CircularProgressIndicator());
        if (s.data!.docs.isEmpty) return const _EmptyCommunity(icon: Icons.event_available, text: 'لا توجد فعاليات بعد. كن أول من ينظم فعالية!');
        return ListView(padding: const EdgeInsets.all(12), children: s.data!.docs.map((d) {
          final data = d.data();
          final attendees = List<String>.from(data['attendees'] ?? []);
          final date = (data['startsAt'] as Timestamp?)?.toDate();
          final joined = attendees.contains(uid);
          return Card(child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(data['title'] ?? 'فعالية', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            if ((data['details'] ?? '').toString().isNotEmpty) Padding(padding: const EdgeInsets.only(top: 6), child: Text(data['details'])),
            const SizedBox(height: 8),
            Row(children: [
              const Icon(Icons.calendar_today, size: 15, color: Colors.grey), const SizedBox(width: 5),
              Text(date == null ? 'الموعد غير محدد' : date.year.toString() + '/' + date.month.toString() + '/' + date.day.toString()),
              const Spacer(), Text(attendees.length.toString() + ' مشارك'),
            ]),
            Align(alignment: Alignment.centerLeft, child: TextButton.icon(onPressed: () async {
              try { await d.reference.update({'attendees': joined ? FieldValue.arrayRemove([uid]) : FieldValue.arrayUnion([uid])}); }
              catch (_) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تعذر تحديث المشاركة.'))); }
            }, icon: Icon(joined ? Icons.check_circle : Icons.add_circle_outline), label: Text(joined ? 'إلغاء المشاركة' : 'سأشارك'))),
          ])));
        }).toList());
      },
    ),
  );
}

class CommunityQuestionPage extends StatefulWidget {
  const CommunityQuestionPage({super.key});
  @override
  State<CommunityQuestionPage> createState() => _CommunityQuestionPageState();
}
class _CommunityQuestionPageState extends State<CommunityQuestionPage> {
  final db = FirebaseFirestore.instance;
  String get uid => FirebaseAuth.instance.currentUser!.uid;
  Future<void> addQuestion() async {
    final text = TextEditingController();
    final ok = await showDialog<bool>(context: context, builder: (ctx) => Directionality(textDirection: TextDirection.rtl, child: AlertDialog(
      title: const Text('سؤال أو اعتراف مجهول'),
      content: TextField(controller: text, maxLines: 5, maxLength: 700, decoration: const InputDecoration(hintText: 'لا تكتب معلومات شخصية حساسة...', border: OutlineInputBorder())),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')), FilledButton(onPressed: () => Navigator.pop(ctx, text.text.trim().isNotEmpty), child: const Text('نشر مجهول'))],
    )));
    if (ok == true) {
      try { await db.collection('communityQuestions').add({'text': text.text.trim(), 'createdAt': FieldValue.serverTimestamp(), 'anonymous': true}); }
      catch (_) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تعذر النشر. تحقق من قواعد Firestore.'))); }
    }
    text.dispose();
  }
  @override
  Widget build(BuildContext context) => Scaffold(
    floatingActionButton: FloatingActionButton.extended(onPressed: addQuestion, icon: const Icon(Icons.add), label: const Text('اكتب بسرية')),
    body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: db.collection('communityQuestions').orderBy('createdAt', descending: true).limit(60).snapshots(),
      builder: (context, s) {
        if (s.hasError) return const Center(child: Text('تعذر تحميل المشاركات.'));
        if (!s.hasData) return const Center(child: CircularProgressIndicator());
        if (s.data!.docs.isEmpty) return const _EmptyCommunity(icon: Icons.question_answer_outlined, text: 'ابدأ أول سؤال أو اعتراف مجهول.');
        return ListView(padding: const EdgeInsets.all(12), children: [
          const Card(child: Padding(padding: EdgeInsets.all(12), child: Text('يظهر النص للجميع بدون اسم الناشر، لكن الإدارة قد تحتاج معرفة صاحب البلاغ عند إساءة الاستخدام. لا تكتب أسراراً أو بيانات شخصية.'))),
          ...s.data!.docs.map((d) => Card(child: ListTile(leading: const CircleAvatar(child: Icon(Icons.question_mark)), title: Text(d.data()['text'] ?? ''), subtitle: const Text('عضو مجهول')))),
        ]);
      },
    ),
  );
}

class CommunityDirectoryPage extends StatelessWidget {
  const CommunityDirectoryPage({super.key});
  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(12), children: [
    const Card(child: Padding(padding: EdgeInsets.all(14), child: Text('اختَر اهتمامك وتابع النقاشات والفعاليات الخاصة به.'))),
    ...List.generate(_interestNames.length, (i) => Card(child: ListTile(
      leading: CircleAvatar(child: Icon(_interestIcons[i])),
      title: Text(_interestNames[i]),
      subtitle: const Text('منشورات ونقاشات وأصدقاء بنفس الاهتمام'),
      trailing: const Icon(Icons.arrow_forward_ios, size: 15),
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => InterestCommunityPage(category: _interestNames[i]))),
    ))),
    const _WritingAssistantCard(),
  ]);
}


class InterestCommunityPage extends StatefulWidget {
  const InterestCommunityPage({super.key, required this.category});
  final String category;
  @override
  State<InterestCommunityPage> createState() => _InterestCommunityPageState();
}

class _InterestCommunityPageState extends State<InterestCommunityPage> {
  final db = FirebaseFirestore.instance;
  String get uid => FirebaseAuth.instance.currentUser!.uid;

  Future<void> addPost() async {
    final text = TextEditingController();
    final ok = await showDialog<bool>(context: context, builder: (ctx) => Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        title: Text('منشور • ' + widget.category),
        content: TextField(controller: text, maxLines: 5, maxLength: 1000, decoration: const InputDecoration(hintText: 'شارك فكرة أو سؤالاً...', border: OutlineInputBorder())),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          FilledButton(onPressed: () => Navigator.pop(ctx, text.text.trim().isNotEmpty), child: const Text('نشر')),
        ],
      ),
    ));
    if (ok == true) {
      try {
        await db.collection('interestPosts').add({
          'category': widget.category, 'authorId': uid,
          'authorName': FirebaseAuth.instance.currentUser?.displayName ?? 'عضو',
          'text': text.text.trim(), 'createdAt': FieldValue.serverTimestamp(),
        });
      } catch (_) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تعذر نشر المشاركة. تحقق من قواعد Firestore.')));
      }
    }
    text.dispose();
  }

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.rtl,
    child: Scaffold(
      appBar: AppBar(title: Text(widget.category)),
      floatingActionButton: FloatingActionButton.extended(onPressed: addPost, icon: const Icon(Icons.add), label: const Text('منشور جديد')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: db.collection('interestPosts').where('category', isEqualTo: widget.category).limit(80).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return const Center(child: Text('تعذر تحميل منشورات المجتمع.'));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snapshot.data!.docs.toList();
          docs.sort((a, b) {
            final aa = (a.data()['createdAt'] as Timestamp?)?.millisecondsSinceEpoch ?? 0;
            final bb = (b.data()['createdAt'] as Timestamp?)?.millisecondsSinceEpoch ?? 0;
            return bb.compareTo(aa);
          });
          if (docs.isEmpty) return const _EmptyCommunity(icon: Icons.forum_outlined, text: 'هذا المجتمع جديد. كن أول من يشارك منشوراً!');
          return ListView(padding: const EdgeInsets.all(12), children: docs.map((doc) {
            final data = doc.data();
            return Card(child: ListTile(
              leading: const CircleAvatar(child: Icon(Icons.person_outline)),
              title: Text(data['authorName'] ?? 'عضو'),
              subtitle: Padding(padding: const EdgeInsets.only(top: 6), child: Text(data['text'] ?? '')),
            ));
          }).toList());
        },
      ),
    ),
  );
}

class _WritingAssistantCard extends StatefulWidget {
  const _WritingAssistantCard();
  @override
  State<_WritingAssistantCard> createState() => _WritingAssistantCardState();
}
class _WritingAssistantCardState extends State<_WritingAssistantCard> {
  final input = TextEditingController();
  String suggestion = '';
  @override
  void dispose() { input.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => Card(child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
    const Text('مساعد صياغة المنشورات', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
    const Text('قالب محلي بسيط يرتب فكرتك دون إرسالها لخدمة خارجية.'),
    TextField(controller: input, maxLines: 3, decoration: const InputDecoration(labelText: 'اكتب فكرتك')),
    FilledButton(onPressed: () { if (input.text.trim().isNotEmpty) setState(() => suggestion = 'مساحة للنقاش 💬\n\n' + input.text.trim() + '\n\nشنو رأيكم؟ شاركونا أفكاركم باحترام.'); }, child: const Text('رتّب فكرتي')),
    if (suggestion.isNotEmpty) ...[
      SelectableText(suggestion),
      TextButton.icon(onPressed: () { Clipboard.setData(ClipboardData(text: suggestion)); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم نسخ النص'))); }, icon: const Icon(Icons.copy), label: const Text('نسخ')),
    ],
  ])));
}

class _EmptyCommunity extends StatelessWidget {
  const _EmptyCommunity({required this.icon, required this.text});
  final IconData icon;
  final String text;
  @override
  Widget build(BuildContext context) => Center(child: Padding(padding: const EdgeInsets.all(28), child: Column(mainAxisSize: MainAxisSize.min, children: [
    Icon(icon, size: 48, color: Colors.grey), const SizedBox(height: 12), Text(text, textAlign: TextAlign.center),
  ])));
}
).hasMatch(id) ? id : null;
  }
  bool _isDirectVideo(Uri uri) => RegExp(r'\.(mp4|m4v|mov|webm|m3u8)
    final raw = (widget.party['streamUrl'] as String? ?? '').trim();
    final uri = Uri.tryParse(raw);
    if (uri == null || !['https', 'http'].contains(uri.scheme) || uri.host.isEmpty) {
      if (mounted) setState(() { _videoLoading = false; _videoError = 'الرابط غير صالح. استخدم رابط http أو https.'; });
      return;
    }
    final controller = VideoPlayerController.networkUrl(uri);
    _videoController = controller;
    try {
      await controller.initialize().timeout(const Duration(seconds: 35));
      await controller.setLooping(false);
      if (mounted) setState(() { _videoLoading = false; _videoError = null; });
    } catch (_) {
      await controller.dispose();
      if (identical(_videoController, controller)) _videoController = null;
      if (mounted) setState(() { _videoLoading = false; _videoError = controller.value.errorDescription?.isNotEmpty == true ? 'تعذر تشغيل الفيديو: ${controller.value.errorDescription}' : 'هذا الرابط لا يقدّم فيديو مباشراً بصيغة يدعمها المشغّل. جرّب رابط MP4 أو HLS ينتهي بـ .m3u8. روابط صفحات المواقع لا تعمل كمصدر فيديو.'; });
    }
  }
  @override
  void dispose() { message.dispose(); _videoController?.dispose(); super.dispose(); }
  Future<void> send() async {
    final value = message.text.trim();
    if (value.isEmpty || busy) return;
    setState(() => busy = true);
    try {
      await party.collection('messages').add({
        'senderId': uid, 'senderName': FirebaseAuth.instance.currentUser?.displayName ?? 'عضو',
        'text': value, 'createdAt': FieldValue.serverTimestamp(),
      });
      message.clear();
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تعذر إرسال الرسالة.')));
    } finally { if (mounted) setState(() => busy = false); }
  }
  @override
  Widget build(BuildContext context) => Directionality(textDirection: TextDirection.rtl, child: Scaffold(
    appBar: AppBar(title: Text(widget.party['title'] ?? 'استاد الأصدقاء'), actions: [
      IconButton(tooltip: 'نسخ رمز الجلسة', icon: const Icon(Icons.copy), onPressed: () {
        Clipboard.setData(ClipboardData(text: widget.partyId));
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم نسخ رمز الجلسة')));
      }),
    ]),
    body: Column(children: [
      Card(margin: const EdgeInsets.fromLTRB(12, 12, 12, 6), clipBehavior: Clip.antiAlias, child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Padding(padding: const EdgeInsets.fromLTRB(14, 12, 14, 8), child: Text(widget.party['match'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
        AspectRatio(aspectRatio: 16 / 9, child: Container(color: Colors.black, alignment: Alignment.center, child: _videoLoading
          ? const CircularProgressIndicator(color: Colors.white)
          : _videoError != null
            ? Padding(padding: const EdgeInsets.all(16), child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text(_videoError!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white)),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: _videoLoading ? null : () {
                    final oldController = _videoController;
                    setState(() { _videoLoading = true; _videoError = null; _videoController = null; });
                    oldController?.dispose();
                    _initializeVideo();
                  },
                  icon: const Icon(Icons.refresh), label: const Text('إعادة المحاولة'),
                ),
              ]))
            : _videoController != null && _videoController!.value.isInitialized
              ? Stack(alignment: Alignment.bottomCenter, children: [
                  Center(child: AspectRatio(aspectRatio: _videoController!.value.aspectRatio, child: VideoPlayer(_videoController!))),
                  VideoProgressIndicator(_videoController!, allowScrubbing: true, padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12), colors: const VideoProgressColors(playedColor: Colors.deepPurpleAccent, bufferedColor: Colors.white54, backgroundColor: Colors.white24)),
                  Positioned(right: 8, bottom: 12, child: IconButton.filledTonal(onPressed: () { setState(() { _videoController!.value.isPlaying ? _videoController!.pause() : _videoController!.play(); }); }, icon: Icon(_videoController!.value.isPlaying ? Icons.pause : Icons.play_arrow))),
                ])
              : const Text('البث غير متاح حالياً', style: TextStyle(color: Colors.white)))),

      ])),
      Expanded(child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: party.collection('messages').orderBy('createdAt').limit(200).snapshots(),
        builder: (context, s) {
          if (s.hasError) return const Center(child: Text('تعذر تحميل دردشة الجلسة.'));
          if (!s.hasData) return const Center(child: CircularProgressIndicator());
          final docs = s.data!.docs;
          return ListView.builder(reverse: true, padding: const EdgeInsets.all(12), itemCount: docs.length, itemBuilder: (context, i) {
            final item = docs[docs.length - 1 - i].data();
            final mine = item['senderId'] == uid;
            return Align(alignment: mine ? Alignment.centerRight : Alignment.centerLeft, child: Container(
              margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(11),
              constraints: const BoxConstraints(maxWidth: 310),
              decoration: BoxDecoration(color: mine ? Theme.of(context).colorScheme.primaryContainer : Theme.of(context).colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(14)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                if (!mine) Text(item['senderName'] ?? 'عضو', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                Text(item['text'] ?? ''),
              ]),
            ));
          });
        },
      )),
      SafeArea(child: Padding(padding: const EdgeInsets.all(10), child: Row(children: [
        Expanded(child: TextField(controller: message, maxLength: 500, decoration: const InputDecoration(hintText: 'اكتب تعليقك على المباراة...', counterText: '', border: OutlineInputBorder()))),
        const SizedBox(width: 8),
        IconButton.filled(onPressed: busy ? null : send, icon: const Icon(Icons.send)),
      ]))),
    ]),
  ));
}

class CommunityEventsPage extends StatefulWidget {
  const CommunityEventsPage({super.key});
  @override
  State<CommunityEventsPage> createState() => _CommunityEventsPageState();
}
class _CommunityEventsPageState extends State<CommunityEventsPage> {
  final db = FirebaseFirestore.instance;
  String get uid => FirebaseAuth.instance.currentUser!.uid;
  Future<void> createEvent() async {
    final title = TextEditingController();
    final details = TextEditingController();
    DateTime when = DateTime.now().add(const Duration(days: 1));
    final ok = await showDialog<bool>(context: context, builder: (ctx) => Directionality(textDirection: TextDirection.rtl, child: StatefulBuilder(builder: (ctx, setD) => AlertDialog(
      title: const Text('إضافة فعالية'),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: title, maxLength: 80, decoration: const InputDecoration(labelText: 'عنوان الفعالية')),
        TextField(controller: details, maxLength: 500, maxLines: 3, decoration: const InputDecoration(labelText: 'التفاصيل')),
        OutlinedButton.icon(icon: const Icon(Icons.calendar_month), label: Text(when.year.toString() + '/' + when.month.toString() + '/' + when.day.toString()), onPressed: () async {
          final date = await showDatePicker(context: ctx, initialDate: when, firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)));
          if (date != null) setD(() => when = date);
        }),
      ])),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')), FilledButton(onPressed: () => Navigator.pop(ctx, title.text.trim().length >= 3), child: const Text('نشر'))],
    ))));
    if (ok == true) {
      try {
        await db.collection('communityEvents').add({
          'title': title.text.trim(), 'details': details.text.trim(), 'startsAt': Timestamp.fromDate(when),
          'createdBy': uid, 'attendees': [uid], 'createdAt': FieldValue.serverTimestamp(),
        });
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم نشر الفعالية')));
      } catch (_) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تعذر النشر. تحقق من قواعد Firestore.')));
      }
    }
    title.dispose(); details.dispose();
  }
  @override
  Widget build(BuildContext context) => Scaffold(
    floatingActionButton: FloatingActionButton.extended(onPressed: createEvent, icon: const Icon(Icons.add), label: const Text('فعالية جديدة')),
    body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: db.collection('communityEvents').orderBy('startsAt').limit(60).snapshots(),
      builder: (context, s) {
        if (s.hasError) return const Center(child: Text('تعذر تحميل الفعاليات.'));
        if (!s.hasData) return const Center(child: CircularProgressIndicator());
        if (s.data!.docs.isEmpty) return const _EmptyCommunity(icon: Icons.event_available, text: 'لا توجد فعاليات بعد. كن أول من ينظم فعالية!');
        return ListView(padding: const EdgeInsets.all(12), children: s.data!.docs.map((d) {
          final data = d.data();
          final attendees = List<String>.from(data['attendees'] ?? []);
          final date = (data['startsAt'] as Timestamp?)?.toDate();
          final joined = attendees.contains(uid);
          return Card(child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(data['title'] ?? 'فعالية', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            if ((data['details'] ?? '').toString().isNotEmpty) Padding(padding: const EdgeInsets.only(top: 6), child: Text(data['details'])),
            const SizedBox(height: 8),
            Row(children: [
              const Icon(Icons.calendar_today, size: 15, color: Colors.grey), const SizedBox(width: 5),
              Text(date == null ? 'الموعد غير محدد' : date.year.toString() + '/' + date.month.toString() + '/' + date.day.toString()),
              const Spacer(), Text(attendees.length.toString() + ' مشارك'),
            ]),
            Align(alignment: Alignment.centerLeft, child: TextButton.icon(onPressed: () async {
              try { await d.reference.update({'attendees': joined ? FieldValue.arrayRemove([uid]) : FieldValue.arrayUnion([uid])}); }
              catch (_) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تعذر تحديث المشاركة.'))); }
            }, icon: Icon(joined ? Icons.check_circle : Icons.add_circle_outline), label: Text(joined ? 'إلغاء المشاركة' : 'سأشارك'))),
          ])));
        }).toList());
      },
    ),
  );
}

class CommunityQuestionPage extends StatefulWidget {
  const CommunityQuestionPage({super.key});
  @override
  State<CommunityQuestionPage> createState() => _CommunityQuestionPageState();
}
class _CommunityQuestionPageState extends State<CommunityQuestionPage> {
  final db = FirebaseFirestore.instance;
  String get uid => FirebaseAuth.instance.currentUser!.uid;
  Future<void> addQuestion() async {
    final text = TextEditingController();
    final ok = await showDialog<bool>(context: context, builder: (ctx) => Directionality(textDirection: TextDirection.rtl, child: AlertDialog(
      title: const Text('سؤال أو اعتراف مجهول'),
      content: TextField(controller: text, maxLines: 5, maxLength: 700, decoration: const InputDecoration(hintText: 'لا تكتب معلومات شخصية حساسة...', border: OutlineInputBorder())),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')), FilledButton(onPressed: () => Navigator.pop(ctx, text.text.trim().isNotEmpty), child: const Text('نشر مجهول'))],
    )));
    if (ok == true) {
      try { await db.collection('communityQuestions').add({'text': text.text.trim(), 'createdAt': FieldValue.serverTimestamp(), 'anonymous': true}); }
      catch (_) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تعذر النشر. تحقق من قواعد Firestore.'))); }
    }
    text.dispose();
  }
  @override
  Widget build(BuildContext context) => Scaffold(
    floatingActionButton: FloatingActionButton.extended(onPressed: addQuestion, icon: const Icon(Icons.add), label: const Text('اكتب بسرية')),
    body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: db.collection('communityQuestions').orderBy('createdAt', descending: true).limit(60).snapshots(),
      builder: (context, s) {
        if (s.hasError) return const Center(child: Text('تعذر تحميل المشاركات.'));
        if (!s.hasData) return const Center(child: CircularProgressIndicator());
        if (s.data!.docs.isEmpty) return const _EmptyCommunity(icon: Icons.question_answer_outlined, text: 'ابدأ أول سؤال أو اعتراف مجهول.');
        return ListView(padding: const EdgeInsets.all(12), children: [
          const Card(child: Padding(padding: EdgeInsets.all(12), child: Text('يظهر النص للجميع بدون اسم الناشر، لكن الإدارة قد تحتاج معرفة صاحب البلاغ عند إساءة الاستخدام. لا تكتب أسراراً أو بيانات شخصية.'))),
          ...s.data!.docs.map((d) => Card(child: ListTile(leading: const CircleAvatar(child: Icon(Icons.question_mark)), title: Text(d.data()['text'] ?? ''), subtitle: const Text('عضو مجهول')))),
        ]);
      },
    ),
  );
}

class CommunityDirectoryPage extends StatelessWidget {
  const CommunityDirectoryPage({super.key});
  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(12), children: [
    const Card(child: Padding(padding: EdgeInsets.all(14), child: Text('اختَر اهتمامك وتابع النقاشات والفعاليات الخاصة به.'))),
    ...List.generate(_interestNames.length, (i) => Card(child: ListTile(
      leading: CircleAvatar(child: Icon(_interestIcons[i])),
      title: Text(_interestNames[i]),
      subtitle: const Text('منشورات ونقاشات وأصدقاء بنفس الاهتمام'),
      trailing: const Icon(Icons.arrow_forward_ios, size: 15),
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => InterestCommunityPage(category: _interestNames[i]))),
    ))),
    const _WritingAssistantCard(),
  ]);
}


class InterestCommunityPage extends StatefulWidget {
  const InterestCommunityPage({super.key, required this.category});
  final String category;
  @override
  State<InterestCommunityPage> createState() => _InterestCommunityPageState();
}

class _InterestCommunityPageState extends State<InterestCommunityPage> {
  final db = FirebaseFirestore.instance;
  String get uid => FirebaseAuth.instance.currentUser!.uid;

  Future<void> addPost() async {
    final text = TextEditingController();
    final ok = await showDialog<bool>(context: context, builder: (ctx) => Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        title: Text('منشور • ' + widget.category),
        content: TextField(controller: text, maxLines: 5, maxLength: 1000, decoration: const InputDecoration(hintText: 'شارك فكرة أو سؤالاً...', border: OutlineInputBorder())),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          FilledButton(onPressed: () => Navigator.pop(ctx, text.text.trim().isNotEmpty), child: const Text('نشر')),
        ],
      ),
    ));
    if (ok == true) {
      try {
        await db.collection('interestPosts').add({
          'category': widget.category, 'authorId': uid,
          'authorName': FirebaseAuth.instance.currentUser?.displayName ?? 'عضو',
          'text': text.text.trim(), 'createdAt': FieldValue.serverTimestamp(),
        });
      } catch (_) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تعذر نشر المشاركة. تحقق من قواعد Firestore.')));
      }
    }
    text.dispose();
  }

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.rtl,
    child: Scaffold(
      appBar: AppBar(title: Text(widget.category)),
      floatingActionButton: FloatingActionButton.extended(onPressed: addPost, icon: const Icon(Icons.add), label: const Text('منشور جديد')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: db.collection('interestPosts').where('category', isEqualTo: widget.category).limit(80).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return const Center(child: Text('تعذر تحميل منشورات المجتمع.'));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snapshot.data!.docs.toList();
          docs.sort((a, b) {
            final aa = (a.data()['createdAt'] as Timestamp?)?.millisecondsSinceEpoch ?? 0;
            final bb = (b.data()['createdAt'] as Timestamp?)?.millisecondsSinceEpoch ?? 0;
            return bb.compareTo(aa);
          });
          if (docs.isEmpty) return const _EmptyCommunity(icon: Icons.forum_outlined, text: 'هذا المجتمع جديد. كن أول من يشارك منشوراً!');
          return ListView(padding: const EdgeInsets.all(12), children: docs.map((doc) {
            final data = doc.data();
            return Card(child: ListTile(
              leading: const CircleAvatar(child: Icon(Icons.person_outline)),
              title: Text(data['authorName'] ?? 'عضو'),
              subtitle: Padding(padding: const EdgeInsets.only(top: 6), child: Text(data['text'] ?? '')),
            ));
          }).toList());
        },
      ),
    ),
  );
}

class _WritingAssistantCard extends StatefulWidget {
  const _WritingAssistantCard();
  @override
  State<_WritingAssistantCard> createState() => _WritingAssistantCardState();
}
class _WritingAssistantCardState extends State<_WritingAssistantCard> {
  final input = TextEditingController();
  String suggestion = '';
  @override
  void dispose() { input.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => Card(child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
    const Text('مساعد صياغة المنشورات', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
    const Text('قالب محلي بسيط يرتب فكرتك دون إرسالها لخدمة خارجية.'),
    TextField(controller: input, maxLines: 3, decoration: const InputDecoration(labelText: 'اكتب فكرتك')),
    FilledButton(onPressed: () { if (input.text.trim().isNotEmpty) setState(() => suggestion = 'مساحة للنقاش 💬\n\n' + input.text.trim() + '\n\nشنو رأيكم؟ شاركونا أفكاركم باحترام.'); }, child: const Text('رتّب فكرتي')),
    if (suggestion.isNotEmpty) ...[
      SelectableText(suggestion),
      TextButton.icon(onPressed: () { Clipboard.setData(ClipboardData(text: suggestion)); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم نسخ النص'))); }, icon: const Icon(Icons.copy), label: const Text('نسخ')),
    ],
  ])));
}

class _EmptyCommunity extends StatelessWidget {
  const _EmptyCommunity({required this.icon, required this.text});
  final IconData icon;
  final String text;
  @override
  Widget build(BuildContext context) => Center(child: Padding(padding: const EdgeInsets.all(28), child: Column(mainAxisSize: MainAxisSize.min, children: [
    Icon(icon, size: 48, color: Colors.grey), const SizedBox(height: 12), Text(text, textAlign: TextAlign.center),
  ])));
}
, caseSensitive: false).hasMatch(uri.path);
  Future<void> _openWebSource(Uri uri, {String? youtubeId}) async {
    final target = youtubeId == null ? uri : Uri.https('www.youtube.com', '/embed/$youtubeId', {'playsinline': '1', 'enablejsapi': '1', 'rel': '0'});
    final controller = WebViewController();
    await controller.setJavaScriptMode(JavaScriptMode.unrestricted);
    await controller.setBackgroundColor(Colors.black);
    await controller.setNavigationDelegate(NavigationDelegate(onPageFinished: (_) async {
      try { await _applyRemotePlayback(await party.get()); } catch (_) {}
    }));
    if (!mounted) return;
    setState(() { _webController = controller; _usingWebView = true; _isYouTube = youtubeId != null; _videoLoading = false; _videoError = null; });
    if (youtubeId != null) {
      await controller.loadHtmlString('''<!doctype html><html><head><meta name="viewport" content="width=device-width,initial-scale=1,maximum-scale=1"><style>html,body,#player{margin:0;width:100%;height:100%;background:#000;overflow:hidden}iframe{width:100%;height:100%;border:0}</style></head><body><div id="player"></div><script>var player;function onYouTubeIframeAPIReady(){player=new YT.Player('player',{videoId:'$youtubeId',playerVars:{playsinline:1,rel:0,enablejsapi:1}});}</script><script src="https://www.youtube.com/iframe_api"></script></body></html>''', baseUrl: 'https://www.youtube.com');
    } else {
      await controller.loadRequest(target);
    }
  }
  Future<void> _initializeVideo() async {
    final raw = (widget.party['streamUrl'] as String? ?? '').trim();
    final uri = Uri.tryParse(raw);
    if (uri == null || !['https', 'http'].contains(uri.scheme) || uri.host.isEmpty) {
      if (mounted) setState(() { _videoLoading = false; _videoError = 'الرابط غير صالح. استخدم رابط http أو https.'; });
      return;
    }
    final controller = VideoPlayerController.networkUrl(uri);
    _videoController = controller;
    try {
      await controller.initialize().timeout(const Duration(seconds: 35));
      await controller.setLooping(false);
      if (mounted) setState(() { _videoLoading = false; _videoError = null; });
    } catch (_) {
      await controller.dispose();
      if (identical(_videoController, controller)) _videoController = null;
      if (mounted) setState(() { _videoLoading = false; _videoError = controller.value.errorDescription?.isNotEmpty == true ? 'تعذر تشغيل الفيديو: ${controller.value.errorDescription}' : 'هذا الرابط لا يقدّم فيديو مباشراً بصيغة يدعمها المشغّل. جرّب رابط MP4 أو HLS ينتهي بـ .m3u8. روابط صفحات المواقع لا تعمل كمصدر فيديو.'; });
    }
  }
  @override
  void dispose() { message.dispose(); _videoController?.dispose(); super.dispose(); }
  Future<void> send() async {
    final value = message.text.trim();
    if (value.isEmpty || busy) return;
    setState(() => busy = true);
    try {
      await party.collection('messages').add({
        'senderId': uid, 'senderName': FirebaseAuth.instance.currentUser?.displayName ?? 'عضو',
        'text': value, 'createdAt': FieldValue.serverTimestamp(),
      });
      message.clear();
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تعذر إرسال الرسالة.')));
    } finally { if (mounted) setState(() => busy = false); }
  }
  @override
  Widget build(BuildContext context) => Directionality(textDirection: TextDirection.rtl, child: Scaffold(
    appBar: AppBar(title: Text(widget.party['title'] ?? 'استاد الأصدقاء'), actions: [
      IconButton(tooltip: 'نسخ رمز الجلسة', icon: const Icon(Icons.copy), onPressed: () {
        Clipboard.setData(ClipboardData(text: widget.partyId));
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم نسخ رمز الجلسة')));
      }),
    ]),
    body: Column(children: [
      Card(margin: const EdgeInsets.fromLTRB(12, 12, 12, 6), clipBehavior: Clip.antiAlias, child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Padding(padding: const EdgeInsets.fromLTRB(14, 12, 14, 8), child: Text(widget.party['match'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
        AspectRatio(aspectRatio: 16 / 9, child: Container(color: Colors.black, alignment: Alignment.center, child: _videoLoading
          ? const CircularProgressIndicator(color: Colors.white)
          : _videoError != null
            ? Padding(padding: const EdgeInsets.all(16), child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text(_videoError!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white)),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: _videoLoading ? null : () {
                    final oldController = _videoController;
                    setState(() { _videoLoading = true; _videoError = null; _videoController = null; });
                    oldController?.dispose();
                    _initializeVideo();
                  },
                  icon: const Icon(Icons.refresh), label: const Text('إعادة المحاولة'),
                ),
              ]))
            : _videoController != null && _videoController!.value.isInitialized
              ? Stack(alignment: Alignment.bottomCenter, children: [
                  Center(child: AspectRatio(aspectRatio: _videoController!.value.aspectRatio, child: VideoPlayer(_videoController!))),
                  VideoProgressIndicator(_videoController!, allowScrubbing: true, padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12), colors: const VideoProgressColors(playedColor: Colors.deepPurpleAccent, bufferedColor: Colors.white54, backgroundColor: Colors.white24)),
                  Positioned(right: 8, bottom: 12, child: IconButton.filledTonal(onPressed: () { setState(() { _videoController!.value.isPlaying ? _videoController!.pause() : _videoController!.play(); }); }, icon: Icon(_videoController!.value.isPlaying ? Icons.pause : Icons.play_arrow))),
                ])
              : const Text('البث غير متاح حالياً', style: TextStyle(color: Colors.white)))),

      ])),
      Expanded(child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: party.collection('messages').orderBy('createdAt').limit(200).snapshots(),
        builder: (context, s) {
          if (s.hasError) return const Center(child: Text('تعذر تحميل دردشة الجلسة.'));
          if (!s.hasData) return const Center(child: CircularProgressIndicator());
          final docs = s.data!.docs;
          return ListView.builder(reverse: true, padding: const EdgeInsets.all(12), itemCount: docs.length, itemBuilder: (context, i) {
            final item = docs[docs.length - 1 - i].data();
            final mine = item['senderId'] == uid;
            return Align(alignment: mine ? Alignment.centerRight : Alignment.centerLeft, child: Container(
              margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(11),
              constraints: const BoxConstraints(maxWidth: 310),
              decoration: BoxDecoration(color: mine ? Theme.of(context).colorScheme.primaryContainer : Theme.of(context).colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(14)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                if (!mine) Text(item['senderName'] ?? 'عضو', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                Text(item['text'] ?? ''),
              ]),
            ));
          });
        },
      )),
      SafeArea(child: Padding(padding: const EdgeInsets.all(10), child: Row(children: [
        Expanded(child: TextField(controller: message, maxLength: 500, decoration: const InputDecoration(hintText: 'اكتب تعليقك على المباراة...', counterText: '', border: OutlineInputBorder()))),
        const SizedBox(width: 8),
        IconButton.filled(onPressed: busy ? null : send, icon: const Icon(Icons.send)),
      ]))),
    ]),
  ));
}

class CommunityEventsPage extends StatefulWidget {
  const CommunityEventsPage({super.key});
  @override
  State<CommunityEventsPage> createState() => _CommunityEventsPageState();
}
class _CommunityEventsPageState extends State<CommunityEventsPage> {
  final db = FirebaseFirestore.instance;
  String get uid => FirebaseAuth.instance.currentUser!.uid;
  Future<void> createEvent() async {
    final title = TextEditingController();
    final details = TextEditingController();
    DateTime when = DateTime.now().add(const Duration(days: 1));
    final ok = await showDialog<bool>(context: context, builder: (ctx) => Directionality(textDirection: TextDirection.rtl, child: StatefulBuilder(builder: (ctx, setD) => AlertDialog(
      title: const Text('إضافة فعالية'),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: title, maxLength: 80, decoration: const InputDecoration(labelText: 'عنوان الفعالية')),
        TextField(controller: details, maxLength: 500, maxLines: 3, decoration: const InputDecoration(labelText: 'التفاصيل')),
        OutlinedButton.icon(icon: const Icon(Icons.calendar_month), label: Text(when.year.toString() + '/' + when.month.toString() + '/' + when.day.toString()), onPressed: () async {
          final date = await showDatePicker(context: ctx, initialDate: when, firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)));
          if (date != null) setD(() => when = date);
        }),
      ])),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')), FilledButton(onPressed: () => Navigator.pop(ctx, title.text.trim().length >= 3), child: const Text('نشر'))],
    ))));
    if (ok == true) {
      try {
        await db.collection('communityEvents').add({
          'title': title.text.trim(), 'details': details.text.trim(), 'startsAt': Timestamp.fromDate(when),
          'createdBy': uid, 'attendees': [uid], 'createdAt': FieldValue.serverTimestamp(),
        });
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم نشر الفعالية')));
      } catch (_) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تعذر النشر. تحقق من قواعد Firestore.')));
      }
    }
    title.dispose(); details.dispose();
  }
  @override
  Widget build(BuildContext context) => Scaffold(
    floatingActionButton: FloatingActionButton.extended(onPressed: createEvent, icon: const Icon(Icons.add), label: const Text('فعالية جديدة')),
    body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: db.collection('communityEvents').orderBy('startsAt').limit(60).snapshots(),
      builder: (context, s) {
        if (s.hasError) return const Center(child: Text('تعذر تحميل الفعاليات.'));
        if (!s.hasData) return const Center(child: CircularProgressIndicator());
        if (s.data!.docs.isEmpty) return const _EmptyCommunity(icon: Icons.event_available, text: 'لا توجد فعاليات بعد. كن أول من ينظم فعالية!');
        return ListView(padding: const EdgeInsets.all(12), children: s.data!.docs.map((d) {
          final data = d.data();
          final attendees = List<String>.from(data['attendees'] ?? []);
          final date = (data['startsAt'] as Timestamp?)?.toDate();
          final joined = attendees.contains(uid);
          return Card(child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(data['title'] ?? 'فعالية', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            if ((data['details'] ?? '').toString().isNotEmpty) Padding(padding: const EdgeInsets.only(top: 6), child: Text(data['details'])),
            const SizedBox(height: 8),
            Row(children: [
              const Icon(Icons.calendar_today, size: 15, color: Colors.grey), const SizedBox(width: 5),
              Text(date == null ? 'الموعد غير محدد' : date.year.toString() + '/' + date.month.toString() + '/' + date.day.toString()),
              const Spacer(), Text(attendees.length.toString() + ' مشارك'),
            ]),
            Align(alignment: Alignment.centerLeft, child: TextButton.icon(onPressed: () async {
              try { await d.reference.update({'attendees': joined ? FieldValue.arrayRemove([uid]) : FieldValue.arrayUnion([uid])}); }
              catch (_) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تعذر تحديث المشاركة.'))); }
            }, icon: Icon(joined ? Icons.check_circle : Icons.add_circle_outline), label: Text(joined ? 'إلغاء المشاركة' : 'سأشارك'))),
          ])));
        }).toList());
      },
    ),
  );
}

class CommunityQuestionPage extends StatefulWidget {
  const CommunityQuestionPage({super.key});
  @override
  State<CommunityQuestionPage> createState() => _CommunityQuestionPageState();
}
class _CommunityQuestionPageState extends State<CommunityQuestionPage> {
  final db = FirebaseFirestore.instance;
  String get uid => FirebaseAuth.instance.currentUser!.uid;
  Future<void> addQuestion() async {
    final text = TextEditingController();
    final ok = await showDialog<bool>(context: context, builder: (ctx) => Directionality(textDirection: TextDirection.rtl, child: AlertDialog(
      title: const Text('سؤال أو اعتراف مجهول'),
      content: TextField(controller: text, maxLines: 5, maxLength: 700, decoration: const InputDecoration(hintText: 'لا تكتب معلومات شخصية حساسة...', border: OutlineInputBorder())),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')), FilledButton(onPressed: () => Navigator.pop(ctx, text.text.trim().isNotEmpty), child: const Text('نشر مجهول'))],
    )));
    if (ok == true) {
      try { await db.collection('communityQuestions').add({'text': text.text.trim(), 'createdAt': FieldValue.serverTimestamp(), 'anonymous': true}); }
      catch (_) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تعذر النشر. تحقق من قواعد Firestore.'))); }
    }
    text.dispose();
  }
  @override
  Widget build(BuildContext context) => Scaffold(
    floatingActionButton: FloatingActionButton.extended(onPressed: addQuestion, icon: const Icon(Icons.add), label: const Text('اكتب بسرية')),
    body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: db.collection('communityQuestions').orderBy('createdAt', descending: true).limit(60).snapshots(),
      builder: (context, s) {
        if (s.hasError) return const Center(child: Text('تعذر تحميل المشاركات.'));
        if (!s.hasData) return const Center(child: CircularProgressIndicator());
        if (s.data!.docs.isEmpty) return const _EmptyCommunity(icon: Icons.question_answer_outlined, text: 'ابدأ أول سؤال أو اعتراف مجهول.');
        return ListView(padding: const EdgeInsets.all(12), children: [
          const Card(child: Padding(padding: EdgeInsets.all(12), child: Text('يظهر النص للجميع بدون اسم الناشر، لكن الإدارة قد تحتاج معرفة صاحب البلاغ عند إساءة الاستخدام. لا تكتب أسراراً أو بيانات شخصية.'))),
          ...s.data!.docs.map((d) => Card(child: ListTile(leading: const CircleAvatar(child: Icon(Icons.question_mark)), title: Text(d.data()['text'] ?? ''), subtitle: const Text('عضو مجهول')))),
        ]);
      },
    ),
  );
}

class CommunityDirectoryPage extends StatelessWidget {
  const CommunityDirectoryPage({super.key});
  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(12), children: [
    const Card(child: Padding(padding: EdgeInsets.all(14), child: Text('اختَر اهتمامك وتابع النقاشات والفعاليات الخاصة به.'))),
    ...List.generate(_interestNames.length, (i) => Card(child: ListTile(
      leading: CircleAvatar(child: Icon(_interestIcons[i])),
      title: Text(_interestNames[i]),
      subtitle: const Text('منشورات ونقاشات وأصدقاء بنفس الاهتمام'),
      trailing: const Icon(Icons.arrow_forward_ios, size: 15),
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => InterestCommunityPage(category: _interestNames[i]))),
    ))),
    const _WritingAssistantCard(),
  ]);
}


class InterestCommunityPage extends StatefulWidget {
  const InterestCommunityPage({super.key, required this.category});
  final String category;
  @override
  State<InterestCommunityPage> createState() => _InterestCommunityPageState();
}

class _InterestCommunityPageState extends State<InterestCommunityPage> {
  final db = FirebaseFirestore.instance;
  String get uid => FirebaseAuth.instance.currentUser!.uid;

  Future<void> addPost() async {
    final text = TextEditingController();
    final ok = await showDialog<bool>(context: context, builder: (ctx) => Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        title: Text('منشور • ' + widget.category),
        content: TextField(controller: text, maxLines: 5, maxLength: 1000, decoration: const InputDecoration(hintText: 'شارك فكرة أو سؤالاً...', border: OutlineInputBorder())),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          FilledButton(onPressed: () => Navigator.pop(ctx, text.text.trim().isNotEmpty), child: const Text('نشر')),
        ],
      ),
    ));
    if (ok == true) {
      try {
        await db.collection('interestPosts').add({
          'category': widget.category, 'authorId': uid,
          'authorName': FirebaseAuth.instance.currentUser?.displayName ?? 'عضو',
          'text': text.text.trim(), 'createdAt': FieldValue.serverTimestamp(),
        });
      } catch (_) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تعذر نشر المشاركة. تحقق من قواعد Firestore.')));
      }
    }
    text.dispose();
  }

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.rtl,
    child: Scaffold(
      appBar: AppBar(title: Text(widget.category)),
      floatingActionButton: FloatingActionButton.extended(onPressed: addPost, icon: const Icon(Icons.add), label: const Text('منشور جديد')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: db.collection('interestPosts').where('category', isEqualTo: widget.category).limit(80).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return const Center(child: Text('تعذر تحميل منشورات المجتمع.'));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snapshot.data!.docs.toList();
          docs.sort((a, b) {
            final aa = (a.data()['createdAt'] as Timestamp?)?.millisecondsSinceEpoch ?? 0;
            final bb = (b.data()['createdAt'] as Timestamp?)?.millisecondsSinceEpoch ?? 0;
            return bb.compareTo(aa);
          });
          if (docs.isEmpty) return const _EmptyCommunity(icon: Icons.forum_outlined, text: 'هذا المجتمع جديد. كن أول من يشارك منشوراً!');
          return ListView(padding: const EdgeInsets.all(12), children: docs.map((doc) {
            final data = doc.data();
            return Card(child: ListTile(
              leading: const CircleAvatar(child: Icon(Icons.person_outline)),
              title: Text(data['authorName'] ?? 'عضو'),
              subtitle: Padding(padding: const EdgeInsets.only(top: 6), child: Text(data['text'] ?? '')),
            ));
          }).toList());
        },
      ),
    ),
  );
}

class _WritingAssistantCard extends StatefulWidget {
  const _WritingAssistantCard();
  @override
  State<_WritingAssistantCard> createState() => _WritingAssistantCardState();
}
class _WritingAssistantCardState extends State<_WritingAssistantCard> {
  final input = TextEditingController();
  String suggestion = '';
  @override
  void dispose() { input.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => Card(child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
    const Text('مساعد صياغة المنشورات', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
    const Text('قالب محلي بسيط يرتب فكرتك دون إرسالها لخدمة خارجية.'),
    TextField(controller: input, maxLines: 3, decoration: const InputDecoration(labelText: 'اكتب فكرتك')),
    FilledButton(onPressed: () { if (input.text.trim().isNotEmpty) setState(() => suggestion = 'مساحة للنقاش 💬\n\n' + input.text.trim() + '\n\nشنو رأيكم؟ شاركونا أفكاركم باحترام.'); }, child: const Text('رتّب فكرتي')),
    if (suggestion.isNotEmpty) ...[
      SelectableText(suggestion),
      TextButton.icon(onPressed: () { Clipboard.setData(ClipboardData(text: suggestion)); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم نسخ النص'))); }, icon: const Icon(Icons.copy), label: const Text('نسخ')),
    ],
  ])));
}

class _EmptyCommunity extends StatelessWidget {
  const _EmptyCommunity({required this.icon, required this.text});
  final IconData icon;
  final String text;
  @override
  Widget build(BuildContext context) => Center(child: Padding(padding: const EdgeInsets.all(28), child: Column(mainAxisSize: MainAxisSize.min, children: [
    Icon(icon, size: 48, color: Colors.grey), const SizedBox(height: 12), Text(text, textAlign: TextAlign.center),
  ])));
}
