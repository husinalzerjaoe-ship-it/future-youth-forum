import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'achievement_hub.dart';
import 'anime_experience.dart';
import 'cinema_hub.dart';
import 'community_events.dart';
import 'community_polls.dart';
import 'football_live_center.dart';
import 'game_center.dart';
import 'inspiration_hub.dart';
import 'match_center.dart';
import 'v12_companion_center.dart';
import 'v18_discovery_hub.dart';
import 'v22_cinema_discovery.dart';
import 'v23_creative_lab.dart';

const _v21Accent = Color(0xFF8B72FF);

class V21UltimateHubPage extends StatefulWidget {
  const V21UltimateHubPage({super.key});
  @override
  State<V21UltimateHubPage> createState() => _V21UltimateHubPageState();
}
class _V21UltimateHubPageState extends State<V21UltimateHubPage> {
  final _search = TextEditingController();
  int _xp = 0;
  bool _loaded = false;
  static final _places = <_V21Place>[
    _V21Place('مختبر الإبداع اليومي', 'أفكار وتحديات كتابة وتصميم وتفكير مع حفظ المفضلة', Icons.lightbulb_circle_rounded, const V23CreativeLabPage(), 'تحديات إبداع كتابة تصميم تفكير يومي'),
    _V21Place('المكتبة الثقافية', 'قراءة ومقالات ورف محفوظ', Icons.auto_stories_rounded, const V21LibraryPage(), 'كتب قراءة ثقافة مقالات معرفة'),
    _V21Place('أكاديمية المستقبل', 'اختبارات ومراجعة', Icons.school_rounded, const V21AcademyPage(), 'تعليم دراسة أكاديمية اختبار'),
    _V21Place('استوديو الإبداع', 'اكتب أفكارك واحفظ مسوداتك', Icons.palette_rounded, const V21CreatorStudioPage(), 'إبداع كتابة خواطر'),
    _V21Place('مخطط الإنجاز', 'مهامك وأهدافك الشخصية', Icons.task_alt_rounded, const V21PlannerPage(), 'مهام أهداف تنظيم'),
    _V21Place('جدار الامتنان', 'احتفظ بلحظاتك الإيجابية', Icons.favorite_rounded, const V21GratitudePage(), 'امتنان يوميات'),
    _V21Place('تحدي اليوم', 'سؤال يومي ونقاط محلية', Icons.bolt_rounded, const V21DailyChallengePage(), 'تحدي يومي سؤال نقاط'),
    _V21Place('مركز الألعاب', 'ألعاب وأسئلة وتحديات', Icons.sports_esports_rounded, const GameCenterPage(), 'ألعاب مسابقات'),
    _V21Place('فعاليات الملتقى', 'المواعيد والتسجيل', Icons.event_rounded, const CommunityEventsPage(), 'فعاليات مسابقات'),
    _V21Place('تصويتات المجتمع', 'شارك برأيك', Icons.poll_rounded, const CommunityPollsPage(), 'تصويت استطلاع'),
    _V21Place('بطولات الأصدقاء', 'منافسات وتحديات', Icons.emoji_events_rounded, const V12CompanionCenterPage(), 'بطولات أصدقاء'),
    _V21Place('السينما', 'الأفلام والمسلسلات وغرف السينما', Icons.movie_rounded, const CinemaHubPage(), 'أفلام مسلسلات'),
    _V21Place('مكتبة أفلام 2025 و2026', 'اكتشاف الأفلام والمسلسلات الحديثة مع معلومات عربية', Icons.local_movies_rounded, const V22CinemaDiscoveryPage(), 'أفلام 2025 2026 مسلسلات حديثة سينما'),
    _V21Place('مركز الكرة', 'المباريات والنتائج', Icons.sports_soccer_rounded, const FootballLiveCenterPage(), 'كرة قدم رياضة'),
    _V21Place('عالم الأنمي', 'الخلفيات وقائمة المشاهدة', Icons.animation_rounded, const AnimeExperiencePage(), 'أنمي اوتاكو'),
    _V21Place('ديوان الإلهام', 'الشعر والاقتباسات', Icons.menu_book_rounded, const InspirationHubPage(), 'شعر اقتباسات'),
    _V21Place('مكتبة المعرفة V18', 'علوم وفضاء وثقافة ومطبخ', Icons.public_rounded, const V18DiscoveryHubPage(), 'علوم فضاء ثقافة'),
    _V21Place('الإنجازات', 'شارات ونشاط', Icons.military_tech_rounded, const AchievementHubPage(), 'إنجازات شارات'),
    _V21Place('جدول المباريات', 'المواعيد والنتائج', Icons.scoreboard_rounded, const MatchCenterPage(), 'مباريات جدول'),
  ];
  @override
  void initState() { super.initState(); _load(); }
  @override
  void dispose() { _search.dispose(); super.dispose(); }
  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() { _xp = p.getInt('v21_personal_xp') ?? 0; _loaded = true; });
  }
  @override
  Widget build(BuildContext context) {
    final q = _search.text.trim().toLowerCase();
    final visible = _places.where((p) => (p.title + ' ' + p.subtitle + ' ' + p.keywords).toLowerCase().contains(q)).toList();
    return Directionality(textDirection: TextDirection.rtl, child: Scaffold(
      appBar: AppBar(title: const Text('عالم الملتقى V21')),
      body: !_loaded ? const Center(child: CircularProgressIndicator()) : ListView(padding: const EdgeInsets.all(14), children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(24), gradient: const LinearGradient(begin: Alignment.topRight, end: Alignment.bottomLeft, colors: [Color(0xFF171936), Color(0xFF5B35B5), Color(0xFF087E91)])),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('عالم واحد… اهتمامات بلا حدود', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            const Text('مساحة للتعلّم والإبداع والتنظيم والتحديات، مع بقاء أقسام الملتقى الأساسية في مكانها.', style: TextStyle(color: Colors.white70, height: 1.5)),
            const SizedBox(height: 12),
            Text('رصيدك الشخصي: ' + _xp.toString() + ' XP', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ]),
        ),
        const SizedBox(height: 14),
        TextField(controller: _search, onChanged: (_) => setState(() {}), decoration: InputDecoration(hintText: 'ابحث عن قسم أو ميزة…', prefixIcon: const Icon(Icons.search_rounded), suffixIcon: _search.text.isEmpty ? null : IconButton(onPressed: () { _search.clear(); setState(() {}); }, icon: const Icon(Icons.close)), border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)))),
        const SizedBox(height: 12),
        Text('استكشف عالم الملتقى • ' + visible.length.toString() + ' قسم', style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900)),
        const SizedBox(height: 10),
        if (visible.isEmpty) const Padding(padding: EdgeInsets.all(24), child: Center(child: Text('ما لقينا نتيجة. جرّب كلمة ثانية.')))
        else LayoutBuilder(builder: (context, constraints) {
          final columns = constraints.maxWidth > 680 ? 3 : 2;
          return GridView.builder(
            shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: visible.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: columns, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 1.2),
            itemBuilder: (context, index) {
              final place = visible[index];
              return Card(clipBehavior: Clip.antiAlias, child: InkWell(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => place.page)),
                child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Container(width: 44, height: 44, decoration: BoxDecoration(color: _v21Accent.withValues(alpha: .14), borderRadius: BorderRadius.circular(14)), child: Icon(place.icon, color: _v21Accent, size: 25)),
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(place.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
                    const SizedBox(height: 4),
                    Text(place.subtitle, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                  ]),
                ])),
              ));
            },
          );
        }),
        const SizedBox(height: 10),
        const Text('المذكرات والمهام والمسودات والتقدم الشخصي تحفظ محلياً على هذا الجهاز. الأقسام الاجتماعية الحالية تواصل استخدام خدماتها الموجودة؛ لا توجد مزامنة سحابية جديدة للأصدقاء في V21.', style: TextStyle(fontSize: 11, color: Colors.grey, height: 1.5)),
      ]),
    ));
  }
}
class _V21Place {
  const _V21Place(this.title, this.subtitle, this.icon, this.page, this.keywords);
  final String title, subtitle, keywords;
  final IconData icon;
  final Widget page;
}

