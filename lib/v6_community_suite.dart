import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const Color _v6Brand = Color(0xFF6554D9);
final FirebaseFirestore _v6Db = FirebaseFirestore.instance;
String get _v6Uid => FirebaseAuth.instance.currentUser!.uid;
String get _v6Name => FirebaseAuth.instance.currentUser?.displayName ?? 'عضو';

class V6CommunitySuitePage extends StatelessWidget {
  const V6CommunitySuitePage({super.key});
  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.rtl,
    child: Scaffold(
      appBar: AppBar(title: const Text('المجتمع الشامل V6')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: const LinearGradient(colors: [Color(0xFF171936), _v6Brand, Color(0xFF24AFC5)]),
          ),
          child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('مجتمعك، إنجازك، وأصدقاؤك ✨', style: TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.w900)),
            SizedBox(height: 8),
            Text('مساحات اهتمام مشتركة، تحديات شخصية، وجدار امتنان يجمع أعضاء الملتقى.', style: TextStyle(color: Colors.white70, height: 1.5)),
          ]),
        ),
        const SizedBox(height: 16),
        _SuiteTile(icon: Icons.groups_rounded, title: 'الأندية ومجموعات الاهتمام', subtitle: 'أنشئ نادياً أو انضم إلى مجتمع يشاركك اهتماماتك', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ForumClubsPage()))),
        _SuiteTile(icon: Icons.flag_rounded, title: 'مهامي وتحدياتي اليومية', subtitle: 'مهام شخصية وسجل إنجاز محلي على جهازك', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DailyMissionsPage()))),
        _SuiteTile(icon: Icons.favorite_rounded, title: 'جدار الامتنان', subtitle: 'شارك كلمة شكر أو رسالة إيجابية مع الجميع', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GratitudeWallPage()))),
        _SuiteTile(icon: Icons.timer_rounded, title: 'مساحة التركيز والبومودورو', subtitle: 'جلسات تركيز واستراحات ومتابعة إنجازك', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FocusRoomPage()))),
        _SuiteTile(icon: Icons.auto_graph_rounded, title: 'مساحتي الشخصية', subtitle: 'سجّل مزاجك وأهدافك وعاداتك وملاحظاتك اليومية', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PersonalGrowthPage()))),
        _SuiteTile(icon: Icons.shield_rounded, title: 'مركز السلامة والخصوصية', subtitle: 'إرشادات سريعة لحماية حسابك وتفاعلك', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const V6SafetyPage()))),
      ]),
    ),
  );
}

class _SuiteTile extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final VoidCallback onTap;
  const _SuiteTile({required this.icon, required this.title, required this.subtitle, required this.onTap});
  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 11),
    child: ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: CircleAvatar(backgroundColor: _v6Brand.withValues(alpha: .14), child: Icon(icon, color: _v6Brand)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_left),
      onTap: onTap,
    ),
  );
}

