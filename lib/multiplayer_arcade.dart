import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class MultiplayerArcadePage extends StatefulWidget {
  const MultiplayerArcadePage({super.key});
  @override
  State<MultiplayerArcadePage> createState() => _MultiplayerArcadePageState();
}

class _MultiplayerArcadePageState extends State<MultiplayerArcadePage> {
  final _db = FirebaseFirestore.instance;
  final _code = TextEditingController();
  bool _busy = false;
  String get _uid => FirebaseAuth.instance.currentUser!.uid;
  String get _name => FirebaseAuth.instance.currentUser?.displayName ?? 'لاعب';

  @override
  void dispose() { _code.dispose(); super.dispose(); }

  Future<void> _createRoom() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final ref = _db.collection('gameRooms').doc();
      await ref.set({
        'game': 'xo', 'hostId': _uid, 'members': [_uid],
        'memberNames': {_uid: _name}, 'status': 'waiting',
        'board': List<String>.filled(9, ''), 'turn': _uid, 'winner': '',
        'createdAt': FieldValue.serverTimestamp(), 'updatedAt': FieldValue.serverTimestamp(),
      });
      if (!mounted) return;
      Navigator.push(context, MaterialPageRoute(builder: (_) => OnlineXoRoomPage(roomId: ref.id)));
    } catch (e) {
      _toast('تعذر إنشاء الغرفة. تأكد من نشر قواعد الألعاب: ' + e.toString());
    } finally { if (mounted) setState(() => _busy = false); }
  }

  Future<void> _joinRoom([String? roomId]) async {
    final id = (roomId ?? _code.text).trim();
    if (id.isEmpty || _busy) return;
    setState(() => _busy = true);
    try {
      final ref = _db.collection('gameRooms').doc(id);
      await _db.runTransaction((tx) async {
        final snap = await tx.get(ref);
        if (!snap.exists) throw Exception('الغرفة غير موجودة');
        final data = snap.data()!;
        final members = List<String>.from(data['members'] ?? []);
        if (members.contains(_uid)) return;
        if (data['game'] != 'xo' || data['status'] != 'waiting' || members.length >= 2) {
          throw Exception('الغرفة مكتملة أو بدأت اللعبة');
        }
        tx.update(ref, {
          'members': FieldValue.arrayUnion([_uid]),
          'memberNames.' + _uid: _name,
          'status': 'playing', 'updatedAt': FieldValue.serverTimestamp(),
        });
      });
      if (!mounted) return;
      _code.clear();
      Navigator.push(context, MaterialPageRoute(builder: (_) => OnlineXoRoomPage(roomId: id)));
    } catch (e) {
      _toast('ما كدرنا ننضم: ' + e.toString().replaceFirst('Exception: ', ''));
    } finally { if (mounted) setState(() => _busy = false); }
  }

  void _toast(String value) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value)));

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.rtl,
    child: Scaffold(
      appBar: AppBar(title: const Text('صالة الألعاب أونلاين')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: const LinearGradient(colors: [Color(0xFF22204D), Color(0xFF6554D9), Color(0xFF168E9B)]),
          ),
          child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(Icons.sports_esports, color: Colors.white, size: 38),
            SizedBox(height: 10),
            Text('العبوا سوا وين ما تكونون', style: TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.bold)),
            SizedBox(height: 6),
            Text('غرف خاصة • رمز دعوة • مزامنة مباشرة بين اللاعبين', style: TextStyle(color: Colors.white70)),
          ]),
        ),
        const SizedBox(height: 16),
        Card(child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const Text('❎⭕ إكس أو أونلاين', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 5),
          const Text('تحدّى صديقك مباشرة. كل حركة تظهر عند الطرفين فوراً.'),
          const SizedBox(height: 12),
          FilledButton.icon(onPressed: _busy ? null : _createRoom, icon: const Icon(Icons.add_circle_outline), label: const Text('إنشاء غرفة جديدة')),
          const SizedBox(height: 8),
          TextField(controller: _code, textCapitalization: TextCapitalization.none, decoration: const InputDecoration(labelText: 'رمز الغرفة', border: OutlineInputBorder())),
          const SizedBox(height: 8),
          OutlinedButton.icon(onPressed: _busy ? null : () => _joinRoom(), icon: const Icon(Icons.login), label: const Text('انضم إلى صديق')),
        ]))),
        const SizedBox(height: 8),
        const Text('ألعاب قادمة للصالة', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        _comingCard(Icons.casino_outlined, 'لودو 2D', 'أربعة لاعبين • نرد • أحجار تتحرك على اللوحة'),
        _comingCard(Icons.style_outlined, 'جاكارو', 'لعب جماعي بالورق وتحريك الأحجار'),
        _comingCard(Icons.visibility_outlined, 'من هو القاتل؟', 'أدوار سرية، تحقيق، تصويت وجولات مع الأصدقاء'),
        _comingCard(Icons.extension_outlined, 'ألعاب جماعية إضافية', 'تحديات وأسئلة وألعاب سريعة متزامنة'),
        const SizedBox(height: 8),
        const Text('ملاحظة: الغرف تحتاج اتصال إنترنت وقواعد Firestore الخاصة بالألعاب منشورة.', style: TextStyle(color: Colors.grey, fontSize: 12)),
      ]),
    ),
  );

  Widget _comingCard(IconData icon, String title, String subtitle) => Card(
    child: ListTile(leading: CircleAvatar(child: Icon(icon)), title: Text(title), subtitle: Text(subtitle), trailing: const Chip(label: Text('ضمن خطة الإضافة'))),
  );
}

class OnlineXoRoomPage extends StatefulWidget {
  const OnlineXoRoomPage({super.key, required this.roomId});
  final String roomId;
  @override
  State<OnlineXoRoomPage> createState() => _OnlineXoRoomPageState();
}

