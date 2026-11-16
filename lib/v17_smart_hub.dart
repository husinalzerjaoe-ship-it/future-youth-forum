import 'package:flutter/material.dart';
import 'v18_discovery_hub.dart';
import 'v19_interactive_hub.dart';
import 'v20_city_hub.dart';
import 'v21_ultimate_hub.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'achievement_hub.dart';
import 'advanced_features.dart';
import 'anime_experience.dart';
import 'cinema_hub.dart';
import 'community_events.dart';
import 'community_polls.dart';
import 'football_live_center.dart';
import 'game_center.dart';
import 'inspiration_hub.dart';
import 'local_bot.dart';
import 'match_center.dart';
import 'v12_companion_center.dart';

const _v17Purple = Color(0xFF806BFF);
final ValueNotifier<Color> v17AccentNotifier = ValueNotifier<Color>(_v17Purple);
final ValueNotifier<bool> v17ReduceMotionNotifier = ValueNotifier<bool>(false);
final ValueNotifier<bool> v17CompactCardsNotifier = ValueNotifier<bool>(false);

class V17SmartHubPage extends StatefulWidget {
  const V17SmartHubPage({super.key});
  @override
  State<V17SmartHubPage> createState() => _V17SmartHubPageState();
}

class _V17SmartHubPageState extends State<V17SmartHubPage> {
  final _search = TextEditingController();
  int _tab = 0;
  static final List<_Destination> _destinations = [
    _Destination('سينما الملتقى', 'الأفلام والمسلسلات وتفاصيلها', Icons.movie_filter_rounded, () => const CinemaHubPage(), 'فيلم مسلسل ترجمة سينما'),
    _Destination('مركز الكرة المباشر', 'النتائج والمواعيد والقنوات الرسمية', Icons.sports_soccer_rounded, () => const FootballLiveCenterPage(), 'رياضة كرة قنوات مباراة'),
    _Destination('مركز المباريات', 'البطولات والنتائج وشعارات الأندية', Icons.scoreboard_rounded, () => const MatchCenterPage(), 'نتائج دوري جدول'),
    _Destination('مركز الألعاب', 'تحديات وأسئلة وألعاب متنوعة', Icons.sports_esports_rounded, () => const GameCenterPage(), 'لعبة مسابقة أسئلة'),
    _Destination('الفعاليات والمسابقات', 'أنشطة الملتقى والتسجيل', Icons.event_available_rounded, () => const CommunityEventsPage(), 'فعالية حدث بطولة'),
    _Destination('بطولات الأصدقاء', 'إنشاء بطولة وتحديات بين أعضاء الملتقى', Icons.emoji_events_rounded, () => const V12CompanionCenterPage(), 'بطولة تحدي أصدقاء مسابقة'),
    _Destination('الإنجازات والأوسمة', 'النقاط وسلاسل النشاط والشارات', Icons.military_tech_rounded, () => const AchievementHubPage(), 'إنجاز شارة نقاط'),
    _Destination('التصويتات', 'استطلاعات المجتمع', Icons.poll_rounded, () => const CommunityPollsPage(), 'تصويت استطلاع'),
    _Destination('مركز الإشعارات', 'تنبيهات المنشن والتفاعلات والأحداث', Icons.notifications_active_rounded, () => const NotificationsPage(), 'إشعار تنبيه منشن رسالة'),
    _Destination('عالم الأنمي', 'قائمة المشاهدة وخلفيات الأنمي', Icons.animation_rounded, () => const AnimeExperiencePage(), 'أنمي اوتاكو'),
    _Destination('مكتبة الإلهام', 'الشعر والاقتباسات والخواطر', Icons.auto_stories_rounded, () => const InspirationHubPage(), 'شعر اقتباس خواطر'),
    _Destination('المساعد المحلي', 'مساعدة وأفكار داخل التطبيق', Icons.smart_toy_rounded, () => const LocalHelperBotPage(), 'مساعد ذكاء مساعدة'),
    _Destination('مركز V19 التفاعلي', 'اختصارات ذكية ومساحة شخصية ومتابعة أقسام الملتقى', Icons.hub_rounded, () => const V19InteractiveHubPage(), 'V19 مركز تفاعلي اختصارات ملاحظات مهمة امتنان'),
    _Destination('مدينة الملتقى V20', 'خريطة الأحياء والمستويات والمهام اليومية وتخصيص المدينة', Icons.location_city_rounded, () => const V20CityHubPage(), 'V20 مدينة خريطة أحياء مستوى نقاط مهمة يومية'),
    _Destination('عالم الملتقى V21', 'المكتبة الثقافية والأكاديمية واستوديو الإبداع ومخطط الإنجاز والتحديات', Icons.auto_awesome_rounded, () => const V21UltimateHubPage(), 'V21 عالم مكتبة أكاديمية إبداع مهام امتنان تحدي يومي'),
    _Destination('مكتبة V18 الشاملة', 'ديوان وأذكار وأكاديمية وعلوم ومطبخ وثقافة وبودكاست', Icons.auto_awesome_rounded, () => const V18DiscoveryHubPage(), 'شعر دعاء ذكر قرآن تعليم علوم فضاء مطبخ العراق بودكاست ثقافة'),
  ];

