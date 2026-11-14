import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const _arenaPurple = Color(0xFF6554D9);
const _arenaInk = Color(0xFF171936);

class _ArenaQuestion {
  final String q, why;
  final List<String> a;
  final int correct;
  const _ArenaQuestion(this.q, this.a, this.correct, this.why);
}

const _arenaSets = <String, List<_ArenaQuestion>>{
  'معلومات عامة': [
    _ArenaQuestion('ما أكبر قارة من حيث المساحة؟',['أفريقيا','آسيا','أوروبا','أستراليا'],1,'آسيا هي الأكبر مساحة.'),
    _ArenaQuestion('ما عاصمة كندا؟',['تورونتو','فانكوفر','أوتاوا','مونتريال'],2,'أوتاوا هي العاصمة.'),
    _ArenaQuestion('كم عدد أضلاع الشكل السداسي؟',['5','6','7','8'],1,'للسداسي ستة أضلاع.'),
    _ArenaQuestion('ما الحيوان الذي يُعرف بملك الغابة؟',['النمر','الأسد','الفهد','الذئب'],1,'الأسد يُلقب بملك الغابة.'),
    _ArenaQuestion('ما أكبر كوكب في المجموعة الشمسية؟',['الأرض','زحل','المشتري','نبتون'],2,'المشتري هو الأكبر.'),
  ],
  'علوم وطبيعة': [
    _ArenaQuestion('ما الرمز الكيميائي للماء؟',['CO2','H2O','O2','NaCl'],1,'الماء يتكون من الهيدروجين والأوكسجين.'),
    _ArenaQuestion('أي عضو يضخ الدم؟',['الرئة','الكبد','القلب','الكلى'],2,'القلب يضخ الدم إلى الجسم.'),
    _ArenaQuestion('ما أقرب نجم إلى الأرض؟',['الشعرى','الشمس','النجم القطبي','سيريوس'],1,'الشمس أقرب نجم إلينا.'),
    _ArenaQuestion('أي غاز تحتاجه النار غالباً للاحتراق؟',['الأوكسجين','الهيليوم','النيتروجين','الأرغون'],0,'الأوكسجين يدعم الاحتراق.'),
    _ArenaQuestion('كم عدد أرجل العنكبوت؟',['6','8','10','12'],1,'للعنكبوت ثماني أرجل.'),
  ],
  'جغرافيا وأعلام': [
    _ArenaQuestion('🇮🇶 علم أي دولة؟',['العراق','الأردن','سوريا','الكويت'],0,'هذا علم العراق.'),
    _ArenaQuestion('ما أطول نهر في أفريقيا؟',['الكونغو','النيل','النيجر','الزمبيزي'],1,'النيل أطول أنهار أفريقيا.'),
    _ArenaQuestion('في أي قارة تقع الأرجنتين؟',['أوروبا','آسيا','أمريكا الجنوبية','أفريقيا'],2,'تقع في أمريكا الجنوبية.'),
    _ArenaQuestion('ما عاصمة تركيا؟',['إسطنبول','أنقرة','إزمير','بورصة'],1,'أنقرة هي العاصمة.'),
    _ArenaQuestion('🇯🇵 أي دولة علمها أبيض وفي وسطه دائرة حمراء؟',['الصين','اليابان','كوريا','فيتنام'],1,'هذا علم اليابان.'),
  ],
  'تاريخ وحضارات': [
    _ArenaQuestion('في أي بلد تقع أهرامات الجيزة؟',['العراق','مصر','السودان','المغرب'],1,'تقع في مصر.'),
    _ArenaQuestion('ما الحضارة التي اشتهرت بالكتابة المسمارية؟',['السومرية','الرومانية','الإغريقية','الفينيقية'],0,'السومريون من أوائل مستخدمي المسمارية.'),
    _ArenaQuestion('أين تقع مدينة بابل الأثرية؟',['مصر','العراق','اليمن','تركيا'],1,'تقع في العراق.'),
    _ArenaQuestion('من بنى تاج محل؟',['شاه جهان','نابليون','صلاح الدين','قورش'],0,'أمر شاه جهان ببنائه.'),
    _ArenaQuestion('ما اسم الطريق التجاري القديم بين الشرق والغرب؟',['طريق الحرير','طريق الذهب','طريق القوافل','طريق البحر'],0,'اشتهر باسم طريق الحرير.'),
  ],
  'كرة القدم': [
    _ArenaQuestion('كم لاعباً يبدأ به كل فريق؟',['9','10','11','12'],2,'أحد عشر لاعباً.'),
    _ArenaQuestion('كم نقطة للفوز في الدوري غالباً؟',['1','2','3','4'],2,'الفوز بثلاث نقاط.'),
    _ArenaQuestion('ما لون بطاقة الطرد؟',['الصفراء','الحمراء','الزرقاء','الخضراء'],1,'البطاقة الحمراء للطرد.'),
    _ArenaQuestion('ما لقب منتخب البرازيل؟',['التانغو','السامبا','الطواحين','الديوك'],1,'البرازيل منتخب السامبا.'),
    _ArenaQuestion('كم دقيقة مدة المباراة الأصلية؟',['60','80','90','100'],2,'تسعون دقيقة.'),
  ],
  'الأنمي': [
    _ArenaQuestion('من بطل أنمي Naruto؟',['ساسكي','ناروتو','كاكاشي','غارا'],1,'ناروتو أوزوماكي هو البطل.'),
    _ArenaQuestion('من طاقم قبعة القش؟',['زورو','ليفاي','غوجو','إيتاتشي'],0,'زورو سياف طاقم لوفي.'),
    _ArenaQuestion('ما اسم بطل Demon Slayer؟',['تانجيرو','زينيتسو','إينوسكي','غيو'],0,'تانجيرو كامادو.'),
    _ArenaQuestion('ما اسم تحول غوكو الذهبي؟',['Bankai','Gear 5','سوبر سايان','نينجا مود'],2,'سوبر سايان.'),
    _ArenaQuestion('من هو بطل Death Note؟',['لايت ياغامي','إدوارد','لوفي','إيرين'],0,'لايت ياغامي هو الشخصية المحورية.'),
  ],
  'تقنية وأمان': [
    _ArenaQuestion('ماذا تعني CPU؟',['وحدة المعالجة المركزية','ذاكرة التخزين','كرت الشاشة','نظام التشغيل'],0,'هي وحدة المعالجة المركزية.'),
    _ArenaQuestion('ما فائدة المصادقة الثنائية؟',['تسريع النت','طبقة حماية إضافية','زيادة الذاكرة','ضغط الصور'],1,'تضيف خطوة تحقق ثانية.'),
    _ArenaQuestion('أي كلمة مرور أقوى؟',['12345678','password','اسمك وتاريخك','عبارة طويلة وفريدة'],3,'العبارة الطويلة الفريدة أقوى.'),
    _ArenaQuestion('ما وظيفة نظام GPS؟',['تحديد الموقع','تنظيف الشاشة','تشغيل الصوت','ضغط الملفات'],0,'يساعد على تحديد الموقع.'),
    _ArenaQuestion('ما الامتداد الشائع لملفات الصور؟',['.mp3','.jpg','.apk','.exe'],1,'.jpg امتداد صور شائع.'),
  ],
  'رياضيات وذكاء': [
    _ArenaQuestion('ما ناتج 15 × 4؟',['45','50','60','65'],2,'15 في 4 تساوي 60.'),
    _ArenaQuestion('ما العدد الأولي؟',['9','15','17','21'],2,'17 لا يقبل القسمة إلا على 1 ونفسه.'),
    _ArenaQuestion('إذا كان اليوم الثلاثاء، فما اليوم بعد 10 أيام؟',['الخميس','الجمعة','السبت','الأحد'],1,'بعد أسبوع الثلاثاء ثم ثلاثة أيام: الجمعة.'),
    _ArenaQuestion('ما نصف ثلاثة أرباع 100؟',['25','37.5','50','75'],1,'ثلاثة أرباع 100 هي 75 ونصفها 37.5.'),
    _ArenaQuestion('كم زاوية قائمة في المربع؟',['2','3','4','5'],2,'للمربع أربع زوايا قائمة.'),
  ],
  'لغة وأدب': [
    _ArenaQuestion('ما جمع كلمة كتاب؟',['كتابات','كتب','كاتبون','مكتبات'],1,'جمع كتاب: كتب.'),
    _ArenaQuestion('ما ضد كلمة شجاع؟',['كريم','جبان','صبور','قوي'],1,'ضد شجاع: جبان.'),
    _ArenaQuestion('ما المقصود بالسجع؟',['تكرار المعنى','توافق أواخر الجمل','وزن الشعر','تشبيه'],1,'توافق أواخر الجمل في النثر.'),
    _ArenaQuestion('كم حرفاً في الأبجدية العربية؟',['26','27','28','29'],2,'عدد الحروف 28.'),
    _ArenaQuestion('من صاحب معلقة قفا نبك؟',['عنترة','امرؤ القيس','زهير','طرفة'],1,'مطلع معلقة امرئ القيس.'),
  ],
  'أفلام وشخصيات': [
    _ArenaQuestion('ما اسم الشخصية الرئيسية في سلسلة Toy Story؟',['باز','وودي','ريكس','آندي'],1,'وودي من أبرز أبطال السلسلة.'),
    _ArenaQuestion('أي بطل يرتدي درعاً أحمر وذهبياً؟',['باتمان','آيرون مان','سبايدرمان','ثور'],1,'آيرون مان يرتدي الدرع الأحمر والذهبي.'),
    _ArenaQuestion('ما اسم مدرسة هاري بوتر؟',['هوجورتس','نارنيا','متروبوليس','كاميلوت'],0,'مدرسة هوجورتس للسحر.'),
    _ArenaQuestion('من هو صديق شريك في أفلامه؟',['حمار','قط','تنين','حصان'],0,'الحمار صديق شريك.'),
    _ArenaQuestion('أي شخصية خيالية تعيش في قاع البحر؟',['سبونج بوب','توم','ميكي','سيمبا'],0,'سبونج بوب يعيش في قاع الهامور.'),
  ],
  'ألغاز وأحاجي': [
    _ArenaQuestion('شيء كلما أخذت منه كبر؟',['البئر','الحفرة','العمر','الظل'],1,'الحفرة تكبر كلما أخذت منها.'),
    _ArenaQuestion('له أسنان ولا يعض؟',['المشط','المفتاح','المنشار','الكتاب'],0,'المشط له أسنان.'),
    _ArenaQuestion('يكتب ولا يقرأ؟',['الكتاب','القلم','الهاتف','الدفتر'],1,'القلم يكتب.'),
    _ArenaQuestion('بيت بلا أبواب ولا نوافذ؟',['الخيمة','البيضة','القصر','الصندوق'],1,'البيضة.'),
    _ArenaQuestion('يمشي بلا قدمين؟',['الوقت','الكرسي','الحجر','الباب'],0,'الوقت يمضي.'),
  ],
  'ثقافة وفنون': [
    _ArenaQuestion('كم مفتاحاً أبيض وأسود تقريباً في البيانو القياسي؟',['66','76','88','100'],2,'البيانو القياسي 88 مفتاحاً.'),
    _ArenaQuestion('ما الفن الذي يعتمد على تشكيل الطين؟',['النحت الخزفي','التصوير','الخط','المسرح'],0,'الخزف يشكل الطين ويحرقه.'),
    _ArenaQuestion('أي آلة وترية عراقية مشهورة؟',['العود','الساكسفون','الترومبيت','الفلوت'],0,'العود آلة وترية شهيرة في الموسيقى العربية.'),
    _ArenaQuestion('ما الألوان الأساسية في الرسم التقليدي؟',['أحمر وأصفر وأزرق','أخضر وأسود وأبيض','بنفسجي وبرتقالي','وردي وبني'],0,'الأحمر والأصفر والأزرق هي الأساسية تقليدياً.'),
    _ArenaQuestion('ما اسم فن الكتابة الجميلة؟',['الخط','النحت','الرقص','التصميم الصوتي'],0,'فن الخط يهتم بجمال الكتابة.'),
  ],
};