class V21LibraryPage extends StatefulWidget {
  const V21LibraryPage({super.key});
  @override
  State<V21LibraryPage> createState() => _V21LibraryPageState();
}
class _V21LibraryPageState extends State<V21LibraryPage> {
  static const _items = <_ReadItem>[
    _ReadItem('كيف تتعلم مهارة جديدة؟', 'التعلّم', 'قسّم المهارة إلى خطوات صغيرة، وخصص وقتاً ثابتاً للتدريب، وراجع ما تعلمته بتطبيق عملي.', Icons.school),
    _ReadItem('مدخل إلى التفكير النقدي', 'مهارات', 'اسأل عن مصدر المعلومة، وابحث عن الأدلة، وميّز بين الحقيقة والرأي، وراجع أكثر من وجهة نظر.', Icons.psychology),
    _ReadItem('رحلة قصيرة في الفضاء', 'علوم', 'تساعدنا دراسة الكواكب والنجوم على فهم نشأة الأنظمة الكونية وحركة الأجرام والمسافات الهائلة.', Icons.rocket_launch),
    _ReadItem('حضارات بلاد الرافدين', 'تاريخ', 'شهدت بلاد الرافدين نشوء مدن قديمة وأنظمة كتابة وإدارة وزراعة تركت أثراً مهماً في تاريخ البشر.', Icons.account_balance),
    _ReadItem('أساسيات الأمان الرقمي', 'تقنية', 'استخدم كلمات مرور فريدة، وفعّل التحقق بخطوتين، ولا تشارك رموز الدخول أو المعلومات الخاصة.', Icons.shield),
    _ReadItem('فن كتابة الخاطرة', 'أدب', 'ابدأ بصورة أو فكرة واحدة، واكتب بلغة واضحة، ثم راجع النص واحذف التكرار مع الحفاظ على صوتك الخاص.', Icons.edit_note),
    _ReadItem('كيف ننظم وقتنا؟', 'تنمية', 'اكتب أولوياتك، وحدد مهمة واحدة مهمة في كل فترة، واترك مساحة للراحة والتغيير عند الحاجة.', Icons.schedule),
    _ReadItem('مبادئ البيئة والاستدامة', 'طبيعة', 'ترشيد الموارد وتقليل النفايات وحماية التنوع الحيوي خطوات تساعد في الحفاظ على البيئة.', Icons.eco),
  ];
  final Set<String> _saved = {}, _read = {};
  bool _loaded = false;
  @override
  void initState() { super.initState(); _load(); }
  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    if (mounted) setState(() { _saved.addAll(p.getStringList('v21_library_saved') ?? const []); _read.addAll(p.getStringList('v21_library_read') ?? const []); _loaded = true; });
  }
  Future<void> _toggle(String title, Set<String> set, String key) async {
    setState(() { if (!set.add(title)) set.remove(title); });
    final p = await SharedPreferences.getInstance(); await p.setStringList(key, set.toList());
  }
  @override
  Widget build(BuildContext context) => Directionality(textDirection: TextDirection.rtl, child: Scaffold(
    appBar: AppBar(title: const Text('المكتبة الثقافية')),
    body: !_loaded ? const Center(child: CircularProgressIndicator()) : ListView(padding: const EdgeInsets.all(14), children: [
      const Text('اقرأ وتعلّم واحفظ ما يعجبك', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
      Text(_read.length.toString() + ' مقروءة • ' + _saved.length.toString() + ' محفوظة', style: const TextStyle(color: Colors.grey)),
      ..._items.map((item) => Card(child: ListTile(
        leading: CircleAvatar(child: Icon(item.icon, color: _v21Accent)), title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold)), subtitle: Text(item.category),
        trailing: IconButton(onPressed: () => _toggle(item.title, _saved, 'v21_library_saved'), icon: Icon(_saved.contains(item.title) ? Icons.bookmark : Icons.bookmark_border)),
        onTap: () => showDialog<void>(context: context, builder: (c) => Directionality(textDirection: TextDirection.rtl, child: AlertDialog(
          title: Text(item.title), content: SingleChildScrollView(child: Text(item.body, style: const TextStyle(height: 1.6))),
          actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text('إغلاق')), FilledButton(onPressed: () { Navigator.pop(c); _toggle(item.title, _read, 'v21_library_read'); }, child: const Text('تمت القراءة'))],
        ))),
      ))),
    ]),
  ));
}
class _ReadItem {
  const _ReadItem(this.title, this.category, this.body, this.icon);
  final String title, category, body;
  final IconData icon;
}

