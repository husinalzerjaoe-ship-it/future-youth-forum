import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'livekit_calls.dart';

const _onlineGames = <String, String>{
  'tap': 'معركة النقر',
  'tunnel': 'سباق النفق',
  'target': 'قنص الهدف',
  'stars': 'صياد النجوم',
  'penalty': 'ضربات الجزاء',
  'pingpong': 'بينج بونج',
  'math': 'سباق الحساب',
};

class ArcadeDuelLobbyPage extends StatefulWidget {
  const ArcadeDuelLobbyPage({super.key});
  @override State<ArcadeDuelLobbyPage> createState() => _ArcadeDuelLobbyPageState();
}

class _ArcadeDuelLobbyPageState extends State<ArcadeDuelLobbyPage> {
  final _db = FirebaseFirestore.instance;
  final _code = TextEditingController();
  String _mode = 'tap';
  bool _busy = false;
  String get _uid => FirebaseAuth.instance.currentUser!.uid;
  String get _name => FirebaseAuth.instance.currentUser?.displayName ?? 'لاعب';

  @override
  void dispose() { _code.dispose(); super.dispose(); }

  Future<void> _create() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final room = _db.collection('arcadeRooms').doc();
      final code = (100000 + Random.secure().nextInt(900000)).toString();
      await room.set({
        'hostId': _uid,
        'gameId': 'arcade_duel_hub',
        'members': [_uid],
        'memberNames': {_uid: _name},
        'roomCode': code,
        'status': 'waiting',
        'visibility': 'private',
        'state': {
          'mode': _mode,
          'scores': {_uid: 0},
          'taps': {_uid: 0},
          'targetLane': Random.secure().nextInt(3),
          'hazardLane': Random.secure().nextInt(3),
          'round': 1,
          'lastAction': 'بانتظار انضمام صديق',
          'winner': '',
        },
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      await Clipboard.setData(ClipboardData(text: code));
      if (mounted) Navigator.push(context, MaterialPageRoute(builder: (_) => ArcadeDuelRoomPage(roomId: room.id)));
    } catch (e) { _toast('تعذر إنشاء الغرفة: $e'); }
    finally { if (mounted) setState(() => _busy = false); }
  }

  Future<void> _join() async {
    final code = _code.text.trim();
    if (!RegExp(r'^\d{6}$').hasMatch(code)) { _toast('أدخل رمزاً من 6 أرقام.'); return; }
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final q = await _db.collection('arcadeRooms').where('roomCode', isEqualTo: code).limit(1).get();
      if (q.docs.isEmpty) throw StateError('الغرفة غير موجودة.');
      final ref = q.docs.first.reference;
      await _db.runTransaction((tx) async {
        final snap = await tx.get(ref);
        final data = snap.data() ?? {};
        final members = List<String>.from(data['members'] ?? const []);
        if (data['gameId'] != 'arcade_duel_hub') throw StateError('هذا الرمز ليس لغرفة ألعاب الصالة.');
        if (members.contains(_uid)) return;
        if (data['status'] != 'waiting' || members.length >= 4) throw StateError('الغرفة بدأت أو اكتمل عدد اللاعبين.');
        final names = Map<String, dynamic>.from(data['memberNames'] ?? const {});
        names[_uid] = _name;
        final scores = Map<String, dynamic>.from(data['state']?['scores'] ?? const {});
        scores[_uid] = 0;
        final taps = Map<String, dynamic>.from(data['state']?['taps'] ?? const {});
        taps[_uid] = 0;
        tx.update(ref, {
          'members': [...members, _uid],
          'memberNames': names,
          'state': {...Map<String, dynamic>.from(data['state'] ?? const {}), 'scores': scores, 'taps': taps},
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });
      if (mounted) {
        _code.clear();
        Navigator.push(context, MaterialPageRoute(builder: (_) => ArcadeDuelRoomPage(roomId: ref.id)));
      }
    } catch (e) { _toast(e.toString().replaceFirst('Bad state: ', '')); }
    finally { if (mounted) setState(() => _busy = false); }
  }

  void _toast(String value) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value)));
  }

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.rtl,
    child: Scaffold(
      appBar: AppBar(title: const Text('غرف الألعاب المتزامنة')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const Text('أنشئ مباراة خاصة', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          const Text('اختار اللعبة، أنشئ رمزاً وارسله لصديقك. كل حركة ونتيجة تتزامن بين الأجهزة عبر Firestore.'),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            value: _mode,
            decoration: const InputDecoration(labelText: 'اللعبة'),
            items: _onlineGames.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
            onChanged: _busy ? null : (v) { if (v != null) setState(() => _mode = v); },
          ),
          const SizedBox(height: 12),
          FilledButton.icon(onPressed: _busy ? null : _create, icon: const Icon(Icons.add_circle_outline), label: const Text('إنشاء غرفة ونسخ الرمز')),
        ]))),
        const SizedBox(height: 12),
        Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const Text('انضم إلى غرفة صديقك', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
          TextField(controller: _code, keyboardType: TextInputType.number, maxLength: 6, decoration: const InputDecoration(labelText: 'رمز الغرفة المكوّن من 6 أرقام', counterText: '')),
          FilledButton.tonalIcon(onPressed: _busy ? null : _join, icon: const Icon(Icons.login), label: const Text('انضم إلى المباراة')),
        ]))),
        const SizedBox(height: 10),
        const Text('الغرفة تدعم حتى 4 لاعبين، ودردشة مستقلة وفويس مباشر.'),
        if (_busy) const Center(child: CircularProgressIndicator()),
      ]),
    ),
  );
}