class FriendsBattleArenaPage extends StatelessWidget {
  const FriendsBattleArenaPage({super.key});
  @override Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.rtl,
    child: Scaffold(
      appBar: AppBar(title: const Text('ساحة منافسات الأصدقاء')),
      body: ListView(padding: const EdgeInsets.all(14), children: [
        Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: const LinearGradient(colors: [_arenaInk, _arenaPurple, Color(0xFF13A9A0)]),
        ), child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(Icons.emoji_events_rounded, color: Colors.white, size: 38),
          SizedBox(height: 8),
          Text('12 ساحة أسئلة وتحديات', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 22)),
          Text('تحديات متنوعة • نقاط • جولات بين الأصدقاء', style: TextStyle(color: Colors.white70)),
        ])),
        const SizedBox(height: 14),
        const Text('اختر تحدياً وابدأ جولة تنافسية محلية', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
        const SizedBox(height: 8),
        ..._arenaSets.entries.toList().asMap().entries.map((entry) {
          final icons = [Icons.public,Icons.science,Icons.flag,Icons.account_balance,Icons.sports_soccer,Icons.animation,Icons.security,Icons.calculate,Icons.menu_book,Icons.movie,Icons.extension,Icons.palette];
          return Card(child: ListTile(
            leading: CircleAvatar(backgroundColor: _arenaPurple.withValues(alpha: .12), child: Icon(icons[entry.key], color: _arenaPurple)),
            title: Text(entry.value.key, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('${entry.value.value.length} أسئلة • سجل نقاطك مع الأصدقاء'),
            trailing: const Icon(Icons.chevron_left),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => _PassAndPlayQuizPage(category: entry.value.key, questions: entry.value.value))),
          ));
        }),
        const Divider(height: 28),
        const Text('ألعاب ثنائية الأبعاد أونلاين', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        const Text('غرفة خاصة برمز ودعوة صديق، واللعب يتزامن مباشرة عبر الإنترنت.'),
        const SizedBox(height: 8),
        FilledButton.icon(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TreasureLobbyPage())),
          icon: const Icon(Icons.map_rounded), label: const Text('مغامرة كنز الأصدقاء 2D')),
      ]),
    ),
  );
}