  @override
  void dispose() { _search.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final q = _search.text.trim().toLowerCase();
    final results = _destinations.where((d) => ('${d.title} ${d.description} ${d.keywords}').toLowerCase().contains(q)).toList();
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('مركز الملتقى الذكي'),
          actions: [IconButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const V17DeviceSettingsPage())), icon: const Icon(Icons.tune_rounded))],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(54),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
              child: SegmentedButton<int>(
                segments: const [
                  ButtonSegment(value: 0, label: Text('بحث شامل'), icon: Icon(Icons.search)),
                  ButtonSegment(value: 1, label: Text('ألعاب جديدة'), icon: Icon(Icons.gamepad_rounded)),
                  ButtonSegment(value: 2, label: Text('تخصيص'), icon: Icon(Icons.palette_outlined)),
                ],
                selected: {_tab},
                onSelectionChanged: (v) => setState(() => _tab = v.first),
              ),
            ),
          ),
        ),
        body: IndexedStack(index: _tab, children: [
          _searchPage(results),
          const V17MiniGamesPage(),
          const V17DeviceSettingsPage(embedded: true),
        ]),
      ),
    );
  }

  Widget _searchPage(List<_Destination> results) => ListView(
    padding: const EdgeInsets.all(14),
    children: [
      Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(22), gradient: const LinearGradient(colors: [_v17Purple, Color(0xFF352A79)])),
        child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('كل الملتقى بمكان واحد', style: TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.w900)),
          SizedBox(height: 6),
          Text('ابحث عن قسم وافتحه مباشرة.', style: TextStyle(color: Colors.white70)),
        ]),
      ),
      const SizedBox(height: 14),
      TextField(
        controller: _search,
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          hintText: 'ابحث عن سينما، مباراة، أنمي، فعالية...',
          prefixIcon: const Icon(Icons.search_rounded),
          suffixIcon: _search.text.isEmpty ? null : IconButton(onPressed: () { _search.clear(); setState(() {}); }, icon: const Icon(Icons.close)),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
      const SizedBox(height: 12),
      if (results.isEmpty)
        const Padding(padding: EdgeInsets.all(24), child: Center(child: Text('ما لقينا قسماً مطابقاً. جرّب كلمة ثانية.')))
      else
        ...results.asMap().entries.map((entry) {
          final d = entry.value;
          const covers = <List<Color>>[
            [Color(0xFF5636A8), Color(0xFF172554)], [Color(0xFF00695C), Color(0xFF123B50)],
            [Color(0xFFAD4B16), Color(0xFF54236E)], [Color(0xFF2457A6), Color(0xFF20204C)],
          ];
          final colors = covers[entry.key % covers.length];
          return Card(
            margin: const EdgeInsets.only(bottom: 10), clipBehavior: Clip.antiAlias,
            child: InkWell(onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => d.page())),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topRight, end: Alignment.bottomLeft, colors: colors)),
                child: Row(children: [
                  Container(width: 54, height: 54, decoration: BoxDecoration(color: Colors.white.withValues(alpha: .15), borderRadius: BorderRadius.circular(16)),
                    child: Icon(d.icon, color: Colors.white, size: 30)),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(d.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 4), Text(d.description, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                  ])),
                  const Icon(Icons.chevron_left_rounded, color: Colors.white),
                ]),
              )),
          );
        }),
    ],
  );
}

class _Destination {
  const _Destination(this.title, this.description, this.icon, this.page, this.keywords);
  final String title, description, keywords;
  final IconData icon;
  final Widget Function() page;
}

