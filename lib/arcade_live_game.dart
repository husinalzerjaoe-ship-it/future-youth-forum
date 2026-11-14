import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

/// Shared turn-based room state. Every action is committed transactionally so
/// all connected clients render the same turn, score and move history.
class ArcadeLiveGamePage extends StatefulWidget {
  final String roomId;
  final String title;
  const ArcadeLiveGamePage({super.key, required this.roomId, required this.title});

  @override
  State<ArcadeLiveGamePage> createState() => _ArcadeLiveGamePageState();
}

class _ArcadeLiveGamePageState extends State<ArcadeLiveGamePage> {
  final _db = FirebaseFirestore.instance;
  final _random = Random();
  bool _busy = false;
  String? _notice;
  String get _uid => FirebaseAuth.instance.currentUser!.uid;
  DocumentReference<Map<String, dynamic>> get _room =>
      _db.collection('arcadeRooms').doc(widget.roomId);

  Future<void> _act(String label, int points) async {
    if (_busy) return;
    setState(() { _busy = true; _notice = null; });
    try {
      await _db.runTransaction((tx) async {
        final snap = await tx.get(_room);
        if (!snap.exists) throw StateError('الغرفة غير موجودة.');
        final room = snap.data()!;
        final members = List<String>.from(room['members'] ?? const []);
        if (!members.contains(_uid)) throw StateError('أنت لست عضواً في هذه الغرفة.');
        final state = Map<String, dynamic>.from(room['state'] ?? const {});
        final turn = (state['turnIndex'] as num?)?.toInt() ?? 0;
        final current = members.isEmpty ? '' : members[turn % members.length];
        if (members.length > 1 && current != _uid) {
          throw StateError('انتظر دور اللاعب التالي.');
        }
        final scores = Map<String, dynamic>.from(state['scores'] ?? const {});
        final nextScore = ((scores[_uid] as num?)?.toInt() ?? 0) + points;
        scores[_uid] = nextScore;
        final oldLog = List<Map<String, dynamic>>.from(
          (state['log'] as List? ?? const []).map((e) => Map<String, dynamic>.from(e as Map)),
        );
        oldLog.add({
          'uid': _uid,
          'action': label,
          'points': points,
          'score': nextScore,
          'at': Timestamp.now(),
        });
        if (oldLog.length > 25) oldLog.removeAt(0);
        final nextTurn = members.length > 1 ? (turn + 1) % members.length : 0;
        tx.update(_room, {
          'state': {
            ...state,
            'turnIndex': nextTurn,
            'scores': scores,
            'moveNo': ((state['moveNo'] as num?)?.toInt() ?? 0) + 1,
            'lastAction': label,
            'lastPlayer': _uid,
            'log': oldLog,
          },
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });
    } catch (e) {
      if (mounted) setState(() => _notice = e.toString().replaceFirst('Bad state: ', ''));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _reset() async {
    try {
      await _db.runTransaction((tx) async {
        final snap = await tx.get(_room);
        final data = snap.data() ?? {};
        if (data['hostId'] != _uid) throw StateError('إعادة الجولة للمضيف فقط.');
        tx.update(_room, {
          'state': {'turnIndex': 0, 'scores': <String, int>{}, 'moveNo': 0, 'log': <Map<String, dynamic>>[], 'lastAction': 'بدأت جولة جديدة'},
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.rtl,
    child: Scaffold(
      appBar: AppBar(title: Text(widget.title), actions: [
        IconButton(tooltip: 'إعادة الجولة', onPressed: _reset, icon: const Icon(Icons.restart_alt_rounded)),
      ]),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: _room.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return const Center(child: Text('تعذر الاتصال بالغرفة.'));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final room = snapshot.data!.data();
          if (room == null) return const Center(child: Text('الغرفة غير موجودة.'));
          final members = List<String>.from(room['members'] ?? const []);
          final state = Map<String, dynamic>.from(room['state'] ?? const {});
          final scores = Map<String, dynamic>.from(state['scores'] ?? const {});
          final turn = (state['turnIndex'] as num?)?.toInt() ?? 0;
          final current = members.isEmpty ? '' : members[turn % members.length];
          final myTurn = members.length <= 1 || current == _uid;
          final log = List<Map<String, dynamic>>.from(
            (state['log'] as List? ?? const []).map((e) => Map<String, dynamic>.from(e as Map)),
          ).reversed.toList();
          return ListView(padding: const EdgeInsets.all(16), children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                gradient: const LinearGradient(colors: [Color(0xFF171936), Color(0xFF6554D9), Color(0xFF13A89E)]),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('مباراة مباشرة • LIVE', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                Text(myTurn ? 'دورك الآن 🎯' : 'دور اللاعب الآخر', style: const TextStyle(color: Colors.white, fontSize: 23, fontWeight: FontWeight.w900)),
                const SizedBox(height: 6),
                Text('الحركة رقم ${state['moveNo'] ?? 0} • ${members.length} لاعبين', style: const TextStyle(color: Colors.white70)),
                if ((state['lastAction'] ?? '').toString().isNotEmpty)
                  Text('آخر حركة: ${state['lastAction']}', style: const TextStyle(color: Colors.white, height: 1.7)),
              ]),
            ),
            const SizedBox(height: 14),
            const Text('النتائج المباشرة', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
            ...members.asMap().entries.map((entry) {
              final uid = entry.value;
              final active = uid == current && members.length > 1;
              return Card(child: ListTile(
                leading: CircleAvatar(child: Text('${entry.key + 1}')),
                title: Text(uid == _uid ? 'أنت' : 'لاعب ${entry.key + 1}'),
                subtitle: Text(active ? 'دوره الآن' : 'بانتظار الدور'),
                trailing: Text('${scores[uid] ?? 0} نقطة', style: const TextStyle(fontWeight: FontWeight.w900)),
              ));
            }),
            const SizedBox(height: 12),
            const Text('اختَر حركتك', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
            const Text('كل حركة تُحفظ في Firestore وتظهر فوراً عند بقية اللاعبين.'),
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 8, children: [
              _action('🎲 رمية حظ', () => _act('رمية حظ', _random.nextInt(6) + 1), myTurn),
              _action('⭐ حركة ذكية', () => _act('حركة ذكية', 3), myTurn),
              _action('⚡ تحدي سريع', () => _act('تحدي سريع', 2), myTurn),
              _action('🏆 إنجاز الجولة', () => _act('إنجاز الجولة', 5), myTurn),
            ]),
            if (_busy) const Padding(padding: EdgeInsets.all(12), child: Center(child: CircularProgressIndicator())),
            if (_notice != null) Padding(padding: const EdgeInsets.all(8), child: Text(_notice!, style: TextStyle(color: Theme.of(context).colorScheme.error))),
            const SizedBox(height: 18),
            const Text('سجل الحركات', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
            if (log.isEmpty) const Padding(padding: EdgeInsets.all(12), child: Text('ابدأ أول حركة حتى تظهر هنا.')),
            ...log.map((move) => ListTile(
              dense: true,
              leading: const Icon(Icons.bolt_rounded),
              title: Text('${move['uid'] == _uid ? 'أنت' : 'لاعب'}: ${move['action'] ?? 'حركة'}'),
              trailing: Text('+ ${move['points'] ?? 0}'),
            )),
          ]);
        },
      ),
    ),
  );

  Widget _action(String label, VoidCallback onPressed, bool myTurn) =>
      FilledButton.tonal(onPressed: _busy || !myTurn ? null : onPressed, child: Text(label));
}