class _PassAndPlayQuizPage extends StatefulWidget {
  final String category;
  final List<_ArenaQuestion> questions;
  const _PassAndPlayQuizPage({required this.category, required this.questions});
  @override State<_PassAndPlayQuizPage> createState() => _PassAndPlayQuizPageState();
}
class _PassAndPlayQuizPageState extends State<_PassAndPlayQuizPage> {
  final _names = [TextEditingController(text: 'اللاعب الأول'), TextEditingController(text: 'اللاعب الثاني')];
  int _players = 2, _turn = 0, _round = 0;
  late List<int> _order;
  late List<int> _scores;
  bool _answered = false;
  int? _selected;
  @override void initState() { super.initState(); _reset(); }
  @override void dispose() { for (final n in _names) { n.dispose(); } super.dispose(); }
  void _reset() {
    _order = List.generate(widget.questions.length, (i) => i)..shuffle(Random());
    _scores = List.filled(_players, 0); _turn = 0; _round = 0; _answered = false; _selected = null;
  }
  @override Widget build(BuildContext context) {
    final q = widget.questions[_order[_round % _order.length]];
    return Directionality(textDirection: TextDirection.rtl, child: Scaffold(
      appBar: AppBar(title: Text('تحدي ${widget.category}')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        if (_round == 0) ...[
          const Text('أسماء المتنافسين', style: TextStyle(fontWeight: FontWeight.bold)),
          Row(children: [
            Expanded(child: TextField(controller: _names[0], decoration: const InputDecoration(labelText: 'اللاعب الأول'))),
            const SizedBox(width: 8),
            Expanded(child: TextField(controller: _names[1], decoration: const InputDecoration(labelText: 'اللاعب الثاني'))),
          ]),
          const SizedBox(height: 10),
        ],
        Card(child: Padding(padding: const EdgeInsets.all(14), child: Column(children: [
          Text('الجولة ${_round + 1} • دور ${_names[_turn].text}', style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Text(q.q, textAlign: TextAlign.center, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          ...List.generate(q.a.length, (i) => Padding(padding: const EdgeInsets.only(bottom: 7), child: SizedBox(width: double.infinity,
            child: OutlinedButton(
              onPressed: _answered ? null : () => setState(() { _selected = i; _answered = true; if (i == q.correct) _scores[_turn]++; }),
              child: Text(q.a[i]),
            ),
          ))),
          if (_answered) ...[
            Text(_selected == q.correct ? 'إجابة صحيحة! +1 ⭐' : 'الإجابة الصحيحة: ${q.a[q.correct]}', style: TextStyle(color: _selected == q.correct ? Colors.green : Colors.deepOrange, fontWeight: FontWeight.bold)),
            Text(q.why),
            FilledButton(onPressed: () => setState(() { _round++; _turn = (_turn + 1) % _players; _answered = false; _selected = null; if (_round >= widget.questions.length * 2) _showResult(); }), child: const Text('مرّر الدور للاعب التالي')),
          ],
        ]))),
        const SizedBox(height: 12),
        const Text('النتائج', style: TextStyle(fontWeight: FontWeight.bold)),
        ...List.generate(_players, (i) => ListTile(leading: const Icon(Icons.person), title: Text(_names[i].text), trailing: Text('${_scores[i]} نقطة', style: const TextStyle(fontWeight: FontWeight.bold)))),
      ]),
    ));
  }
  void _showResult() {
    final max = _scores.reduce((a,b) => a > b ? a : b);
    final winners = List.generate(_players, (i) => i).where((i) => _scores[i] == max).map((i) => _names[i].text).join(' و ');
    showDialog<void>(context: context, builder: (c) => AlertDialog(
      title: const Text('انتهت المنافسة 🏆'),
      content: Text('الفائز: $winners\nالنتيجة: ${_scores.join(' - ')}'),
      actions: [TextButton(onPressed: () { Navigator.pop(c); setState(_reset); }, child: const Text('جولة جديدة'))],
    ));
  }
}

class TreasureLobbyPage extends StatefulWidget {
  const TreasureLobbyPage({super.key});
  @override State<TreasureLobbyPage> createState() => _TreasureLobbyPageState();
}
class _TreasureLobbyPageState extends State<TreasureLobbyPage> {
  final _db = FirebaseFirestore.instance;
  final _code = TextEditingController();
  bool _busy = false;
  String get _uid => FirebaseAuth.instance.currentUser!.uid;
  String get _name => FirebaseAuth.instance.currentUser?.displayName ?? 'لاعب';
  @override void dispose() { _code.dispose(); super.dispose(); }

