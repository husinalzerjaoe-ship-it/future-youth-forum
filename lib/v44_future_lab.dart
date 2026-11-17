import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _v44Brand = Color(0xFF7665E8);

class V44ChallengeLogic {
  static int challengeIndex(DateTime day, int count) {
    if (count <= 0) return 0;
    final seed = day.year * 10000 + day.month * 100 + day.day;
    return seed % count;
  }

  static int nextStreak({
    required DateTime? previous,
    required DateTime today,
    required int currentStreak,
  }) {
    if (previous == null) return 1;
    final prior = DateTime(previous.year, previous.month, previous.day);
    final current = DateTime(today.year, today.month, today.day);
    final difference = current.difference(prior).inDays;
    if (difference == 0) return currentStreak < 1 ? 1 : currentStreak;
    if (difference == 1) return currentStreak + 1;
    return 1;
  }
}

class V44FutureLabPage extends StatefulWidget {
  const V44FutureLabPage({super.key, required this.onOpen});
  final ValueChanged<String> onOpen;

  @override
  State<V44FutureLabPage> createState() => _V44FutureLabPageState();
}

class _V44FutureLabPageState extends State<V44FutureLabPage> {
  static const _challenges = <String>[
    'اكتب تعليقاً إيجابياً يشجّع أحد أعضاء الملتقى.',
    'اكتشف لعبة جديدة وتحدَّ أحد أصدقائك.',
    'اقرأ معلومة جديدة وشاركها مع الآخرين.',
    'اكتب فكرة إبداعية في دفتر أفكارك.',
    'شارك في نقاش باحترام واستمع لوجهة نظر مختلفة.',
    'رتّب هدفاً صغيراً تريد إنجازه اليوم.',
    'اكتشف قصيدة أو اقتباساً جديداً من المكتبة.',
  ];

  static const _quickTasks = <String>[
    'أتعلم شيئاً جديداً',
    'أشارك بتفاعل مفيد',
    'أخصص وقتاً لهواية أحبها',
  ];

  final _ideaController = TextEditingController();
  final List<String> _ideas = [];
  Map<String, bool> _tasks = {};
  bool _loading = true;
  bool _challengeDone = false;
  int _points = 0;
  int _streak = 0;
  int _focusMinutes = 25;
  int _secondsLeft = 25 * 60;
  bool _timerRunning = false;
  Timer? _timer;

  DateTime get _today {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  String get _dayKey =>
      '${_today.year}-${_today.month.toString().padLeft(2, '0')}-${_today.day.toString().padLeft(2, '0')}';

  String get _challenge => _challenges[
      V44ChallengeLogic.challengeIndex(_today, _challenges.length)];

  int get _doneTasks => _quickTasks.where((task) => _tasks[task] == true).length;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _ideaController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final savedDay = prefs.getString('v44_challenge_done_day');
    _challengeDone = savedDay == _dayKey;
    _points = prefs.getInt('v44_local_points') ?? 0;
    _streak = prefs.getInt('v44_local_streak') ?? 0;
    final rawTasks = prefs.getString('v44_tasks_$_dayKey');
    if (rawTasks != null) {
      try {
        final decoded = jsonDecode(rawTasks);
        if (decoded is Map<String, dynamic>) {
          _tasks = decoded.map((key, value) => MapEntry(key, value == true));
        }
      } catch (_) {
        _tasks = {};
      }
    }
    for (final task in _quickTasks) {
      _tasks.putIfAbsent(task, () => false);
    }
    _ideas.addAll(prefs.getStringList('v44_ideas') ?? const []);
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _saveTasks() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('v44_tasks_$_dayKey', jsonEncode(_tasks));
  }

