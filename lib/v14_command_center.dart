import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'achievement_hub.dart';
import 'anime_experience.dart';
import 'daily_world.dart';
import 'inspiration_hub.dart';
import 'local_bot.dart';
import 'advanced_features.dart';
import 'arcade_hub.dart';
import 'cinema_hub.dart';
import 'community_events.dart';
import 'community_expansion.dart' hide CommunityEventsPage;
import 'community_plus.dart';
import 'community_polls.dart';
import 'creative_library.dart';
import 'engagement_features.dart';
import 'enhanced_public_chat.dart';
import 'football_live_center.dart';
import 'football_news.dart';
import 'friends_battle_arena.dart';
import 'future_arcade.dart';
import 'future_dashboard.dart';
import 'future_studio.dart';
import 'game_center.dart';
import 'jitsi_backup_calls.dart';
import 'knowledge_corner.dart';
import 'match_center.dart';
import 'premium_media_hub.dart';
import 'v11_premium_hub.dart';
import 'v12_futuristic_hub.dart';
import 'v6_community_suite.dart';
import 'watch_party.dart';
import 'v17_smart_hub.dart';

const _v14Purple = Color(0xFF8D7CFF);
const _v14Navy = Color(0xFF11152D);

class V14CommandCenterPage extends StatefulWidget {
  const V14CommandCenterPage({super.key});

  @override
  State<V14CommandCenterPage> createState() => _V14CommandCenterPageState();
}

class _V14CommandCenterPageState extends State<V14CommandCenterPage> {
  final _search = TextEditingController();
  String _category = 'الكل';
  Set<String> _favorites = <String>{};
  List<String> _recent = <String>[];

  @override
  void initState() {
    super.initState();
    _loadPersonalization();
  }