  Future<void> _create() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final code = (100000 + Random.secure().nextInt(900000)).toString();
      final room = _db.collection('gameRooms').doc(code);
      await room.set({
        'game': 'treasure_duel', 'hostId': _uid, 'roomCode': code,
        'members': [_uid], 'memberNames': {_uid: _name},
        'status': 'waiting', 'positions': [0, 48], 'scores': {_uid: 0},
        'turn': _uid, 'winner': '', 'treasures': [8, 12, 16, 24, 32, 40],
        'moves': 0, 'createdAt': FieldValue.serverTimestamp(), 'updatedAt': FieldValue.serverTimestamp(),
      });
      if (!mounted) return;
      Navigator.push(context, MaterialPageRoute(builder: (_) => TreasureRoomPage(roomId: code)));
    } catch (e) { _toast('تعذر إنشاء الغرفة: $e'); }
    finally { if (mounted) setState(() => _busy = false); }
  }

  Future<bool> _join(String? value) async {
    final code = (value ?? _code.text).trim();
    if (!RegExp(r'^\d{6}$').hasMatch(code) || _busy) {
      _toast('اكتب رمزاً من 6 أرقام');
      return false;
    }
    setState(() => _busy = true);
    var joined = false;
    try {
      final room = _db.collection('gameRooms').doc(code);
      await _db.runTransaction((tx) async {
        final snap = await tx.get(room);
        if (!snap.exists) throw Exception('الغرفة غير موجودة');
        final data = snap.data()!;
        final members = List<String>.from(data['members'] ?? []);
        if (members.contains(_uid)) {
          joined = true;
          return;
        }
        if (data['game'] != 'treasure_duel' || data['status'] != 'waiting' || members.length != 1) {
          throw Exception('الغرفة بدأت أو اكتملت');
        }
        final scores = Map<String, dynamic>.from(data['scores'] ?? {});
        scores[_uid] = 0;
        tx.update(room, {
          'members': FieldValue.arrayUnion([_uid]),
          'memberNames.$_uid': _name,
          'scores': scores,
          'status': 'playing',
          'updatedAt': FieldValue.serverTimestamp(),
        });
        joined = true;
      });
      if (!mounted) return joined;
      _code.clear();
      if (joined) {
        Navigator.push(context, MaterialPageRoute(builder: (_) => TreasureRoomPage(roomId: code)));
      }
      return joined;
    } catch (e) {
      _toast(e.toString().replaceFirst('Exception: ', ''));
      return false;
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _invite(String roomId) async {
    try {
      final profiles = await _db.collection('publicProfiles').limit(100).get();
      if (!mounted) return;
      final selected = await showModalBottomSheet<String>(context: context, showDragHandle: true, builder: (c) => Directionality(
        textDirection: TextDirection.rtl, child: SafeArea(child: ListView(shrinkWrap: true, children: [
          const Padding(padding: EdgeInsets.all(16), child: Text('اختَر صديقاً لدعوته', style: TextStyle(fontWeight: FontWeight.bold))),
          ...profiles.docs.where((p) => p.id != _uid).map((p) => ListTile(title: Text(p.data()['name']?.toString() ?? 'عضو'), onTap: () => Navigator.pop(c, p.id))),
        ])),
      ));
      if (selected == null) return;
      final me = await _db.collection('publicProfiles').doc(_uid).get();
      await _db.collection('gameInvites').add({
        'from': _uid, 'to': selected, 'fromName': me.data()?['name'] ?? _name,
        'game': 'treasure', 'roomId': roomId, 'roomCode': roomId,
        'status': 'pending', 'createdAt': FieldValue.serverTimestamp(),
      });
      _toast('تم إرسال الدعوة 🎮');
    } catch (e) { _toast('تعذر إرسال الدعوة: $e'); }
  }

  void _toast(String s) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s))); }

  @override Widget build(BuildContext context) => Directionality(textDirection: TextDirection.rtl, child: Scaffold(
    appBar: AppBar(title: const Text('مغامرة كنز الأصدقاء 2D')),
    body: ListView(padding: const EdgeInsets.all(16), children: [
      Container(padding: const EdgeInsets.all(18), decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), gradient: const LinearGradient(colors: [_arenaInk,_arenaPurple,Color(0xFF159E91)])),
        child: const Text('🗺️ تحرك على الخريطة، اجمع الكنوز، ونافس صديقك خطوة بخطوة!', style: TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.bold))),
      const SizedBox(height: 14),
      FilledButton.icon(onPressed: _busy ? null : _create, icon: const Icon(Icons.add), label: const Text('إنشاء غرفة كنز')),
      const SizedBox(height: 10),
      TextField(controller: _code, keyboardType: TextInputType.number, maxLength: 6, textAlign: TextAlign.center, decoration: const InputDecoration(labelText: 'رمز الغرفة', counterText: '', border: OutlineInputBorder())),
      OutlinedButton.icon(onPressed: _busy ? null : () => _join(null), icon: const Icon(Icons.login), label: const Text('انضم إلى غرفة صديق')),
      const SizedBox(height: 16),
      const Text('دعواتك الواردة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
      StreamBuilder<QuerySnapshot<Map<String,dynamic>>>(
        stream: _db.collection('gameInvites').where('to', isEqualTo: _uid).limit(30).snapshots(),
        builder: (context, snap) {
          if (!snap.hasData) return const Padding(padding: EdgeInsets.all(12), child: LinearProgressIndicator());
          final docs = snap.data!.docs.where((d) => d.data()['game'] == 'treasure' && d.data()['status'] == 'pending').toList();
          if (docs.isEmpty) return const Card(child: Padding(padding: EdgeInsets.all(12), child: Text('ما عندك دعوات جديدة.')));
          return Column(children: docs.map((d) => Card(child: ListTile(
            leading: const Icon(Icons.mail), title: Text('دعوة من ${d.data()['fromName'] ?? 'صديق'}'),
            subtitle: Text('غرفة ${d.data()['roomCode'] ?? d.data()['roomId']}'),
            trailing: FilledButton(onPressed: _busy ? null : () async { final joined = await _join(d.data()['roomId']?.toString()); if (joined && mounted) await d.reference.update({'status':'accepted'}); }, child: const Text('انضم')),
          ))).toList());
        },
      ),
    ]),
  ));
}

