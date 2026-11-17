import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'game_room_social.dart';

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
  _FriendsQuestion('من فاز بأول نسخة من كأس العالم عام 1930؟', ['البرازيل','الأرجنتين','الأوروغواي','إيطاليا'], 2),
  _FriendsQuestion('ما المنتخب الأكثر تتويجاً بكأس أمم أفريقيا؟', ['مصر','الكاميرون','نيجيريا','غانا'], 0),
  _FriendsQuestion('أي نادٍ حقق الثلاثية الأوروبية التاريخية عام 1999؟', ['ريال مدريد','مانشستر يونايتد','بايرن ميونخ','يوفنتوس'], 1),
  _FriendsQuestion('من سجل هدف إسبانيا في نهائي كأس العالم 2010؟', ['دافيد فيا','تشافي','أندريس إنييستا','فرناندو توريس'], 2),
  _FriendsQuestion('ما اسم البطولة الأوروبية الثانية للأندية من حيث المستوى؟', ['دوري المؤتمر','الدوري الأوروبي','السوبر الأوروبي','كأس العالم للأندية'], 1),
  _FriendsQuestion('أي حارس فاز بالكرة الذهبية عام 1963؟', ['إيكر كاسياس','ليف ياشين','بوفون','مانويل نوير'], 1),
  _FriendsQuestion('أي منتخب وصل نهائي كأس العالم 2014؟', ['هولندا','الأرجنتين','البرازيل','فرنسا'], 1),
  _FriendsQuestion('من هو الهداف التاريخي لدوري أبطال أوروبا حتى موسم 2024-25؟', ['ليونيل ميسي','كريستيانو رونالدو','روبرت ليفاندوفسكي','كريم بنزيما'], 1),
  _FriendsQuestion('أي نادٍ إيطالي يُلقب بالروسونيري؟', ['إنتر','لاتسيو','ميلان','روما'], 2),
  _FriendsQuestion('كم مرة فازت ألمانيا بكأس العالم للرجال حتى 2022؟', ['3','4','5','6'], 1),
  _FriendsQuestion('من فاز بجائزة أفضل لاعب في كأس العالم 2018؟', ['لوكا مودريتش','كيليان مبابي','أنطوان غريزمان','إيدين هازارد'], 0),
  _FriendsQuestion('أي نادٍ فاز بدوري أبطال أوروبا 2004؟', ['موناكو','بورتو','ديبورتيفو','ميلان'], 1),
  _FriendsQuestion('كم عدد كواكب المجموعة الشمسية؟', ['7','8','9','10'], 1),
  _FriendsQuestion('ما الرمز الكيميائي للماء؟', ['CO2','O2','H2O','NaCl'], 2),
  _FriendsQuestion('ما القارة الأكبر مساحة؟', ['أفريقيا','آسيا','أوروبا','أستراليا'], 1),
  _FriendsQuestion('ما عاصمة اليابان؟', ['بكين','سيول','طوكيو','بانكوك'], 2),
  _FriendsQuestion('أي كوكب يُعرف بالكوكب الأحمر؟', ['الزهرة','المريخ','زحل','عطارد'], 1),
  _FriendsQuestion('كم دقيقة في ساعتين؟', ['60','90','120','180'], 2),
  _FriendsQuestion('ما العضو الذي يضخ الدم في الجسم؟', ['الرئة','القلب','الكبد','المعدة'], 1),
  _FriendsQuestion('ما ناتج 12 × 8؟', ['86','92','96','108'], 2),
  _FriendsQuestion('ما عاصمة كندا؟', ['تورونتو','فانكوفر','أوتاوا','مونتريال'], 2),
  _FriendsQuestion('أي غاز تحتاجه النباتات في البناء الضوئي؟', ['الأوكسجين','ثاني أوكسيد الكربون','الهيليوم','الهيدروجين'], 1),
  _FriendsQuestion('كم ضلعاً للمسدس؟', ['5','6','7','8'], 1),
  _FriendsQuestion('ما أقرب نجم إلى الأرض؟', ['الشمس','الشعرى','النجم القطبي','سيريوس'], 0),
  _FriendsQuestion('ما اللغة الرسمية في البرازيل؟', ['الإسبانية','البرتغالية','الفرنسية','الإنجليزية'], 1),
  _FriendsQuestion('أي جهاز يُستخدم لقياس درجة الحرارة؟', ['البوصلة','مقياس الحرارة','المسطرة','الساعة'], 1),
  _FriendsQuestion('ما أكبر حيوان يعيش حالياً؟', ['الفيل الأفريقي','الحوت الأزرق','الزرافة','الدب القطبي'], 1),
  _FriendsQuestion('كم يوماً في السنة الكبيسة؟', ['364','365','366','367'], 2),
  _FriendsQuestion('ما عاصمة أستراليا؟', ['سيدني','ملبورن','كانبيرا','بيرث'], 2),
  _FriendsQuestion('أي لون ينتج من مزج الأزرق والأصفر؟', ['برتقالي','أخضر','بنفسجي','أحمر'], 1),
  _FriendsQuestion('ما وحدة قياس شدة التيار الكهربائي؟', ['الفولت','الأوم','الأمبير','الواط'], 2),
  _FriendsQuestion('أي محيط يقع بين أفريقيا وأستراليا؟', ['الأطلسي','الهندي','الهادئ','المتجمد الشمالي'], 1),
  _FriendsQuestion('من كتب رواية البؤساء؟', ['فيكتور هوغو','تشارلز ديكنز','تولستوي','دوستويفسكي'], 0),
  _FriendsQuestion('ما عاصمة المغرب؟', ['الدار البيضاء','مراكش','الرباط','فاس'], 2),
  _FriendsQuestion('ما الكوكب الأكبر في المجموعة الشمسية؟', ['الأرض','المشتري','زحل','نبتون'], 1),
  _FriendsQuestion('كم يساوي الجذر التربيعي لـ 144؟', ['10','11','12','14'], 2),
  _FriendsQuestion('في أي دولة تقع أهرامات الجيزة؟', ['العراق','مصر','الأردن','السودان'], 1),
  _FriendsQuestion('ما العنصر الكيميائي الذي رمزه Fe؟', ['الفضة','الحديد','الفلور','الذهب'], 1),
  _FriendsQuestion('ما عاصمة تركيا؟', ['إسطنبول','أنقرة','إزمير','بورصة'], 1),
  _FriendsQuestion('كم عدد أضلاع الشكل الخماسي؟', ['4','5','6','7'], 1),
  _FriendsQuestion('من رسم لوحة الموناليزا؟', ['فان غوخ','بيكاسو','ليوناردو دافنشي','مونيه'], 2),
  _FriendsQuestion('ما أكبر عضو في جسم الإنسان؟', ['القلب','الجلد','الكبد','الرئة'], 1),
  _FriendsQuestion('أي لغة تُستخدم أساساً لتطوير تطبيقات Flutter؟', ['Java','Dart','Swift','Ruby'], 1),
  _FriendsQuestion('ما اسم المجرة التي تضم المجموعة الشمسية؟', ['المرأة المسلسلة','درب التبانة','السومبريرو','العيون السوداء'], 1),
  _FriendsQuestion('كم ثانية في خمس دقائق؟', ['120','240','300','360'], 2),
  _FriendsQuestion('أي حيوان يُعد من الثدييات ويطير؟', ['النسر','الخفاش','البطريق','الدجاجة'], 1),
  _FriendsQuestion('ما عاصمة إيطاليا؟', ['ميلانو','روما','نابولي','تورينو'], 1),
  _FriendsQuestion('ما اسم العملية التي تصنع بها النباتات غذاءها؟', ['التبخر','البناء الضوئي','التكاثف','التنفس فقط'], 1),
  _FriendsQuestion('كم لاعباً في فريق كرة السلة داخل الملعب؟', ['4','5','6','7'], 1),
  _FriendsQuestion('ما البحر الذي يفصل بين شبه الجزيرة العربية وأفريقيا؟', ['بحر العرب','البحر الأحمر','بحر قزوين','البحر الأسود'], 1),
  _FriendsQuestion('ما أصغر عدد أولي؟', ['0','1','2','3'], 2),
  _FriendsQuestion('أي آلة موسيقية تحتوي عادة على 88 مفتاحاً؟', ['الكمان','البيانو','العود','الناي'], 1),
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
  String _mode = '1v1';
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
      // Create directly. A pre-read of a missing room can be rejected by
      // Firestore read rules before the create operation is evaluated.
      await ref.set({
        'game': 'football_quiz', 'hostId': _uid, 'roomCode': code,
        'members': [_uid], 'memberNames': {_uid: _name},
        'status': 'waiting', 'round': 0, 'answers': {}, 'scores': {_uid: 0}, 'mode': _mode,
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
        if (data['game'] != 'football_quiz' || data['status'] != 'waiting' || members.length >= ((data['mode'] == '2v2') ? 4 : 2)) {
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
            Text('اختر 1 ضد 1 أو فرق 2 ضد 2 • أسئلة بمستوى متقدم • نقاط وترتيب لحظي', style: TextStyle(color: Colors.white70)),
          ]),
        ),
        const SizedBox(height: 14),
        DropdownButtonFormField<String>(
          value: _mode,
          decoration: const InputDecoration(labelText: 'نمط اللعب', border: OutlineInputBorder()),
          items: const [
            DropdownMenuItem(value: '1v1', child: Text('فردي 1 ضد 1')),
            DropdownMenuItem(value: '2v2', child: Text('فرق 2 ضد 2')),
          ],
          onChanged: _busy ? null : (value) => setState(() => _mode = value ?? '1v1'),
        ),
        const SizedBox(height: 10),
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
        final requiredPlayers = data['mode'] == '2v2' ? 4 : 2;
        if (members.length < requiredPlayers) {
          throw Exception(data['mode'] == '2v2' ? 'تحتاج المسابقة إلى 4 لاعبين لبدء تحدي 2 ضد 2' : 'بانتظار لاعب آخر');
        }
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
          final requiredPlayers = data['mode'] == '2v2' ? 4 : 2;
          final waiting = members.length < requiredPlayers;
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
            if (data['mode'] == '2v2' && members.length == 4) ...[
              Card(child: Padding(padding: const EdgeInsets.all(12), child: Column(children: [
                const Text('نتيجة الفرق', style: TextStyle(fontWeight: FontWeight.bold)),
                Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                  Text('الفريق A: ${members.take(2).fold<int>(0, (sum, id) => sum + ((scores[id] as num?)?.toInt() ?? 0))}'),
                  Text('الفريق B: ${members.skip(2).fold<int>(0, (sum, id) => sum + ((scores[id] as num?)?.toInt() ?? 0))}'),
                ]),
              ]))),
            ],
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
            const SizedBox(height: 12),
            GameRoomSocialPanel(roomId: widget.roomId),
          ]);
        },
      ),
    ),
  );
}