class ArcadeDuelRoomPage extends StatefulWidget {
  final String roomId;
  const ArcadeDuelRoomPage({super.key, required this.roomId});
  @override State<ArcadeDuelRoomPage> createState() => _ArcadeDuelRoomPageState();
}

class _ArcadeDuelRoomPageState extends State<ArcadeDuelRoomPage> {
  final _db = FirebaseFirestore.instance;
  final _chat = TextEditingController();
  bool _busy = false;
  String? _notice;
  String get _uid => FirebaseAuth.instance.currentUser!.uid;
  DocumentReference<Map<String, dynamic>> get _room => _db.collection('arcadeRooms').doc(widget.roomId);

  Future<void> _start(Map<String, dynamic> room) async {
    try {
      await _db.runTransaction((tx) async {
        final snap = await tx.get(_room);
        final data = snap.data() ?? {};
        if (data['hostId'] != _uid) throw StateError('المضيف فقط يبدأ المباراة.');
        if (List<String>.from(data['members'] ?? const []).length < 2) throw StateError('انتظر انضمام صديق واحد على الأقل.');
        tx.update(_room, {'status': 'playing', 'updatedAt': FieldValue.serverTimestamp()});
      });
    } catch (e) { _toast(e.toString().replaceFirst('Bad state: ', '')); }
  }

  Future<void> _act(String action, {int lane = 0, bool correct = false}) async {
    if (_busy) return;
    setState(() { _busy = true; _notice = null; });
    try {
      await _db.runTransaction((tx) async {
        final snap = await tx.get(_room);
        if (!snap.exists) throw StateError('الغرفة غير موجودة.');
        final room = snap.data()!;
        final members = List<String>.from(room['members'] ?? const []);
        if (!members.contains(_uid)) throw StateError('حسابك ليس ضمن هذه الغرفة.');
        if (room['status'] != 'playing') throw StateError('المباراة لم تبدأ بعد.');
        final state = Map<String, dynamic>.from(room['state'] ?? const {});
        if ((state['winner'] ?? '').toString().isNotEmpty) throw StateError('انتهت المباراة؛ اطلب من المضيف إعادة الجولة.');
        final scores = Map<String, dynamic>.from(state['scores'] ?? const {});
        final taps = Map<String, dynamic>.from(state['taps'] ?? const {});
        var points = 0;
        final mode = state['mode']?.toString() ?? 'tap';
        var target = (state['targetLane'] as num?)?.toInt() ?? 1;
        var hazard = (state['hazardLane'] as num?)?.toInt() ?? 1;
        final random = Random.secure();
        switch (mode) {
          case 'tap':
            taps[_uid] = ((taps[_uid] as num?)?.toInt() ?? 0) + 1;
            points = 1;
            break;
          case 'tunnel':
            if (lane == hazard) { points = 0; } else { points = 2; }
            hazard = random.nextInt(3);
            break;
          case 'target':
          case 'stars':
          case 'hearts':
            points = lane == target ? 2 : 0;
            target = random.nextInt(3);
            break;
          case 'penalty':
            points = lane == target ? 0 : 3;
            target = random.nextInt(3);
            break;
          case 'pingpong':
            points = 1;
            break;
          case 'math':
            points = correct ? 3 : 0;
            if (correct) {
              state['mathA'] = 2 + random.nextInt(18);
              state['mathB'] = 2 + random.nextInt(12);
            }
            break;
          default:
            points = 1;
        }
        scores[_uid] = ((scores[_uid] as num?)?.toInt() ?? 0) + points;
        final tapsNow = (taps[_uid] as num?)?.toInt() ?? 0;
        final goalReached = mode == 'tap' ? tapsNow >= 20 : (scores[_uid] as num).toInt() >= 15;
        final winner = goalReached ? _uid : '';
        final names = Map<String, dynamic>.from(room['memberNames'] ?? const {});
        final actionLabel = '$action (+$points)';
        tx.update(_room, {
          'state': {
            ...state,
            'scores': scores,
            'taps': taps,
            'targetLane': target,
            'hazardLane': hazard,
            'round': ((state['round'] as num?)?.toInt() ?? 1) + 1,
            'lastAction': actionLabel,
            'lastPlayer': _uid,
            'winner': winner,
            'winnerName': winner.isEmpty ? '' : (names[_uid]?.toString() ?? 'لاعب'),
          },
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });
    } catch (e) {
      if (mounted) setState(() => _notice = e.toString().replaceFirst('Bad state: ', ''));
    } finally { if (mounted) setState(() => _busy = false); }
  }

  Future<void> _reset() async {
    try {
      await _db.runTransaction((tx) async {
        final snap = await tx.get(_room);
        final data = snap.data() ?? {};
        if (data['hostId'] != _uid) throw StateError('إعادة الجولة للمضيف فقط.');
        final members = List<String>.from(data['members'] ?? const []);
        final state = Map<String, dynamic>.from(data['state'] ?? const {});
        tx.update(_room, {
          'state': {
            ...state,
            'scores': {for (final id in members) id: 0},
            'taps': {for (final id in members) id: 0},
            'targetLane': Random.secure().nextInt(3),
            'hazardLane': Random.secure().nextInt(3),
            'round': 1,
            'winner': '',
            'winnerName': '',
            'lastAction': 'بدأت جولة جديدة',
          },
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });
    } catch (e) { _toast(e.toString()); }
  }

  Future<void> _sendChat() async {
    final value = _chat.text.trim();
    if (value.isEmpty) return;
    _chat.clear();
    try {
      await _room.collection('chat').add({'uid': _uid, 'text': value, 'createdAt': FieldValue.serverTimestamp()});
    } catch (e) { _toast('تعذر إرسال الرسالة: $e'); }
  }

  void _toast(String value) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value)));
  }

