import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'livekit_calls.dart';

/// A synchronized cooperative 2D grid adventure built on the existing
/// private arcade room. Every player's move is committed transactionally.
class FriendWorldGamePage extends StatefulWidget {
  final String roomId;
  final String title;
  const FriendWorldGamePage({super.key, required this.roomId, required this.title});
  @override State<FriendWorldGamePage> createState() => _FriendWorldGamePageState();
}

class _FriendWorldGamePageState extends State<FriendWorldGamePage> {
  final _db = FirebaseFirestore.instance;
  bool _busy = false;
  String? _notice;
  final TextEditingController _chatController = TextEditingController();
  String get _uid => FirebaseAuth.instance.currentUser!.uid;
  DocumentReference<Map<String, dynamic>> get _room => _db.collection('arcadeRooms').doc(widget.roomId);
  static const int _side = 9;
  static const Set<int> _walls = {20, 21, 22, 38, 39, 40, 56, 57, 58};
  static const List<int> _firstStars = [4, 13, 18, 31, 36, 49, 64, 76];

  Map<String, dynamic> _initialState(List<String> members) {
    final players = <String, int>{};
    for (var i = 0; i < members.length; i++) {
      players[members[i]] = i == 0 ? 0 : i == 1 ? 80 : i == 2 ? 8 : 72;
    }
    return {
      'mode': 'cooperative_2d',
      'players': players,
      'stars': _firstStars,
      'score': 0,
      'moves': 0,
      'wave': 1,
      'finished': false,
    };
  }

  Future<void> _ensureState(List<String> members, Map<String, dynamic> state) async {
    final existing = state['players'] is Map
        ? Map<String, dynamic>.from(state['players'] as Map)
        : <String, dynamic>{};
    if (state['mode'] == 'cooperative_2d' && members.every(existing.containsKey)) return;
    await _db.runTransaction((tx) async {
      final snap = await tx.get(_room);
      if (!snap.exists) return;
      final room = snap.data()!;
      final current = Map<String, dynamic>.from(room['state'] ?? const {});
      final roomMembers = List<String>.from(room['members'] ?? members);
      final currentPlayers = current['players'] is Map
          ? Map<String, dynamic>.from(current['players'] as Map)
          : <String, dynamic>{};
      if (current['mode'] != 'cooperative_2d') {
        tx.update(_room, {'state': _initialState(roomMembers), 'updatedAt': FieldValue.serverTimestamp()});
        return;
      }
      const spawns = [0, 80, 8, 72];
      for (var i = 0; i < roomMembers.length && i < spawns.length; i++) {
        currentPlayers.putIfAbsent(roomMembers[i], () => spawns[i]);
      }
      tx.update(_room, {'state': {...current, 'players': currentPlayers}, 'updatedAt': FieldValue.serverTimestamp()});
    });
  }

  @override
  void dispose() {
    _chatController.dispose();
    super.dispose();
  }

