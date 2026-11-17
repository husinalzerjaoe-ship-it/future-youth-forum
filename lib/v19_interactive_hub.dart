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

const _v19Accent = Color(0xFF8B72FF);

class V19InteractiveHubPage extends StatefulWidget {
  const V19InteractiveHubPage({super.key});
  @override
  State<V19InteractiveHubPage> createState() => _V19InteractiveHubPageState();
}

class _V19InteractiveHubPageState extends State<V19InteractiveHubPage> {
  final _search = TextEditingController();
  final Set<String> _favorites = {};
  bool _favoritesOnly = false;
  static final List<_V19Shortcut> _shortcuts = [
    _V19Shortcut('سينما الملتقى', 'الأفلام والمسلسلات', Icons.movie_rounded, () => const CinemaHubPage(), 'سينما فيلم مسلسل'),
    _V19Shortcut('مركز الكرة المباشر', 'متابعة المباريات والنتائج', Icons.sports_soccer_rounded, () => const FootballLiveCenterPage(), 'كرة قدم رياضة مباريات'),
    _V19Shortcut('مركز المباريات', 'الجداول والنتائج', Icons.scoreboard_rounded, () => const MatchCenterPage(), 'جدول نتائج دوري'),
    _V19Shortcut('الألعاب والتحديات', 'ألعاب وأسئلة للأصدقاء', Icons.sports_esports_rounded, () => const GameCenterPage(), 'لعبة ألعاب تحدي'),
    _V19Shortcut('فعاليات الملتقى', 'المسابقات والأنشطة', Icons.event_rounded, () => const CommunityEventsPage(), 'فعالية مسابقة حدث'),
    _V19Shortcut('بطولات الأصدقاء', 'تحديات جماعية', Icons.emoji_events_rounded, () => const V12CompanionCenterPage(), 'بطولة أصدقاء'),
    _V19Shortcut('الإنجازات والأوسمة', 'نقاط وشارات النشاط', Icons.military_tech_rounded, () => const AchievementHubPage(), 'إنجاز نقاط شارة'),
    _V19Shortcut('تصويتات المجتمع', 'شارك برأيك', Icons.poll_rounded, () => const CommunityPollsPage(), 'تصويت استطلاع'),
    _V19Shortcut('عالم الأنمي', 'قائمة المشاهدة والخلفيات', Icons.animation_rounded, () => const AnimeExperiencePage(), 'أنمي اوتاكو'),
    _V19Shortcut('مكتبة الإلهام', 'الشعر والاقتباسات', Icons.auto_stories_rounded, () => const InspirationHubPage(), 'شعر اقتباسات خواطر'),
    _V19Shortcut('مكتبة V18 الشاملة', 'التعلم والعلوم والثقافة', Icons.auto_awesome_rounded, () => const V18DiscoveryHubPage(), 'تعليم علوم فضاء ثقافة العراق'),
  ];

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() => _favorites.addAll(prefs.getStringList('v19_shortcut_favorites') ?? const []));
  }

  Future<void> _toggleFavorite(String title) async {
    setState(() {
      if (!_favorites.add(title)) _favorites.remove(title);
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('v19_shortcut_favorites', _favorites.toList());
  }

  Future<void> _openPrivateSpace(String title, String key, String hint) async {
    final prefs = await SharedPreferences.getInstance();
    final controller = TextEditingController(text: prefs.getString(key) ?? '');
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: Text(title),
          content: SizedBox(
            width: 420,
            child: TextField(
              controller: controller,
              minLines: 4,
              maxLines: 8,
              maxLength: 1200,
              decoration: InputDecoration(hintText: hint, border: const OutlineInputBorder()),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('إغلاق')),
            FilledButton(
              onPressed: () async {
                final value = controller.text.trim();
                await prefs.setString(key, value);
                if (dialogContext.mounted) Navigator.pop(dialogContext);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('انحفظت ملاحظتك على هذا الجهاز.')),
                  );
                }
              },
              child: const Text('حفظ'),
            ),
          ],
        ),
      ),
    );
    controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _search.text.trim().toLowerCase();
    final filtered = _shortcuts.where((item) {
      final matches = ('${item.title} ${item.description} ${item.keywords}').toLowerCase().contains(query);
      return matches && (!_favoritesOnly || _favorites.contains(item.title));
    }).toList();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('مركز الملتقى V19'),
          actions: [
            IconButton(
              tooltip: 'المفضلة فقط',
              onPressed: () => setState(() => _favoritesOnly = !_favoritesOnly),
              icon: Icon(_favoritesOnly ? Icons.star_rounded : Icons.star_border_rounded),
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(14),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: const LinearGradient(
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                  colors: [Color(0xFF8B72FF), Color(0xFF30245F), Color(0xFF15213C)],
                ),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('كل اهتماماتك أقرب إلك', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
                  SizedBox(height: 7),
                  Text('رتّب أقسامك المفضلة وافتح خدمات الملتقى من مكان واحد.', style: TextStyle(color: Colors.white70)),
                  SizedBox(height: 12),
                  Row(children: [
                    Icon(Icons.bolt_rounded, color: Color(0xFFFFD66B)),
                    SizedBox(width: 6),
                    Text('نسخة V19 • اختصارات ومساحة شخصية', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                  ]),
                ],
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _search,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'ابحث عن قسم أو خدمة...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _search.text.isEmpty ? null : IconButton(
                  onPressed: () { _search.clear(); setState(() {}); },
                  icon: const Icon(Icons.close_rounded),
                ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
            const SizedBox(height: 10),
            const Text('مساحتك الشخصية', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            _PrivateToolTile(
              icon: Icons.sticky_note_2_rounded,
              title: 'دفتر ملاحظاتي',
              subtitle: 'ملاحظات خاصة محفوظة على جهازك',
              onTap: () => _openPrivateSpace('دفتر ملاحظاتي', 'v19_private_notes', 'اكتب أفكارك وملاحظاتك هنا...'),
            ),
            _PrivateToolTile(
              icon: Icons.today_rounded,
              title: 'مهمة اليوم',
              subtitle: 'حدد هدفاً صغيراً وتابع إنجازه بنفسك',
              onTap: () {
                final now = DateTime.now();
                final key = 'v19_daily_mission_${now.year}_${now.month}_${now.day}';
                _openPrivateSpace('مهمة اليوم', key, 'شنو الشيء المفيد اللي تريد تنجزه اليوم؟');
              },
            ),
            _PrivateToolTile(
              icon: Icons.volunteer_activism_rounded,
              title: 'مساحة الامتنان',
              subtitle: 'دوّن شيئاً إيجابياً تريد تذكره',
              onTap: () => _openPrivateSpace('مساحة الامتنان', 'v19_gratitude_note', 'اكتب شيئاً تشعر بالامتنان له...'),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                const Expanded(child: Text('أقسام الملتقى', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900))),
                Text('${filtered.length} قسم', style: TextStyle(color: Theme.of(context).colorScheme.secondary)),
              ],
            ),
            const SizedBox(height: 8),
            if (filtered.isEmpty)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: Text('ماكو نتائج. جرّب كلمة ثانية أو ألغِ فلتر المفضلة.')),
              )
            else
              ...filtered.map((item) => Card(
                margin: const EdgeInsets.only(bottom: 9),
                clipBehavior: Clip.antiAlias,
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  leading: CircleAvatar(
                    backgroundColor: _v19Accent.withValues(alpha: .16),
                    child: Icon(item.icon, color: _v19Accent),
                  ),
                  title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.w800)),
                  subtitle: Text(item.description),
                  trailing: IconButton(
                    tooltip: _favorites.contains(item.title) ? 'إزالة من المفضلة' : 'إضافة للمفضلة',
                    onPressed: () => _toggleFavorite(item.title),
                    icon: Icon(
                      _favorites.contains(item.title) ? Icons.star_rounded : Icons.star_border_rounded,
                      color: _favorites.contains(item.title) ? const Color(0xFFFFC857) : null,
                    ),
                  ),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => item.page())),
                ),
              )),
            const SizedBox(height: 12),
            const Text(
              'ملاحظة: دفتر الملاحظات ومهمة اليوم ومساحة الامتنان تحفظ بياناتها محلياً على هذا الجهاز، ولا تُنشر للأعضاء.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

class _PrivateToolTile extends StatelessWidget {
  const _PrivateToolTile({required this.icon, required this.title, required this.subtitle, required this.onTap});
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 7),
    child: ListTile(
      leading: Icon(icon, color: _v19Accent),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_left_rounded),
      onTap: onTap,
    ),
  );
}

class _V19Shortcut {
  const _V19Shortcut(this.title, this.description, this.icon, this.page, this.keywords);
  final String title;
  final String description;
  final IconData icon;
  final Widget Function() page;
  final String keywords;
}
