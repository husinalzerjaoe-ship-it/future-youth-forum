import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// V64 offline-first personal tools. Journal and notes remain on this device.
class V64PersonalToolboxPage extends StatefulWidget {
  const V64PersonalToolboxPage({super.key});
  @override
  State<V64PersonalToolboxPage> createState() => _V64PersonalToolboxPageState();
}

class _V64PersonalToolboxPageState extends State<V64PersonalToolboxPage> {
  static const _journalKey = 'v64_private_journal_entries';
  static const _notesKey = 'v64_private_quick_notes';
  final _random = Random();
  final _journalController = TextEditingController();
  final _noteController = TextEditingController();
  final List<_V64Entry> _journal = [];
  final List<_V64Entry> _notes = [];
  bool _loading = true;
  Timer? _stopwatchTicker;
  Timer? _countdownTicker;
  Duration _stopwatch = Duration.zero;
  Duration _countdown = Duration.zero;
  bool _stopwatchRunning = false;
  bool _countdownRunning = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _stopwatchTicker?.cancel();
    _countdownTicker?.cancel();
    _journalController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _journal.addAll(_decode(prefs.getString(_journalKey)));
      _notes.addAll(_decode(prefs.getString(_notesKey)));
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  List<_V64Entry> _decode(String? raw) {
    if (raw == null) return [];
    final value = jsonDecode(raw);
    if (value is! List) return [];
    return value.whereType<Map>().map((e) => _V64Entry.fromJson(Map<String, dynamic>.from(e))).toList();
  }

  Future<void> _save(bool journal) async {
    final prefs = await SharedPreferences.getInstance();
    final items = journal ? _journal : _notes;
    await prefs.setString(journal ? _journalKey : _notesKey,
      jsonEncode(items.map((e) => e.toJson()).toList()));
  }