class TreasureRoomPage extends StatefulWidget {
  final String roomId;
  const TreasureRoomPage({super.key, required this.roomId});
  @override State<TreasureRoomPage> createState() => _TreasureRoomPageState();
}
class _TreasureRoomPageState extends State<TreasureRoomPage> {
  final _db = FirebaseFirestore.instance;
  bool _busy = false;
  String get _uid => FirebaseAuth.instance.currentUser!.uid;
  DocumentReference<Map<String,dynamic>> get _room => _db.collection('gameRooms').doc(widget.roomId);
  Future<void> _move(int target, Map<String,dynamic> data) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await _db.runTransaction((tx) async {
        final snap = await tx.get(_room);
        if (!snap.exists) throw Exception('الغرفة انتهت');
        final d = snap.data()!;
        final members = List<String>.from(d['members'] ?? []);
        final positions = List<int>.from(d['positions'] ?? [0,48]);
        final treasures = List<int>.from(d['treasures'] ?? []);
        if (d['status'] != 'playing' || !members.contains(_uid) || d['turn'] != _uid) throw Exception('انتظر دورك');
        final index = members.indexOf(_uid);
        final current = positions[index];
        if (target < 0 || target >= 49 || ((target ~/ 7 - current ~/ 7).abs() + (target % 7 - current % 7).abs()) != 1) throw Exception('تقدر تتحرك خانة واحدة فقط');
        if (positions.contains(target)) throw Exception('صديقك واقف بهذا المكان');
        positions[index] = target;
        final scores = Map<String,dynamic>.from(d['scores'] ?? {});
        if (treasures.contains(target)) { scores[_uid] = (scores[_uid] as num? ?? 0).toInt() + 1; treasures.remove(target); }
        final moves = (d['moves'] as num? ?? 0).toInt() + 1;
        final ended = treasures.isEmpty || moves >= 36;
        final winner = ended ? (members.firstWhere((m) => (scores[m] as num? ?? 0) == members.map((id) => (scores[id] as num? ?? 0)).reduce(max))) : '';
        final next = members.firstWhere((m) => m != _uid);
        tx.update(_room, {'positions': positions, 'treasures': treasures, 'scores': scores, 'moves': moves, 'turn': ended ? '' : next, 'winner': winner, 'status': ended ? 'finished' : 'playing', 'updatedAt': FieldValue.serverTimestamp()});
      });
    } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', '')))); }
    finally { if (mounted) setState(() => _busy = false); }
  }
  @override Widget build(BuildContext context) => Directionality(textDirection: TextDirection.rtl, child: Scaffold(
    appBar: AppBar(title: const Text('كنز الأصدقاء • خريطة 2D')),
    body: StreamBuilder<DocumentSnapshot<Map<String,dynamic>>>(
      stream: _room.snapshots(),
      builder: (context, snap) {
        if (snap.hasError) return const Center(child: Text('تعذر الاتصال. تأكد من نشر قواعد Firestore الجديدة.'));
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        if (!snap.data!.exists) return const Center(child: Text('الغرفة غير موجودة.'));
        final d = snap.data!.data()!;
        final members = List<String>.from(d['members'] ?? []);
        final names = Map<String,dynamic>.from(d['memberNames'] ?? {});
        final positions = List<int>.from(d['positions'] ?? [0,48]);
        final treasures = List<int>.from(d['treasures'] ?? []);
        final scores = Map<String,dynamic>.from(d['scores'] ?? {});
        final playing = d['status'] == 'playing';
        final mine = members.indexOf(_uid);
        final myTurn = playing && d['turn'] == _uid;
        final winner = d['winner']?.toString() ?? '';
        return ListView(padding: const EdgeInsets.all(12), children: [
          Card(child: Padding(padding: const EdgeInsets.all(12), child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: members.map((m) => Column(children: [
            Text(names[m]?.toString() ?? 'لاعب', style: const TextStyle(fontWeight: FontWeight.bold)),
            Text('⭐ ${scores[m] ?? 0}'),
          ])).toList()))),
          Card(child: Padding(padding: const EdgeInsets.all(10), child: Text(
            d['status'] == 'waiting' ? 'أرسل الدعوة أو شارك الرمز ${widget.roomId}' :
            d['status'] == 'finished' ? (winner == _uid ? 'فزت بالمغامرة! 🏆' : winner.isEmpty ? 'تعادل!' : 'فاز صديقك!') :
            myTurn ? 'دورك! اجمع أقرب كنز ✨' : 'دور ${names[d['turn']] ?? 'صديقك'}',
            textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)))),
          if (d['status'] == 'waiting') FilledButton.icon(onPressed: () => _invite(widget.roomId), icon: const Icon(Icons.person_add_alt_1), label: const Text('ادعُ صديقاً')),
          if (playing) ...[
            const Text('حرّك شخصيتك خانة واحدة باتجاه الأعلى أو الأسفل أو اليمين أو اليسار', textAlign: TextAlign.center),
            const SizedBox(height: 10),
            AspectRatio(aspectRatio: 1, child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(), itemCount: 49,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7, crossAxisSpacing: 4, mainAxisSpacing: 4),
              itemBuilder: (context, i) {
                final p = positions.indexOf(i);
                final treasure = treasures.contains(i);
                final me = p == mine;
                final other = p >= 0 && !me;
                final row = i ~/ 7, col = i % 7;
                final current = mine >= 0 ? positions[mine] : -1;
                final canMove = myTurn && ((row-current~/7).abs() + (col-current%7).abs() == 1) && !positions.contains(i);
                return InkWell(onTap: canMove && !_busy ? () => _move(i,d) : null, child: AnimatedContainer(duration: const Duration(milliseconds: 180),
                  decoration: BoxDecoration(color: me ? _arenaPurple : other ? Colors.teal : treasure ? Colors.amber.withValues(alpha:.25) : Theme.of(context).colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(9), border: Border.all(color: canMove ? Colors.green : Colors.transparent, width: 2)),
                  child: Center(child: Text(me ? '🧙' : other ? '🛡️' : treasure ? '💎' : '', style: const TextStyle(fontSize: 21))),
                ));
              },
            )),
          ],
          if (d['status'] == 'finished') FilledButton.icon(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.home), label: const Text('العودة للألعاب')),
          const SizedBox(height: 8),
          SelectableText('رمز الغرفة: ${widget.roomId}', textAlign: TextAlign.center),
          TextButton.icon(onPressed: () => Clipboard.setData(ClipboardData(text: widget.roomId)), icon: const Icon(Icons.copy), label: const Text('نسخ الرمز')),
        ]);
      },
    ),
  ));
  Future<void> _invite(String roomId) async {
    try {
      final profiles = await _db.collection('publicProfiles').limit(100).get();
      if (!mounted) return;
      final selected = await showModalBottomSheet<String>(context: context, showDragHandle: true, builder: (c) => Directionality(
        textDirection: TextDirection.rtl, child: SafeArea(child: ListView(shrinkWrap: true, children: [
          const Padding(padding: EdgeInsets.all(16), child: Text('اختَر صديقاً لدعوته')),
          ...profiles.docs.where((p) => p.id != _uid).map((p) => ListTile(title: Text(p.data()['name']?.toString() ?? 'عضو'), onTap: () => Navigator.pop(c, p.id))),
        ])),
      ));
      if (selected == null) return;
      final me = await _db.collection('publicProfiles').doc(_uid).get();
      await _db.collection('gameInvites').add({'from':_uid,'to':selected,'fromName':me.data()?['name'] ?? 'صديق','game':'treasure','roomId':roomId,'roomCode':roomId,'status':'pending','createdAt':FieldValue.serverTimestamp()});
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('وصلت الدعوة لصديقك 🎮')));
    } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تعذر إرسال الدعوة: $e'))); }
  }
}
