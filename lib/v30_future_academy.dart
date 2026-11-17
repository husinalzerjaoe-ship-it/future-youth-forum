import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _academyPurple = Color(0xFF7562E8);

class V30FutureAcademyPage extends StatefulWidget {
  const V30FutureAcademyPage({super.key});
  @override
  State<V30FutureAcademyPage> createState() => _V30FutureAcademyPageState();
}

class _V30FutureAcademyPageState extends State<V30FutureAcademyPage> {
  final List<Map<String, dynamic>> _tasks = [];
  final List<Map<String, dynamic>> _notes = [];
  final Set<String> _completedLessons = {};
  bool _loading = true;

  static const _tracks = <_SkillTrack>[
    _SkillTrack('مهارات البرمجة', 'ابدأ بفهم طريقة تفكير المبرمج', Icons.code_rounded, [
      'تعرّف على معنى الخوارزمية بخطوات يومية بسيطة',
      'افهم المتغيرات وأنواع البيانات',
      'تدرّب على الشروط والتكرار بأمثلة تعليمية',
      'خطط لتطبيق صغير على الورق قبل تنفيذه',
    ]),
    _SkillTrack('التصميم والإبداع', 'حوّل الأفكار إلى واجهات واضحة', Icons.brush_rounded, [
      'تعلّم مبادئ التباين والتناسق البصري',
      'ارسم مخططاً أولياً لشاشة تطبيق',
      'اختر لوحة ألوان متناسقة من ثلاثة ألوان',
      'راجع سهولة الاستخدام ووضوح الأزرار',
    ]),
    _SkillTrack('اللغة والتواصل', 'طوّر التعبير والكتابة والحوار', Icons.translate_rounded, [
      'اكتب فقرة قصيرة ثم راجع وضوحها',
      'تعلّم خمس مفردات جديدة واستخدمها بجمل',
      'لخّص موضوعاً في ثلاث نقاط',
      'تدرّب على عرض فكرة باحترام واختصار',
    ]),
    _SkillTrack('التفكير النقدي', 'اسأل وتحقق وقارن بين المصادر', Icons.psychology_alt_rounded, [
      'ميّز بين الرأي والمعلومة القابلة للتحقق',
      'قارن معلومة في مصدرين موثوقين',
      'اكتب دليلاً يؤيد الفكرة ودليلاً يحدّ منها',
      'حدّد ما لا تعرفه قبل إصدار الحكم',
    ]),
    _SkillTrack('السلامة الرقمية', 'استخدم الإنترنت بوعي وخصوصية', Icons.shield_moon_rounded, [
      'تعرّف على كلمات المرور القوية والمصادقة الثنائية',
      'راجع أذونات التطبيقات قبل منحها',
      'تعلّم تمييز الروابط والرسائل المشبوهة',
      'راجع إعدادات الخصوصية في حساباتك',
    ]),
    _SkillTrack('إدارة المشاريع', 'قسّم الفكرة إلى خطوات قابلة للإنجاز', Icons.rocket_launch_rounded, [
      'اكتب المشكلة التي تريد حلها بجملة واحدة',
      'حدّد النتيجة المطلوبة بوضوح',
      'قسّم العمل إلى ثلاث مهام صغيرة',
      'راجع ما أنجزته وحدّد الخطوة التالية',
    ]),
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    try {
      final tasks = jsonDecode(prefs.getString('v30_academy_tasks') ?? '[]') as List;
      final notes = jsonDecode(prefs.getString('v30_academy_notes') ?? '[]') as List;
      _tasks.addAll(tasks.map((e) => Map<String, dynamic>.from(e as Map)));
      _notes.addAll(notes.map((e) => Map<String, dynamic>.from(e as Map)));
      _completedLessons.addAll(prefs.getStringList('v30_academy_lessons') ?? const []);
    } catch (_) {
      // Ignore damaged local cache and keep the academy usable.
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('v30_academy_tasks', jsonEncode(_tasks));
    await prefs.setString('v30_academy_notes', jsonEncode(_notes));
    await prefs.setStringList('v30_academy_lessons', _completedLessons.toList());
  }

  Future<void> _toggleLesson(String id) async {
    setState(() {
      if (!_completedLessons.add(id)) _completedLessons.remove(id);
    });
    await _save();
  }

  Future<void> _addTask() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('مهمة جديدة'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 90,
          decoration: const InputDecoration(hintText: 'مثلاً: أراجع درساً لمدة 20 دقيقة'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          FilledButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: const Text('إضافة')),
        ],
      ),
    );
    controller.dispose();
    if (result == null || result.isEmpty) return;
    setState(() => _tasks.insert(0, {'title': result, 'done': false, 'created': DateTime.now().toIso8601String()}));
    await _save();
  }

  Future<void> _addNote() async {
    final title = TextEditingController();
    final body = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('احفظ فكرة جديدة'),
        content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: title, maxLength: 60, decoration: const InputDecoration(labelText: 'عنوان الفكرة')),
          TextField(controller: body, minLines: 3, maxLines: 6, maxLength: 700, decoration: const InputDecoration(labelText: 'التفاصيل')),
        ])),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('حفظ')),
        ],
      ),
    );
    if (result != true || (title.text.trim().isEmpty && body.text.trim().isEmpty)) {
      title.dispose(); body.dispose(); return;
    }
    setState(() => _notes.insert(0, {
      'title': title.text.trim().isEmpty ? 'فكرة بدون عنوان' : title.text.trim(),
      'body': body.text.trim(),
      'created': DateTime.now().toIso8601String(),
    }));
    title.dispose(); body.dispose();
    await _save();
  }

  Future<void> _removeTask(int index) async {
    setState(() => _tasks.removeAt(index));
    await _save();
  }

  Future<void> _removeNote(int index) async {
    setState(() => _notes.removeAt(index));
    await _save();
  }

  @override
  Widget build(BuildContext context) {
    final totalLessons = _tracks.fold<int>(0, (sum, track) => sum + track.lessons.length);
    final taskDone = _tasks.where((task) => task['done'] == true).length;
    final progress = totalLessons == 0 ? 0.0 : _completedLessons.length / totalLessons;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: DefaultTabController(
        length: 3,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('أكاديمية المستقبل'),
            bottom: const TabBar(isScrollable: true, tabs: [
              Tab(icon: Icon(Icons.school_rounded), text: 'مسارات التعلم'),
              Tab(icon: Icon(Icons.checklist_rounded), text: 'مخطط المهام'),
              Tab(icon: Icon(Icons.lightbulb_outline_rounded), text: 'دفتر الأفكار'),
            ]),
          ),
          body: _loading ? const Center(child: CircularProgressIndicator()) : TabBarView(children: [
            _buildTracks(progress, totalLessons),
            _buildTasks(taskDone),
            _buildNotes(),
          ]),
        ),
      ),
    );
  }

  Widget _buildTracks(double progress, int totalLessons) => ListView(
    padding: const EdgeInsets.all(14),
    children: [
      _hero('تعلّم خطوة بخطوة', 'مسارات قصيرة تساعدك على اكتساب مهارات مفيدة، واحفظ تقدمك على جهازك.', Icons.school_rounded),
      const SizedBox(height: 12),
      Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('تقدمك في الأكاديمية', style: TextStyle(fontWeight: FontWeight.bold)),
          Text('${_completedLessons.length} / $totalLessons'),
        ]),
        const SizedBox(height: 10),
        LinearProgressIndicator(value: progress, minHeight: 9, borderRadius: BorderRadius.circular(20)),
        const SizedBox(height: 6),
        const Text('علّم الخطوة كمكتملة بعد إنجازها. التقدم محفوظ محلياً.', style: TextStyle(fontSize: 12, color: Colors.grey)),
      ]))),
      ..._tracks.map((track) {
        final done = track.lessons.where((lesson) => _completedLessons.contains('${track.title}|$lesson')).length;
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: ExpansionTile(
            leading: CircleAvatar(backgroundColor: _academyPurple.withValues(alpha: .12), child: Icon(track.icon, color: _academyPurple)),
            title: Text(track.title, style: const TextStyle(fontWeight: FontWeight.w800)),
            subtitle: Text('${track.description} • $done/${track.lessons.length}'),
            children: track.lessons.map((lesson) {
              final id = '${track.title}|$lesson';
              return CheckboxListTile(
                value: _completedLessons.contains(id),
                onChanged: (_) => _toggleLesson(id),
                title: Text(lesson, style: const TextStyle(fontSize: 13)),
                controlAffinity: ListTileControlAffinity.leading,
              );
            }).toList(),
          ),
        );
      }),
    ],
  );

  Widget _buildTasks(int done) => ListView(
    padding: const EdgeInsets.all(14),
    children: [
      _hero('مخطط إنجازك', 'اكتب مهاماً صغيرة، علّم ما أنجزته، وارجع لخطة يومك متى ما تحتاج.', Icons.task_alt_rounded),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(child: _stat('كل المهام', '${_tasks.length}', Icons.list_alt_rounded)),
        const SizedBox(width: 8),
        Expanded(child: _stat('المكتمل', '$done', Icons.check_circle_outline_rounded)),
        const SizedBox(width: 8),
        Expanded(child: _stat('المتبقي', '${_tasks.length - done}', Icons.pending_actions_rounded)),
      ]),
      const SizedBox(height: 12),
      FilledButton.icon(onPressed: _addTask, icon: const Icon(Icons.add), label: const Text('أضف مهمة')),
      const SizedBox(height: 8),
      if (_tasks.isEmpty) const Card(child: Padding(padding: EdgeInsets.all(22), child: Center(child: Text('ما عندك مهام بعد. أضف أول خطوة صغيرة!')))),
      ..._tasks.asMap().entries.map((entry) => Card(
        child: ListTile(
          leading: Checkbox(value: entry.value['done'] == true, onChanged: (value) async {
            setState(() => entry.value['done'] = value ?? false);
            await _save();
          }),
          title: Text(entry.value['title']?.toString() ?? '', style: TextStyle(decoration: entry.value['done'] == true ? TextDecoration.lineThrough : null)),
          subtitle: Text(entry.value['done'] == true ? 'مكتملة' : 'بانتظار الإنجاز'),
          trailing: IconButton(icon: const Icon(Icons.delete_outline), tooltip: 'حذف المهمة', onPressed: () => _removeTask(entry.key)),
        ),
      )),
    ],
  );

  Widget _buildNotes() => ListView(
    padding: const EdgeInsets.all(14),
    children: [
      _hero('دفتر الأفكار والمشاريع', 'احتفظ بأفكارك وخططك وملاحظاتك داخل جهازك، ويمكنك تعديلها أو حذفها لاحقاً.', Icons.lightbulb_rounded),
      const SizedBox(height: 12),
      FilledButton.icon(onPressed: _addNote, icon: const Icon(Icons.note_add_rounded), label: const Text('اكتب فكرة')),
      const SizedBox(height: 8),
      if (_notes.isEmpty) const Card(child: Padding(padding: EdgeInsets.all(22), child: Center(child: Text('دفترك فارغ حالياً. دوّن فكرة تحب تطورها.')))),
      ..._notes.asMap().entries.map((entry) => Card(
        child: ListTile(
          isThreeLine: true,
          leading: const CircleAvatar(child: Icon(Icons.lightbulb_outline_rounded)),
          title: Text(entry.value['title']?.toString() ?? 'فكرة'),
          subtitle: Text(entry.value['body']?.toString() ?? '', maxLines: 3, overflow: TextOverflow.ellipsis),
          trailing: IconButton(icon: const Icon(Icons.delete_outline), tooltip: 'حذف الفكرة', onPressed: () => _removeNote(entry.key)),
        ),
      )),
    ],
  );

  Widget _hero(String title, String subtitle, IconData icon) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(22),
      gradient: const LinearGradient(begin: Alignment.topRight, end: Alignment.bottomLeft, colors: [Color(0xFF201B4C), Color(0xFF6652C8), Color(0xFF087E91)]),
    ),
    child: Row(children: [
      Icon(icon, color: const Color(0xFFFFD98A), size: 36),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w900)),
        const SizedBox(height: 5),
        Text(subtitle, style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ])),
    ]),
  );

  Widget _stat(String title, String value, IconData icon) => Card(child: Padding(
    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
    child: Column(children: [Icon(icon, color: _academyPurple), const SizedBox(height: 5), Text(value, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)), Text(title, style: const TextStyle(fontSize: 11))]),
  ));
}

class _SkillTrack {
  const _SkillTrack(this.title, this.description, this.icon, this.lessons);
  final String title;
  final String description;
  final IconData icon;
  final List<String> lessons;
}