class V21AcademyPage extends StatefulWidget {
  const V21AcademyPage({super.key});
  @override
  State<V21AcademyPage> createState() => _V21AcademyPageState();
}
class _V21AcademyPageState extends State<V21AcademyPage> {
  static const _questions = <_AcademyQuestion>[
    _AcademyQuestion('ما اللغة الأساسية التي يستخدمها Flutter؟', ['Dart', 'Python', 'JavaScript'], 0, 'Flutter يستخدم لغة Dart لبناء التطبيقات.'),
    _AcademyQuestion('ما وظيفة HTTPS؟', ['ضغط الصور', 'حماية الاتصال بالتشفير', 'زيادة مساحة الهاتف'], 1, 'HTTPS يحمي البيانات أثناء انتقالها.'),
    _AcademyQuestion('أي كوكب يُعرف بالكوكب الأحمر؟', ['الزهرة', 'المريخ', 'نبتون'], 1, 'يظهر المريخ بلون مائل إلى الأحمر بسبب أكاسيد الحديد على سطحه.'),
    _AcademyQuestion('ما النهران الأشهر في بلاد الرافدين؟', ['دجلة والفرات', 'النيل والكونغو', 'الأردن والليطاني'], 0, 'دجلة والفرات يرتبطان بتاريخ بلاد الرافدين.'),
    _AcademyQuestion('ما وحدة قياس شدة التيار الكهربائي؟', ['الفولت', 'الأمبير', 'الواط'], 1, 'الأمبير هو وحدة قياس شدة التيار.'),
    _AcademyQuestion('أي مما يأتي يساعد على حماية الحساب؟', ['مشاركة رمز الدخول', 'كلمة مرور فريدة والتحقق بخطوتين', 'استخدام كلمة واحدة لكل المواقع'], 1, 'استخدم كلمة مرور مختلفة وفعّل التحقق بخطوتين.'),
  ];
  int _index = 0, _score = 0;
  int? _choice;
  bool _done = false;
  Future<void> _next() async {
    if (_choice == null) return;
    if (_index + 1 == _questions.length) {
      setState(() => _done = true);
      final p = await SharedPreferences.getInstance();
      if (_score > (p.getInt('v21_academy_best') ?? 0)) await p.setInt('v21_academy_best', _score);
    } else { setState(() { _index++; _choice = null; }); }
  }
  void _answer(int i) { if (_choice != null) return; setState(() { _choice = i; if (i == _questions[_index].answer) _score++; }); }
  void _restart() => setState(() { _index = 0; _score = 0; _choice = null; _done = false; });
  @override
  Widget build(BuildContext context) {
    final q = _questions[_index];
    return Directionality(textDirection: TextDirection.rtl, child: Scaffold(
      appBar: AppBar(title: const Text('أكاديمية المستقبل')),
      body: _done ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.workspace_premium_rounded, size: 66, color: Color(0xFFFFC857)),
        const Text('أحسنت! أكملت الاختبار', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900)),
        Text('نتيجتك ' + _score.toString() + ' من ' + _questions.length.toString()),
        const SizedBox(height: 12), FilledButton.icon(onPressed: _restart, icon: const Icon(Icons.replay), label: const Text('إعادة الاختبار')),
      ])) : ListView(padding: const EdgeInsets.all(18), children: [
        LinearProgressIndicator(value: (_index + 1) / _questions.length, minHeight: 7),
        Text('السؤال ' + (_index + 1).toString() + ' من ' + _questions.length.toString() + ' • النتيجة ' + _score.toString(), style: const TextStyle(color: _v21Accent, fontWeight: FontWeight.bold)),
        const SizedBox(height: 18), Text(q.text, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
        ...List.generate(q.options.length, (i) => Card(
          color: _choice == i ? (_choice == q.answer ? Colors.green.withValues(alpha: .16) : Colors.red.withValues(alpha: .12)) : null,
          child: ListTile(onTap: () => _answer(i), title: Text(q.options[i]), trailing: _choice == i ? const Icon(Icons.check_circle) : null),
        )),
        if (_choice != null) ...[Text(q.explanation), FilledButton(onPressed: _next, child: Text(_index + 1 == _questions.length ? 'عرض النتيجة' : 'السؤال التالي'))],
      ]),
    ));
  }
}
class _AcademyQuestion {
  const _AcademyQuestion(this.text, this.options, this.answer, this.explanation);
  final String text, explanation;
  final List<String> options;
  final int answer;
}