  Future<void> _loadPersonalization() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _favorites = (prefs.getStringList('v15_favorite_tools') ?? <String>[]).toSet();
      _recent = prefs.getStringList('v15_recent_tools') ?? <String>[];
    });
  }

  Future<void> _toggleFavorite(String title) async {
    final next = Set<String>.from(_favorites);
    if (next.contains(title)) { next.remove(title); } else { next.add(title); }
    setState(() => _favorites = next);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('v15_favorite_tools', next.toList());
  }

  Future<void> _rememberAndOpen(_V14Tool tool) async {
    final next = <String>[tool.title, ..._recent.where((item) => item != tool.title)].take(8).toList();
    setState(() => _recent = next);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('v15_recent_tools', next);
    if (!mounted) return;
    await Navigator.push(context, MaterialPageRoute(builder: (_) => tool.page()));
  }

  static final List<_V14Tool> _tools = [
    _V14Tool('الجديد', 'مركز V17 الذكي', 'بحث شامل وست ألعاب جديدة وإعدادات الأداء والتخصيص', Icons.auto_awesome_rounded, () => const V17SmartHubPage()),
    _V14Tool('الدردشة', 'المحادثة العامة', 'الرسائل العامة والوسائط والردود والتفاعلات', Icons.forum_rounded, () => const EnhancedPublicChatPage()),
    _V14Tool('الدردشة', 'الرسائل الخاصة', 'محادثات الأصدقاء والصور والفيديو والصوت', Icons.mark_email_unread_rounded, () => const DirectMessagesPage()),
    _V14Tool('المشاهدة', 'غرف المشاهدة الجماعية', 'YouTube وروابط الفيديو والمزامنة والدردشة', Icons.groups_rounded, () => const WatchPartyLobbyPage()),
    _V14Tool('المشاهدة', 'سينما الملتقى', 'الأفلام والمسلسلات وغرف السينما والأنمي', Icons.movie_filter_rounded, () => const CinemaHubPage()),
    _V14Tool('المشاهدة', 'الاتصال الاحتياطي', 'افتح غرفة صوت وصورة عبر Jitsi عند الحاجة', Icons.video_call_rounded, () => const JitsiBackupCallsPage()),
    _V14Tool('الوسائط', 'مكتبة ومشغّل المستقبل', 'الموسيقى والوسائط ومشغّل الخلفية', Icons.library_music_rounded, () => const PremiumMediaHubPage()),
    _V14Tool('الرياضة', 'مركز الكرة المباشر', 'متابعة المباريات والمحتوى الرياضي', Icons.sports_soccer_rounded, () => const FootballLiveCenterPage()),
    _V14Tool('الرياضة', 'أخبار كرة القدم', 'الأخبار والانتقالات والدوريات', Icons.newspaper_rounded, () => const FootballNewsPage()),
    _V14Tool('الرياضة', 'مركز المباريات', 'المواعيد والنتائج والبطولات', Icons.scoreboard_rounded, () => const MatchCenterPage()),
    _V14Tool('الألعاب', 'مركز الألعاب', 'التحديات والأسئلة والألعاب المتنوعة', Icons.sports_esports_rounded, () => const GameCenterPage()),
    _V14Tool('الألعاب', 'مدينة الألعاب 2D', 'ألعاب الأركيد والتجارب التفاعلية', Icons.videogame_asset_rounded, () => const FutureArcadePage()),
    _V14Tool('الألعاب', 'ألعاب الأصدقاء', 'منافسات وجولات جماعية مع الأصدقاء', Icons.people_alt_rounded, () => const FriendsBattleArenaPage()),
    _V14Tool('الألعاب', 'ألعاب الأركيد', 'تحديات ومراحل وألعاب إضافية', Icons.gamepad_rounded, () => const ArcadeHubPage()),
    _V14Tool('المجتمع', 'بوابة V12 المستقبلية', 'المهام اليومية والاستوديو والميزات الجديدة', Icons.auto_awesome_rounded, () => const V12FuturisticHubPage()),
    _V14Tool('المجتمع', 'بوابة V11 المميزة', 'مركز العضويات والمجتمع المتقدم', Icons.workspace_premium_rounded, () => const V11PremiumHubPage()),
    _V14Tool('المجتمع', 'المجتمع الشامل', 'الأندية والمناقشات والمهام والخصوصية', Icons.hub_rounded, () => const V6CommunitySuitePage()),
    _V14Tool('المجتمع', 'توسعة المجتمع', 'مساحات وفعاليات ومجموعات المجتمع', Icons.diversity_3_rounded, () => const CommunityExpansionPage()),
    _V14Tool('المجتمع', 'مجتمع الاهتمامات', 'نقاشات ومجتمعات الأعضاء', Icons.forum_outlined, () => const CommunityPlusPage()),
    _V14Tool('المجتمع', 'الفعاليات', 'تقويم اللقاءات والأنشطة والمسابقات', Icons.event_available_rounded, () => const CommunityEventsPage()),
    _V14Tool('المجتمع', 'التصويتات', 'استطلاعات وقرارات المجتمع', Icons.poll_rounded, () => const CommunityPollsPage()),
    _V14Tool('المجتمع', 'النقاط ولوحة الصدارة', 'النشاط والنقاط والتنافس الأسبوعي', Icons.leaderboard_rounded, () => const EngagementHubPage()),
    _V14Tool('المجتمع', 'الإنجازات والأوسمة', 'إنجازاتك وشارات التقدم', Icons.military_tech_rounded, () => const AchievementHubPage()),
    _V14Tool('الإبداع والمعرفة', 'استوديو المستقبل', 'تصميم البطاقات والأفكار الإبداعية', Icons.palette_rounded, () => const FutureStudioPage()),
    _V14Tool('الإبداع والمعرفة', 'مكتبة العبارات والأدعية', 'اقتباسات وشعر وأذكار وعبارات', Icons.auto_stories_rounded, () => const CreativeLibraryPage()),
    _V14Tool('الإبداع والمعرفة', 'ركن المعرفة', 'اكتشافات ومعلومات وتحديات معرفية', Icons.lightbulb_rounded, () => const KnowledgeCornerPage()),
    _V14Tool('الإبداع والمعرفة', 'لوحة يومي', 'المهام والتنظيم الشخصي', Icons.today_rounded, () => const FutureDashboardPage()),
    _V14Tool('التواصل', 'مركز الإشعارات', 'تنبيهات المنشن والتفاعلات والأحداث الجديدة', Icons.notifications_active_rounded, () => const NotificationsPage()),
    _V14Tool('المجتمع', 'دليل الأعضاء', 'اكتشف مجتمعات وأعضاء الملتقى', Icons.people_alt_rounded, () => const CommunityDirectoryPage()),
    _V14Tool('المجتمع', 'مساحات المشاهدة', 'استكشف غرف ومجموعات المشاهدة', Icons.live_tv_rounded, () => const WatchPartiesPage()),
    _V14Tool('المجتمع', 'مجتمعات الاهتمام', 'انضم إلى نقاشات حسب اهتماماتك', Icons.diversity_2_rounded, () => const InterestCommunityPage(category: 'عام')),
    _V14Tool('الترفيه', 'عالم الأنمي', 'خلفيات الأنمي وقائمة المشاهدة والاختبارات', Icons.animation_rounded, () => const AnimeExperiencePage()),
    _V14Tool('الإبداع والمعرفة', 'عالمك اليومي', 'تحديات ومحتوى وأدوات يومية', Icons.today_rounded, () => const DailyWorldPage()),
    _V14Tool('الإبداع والمعرفة', 'إلهام يومي', 'اقتباسات وأفكار ومساحات كتابة', Icons.lightbulb_rounded, () => const InspirationHubPage()),
    _V14Tool('الإبداع والمعرفة', 'المساعد المحلي', 'مساعدة وأفكار داخل التطبيق دون خدمة مدفوعة', Icons.smart_toy_rounded, () => const LocalHelperBotPage()),
    _V14Tool('الحساب والأمان', 'المنشورات المحفوظة', 'ارجع إلى المنشورات التي احتفظت بها', Icons.bookmark_rounded, () => const SavedPostsPage()),
    _V14Tool('الحساب والأمان', 'الأمان والخصوصية', 'أدوات الحظر وإرشادات سلامة المجتمع', Icons.shield_rounded, () => const MemberSafetyPage()),
  ];

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final q = _search.text.trim().toLowerCase();
    final visible = _tools.where((tool) {
      final matchesCategory = _category == 'الكل' || (_category == 'المفضلة' ? _favorites.contains(tool.title) : tool.category == _category);
      final matchesSearch = q.isEmpty || ('${tool.title} ${tool.subtitle} ${tool.category}').toLowerCase().contains(q);
      return matchesCategory && matchesSearch;
    }).toList();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('مركز الملتقى V15'),
          actions: [
            IconButton(
              tooltip: 'مسح البحث',
              onPressed: () => setState(_search.clear),
              icon: const Icon(Icons.search_off_rounded),
            ),
          ],
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [_v14Navy, Color(0xFF211A45), Color(0xFF101B2A)],
            ),
          ),
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF5946B9), Color(0xFF252B59), Color(0xFF12606C)],
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                    ),
                    border: Border.all(color: Colors.white.withValues(alpha: .18)),
                    boxShadow: const [BoxShadow(color: Color(0x553D2E91), blurRadius: 24, offset: Offset(0, 9))],
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      const Icon(Icons.auto_awesome_rounded, color: Color(0xFFFFD778), size: 30),
                      const SizedBox(width: 9),
                      const Expanded(child: Text('كل عالم الملتقى بمكان واحد', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900))),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(color: Colors.white.withValues(alpha: .15), borderRadius: BorderRadius.circular(20)),
                        child: const Text('V15', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ]),
                    const SizedBox(height: 9),
                    const Text('اختصر الطريق إلى الدردشة والمشاهدة والألعاب والرياضة والإبداع. كل الاختصارات تفتح ميزات نسختك الحالية دون استبدالها أو حذفها.',
                      style: TextStyle(color: Colors.white70, height: 1.55)),
                    const SizedBox(height: 13),
                    Text('${_tools.length} خدمة • مفضلاتك وآخر أقسامك محفوظة على جهازك', style: const TextStyle(color: Color(0xFFE4DCFF), fontSize: 12, fontWeight: FontWeight.w700)),
                  ]),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: TextField(
                    controller: _search,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'ابحث عن ميزة: دردشة، أنمي، ألعاب، كرة...',
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: _search.text.isEmpty ? null : IconButton(onPressed: () { _search.clear(); setState(() {}); }, icon: const Icon(Icons.close_rounded)),
                      filled: true,
                      fillColor: const Color(0xFF242541),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 58,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
                    scrollDirection: Axis.horizontal,
                    children: [
                      'الكل', 'المفضلة', 'الدردشة', 'المشاهدة', 'الوسائط', 'الرياضة', 'الألعاب', 'المجتمع', 'الترفيه', 'الإبداع والمعرفة', 'الحساب والأمان',
                    ].map((category) => Padding(
                      padding: const EdgeInsetsDirectional.only(start: 7),
                      child: ChoiceChip(
                        label: Text(category),
                        selected: _category == category,
                        onSelected: (_) => setState(() => _category = category),
                        selectedColor: _v14Purple.withValues(alpha: .3),
                        side: BorderSide(color: _category == category ? _v14Purple : Colors.white24),
                        labelStyle: TextStyle(color: _category == category ? Colors.white : Colors.white70, fontWeight: FontWeight.w700),
                      ),
                    )).toList(),
                  ),
                ),
              ),
              if (_recent.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 8, 14, 2),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('آخر ما فتحته', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 8),
                      SizedBox(height: 42, child: ListView(scrollDirection: Axis.horizontal, children: _recent.map((title) {
                        final matches = _tools.where((tool) => tool.title == title).toList();
                        if (matches.isEmpty) return const SizedBox.shrink();
                        final tool = matches.first;
                        return Padding(
                          padding: const EdgeInsetsDirectional.only(end: 7),
                          child: ActionChip(
                            avatar: Icon(tool.icon, size: 17, color: const Color(0xFFB9AEFF)),
                            label: Text(tool.title),
                            onPressed: () => _rememberAndOpen(tool),
                          ),
                        );
                      }).toList())),
                    ]),
                  ),
                ),
              if (visible.isEmpty)
                const SliverFillRemaining(hasScrollBody: false, child: Center(child: Text('ما لقينا ميزة بهذا الاسم.', style: TextStyle(color: Colors.white70))))
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(14, 8, 14, 24),
                  sliver: SliverGrid(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final tool = visible[index];
                        return _V14ToolCard(tool: tool, isFavorite: _favorites.contains(tool.title), onToggleFavorite: () => _toggleFavorite(tool.title), onOpen: () => _rememberAndOpen(tool));
                      },
                      childCount: visible.length,
                    ),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: .98,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _V14Tool {
  final String category;
  final String title;
  final String subtitle;
  final IconData icon;
  final Widget Function() page;
  const _V14Tool(this.category, this.title, this.subtitle, this.icon, this.page);
}

