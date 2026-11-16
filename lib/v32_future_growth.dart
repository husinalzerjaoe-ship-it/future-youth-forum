import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FutureGrowthPage extends StatefulWidget {
  const FutureGrowthPage({super.key});
  @override State<FutureGrowthPage> createState() => _FutureGrowthPageState();
}

class _FutureGrowthPageState extends State<FutureGrowthPage> {
  static const _key = 'v32_growth_goals';
  static const _dayKey = 'v32_growth_day';
  static const _streakKey = 'v32_growth_streak';
  static const _prompts = <String>[
    'شنو الشي الجديد اللي تعلمته اليوم؟',
    'شنو خطوة صغيرة تقربك من هدفك؟',
    'شنو فكرة حلوة تريد تجربها هذا الأسبوع؟',
    'منو شخص ساعدك أو ألهمك اليوم؟',
    'شنو إنجاز بسيط تحب تحتفل بيه؟',
  ];
  final _controller = TextEditingController();
  List<Map<String, dynamic>> _goals = [];
  int _streak = 0;
  bool _checkedIn = false;
  bool _loading = true;

  String get _today {
    final now = DateTime.now();
    return '\${now.year.toString().padLeft(4, '0')}-\${now.month.toString().padLeft(2, '0')}-\${now.day.toString().padLeft(2, '0')}';
  }

  @override void initState() { super.initState(); _load(); }
  @override void dispose() { _controller.dispose(); super.dispose(); }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_key);
    final lastDay = prefs.getString(_dayKey) ?? '';
    final sameDay = lastDay == _today;
    if (saved != null) {
      try {
        final decoded = jsonDecode(saved) as List<dynamic>;
        _goals = decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      } catch (_) { _goals = []; }
    }
    if (!sameDay) {
      for (final goal in _goals) { goal['done'] = false; }
      await _saveGoals();
    }
    _streak = prefs.getInt(_streakKey) ?? 0;
    _checkedIn = sameDay && (prefs.getBool('v32_growth_checked') ?? false);
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _saveGoals() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(_goals));
  }

  Future<void> _addGoal() async {
    final value = _controller.text.trim();
    if (value.isEmpty || value.length > 70) return;
    setState(() { _goals.add({'id': DateTime.now().microsecondsSinceEpoch.toString(), 'title': value, 'done': false}); _controller.clear(); });
    await _saveGoals();
  }

  Future<void> _toggleGoal(int index, bool value) async {
    setState(() => _goals[index]['done'] = value);
    await _saveGoals();
  }

  Future<void> _removeGoal(int index) async {
    setState(() => _goals.removeAt(index));
    await _saveGoals();
  }

  Future<void> _checkIn() async {
    if (_checkedIn) return;
    final prefs = await SharedPreferences.getInstance();
    final last = prefs.getString(_dayKey) ?? '';
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    final yesterdayKey = '\${yesterday.year.toString().padLeft(4, '0')}-\${yesterday.month.toString().padLeft(2, '0')}-\${yesterday.day.toString().padLeft(2, '0')}';
    _streak = last == yesterdayKey ? _streak + 1 : 1;
    _checkedIn = true;
    await prefs.setInt(_streakKey, _streak);
    await prefs.setBool('v32_growth_checked', true);
    await prefs.setString(_dayKey, _today);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final completed = _goals.where((g) => g['done'] == true).length;
    final progress = _goals.isEmpty ? 0.0 : completed / _goals.length;
    final prompt = _prompts[DateTime.now().day % _prompts.length];
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('مسار تطوري'), actions: [
          IconButton(tooltip: 'إعادة تحميل', onPressed: _load, icon: const Icon(Icons.refresh_rounded)),
        ]),
        body: _loading ? const Center(child: CircularProgressIndicator()) : ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: const LinearGradient(begin: Alignment.topRight, end: Alignment.bottomLeft, colors: [Color(0xFF29215D), Color(0xFF6554D9), Color(0xFF168E9B)]),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('خطوة صغيرة كل يوم تصنع فرقاً كبيراً', style: TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w900)),
                const SizedBox(height: 14),
                Row(children: [
                  const Icon(Icons.local_fire_department_rounded, color: Color(0xFFFFD166), size: 30),
                  const SizedBox(width: 7),
                  Text('$_streak يوم متواصل', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  const Spacer(),
                  FilledButton.tonalIcon(
                    onPressed: _checkedIn ? null : _checkIn,
                    icon: Icon(_checkedIn ? Icons.check_circle : Icons.wb_sunny_outlined),
                    label: Text(_checkedIn ? 'سجلت حضورك' : 'تسجيل اليوم'),
                  ),
                ]),
              ]),
            ),
            const SizedBox(height: 14),
            Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text('أهداف اليوم', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17)),
                Text('$completed / \${_goals.length}', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF6554D9))),
              ]),
              const SizedBox(height: 10),
              ClipRRect(borderRadius: BorderRadius.circular(20), child: LinearProgressIndicator(value: progress, minHeight: 9)),
              const SizedBox(height: 14),
              Row(children: [
                Expanded(child: TextField(
                  controller: _controller,
                  maxLength: 70,
                  onSubmitted: (_) => _addGoal(),
                  decoration: const InputDecoration(counterText: '', hintText: 'أضف هدفاً صغيراً لليوم', border: OutlineInputBorder()),
                )),
                const SizedBox(width: 8),
                IconButton.filled(onPressed: _addGoal, icon: const Icon(Icons.add_rounded), tooltip: 'إضافة هدف'),
              ]),
              if (_goals.isEmpty) const Padding(padding: EdgeInsets.symmetric(vertical: 18), child: Center(child: Text('ابدأ بإضافة أول هدف لك اليوم.'))),
              ..._goals.asMap().entries.map((entry) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Checkbox(value: entry.value['done'] == true, onChanged: (v) => _toggleGoal(entry.key, v ?? false)),
                title: Text(entry.value['title'].toString(), style: TextStyle(decoration: entry.value['done'] == true ? TextDecoration.lineThrough : null, color: entry.value['done'] == true ? Colors.grey : null)),
                trailing: IconButton(onPressed: () => _removeGoal(entry.key), icon: const Icon(Icons.close_rounded), tooltip: 'حذف الهدف'),
              )),
            ]))),
            const SizedBox(height: 14),
            Card(child: ListTile(
              leading: const CircleAvatar(child: Icon(Icons.lightbulb_outline_rounded)),
              title: const Text('سؤال اليوم', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Padding(padding: const EdgeInsets.only(top: 7), child: Text(prompt)),
              trailing: const Icon(Icons.auto_awesome_rounded),
            )),
            const SizedBox(height: 10),
            const Text('ملاحظة: أهدافك وسلسلة حضورك محفوظة على هذا الجهاز فقط، ولا تُرسل إلى حسابك أو إلى أعضاء آخرين.', style: TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