  Future<void> _sendChat() async {
    final text = _chatController.text.trim();
    if (text.isEmpty || text.length > 500) return;
    _chatController.clear();
    try {
      await _room.collection('chat').add({
        'uid': _uid,
        'text': text,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (mounted) setState(() => _notice = 'تعذر إرسال رسالة الغرفة: $e');
    }
  }

  Future<void> _move(int target) async {
    if (_busy) return;
    setState(() { _busy = true; _notice = null; });
    try {
      await _db.runTransaction((tx) async {
        final snap = await tx.get(_room);
        if (!snap.exists) throw StateError('الغرفة غير موجودة.');
        final room = snap.data()!;
        final members = List<String>.from(room['members'] ?? const []);
        if (!members.contains(_uid)) throw StateError('هذا الحساب ليس ضمن لاعبي الغرفة.');
        if (room['status'] != 'playing') throw StateError('ابدأوا الجولة من غرفة الانتظار أولاً.');
        final state = Map<String, dynamic>.from(room['state'] ?? const {});
        if (state['mode'] != 'cooperative_2d') throw StateError('جاري تجهيز عالم اللعبة، حاول بعد لحظة.');
        final players = Map<String, dynamic>.from(state['players'] ?? const {});
        final current = (players[_uid] as num?)?.toInt();
        if (current == null) throw StateError('تعذر تحديد مكان شخصيتك.');
        final distance = (target ~/ _side - current ~/ _side).abs() + (target % _side - current % _side).abs();
        if (target < 0 || target >= _side * _side || distance != 1) throw StateError('اختار خانة مجاورة لشخصيتك.');
        if (_walls.contains(target)) throw StateError('هذا الطريق مغلق؛ جرّب طريقاً آخر.');
        if (players.values.any((p) => (p as num).toInt() == target)) throw StateError('لا يمكن الوقوف فوق شخصية صديقك.');
        final stars = List<int>.from(state['stars'] ?? _firstStars);
        var score = (state['score'] as num?)?.toInt() ?? 0;
        if (stars.remove(target)) score++;
        var wave = (state['wave'] as num?)?.toInt() ?? 1;
        if (stars.isEmpty) {
          wave++;
          stars.addAll(_firstStars.map((v) => (v + wave * 7) % 81).where((v) => !_walls.contains(v) && !players.values.any((p) => p == v)));
        }
        players[_uid] = target;
        final moves = ((state['moves'] as num?)?.toInt() ?? 0) + 1;
        tx.update(_room, {
          'state': {...state, 'players': players, 'stars': stars, 'score': score, 'moves': moves, 'wave': wave},
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });
      HapticFeedback.selectionClick();
    } catch (e) {
      if (mounted) setState(() => _notice = e.toString().replaceFirst('Bad state: ', ''));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.rtl,
    child: Scaffold(
      appBar: AppBar(title: const Text('مغامرة الأصدقاء • 2D'), actions: [
        IconButton(tooltip: 'غرفة الصوت', onPressed: () => Navigator.push(context, MaterialPageRoute(
          builder: (_) => LiveKitCallsPage(initialRoom: 'arcade_${widget.roomId}'),
        )), icon: const Icon(Icons.mic_rounded)),
        IconButton(tooltip: 'نسخ رمز الغرفة', onPressed: () async {
          final snap = await _room.get();
          await Clipboard.setData(ClipboardData(text: snap.data()?['roomCode']?.toString() ?? widget.roomId));
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم نسخ رمز الغرفة')));
        }, icon: const Icon(Icons.copy_rounded)),
      ]),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: _room.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return const Center(child: Text('تعذر الاتصال بعالم اللعبة. تحقق من اتصال الإنترنت وقواعد الغرفة.'));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final room = snapshot.data!.data();
          if (room == null) return const Center(child: Text('الغرفة غير موجودة.'));
          final members = List<String>.from(room['members'] ?? const []);
          final state = Map<String, dynamic>.from(room['state'] ?? const {});
          if (state['mode'] != 'cooperative_2d' || state['players'] is! Map) {
            _ensureState(members, state);
            return const Center(child: CircularProgressIndicator());
          }
          final players = Map<String, dynamic>.from(state['players'] ?? const {});
          final stars = List<int>.from(state['stars'] ?? _firstStars);
          final myPosition = (players[_uid] as num?)?.toInt() ?? 0;
          final score = (state['score'] as num?)?.toInt() ?? 0;
          final names = Map<String, dynamic>.from(room['memberNames'] ?? const {});
          final roomCode = room['roomCode']?.toString() ?? widget.roomId;
          return ListView(padding: const EdgeInsets.all(14), children: [
            Container(
              padding: const EdgeInsets.all(17),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                gradient: const LinearGradient(colors: [Color(0xFF151B3B), Color(0xFF6654D9), Color(0xFF008F91)]),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('CO-OP WORLD • LIVE', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w900)),
                const SizedBox(height: 7),
                const Text('اجمعوا النجوم كفريق واحد ✨', style: TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.w900)),
                const SizedBox(height: 8),
                Text('النقاط المشتركة: $score  •  المرحلة: ${state['wave'] ?? 1}  •  الحركات: ${state['moves'] ?? 0}', style: const TextStyle(color: Colors.white)),
                const SizedBox(height: 8),
                Text('اللاعبون: ${members.map((m) => names[m]?.toString() ?? (m == _uid ? 'أنت' : 'صديق')).join('  •  ')}', style: const TextStyle(color: Colors.white70)),
              ]),
            ),
            const SizedBox(height: 12),
            if (room['status'] != 'playing')
              const Card(child: Padding(padding: EdgeInsets.all(14), child: Text('بانتظار بدء الجولة من غرفة الأصدقاء. ارجعوا للغرفة واضغطوا بدء اللعب.'))),
            AspectRatio(
              aspectRatio: 1,
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _side * _side,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: _side, crossAxisSpacing: 3, mainAxisSpacing: 3),
                itemBuilder: (context, cell) {
                  final playerEntries = players.entries.where((e) => (e.value as num).toInt() == cell).toList();
                  final player = playerEntries.isEmpty ? null : playerEntries.first.key;
                  final isMe = player == _uid;
                  final star = stars.contains(cell);
                  final wall = _walls.contains(cell);
                  final row = cell ~/ _side, col = cell % _side;
                  final canMove = room['status'] == 'playing' && !wall &&
                    ((row - myPosition ~/ _side).abs() + (col - myPosition % _side).abs() == 1) &&
                    !players.values.any((v) => (v as num).toInt() == cell);
                  return InkWell(
                    onTap: canMove && !_busy ? () => _move(cell) : null,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      decoration: BoxDecoration(
                        color: isMe ? const Color(0xFF6654D9) : player != null ? const Color(0xFF008F91) :
                          wall ? Colors.blueGrey.shade800 : star ? Colors.amber.withValues(alpha: .22) : Theme.of(context).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: canMove ? Colors.lightGreenAccent : Colors.transparent, width: 1.5),
                      ),
                      child: Center(child: Text(isMe ? '🧙' : player != null ? '🧝' : wall ? '🪨' : star ? '⭐' : '', style: const TextStyle(fontSize: 15))),
                    ),
                  );
                },
              ),
            ),
            if (_busy) const LinearProgressIndicator(),
            if (_notice != null) Padding(padding: const EdgeInsets.all(8), child: Text(_notice!, style: TextStyle(color: Theme.of(context).colorScheme.error))),
            const SizedBox(height: 10),
            SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => LiveKitCallsPage(initialRoom: 'arcade_${widget.roomId}'),
            )), icon: const Icon(Icons.mic_rounded), label: const Text('فويس مباشر'))),
            const SizedBox(height: 16),
            const Text('دردشة لاعبي الغرفة', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17)),
            const SizedBox(height: 8),
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _room.collection('chat').orderBy('createdAt', descending: true).limit(30).snapshots(),
              builder: (context, chatSnapshot) {
                if (chatSnapshot.hasError) {
                  return const Text('تعذر تحميل دردشة الغرفة. تحقق من صلاحيات Firestore.');
                }
                final messages = chatSnapshot.data?.docs ?? [];
                if (messages.isEmpty) {
                  return const Padding(padding: EdgeInsets.all(12), child: Text('ابدأوا الحديث أثناء المغامرة.'));
                }
                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  reverse: true,
                  itemCount: messages.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 5),
                  itemBuilder: (context, index) {
                    final message = messages[index].data();
                    final sender = message['uid']?.toString() ?? '';
                    final senderName = names[sender]?.toString() ?? (sender == _uid ? 'أنت' : 'لاعب');
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(senderName, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                        const SizedBox(height: 3),
                        Text(message['text']?.toString() ?? ''),
                      ]),
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: TextField(
                controller: _chatController,
                maxLength: 500,
                decoration: const InputDecoration(
                  hintText: 'اكتب رسالة للاعبين...',
                  counterText: '',
                  border: OutlineInputBorder(),
                ),
                onSubmitted: (_) => _sendChat(),
              )),
              const SizedBox(width: 8),
              IconButton.filled(onPressed: _sendChat, icon: const Icon(Icons.send_rounded)),
            ]),
            const Padding(padding: EdgeInsets.only(top: 10), child: Text('كل حركة تتزامن مباشرة عند جميع اللاعبين. اجمعوا النجوم معاً وتجاوزوا الصخور كفريق.', textAlign: TextAlign.center)),
            Text('رمز الغرفة: $roomCode', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold)),
          ]);
        },
      ),
    ),
  );
}


