import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const _friendsQuizQuestions = <_FriendsQuestion>[
  _FriendsQuestion('كم لاعباً يبدأ به كل فريق مباراة كرة القدم؟', ['9','10','11','12'], 2),
  _FriendsQuestion('كم نقطة يحصل عليها الفريق عند الفوز بالدوري؟', ['1','2','3','4'], 2),
  _FriendsQuestion('أي منتخب فاز بكأس العالم 2022؟', ['فرنسا','الأرجنتين','البرازيل','كرواتيا'], 1),
  _FriendsQuestion('ما اسم ملعب ليفربول؟', ['ويمبلي','أنفيلد','أولد ترافورد','سان سيرو'], 1),
  _FriendsQuestion('من اللاعب الملقب بالملك المصري؟', ['محمد صلاح','رياض محرز','عمر مرموش','محمد النني'], 0),
  _FriendsQuestion('أي منتخب يلقب بمنتخب السامبا؟', ['الأرجنتين','البرازيل','إيطاليا','ألمانيا'], 1),
  _FriendsQuestion('ما لون البطاقة التي تعني الطرد؟', ['الصفراء','الحمراء','الزرقاء','الخضراء'], 1),
  _FriendsQuestion('كم دقيقة مدة المباراة الأصلية؟', ['60','80','90','100'], 2),
  _FriendsQuestion('أي نادٍ يلقب بالسيدة العجوز؟', ['ميلان','إنتر','يوفنتوس','روما'], 2),
  _FriendsQuestion('من فاز بكأس العالم 2018؟', ['فرنسا','ألمانيا','كرواتيا','إسبانيا'], 0),
  _FriendsQuestion('من اللاعب البرتغالي الشهير بالرقم 7؟', ['برونو','كريستيانو رونالدو','ناني','برناردو'], 1),
  _FriendsQuestion('أي نادٍ ملعبه سانتياغو برنابيو؟', ['برشلونة','ريال مدريد','أتلتيكو','إشبيلية'], 1),
];

class _FriendsQuestion {
  final String title;
  final List<String> options;
  final int correct;
  const _FriendsQuestion(this.title, this.options, this.correct);
}

class FriendsQuizPage extends StatefulWidget {
  const FriendsQuizPage({super.key});
  @override
  State<FriendsQuizPage> createState() => _FriendsQuizPageState();
}