class ForumClubsPage extends StatefulWidget {
  const ForumClubsPage({super.key});
  @override State<ForumClubsPage> createState() => _ForumClubsPageState();
}
class _ForumClubsPageState extends State<ForumClubsPage> {
  bool creating = false;
  Future<void> _createClub() async {
    final name = TextEditingController();
    final about = TextEditingController();
    String category = 'التقنية';
    final ok = await showDialog<bool>(context: context, builder: (dialogContext) =>
      Directionality(textDirection: TextDirection.rtl, child: StatefulBuilder(builder: (context, refresh) =>
        AlertDialog(title: const Text('إنشاء نادٍ جديد'),
          content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: name, maxLength: 40, decoration: const InputDecoration(labelText: 'اسم النادي')),
            TextField(controller: about, maxLength: 180, maxLines: 3, decoration: const InputDecoration(labelText: 'وصف النادي')),
            DropdownButtonFormField<String>(
              value: category,
              decoration: const InputDecoration(labelText: 'التصنيف'),
              items: const ['الأنمي والمانغا','كرة القدم','الشعر والأدب','الألعاب','التقنية','التصوير والفن','القراءة','متنوع'].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
              onChanged: (v) { if (v != null) refresh(() => category = v); },
            ),
          ])),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('إلغاء')),
            FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('إنشاء')),
          ],
        ))));
    if (ok == true && name.text.trim().isNotEmpty) {
      setState(() => creating = true);
      try {
        await _v6Db.collection('forumClubs').add({
          'name': name.text.trim(), 'description': about.text.trim(), 'category': category,
          'ownerId': _v6Uid, 'ownerName': _v6Name, 'members': [_v6Uid],
          'active': true, 'createdAt': FieldValue.serverTimestamp(),
        });
      } catch (_) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تعذر إنشاء النادي. تأكد من نشر قواعد V6.')));
      } finally { if (mounted) setState(() => creating = false); }
    }
    name.dispose(); about.dispose();
  }
  @override
  Widget build(BuildContext context) => Directionality(textDirection: TextDirection.rtl,
    child: Scaffold(
      appBar: AppBar(title: const Text('أندية الملتقى')),
      floatingActionButton: FloatingActionButton.extended(onPressed: creating ? null : _createClub, icon: const Icon(Icons.add), label: Text(creating ? 'جارٍ الإنشاء' : 'إنشاء نادٍ')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _v6Db.collection('forumClubs').orderBy('createdAt', descending: true).limit(60).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return const Center(child: Text('تعذر تحميل الأندية. تحقق من قواعد Firestore.'));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snapshot.data!.docs.where((d) => d.data()['active'] == true).toList();
          if (docs.isEmpty) return const Center(child: Text('ماكو أندية بعد. أنشئ أول نادٍ وابدأ مجتمعك!'));
          return ListView.builder(padding: const EdgeInsets.fromLTRB(12, 12, 12, 88), itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index]; final data = doc.data();
              final members = (data['members'] as List?) ?? [];
              final joined = members.contains(_v6Uid);
              return Card(child: ListTile(
                leading: const CircleAvatar(child: Icon(Icons.groups)),
                title: Text(data['name']?.toString() ?? 'نادي'),
                subtitle: Text((data['category']?.toString() ?? 'متنوع') + ' • ' + members.length.toString() + ' عضو\n' + (data['description']?.toString() ?? '')),
                isThreeLine: true,
                trailing: joined ? const Icon(Icons.check_circle, color: Colors.green) : const Icon(Icons.add_circle_outline),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ForumClubPage(clubId: doc.id))),
              ));
            });
        },
      ),
    ));
}