  Future<void> _completeChallenge() async {
    if (_challengeDone) return;
    final prefs = await SharedPreferences.getInstance();
    final previousRaw = prefs.getString('v44_previous_challenge_day');
    final previous = previousRaw == null ? null : DateTime.tryParse(previousRaw);
    _streak = V44ChallengeLogic.nextStreak(
      previous: previous,
      today: _today,
      currentStreak: _streak,
    );
    _challengeDone = true;
    _points += 25;
    await prefs.setString('v44_challenge_done_day', _dayKey);
    await prefs.setString('v44_previous_challenge_day', _dayKey);
    await prefs.setInt('v44_local_points', _points);
    await prefs.setInt('v44_local_streak', _streak);
    if (mounted) setState(() {});
  }

  Future<void> _saveIdea() async {
    final value = _ideaController.text.trim();
    if (value.isEmpty) return;
    setState(() {
      _ideas.insert(0, value);
      if (_ideas.length > 60) _ideas.removeLast();
      _ideaController.clear();
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('v44_ideas', _ideas);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('انحفظت فكرتك على هذا الجهاز.')),
      );
    }
  }

  void _startTimer() {
    if (_timerRunning) {
      _timer?.cancel();
      setState(() => _timerRunning = false);
      return;
    }
    if (_secondsLeft <= 0) _secondsLeft = _focusMinutes * 60;
    setState(() => _timerRunning = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_secondsLeft <= 1) {
        timer.cancel();
        setState(() {
          _secondsLeft = 0;
          _timerRunning = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('أحسنت! انتهت جلسة التركيز.')),
        );
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  void _resetTimer([int? minutes]) {
    _timer?.cancel();
    setState(() {
      if (minutes != null) _focusMinutes = minutes;
      _secondsLeft = _focusMinutes * 60;
      _timerRunning = false;
    });
  }

  String get _timerLabel {
    final minutes = (_secondsLeft ~/ 60).toString().padLeft(2, '0');
    final seconds = (_secondsLeft % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('مختبر المستقبل V44'),
          actions: [
            IconButton(
              tooltip: 'تحديث',
              onPressed: _loading ? null : () => setState(() {}),
              icon: const Icon(Icons.refresh_rounded),
            ),
          ],
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 28),
                children: [
                  _heroCard(),
                  const SizedBox(height: 14),
                  _sectionTitle('مهمة اليوم', Icons.flag_rounded),
                  _challengeCard(),
                  const SizedBox(height: 14),
                  _sectionTitle('خطواتك الصغيرة', Icons.checklist_rounded),
                  _tasksCard(),
                  const SizedBox(height: 14),
                  _sectionTitle('جلسة التركيز', Icons.timer_rounded),
                  _focusCard(),
                  const SizedBox(height: 14),
                  _sectionTitle('دفتر الأفكار', Icons.lightbulb_outline_rounded),
                  _ideasCard(),
                  const SizedBox(height: 14),
                  _sectionTitle('مراكز الملتقى', Icons.explore_rounded),
                  _shortcutsCard(),
                ],
              ),
      ),
    );
  }

  Widget _heroCard() => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: const LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [Color(0xFF5142A8), Color(0xFF202A54), Color(0xFF172C3D)],
          ),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('مساحة جديدة لأفكارك وإنجازاتك',
              style: TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          const Text('أدوات خفيفة تعمل محلياً، وتبقى بياناتها على جهازك.',
              style: TextStyle(color: Colors.white70, height: 1.5)),
          const SizedBox(height: 16),
          Wrap(spacing: 8, runSpacing: 8, children: [
            _statChip(Icons.stars_rounded, '$_points نقطة محلية'),
            _statChip(Icons.local_fire_department_rounded, '$_streak يوم متواصل'),
            _statChip(Icons.task_alt_rounded, '$_doneTasks/3 مهام'),
          ]),
        ]),
      );

  Widget _statChip(IconData icon, String label) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .12),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Colors.white24),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 16, color: const Color(0xFFE1D9FF)),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
        ]),
      );

  Widget _sectionTitle(String title, IconData icon) => Padding(
        padding: const EdgeInsets.fromLTRB(3, 2, 3, 9),
        child: Row(children: [
          Icon(icon, color: _v44Brand),
          const SizedBox(width: 8),
          Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
        ]),
      );

  Widget _challengeCard() => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('تحدي بسيط يصنع فرقاً', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(_challenge, style: const TextStyle(fontSize: 15, height: 1.5)),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _challengeDone ? null : _completeChallenge,
                icon: Icon(_challengeDone ? Icons.check_circle : Icons.bolt_rounded),
                label: Text(_challengeDone ? 'أكملت تحدي اليوم' : 'إكمال التحدي +25 نقطة'),
              ),
            ),
          ]),
        ),
      );

  Widget _tasksCard() => Card(
        child: Column(children: _quickTasks.map((task) => CheckboxListTile(
          value: _tasks[task] == true,
          controlAffinity: ListTileControlAffinity.leading,
          title: Text(task),
          onChanged: (value) async {
            setState(() => _tasks[task] = value == true);
            await _saveTasks();
          },
        )).toList()),
      );

  Widget _focusCard() => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            Text(_timerLabel, style: const TextStyle(fontSize: 42, fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            Wrap(spacing: 8, children: [15, 25, 45].map((minutes) => ChoiceChip(
              label: Text('$minutes دقيقة'),
              selected: _focusMinutes == minutes,
              onSelected: _timerRunning ? null : (_) => _resetTimer(minutes),
            )).toList()),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: FilledButton.icon(
                onPressed: _startTimer,
                icon: Icon(_timerRunning ? Icons.pause_rounded : Icons.play_arrow_rounded),
                label: Text(_timerRunning ? 'إيقاف مؤقت' : 'ابدأ التركيز'),
              )),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                tooltip: 'إعادة ضبط',
                onPressed: () => _resetTimer(),
                icon: const Icon(Icons.restart_alt_rounded),
              ),
            ]),
          ]),
        ),
      );

  Widget _ideasCard() => Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            TextField(
              controller: _ideaController,
              minLines: 2,
              maxLines: 4,
              maxLength: 500,
              decoration: const InputDecoration(
                hintText: 'اكتب فكرة مشروع أو لعبة أو منشور...',
                border: OutlineInputBorder(),
              ),
            ),
            FilledButton.icon(
              onPressed: _saveIdea,
              icon: const Icon(Icons.save_alt_rounded),
              label: const Text('حفظ الفكرة'),
            ),
            if (_ideas.isNotEmpty) ...[
              const Divider(height: 24),
              ..._ideas.take(8).map((idea) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.lightbulb_outline_rounded, color: _v44Brand),
                title: Text(idea),
                trailing: IconButton(
                  tooltip: 'حذف',
                  icon: const Icon(Icons.delete_outline_rounded),
                  onPressed: () async {
                    setState(() => _ideas.remove(idea));
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setStringList('v44_ideas', _ideas);
                  },
                ),
              )),
            ],
          ]),
        ),
      );

  Widget _shortcutsCard() => Card(
        child: Column(children: [
          _shortcut(Icons.sports_esports_rounded, 'عالم الألعاب والتحديات', 'games'),
          _shortcut(Icons.event_available_rounded, 'تقويم فعاليات المجتمع', 'events'),
          _shortcut(Icons.auto_awesome_rounded, 'استوديو الإبداع', 'studio'),
          _shortcut(Icons.menu_book_rounded, 'ركن المعرفة', 'knowledge'),
          _shortcut(Icons.library_music_rounded, 'مكتبة ومشغل الميديا', 'media'),
          _shortcut(Icons.groups_rounded, 'المجتمع والأندية', 'community'),
        ]),
      );

  Widget _shortcut(IconData icon, String label, String route) => ListTile(
        leading: Icon(icon, color: _v44Brand),
        title: Text(label),
        trailing: const Icon(Icons.chevron_left_rounded),
        onTap: () => widget.onOpen(route),
      );
}
