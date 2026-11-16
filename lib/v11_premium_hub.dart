import 'package:flutter/material.dart';
import 'advanced_features.dart';
import 'achievement_hub.dart';
import 'community_expansion.dart' hide CommunityEventsPage;
import 'community_events.dart';
import 'community_polls.dart';
import 'community_plus.dart';
import 'creative_library.dart';
import 'engagement_features.dart';
import 'extra_community_features.dart';
import 'football_live_center.dart';
import 'friends_battle_arena.dart';
import 'future_dashboard.dart';
import 'game_center.dart';
import 'knowledge_corner.dart';
import 'premium_media_hub.dart';
import 'v6_community_suite.dart';

const _v11Purple = Color(0xFF8B78FF);
const _v11Navy = Color(0xFF11152D);

class V11PremiumHubPage extends StatelessWidget {
  const V11PremiumHubPage({super.key});

  void _open(BuildContext context, Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.rtl,
    child: Scaffold(
      backgroundColor: const Color(0xFF101321),
      appBar: AppBar(
        title: const Text('ملتقى المستقبل الذكي'),
        backgroundColor: _v11Navy,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 28),
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(26),
              gradient: const LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: [Color(0xFF5143A8), Color(0xFF24234F), Color(0xFF172C45)],
              ),
              border: Border.all(color: Colors.white.withValues(alpha: .13)),
              boxShadow: [BoxShadow(color: _v11Purple.withValues(alpha: .16), blurRadius: 28, offset: const Offset(0, 12))],
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Icon(Icons.auto_awesome_rounded, color: Color(0xFFE5DFFF), size: 30),
                  SizedBox(width: 9),
                  Text('V11 • PREMIUM EXPERIENCE', style: TextStyle(color: Color(0xFFE5DFFF), fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1)),
                ]),
                SizedBox(height: 16),
                Text('كل اهتماماتك بمكان واحد', style: TextStyle(color: Colors.white, fontSize: 23, fontWeight: FontWeight.w900)),
                SizedBox(height: 7),
                Text('تواصل، اكتشف، العب، شاهد، واصنع لحظاتك مع مجتمعك.', style: TextStyle(color: Colors.white70, height: 1.6)),
              ],
            ),
          ),
          const SizedBox(height: 22),
          const _V11SectionTitle(title: 'تواصل ومجتمع', subtitle: 'ابقَ قريباً من أصدقائك ونشاط الملتقى'),
          _V11FeatureTile(icon: Icons.mark_email_unread_rounded, title: 'صندوق الرسائل الخاصة', subtitle: 'محادثاتك والرسائل الأخيرة', color: const Color(0xFF8B78FF), onTap: () => _open(context, const DirectMessagesPage())),
          _V11FeatureTile(icon: Icons.notifications_active_outlined, title: 'مركز الإشعارات', subtitle: 'التنبيهات والتفاعلات والدعوات', color: const Color(0xFF48C6D8), onTap: () => _open(context, const NotificationsPage())),
          _V11FeatureTile(icon: Icons.groups_rounded, title: 'المجتمع والأندية', subtitle: 'اهتمامات ونقاشات وغرف مجتمعية', color: const Color(0xFF63C99A), onTap: () => _open(context, const V6CommunitySuitePage())),
          _V11FeatureTile(icon: Icons.explore_rounded, title: 'اكتشف المجتمعات', subtitle: 'غرف المشاهدة والفعاليات ومجتمعات الاهتمام', color: const Color(0xFFFFB86B), onTap: () => _open(context, const CommunityExpansionPage())),
          const SizedBox(height: 18),
          const _V11SectionTitle(title: 'الترفيه والتحديات', subtitle: 'أوقات ممتعة ومنافسات بين الأصدقاء'),
          _V11FeatureTile(icon: Icons.movie_filter_rounded, title: 'مكتبة الترفيه والميديا', subtitle: 'المحتوى والمشغل والمكتبة', color: const Color(0xFFFF8DAB), onTap: () => _open(context, const PremiumMediaHubPage())),
          _V11FeatureTile(icon: Icons.sports_esports_rounded, title: 'مركز الألعاب', subtitle: 'ألعاب وتحديات متنوعة', color: const Color(0xFFB79AFF), onTap: () => _open(context, const GameCenterPage())),
          _V11FeatureTile(icon: Icons.people_alt_rounded, title: 'ساحة منافسات الأصدقاء', subtitle: 'تحديات ولعب جماعي', color: const Color(0xFF66D6C2), onTap: () => _open(context, const FriendsBattleArenaPage())),
          _V11FeatureTile(icon: Icons.live_tv_rounded, title: 'مركز كرة القدم', subtitle: 'المباريات والقنوات الرسمية', color: const Color(0xFF8BCB75), onTap: () => _open(context, const FootballLiveCenterPage())),
          const SizedBox(height: 18),
          const _V11SectionTitle(title: 'طوّر تجربتك', subtitle: 'أهدافك وإنجازاتك ومساحتك الإبداعية'),
          _V11FeatureTile(icon: Icons.emoji_events_rounded, title: 'الإنجازات ولوحة النشاط', subtitle: 'مستويات وشارات ونقاط المجتمع', color: const Color(0xFFFFCA72), onTap: () => _open(context, const AchievementHubPage())),
          _V11FeatureTile(icon: Icons.bolt_rounded, title: 'النشاط والتحديات اليومية', subtitle: 'تابع تقدمك ومشاركاتك', color: const Color(0xFF70C7FF), onTap: () => _open(context, const EngagementHubPage())),
          _V11FeatureTile(icon: Icons.dashboard_customize_rounded, title: 'لوحة يومي وأهدافي', subtitle: 'العادات والتركيز والملاحظات', color: const Color(0xFFB99BFF), onTap: () => _open(context, const FutureDashboardPage())),
          _V11FeatureTile(icon: Icons.auto_awesome_rounded, title: 'استوديو الإبداع والمكتبة', subtitle: 'عبارات وأفكار وتصميم', color: const Color(0xFFFFA77C), onTap: () => _open(context, const CreativeLibraryPage())),
          _V11FeatureTile(icon: Icons.shield_moon_rounded, title: 'الأمان والخصوصية', subtitle: 'إعدادات الحماية وإدارة الحظر', color: const Color(0xFF79C8B4), onTap: () => _open(context, const MemberSafetyPage())),
          const SizedBox(height: 18),
          const _V11SectionTitle(title: 'اكتشاف ومعرفة', subtitle: 'مساحات جديدة للتعلّم والاستكشاف'),
          _V11FeatureTile(icon: Icons.lightbulb_outline_rounded, title: 'ركن المعرفة', subtitle: 'محتوى واكتشاف يومي', color: const Color(0xFFFFD36D), onTap: () => _open(context, const KnowledgeCornerPage())),
          _V11FeatureTile(icon: Icons.event_available_rounded, title: 'فعاليات المجتمع', subtitle: 'الأنشطة والمواعيد القادمة', color: const Color(0xFF6FC7E8), onTap: () => _open(context, const CommunityEventsPage())),
          _V11FeatureTile(icon: Icons.poll_rounded, title: 'تصويتات المجتمع', subtitle: 'شارك رأيك وصوّت', color: const Color(0xFFB69AFF), onTap: () => _open(context, const CommunityPollsPage())),
          _V11FeatureTile(icon: Icons.forum_rounded, title: 'مجتمع الأوتاكو والنقاشات', subtitle: 'موضوعات واهتمامات الأعضاء', color: const Color(0xFFEA8BB4), onTap: () => _open(context, const CommunityPlusPage())),
          _V11FeatureTile(icon: Icons.tune_rounded, title: 'المزيد من الأدوات', subtitle: 'الغرف والملفات والمزايا الإضافية', color: const Color(0xFF80B8FF), onTap: () => _open(context, const ExtraCommunityFeaturesPage())),
          const SizedBox(height: 18),
          const Center(child: Text('ملتقى شباب المستقبل • V11', style: TextStyle(color: Colors.white38, fontSize: 11))),
        ],
      ),
    ),
  );
}

class _V11SectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;
  const _V11SectionTitle({required this.title, required this.subtitle});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 9),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w900)),
      const SizedBox(height: 3),
      Text(subtitle, style: const TextStyle(color: Colors.white54, fontSize: 11)),
    ]),
  );
}

class _V11FeatureTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
  const _V11FeatureTile({required this.icon, required this.title, required this.subtitle, required this.color, required this.onTap});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Material(
      color: const Color(0xFF1A1E31),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
          child: Row(children: [
            Container(width: 43, height: 43, decoration: BoxDecoration(color: color.withValues(alpha: .14), borderRadius: BorderRadius.circular(14)), child: Icon(icon, color: color)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13)),
              const SizedBox(height: 3),
              Text(subtitle, style: const TextStyle(color: Colors.white54, fontSize: 11)),
            ])),
            const Icon(Icons.chevron_left_rounded, color: Colors.white38),
          ]),
        ),
      ),
    ),
  );
}
