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
import 'v19_interactive_hub.dart';

const _v20Purple = Color(0xFF806BFF);

class V20CityHubPage extends StatefulWidget {
  const V20CityHubPage({super.key});
  @override
  State<V20CityHubPage> createState() => _V20CityHubPageState();
}

class _V20CityHubPageState extends State<V20CityHubPage> {
  int _xp = 0, _theme = 0;
  bool _loaded = false, _claimedToday = false;
  static const _themes = <List<Color>>[
    [Color(0xFF172554), Color(0xFF6D28D9), Color(0xFF0891B2)],
    [Color(0xFF064E3B), Color(0xFF0F766E), Color(0xFF164E63)],
    [Color(0xFF7C2D12), Color(0xFF9D174D), Color(0xFF4C1D95)],
    [Color(0xFF1E293B), Color(0xFF334155), Color(0xFF475569)],
  ];
  static final _districts = <_V20District>[
    _V20District('حي السينما', 'أفلام ومسلسلات', Icons.movie_rounded, const CinemaHubPage()),
    _V20District('الملعب الكبير', 'مباريات ونتائج مباشرة', Icons.sports_soccer_rounded, const FootballLiveCenterPage()),
    _V20District('ساحة البطولات', 'تحديات وبطولات الأصدقاء', Icons.emoji_events_rounded, const V12CompanionCenterPage()),
    _V20District('مدينة الألعاب', 'ألعاب وأسئلة وتحديات', Icons.sports_esports_rounded, const GameCenterPage()),
    _V20District('مركز الفعاليات', 'أنشطة ومسابقات الملتقى', Icons.event_available_rounded, const CommunityEventsPage()),
    _V20District('مكتبة المعرفة', 'تعلم وعلوم وثقافة', Icons.auto_stories_rounded, const V18DiscoveryHubPage()),
    _V20District('عالم الأنمي', 'قائمة المشاهدة والخلفيات', Icons.animation_rounded, const AnimeExperiencePage()),
    _V20District('ديوان الإلهام', 'شعر واقتباسات وخواطر', Icons.menu_book_rounded, const InspirationHubPage()),
    _V20District('مجلس التصويت', 'شارك برأيك واستطلاعاتك', Icons.how_to_vote_rounded, const CommunityPollsPage()),
    _V20District('مركز الإنجازات', 'أوسمة ونقاط النشاط', Icons.military_tech_rounded, const AchievementHubPage()),
    _V20District('جدول المباريات', 'المواعيد والنتائج', Icons.scoreboard_rounded, const MatchCenterPage()),
    _V20District('المركز الذكي', 'اختصارات وأدواتك الشخصية', Icons.hub_rounded, const V19InteractiveHubPage()),
  ];

