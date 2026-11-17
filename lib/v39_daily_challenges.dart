import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Local-only progress tracker: it does not grant server coins or modify profiles.
class V39ChallengeLogic {
  static DateTime day(DateTime value) => DateTime(value.year, value.month, value.day);

  static int nextStreak({
    required DateTime? previous,
    required DateTime today,
    required int currentStreak,
  }) {
    if (previous == null) return 1;
    final p = day(previous);
    final t = day(today);
    if (p == t) return currentStreak;
    if (p.add(const Duration(days: 1)) == t) return currentStreak + 1;
    return 1;
  }

  static int challengeIndex(DateTime date, int count) {
    if (count <= 0) return 0;
    final days = day(date).difference(DateTime(2025, 1, 1)).inDays;
    return days.abs() % count;
  }
}

class V39DailyChallengesPage extends StatefulWidget {
  const V39DailyChallengesPage({super.key});

  @override
  State<V39DailyChallengesPage> createState() => _V39DailyChallengesPageState();
}

class _V39DailyChallengesPageState extends State<V39DailyChallengesPage> {
  static const _tasks = <({String title, String detail, IconData icon})>[
    (title: 'مستكشف المعرفة', detail: 'تعلّم معلومة جديدة وشاركها مع صديق.', icon: Icons.lightbulb_outline),
    (title: 'صانع البهجة', detail: 'اكتب تعليقاً مشجعاً على منشور أحد الأعضاء.', icon: Icons.favorite_outline),
    (title: 'تحدي القراءة', detail: 'اقرأ عشر صفحات أو مقالاً مفيداً.', icon: Icons.menu_book_rounded),
    (title: 'روح الفريق', detail: 'شارك في تصويت أو فعالية داخل الملتقى.', icon: Icons.groups_2_outlined),
    (title: 'مبدع اليوم', detail: 'اكتب فكرة أو خاطرة قصيرة من تأليفك.', icon: Icons.brush_outlined),
    (title: 'صديق وفي', detail: 'تواصل مع صديق برسالة لطيفة.', icon: Icons.waving_hand_outlined),
    (title: 'عقل متفتح', detail: 'حل لغزاً أو سؤالاً ثقافياً.', icon: Icons.psychology_alt_outlined),
    (title: 'استراحة ذكية', detail: 'خذ استراحة قصيرة بعيداً عن الشاشة.', icon: Icons.spa_outlined),
    (title: 'مشارك نشيط', detail: 'شارك في نشاط مجتمعي مفيد.', icon: Icons.forum_outlined),
    (title: 'ذاكرة قوية', detail: 'جرّب لعبة ذاكرة في مركز الألعاب.', icon: Icons.extension_outlined),
    (title: 'عين على الإبداع', detail: 'اكتشف قسماً جديداً في الملتقى.', icon: Icons.explore_outlined),
    (title: 'امتنان اليوم', detail: 'اكتب شيئاً واحداً أنت ممتن له.', icon: Icons.volunteer_activism_outlined),
    (title: 'تحدي التنظيم', detail: 'رتّب مهمة صغيرة وأنجزها.', icon: Icons.checklist_rounded),
    (title: 'معلومة رياضية', detail: 'تابع نتيجة أو معلومة في مركز المباريات.', icon: Icons.sports_soccer_outlined),
  ];

  bool _loading = true;
  bool _completedToday = false;
  int _streak = 0;
  int _total = 0;
  int _xp = 0;
  DateTime? _lastCompleted;

