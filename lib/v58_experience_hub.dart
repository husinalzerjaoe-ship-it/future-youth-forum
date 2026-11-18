import 'package:flutter/material.dart';
import 'advanced_features.dart';
import 'community_events.dart';
import 'community_pages.dart';
import 'community_polls.dart';
import 'community_plus.dart';
import 'future_arcade.dart';
import 'future_culture_hub.dart';
import 'future_planner.dart';
import 'future_studio.dart';
import 'friends_battle_arena.dart';
import 'friends_fun_world.dart';
import 'game_center.dart';
import 'iptv_center.dart';
import 'knowledge_corner.dart';
import 'premium_media_hub.dart';
import 'v52_community_reels.dart';
import 'v53_community_hub.dart';
import 'v54_world_community.dart';
import 'v56_future_world.dart';

class V58ExperienceHubPage extends StatefulWidget {
  const V58ExperienceHubPage({super.key});
  @override
  State<V58ExperienceHubPage> createState() => _V58ExperienceHubPageState();
}

class _V58ExperienceHubPageState extends State<V58ExperienceHubPage> {
  static const _accent = Color(0xFF8B78FF);
  final _search = TextEditingController();
  String _category = 'الكل';

  late final List<_V58Feature> _features = [
    _V58Feature('ريلز الملتقى', 'مقاطع عمودية، إعجابات وتعليقات', Icons.smart_display_rounded, 'المجتمع', () => const CommunityReelsPage()),
    _V58Feature('مركز المجتمع', 'الأندية والإنجازات ومحتوى الأعضاء', Icons.groups_rounded, 'المجتمع', () => const V53CommunityHubPage()),
    _V58Feature('عالم المجتمع', 'الإشعارات والفعاليات والتفاعل', Icons.public_rounded, 'المجتمع', () => const V54WorldCommunityPage()),
    _V58Feature('الفعاليات', 'تابع فعاليات الملتقى ومواعيدها', Icons.event_rounded, 'المجتمع', () => const CommunityEventsPage()),
    _V58Feature('التصويت والاستطلاعات', 'شارك برأيك في استطلاعات الأعضاء', Icons.poll_rounded, 'المجتمع', () => const CommunityPollsPage()),
    _V58Feature('الدردشة الخاصة', 'افتح محادثاتك الخاصة', Icons.forum_rounded, 'التواصل', () => const DirectMessagesPage()),
    _V58Feature('مركز الألعاب', 'ألعاب وتحديات متنوعة', Icons.sports_esports_rounded, 'الألعاب', () => const GameCenterPage()),
    _V58Feature('عالم وناسة الأصدقاء', 'نشاطات وألعاب اجتماعية', Icons.celebration_rounded, 'الألعاب', () => const FriendsFunWorldPage()),
    _V58Feature('مدينة ألعاب 2D', 'افتح تجارب الألعاب الموجودة', Icons.videogame_asset_rounded, 'الألعاب', () => const FutureArcadePage()),
    _V58Feature('منافسات الأصدقاء', 'تحديات ولوحة منافسة', Icons.emoji_events_rounded, 'الألعاب', () => const FriendsBattleArenaPage()),
    _V58Feature('مركز IPTV', 'قوائم القنوات والمكتبة والمشغل', Icons.live_tv_rounded, 'الترفيه', () => const IptvCenterPage()),
    _V58Feature('مكتبة الوسائط', 'مركز الصوت والفيديو', Icons.video_library_rounded, 'الترفيه', () => const PremiumMediaHubPage()),
    _V58Feature('عالم المستقبل V56', 'دفتر الأحلام والذكريات والقصص', Icons.auto_awesome_rounded, 'الإبداع والمعرفة', () => const V56FutureWorldPage()),
    _V58Feature('استوديو الإبداع', 'مساحة الكتابة وصناعة المحتوى', Icons.brush_rounded, 'الإبداع والمعرفة', () => const FutureStudioPage()),
    _V58Feature('ركن المعرفة', 'اكتشاف ومعلومات ومحتوى معرفي', Icons.lightbulb_rounded, 'الإبداع والمعرفة', () => const KnowledgeCornerPage()),
    _V58Feature('مخطط المستقبل', 'نظم مهامك وأهدافك', Icons.event_note_rounded, 'الإبداع والمعرفة', () => const FuturePlannerPage()),
    _V58Feature('الأمان والخصوصية', 'إرشادات وأدوات سلامة الحساب', Icons.shield_rounded, 'الأمان', () => const MemberSafetyPage()),
    _V58Feature('المجتمع الشامل', 'مساحة إضافية للأقسام الاجتماعية', Icons.hub_rounded, 'المجتمع', () => const CommunityPlusPage()),
    _V58Feature('مكتبة الثقافة', 'الشعر والاقتباسات والثقافة', Icons.menu_book_rounded, 'الإبداع والمعرفة', () => const FutureCultureHubPage()),
  ];

