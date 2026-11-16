import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _dashViolet = Color(0xFF7665E8);
const _dashCyan = Color(0xFF42C8D5);

class FutureDashboardPage extends StatefulWidget {
  const FutureDashboardPage({super.key});
  @override
  State<FutureDashboardPage> createState() => _FutureDashboardPageState();
}

class _FutureDashboardPageState extends State<FutureDashboardPage> {
  static const _habits = <String>[
    'اقرأ أو تعلّم شيئاً جديداً',
    'تحرّك واشرب ماء كافي',
    'تواصل مع شخص تحبه',
    'أنجز أهم مهمة عندك',
  ];
  static const _quotes = <String>[
    'كل خطوة صغيرة اليوم تصنع فرقاً كبيراً غداً.',
    'لا تنتظر الوقت المثالي؛ ابدأ بما تملك الآن.',
    'الاستمرار الهادئ أقوى من الحماس المؤقت.',
    'اصنع شيئاً يجعلك فخوراً بنفسك اليوم.',
    'تقدّمك مو لازم يكون سريع، المهم ما توقف.',
    'أفكارك تستحق فرصة؛ حوّل واحدة منها إلى فعل.',
  ];
  final _goal = TextEditingController();
  final _note = TextEditingController();
  final Map<String, bool> _done = {};
  bool _loading = true;
  bool _running = false;
  int _streak = 1;
  int _seconds = 1500;
  Timer? _timer;