class ForumClubPage extends StatefulWidget {
  final String clubId;
  const ForumClubPage({super.key, required this.clubId});
  @override State<ForumClubPage> createState() => _ForumClubPageState();
}
class _ForumClubPageState extends State<ForumClubPage> {
  final post = TextEditingController();
  bool busy = false;
  @override void dispose() { post.dispose(); super.dispose(); }
  Future<void> _join() async {
    try { await _v6Db.collection('forumClubs').doc(widget.clubId).update({'members': FieldValue.arrayUnion([_v6Uid])}); }
    catch (_) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تعذر الانضمام للنادي.'))); }
  }
  Future<void> _send() async {
    final value = post.text.trim();
    if (value.isEmpty || busy) return;
    setState(() => busy = true);
    try {
      await _v6Db.collection('forumClubs').doc(widget.clubId).collection('posts').add({
        'authorId': _v6Uid, 'authorName': _v6Name, 'text': value, 'createdAt': FieldValue.serverTimestamp(),
      });
      post.clear();
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('انضم للنادي أولاً أو تحقق من قواعد Firestore.')));
    } finally { if (mounted) setState(() => busy = false); }
  }
  @override
  Widget build(BuildContext context) => Directionality(textDirection: TextDirection.rtl,
    child: Scaffold(appBar: AppBar(title: const Text('مجتمع النادي')),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: _v6Db.collection('forumClubs').doc(widget.clubId).snapshots(),
        builder: (context, clubSnap) {
          if (!clubSnap.hasData) return const Center(child: CircularProgressIndicator());
          if (!clubSnap.data!.exists) return const Center(child: Text('هذا النادي غير متاح.'));
          final club = clubSnap.data!.data()!;
          final members = (club['members'] as List?) ?? [];
          final joined = members.contains(_v6Uid);
          return Column(children: [
            Padding(padding: const EdgeInsets.all(14), child: Card(child: Padding(padding: const EdgeInsets.all(14),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Text(club['name']?.toString() ?? 'نادي', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                Text(club['description']?.toString() ?? ''),
                Text((club['category']?.toString() ?? 'متنوع') + ' • ' + members.length.toString() + ' عضو'),
                if (!joined) Align(alignment: Alignment.centerLeft, child: FilledButton.icon(onPressed: _join, icon: const Icon(Icons.group_add), label: const Text('انضم للنادي'))),
              ])))),
            Expanded(child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _v6Db.collection('forumClubs').doc(widget.clubId).collection('posts').orderBy('createdAt', descending: true).limit(80).snapshots(),
              builder: (context, snap) {
                if (snap.hasError) return const Center(child: Text('تعذر تحميل نقاشات النادي.'));
                if (!snap.hasData) return const Center(child: CircularProgressIndicator());
                if (snap.data!.docs.isEmpty) return const Center(child: Text('ابدأ أول نقاش داخل النادي.'));
                return ListView(padding: const EdgeInsets.symmetric(horizontal: 12), children: snap.data!.docs.map((doc) {
                  final d = doc.data();
                  return Card(child: ListTile(leading: const CircleAvatar(child: Icon(Icons.person)), title: Text(d['authorName']?.toString() ?? 'عضو'), subtitle: Text(d['text']?.toString() ?? '')));
                }).toList());
              },
            )),
            if (joined) SafeArea(top: false, child: Padding(padding: const EdgeInsets.all(10), child: Row(children: [
              Expanded(child: TextField(controller: post, maxLength: 1000, minLines: 1, maxLines: 4, decoration: const InputDecoration(hintText: 'اكتب مشاركة للنادي...', border: OutlineInputBorder(), counterText: ''))),
              const SizedBox(width: 8),
              IconButton.filled(onPressed: busy ? null : _send, icon: const Icon(Icons.send)),
            ]))),
          ]);
        },
      ),
    ));
}

class DailyMissionsPage extends StatefulWidget {
  const DailyMissionsPage({super.key});
  @override State<DailyMissionsPage> createState() => _DailyMissionsPageState();
}
class _DailyMissionsPageState extends State<DailyMissionsPage> {
  static const missions = [
    'شارك بكلمة إيجابية مع أحد الأعضاء', 'تعلّم معلومة جديدة واكتبها بملاحظاتك',
    'اقرأ اقتباساً أو صفحة من كتاب', 'اسأل صديقاً عن يومه واطمئن عليه',
    'جرّب لعبة جديدة في الملتقى', 'اكتب هدفاً صغيراً تريد إنجازه',
    'شارك في نقاش باحترام وفائدة', 'رتّب ملفك الشخصي وحدّث نبذتك',
    'اكتشف قسماً جديداً داخل الملتقى', 'اكتب ثلاثة أشياء أنت ممتن لها',
  ];
  Set<int> done = {};
  bool ready = false;
  String get _date { final d = DateTime.now(); return d.year.toString() + '-' + d.month.toString() + '-' + d.day.toString(); }
  @override void initState() { super.initState(); _load(); }
  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final savedDate = prefs.getString('v6_mission_date');
    if (savedDate != _date) {
      await prefs.setString('v6_mission_date', _date);
      await prefs.setString('v6_mission_done', '');
      done = {};
    } else {
      done = (prefs.getString('v6_mission_done') ?? '').split(',').where((x) => x.isNotEmpty)
        .map((x) => int.tryParse(x) ?? -1).where((x) => x >= 0 && x < missions.length).toSet();
    }
    if (mounted) setState(() => ready = true);
  }
  Future<void> _toggle(int i, bool value) async {
    setState(() { if (value) { done.add(i); } else { done.remove(i); } });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('v6_mission_done', done.join(','));
  }
  @override
  Widget build(BuildContext context) => Directionality(textDirection: TextDirection.rtl,
    child: Scaffold(appBar: AppBar(title: const Text('مهامي اليومية')),
      body: !ready ? const Center(child: CircularProgressIndicator()) : ListView(padding: const EdgeInsets.all(14), children: [
        Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('خطوات صغيرة تصنع فرقاً كبيراً 🌱', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6), Text('أنجزت ' + done.length.toString() + ' من ' + missions.length.toString() + ' مهام اليوم'),
          const SizedBox(height: 10), LinearProgressIndicator(value: done.length / missions.length),
        ]))),
        ...List.generate(missions.length, (i) => CheckboxListTile(
          value: done.contains(i), onChanged: (v) => _toggle(i, v ?? false),
          title: Text(missions[(DateTime.now().day + i) % missions.length]),
          secondary: CircleAvatar(child: Text((i + 1).toString())),
        )),
        const Padding(padding: EdgeInsets.all(8), child: Text('تُحفظ قائمة المهام على هذا الجهاز فقط ولا تُضاف نقاط عامة تلقائياً.', style: TextStyle(color: Colors.grey, fontSize: 12))),
      ]),
    ));
}