  @override
  void dispose() { _chat.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.rtl,
    child: Scaffold(
      appBar: AppBar(title: const Text('مباراة أصدقاء مباشرة'), actions: [
        IconButton(tooltip: 'الفويس', onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => LiveKitCallsPage(initialRoom: 'arcade_${widget.roomId}'))), icon: const Icon(Icons.mic_rounded)),
        IconButton(tooltip: 'إعادة الجولة', onPressed: _reset, icon: const Icon(Icons.restart_alt_rounded)),
      ]),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: _room.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return const Center(child: Text('تعذر الاتصال بالغرفة. راجع اتصال الإنترنت وقواعد Firestore.'));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final room = snapshot.data!.data();
          if (room == null) return const Center(child: Text('الغرفة غير موجودة.'));
          final members = List<String>.from(room['members'] ?? const []);
          final names = Map<String, dynamic>.from(room['memberNames'] ?? const {});
          final state = Map<String, dynamic>.from(room['state'] ?? const {});
          final scores = Map<String, dynamic>.from(state['scores'] ?? const {});
          final mode = state['mode']?.toString() ?? 'tap';
          final target = (state['targetLane'] as num?)?.toInt() ?? 1;
          final hazard = (state['hazardLane'] as num?)?.toInt() ?? 1;
          final winner = (state['winnerName'] ?? '').toString();
          final a = (state['mathA'] as num?)?.toInt() ?? 7;
          final b = (state['mathB'] as num?)?.toInt() ?? 5;
          return ListView(padding: const EdgeInsets.all(14), children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), gradient: const LinearGradient(colors: [Color(0xFF171936), Color(0xFF6554D9), Color(0xFF13A89E)])),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(_onlineGames[mode] ?? 'تحدي الأصدقاء', style: const TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.w900)),
                Text('رمز الغرفة: ${room['roomCode'] ?? ''}  •  ${members.length}/4 لاعبين', style: const TextStyle(color: Colors.white70)),
                const SizedBox(height: 8),
                Text(room['status'] == 'playing' ? 'مباراة متزامنة LIVE' : 'بانتظار اللاعبين', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                if (room['status'] != 'playing' && room['hostId'] == _uid)
                  FilledButton(onPressed: members.length >= 2 ? () => _start(room) : null, child: const Text('ابدأ المباراة')),
                if (winner.isNotEmpty) Text('🏆 الفائز: $winner', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
              ]),
            ),
            const SizedBox(height: 12),
            ...members.map((id) => Card(child: ListTile(
              leading: CircleAvatar(child: Text((names[id]?.toString().isNotEmpty ?? false) ? names[id].toString().characters.first : 'ل')),
              title: Text(id == _uid ? 'أنت' : names[id]?.toString() ?? 'لاعب'),
              trailing: Text('${scores[id] ?? 0} نقطة', style: const TextStyle(fontWeight: FontWeight.w900)),
            ))),
            if (room['status'] == 'playing' && winner.isEmpty) ...[
              const SizedBox(height: 10),
              _controls(mode, target, hazard, a, b),
            ],
            if (_notice != null) Padding(padding: const EdgeInsets.all(8), child: Text(_notice!, style: TextStyle(color: Theme.of(context).colorScheme.error))),
            const SizedBox(height: 12),
            const Text('دردشة المباراة', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
            SizedBox(height: 190, child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _room.collection('chat').orderBy('createdAt').limit(50).snapshots(),
              builder: (context, chatSnap) {
                if (chatSnap.hasError) return const Center(child: Text('تعذر تحميل الدردشة.'));
                if (!chatSnap.hasData) return const Center(child: CircularProgressIndicator());
                return ListView(children: chatSnap.data!.docs.map((d) {
                  final m = d.data();
                  return ListTile(dense: true, title: Text(m['uid'] == _uid ? 'أنت' : (names[m['uid']] ?? 'لاعب').toString()), subtitle: Text((m['text'] ?? '').toString()));
                }).toList());
              },
            )),
            Row(children: [
              Expanded(child: TextField(controller: _chat, onSubmitted: (_) => _sendChat(), decoration: const InputDecoration(hintText: 'اكتب رسالة...', border: OutlineInputBorder()))),
              IconButton.filled(onPressed: _sendChat, icon: const Icon(Icons.send)),
            ]),
            const SizedBox(height: 8),
            FilledButton.tonalIcon(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => LiveKitCallsPage(initialRoom: 'arcade_${widget.roomId}'))), icon: const Icon(Icons.mic_rounded), label: const Text('انضم إلى فويس المباراة')),
            const Text('كل حركة تُحفظ في الغرفة وتظهر مباشرة على أجهزة اللاعبين.'),
          ]);
        },
      ),
    ),
  );

  Widget _controls(String mode, int target, int hazard, int a, int b) {
    if (mode == 'tap') return SizedBox(height: 190, child: FilledButton.icon(onPressed: _busy ? null : () => _act('ضغطة'), icon: const Icon(Icons.touch_app, size: 38), label: const Text('اضغط بأسرع ما يمكن — أول لاعب يصل 20 يفوز')));
    if (mode == 'pingpong') return SizedBox(height: 170, child: FilledButton.icon(onPressed: _busy ? null : () => _act('إرجاع الكرة'), icon: const Icon(Icons.sports_tennis_rounded, size: 36), label: const Text('اضغط لإرجاع الكرة وجمع نقطة')));
    if (mode == 'math') return Column(children: [
      Text('$a + $b = ؟', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
      Wrap(spacing: 8, children: [a + b, a + b + 1, a + b - 1].map((v) => FilledButton(onPressed: _busy ? null : () => _act('إجابة $v', correct: v == a + b), child: Text('$v'))).toList()),
    ]);
    if (mode == 'tunnel') return Column(children: [
      const Text('اختار مساراً وتجنب الحاجز 🚧'),
      Row(children: List.generate(3, (i) => Expanded(child: Padding(padding: const EdgeInsets.all(4), child: FilledButton(onPressed: _busy ? null : () => _act('المسار ${i + 1}', lane: i), child: Text(i == hazard ? '🚧' : 'المسار ${i + 1}')))))),
    ]);
    final labels = mode == 'penalty' ? ['يسار المرمى','وسط المرمى','يمين المرمى'] : ['يسار','وسط','يمين'];
    return Column(children: [
      Text(mode == 'penalty' ? 'الحارس يغطي زاوية — اختار مكان التسديد ⚽' : 'اضغط الهدف الصحيح: ⭐ الهدف الحالي هو اللمعة البنفسجية'),
      Row(children: List.generate(3, (i) => Expanded(child: Padding(padding: const EdgeInsets.all(4), child: FilledButton(
        style: FilledButton.styleFrom(backgroundColor: (mode != 'penalty' && i == target) ? Colors.deepPurple : null),
        onPressed: _busy ? null : () => _act(labels[i], lane: i),
        child: Text(mode == 'penalty' ? '🥅 ${labels[i]}' : (i == target ? '✨ ${labels[i]}' : labels[i]),
      )))))),
    ]);
  }
}