class V17MiniGamesPage extends StatelessWidget {
  const V17MiniGamesPage({super.key});
  static const games = <_Quiz>[
    _Quiz('تحدي العلوم', 'علوم واكتشافات', Icons.science_rounded, [
      _Question('ما الكوكب الأقرب إلى الشمس؟', ['عطارد', 'الأرض', 'المريخ', 'زحل'], 0, 'عطارد أقرب كواكب المجموعة الشمسية إلى الشمس.'),
      _Question('ما الغاز الذي تمتصه النباتات في البناء الضوئي؟', ['الأكسجين', 'ثاني أكسيد الكربون', 'الهيليوم', 'الهيدروجين'], 1, 'تمتص النباتات ثاني أكسيد الكربون.'),
      _Question('ما وحدة قياس شدة التيار؟', ['الفولت', 'الأوم', 'الأمبير', 'الواط'], 2, 'الأمبير وحدة قياس شدة التيار الكهربائي.'),
      _Question('ما الجزيء الذي يحمل المعلومات الوراثية؟', ['DNA', 'النشا', 'الكالسيوم', 'الهيموغلوبين'], 0, 'يحمل DNA التعليمات الوراثية.'),
    ]),
    _Quiz('ذاكرة العراق', 'حضارة ومدن وتاريخ', Icons.account_balance_rounded, [
      _Question('ما النهران اللذان يمران بالعراق؟', ['النيل والأمازون', 'دجلة والفرات', 'الأردن والليطاني', 'السند والغانج'], 1, 'دجلة والفرات من أبرز أنهار بلاد الرافدين.'),
      _Question('قرب أي مدينة تقع آثار بابل؟', ['الحلة', 'دهوك', 'الناصرية', 'السليمانية'], 0, 'تقع آثار بابل قرب مدينة الحلة.'),
      _Question('أي كتابة ارتبطت بحضارة سومر؟', ['الهيروغليفية', 'المسمارية', 'اللاتينية', 'السنسكريتية'], 1, 'الكتابة المسمارية من أقدم أنظمة الكتابة.'),
      _Question('أين تقع زقورة أور؟', ['ذي قار', 'نينوى', 'الأنبار', 'دهوك'], 0, 'تقع زقورة أور في محافظة ذي قار.'),
    ]),
    _Quiz('تحدي كرة القدم', 'قواعد ومعلومات كروية', Icons.sports_soccer_rounded, [
      _Question('كم لاعباً يبدأ به الفريق داخل الملعب؟', ['9', '10', '11', '12'], 2, 'يتكون الفريق من 11 لاعباً.'),
      _Question('كم دقيقة مدة الشوط الواحد؟', ['30', '40', '45', '50'], 2, 'مدة الشوط 45 دقيقة قبل بدل الضائع.'),
      _Question('ما لون البطاقة التي تعني الطرد؟', ['الصفراء', 'الحمراء', 'الزرقاء', 'الخضراء'], 1, 'البطاقة الحمراء تعني الطرد.'),
      _Question('كم نقطة يمنح الفوز في نظام الدوري الشائع؟', ['نقطة', 'نقطتان', 'ثلاث نقاط', 'أربع نقاط'], 2, 'الفوز يمنح ثلاث نقاط.'),
    ]),
    _Quiz('رحلة حول العالم', 'جغرافيا وعواصم', Icons.public_rounded, [
      _Question('ما عاصمة اليابان؟', ['كيوتو', 'طوكيو', 'أوساكا', 'ناغويا'], 1, 'طوكيو هي عاصمة اليابان.'),
      _Question('في أي قارة تقع الأرجنتين؟', ['أوروبا', 'آسيا', 'أمريكا الجنوبية', 'أفريقيا'], 2, 'تقع الأرجنتين في أمريكا الجنوبية.'),
      _Question('ما أكبر محيط على الأرض؟', ['الأطلسي', 'الهندي', 'الهادئ', 'المتجمد الشمالي'], 2, 'المحيط الهادئ هو الأكبر.'),
      _Question('ما عاصمة أستراليا؟', ['سيدني', 'ملبورن', 'كانبيرا', 'بيرث'], 2, 'كانبيرا هي العاصمة.'),
    ]),
    _Quiz('أسرار التقنية', 'حاسوب وإنترنت وابتكار', Icons.memory_rounded, [
      _Question('ماذا تعني CPU؟', ['وحدة المعالجة المركزية', 'ذاكرة الصور', 'وحدة الطاقة', 'نظام الملفات'], 0, 'CPU هي وحدة المعالجة المركزية.'),
      _Question('أي لغة يستخدمها Flutter؟', ['Dart', 'Ruby', 'PHP', 'Lua'], 0, 'Flutter يعتمد على لغة Dart.'),
      _Question('ما وظيفة HTTPS الأساسية؟', ['ضغط الصور', 'تشفير الاتصال', 'زيادة الشاشة', 'إيقاف الإنترنت'], 1, 'HTTPS يحمي الاتصال بالتشفير.'),
      _Question('أي امتداد شائع لملفات الصور؟', ['.mp3', '.jpg', '.apk', '.zip'], 1, 'JPG صيغة صور شائعة.'),
    ]),
    _Quiz('مملكة الحيوانات', 'عالم الحيوان والطبيعة', Icons.pets_rounded, [
      _Question('ما أسرع حيوان بري؟', ['الأسد', 'الفهد', 'الحصان', 'الذئب'], 1, 'الفهد أسرع الحيوانات البرية.'),
      _Question('ما أكبر حيوان معروف؟', ['الفيل', 'الحوت الأزرق', 'الزرافة', 'القرش الأبيض'], 1, 'الحوت الأزرق أكبر الحيوانات المعروفة.'),
      _Question('ماذا تسمى يرقات الضفادع؟', ['شراغيف', 'جراء', 'فراخ', 'يرقات نحل'], 0, 'تسمى يرقات الضفادع بالشراغيف.'),
      _Question('أي طائر يستطيع تقليد أصوات كثيرة؟', ['الببغاء', 'البطريق', 'النعامة', 'النسر'], 0, 'تشتهر الببغاوات بتقليد الأصوات.'),
    ]),
  ];

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(14),
    children: [
      const Text('ست ألعاب جديدة', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900)),
      const SizedBox(height: 5),
      const Text('كل لعبة فيها أسئلة وإجابات وتفسير للجواب الصحيح.'),
      const SizedBox(height: 12),
      ...games.map((g) => Card(
        margin: const EdgeInsets.only(bottom: 10),
        child: ListTile(
          contentPadding: const EdgeInsets.all(14),
          leading: CircleAvatar(radius: 25, backgroundColor: _v17Purple.withValues(alpha: .16), child: Icon(g.icon, color: _v17Purple)),
          title: Text(g.title, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text('${g.subtitle} • ${g.questions.length} أسئلة'),
          trailing: const Icon(Icons.play_circle_fill_rounded, color: _v17Purple, size: 30),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => V17QuizPlayPage(quiz: g))),
        ),
      )),
    ],
  );
}