class GratitudeWallPage extends StatefulWidget {
  const GratitudeWallPage({super.key});
  @override State<GratitudeWallPage> createState() => _GratitudeWallPageState();
}
class _GratitudeWallPageState extends State<GratitudeWallPage> {
  final text = TextEditingController();
  bool busy = false;
  @override void dispose() { text.dispose(); super.dispose(); }
  Future<void> _publish() async {
    final value = text.text.trim();
    if (value.isEmpty || busy) return;
    setState(() => busy = true);
    try {
      await _v6Db.collection('forumThanks').add({'authorId': _v6Uid, 'authorName': _v6Name, 'text': value, 'createdAt': FieldValue.serverTimestamp()});
      text.clear();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('وصلت رسالتك الطيبة 💜')));
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تعذر النشر. تحقق من قواعد Firestore.')));
    } finally { if (mounted) setState(() => busy = false); }
  }
  @override
  Widget build(BuildContext context) => Directionality(textDirection: TextDirection.rtl,
    child: Scaffold(appBar: AppBar(title: const Text('جدار الامتنان')),
      body: Column(children: [
        Padding(padding: const EdgeInsets.all(12), child: Card(child: Padding(padding: const EdgeInsets.all(12), child: Column(children: [
          const Text('خلّي أثرك كلمة طيبة 🌷', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          TextField(controller: text, maxLength: 400, maxLines: 3, decoration: const InputDecoration(hintText: 'اكتب كلمة شكر أو رسالة إيجابية...')),
          Align(alignment: Alignment.centerLeft, child: FilledButton.icon(onPressed: busy ? null : _publish, icon: const Icon(Icons.send), label: Text(busy ? 'جارٍ النشر...' : 'انشر'))),
        ])))),
        Expanded(child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _v6Db.collection('forumThanks').orderBy('createdAt', descending: true).limit(80).snapshots(),
          builder: (context, snap) {
            if (snap.hasError) return const Center(child: Text('تعذر تحميل جدار الامتنان.'));
            if (!snap.hasData) return const Center(child: CircularProgressIndicator());
            if (snap.data!.docs.isEmpty) return const Center(child: Text('كن أول من يترك كلمة طيبة.'));
            return ListView(padding: const EdgeInsets.symmetric(horizontal: 12), children: snap.data!.docs.map((doc) {
              final d = doc.data();
              return Card(child: ListTile(leading: const CircleAvatar(backgroundColor: Color(0xFFFFE6EF), child: Icon(Icons.favorite, color: Colors.pink)), title: Text(d['authorName']?.toString() ?? 'عضو'), subtitle: Text(d['text']?.toString() ?? '')));
            }).toList());
          },
        )),
      ]),
    ));
}

