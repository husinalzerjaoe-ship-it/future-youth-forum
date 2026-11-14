import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AchievementHubPage extends StatefulWidget {
  const AchievementHubPage({super.key});
  @override
  State<AchievementHubPage> createState() => _AchievementHubPageState();
}

class _AchievementHubPageState extends State<AchievementHubPage> {
  final db = FirebaseFirestore.instance;
  bool busy = false;
  String get uid => FirebaseAuth.instance.currentUser!.uid;
  String get today => DateTime.now().toUtc().toIso8601String().substring(0, 10);
  String get yesterday => DateTime.now().toUtc().subtract(const Duration(days: 1)).toIso8601String().substring(0, 10);

  Future<void> checkIn() async {
    if (busy) return;
    setState(() => busy = true);
    try {
      final ref = db.collection('users').doc(uid);
      await db.runTransaction((tx) async {
        final snapshot = await tx.get(ref);
        final data = snapshot.data() ?? <String, dynamic>{};
        if (data['dailyCheckinDate'] == today) throw StateError('checked');
        final previous = data['dailyCheckinDate']?.toString() ?? '';
        final oldStreak = (data['dailyStreak'] as num?)?.toInt() ?? 0;
        final streak = previous == yesterday ? oldStreak + 1 : 1;
        final xp = (data['communityXP'] as num?)?.toInt() ?? 0;
        tx.set(ref, {
          'dailyCheckinDate': today,
          'dailyStreak': streak,
          'communityXP': xp + 10,
          'lastCheckinAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      });
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تسجيل حضورك اليومي +10 نقاط')));
    } on StateError {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('سجلت حضورك اليوم. ارجع باچر حتى تحافظ على السلسلة!')));
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تعذر تسجيل الحضور.')));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.rtl,
    child: Scaffold(
      appBar: AppBar(title: const Text('إنجازاتي ومستوياتي')),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: db.collection('users').doc(uid).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final data = snapshot.data!.data() ?? <String, dynamic>{};
          final xp = (data['communityXP'] as num?)?.toInt() ?? 0;
          final streak = (data['dailyStreak'] as num?)?.toInt() ?? 0;
          final done = data['dailyCheckinDate'] == today;
          final level = xp >= 500 ? 'أسطورة' : xp >= 200 ? 'ذهبي' : xp >= 75 ? 'متقدم' : xp >= 20 ? 'نشط' : 'مبتدئ';
          final badges = <_BadgeInfo>[
            _BadgeInfo('أول حضور', 'سجل حضورك اليومي مرة واحدة', Icons.waving_hand, xp >= 10),
            _BadgeInfo('ثلاثة أيام', 'حافظ على سلسلة 3 أيام', Icons.local_fire_department, streak >= 3),
            _BadgeInfo('أسبوع متواصل', 'حافظ على سلسلة 7 أيام', Icons.calendar_month, streak >= 7),
            _BadgeInfo('عضو نشيط', 'اجمع 100 نقطة مجتمع', Icons.bolt, xp >= 100),
            _BadgeInfo('نجم الملتقى', 'اجمع 500 نقطة مجتمع', Icons.stars, xp >= 500),
          ];
          return ListView(padding: const EdgeInsets.all(14), children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(children: [
                  const CircleAvatar(radius: 34, child: Icon(Icons.workspace_premium, size: 36)),
                  const SizedBox(height: 10),
                  Text(level, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  Text(xp.toString() + ' نقطة مجتمع', style: TextStyle(color: Theme.of(context).colorScheme.primary)),
                  const SizedBox(height: 12),
                  LinearProgressIndicator(value: (xp % 100) / 100),
                  const SizedBox(height: 6),
                  Text('التقدم للمستوى التالي: ' + (100 - (xp % 100)).toString() + ' نقطة'),
                ]),
              ),
            ),
            Card(child: Padding(padding: const EdgeInsets.all(16), child: Row(children: [
              const Icon(Icons.local_fire_department, color: Colors.deepOrange, size: 32),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('سلسلة الحضور اليومي', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(streak.toString() + ' يوم متواصل'),
              ])),
              FilledButton(onPressed: done || busy ? null : checkIn, child: Text(done ? 'تم الحضور اليوم' : 'سجل حضوري +10')),
            ]))),
            const Padding(padding: EdgeInsets.fromLTRB(4, 16, 4, 8), child: Text('شاراتك', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
            ...badges.map((badge) => Card(child: ListTile(
              leading: CircleAvatar(
                backgroundColor: badge.unlocked ? Colors.amber.withValues(alpha: .2) : Colors.grey.withValues(alpha: .12),
                child: Icon(badge.icon, color: badge.unlocked ? Colors.amber.shade800 : Colors.grey),
              ),
              title: Text(badge.title),
              subtitle: Text(badge.description),
              trailing: Icon(badge.unlocked ? Icons.check_circle : Icons.lock_outline, color: badge.unlocked ? Colors.green : Colors.grey),
            ))),
            const Card(child: Padding(padding: EdgeInsets.all(12), child: Text('النقاط هنا للحضور اليومي فقط. نقاط الألعاب الحالية تبقى ضمن مدينة الترفيه، وسيتم ربط لوحات المتصدرين بعد تجهيز صلاحيات عامة آمنة لها.'))),
          ]);
        },
      ),
    ),
  );
}

class _BadgeInfo {
  const _BadgeInfo(this.title, this.description, this.icon, this.unlocked);
  final String title, description;
  final IconData icon;
  final bool unlocked;
}
