import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

/// Private, device-local collection of useful public links.
/// Passwords, tokens and links containing embedded credentials are rejected.
class V60LinkLibraryPage extends StatefulWidget {
  const V60LinkLibraryPage({super.key});

  @override
  State<V60LinkLibraryPage> createState() => _V60LinkLibraryPageState();
}

class _V60LinkLibraryPageState extends State<V60LinkLibraryPage> {
  static const _storageKey = 'v60_personal_link_library_v1';
  final _search = TextEditingController();
  final List<Map<String, String>> _items = [];
  String _category = 'الكل';
  bool _favoritesOnly = false;
  bool _loading = true;

  List<String> get _categories => [
    'الكل',
    ..._items.map((e) => e['category'] ?? 'عام').toSet().toList()..sort(),
  ];

  List<Map<String, String>> get _visible {
    final q = _search.text.trim().toLowerCase();
    return _items.where((e) {
      final categoryOk = _category == 'الكل' || e['category'] == _category;
      final favoriteOk = !_favoritesOnly || e['favorite'] == 'true';
      final text = '${e['title']} ${e['url']} ${e['note']} ${e['category']}'.toLowerCase();
      return categoryOk && favoriteOk && (q.isEmpty || text.contains(q));
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    try {
      final raw = jsonDecode(prefs.getString(_storageKey) ?? '[]') as List;
      _items.addAll(raw.whereType<Map>().map((e) =>
        e.map((k, v) => MapEntry(k.toString(), v.toString()))));
    } catch (_) {
      _items.clear();
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, jsonEncode(_items));
  }

  String? _validatedUrl(String raw) {
    final uri = Uri.tryParse(raw.trim());
    if (uri == null ||
        !{'http', 'https'}.contains(uri.scheme.toLowerCase()) ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty ||
        raw.trim().length > 2048) {
      return null;
    }
    return uri.toString();
  }

  Future<void> _add() async {
    final title = TextEditingController();
    final url = TextEditingController();
    final note = TextEditingController();
    final category = TextEditingController(text: 'عام');
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('إضافة رابط للمكتبة'),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(controller: title, maxLength: 70,
                decoration: const InputDecoration(labelText: 'اسم الرابط')),
              TextField(controller: url, keyboardType: TextInputType.url,
                decoration: const InputDecoration(labelText: 'الرابط (https أو http)')),
              TextField(controller: category, maxLength: 30,
                decoration: const InputDecoration(labelText: 'التصنيف')),
              TextField(controller: note, maxLength: 140,
                decoration: const InputDecoration(labelText: 'ملاحظة اختيارية')),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c, false),
              child: const Text('إلغاء')),
            FilledButton(onPressed: () => Navigator.pop(c, true),
              child: const Text('حفظ')),
          ],
        ),
      ),
    );
    final safeUrl = _validatedUrl(url.text);
    if (ok == true) {
      if (title.text.trim().isEmpty || safeUrl == null) {
        _message('اكتب اسماً ورابطاً صحيحاً يبدأ بـ http أو https.');
      } else {
        setState(() => _items.insert(0, {
          'id': DateTime.now().microsecondsSinceEpoch.toString(),
          'title': title.text.trim(),
          'url': safeUrl,
          'category': category.text.trim().isEmpty ? 'عام' : category.text.trim(),
          'note': note.text.trim(),
          'favorite': 'false',
        }));
        await _save();
        _message('انحفظ الرابط على جهازك.');
      }
    }
    title.dispose();
    url.dispose();
    note.dispose();
    category.dispose();
  }

  Future<void> _open(Map<String, String> item) async {
    final safeUrl = _validatedUrl(item['url'] ?? '');
    if (safeUrl == null) {
      _message('هذا الرابط غير صالح أو يحتوي بيانات دخول مضمّنة.');
      return;
    }
    final opened = await launchUrl(Uri.parse(safeUrl),
      mode: LaunchMode.externalApplication);
    if (!opened && mounted) _message('تعذر فتح الرابط على هذا الجهاز.');
  }

  Future<void> _toggleFavorite(Map<String, String> item) async {
    setState(() => item['favorite'] =
      item['favorite'] == 'true' ? 'false' : 'true');
    await _save();
  }

  Future<void> _delete(Map<String, String> item) async {
    final yes = await showDialog<bool>(context: context, builder: (c) =>
      Directionality(textDirection: TextDirection.rtl, child: AlertDialog(
        title: const Text('حذف الرابط؟'),
        content: Text('سيتم حذف «${item['title']}» من مكتبتك المحلية.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false),
            child: const Text('إلغاء')),
          FilledButton(onPressed: () => Navigator.pop(c, true),
            child: const Text('حذف')),
        ],
      )));
    if (yes == true) {
      setState(() => _items.remove(item));
      await _save();
    }
  }

  void _message(String value) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(value)));
  }

  @override
  Widget build(BuildContext context) {
    final visible = _visible;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('مكتبتي الشخصية للروابط'),
          actions: [
            IconButton(
              tooltip: _favoritesOnly ? 'عرض الكل' : 'المفضلة فقط',
              onPressed: () => setState(() => _favoritesOnly = !_favoritesOnly),
              icon: Icon(_favoritesOnly ? Icons.favorite : Icons.favorite_border),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _add,
          icon: const Icon(Icons.add_link),
          label: const Text('إضافة رابط'),
        ),
        body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(padding: const EdgeInsets.all(14), children: [
              Card(child: Padding(
                padding: const EdgeInsets.all(15),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('روابطك المهمة بمكان واحد',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 5),
                  const Text('احفظ مواقعك ومصادرك العامة ورتبها بتصنيفات. البيانات تبقى على هذا الجهاز.'),
                  const SizedBox(height: 10),
                  TextField(controller: _search,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      hintText: 'ابحث بالاسم أو الرابط أو الملاحظة'),
                  ),
                ]),
              )),
              const SizedBox(height: 8),
              SizedBox(height: 42, child: ListView(
                scrollDirection: Axis.horizontal,
                children: _categories.map((c) => Padding(
                  padding: const EdgeInsetsDirectional.only(end: 7),
                  child: ChoiceChip(label: Text(c), selected: _category == c,
                    onSelected: (_) => setState(() => _category = c)),
                )).toList(),
              )),
              if (visible.isEmpty)
                const Card(child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: Text('مكتبتك فارغة هنا. أضف أول رابط من الزر أدناه.')),
                ))
              else
                ...visible.map((item) => Card(
                  child: ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.link)),
                    title: Text(item['title'] ?? 'رابط',
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: Text(
                      '${item['category']} • ${item['url']}'
                      '${(item['note'] ?? '').isEmpty ? '' : '\n${item['note']}'}',
                      maxLines: 3, overflow: TextOverflow.ellipsis),
                    onTap: () => _open(item),
                    trailing: PopupMenuButton<String>(
                      onSelected: (v) {
                        if (v == 'open') _open(item);
                        if (v == 'favorite') _toggleFavorite(item);
                        if (v == 'copy') {
                          Clipboard.setData(ClipboardData(text: item['url'] ?? ''));
                          _message('تم نسخ الرابط.');
                        }
                        if (v == 'delete') _delete(item);
                      },
                      itemBuilder: (_) => [
                        const PopupMenuItem(value: 'open', child: Text('فتح الرابط')),
                        PopupMenuItem(value: 'favorite',
                          child: Text(item['favorite'] == 'true' ? 'إزالة من المفضلة' : 'إضافة للمفضلة')),
                        const PopupMenuItem(value: 'copy', child: Text('نسخ الرابط')),
                        const PopupMenuItem(value: 'delete', child: Text('حذف')),
                      ],
                    ),
                  ),
                )),
              const SizedBox(height: 70),
            ]),
      ),
    );
  }
}