class V6SafetyPage extends StatelessWidget {
  const V6SafetyPage({super.key});
  @override
  Widget build(BuildContext context) => Directionality(textDirection: TextDirection.rtl,
    child: Scaffold(appBar: AppBar(title: const Text('السلامة والخصوصية')),
      body: ListView(padding: const EdgeInsets.all(16), children: const [
        _SafetyTip(icon: Icons.password, title: 'احمِ كلمة المرور', body: 'استخدم كلمة مرور قوية ومختلفة، ولا تشاركها مع أي شخص بما في ذلك المشرفون.'),
        _SafetyTip(icon: Icons.location_off, title: 'لا تكشف موقعك', body: 'لا تنشر عنوان المنزل أو موقعك المباشر أو بياناتك الشخصية في الغرف العامة.'),
        _SafetyTip(icon: Icons.link_off, title: 'انتبه للروابط', body: 'لا تفتح روابط مجهولة ولا تثبّت ملفات APK مرسلة من حسابات غير موثوقة.'),
        _SafetyTip(icon: Icons.block, title: 'استخدم الحظر والإبلاغ', body: 'احتفظ بالدليل عند التعرض للإساءة، واستخدم أدوات الحظر والإبلاغ المتاحة.'),
        _SafetyTip(icon: Icons.verified_user, title: 'احترم خصوصية الآخرين', body: 'لا تنشر صوراً أو محادثات أو معلومات شخص آخر دون إذنه.'),
      ]),
    ));
}
class _SafetyTip extends StatelessWidget {
  final IconData icon; final String title, body;
  const _SafetyTip({required this.icon, required this.title, required this.body});
  @override
  Widget build(BuildContext context) => Card(child: ListTile(leading: Icon(icon, color: _v6Brand), title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)), subtitle: Text(body)));
}



class FocusRoomPage extends StatefulWidget {
  const FocusRoomPage({super.key});
  @override State<FocusRoomPage> createState() => _FocusRoomPageState();
}

class _FocusRoomPageState extends State<FocusRoomPage> {
  Timer? _timer;
  int _minutes = 25;
  int _seconds = 0;
  int _sessions = 0;
  bool _running = false;
  bool _breakMode = false;
  final _taskController = TextEditingController();
  int get _total => _minutes * 60 + _seconds;

  @override void initState() { super.initState(); _loadSessions(); }
  @override void dispose() { _timer?.cancel(); _taskController.dispose(); super.dispose(); }

  Future<void> _loadSessions() async {
    final p = await SharedPreferences.getInstance();
    if (mounted) setState(() => _sessions = p.getInt('focus_sessions') ?? 0);
  }