class _Quiz {
  const _Quiz(this.title, this.subtitle, this.icon, this.questions);
  final String title, subtitle;
  final IconData icon;
  final List<_Question> questions;
}

class _Question {
  const _Question(this.text, this.options, this.answer, this.explanation);
  final String text, explanation;
  final List<String> options;
  final int answer;
}

class V17QuizPlayPage extends StatefulWidget {
  const V17QuizPlayPage({super.key, required this.quiz});
  final _Quiz quiz;
  @override
  State<V17QuizPlayPage> createState() => _V17QuizPlayPageState();
}

class _V17QuizPlayPageState extends State<V17QuizPlayPage> {
  int _index = 0, _score = 0;
  int? _selected;
  bool _finished = false;

  void _answer(int i) {
    if (_selected != null) return;
    setState(() { _selected = i; if (i == widget.quiz.questions[_index].answer) _score++; });
  }

  Future<void> _next() async {
    if (_index + 1 < widget.quiz.questions.length) {
      setState(() { _index++; _selected = null; });
      return;
    }
    setState(() => _finished = true);
    final prefs = await SharedPreferences.getInstance();
    final key = 'v17_best_${widget.quiz.title}';
    if (_score > (prefs.getInt(key) ?? 0)) await prefs.setInt(key, _score);
  }

  void _restart() => setState(() { _index = 0; _score = 0; _selected = null; _finished = false; });