  String get _dayKey {
    final n = DateTime.now();
    return n.year.toString() + '-' + n.month.toString().padLeft(2, '0') + '-' + n.day.toString().padLeft(2, '0');
  }
  String get _dateLabel {
    const days = ['الاثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت', 'الأحد'];
    const months = ['يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو', 'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'];
    final n = DateTime.now();
    return days[n.weekday - 1] + '، ' + n.day.toString() + ' ' + months[n.month - 1];
  }
  int get _completed => _habits.where((h) => _done[h] == true).length;
  String get _quote => _quotes[DateTime.now().difference(DateTime(DateTime.now().year)).inDays % _quotes.length];

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    final previous = p.getString('fy_dashboard_last_day');
    final today = _dayKey;
    var streak = p.getInt('fy_dashboard_streak') ?? 0;
    if (previous != today) {
      if (previous == null) {
        streak = 1;
      } else {
        final old = DateTime.tryParse(previous);
        final now = DateTime.now();
        final yesterday = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 1));
        streak = old != null && old.year == yesterday.year && old.month == yesterday.month && old.day == yesterday.day ? streak + 1 : 1;
      }
      await p.setString('fy_dashboard_last_day', today);
      await p.setInt('fy_dashboard_streak', streak);
    }
    _streak = streak < 1 ? 1 : streak;
    if (p.getString('fy_dashboard_task_day') == today) {
      for (final h in _habits) { _done[h] = p.getBool('fy_dashboard_habit_' + h) ?? false; }
      _goal.text = p.getString('fy_dashboard_goal') ?? '';
      _note.text = p.getString('fy_dashboard_note') ?? '';
    } else {
      for (final h in _habits) { _done[h] = false; }
      _goal.clear(); _note.clear();
      await p.setString('fy_dashboard_task_day', today);
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    final p = await SharedPreferences.getInstance();
    await p.setString('fy_dashboard_task_day', _dayKey);
    await p.setString('fy_dashboard_goal', _goal.text.trim());
    await p.setString('fy_dashboard_note', _note.text.trim());
    for (final h in _habits) { await p.setBool('fy_dashboard_habit_' + h, _done[h] == true); }
  }

  void _toggleTimer() {
    if (_running) {
      _timer?.cancel();
      setState(() => _running = false);
      return;
    }
    if (_seconds <= 0) _seconds = 1500;
    setState(() => _running = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) { timer.cancel(); return; }
      if (_seconds <= 1) {
        timer.cancel();
        setState(() { _seconds = 0; _running = false; });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('أحسنت! انتهت جلسة التركيز 🌟')));
      } else { setState(() => _seconds--); }
    });
  }
  void _resetTimer() {
    _timer?.cancel();
    setState(() { _seconds = 1500; _running = false; });
  }

  @override
  void dispose() { _timer?.cancel(); _goal.dispose(); _note.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final progress = _completed / _habits.length;
    final time = (_seconds ~/ 60).toString().padLeft(2, '0') + ':' + (_seconds % 60).toString().padLeft(2, '0');
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFF101322),
        appBar: AppBar(
          title: const Text('بوابة المستقبل'),
          backgroundColor: const Color(0xFF15182F),
          foregroundColor: Colors.white,
          actions: [IconButton(
            tooltip: 'حفظ يومي',
            onPressed: _loading ? null : () async {
              await _save();
              if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('انحفظ يومك على هذا الجهاز 💜')));
            },
            icon: const Icon(Icons.bookmark_added_outlined),
          )],
        ),
        body: _loading ? const Center(child: CircularProgressIndicator()) : ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(26),
                gradient: const LinearGradient(begin: Alignment.topRight, end: Alignment.bottomLeft,
                  colors: [Color(0xFF39316F), Color(0xFF1B5570), Color(0xFF171A35)]),
                boxShadow: [BoxShadow(color: _dashViolet.withValues(alpha: .18), blurRadius: 24, offset: const Offset(0, 10))],
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(_dateLabel, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 8),
                const Text('مساحة يومك تبدأ من هنا ✨', style: TextStyle(color: Colors.white, fontSize: 23, fontWeight: FontWeight.w900)),
                const SizedBox(height: 8),
                const Text('رتّب أفكارك، أنجز أهدافك، وخذ وقتاً لنفسك.', style: TextStyle(color: Colors.white70, height: 1.5)),
                const SizedBox(height: 18),
                Row(children: [
                  _stat('🔥', _streak.toString(), 'أيام متواصلة'),
                  const SizedBox(width: 10),
                  _stat('✅', _completed.toString() + '/4', 'إنجازات اليوم'),
                ]),
              ]),
            ),
            const SizedBox(height: 16),
            _heading('هدفك الرئيسي', Icons.flag_rounded),
            _panel(TextField(controller: _goal, maxLength: 100, onChanged: (_) => _save(),
              decoration: const InputDecoration(hintText: 'شنو أهم شي تريد تنجزه اليوم؟', counterText: '', border: InputBorder.none,
                prefixIcon: Icon(Icons.bolt_rounded, color: _dashCyan)))),
            const SizedBox(height: 16),
            _heading('تحدياتك اليومية', Icons.check_circle_outline_rounded),
            _panel(Column(children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text('تقدّمك اليوم', style: TextStyle(color: Colors.white70)),
                Text((progress * 100).round().toString() + '%', style: const TextStyle(color: _dashCyan, fontWeight: FontWeight.bold)),
              ]),
              const SizedBox(height: 9),
              ClipRRect(borderRadius: BorderRadius.circular(20),
                child: LinearProgressIndicator(value: progress, minHeight: 8, backgroundColor: Colors.white10, color: _dashCyan)),
              const SizedBox(height: 8),
              for (final h in _habits)
                CheckboxListTile(
                  value: _done[h] ?? false,
                  onChanged: (v) { setState(() => _done[h] = v ?? false); _save(); },
                  dense: true, contentPadding: EdgeInsets.zero, activeColor: _dashViolet,
                  title: Text(h, style: const TextStyle(color: Colors.white, fontSize: 14)),
                  controlAffinity: ListTileControlAffinity.leading,
                ),
            ])),
            const SizedBox(height: 16),
            _heading('جلسة تركيز 25 دقيقة', Icons.hourglass_bottom_rounded),
            _panel(Column(children: [
              Text(time, style: const TextStyle(color: Colors.white, fontSize: 42, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              const Text('ابتعد عن المشتتات وركز على مهمة واحدة', style: TextStyle(color: Colors.white60, fontSize: 12)),
              const SizedBox(height: 14),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                FilledButton.icon(
                  style: FilledButton.styleFrom(backgroundColor: _dashViolet),
                  onPressed: _toggleTimer,
                  icon: Icon(_running ? Icons.pause_rounded : Icons.play_arrow_rounded),
                  label: Text(_running ? 'إيقاف مؤقت' : 'ابدأ التركيز'),
                ),
                const SizedBox(width: 9),
                IconButton.filledTonal(onPressed: _resetTimer, icon: const Icon(Icons.refresh_rounded), tooltip: 'إعادة'),
              ]),
            ])),
            const SizedBox(height: 16),
            _heading('دفتر أفكارك', Icons.edit_note_rounded),
            _panel(TextField(controller: _note, minLines: 3, maxLines: 6, maxLength: 1000, onChanged: (_) => _save(),
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(hintText: 'اكتب فكرة، ملاحظة، أو شيء تريد تتذكره...',
                hintStyle: TextStyle(color: Colors.white38), border: InputBorder.none))),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(22), color: const Color(0xFF292448),
                border: Border.all(color: _dashViolet.withValues(alpha: .45))),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Icon(Icons.auto_awesome_rounded, color: Color(0xFFFFD27A), size: 26),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('رسالة اليوم إلك', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  const SizedBox(height: 5),
                  Text(_quote, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, height: 1.5)),
                ])),
              ]),
            ),
            const SizedBox(height: 12),
            const Text('أهدافك وملاحظاتك محفوظة محلياً على جهازك، وليست منشورة للأعضاء.',
              textAlign: TextAlign.center, style: TextStyle(color: Colors.white38, fontSize: 11)),
          ],
        ),
      ),
    );
  }

  Widget _heading(String title, IconData icon) => Padding(
    padding: const EdgeInsets.only(bottom: 9),
    child: Row(children: [Icon(icon, color: _dashCyan, size: 20), const SizedBox(width: 8),
      Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16))]),
  );
  Widget _panel(Widget child) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(color: const Color(0xFF1A1E32), borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Colors.white.withValues(alpha: .07))),
    child: child,
  );
  Widget _stat(String emoji, String value, String label) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: .10), borderRadius: BorderRadius.circular(16)),
      child: Row(children: [
        Text(emoji, style: const TextStyle(fontSize: 21)), const SizedBox(width: 8),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10)),
        ])),
      ]),
    ),
  );
}