  void _start() {
    if (_running) return;
    if (_total == 0) _reset();
    setState(() => _running = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) { timer.cancel(); return; }
      if (_minutes == 0 && _seconds == 0) {
        timer.cancel();
        final wasFocus = !_breakMode;
        setState(() {
          _running = false;
          if (!_breakMode) { _sessions++; _breakMode = true; _minutes = 5; }
          else { _breakMode = false; _minutes = 25; }
          _seconds = 0;
        });
        SharedPreferences.getInstance().then((p) => p.setInt('focus_sessions', _sessions));
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(wasFocus ? 'أحسنت! اكتملت جلسة تركيز 🎉' : 'انتهت الاستراحة، مستعد لجلسة جديدة؟')));
        return;
      }
      setState(() {
        if (_seconds == 0) { _minutes--; _seconds = 59; } else { _seconds--; }
      });
    });
  }

  void _pause() { _timer?.cancel(); setState(() => _running = false); }
  void _reset() {
    _timer?.cancel();
    setState(() { _running = false; _breakMode = false; _minutes = 25; _seconds = 0; });
  }

  @override Widget build(BuildContext context) {
    final progress = (1 - (_total / ((_breakMode ? 5 : 25) * 60)).clamp(0.0, 1.0)).toDouble();
    return Directionality(textDirection: TextDirection.rtl, child: Scaffold(
      appBar: AppBar(title: const Text('مساحة التركيز')),
      body: ListView(padding: const EdgeInsets.all(18), children: [
        Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(colors: [Color(0xFF171936), _v6Brand, Color(0xFF168E9B)])),
          child: Column(children: [
            Text(_breakMode ? 'وقت الاستراحة ☕' : 'وقت الإنجاز 🎯', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
            const SizedBox(height: 20),
            SizedBox(width: 210, height: 210, child: Stack(alignment: Alignment.center, children: [
              SizedBox.expand(child: CircularProgressIndicator(value: progress, strokeWidth: 11, backgroundColor: Colors.white24, valueColor: const AlwaysStoppedAnimation<Color>(Colors.white))),
              Text('${_minutes.toString().padLeft(2, '0')}:${_seconds.toString().padLeft(2, '0')}', style: const TextStyle(color: Colors.white, fontSize: 42, fontWeight: FontWeight.w900)),
            ])),
            const SizedBox(height: 18),
            Text('جلسات مكتملة: $_sessions', style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
          ]),
        ),
        const SizedBox(height: 16),
        TextField(controller: _taskController, onChanged: (_) => setState(() {}), maxLength: 100, decoration: const InputDecoration(labelText: 'شنو المهمة اللي تريد تركز عليها؟', prefixIcon: Icon(Icons.edit_note), border: OutlineInputBorder())),
        Row(children: [
          Expanded(child: FilledButton.icon(onPressed: _running ? _pause : _start, icon: Icon(_running ? Icons.pause : Icons.play_arrow), label: Text(_running ? 'إيقاف مؤقت' : 'ابدأ التركيز'))),
          const SizedBox(width: 8),
          OutlinedButton.icon(onPressed: _reset, icon: const Icon(Icons.restart_alt), label: const Text('إعادة')),
        ]),
        const SizedBox(height: 12),
        Card(child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('طريقة الاستخدام', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
          const SizedBox(height: 6),
          const Text('ركز 25 دقيقة على مهمة واحدة، ثم خذ استراحة 5 دقائق. كرر الجلسات وسجّل تقدمك بهدوء.'),
          if (_taskController.text.trim().isNotEmpty) Text('مهمتك الحالية: ${_taskController.text.trim()}', style: const TextStyle(fontWeight: FontWeight.bold)),
        ]))),
      ]),
    ));
  }
}

class PersonalGrowthPage extends StatefulWidget {
  const PersonalGrowthPage({super.key});
  @override State<PersonalGrowthPage> createState() => _PersonalGrowthPageState();
}

class _PersonalGrowthPageState extends State<PersonalGrowthPage> {
  static const moods = ['مبسوط 😄', 'مرتاح 🙂', 'عادي 😐', 'متعب 😔', 'متوتر 😣'];
  static const habits = ['شربت ماء كفاية', 'قرأت أو تعلمت شيئاً', 'تحركت أو مارست الرياضة', 'تواصلت مع شخص أحبه', 'أنجزت مهمة مهمة'];
  final note = TextEditingController();
  final goal = TextEditingController();
  String mood = moods[1];
  Set<int> checked = {};
  List<String> goals = [];
  List<String> notes = [];
  bool ready = false;
  String get today {
    final d = DateTime.now();
    return '${d.year}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}';
  }