  @override
  Widget build(BuildContext context) {
    final q = widget.quiz.questions[_index];
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: Text(widget.quiz.title)),
        body: _finished
          ? Center(child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.emoji_events_rounded, size: 64, color: Color(0xFFFFC857)),
                const SizedBox(height: 12),
                const Text('انتهى التحدي!', style: TextStyle(fontSize: 25, fontWeight: FontWeight.w900)),
                Text('نتيجتك: $_score من ${widget.quiz.questions.length}', style: const TextStyle(fontSize: 18)),
                const SizedBox(height: 18),
                FilledButton.icon(onPressed: _restart, icon: const Icon(Icons.replay), label: const Text('إعادة اللعب')),
              ]),
            ))
          : ListView(padding: const EdgeInsets.all(18), children: [
              LinearProgressIndicator(value: (_index + 1) / widget.quiz.questions.length, minHeight: 7),
              const SizedBox(height: 12),
              Text('السؤال ${_index + 1} من ${widget.quiz.questions.length} • النقاط $_score', style: const TextStyle(color: _v17Purple, fontWeight: FontWeight.bold)),
              const SizedBox(height: 18),
              Text(q.text, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w900)),
              const SizedBox(height: 16),
              ...List.generate(q.options.length, (i) {
                final selected = _selected == i;
                final correct = _selected != null && i == q.answer;
                return Card(
                  color: correct ? Colors.green.withValues(alpha: .16) : selected ? Colors.red.withValues(alpha: .12) : null,
                  child: ListTile(
                    title: Text(q.options[i]),
                    trailing: correct ? const Icon(Icons.check_circle, color: Colors.green) : selected ? const Icon(Icons.cancel, color: Colors.red) : null,
                    onTap: _selected == null ? () => _answer(i) : null,
                  ),
                );
              }),
              if (_selected != null) ...[
                const SizedBox(height: 10),
                Text(q.explanation),
                const SizedBox(height: 12),
                FilledButton(onPressed: _next, child: Text(_index + 1 == widget.quiz.questions.length ? 'عرض النتيجة' : 'السؤال التالي')),
              ],
            ]),
      ),
    );
  }
}

class V17DeviceSettingsPage extends StatefulWidget {
  const V17DeviceSettingsPage({super.key, this.embedded = false});
  final bool embedded;
  @override
  State<V17DeviceSettingsPage> createState() => _V17DeviceSettingsPageState();
}