  DateTime get _today => V39ChallengeLogic.day(DateTime.now());
  String get _todayKey => '${_today.year}-${_today.month}-${_today.day}';
  ({String title, String detail, IconData icon}) get _challenge =>
      _tasks[V39ChallengeLogic.challengeIndex(_today, _tasks.length)];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final last = DateTime.tryParse(prefs.getString('v39_challenge_last') ?? '');
    if (!mounted) return;
    setState(() {
      _lastCompleted = last;
      _completedToday = last != null && V39ChallengeLogic.day(last) == _today;
      _streak = prefs.getInt('v39_challenge_streak') ?? 0;
      _total = prefs.getInt('v39_challenge_total') ?? 0;
      _xp = prefs.getInt('v39_challenge_xp') ?? 0;
      _loading = false;
    });
  }

  Future<void> _complete() async {
    if (_completedToday) return;
    final next = V39ChallengeLogic.nextStreak(
      previous: _lastCompleted,
      today: _today,
      currentStreak: _streak,
    );
    final bonus = next % 3 == 0 ? 10 : 0;
    final gained = 15 + bonus;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('v39_challenge_last', _today.toIso8601String());
    await prefs.setInt('v39_challenge_streak', next);
    await prefs.setInt('v39_challenge_total', _total + 1);
    await prefs.setInt('v39_challenge_xp', _xp + gained);
    if (!mounted) return;
    setState(() {
      _lastCompleted = _today;
      _completedToday = true;
      _streak = next;
      _total += 1;
      _xp += gained;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('أحسنت! حصلت على $gained XP ${bonus > 0 ? 'مع مكافأة الاستمرار' : ''}')),
    );
  }

  int get _level => (_xp ~/ 100) + 1;
  int get _levelProgress => _xp % 100;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    if (_loading) return const Center(child: CircularProgressIndicator());
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('تحديات وإنجازات V39')),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [cs.primary, cs.tertiary]),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('كل يوم إنجاز جديد ✨', style: TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.w900)),
                const SizedBox(height: 8),
                Text('المستوى $_level  •  $_xp XP', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: LinearProgressIndicator(value: _levelProgress / 100, minHeight: 9, backgroundColor: Colors.white24, color: Colors.white),
                ),
                const SizedBox(height: 5),
                Text('$_levelProgress / 100 XP للمستوى التالي', style: const TextStyle(color: Colors.white70, fontSize: 12)),
              ]),
            ),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _stat('🔥', '$_streak', 'أيام متتالية')),
              const SizedBox(width: 8),
              Expanded(child: _stat('🏅', '$_total', 'إنجاز مكتمل')),
              const SizedBox(width: 8),
              Expanded(child: _stat('⭐', '$_xp', 'نقاط الخبرة')),
            ]),
            const SizedBox(height: 16),
            Card(child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Icon(_challenge.icon, color: cs.primary, size: 28),
                  const SizedBox(width: 9),
                  const Expanded(child: Text('مهمة اليوم', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900))),
                  Chip(label: Text(_completedToday ? 'مكتملة' : '+15 XP')),
                ]),
                const SizedBox(height: 10),
                Text(_challenge.title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                const SizedBox(height: 5),
                Text(_challenge.detail),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _completedToday ? null : _complete,
                    icon: Icon(_completedToday ? Icons.check_circle : Icons.task_alt),
                    label: Text(_completedToday ? 'أنجزت مهمة اليوم' : 'إكمال المهمة واستلام XP'),
                  ),
                ),
                if (_streak > 0) Text('كل 3 أيام متتالية تمنحك 10 XP إضافية.', style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12)),
              ]),
            )),
            const SizedBox(height: 10),
            const Text('إنجازاتك', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            _achievement('البداية الجميلة', 'أكمل أول مهمة يومية.', _total >= 1),
            _achievement('ثلاثة أيام من الالتزام', 'حافظ على سلسلة 3 أيام.', _streak >= 3),
            _achievement('أسبوع من الإنجاز', 'حافظ على سلسلة 7 أيام.', _streak >= 7),
            _achievement('صاحب العشر مهام', 'أكمل 10 مهام يومية.', _total >= 10),
            _achievement('مستكشف الملتقى', 'وصل إلى المستوى 5.', _level >= 5),
            const SizedBox(height: 10),
            Text('ملاحظة: هذا سجل محلي على هذا الجهاز، ولا يضيف عملات للمحفظة أو نقاطاً عامة إلى حسابك.', style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _stat(String emoji, String value, String label) => Card(
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 5),
      child: Column(children: [
        Text(emoji, style: const TextStyle(fontSize: 22)),
        const SizedBox(height: 3),
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
        Text(label, style: const TextStyle(fontSize: 10), textAlign: TextAlign.center),
      ]),
    ),
  );

  Widget _achievement(String title, String detail, bool unlocked) => Card(
    child: ListTile(
      leading: Icon(unlocked ? Icons.workspace_premium : Icons.lock_outline, color: unlocked ? Colors.amber : Colors.grey),
      title: Text(title),
      subtitle: Text(detail),
      trailing: Icon(unlocked ? Icons.check_circle : Icons.circle_outlined, color: unlocked ? Colors.green : Colors.grey),
    ),
  );
}