class _FriendsQuizPageState extends State<FriendsQuizPage> {
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
      final code = (100000 + Random.secure().nextInt(900000)).toString();
      final ref = _db.collection('gameRooms').doc(code);
      if ((await ref.get()).exists) throw Exception('حاول إنشاء غرفة جديدة');
      await ref.set({
        'game': 'football_quiz', 'hostId': _uid, 'roomCode': code,
        'members': [_uid], 'memberNames': {_uid: _name},
        'status': 'waiting', 'round': 0, 'answers': {}, 'scores': {_uid: 0},
        'createdAt': FieldValue.serverTimestamp(), 'updatedAt': FieldValue.serverTimestamp(),
      });
      if (!mounted) return;
      Navigator.push(context, MaterialPageRoute(builder: (_) => FriendsQuizRoomPage(roomId: code)));
    } catch (e) {
      _toast('تعذر إنشاء الغرفة: $e');
    } finally { if (mounted) setState(() => _busy = false); }
  }

  Future<bool> _join(String? value) async {
    final code = (value ?? _code.text).trim();
    if (!RegExp(r'^\d{6}$').hasMatch(code) || _busy) {
      _toast('اكتب رمزاً صحيحاً من 6 أرقام');
      return false;
    }
    setState(() => _busy = true);
    var joined = false;
    try {
      final ref = _db.collection('gameRooms').doc(code);
      await _db.runTransaction((tx) async {
        final snap = await tx.get(ref);
        if (!snap.exists) throw Exception('الغرفة غير موجودة أو انتهت');
        final data = snap.data()!;
        final members = List<String>.from(data['members'] ?? []);
        if (members.contains(_uid)) { joined = true; return; }
        if (data['game'] != 'football_quiz' || data['status'] != 'waiting' || members.length >= 4) {
          throw Exception('المسابقة بدأت أو اكتمل عدد اللاعبين');
        }
        final scores = Map<String, dynamic>.from(data['scores'] ?? {});
        scores[_uid] = 0;
        tx.update(ref, {
          'members': FieldValue.arrayUnion([_uid]),
          'memberNames.$_uid': _name,
          'scores': scores,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        joined = true;
      });
      if (!mounted) return joined;
      _code.clear();
      if (joined) Navigator.push(context, MaterialPageRoute(builder: (_) => FriendsQuizRoomPage(roomId: code)));
      return joined;
    } catch (e) {
      _toast(e.toString().replaceFirst('Exception: ', ''));
      return false;
    } finally { if (mounted) setState(() => _busy = false); }
  }

  void _toast(String value) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value)));

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.rtl,
    child: Scaffold(
      appBar: AppBar(title: const Text('مسابقة الأسئلة مع الأصدقاء')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: const LinearGradient(colors: [Color(0xFF211A49), Color(0xFF6554D9), Color(0xFF168E9B)]),
          ),
          child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(Icons.quiz_rounded, color: Colors.white, size: 38),
            SizedBox(height: 10),
            Text('من يعرف أكثر؟ 🏆', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
            Text('مسابقة مباشرة من 2 إلى 4 لاعبين • 12 سؤالاً • نقاط وترتيب لحظي', style: TextStyle(color: Colors.white70)),
          ]),
        ),
        const SizedBox(height: 14),
        FilledButton.icon(
          onPressed: _busy ? null : _createRoom,
          icon: const Icon(Icons.add_circle_outline),
          label: const Text('أنشئ مسابقة وادعُ أصدقاءك'),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _code,
          keyboardType: TextInputType.number,
          maxLength: 6,
          textAlign: TextAlign.center,
          decoration: const InputDecoration(labelText: 'أدخل رمز المسابقة', border: OutlineInputBorder(), counterText: ''),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(onPressed: _busy ? null : () => _join(null), icon: const Icon(Icons.login), label: const Text('انضم إلى مسابقة')),
        const SizedBox(height: 18),
        const Text('دعواتك الواردة', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _db.collection('gameInvites').where('to', isEqualTo: _uid).limit(30).snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) return const Text('تعذر تحميل الدعوات.');
            if (!snapshot.hasData) return const LinearProgressIndicator();
            final docs = snapshot.data!.docs.where((d) => d.data()['game'] == 'football' && d.data()['status'] == 'pending').toList();
            if (docs.isEmpty) return const Card(child: Padding(padding: EdgeInsets.all(12), child: Text('لا توجد دعوات مسابقة حالياً.')));
            return Column(children: docs.map((d) => Card(child: ListTile(
              leading: const CircleAvatar(child: Icon(Icons.emoji_events)),
              title: Text('دعوة من ${d.data()['fromName'] ?? 'صديق'}'),
              subtitle: Text('رمز الغرفة: ${d.data()['roomId'] ?? '------'}'),
              trailing: FilledButton(
                onPressed: _busy ? null : () async {
                  final roomId = d.data()['roomId']?.toString() ?? '';
                  final joined = await _join(roomId);
                  if (joined && mounted) await d.reference.update({'status': 'accepted'});
                },
                child: const Text('انضم'),
              ),
            ))).toList());
          },
        ),
      ]),
    ),
  );
}

class FriendsQuizRoomPage extends StatefulWidget {
  const FriendsQuizRoomPage({super.key, required this.roomId});
  final String roomId;
  @override
  State<FriendsQuizRoomPage> createState() => _FriendsQuizRoomPageState();
}

class _FriendsQuizRoomPageState extends State<FriendsQuizRoomPage> {
  final _db = FirebaseFirestore.instance;
  bool _busy = false;
  String get _uid => FirebaseAuth.instance.currentUser!.uid;
  DocumentReference<Map<String, dynamic>> get _room => _db.collection('gameRooms').doc(widget.roomId);