  String get _dayKey {
    final now = DateTime.now();
    return 'v20_daily_claim_${now.year}_${now.month}_${now.day}';
  }

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _xp = prefs.getInt('v20_city_xp') ?? 0;
      _theme = (prefs.getInt('v20_city_theme') ?? 0).clamp(0, _themes.length - 1).toInt();
      _claimedToday = prefs.getBool(_dayKey) ?? false;
      _loaded = true;
    });
  }

  Future<void> _claimDaily() async {
    if (_claimedToday) return;
    final prefs = await SharedPreferences.getInstance();
    final next = _xp + 20;
    await prefs.setInt('v20_city_xp', next);
    await prefs.setBool(_dayKey, true);
    if (!mounted) return;
    setState(() { _xp = next; _claimedToday = true; });
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('أضفنا 20 نقطة محلية إلى رصيدك اليومي!')));
  }

  Future<void> _changeTheme() async {
    final next = (_theme + 1) % _themes.length;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('v20_city_theme', next);
    if (mounted) setState(() => _theme = next);
  }

  int get _level => (_xp ~/ 100) + 1;
  int get _levelProgress => _xp % 100;

  @override
  Widget build(BuildContext context) {
    final colors = _themes[_theme];
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('مدينة الملتقى V20'),
          actions: [IconButton(tooltip: 'تغيير مظهر المدينة', onPressed: _changeTheme, icon: const Icon(Icons.palette_rounded))],
        ),
        body: !_loaded ? const Center(child: CircularProgressIndicator()) : ListView(
          padding: const EdgeInsets.all(14),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(26),
                gradient: LinearGradient(begin: Alignment.topRight, end: Alignment.bottomLeft, colors: colors),
                boxShadow: [BoxShadow(color: colors.first.withValues(alpha: .22), blurRadius: 18, offset: const Offset(0, 8))],
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Row(children: [
                  Icon(Icons.location_city_rounded, color: Colors.white, size: 30),
                  SizedBox(width: 8),
                  Text('أهلاً بك في مدينتك الرقمية', style: TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w900)),
                ]),
                const SizedBox(height: 8),
                const Text('كل اهتمامات الملتقى في أحياء واضحة، افتح المكان الذي تحبه واكتشف أقسامك.', style: TextStyle(color: Colors.white70, height: 1.4)),
                const SizedBox(height: 18),
                Row(children: [
                  Expanded(child: _StatPill(icon: Icons.stars_rounded, label: 'المستوى ' + _level.toString(), value: _xp.toString() + ' XP')),
                  const SizedBox(width: 8),
                  Expanded(child: _StatPill(icon: Icons.grid_view_rounded, label: 'أحياء المدينة', value: _districts.length.toString() + ' حي')),
                ]),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: LinearProgressIndicator(value: _levelProgress / 100, minHeight: 9, backgroundColor: Colors.white24, valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFFD66B))),
                ),
                const SizedBox(height: 5),
                Text(_levelProgress.toString() + ' / 100 نقطة للمستوى التالي', style: const TextStyle(color: Colors.white70, fontSize: 11)),
              ]),
            ),
            const SizedBox(height: 14),
            Card(child: ListTile(
              leading: const CircleAvatar(backgroundColor: Color(0x1A16A34A), child: Icon(Icons.today_rounded, color: Color(0xFF16A34A))),
              title: const Text('مهمة المدينة اليومية', style: TextStyle(fontWeight: FontWeight.w900)),
              subtitle: Text(_claimedToday ? 'أنجزت مكافأة اليوم • ارجع باچر لمهمة جديدة' : 'افتح المدينة وتعرّف على أحد أقسامها لتحصل على 20 نقطة محلية'),
              trailing: FilledButton(onPressed: _claimedToday ? null : _claimDaily, child: Text(_claimedToday ? 'تم' : '+20 XP')),
            )),
            const SizedBox(height: 12),
            Row(children: [
              const Expanded(child: Text('خريطة أحياء الملتقى', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900))),
              Text(_districts.length.toString() + ' وجهة', style: TextStyle(color: Theme.of(context).colorScheme.secondary)),
            ]),
            const SizedBox(height: 5),
            Text('اضغط على أي حي للدخول إلى القسم الموجود فيه.', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12)),
            const SizedBox(height: 10),
            LayoutBuilder(builder: (context, constraints) {
              final columns = constraints.maxWidth >= 650 ? 3 : 2;
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _districts.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: columns, crossAxisSpacing: 9, mainAxisSpacing: 9, childAspectRatio: columns == 3 ? 1.35 : 1.18),
                itemBuilder: (context, index) {
                  final district = _districts[index];
                  final color = colors[index % colors.length];
                  return Material(
                    color: Theme.of(context).colorScheme.surfaceContainer,
                    borderRadius: BorderRadius.circular(19),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => district.page)),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                          Row(children: [
                            Container(width: 42, height: 42, decoration: BoxDecoration(color: color.withValues(alpha: .15), borderRadius: BorderRadius.circular(13)), child: Icon(district.icon, color: color, size: 24)),
                            const Spacer(),
                            Icon(Icons.north_west_rounded, size: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
                          ]),
                          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(district.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
                            const SizedBox(height: 3),
                            Text(district.subtitle, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                          ]),
                        ]),
                      ),
                    ),
                  );
                },
              );
            }),
            const SizedBox(height: 14),
            Card(child: ListTile(
              leading: const Icon(Icons.tune_rounded, color: _v20Purple),
              title: const Text('تخصيص ألوان المدينة', style: TextStyle(fontWeight: FontWeight.w800)),
              subtitle: const Text('بدّل بين أربعة أجواء لونية واحفظ اختيارك على جهازك'),
              trailing: const Icon(Icons.chevron_left_rounded),
              onTap: _changeTheme,
            )),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text('ملاحظة: نقاط المستوى ومكافأة اليوم والمظهر تُحفظ محلياً على هذا الجهاز. الأحياء تفتح الأقسام الحالية؛ لا تمثل هذه النقاط ترتيباً عاماً بين الأعضاء أو جوائز فعلية.', style: TextStyle(fontSize: 11, color: Colors.grey, height: 1.4)),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
    decoration: BoxDecoration(color: Colors.white.withValues(alpha: .13), borderRadius: BorderRadius.circular(14)),
    child: Row(children: [
      Icon(icon, color: const Color(0xFFFFD66B), size: 20),
      const SizedBox(width: 7),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10)),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13)),
      ])),
    ]),
  );
}

class _V20District {
  const _V20District(this.title, this.subtitle, this.icon, this.page);
  final String title, subtitle;
  final IconData icon;
  final Widget page;
}