class _V14ToolCard extends StatelessWidget {
  final _V14Tool tool;
  final bool isFavorite;
  final VoidCallback onToggleFavorite;
  final VoidCallback onOpen;
  const _V14ToolCard({required this.tool, required this.isFavorite, required this.onToggleFavorite, required this.onOpen});

  @override
  Widget build(BuildContext context) => Material(
    color: const Color(0xFF20223D),
    borderRadius: BorderRadius.circular(18),
    child: InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onOpen,
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _v14Purple.withValues(alpha: .24)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
            width: 42, height: 42,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(13),
              gradient: const LinearGradient(colors: [Color(0xFF6F5AD8), Color(0xFF247E8B)]),
            ),
            child: Icon(tool.icon, color: Colors.white, size: 23),
          ),
            const Spacer(),
            IconButton(visualDensity: VisualDensity.compact, tooltip: isFavorite ? 'إزالة من المفضلة' : 'إضافة للمفضلة', onPressed: onToggleFavorite, icon: Icon(isFavorite ? Icons.star_rounded : Icons.star_border_rounded, color: isFavorite ? const Color(0xFFFFD66B) : Colors.white54)),
          ]),
          const Spacer(),
          Text(tool.title, maxLines: 2, overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14)),
          const SizedBox(height: 5),
          Text(tool.subtitle, maxLines: 3, overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white70, fontSize: 11, height: 1.4)),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: Text(tool.category, style: const TextStyle(color: Color(0xFFB9AEFF), fontSize: 10, fontWeight: FontWeight.bold))),
            const Icon(Icons.arrow_forward_rounded, color: Color(0xFFB9AEFF), size: 17),
          ]),
        ]),
      ),
    ),
  );
}