class _V17DeviceSettingsPageState extends State<V17DeviceSettingsPage> {
  String _performance = 'balanced', _quality = 'auto', _refresh = 'system', _accent = 'purple';
  bool _reduceMotion = false, _compactCards = false, _loaded = false;
  static const _colors = <String, Color>{
    'purple': Color(0xFF806BFF), 'cyan': Color(0xFF26C6DA),
    'blue': Color(0xFF448AFF), 'gold': Color(0xFFFFC857),
  };

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _performance = p.getString('v17_performance') ?? 'balanced';
      _quality = p.getString('v17_media_quality') ?? 'auto';
      _refresh = p.getString('v17_refresh_preference') ?? 'system';
      _accent = p.getString('v17_accent') ?? 'purple';
      _reduceMotion = p.getBool('v17_reduce_motion') ?? false;
      _compactCards = p.getBool('v17_compact_cards') ?? false;
      _loaded = true;
      v17AccentNotifier.value = _colors[_accent] ?? _v17Purple;
      v17ReduceMotionNotifier.value = _reduceMotion;
      v17CompactCardsNotifier.value = _compactCards;
    });
  }

  Future<void> _save() async {
    final p = await SharedPreferences.getInstance();
    await p.setString('v17_performance', _performance);
    await p.setString('v17_media_quality', _quality);
    await p.setString('v17_refresh_preference', _refresh);
    await p.setString('v17_accent', _accent);
    await p.setBool('v17_reduce_motion', _reduceMotion);
    await p.setBool('v17_compact_cards', _compactCards);
    v17AccentNotifier.value = _colors[_accent] ?? _v17Purple;
    v17ReduceMotionNotifier.value = _reduceMotion;
    v17CompactCardsNotifier.value = _compactCards;
    PaintingBinding.instance.imageCache.maximumSize = _performance == 'high' ? 600 : _performance == 'battery' ? 160 : 320;
    final baseCacheBytes = _performance == 'high' ? 120 * 1024 * 1024 : _performance == 'battery' ? 24 * 1024 * 1024 : 64 * 1024 * 1024;
    PaintingBinding.instance.imageCache.maximumSizeBytes = _quality == 'data'
        ? baseCacheBytes ~/ 2
        : _quality == 'high' ? baseCacheBytes : (baseCacheBytes * 3) ~/ 4;
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حفظ تفضيلات V17 على هذا الجهاز.')));
  }

  @override
  Widget build(BuildContext context) {
    final body = !_loaded
      ? const Center(child: CircularProgressIndicator())
      : ListView(padding: const EdgeInsets.all(16), children: [
          const Text('تخصيص الأداء والمظهر', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          const Text('هذه تفضيلات داخل التطبيق وعلى هذا الجهاز. معدل تحديث الشاشة الفعلي يحدده الهاتف والنظام ولا يمكن فرضه من التطبيق.'),
          const SizedBox(height: 14),
          _section('الأداء', Icons.speed_rounded, [
            DropdownButtonFormField<String>(
              value: _performance,
              decoration: const InputDecoration(labelText: 'ملف الأداء', border: OutlineInputBorder()),
              items: const [
                DropdownMenuItem(value: 'battery', child: Text('توفير الطاقة')),
                DropdownMenuItem(value: 'balanced', child: Text('متوازن')),
                DropdownMenuItem(value: 'high', child: Text('أداء عالٍ')),
              ],
              onChanged: (v) => setState(() => _performance = v ?? 'balanced'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _refresh,
              decoration: const InputDecoration(labelText: 'تفضيل سلاسة العرض (لا يغيّر تردد الشاشة)', border: OutlineInputBorder()),
              items: const [
                DropdownMenuItem(value: 'system', child: Text('حسب الجهاز والنظام')),
                DropdownMenuItem(value: '60', child: Text('استهداف 60 إطاراً عند الإمكان')),
                DropdownMenuItem(value: '90', child: Text('استهداف 90 إطاراً عند الإمكان')),
                DropdownMenuItem(value: '120', child: Text('استهداف 120 إطاراً عند الإمكان')),
              ],
              onChanged: (v) => setState(() => _refresh = v ?? 'system'),
            ),
          ]),
          const SizedBox(height: 14),
          _section('جودة الوسائط', Icons.high_quality_rounded, [
            DropdownButtonFormField<String>(
              value: _quality,
              decoration: const InputDecoration(labelText: 'تفضيل جودة الوسائط', helperText: 'الجودة النهائية تعتمد على الخيارات التي يوفرها مصدر الصورة أو الفيديو.', border: OutlineInputBorder()),
              items: const [
                DropdownMenuItem(value: 'auto', child: Text('تلقائية حسب الاتصال')),
                DropdownMenuItem(value: 'data', child: Text('موفرة للبيانات')),
                DropdownMenuItem(value: 'high', child: Text('عالية عند توفر المصدر')),
              ],
              onChanged: (v) => setState(() => _quality = v ?? 'auto'),
            ),
          ]),
          const SizedBox(height: 14),
          _section('المظهر والملف الشخصي', Icons.palette_rounded, [
            const Text('لون التمييز المحلي'),
            const SizedBox(height: 10),
            Wrap(spacing: 12, children: _colors.entries.map((e) => InkWell(
              onTap: () => setState(() => _accent = e.key),
              borderRadius: BorderRadius.circular(30),
              child: CircleAvatar(radius: 19, backgroundColor: e.value, child: _accent == e.key ? const Icon(Icons.check, color: Colors.white) : null),
            )).toList()),
            SwitchListTile(contentPadding: EdgeInsets.zero, value: _compactCards, onChanged: (v) => setState(() => _compactCards = v), title: const Text('بطاقات مضغوطة')),
            SwitchListTile(contentPadding: EdgeInsets.zero, value: _reduceMotion, onChanged: (v) => setState(() => _reduceMotion = v), title: const Text('تقليل الحركة والمؤثرات')),
          ]),
          const SizedBox(height: 14),
          FilledButton.icon(onPressed: _save, icon: const Icon(Icons.save_rounded), label: const Text('حفظ الإعدادات')),
          const SizedBox(height: 8),
          Text('لون التمييز: $_accent • ملف الأداء: $_performance', style: TextStyle(color: _colors[_accent])),
        ]);
    if (widget.embedded) return Directionality(textDirection: TextDirection.rtl, child: body);
    return Directionality(textDirection: TextDirection.rtl, child: Scaffold(appBar: AppBar(title: const Text('إعدادات الجهاز والتخصيص')), body: body));
  }

  Widget _section(String title, IconData icon, List<Widget> children) => Card(
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Icon(icon, color: _colors[_accent]), const SizedBox(width: 8), Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16))]),
        const SizedBox(height: 12),
        ...children,
      ]),
    ),
  );
}
