import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'achievement_hub.dart';
import 'advanced_features.dart';
import 'community_events.dart';
import 'community_pages.dart';
import 'community_polls.dart';
import 'community_plus.dart';
import 'engagement_features.dart';
import 'friends_fun_world.dart';
import 'future_style_store.dart';
import 'knowledge_corner.dart';
import 'v52_community_reels.dart';

class V54WorldCommunityPage extends StatelessWidget {
  const V54WorldCommunityPage({super.key});

  void _open(BuildContext context, Widget page) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    final items = <({String title, String subtitle, IconData icon, Widget page})>[
      (title: 'ريلز ومقاطع الملتقى', subtitle: 'المقاطع والتعليقات والمحفوظات', icon: Icons.video_library_rounded, page: const CommunityReelsPage()),
      (title: 'الفعاليات والمسابقات', subtitle: 'مواعيد وأنشطة المجتمع', icon: Icons.event_available_rounded, page: const CommunityEventsPage()),
      (title: 'الإنجازات ولوحة الصدارة', subtitle: 'النقاط والحضور والشارات', icon: Icons.workspace_premium_rounded, page: const AchievementHubPage()),
      (title: 'مجتمعات ونقاشات الأعضاء', subtitle: 'مساحات الاهتمامات والنقاش', icon: Icons.groups_rounded, page: const CommunityPlusPage()),
      (title: 'التصويتات والاستطلاعات', subtitle: 'شارك رأيك في قرارات المجتمع', icon: Icons.poll_rounded, page: const CommunityPollsPage()),
      (title: 'عالم الألعاب والأصدقاء', subtitle: 'ألعاب وتحديات جماعية', icon: Icons.sports_esports_rounded, page: const FriendsFunWorldPage()),
      (title: 'استوديو تخصيص الحساب', subtitle: 'الألقاب والإطارات والزخارف', icon: Icons.palette_rounded, page: const FutureStyleStorePage()),
      (title: 'مكتبة المعرفة', subtitle: 'محتوى واكتشافات وأفكار', icon: Icons.lightbulb_outline_rounded, page: const KnowledgeCornerPage()),
      (title: 'الأمان والخصوصية', subtitle: 'الحظر والإبلاغ وإرشادات الاستخدام', icon: Icons.shield_rounded, page: const MemberSafetyPage()),
      (title: 'مركز الإشعارات', subtitle: 'المنشن والتفاعلات والتنبيهات', icon: Icons.notifications_active_rounded, page: const V54NotificationsPage()),
    ];

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('عالم شباب المستقبل V54')),
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
                  colors: [Color(0xFF171936), Color(0xFF6554D9), Color(0xFF1596A6)],
                ),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 34),
                  SizedBox(height: 12),
                  Text('كل مجتمعك في مكان واحد', style: TextStyle(color: Colors.white, fontSize: 23, fontWeight: FontWeight.w900)),
                  SizedBox(height: 7),
                  Text('اكتشف المقاطع والفعاليات والألعاب والإنجازات والنقاشات، مع الاحتفاظ بالأقسام الأصلية للملتقى.', style: TextStyle(color: Colors.white70, height: 1.55)),
                ],
              ),
            ),
            const SizedBox(height: 14),
            const _V54QuickStats(),
            const SizedBox(height: 8),
            ...items.map((item) => Card(
              clipBehavior: Clip.antiAlias,
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 7),
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
            const SizedBox(height: 10),
            const Card(
              child: Padding(
                padding: EdgeInsets.all(14),
                child: Text('ملاحظة: هذه البوابة توحّد الوصول إلى الأنظمة الموجودة بالتطبيق ولا تنشئ نسخاً مكررة منها. بعض الوظائف تعتمد على اتصال Firebase وقواعد الصلاحيات الحالية.'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _V54QuickStats extends StatelessWidget {
  const _V54QuickStats();

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox.shrink();
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('publicProfiles').doc(user.uid).snapshots(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data() ?? const <String, dynamic>{};
        return Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            child: Row(
              children: [
                Expanded(child: _stat(Icons.stars_rounded, '${data['points'] ?? 0}', 'نقاطك')),
                Expanded(child: _stat(Icons.calendar_month_rounded, '${data['checkInCount'] ?? 0}', 'أيام الحضور')),
                Expanded(child: _stat(Icons.person_rounded, (data['name'] ?? 'عضو').toString(), 'حسابك')),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _stat(IconData icon, String value, String label) => Column(
    children: [
      Icon(icon, color: const Color(0xFF9C8CFF)),
      const SizedBox(height: 4),
      Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold)),
      Text(label, style: const TextStyle(fontSize: 11, color: Colors.white60)),
    ],
  );
}

class V54NotificationsPage extends StatelessWidget {
  const V54NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const Scaffold(body: Center(child: Text('سجّل الدخول لعرض إشعاراتك.')));
    }
    final query = FirebaseFirestore.instance.collection('notifications')
        .where('recipientId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .limit(60);
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('مركز الإشعارات')),
        body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: query.snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) return Center(child: Padding(
              padding: const EdgeInsets.all(20),
              child: SelectableText('تعذر تحميل الإشعارات.\nتفاصيل الخطأ: ${snapshot.error}'),
            ));
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
            final docs = snapshot.data!.docs;
            if (docs.isEmpty) return const Center(child: Text('ما عندك إشعارات حالياً.'));
            return ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: docs.length,
              separatorBuilder: (_, __) => const SizedBox(height: 6),
              itemBuilder: (context, index) {
                final doc = docs[index];
                final data = doc.data();
                final read = data['read'] == true;
                final type = (data['type'] ?? '').toString();
                final icon = switch (type) {
                  'like' => Icons.favorite_rounded,
                  'comment' => Icons.mode_comment_rounded,
                  'mention' => Icons.alternate_email_rounded,
                  'follow' => Icons.person_add_alt_1_rounded,
                  'message' => Icons.mail_rounded,
                  _ => Icons.notifications_rounded,
                };
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: read ? Colors.white10 : const Color(0xFF6554D9).withOpacity(.25),
                      child: Icon(icon, color: read ? Colors.white54 : const Color(0xFFB9AEFF)),
                    ),
                    title: Text((data['actorName'] ?? 'الملتقى').toString(), style: TextStyle(fontWeight: read ? FontWeight.normal : FontWeight.bold)),
                    subtitle: Text((data['text'] ?? 'إشعار جديد').toString()),
                    trailing: read ? const Icon(Icons.done, color: Colors.white38) : const Icon(Icons.circle, size: 9, color: Color(0xFF8D7BFF)),
                    onTap: read ? null : () async {
                      try {
                        await doc.reference.update({'read': true});
                      } catch (_) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تعذر تحديث حالة الإشعار.')));
                        }
                      }
                    },
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