  Future<void> _addEntry(bool journal) async {
    final controller = journal ? _journalController : _noteController;
    controller.clear();
    final value = await showDialog<String>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: Text(journal ? 'يوميات خاصة' : 'ملاحظة سريعة'),
          content: TextField(
            controller: controller, autofocus: true, minLines: 3, maxLines: 7, maxLength: 1200,
            decoration: const InputDecoration(
              hintText: 'اكتب هنا… تُحفظ على جهازك فقط',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
            FilledButton(onPressed: () => Navigator.pop(ctx, controller.text.trim()), child: const Text('حفظ')),
          ],
        ),
      ),
    );
    if (!mounted || value == null || value.isEmpty) return;
    final items = journal ? _journal : _notes;
    setState(() => items.insert(0, _V64Entry(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      text: value,
      createdAt: DateTime.now().toIso8601String(),
    )));
    await _save(journal);
  }

  Future<void> _delete(_V64Entry entry, bool journal) async {
    setState(() => (journal ? _journal : _notes).removeWhere((e) => e.id == entry.id));
    await _save(journal);
  }

  void _startStopwatch() {
    if (_stopwatchRunning) return;
    setState(() => _stopwatchRunning = true);
    _stopwatchTicker = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (mounted) setState(() => _stopwatch += const Duration(milliseconds: 100));
    });
  }

  void _pauseStopwatch() {
    _stopwatchTicker?.cancel();
    setState(() => _stopwatchRunning = false);
  }

  void _resetStopwatch() {
    _stopwatchTicker?.cancel();
    setState(() { _stopwatchRunning = false; _stopwatch = Duration.zero; });
  }

  Future<void> _toggleCountdown() async {
    if (_countdownRunning) {
      _countdownTicker?.cancel();
      setState(() => _countdownRunning = false);
      return;
    }
    if (_countdown == Duration.zero) {
      final controller = TextEditingController(text: '5');
      final minutes = await showDialog<int>(
        context: context,
        builder: (ctx) => Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Text('ضبط المؤقت بالدقائق'),
            content: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'عدد الدقائق', border: OutlineInputBorder()),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
              FilledButton(onPressed: () => Navigator.pop(ctx, int.tryParse(controller.text)), child: const Text('ابدأ')),
            ],
          ),
        ),
      );
      controller.dispose();
      if (!mounted || minutes == null || minutes < 1 || minutes > 1440) return;
      setState(() => _countdown = Duration(minutes: minutes));
    }
    setState(() => _countdownRunning = true);
    _countdownTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (_countdown.inSeconds <= 1) {
        _countdownTicker?.cancel();
        setState(() { _countdown = Duration.zero; _countdownRunning = false; });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('انتهى الوقت المحدد ⏰')));
      } else {
        setState(() => _countdown -= const Duration(seconds: 1));
      }
    });
  }

  void _resetCountdown() {
    _countdownTicker?.cancel();
    setState(() { _countdownRunning = false; _countdown = Duration.zero; });
  }

  String _clock(Duration value, {bool tenths = false}) {
    final h = value.inHours.toString().padLeft(2, '0');
    final m = (value.inMinutes % 60).toString().padLeft(2, '0');
    final s = (value.inSeconds % 60).toString().padLeft(2, '0');
    final fraction = tenths ? '.${value.inMilliseconds % 1000 ~/ 100}' : '';
    return '$h:$m:$s$fraction';
  }

  Future<void> _randomPicker() async {
    final controller = TextEditingController();
    final raw = await showDialog<String>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('قرعة الاختيارات'),
          content: TextField(controller: controller, minLines: 3, maxLines: 7,
            decoration: const InputDecoration(hintText: 'كل اختيار بسطر منفصل', border: OutlineInputBorder())),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
            FilledButton(onPressed: () => Navigator.pop(ctx, controller.text), child: const Text('اسحب القرعة')),
          ],
        ),
      ),
    );
    controller.dispose();
    if (!mounted || raw == null) return;
    final choices = raw.split('\n').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    if (choices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('أضف اختياراً واحداً على الأقل')));
      return;
    }
    final result = choices[_random.nextInt(choices.length)];
    await showDialog<void>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('الاختيار الفائز 🎉'),
          content: SelectableText(result, style: const TextStyle(fontSize: 23, fontWeight: FontWeight.bold)),
          actions: [FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('حسناً'))],
        ),
      ),
    );
  }

  Future<void> _textLab() async {
    final controller = TextEditingController();
    String output = '';
    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, refresh) {
        final text = controller.text;
        final words = text.trim().isEmpty ? 0 : text.trim().split(RegExp(r'\s+')).length;
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Text('مختبر النصوص'),
            content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(controller: controller, minLines: 4, maxLines: 8,
                onChanged: (_) => refresh(),
                decoration: const InputDecoration(labelText: 'اكتب أو الصق النص', border: OutlineInputBorder())),
              const SizedBox(height: 8),
              Align(alignment: Alignment.centerRight,
                child: Text('الكلمات: $words • الحروف: ${text.length} • الأسطر: ${text.isEmpty ? 0 : text.split('\n').length}')),
              Wrap(spacing: 6, runSpacing: 6, children: [
                OutlinedButton(onPressed: () => refresh(() {
                  output = text.split('\n').map((e) => e.trim()).where((e) => e.isNotEmpty).toSet().join('\n');
                }), child: const Text('حذف الأسطر المكررة')),
                OutlinedButton(onPressed: () => refresh(() {
                  output = text.replaceAll(RegExp(r'[ \t]+'), ' ').replaceAll(RegExp(r'\n{3,}'), '\n\n').trim();
                }), child: const Text('تنسيق المسافات')),
                OutlinedButton(onPressed: () => refresh(() => output = text.trim()), child: const Text('تنظيف النص')),
              ]),
              if (output.isNotEmpty) ...[
                const SizedBox(height: 10),
                SelectableText(output),
                Align(alignment: Alignment.centerLeft, child: TextButton.icon(
                  onPressed: () => Clipboard.setData(ClipboardData(text: output)),
                  icon: const Icon(Icons.copy), label: const Text('نسخ الناتج'))),
              ],
            ])),
            actions: [FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('إغلاق'))],
          ),
        );
      }),
    );
    controller.dispose();
  }

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.rtl,
    child: Scaffold(
      appBar: AppBar(title: const Text('صندوق أدوات V64'), centerTitle: true),
      body: _loading ? const Center(child: CircularProgressIndicator()) : ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              gradient: const LinearGradient(begin: Alignment.topRight, end: Alignment.bottomLeft,
                colors: [Color(0xFF30256A), Color(0xFF171936), Color(0xFF12616B)]),
            ),
            child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('أدواتك الخاصة، بدون خدمات خارجية',
                style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              SizedBox(height: 6),
              Text('اليوميات والملاحظات تبقى على هذا الجهاز. المؤقتات والقرعة ومختبر النصوص تعمل محلياً.',
                style: TextStyle(color: Colors.white70, height: 1.5)),
            ]),
          ),
          const SizedBox(height: 12),
          _entrySection('يومياتي الخاصة', 'تدوينات شخصية محفوظة على الجهاز', Icons.menu_book_rounded, _journal, true),
          _entrySection('ملاحظاتي السريعة', 'ملاحظات محلية خاصة', Icons.sticky_note_2_rounded, _notes, false),
          _sectionCard('ساعة الإيقاف', 'قياس الوقت مع إيقاف واستئناف', Icons.timer_outlined,
            Column(children: [
              Text(_clock(_stopwatch, tenths: true), key: const ValueKey('v64-stopwatch-time'),
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
              Wrap(spacing: 8, children: [
                FilledButton(onPressed: _stopwatchRunning ? _pauseStopwatch : _startStopwatch,
                  child: Text(_stopwatchRunning ? 'إيقاف مؤقت' : 'ابدأ')),
                OutlinedButton(onPressed: _resetStopwatch, child: const Text('إعادة')),
              ]),
            ])),
          _sectionCard('مؤقت تنازلي', 'ضبط دقائق وتنبيه عند انتهاء الوقت', Icons.hourglass_bottom_rounded,
            Column(children: [
              Text(_clock(_countdown), key: const ValueKey('v64-countdown-time'),
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
              Wrap(spacing: 8, children: [
                FilledButton(onPressed: _toggleCountdown,
                  child: Text(_countdownRunning ? 'إيقاف مؤقت' : (_countdown == Duration.zero ? 'ضبط وابدأ' : 'استئناف'))),
                OutlinedButton(onPressed: _resetCountdown, child: const Text('تصفير')),
              ]),
            ])),
          Card(child: ListTile(leading: const CircleAvatar(child: Icon(Icons.casino_rounded)),
            title: const Text('قرعة الاختيارات'), subtitle: const Text('اختيار عشوائي من قائمة تكتبها'),
            trailing: const Icon(Icons.chevron_left), onTap: _randomPicker)),
          Card(child: ListTile(leading: const CircleAvatar(child: Icon(Icons.text_fields_rounded)),
            title: const Text('مختبر النصوص'), subtitle: const Text('عداد كلمات وحروف وتنظيف التكرار والمسافات'),
            trailing: const Icon(Icons.chevron_left), onTap: _textLab)),
        ],
      ),
    ),
  );

  Widget _sectionCard(String title, String subtitle, IconData icon, Widget child) => Card(
    child: Padding(padding: const EdgeInsets.all(16), child: Column(children: [
      Row(children: [CircleAvatar(child: Icon(icon)), const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
        ]))]),
      const SizedBox(height: 14), child,
    ])),
  );

  Widget _entrySection(String title, String subtitle, IconData icon, List<_V64Entry> entries, bool journal) =>
    _sectionCard(title, subtitle, icon, Column(children: [
      Align(alignment: Alignment.centerLeft, child: FilledButton.tonalIcon(
        onPressed: _loading ? null : () => _addEntry(journal),
        icon: const Icon(Icons.add), label: const Text('إضافة'))),
      if (entries.isEmpty) Padding(padding: const EdgeInsets.all(8),
        child: Text(journal ? 'ما كتبت أي يوميات بعد.' : 'ما عندك ملاحظات محفوظة بعد.')),
      ...entries.map((entry) => ListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(entry.text, maxLines: 2, overflow: TextOverflow.ellipsis),
        subtitle: Text(_dateLabel(entry.createdAt)),
        trailing: IconButton(tooltip: 'حذف', icon: const Icon(Icons.delete_outline),
          onPressed: () => _delete(entry, journal)),
      )),
    ]));

  String _dateLabel(String raw) {
    final date = DateTime.tryParse(raw)?.toLocal();
    if (date == null) return 'تاريخ غير معروف';
    return '${date.day}/${date.month}/${date.year} • ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}

class _V64Entry {
  final String id;
  final String text;
  final String createdAt;
  const _V64Entry({required this.id, required this.text, required this.createdAt});
  Map<String, String> toJson() => {'id': id, 'text': text, 'createdAt': createdAt};
  factory _V64Entry.fromJson(Map<String, dynamic> json) => _V64Entry(
    id: (json['id'] ?? '').toString(),
    text: (json['text'] ?? '').toString(),
    createdAt: (json['createdAt'] ?? '').toString(),
  );
}
