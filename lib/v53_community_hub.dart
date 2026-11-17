import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'achievement_hub.dart';
import 'community_events.dart';
import 'community_polls.dart';
import 'engagement_features.dart';
import 'future_style_store.dart';
import 'friends_fun_world.dart';
import 'knowledge_corner.dart';
import 'v52_community_reels.dart';

class V53CommunityHubPage extends StatelessWidget {
  const V53CommunityHubPage({super.key});

  void _open(BuildContext context, Widget page) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    final items = <({String title, String subtitle, IconData icon, Widget page})>[
      (title: 'المقاطع المحفوظة', subtitle: 'ارجع للمقاطع التي حفظتها', icon: Icons.bookmarks_rounded, page: const V53SavedClipsPage()),
      (title: 'ريلز الملتقى', subtitle: 'مقاطع دائمة وتعليقات صوتية وصور ومشاركة خاصة', icon: Icons.video_library_rounded, page: const CommunityReelsPage()),
      (title: 'الفعاليات والمسابقات', subtitle: 'تابع الفعاليات والمواعيد والأنشطة', icon: Icons.event_available_rounded, page: const CommunityEventsPage()),
      (title: 'التصويتات', subtitle: 'شارك رأيك باستطلاعات المجتمع', icon: Icons.poll_rounded, page: const CommunityPollsPage()),
      (title: 'الإنجازات والحضور', subtitle: 'نقاطك وسلسلة الحضور والشارات', icon: Icons.workspace_premium_rounded, page: const AchievementHubPage()),
      (title: 'لوحة الصدارة', subtitle: 'تابع النشاط والتحديات والنقاط', icon: Icons.leaderboard_rounded, page: const EngagementHubPage()),
      (title: 'عالم الأصدقاء', subtitle: 'ألعاب وتحديات جماعية', icon: Icons.sports_esports_rounded, page: const FriendsFunWorldPage()),
      (title: 'متجر الستايل', subtitle: 'الألقاب والإطارات والزخارف', icon: Icons.storefront_rounded, page: const FutureStyleStorePage()),
      (title: 'ركن المعرفة', subtitle: 'اكتشافات ومحتوى معرفي', icon: Icons.lightbulb_outline_rounded, page: const KnowledgeCornerPage()),
    ];
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('عالم ملتقى شباب المستقبل V53')),
        body: ListView(
          padding: const EdgeInsets.all(14),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                gradient: const LinearGradient(
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                  colors: [Color(0xFF25245B), Color(0xFF6554D9), Color(0xFF137C91)],
                ),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 34),
                  SizedBox(height: 12),
                  Text('كل مجتمعك بمكان واحد', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
                  SizedBox(height: 6),
                  Text('مقاطع، فعاليات، ألعاب، إنجازات، تصويتات واكتشافات — مع الحفاظ على أقسام الملتقى الأصلية.', style: TextStyle(color: Colors.white70, height: 1.5)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ...items.map((item) => Card(
              clipBehavior: Clip.antiAlias,
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                leading: CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                  child: Icon(item.icon, color: Theme.of(context).colorScheme.onPrimaryContainer),
                ),
                title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(item.subtitle),
                trailing: const Icon(Icons.chevron_left_rounded),
                onTap: () => _open(context, item.page),
              ),
            )),
            const SizedBox(height: 12),
            const Card(child: Padding(
              padding: EdgeInsets.all(14),
              child: Text('هذه البوابة تجمع الأنظمة الموجودة فعلاً في التطبيق؛ لا تنشئ نسخاً مكررة منها ولا تستبدل صفحاتها الأصلية.'),
            )),
          ],
        ),
      ),
    );
  }
}


class V53SavedClipsPage extends StatelessWidget {
  const V53SavedClipsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const Scaffold(body: Center(child: Text('سجّل الدخول لعرض محفوظاتك.')));
    }
    final stream = FirebaseFirestore.instance.collection('users').doc(uid)
        .collection('savedClips').orderBy('savedAt', descending: true).snapshots();
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('مقاطعك المحفوظة')),
        body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: stream,
          builder: (context, snapshot) {
            if (snapshot.hasError) return const Center(child: Text('تعذر تحميل المحفوظات حالياً.'));
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
            final docs = snapshot.data!.docs;
            if (docs.isEmpty) return const Center(child: Text('ما عندك مقاطع محفوظة بعد. اضغط علامة الحفظ على أي ريل.'));
            return ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: docs.length,
              itemBuilder: (context, index) {
                final data = docs[index].data();
                return Card(child: ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.play_arrow_rounded)),
                  title: Text((data['caption'] ?? 'مقطع من الملتقى').toString(), maxLines: 2, overflow: TextOverflow.ellipsis),
                  subtitle: Text('بواسطة ${(data['authorName'] ?? 'عضو').toString()}'),
                  trailing: IconButton(
                    tooltip: 'نسخ رابط المقطع',
                    icon: const Icon(Icons.copy_rounded),
                    onPressed: () async {
                      final url = (data['videoUrl'] ?? '').toString();
                      if (url.startsWith('https://')) {
                        await Clipboard.setData(ClipboardData(text: url));
                        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم نسخ رابط المقطع')));
                      }
                    },
                  ),
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CommunityReelsPage())),
                ));
              },
            );
          },
        ),
      ),
    );
  }
}