class _OnlineXoRoomPageState extends State<OnlineXoRoomPage> {
  final _db = FirebaseFirestore.instance;
  bool _busy = false;
  String get _uid => FirebaseAuth.instance.currentUser!.uid;
  DocumentReference<Map<String, dynamic>> get _room => _db.collection('gameRooms').doc(widget.roomId);
  static const _wins = [[0,1,2],[3,4,5],[6,7,8],[0,3,6],[1,4,7],[2,5,8],[0,4,8],[2,4,6]];

  Future<void> _play(int index) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await _db.runTransaction((tx) async {
        final snap = await tx.get(_room);
        if (!snap.exists) throw Exception('الغرفة انتهت');
        final current = snap.data()!;
        final members = List<String>.from(current['members'] ?? []);
        final board = List<String>.from(current['board'] ?? List<String>.filled(9, ''));
        if (!members.contains(_uid) || current['status'] != 'playing' ||
            current['turn'] != _uid || index < 0 || index > 8 || board[index].isNotEmpty) {
          throw Exception('انتظر دورك أو هذه الخانة مأخوذة');
        }
        final mark = members.first == _uid ? 'X' : 'O';
        board[index] = mark;
        String winner = '';
        for (final line in _wins) {
          if (board[line[0]].isNotEmpty && board[line[0]] == board[line[1]] && board[line[1]] == board[line[2]]) {
            winner = _uid;
            break;
          }
        }
        final draw = winner.isEmpty && board.every((v) => v.isNotEmpty);
        final next = members.firstWhere((m) => m != _uid);
        tx.update(_room, {
          'board': board, 'winner': winner.isNotEmpty ? winner : (draw ? 'draw' : ''),
          'turn': winner.isNotEmpty || draw ? '' : next,
          'status': winner.isNotEmpty || draw ? 'finished' : 'playing',
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))));
    } finally { if (mounted) setState(() => _busy = false); }
  }

  Future<void> _rematch(Map<String, dynamic> data) async {
    if (data['hostId'] != _uid) return;
    await _room.update({
      'board': List<String>.filled(9, ''), 'winner': '',
      'turn': (data['members'] as List).first,
      'status': (data['members'] as List).length == 2 ? 'playing' : 'waiting',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.rtl,
    child: Scaffold(
      appBar: AppBar(title: const Text('إكس أو • مواجهة أصدقاء')),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: _room.snapshots(),
        builder: (context, snap) {
          if (snap.hasError) return const Center(child: Text('تعذر الاتصال بالغرفة. راجع قواعد Firestore.'));
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          if (!snap.data!.exists) return const Center(child: Text('الغرفة غير موجودة.'));
          final data = snap.data!.data()!;
          final members = List<String>.from(data['members'] ?? []);
          final names = Map<String, dynamic>.from(data['memberNames'] ?? {});
          final board = List<String>.from(data['board'] ?? List<String>.filled(9, ''));
          final status = data['status'] as String? ?? 'waiting';
          final winner = data['winner'] as String? ?? '';
          final mine = members.indexOf(_uid);
          final myMark = mine == 0 ? 'X' : 'O';
          final turn = data['turn'] == _uid;
          final message = status == 'waiting' ? 'شارك رمز الغرفة مع صديقك حتى ينضم'
              : status == 'finished' ? (winner == 'draw' ? 'تعادل! لعبة حلوة 🤝' : (winner == _uid ? 'فزت! تستاهل 🏆' : 'صديقك فاز، جولة ثانية؟'))
              : (turn ? 'دورك الآن • ' + myMark : 'دور ' + (names[data['turn']] ?? 'صديقك').toString());
          return ListView(padding: const EdgeInsets.all(16), children: [
            Card(child: Padding(padding: const EdgeInsets.all(14), child: Column(children: [
              const Text('رمز الدعوة', style: TextStyle(color: Colors.grey)),
              SelectableText(widget.roomId, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold, letterSpacing: 1)),
              TextButton.icon(onPressed: () { Clipboard.setData(ClipboardData(text: widget.roomId)); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم نسخ الرمز'))); }, icon: const Icon(Icons.copy), label: const Text('نسخ الرمز')),
              const Divider(),
              Text((members.isNotEmpty ? (names[members[0]] ?? 'اللاعب الأول') : 'اللاعب الأول').toString() + '  X   •   O  ' + (members.length > 1 ? (names[members[1]] ?? 'اللاعب الثاني').toString() : 'بانتظار صديق')),
            ]))),
            const SizedBox(height: 14),
            Center(child: Text(message, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
            const SizedBox(height: 14),
            AspectRatio(aspectRatio: 1, child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 8, mainAxisSpacing: 8),
              itemCount: 9,
              itemBuilder: (context, i) => InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: status == 'playing' && turn && board[i].isEmpty ? () => _play(i) : null,
                child: Ink(
                  decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(18), border: Border.all(color: Theme.of(context).colorScheme.outlineVariant)),
                  child: Center(child: Text(board[i], style: TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: board[i] == 'X' ? Colors.deepPurple : Colors.teal))),
                ),
              ),
            )),
            const SizedBox(height: 14),
            if (status == 'finished' && data['hostId'] == _uid)
              FilledButton.icon(onPressed: _busy ? null : () => _rematch(data), icon: const Icon(Icons.replay), label: const Text('ابدأ جولة جديدة')),
            if (status == 'waiting' && mine == 0)
              const Text('خلي صديقك يفتح صالة الألعاب ويدخل رمز الغرفة أعلاه.', textAlign: TextAlign.center),
          ]);
        },
      ),
    ),
  );
}