  @override void initState() { super.initState(); _load(); }
  @override void dispose() { note.dispose(); goal.dispose(); super.dispose(); }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    mood = p.getString('growth_mood_$today') ?? moods[1];
    checked = (p.getString('growth_habits_$today') ?? '').split(',').where((x) => x.isNotEmpty)
      .map((x) => int.tryParse(x) ?? -1).where((x) => x >= 0 && x < habits.length).toSet();
    goals = p.getStringList('growth_goals') ?? [];
    notes = p.getStringList('growth_notes') ?? [];
    if (mounted) setState(() => ready = true);
  }

  Future<void> _saveMood() async {
    final p = await SharedPreferences.getInstance();
    await p.setString('growth_mood_$today', mood);
    await p.setString('growth_habits_$today', checked.join(','));
  }

  Future<void> _addGoal() async {
    final v = goal.text.trim();
    if (v.isEmpty) return;
    goals.insert(0, v);
    goal.clear();
    final p = await SharedPreferences.getInstance();
    await p.setStringList('growth_goals', goals);
    if (mounted) setState(() {});
  }

  Future<void> _addNote() async {
    final v = note.text.trim();
    if (v.isEmpty) return;
    notes.insert(0, '$today • $v');
    note.clear();
    final p = await SharedPreferences.getInstance();
    await p.setStringList('growth_notes', notes.take(50).toList());
    if (mounted) setState(() {});
  }

  Future<void> _removeGoal(int i) async {
    goals.removeAt(i);
    final p = await SharedPreferences.getInstance();
    await p.setStringList('growth_goals', goals);
    if (mounted) setState(() {});
  }

  @override Widget build(BuildContext context) => Directionality(textDirection: TextDirection.rtl,
    child: Scaffold(appBar: AppBar(title: const Text('مساحتي الشخصية')),
      body: !ready ? const Center(child: CircularProgressIndicator()) : ListView(padding: const EdgeInsets.all(14), children: [
        Container(padding: const EdgeInsets.all(18), decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: const LinearGradient(colors: [Color(0xFF171936), _v6Brand, Color(0xFF24AFC5)])),
          child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('كل يوم فرصة جديدة 🌱', style: TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.w900)),
            SizedBox(height: 6),
            Text('مساحة خاصة لترتيب أفكارك ومتابعة تقدمك. بياناتك محفوظة على جهازك.', style: TextStyle(color: Colors.white70)),
          ])),
        const SizedBox(height: 14),
        Card(child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('شلون مزاجك اليوم؟', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: moods.map((m) => ChoiceChip(label: Text(m), selected: mood == m,
            onSelected: (_) { setState(() => mood = m); _saveMood(); })).toList()),
          const SizedBox(height: 14),
          const Text('عاداتي الإيجابية اليوم', style: TextStyle(fontWeight: FontWeight.bold)),
          ...List.generate(habits.length, (i) => CheckboxListTile(dense: true, contentPadding: EdgeInsets.zero,
            value: checked.contains(i), title: Text(habits[i]), onChanged: (v) {
              setState(() { if (v == true) { checked.add(i); } else { checked.remove(i); } });
              _saveMood();
            })),
          LinearProgressIndicator(value: checked.length / habits.length),
          const SizedBox(height: 5),
          Text('${checked.length} من ${habits.length} عادات مكتملة'),
        ]))),
        Card(child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('أهدافي الصغيرة 🎯', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
          const SizedBox(height: 8),
          Row(children: [Expanded(child: TextField(controller: goal, maxLength: 100, decoration: const InputDecoration(hintText: 'مثلاً: أتعلم مهارة جديدة', counterText: ''))),
            IconButton.filled(onPressed: _addGoal, icon: const Icon(Icons.add))]),
          ...goals.asMap().entries.map((e) => ListTile(dense: true, contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.flag_outlined), title: Text(e.value), trailing: IconButton(icon: const Icon(Icons.close), onPressed: () => _removeGoal(e.key)))),
          if (goals.isEmpty) const Text('أضف هدفاً صغيراً تبدأ به اليوم.', style: TextStyle(color: Colors.grey)),
        ]))),
        Card(child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('دفتر ملاحظاتي ✍️', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
          TextField(controller: note, maxLength: 500, maxLines: 3, decoration: const InputDecoration(hintText: 'اكتب فكرة أو ذكرى أو شيئاً تريد تذكره...')),
          Align(alignment: Alignment.centerLeft, child: FilledButton.icon(onPressed: _addNote, icon: const Icon(Icons.save), label: const Text('حفظ الملاحظة'))),
          ...notes.take(10).map((n) => Card(color: Theme.of(context).colorScheme.surfaceContainerLow, child: Padding(padding: const EdgeInsets.all(10), child: Text(n)))),
          if (notes.isEmpty) const Text('ملاحظاتك الخاصة تظهر هنا.', style: TextStyle(color: Colors.grey)),
        ]))),
      ]),
    ));
}