  static const _categories = ['الكل', 'المجتمع', 'التواصل', 'الألعاب', 'الترفيه', 'الإبداع والمعرفة', 'الأمان'];

  @override
  void dispose() { _search.dispose(); super.dispose(); }

  void _open(_V58Feature feature) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => feature.page()));
  }

  @override
  Widget build(BuildContext context) {
    final query = _search.text.trim().toLowerCase();
    final visible = _features.where((feature) {
      final matchesCategory = _category == 'الكل' || feature.category == _category;
      final haystack = '${feature.title} ${feature.subtitle} ${feature.category}'.toLowerCase();
      return matchesCategory && (query.isEmpty || haystack.contains(query));
    }).toList();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('مركز تجربة الملتقى V58'),
          actions: [IconButton(tooltip: 'مسح البحث', onPressed: () { _search.clear(); setState(() {}); }, icon: const Icon(Icons.refresh_rounded))],
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 28),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: const LinearGradient(begin: Alignment.topRight, end: Alignment.bottomLeft, colors: [Color(0xFF30256A), Color(0xFF171936), Color(0xFF124B60)]),
              ),
              child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [Icon(Icons.auto_awesome_rounded, color: Color(0xFFE5DFFF), size: 30), SizedBox(width: 10), Expanded(child: Text('كل الملتقى بمكان واحد', style: TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.w900)))]),
                SizedBox(height: 10),
                Text('بوابة موحدة للوصول السريع إلى المجتمع والألعاب والترفيه والإبداع والأمان، مع إبقاء الأقسام الأصلية كما هي.', style: TextStyle(color: Colors.white70, height: 1.6)),
              ]),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _search,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(hintText: 'ابحث عن قسم أو ميزة...', prefixIcon: const Icon(Icons.search_rounded), suffixIcon: _search.text.isEmpty ? null : IconButton(onPressed: () { _search.clear(); setState(() {}); }, icon: const Icon(Icons.close_rounded)), filled: true, border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none)),
            ),
            const SizedBox(height: 12),
            SizedBox(height: 42, child: ListView(scrollDirection: Axis.horizontal, children: _categories.map((category) => Padding(
              padding: const EdgeInsetsDirectional.only(end: 8),
              child: ChoiceChip(label: Text(category), selected: _category == category, onSelected: (_) => setState(() => _category = category), selectedColor: _accent.withValues(alpha: .25)),
            )).toList())),
            const SizedBox(height: 12),
            Row(children: [const Icon(Icons.apps_rounded, color: _accent), const SizedBox(width: 8), Text('الأقسام والميزات (${visible.length})', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold))]),
            const SizedBox(height: 10),
            if (visible.isEmpty)
              const Card(child: Padding(padding: EdgeInsets.all(22), child: Center(child: Text('ما لقينا قسم بهذا الاسم. جرّب كلمة ثانية.'))))
            else
              LayoutBuilder(builder: (context, constraints) {
                final columns = constraints.maxWidth >= 700 ? 3 : 2;
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: visible.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: columns, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 1.12),
                  itemBuilder: (context, index) {
                    final feature = visible[index];
                    return Card(clipBehavior: Clip.antiAlias, child: InkWell(
                      onTap: () => _open(feature),
                      child: Padding(padding: const EdgeInsets.all(13), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Container(width: 42, height: 42, decoration: BoxDecoration(color: _accent.withValues(alpha: .16), borderRadius: BorderRadius.circular(13)), child: Icon(feature.icon, color: _accent)),
                        const Spacer(),
                        Text(feature.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 5),
                        Text(feature.subtitle, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, color: Theme.of(context).hintColor)),
                        const SizedBox(height: 5),
                        Row(children: [Text(feature.category, style: const TextStyle(fontSize: 10, color: _accent)), const Spacer(), const Icon(Icons.arrow_back_ios_new_rounded, size: 12)]),
                      ])),
                    ));
                  },
                );
              }),
            const SizedBox(height: 16),
            Card(child: ListTile(leading: const Icon(Icons.verified_user_outlined, color: _accent), title: const Text('ملاحظة حول الخصوصية'), subtitle: const Text('استخدم أدوات الإبلاغ والحظر، ولا تشارك كلمات المرور أو روابطاً تحتوي رموز دخول.'), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MemberSafetyPage())))),
          ],
        ),
      ),
    );
  }
}

class _V58Feature {
  const _V58Feature(this.title, this.subtitle, this.icon, this.category, this.page);
  final String title;
  final String subtitle;
  final IconData icon;
  final String category;
  final Widget Function() page;
}
