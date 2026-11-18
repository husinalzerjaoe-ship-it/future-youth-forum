import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A private, device-local daily action board. It deliberately does not write
/// personal notes or routines to Firestore.
class V61DailyFocusPage extends StatefulWidget {
  const V61DailyFocusPage({super.key});

  @override
  State<V61DailyFocusPage> createState() => _V61DailyFocusPageState();
}

class _V61DailyFocusPageState extends State<V61DailyFocusPage> {
  static const _storageKey = 'v61_daily_focus_items';
  final List<_FocusItem> _items = [];
  bool _loading = true;
  bool _saving = false;

  int get _done => _items.where((item) => item.done).length;
  double get _progress => _items.isEmpty ? 0 : _done / _items.length;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw != null) {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          _items
            ..clear()
            ..addAll(decoded.whereType<Map>().map(
              (item) => _FocusItem.fromJson(Map<String, dynamic>.from(item)),
            ));
        }
      }
    } catch (_) {
      // A damaged local cache must not prevent the rest of the app opening.
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _persist() async {
    if (_saving) return;
    _saving = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _storageKey,
        jsonEncode(_items.map((item) => item.toJson()).toList()),
      );
    } finally {
      _saving = false;
    }
  }

  Future<void> _addItem() async {
    final controller = TextEditingController();
    final title = await showDialog<String>(
      context: context,
      builder: (dialogContext) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('أضف هدفاً لليوم'),
          content: TextField(
            controller: controller,
            autofocus: true,
            maxLength: 90,
            textInputAction: TextInputAction.done,
            onSubmitted: (value) => Navigator.pop(dialogContext, value.trim()),
            decoration: const InputDecoration(
              hintText: 'مثلاً: أقرأ 10 صفحات',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, controller.text.trim()),
              child: const Text('إضافة'),
            ),
          ],
        ),
      ),
    );
    controller.dispose();
    if (!mounted || title == null || title.trim().isEmpty) return;
    setState(() => _items.insert(0, _FocusItem(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      title: title.trim(),
      done: false,
    )));
    await _persist();
  }

  Future<void> _toggle(_FocusItem item, bool value) async {
    setState(() => item.done = value);
    await _persist();
  }

  Future<void> _delete(_FocusItem item) async {
    setState(() => _items.removeWhere((entry) => entry.id == item.id));
    await _persist();
  }

  Future<void> _clearCompleted() async {
    setState(() => _items.removeWhere((item) => item.done));
    await _persist();
  }

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.rtl,
    child: Scaffold(
      appBar: AppBar(
        title: const Text('تركيزي اليومي V61'),
        actions: [
          if (_items.any((item) => item.done))
            IconButton(
              tooltip: 'حذف المنجز',
              onPressed: _clearCompleted,
              icon: const Icon(Icons.cleaning_services_outlined),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _loading ? null : _addItem,
        icon: const Icon(Icons.add_rounded),
        label: const Text('هدف جديد'),
      ),
      body: _loading
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  gradient: const LinearGradient(
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                    colors: [Color(0xFF30256A), Color(0xFF171936), Color(0xFF12616B)],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(children: [
                      Icon(Icons.track_changes_rounded, color: Colors.white, size: 30),
                      SizedBox(width: 10),
                      Expanded(child: Text(
                        'خطوة صغيرة كل يوم',
                        style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                      )),
                    ]),
                    const SizedBox(height: 8),
                    Text(
                      _items.isEmpty ? 'اكتب أول هدف تريد إنجازه اليوم.' : 'أنجزت $_done من ${_items.length} أهداف اليوم',
                      style: const TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 14),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: LinearProgressIndicator(
                        value: _progress,
                        minHeight: 10,
                        backgroundColor: Colors.white24,
                        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF65E6C4)),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${(_progress * 100).round()}% مكتمل',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Row(children: [
                const Icon(Icons.today_rounded),
                const SizedBox(width: 8),
                const Expanded(child: Text('قائمة أهدافك', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
                Text('${_items.length} هدف', style: TextStyle(color: Theme.of(context).hintColor)),
              ]),
              const SizedBox(height: 10),
              if (_items.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(children: [
                      Icon(Icons.flag_outlined, size: 42, color: Theme.of(context).colorScheme.primary),
                      const SizedBox(height: 10),
                      const Text('ما عندك أهداف مضافة بعد', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 5),
                      Text('اضغط «هدف جديد» ورتّب يومك على راحتك.', style: TextStyle(color: Theme.of(context).hintColor)),
                    ]),
                  ),
                )
              else
                ..._items.map((item) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: Checkbox(
                      value: item.done,
                      onChanged: (value) => _toggle(item, value ?? false),
                    ),
                    title: Text(
                      item.title,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        decoration: item.done ? TextDecoration.lineThrough : null,
                        color: item.done ? Theme.of(context).hintColor : null,
                      ),
                    ),
                    subtitle: Text(item.done ? 'تم الإنجاز' : 'بانتظار الإنجاز'),
                    trailing: IconButton(
                      tooltip: 'حذف الهدف',
                      onPressed: () => _delete(item),
                      icon: const Icon(Icons.delete_outline_rounded),
                    ),
                  ),
                )),
              const SizedBox(height: 12),
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.lock_outline_rounded, color: Colors.teal),
                      SizedBox(width: 10),
                      Expanded(child: Text(
                        'خصوصيتك محفوظة: الأهداف تُخزّن على هذا الجهاز فقط، ولا تُرفع إلى حسابك أو إلى Firestore.',
                        style: TextStyle(height: 1.5),
                      )),
                    ],
                  ),
                ),
              ),
            ],
          ),
    ),
  );
}

class _FocusItem {
  _FocusItem({required this.id, required this.title, required this.done});

  final String id;
  final String title;
  bool done;

  factory _FocusItem.fromJson(Map<String, dynamic> json) => _FocusItem(
    id: json['id'] as String? ?? DateTime.now().microsecondsSinceEpoch.toString(),
    title: json['title'] as String? ?? '',
    done: json['done'] == true,
  );

  Map<String, dynamic> toJson() => {'id': id, 'title': title, 'done': done};
}