  Future<void> _submit(int choice) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await _db.runTransaction((tx) async {
        final snap = await tx.get(_room);
        if (!snap.exists) throw Exception('الغرفة غير موجودة');
        final data = snap.data()!;
        final members = List<String>.from(data['members'] ?? []);
        final round = (data['round'] as num?)?.toInt() ?? 0;
        final answers = Map<String, dynamic>.from(data['answers'] ?? {});
        if (members.length < 2) throw Exception('بانتظار لاعب آخر');
        if (!members.contains(_uid) || round >= _friendsQuizQuestions.length || answers.containsKey(_uid)) {
          throw Exception('إجابتك مسجلة أو انتهت المسابقة');
        }
        final scores = Map<String, dynamic>.from(data['scores'] ?? {});
        if (choice == _friendsQuizQuestions[round].correct) {
          scores[_uid] = ((scores[_uid] as num?)?.toInt() ?? 0) + 1;
        }
        answers[_uid] = choice;
        final everyoneAnswered = members.every(answers.containsKey);
        final nextRound = everyoneAnswered ? round + 1 : round;
        tx.update(_room, {
          'answers': everyoneAnswered ? <String, dynamic>{} : answers,
          'scores': scores,
          'round': nextRound,
          'status': nextRound >= _friendsQuizQuestions.length ? 'finished' : 'playing',
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))));
    } finally { if (mounted) setState(() => _busy = false); }
  }

  Future<void> _invite(BuildContext context, Map<String, dynamic> data) async {
    try {
      final profiles = await _db.collection('publicProfiles').limit(100).get();
      if (!context.mounted) return;
      final friends = profiles.docs.where((d) => d.id != _uid && !(data['members'] as List).contains(d.id)).toList();
      final chosen = await showModalBottomSheet<String>(
        context: context,
        showDragHandle: true,
        builder: (c) => Directionality(textDirection: TextDirection.rtl, child: ListView(shrinkWrap: true, children: [
          const Padding(padding: EdgeInsets.all(16), child: Text('اختَر صديقاً للمسابقة', style: TextStyle(fontWeight: FontWeight.bold))),
          ...friends.map((d) => ListTile(title: Text(d.data()['name']?.toString() ?? 'عضو'), leading: const CircleAvatar(child: Icon(Icons.person)), onTap: () => Navigator.pop(c, d.id))),
        ])),
      );
      if (chosen == null) return;
      final me = await _db.collection('publicProfiles').doc(_uid).get();
      await _db.collection('gameInvites').add({
        'from': _uid, 'to': chosen, 'fromName': me.data()?['name'] ?? 'صديق',
        'game': 'football', 'roomId': widget.roomId, 'roomCode': widget.roomId,
        'status': 'pending', 'createdAt': FieldValue.serverTimestamp(),
      });
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إرسال الدعوة 🎮')));
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تعذر إرسال الدعوة: $e')));
    }
  }

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.rtl,
    child: Scaffold(
      appBar: AppBar(title: const Text('منافسة الأصدقاء')),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: _room.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return const Center(child: Text('تعذر الاتصال بالغرفة. تأكد من قواعد Firestore.'));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          if (!snapshot.data!.exists) return const Center(child: Text('الغرفة غير موجودة.'));
          final data = snapshot.data!.data()!;
          final members = List<String>.from(data['members'] ?? []);
          final names = Map<String, dynamic>.from(data['memberNames'] ?? {});
          final scores = Map<String, dynamic>.from(data['scores'] ?? {});
          final answers = Map<String, dynamic>.from(data['answers'] ?? {});
          final round = (data['round'] as num?)?.toInt() ?? 0;
          final waiting = members.length < 2;
          final done = data['status'] == 'finished' || round >= _friendsQuizQuestions.length;
          final answered = answers.containsKey(_uid);
          return ListView(padding: const EdgeInsets.all(16), children: [
            Card(child: Padding(padding: const EdgeInsets.all(14), child: Column(children: [
              const Text('رمز الغرفة', style: TextStyle(color: Colors.grey)),
              SelectableText(widget.roomId, style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900, letterSpacing: 5)),
              TextButton.icon(onPressed: () {
                Clipboard.setData(ClipboardData(text: widget.roomId));
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم نسخ الرمز')));
              }, icon: const Icon(Icons.copy), label: const Text('نسخ الرمز')),
              if (data['hostId'] == _uid) TextButton.icon(onPressed: () => _invite(context, data), icon: const Icon(Icons.person_add_alt_1), label: const Text('دعوة صديق')),
            ]))),
            Card(child: Padding(padding: const EdgeInsets.all(12), child: Column(children: [
              const Text('ترتيب اللاعبين', style: TextStyle(fontWeight: FontWeight.bold)),
              ...members.map((id) => ListTile(dense: true, title: Text(names[id]?.toString() ?? 'لاعب'), trailing: Text('${scores[id] ?? 0} نقطة'))),
            ]))),
            if (waiting) const Card(child: Padding(padding: EdgeInsets.all(18), child: Text('بانتظار صديق آخر للانضمام إلى المسابقة.'))),
            if (!waiting && !done && answered) const Card(child: Padding(padding: EdgeInsets.all(18), child: Text('إجابتك وصلت! ننتظر بقية اللاعبين.'))),
            if (!waiting && !done && !answered) ...[
              Text('السؤال ${round + 1} من ${_friendsQuizQuestions.length}', style: const TextStyle(color: Colors.deepPurple, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Text(_friendsQuizQuestions[round].title, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              ...List.generate(_friendsQuizQuestions[round].options.length, (i) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: OutlinedButton(onPressed: _busy ? null : () => _submit(i), child: Align(alignment: Alignment.centerRight, child: Text(_friendsQuizQuestions[round].options[i]))),
              )),
            ],
            if (done) const Card(child: Padding(padding: EdgeInsets.all(18), child: Text('انتهت المسابقة! مبروك للفائز 🏆'))),
          ]);
        },
      ),
    ),
  );
}