class FriendWorldLobbyPage extends StatefulWidget {
  const FriendWorldLobbyPage({super.key});
  @override State<FriendWorldLobbyPage> createState() => _FriendWorldLobbyPageState();
}

class _FriendWorldLobbyPageState extends State<FriendWorldLobbyPage> {
  final _db = FirebaseFirestore.instance;
  final _code = TextEditingController();
  bool _busy = false;
  String? _roomId;
  String get _uid => FirebaseAuth.instance.currentUser!.uid;
  String get _name => FirebaseAuth.instance.currentUser?.displayName ?? 'لاعب';

  @override
  void dispose() { _code.dispose(); super.dispose(); }

  Future<void> _create() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final ref = _db.collection('arcadeRooms').doc();
      final code = (100000 + Random.secure().nextInt(900000)).toString();
      await ref.set({
        'hostId': _uid, 'gameId': 'arcade_friend_world',
        'members': [_uid], 'memberNames': {_uid: _name},
        'roomCode': code, 'status': 'waiting', 'visibility': 'private',
        'state': {'mode': 'cooperative_2d', 'players': {}, 'stars': [], 'score': 0, 'moves': 0, 'wave': 1, 'finished': false},
        'createdAt': FieldValue.serverTimestamp(), 'updatedAt': FieldValue.serverTimestamp(),
      });
      if (mounted) setState(() => _roomId = ref.id);
      await Clipboard.setData(ClipboardData(text: code));
    } catch (e) { _message('تعذر إنشاء الغرفة: $e'); }
    finally { if (mounted) setState(() => _busy = false); }
  }

  Future<void> _join() async {
    final code = _code.text.trim();
    if (!RegExp(r'^\d{6}$').hasMatch(code) || _busy) {
      _message('أدخل رمز غرفة صحيحاً من 6 أرقام.');
      return;
    }
    setState(() => _busy = true);
    try {
      final result = await _db.collection('arcadeRooms').where('roomCode', isEqualTo: code).limit(2).get();
      if (result.docs.isEmpty) throw StateError('ما لقينا غرفة بهذا الرمز. تأكد من الأرقام الستة.');
      if (result.docs.length > 1) throw StateError('الرمز غير فريد، اطلب من صديقك إنشاء غرفة جديدة.');
      final ref = result.docs.first.reference;
      final profile = await _db.collection('publicProfiles').doc(_uid).get();
      final memberName = (profile.data()?['name'] ?? _name).toString();
      await _db.runTransaction((tx) async {
        final snap = await tx.get(ref);
        final data = snap.data() ?? {};
        final members = List<String>.from(data['members'] ?? const []);
        if (data['gameId'] != 'arcade_friend_world') throw StateError('هذا الرمز ليس لعالم الأصدقاء.');
        if (data['roomCode']?.toString() != code) throw StateError('رمز الغرفة غير مطابق.');
        if (members.contains(_uid)) return;
        if (data['status'] != 'waiting' || members.length >= 4) throw StateError('الغرفة بدأت أو اكتمل عدد اللاعبين.');
        tx.update(ref, {
          'members': [...members, _uid],
          'memberNames.$_uid': memberName,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });
      if (mounted) setState(() => _roomId = ref.id);
      _code.clear();
    } catch (e) { _message(e.toString().replaceFirst('Bad state: ', '')); }
    finally { if (mounted) setState(() => _busy = false); }
  }

  Future<void> _start() async {
    try {
      await _db.runTransaction((tx) async {
        final ref = _db.collection('arcadeRooms').doc(_roomId);
        final snap = await tx.get(ref);
        final data = snap.data() ?? {};
        if (data['hostId'] != _uid) throw StateError('بدء الجولة للمضيف فقط.');
        if (List<String>.from(data['members'] ?? const []).length < 2) throw StateError('تحتاجون لاعبين اثنين على الأقل.');
        tx.update(ref, {'status': 'playing', 'updatedAt': FieldValue.serverTimestamp()});
      });
      if (mounted) Navigator.push(context, MaterialPageRoute(builder: (_) => FriendWorldGamePage(roomId: _roomId!, title: 'عالم الأصدقاء')));
    } catch (e) { _message(e.toString().replaceFirst('Bad state: ', '')); }
  }

  void _message(String value) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value)));
  }

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.rtl,
    child: Scaffold(
      appBar: AppBar(title: const Text('عالم الأصدقاء 2D')),
      body: _roomId == null
        ? ListView(padding: const EdgeInsets.all(16), children: [
            const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('استكشفوا خريطة مشتركة، تحركوا بالتناوب، واجمعوا النجوم كفريق. الغرفة تدعم حتى 4 لاعبين مع دردشة وصوت.'))),
            FilledButton.icon(onPressed: _busy ? null : _create, icon: const Icon(Icons.add), label: const Text('إنشاء غرفة ونسخ الرمز')),
            const SizedBox(height: 18),
            TextField(controller: _code, keyboardType: TextInputType.number, maxLength: 6, decoration: const InputDecoration(labelText: 'رمز غرفة صديقك')),
            FilledButton.tonalIcon(onPressed: _busy ? null : _join, icon: const Icon(Icons.login), label: const Text('انضم للغرفة')),
            if (_busy) const Center(child: CircularProgressIndicator()),
          ])
        : StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: _db.collection('arcadeRooms').doc(_roomId).snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              final room = snapshot.data?.data();
              if (room == null) return const Center(child: Text('الغرفة غير موجودة.'));
              final members = List<String>.from(room['members'] ?? const []);
              final names = Map<String, dynamic>.from(room['memberNames'] ?? const {});
              final code = (room['roomCode'] ?? '').toString();
              return ListView(padding: const EdgeInsets.all(16), children: [
                Card(child: ListTile(
                  title: const Text('رمز الغرفة'),
                  subtitle: Text(code, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 3)),
                  trailing: IconButton(icon: const Icon(Icons.copy), onPressed: () async { await Clipboard.setData(ClipboardData(text: code)); _message('تم نسخ الرمز'); }),
                )),
                Text('اللاعبون ' + members.length.toString() + '/4', style: const TextStyle(fontWeight: FontWeight.bold)),
                ...members.map((id) => ListTile(leading: const Icon(Icons.person), title: Text(id == _uid ? 'أنت' : (names[id] ?? 'صديق').toString()))),
                if (room['status'] == 'waiting')
                  FilledButton.icon(onPressed: room['hostId'] == _uid ? _start : null, icon: const Icon(Icons.play_arrow), label: const Text('ابدأ المغامرة (لاعبان على الأقل)')),
                if (room['status'] == 'playing')
                  FilledButton.icon(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => FriendWorldGamePage(roomId: _roomId!, title: 'عالم الأصدقاء'))), icon: const Icon(Icons.map), label: const Text('دخول عالم اللعبة')),
              ]);
            },
          ),
    ),
  );
}