class V21CreatorStudioPage extends StatefulWidget {
  const V21CreatorStudioPage({super.key});
  @override
  State<V21CreatorStudioPage> createState() => _V21CreatorStudioPageState();
}
class _V21CreatorStudioPageState extends State<V21CreatorStudioPage> {
  final _title = TextEditingController(), _body = TextEditingController();
  List<Map<String, String>> _drafts = [];
  bool _loaded = false;
  @override
  void initState() { super.initState(); _load(); }
  @override
  void dispose() { _title.dispose(); _body.dispose(); super.dispose(); }
  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    try { _drafts = (jsonDecode(p.getString('v21_creator_drafts') ?? '[]') as List).map((e) => Map<String, String>.from(e as Map)).toList(); } catch (_) { _drafts = []; }
    if (mounted) setState(() => _loaded = true);
  }
  Future<void> _save() async {
    if (_title.text.trim().isEmpty || _body.text.trim().isEmpty) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('اكتب عنواناً ونصاً قبل الحفظ.'))); return; }
    _drafts.insert(0, {'title': _title.text.trim(), 'body': _body.text.trim()});
    final p = await SharedPreferences.getInstance(); await p.setString('v21_creator_drafts', jsonEncode(_drafts));
    _title.clear(); _body.clear(); if (mounted) setState(() {});
  }
  Future<void> _delete(int i) async { _drafts.removeAt(i); final p = await SharedPreferences.getInstance(); await p.setString('v21_creator_drafts', jsonEncode(_drafts)); if (mounted) setState(() {}); }
  @override
  Widget build(BuildContext context) => Directionality(textDirection: TextDirection.rtl, child: Scaffold(
    appBar: AppBar(title: const Text('استوديو الإبداع')),
    body: !_loaded ? const Center(child: CircularProgressIndicator()) : ListView(padding: const EdgeInsets.all(14), children: [
      const Text('مساحة لأفكارك ومسوداتك', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
      TextField(controller: _title, maxLength: 80, decoration: const InputDecoration(labelText: 'عنوان الفكرة', border: OutlineInputBorder())),
      TextField(controller: _body, minLines: 4, maxLines: 8, maxLength: 4000, decoration: const InputDecoration(labelText: 'اكتب خاطرتك أو فكرتك أو مسودتك', border: OutlineInputBorder())),
      FilledButton.icon(onPressed: _save, icon: const Icon(Icons.save_rounded), label: const Text('حفظ المسودة')),
      Text('مسوداتي (' + _drafts.length.toString() + ')', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
      ..._drafts.asMap().entries.map((e) => Card(child: ListTile(
        title: Text(e.value['title'] ?? 'مسودة'), subtitle: Text(e.value['body'] ?? '', maxLines: 2, overflow: TextOverflow.ellipsis),
        onTap: () => showDialog<void>(context: context, builder: (c) => Directionality(textDirection: TextDirection.rtl, child: AlertDialog(title: Text(e.value['title'] ?? 'مسودة'), content: SingleChildScrollView(child: Text(e.value['body'] ?? '')), actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text('إغلاق'))]))),
        trailing: IconButton(onPressed: () => _delete(e.key), icon: const Icon(Icons.delete_outline)),
      ))),
    ]),
  ));
}

