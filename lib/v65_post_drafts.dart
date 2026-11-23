import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// V65 offline-first post drafts. Nothing is published or uploaded automatically.
class V65PostDraftsPage extends StatefulWidget {
  const V65PostDraftsPage({super.key});

  @override
  State<V65PostDraftsPage> createState() => _V65PostDraftsPageState();
}

class _V65PostDraftsPageState extends State<V65PostDraftsPage> {
  static const _storageKey = 'v65_offline_post_drafts';
  final List<_V65Draft> _drafts = [];
  bool _loading = true;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _loadDrafts();
  }

  Future<void> _loadDrafts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw != null) {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          _drafts.addAll(decoded.whereType<Map>().map(
            (item) => _V65Draft.fromJson(Map<String, dynamic>.from(item)),
          ));
        }
      }
    } catch (_) {
      // A damaged local cache must not prevent the rest of the app from opening.
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _storageKey,
      jsonEncode(_drafts.map((draft) => draft.toJson()).toList()),
    );
  }

  Future<void> _editDraft([_V65Draft? existing]) async {
    final titleController = TextEditingController(text: existing?.title ?? '');
    final bodyController = TextEditingController(text: existing?.body ?? '');
    final result = await showDialog<_V65Draft>(
      context: context,
      builder: (dialogContext) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: Text(existing == null ? 'مسودة منشور جديدة' : 'تعديل المسودة'),
          content: SizedBox(
            width: 520,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    maxLength: 90,
                    decoration: const InputDecoration(
                      labelText: 'عنوان المسودة',
                      hintText: 'مثلاً: فكرة للنقاش',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: bodyController,
                    minLines: 5,
                    maxLines: 10,
                    maxLength: 6000,
                    decoration: const InputDecoration(
                      labelText: 'محتوى المنشور',
                      hintText: 'اكتب أفكارك هنا... ستبقى مسودة على جهازك',
                      alignLabelWithHint: true,
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('إلغاء'),
            ),
            FilledButton.icon(
              onPressed: () {
                final body = bodyController.text.trim();
                final title = titleController.text.trim();
                if (body.isEmpty) return;
                Navigator.pop(
                  dialogContext,
                  _V65Draft(
                    id: existing?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
                    title: title.isEmpty ? 'مسودة بدون عنوان' : title,
                    body: body,
                    updatedAt: DateTime.now().toIso8601String(),
                  ),
                );
              },
              icon: const Icon(Icons.save_outlined),
              label: const Text('حفظ المسودة'),
            ),
          ],
        ),
      ),
    );
    titleController.dispose();
    bodyController.dispose();
    if (!mounted || result == null) return;

    setState(() {
      final index = _drafts.indexWhere((draft) => draft.id == result.id);
      if (index < 0) {
        _drafts.insert(0, result);
      } else {
        _drafts[index] = result;
      }
      _drafts.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    });
    await _persist();
  }

  Future<void> _deleteDraft(_V65Draft draft) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('حذف المسودة؟'),
          content: Text('سيتم حذف «${draft.title}» من هذا الجهاز.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('حذف'),
            ),
          ],
        ),
      ),
    );
    if (confirmed != true) return;
    setState(() => _drafts.removeWhere((item) => item.id == draft.id));
    await _persist();
  }

  Future<void> _copyDraft(_V65Draft draft) async {
    await Clipboard.setData(ClipboardData(text: draft.body));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم نسخ محتوى المسودة')),
    );
  }

  String _dateLabel(String raw) {
    final date = DateTime.tryParse(raw)?.toLocal();
    if (date == null) return 'وقت غير معروف';
    return '${date.day}/${date.month}/${date.year} • '
        '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final normalizedQuery = _query.trim().toLowerCase();
    final visibleDrafts = _drafts.where((draft) {
      if (normalizedQuery.isEmpty) return true;
      return draft.title.toLowerCase().contains(normalizedQuery) ||
          draft.body.toLowerCase().contains(normalizedQuery);
    }).toList();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('مسودات منشوراتي V65'),
          centerTitle: true,
          actions: [
            IconButton(
              tooltip: 'مسودة جديدة',
              onPressed: _loading ? null : () => _editDraft(),
              icon: const Icon(Icons.add_box_outlined),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _loading ? null : () => _editDraft(),
          icon: const Icon(Icons.edit_note_rounded),
          label: const Text('مسودة جديدة'),
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 92),
                children: [
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF30256A), Color(0xFF12616B)],
                        begin: Alignment.topRight,
                        end: Alignment.bottomLeft,
                      ),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'أفكارك محفوظة حتى تكون جاهزاً للنشر',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 7),
                        Text(
                          'اكتب المنشور وعدّله لاحقاً وانسخ محتواه إلى شاشة النشر عندما تريد. لا يتم نشر أي شيء تلقائياً.',
                          style: TextStyle(color: Colors.white70, height: 1.5),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    onChanged: (value) => setState(() => _query = value),
                    decoration: InputDecoration(
                      hintText: 'ابحث في عناوين ومحتوى المسودات',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _query.isEmpty
                          ? null
                          : IconButton(
                              onPressed: () => setState(() => _query = ''),
                              icon: const Icon(Icons.clear),
                            ),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.drafts_outlined),
                      const SizedBox(width: 8),
                      Text('المسودات المحفوظة: ${_drafts.length}'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (visibleDrafts.isEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            const Icon(Icons.edit_document, size: 42),
                            const SizedBox(height: 10),
                            Text(
                              _drafts.isEmpty
                                  ? 'ما عندك مسودات بعد. احفظ أول فكرة تخطر ببالك.'
                                  : 'ما لقينا مسودات تطابق البحث.',
                              textAlign: TextAlign.center,
                            ),
                            if (_drafts.isEmpty) ...[
                              const SizedBox(height: 12),
                              FilledButton.icon(
                                onPressed: () => _editDraft(),
                                icon: const Icon(Icons.add),
                                label: const Text('إنشاء أول مسودة'),
                              ),
                            ],
                          ],
                        ),
                      ),
                    )
                  else
                    ...visibleDrafts.map(
                      (draft) => Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                draft.title,
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                draft.body,
                                maxLines: 4,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'آخر تعديل: ${_dateLabel(draft.updatedAt)}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              const Divider(),
                              Wrap(
                                spacing: 8,
                                runSpacing: 4,
                                children: [
                                  TextButton.icon(
                                    onPressed: () => _editDraft(draft),
                                    icon: const Icon(Icons.edit_outlined),
                                    label: const Text('تعديل'),
                                  ),
                                  TextButton.icon(
                                    onPressed: () => _copyDraft(draft),
                                    icon: const Icon(Icons.copy_outlined),
                                    label: const Text('نسخ'),
                                  ),
                                  TextButton.icon(
                                    onPressed: () => _deleteDraft(draft),
                                    icon: const Icon(Icons.delete_outline),
                                    label: const Text('حذف'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}

class _V65Draft {
  final String id;
  final String title;
  final String body;
  final String updatedAt;

  const _V65Draft({
    required this.id,
    required this.title,
    required this.body,
    required this.updatedAt,
  });

  Map<String, String> toJson() => {
        'id': id,
        'title': title,
        'body': body,
        'updatedAt': updatedAt,
      };

  factory _V65Draft.fromJson(Map<String, dynamic> json) => _V65Draft(
        id: (json['id'] ?? '').toString(),
        title: (json['title'] ?? 'مسودة بدون عنوان').toString(),
        body: (json['body'] ?? '').toString(),
        updatedAt: (json['updatedAt'] ?? '').toString(),
      );
}
