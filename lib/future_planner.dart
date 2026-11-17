import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Private, offline-first planner. Data stays on this device.
class FuturePlannerPage extends StatefulWidget {
  const FuturePlannerPage({super.key});
  @override
  State<FuturePlannerPage> createState() => _FuturePlannerPageState();
}

class _FuturePlannerPageState extends State<FuturePlannerPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 3, vsync: this);
  final List<Map<String, dynamic>> _tasks = [];
  final List<Map<String, dynamic>> _habits = [];
  final TextEditingController _journal = TextEditingController();
  bool _loading = true;
  String _filter = 'الكل';
  static const _taskKey = 'future_planner_tasks_v1';
  static const _habitKey = 'future_planner_habits_v1';
  static const _journalKey = 'future_planner_journal_v1';

  String get _today => _dateKey(DateTime.now());
  String _dateKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    List<Map<String, dynamic>> decodeList(String key) {
      try {
        final raw = jsonDecode(prefs.getString(key) ?? '[]') as List;
        return raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      } catch (_) {
        return [];
      }
    }
    if (!mounted) return;
    setState(() {
      _tasks.addAll(decodeList(_taskKey));
      _habits.addAll(decodeList(_habitKey));
      _journal.text = prefs.getString(_journalKey) ?? '';
      _loading = false;
    });
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_taskKey, jsonEncode(_tasks));
    await prefs.setString(_habitKey, jsonEncode(_habits));
  }

  @override
  void dispose() {
    _tabs.dispose();
    _journal.dispose();
    super.dispose();
  }

  Future<void> _addTask() async {
    final title = TextEditingController();
    final detail = TextEditingController();
    String priority = 'عادي';
    String category = 'شخصي';
    DateTime? due;
    final ok = await showDialog<bool>(context: context, builder: (c) =>
      StatefulBuilder(builder: (c, refresh) => AlertDialog(
        title: const Text('مهمة جديدة'),
        content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: title, maxLength: 80, decoration: const InputDecoration(labelText: 'عنوان المهمة')),
          TextField(controller: detail, maxLength: 180, decoration: const InputDecoration(labelText: 'تفاصيل (اختياري)')),
          DropdownButtonFormField<String>(initialValue: priority, decoration: const InputDecoration(labelText: 'الأولوية'),
            items: ['منخفضة','عادي','مهمة','عاجلة'].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
            onChanged: (v) => refresh(() => priority = v ?? priority)),
          DropdownButtonFormField<String>(initialValue: category, decoration: const InputDecoration(labelText: 'التصنيف'),
            items: ['شخصي','دراسة','مشروع','مجتمع','ترفيه'].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
            onChanged: (v) => refresh(() => category = v ?? category)),
          const SizedBox(height: 8),
          OutlinedButton.icon(onPressed: () async {
            final selected = await showDatePicker(context: c, initialDate: due ?? DateTime.now(),
              firstDate: DateTime.now().subtract(const Duration(days: 365)),
              lastDate: DateTime.now().add(const Duration(days: 3650)));
            if (selected != null) refresh(() => due = selected);
          }, icon: const Icon(Icons.calendar_month), label: Text(due == null ? 'موعد اختياري' : _dateKey(due!))),
        ])),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('إلغاء')),
          FilledButton(onPressed: () => Navigator.pop(c, title.text.trim().isNotEmpty), child: const Text('إضافة')),
        ],
      )));
    if (ok == true && title.text.trim().isNotEmpty) {
      setState(() => _tasks.insert(0, {'id': DateTime.now().microsecondsSinceEpoch.toString(),
        'title': title.text.trim(), 'detail': detail.text.trim(), 'priority': priority,
        'category': category, 'due': due == null ? '' : _dateKey(due!), 'done': false}));
      await _save();
    }
    title.dispose();
    detail.dispose();
  }

  Future<void> _addHabit() async {
    final name = TextEditingController();
    final ok = await showDialog<bool>(context: context, builder: (c) => AlertDialog(
      title: const Text('عادة جديدة'),
      content: TextField(controller: name, autofocus: true, maxLength: 50,
        decoration: const InputDecoration(hintText: 'مثلاً: قراءة 10 دقائق')),
      actions: [
        TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('إلغاء')),
        FilledButton(onPressed: () => Navigator.pop(c, name.text.trim().isNotEmpty), child: const Text('إضافة')),
      ],
    ));
    if (ok == true && name.text.trim().isNotEmpty) {
      setState(() => _habits.add({'id': DateTime.now().microsecondsSinceEpoch.toString(),
        'name': name.text.trim(), 'days': <String>[]}));
      await _save();
    }
    name.dispose();
  }

  Future<void> _toggleHabit(Map<String, dynamic> habit) async {
    final days = List<String>.from(habit['days'] as List? ?? []);
    if (days.contains(_today)) { days.remove(_today); } else { days.add(_today); }
    setState(() => habit['days'] = days);
    await _save();
  }

  Future<void> _saveJournal() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_journalKey, _journal.text);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('انحفظت مذكرتك على هذا الجهاز')));
  }

  Future<void> _deleteTask(Map<String, dynamic> task) async {
    setState(() => _tasks.remove(task));
    await _save();
  }

  Future<void> _deleteHabit(Map<String, dynamic> habit) async {
    setState(() => _habits.remove(habit));
    await _save();
  }

  @override
  Widget build(BuildContext context) {
    final done = _tasks.where((t) => t['done'] == true).length;
    final todayHabits = _habits.where((h) => List<String>.from(h['days'] as List? ?? []).contains(_today)).length;
    return Directionality(textDirection: TextDirection.rtl, child: Scaffold(
      appBar: AppBar(title: const Text('مخطط المستقبل')),
      floatingActionButton: AnimatedBuilder(animation: _tabs, builder: (_, __) =>
        FloatingActionButton.extended(onPressed: _loading ? null : (_tabs.index == 0 ? _addTask : _tabs.index == 1 ? _addHabit : _saveJournal),
          icon: Icon(_tabs.index == 0 ? Icons.add_task : _tabs.index == 1 ? Icons.add : Icons.save),
          label: Text(_tabs.index == 0 ? 'مهمة جديدة' : _tabs.index == 1 ? 'عادة جديدة' : 'حفظ المذكرة'))),
      body: _loading ? const Center(child: CircularProgressIndicator()) : Column(children: [
        Container(margin: const EdgeInsets.all(14), padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(colors: [Color(0xFF242052), Color(0xFF6554D9), Color(0xFF167C88)])),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('رتّب يومك، خطوة بخطوة ✨', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: _stat('المهام المنجزة', '$done / ${_tasks.length}')),
              Expanded(child: _stat('عادات اليوم', '$todayHabits / ${_habits.length}')),
              Expanded(child: _stat('تاريخ اليوم', _today)),
            ]),
          ])),
        TabBar(controller: _tabs, tabs: const [
          Tab(icon: Icon(Icons.checklist_rounded), text: 'المهام'),
          Tab(icon: Icon(Icons.repeat_rounded), text: 'العادات'),
          Tab(icon: Icon(Icons.edit_note_rounded), text: 'مذكرتي'),
        ], onTap: (_) => setState(() {})),
        Expanded(child: TabBarView(controller: _tabs, children: [
          _taskList(),
          _habitList(),
          Padding(padding: const EdgeInsets.all(14), child: Column(children: [
            const Text('مساحة خاصة للخواطر والأفكار والخطط. تحفظ محلياً ولا تُرفع إلى الإنترنت.',
              style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 10),
            Expanded(child: TextField(controller: _journal, expands: true, minLines: null, maxLines: null,
              textAlignVertical: TextAlignVertical.top, decoration: const InputDecoration(
                hintText: 'اكتب أفكارك هنا...', border: OutlineInputBorder()))),
            const SizedBox(height: 68),
          ])),
        ])),
      ]),
    ));
  }

  Widget _stat(String label, String value) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
    const SizedBox(height: 3),
    Text(value, maxLines: 1, overflow: TextOverflow.ellipsis,
      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
  ]);

  Widget _taskList() {
    final filtered = _tasks.where((t) => _filter == 'الكل' ||
      (_filter == 'مكتملة' && t['done'] == true) ||
      (_filter == 'غير مكتملة' && t['done'] != true)).toList();
    return Column(children: [
      Padding(padding: const EdgeInsets.fromLTRB(12, 8, 12, 2), child: Wrap(spacing: 6, children: [
        for (final f in ['الكل','غير مكتملة','مكتملة'])
          ChoiceChip(label: Text(f), selected: _filter == f, onSelected: (_) => setState(() => _filter = f)),
      ])),
      Expanded(child: filtered.isEmpty
        ? const Center(child: Text('ماكو مهام هنا. أضف أول مهمة وابدأ 👌'))
        : ListView.builder(padding: const EdgeInsets.fromLTRB(12, 8, 12, 88), itemCount: filtered.length,
          itemBuilder: (context, i) {
            final task = filtered[i];
            final isDone = task['done'] == true;
            final due = (task['due'] ?? '').toString();
            return Card(child: ListTile(
              leading: Checkbox(value: isDone, onChanged: (v) async {
                setState(() => task['done'] = v ?? false); await _save();
              }),
              title: Text(task['title'] ?? '', style: TextStyle(fontWeight: FontWeight.bold,
                decoration: isDone ? TextDecoration.lineThrough : null)),
              subtitle: Text([
                if ((task['detail'] ?? '').toString().isNotEmpty) task['detail'],
                '${task['category']} • أولوية ${task['priority']}',
                if (due.isNotEmpty) 'الموعد: $due',
              ].join('\n')),
              isThreeLine: true,
              trailing: IconButton(tooltip: 'حذف المهمة', icon: const Icon(Icons.delete_outline),
                onPressed: () => _deleteTask(task)),
            ));
          })),
    ]);
  }

  Widget _habitList() => _habits.isEmpty
    ? const Center(child: Text('أضف عادة صغيرة تود متابعتها يومياً.'))
    : ListView.builder(padding: const EdgeInsets.fromLTRB(12, 10, 12, 88), itemCount: _habits.length,
      itemBuilder: (context, i) {
        final habit = _habits[i];
        final days = List<String>.from(habit['days'] as List? ?? []);
        final checked = days.contains(_today);
        return Card(child: ListTile(
          leading: Icon(checked ? Icons.check_circle : Icons.circle_outlined,
            color: checked ? Colors.green : Theme.of(context).colorScheme.primary),
          title: Text(habit['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text('أيام الإنجاز المسجلة: ${days.length}'),
          trailing: Row(mainAxisSize: MainAxisSize.min, children: [
            Checkbox(value: checked, onChanged: (_) => _toggleHabit(habit)),
            IconButton(tooltip: 'حذف العادة', icon: const Icon(Icons.delete_outline), onPressed: () => _deleteHabit(habit)),
          ]),
          onTap: () => _toggleHabit(habit),
        ));
      });

}