class V21PlannerPage extends StatefulWidget {
  const V21PlannerPage({super.key});
  @override
  State<V21PlannerPage> createState() => _V21PlannerPageState();
}
class _V21PlannerPageState extends State<V21PlannerPage> {
  final _controller = TextEditingController();
  List<Map<String, dynamic>> _tasks = [];
  bool _loaded = false;
  @override
  void initState() { super.initState(); _load(); }
  @override
  void dispose() { _controller.dispose(); super.dispose(); }
  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    try { _tasks = (jsonDecode(p.getString('v21_tasks') ?? '[]') as List).map((e) => Map<String, dynamic>.from(e as Map)).toList(); } catch (_) { _tasks = []; }
    if (mounted) setState(() => _loaded = true);
  }
  Future<void> _persist() async { final p = await SharedPreferences.getInstance(); await p.setString('v21_tasks', jsonEncode(_tasks)); }
  Future<void> _add() async { final v = _controller.text.trim(); if (v.isEmpty) return; setState(() { _tasks.insert(0, {'text': v, 'done': false}); _controller.clear(); }); await _persist(); }
  Future<void> _toggle(int i, bool? v) async { setState(() => _tasks[i]['done'] = v ?? false); await _persist(); }
  Future<void> _delete(int i) async { setState(() => _tasks.removeAt(i)); await _persist(); }
  @override
  Widget build(BuildContext context) => Directionality(textDirection: TextDirection.rtl, child: Scaffold(
    appBar: AppBar(title: const Text('مخطط الإنجاز')),
    body: !_loaded ? const Center(child: CircularProgressIndicator()) : ListView(padding: const EdgeInsets.all(14), children: [
      const Text('رتّب أهدافك بخطوات بسيطة', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
      Row(children: [Expanded(child: TextField(controller: _controller, maxLength: 120, decoration: const InputDecoration(hintText: 'أضف مهمة جديدة', border: OutlineInputBorder()))), IconButton.filled(onPressed: _add, icon: const Icon(Icons.add))]),
      Text(_tasks.where((t) => t['done'] == true).length.toString() + ' من ' + _tasks.length.toString() + ' مهام مكتملة'),
      LinearProgressIndicator(value: _tasks.isEmpty ? 0 : _tasks.where((t) => t['done'] == true).length / _tasks.length),
      ..._tasks.asMap().entries.map((e) => Card(child: CheckboxListTile(value: e.value['done'] == true, onChanged: (v) => _toggle(e.key, v), title: Text(e.value['text']?.toString() ?? '', style: TextStyle(decoration: e.value['done'] == true ? TextDecoration.lineThrough : null)), secondary: IconButton(onPressed: () => _delete(e.key), icon: const Icon(Icons.delete_outline))))),
    ]),
  ));
}

class V21GratitudePage extends StatefulWidget {
  const V21GratitudePage({super.key});
  @override
  State<V21GratitudePage> createState() => _V21GratitudePageState();
}
class _V21GratitudePageState extends State<V21GratitudePage> {
  final _controller = TextEditingController();
  List<String> _entries = [];
  bool _loaded = false;
  @override
  void initState() { super.initState(); _load(); }
  @override
  void dispose() { _controller.dispose(); super.dispose(); }
  Future<void> _load() async { final p = await SharedPreferences.getInstance(); if (mounted) setState(() { _entries = p.getStringList('v21_gratitude') ?? []; _loaded = true; }); }
  Future<void> _add() async { final v = _controller.text.trim(); if (v.isEmpty) return; _entries.insert(0, v); final p = await SharedPreferences.getInstance(); await p.setStringList('v21_gratitude', _entries.take(100).toList()); _controller.clear(); if (mounted) setState(() {}); }
  Future<void> _delete(int i) async { _entries.removeAt(i); final p = await SharedPreferences.getInstance(); await p.setStringList('v21_gratitude', _entries); if (mounted) setState(() {}); }
  @override
  Widget build(BuildContext context) => Directionality(textDirection: TextDirection.rtl, child: Scaffold(
    appBar: AppBar(title: const Text('جدار الامتنان الشخصي')),
    body: !_loaded ? const Center(child: CircularProgressIndicator()) : ListView(padding: const EdgeInsets.all(14), children: [
      const Text('دوّن الأشياء الجميلة التي تود تذكرها', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900)),
      TextField(controller: _controller, maxLength: 300, minLines: 2, maxLines: 4, decoration: const InputDecoration(hintText: 'شيء أنا ممتن له اليوم…', border: OutlineInputBorder())),
      FilledButton.icon(onPressed: _add, icon: const Icon(Icons.favorite_rounded), label: const Text('إضافة ذكرى')),
      ..._entries.asMap().entries.map((e) => Card(child: ListTile(leading: const Icon(Icons.favorite, color: Colors.pinkAccent), title: Text(e.value), trailing: IconButton(onPressed: () => _delete(e.key), icon: const Icon(Icons.delete_outline))))),
    ]),
  ));
}

class V21DailyChallengePage extends StatefulWidget {
  const V21DailyChallengePage({super.key});
  @override
  State<V21DailyChallengePage> createState() => _V21DailyChallengePageState();
}
class _V21DailyChallengePageState extends State<V21DailyChallengePage> {
  static const _questions = <_AcademyQuestion>[
    _AcademyQuestion('ما عاصمة العراق؟', ['بغداد', 'البصرة', 'الموصل'], 0, 'بغداد عاصمة جمهورية العراق.'),
    _AcademyQuestion('ما الكوكب الأكبر في مجموعتنا الشمسية؟', ['الأرض', 'المشتري', 'عطارد'], 1, 'المشتري هو أكبر كواكب المجموعة الشمسية.'),
    _AcademyQuestion('ما اسم الكتابة التي اشتهر بها السومريون؟', ['المسمارية', 'الهيروغليفية', 'اللاتينية'], 0, 'الكتابة المسمارية ارتبطت بحضارات بلاد الرافدين.'),
    _AcademyQuestion('ما الذي تحتاجه النباتات للبناء الضوئي؟', ['الذهب', 'ضوء الشمس', 'الملح فقط'], 1, 'تستخدم النباتات ضوء الشمس في عملية البناء الضوئي.'),
    _AcademyQuestion('كم ضلعاً للمثلث؟', ['ثلاثة', 'أربعة', 'خمسة'], 0, 'للمثلث ثلاثة أضلاع.'),
  ];
  int? _choice;
  bool _loaded = false, _claimed = false;
  int _questionIndex = 0;
  String get _key { final n = DateTime.now(); return 'v21_daily_' + n.year.toString() + '_' + n.month.toString() + '_' + n.day.toString(); }
  @override
  void initState() { super.initState(); _load(); }
  Future<void> _load() async { final p = await SharedPreferences.getInstance(); if (mounted) setState(() { _claimed = p.getBool(_key) ?? false; _questionIndex = DateTime.now().day % _questions.length; _loaded = true; }); }
  Future<void> _answer() async {
    if (_choice == null || _claimed) return;
    final correct = _choice == _questions[_questionIndex].answer;
    final p = await SharedPreferences.getInstance(); await p.setBool(_key, true);
    if (correct) await p.setInt('v21_personal_xp', (p.getInt('v21_personal_xp') ?? 0) + 10);
    if (!mounted) return;
    setState(() => _claimed = true);
    showDialog<void>(context: context, builder: (c) => Directionality(textDirection: TextDirection.rtl, child: AlertDialog(
      title: Text(correct ? 'إجابة صحيحة!' : 'محاولة جميلة'),
      content: Text((correct ? 'حصلت على 10 نقاط محلية. ' : 'ما حصلت نقاط اليوم. ') + _questions[_questionIndex].explanation),
      actions: [FilledButton(onPressed: () => Navigator.pop(c), child: const Text('تمام'))],
    )));
  }
  @override
  Widget build(BuildContext context) {
    final q = _questions[_questionIndex];
    return Directionality(textDirection: TextDirection.rtl, child: Scaffold(
      appBar: AppBar(title: const Text('تحدي اليوم')),
      body: !_loaded ? const Center(child: CircularProgressIndicator()) : ListView(padding: const EdgeInsets.all(18), children: [
        const Icon(Icons.bolt_rounded, size: 54, color: Color(0xFFFFC857)),
        const Text('سؤال واحد كل يوم', textAlign: TextAlign.center, style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900)),
        const SizedBox(height: 12), Text(q.text, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
        ...List.generate(q.options.length, (i) => Card(child: RadioListTile<int>(value: i, groupValue: _choice, onChanged: _claimed ? null : (v) => setState(() => _choice = v), title: Text(q.options[i])))),
        FilledButton(onPressed: _claimed || _choice == null ? null : _answer, child: Text(_claimed ? 'أكملت تحدي اليوم' : 'تأكيد الإجابة')),
        const Text('النقاط محلية على هذا الجهاز ولا تمثل ترتيباً عاماً أو جائزة.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 11)),
      ]),
    ));
  }
}
