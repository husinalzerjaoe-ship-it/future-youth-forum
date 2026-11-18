import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'iptv_center.dart';
import 'premium_media_hub.dart';
import 'v54_world_community.dart';
import 'knowledge_corner.dart';
import 'community_events.dart';

/// V56 private journals are device-local and scoped to the signed-in account.
class V56FutureWorldPage extends StatefulWidget {
  const V56FutureWorldPage({super.key});
  @override
  State<V56FutureWorldPage> createState() => _V56FutureWorldPageState();
}

class _V56FutureWorldPageState extends State<V56FutureWorldPage> {
  static const accent = Color(0xFF806BFF);
  static const prompts = [
    'شنو أجمل ذكرى تتمنى تبقى وياك دائماً؟',
    'إذا تتعلم مهارة جديدة، شنو تختار؟',
    'شنو مكان تتمنى تزوره وليش؟',
    'شنو فكرة صغيرة ممكن تخلي يومك أحسن؟',
    'أي كتاب أو قصة تتمنى تقرأها قريباً؟',
    'شنو إنجاز بسيط تفتخر بيه؟',
    'شنو الشي اللي تحب تتذكره من هالسنة؟',
  ];
  static const samples = [
    ['النافذة التي لا تنام', 'غموض', 'في آخر الممر كانت نافذة صغيرة تطل على شارع هادئ. كل ليلة يظهر خلف زجاجها ضوء دافئ، رغم أن البيت مهجور منذ سنوات. تركت ليان رسالة على العتبة تسأل: من هناك؟ في الصباح وجدت ورقة تقول: أنا أحرس الذكريات التي نسيها أصحابها. عادت في الليلة التالية ومعها دفتر، وبدأت تكتب الحكايات التي سمعتها من أهل الحي.'],
    ['مدينة فوق الغيم', 'فانتازيا', 'كان المسافر يحمل خريطة لا تظهر إلا تحت ضوء القمر. قادته إلى تل مرتفع، وهناك رأى سلماً من ضباب يصعد إلى مدينة معلقة فوق الغيوم. لم تكن المدينة تبحث عن أبطال، بل عن شخص يعرف كيف يصغي. جلس في الساحة واستمع إلى حكايات الناس حتى طلعت الشمس. عندها تحولت الخريطة إلى صفحة بيضاء، لكنه أدرك أن رحلته الحقيقية بدأت للتو.'],
    ['رسالة من الغد', 'خيال علمي', 'وصلت رسالة مؤرخة بعد عشر سنوات. لم تحمل سراً كبيراً، بل سؤالاً واحداً: هل ما زلت تحتفظ بالأشياء التي تحبها؟ قرر صاحب الرسالة أن يخصص وقتاً لأصدقائه وقراءته وأفكاره. وفي المساء كتب رداً قصيراً: سأحاول أن أكون شخصاً لا يندم على الأيام التي عاشها.'],
  ];

  bool loading = true;
  List<Map<String, dynamic>> dreams = [];
  List<Map<String, dynamic>> memories = [];
  List<Map<String, dynamic>> stories = [];
  int readCount = 0;
  String get prefix => 'v56_' + (FirebaseAuth.instance.currentUser?.uid ?? 'guest') + '_';

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    List<Map<String, dynamic>> read(String key) {
      try {
        final raw = p.getString(prefix + key);
        if (raw == null) return [];
        return (jsonDecode(raw) as List).whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
      } catch (_) { return []; }
    }
    if (!mounted) return;
    setState(() {
      dreams = read('dreams'); memories = read('memories'); stories = read('stories');
      readCount = p.getInt(prefix + 'read_count') ?? 0; loading = false;
    });
  }

  Future<void> _save(String key, List<Map<String, dynamic>> list) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(prefix + key, jsonEncode(list));
  }

  Future<void> _add(String kind, String key, List<Map<String, dynamic>> old,
      ValueChanged<List<Map<String, dynamic>>> update, String hint) async {
    final title = TextEditingController();
    final body = TextEditingController();
    final ok = await showDialog<bool>(context: context, builder: (ctx) => Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        title: Text(kind),
        content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: title, decoration: const InputDecoration(labelText: 'العنوان')),
          const SizedBox(height: 10),
          TextField(controller: body, minLines: 4, maxLines: 8,
            decoration: InputDecoration(labelText: hint, border: const OutlineInputBorder())),
        ])),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('حفظ')),
        ],
      ),
    ));
    final t = title.text.trim().isEmpty ? kind : title.text.trim();
    final b = body.text.trim();
    title.dispose(); body.dispose();
    if (ok != true || b.isEmpty) return;
    final next = <Map<String, dynamic>>[
      {'title': t, 'body': b, 'createdAt': DateTime.now().toIso8601String()},
      ...old,
    ];
    update(next); await _save(key, next);
  }

  Future<void> _delete(String key, List<Map<String, dynamic>> old, int i,
      ValueChanged<List<Map<String, dynamic>>> update) async {
    final next = [...old]..removeAt(i);
    update(next); await _save(key, next);
  }

  String _date(dynamic value) {
    final d = DateTime.tryParse(value?.toString() ?? '')?.toLocal();
    if (d == null) return '';
    return d.year.toString() + '/' + d.month.toString().padLeft(2, '0') + '/' + d.day.toString().padLeft(2, '0');
  }

  void _reader(String title, String body, String category) {
    showDialog<void>(context: context, builder: (ctx) => Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        title: Text(title),
        content: SizedBox(width: 520, child: SingleChildScrollView(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [Chip(label: Text(category)), SelectableText(body, style: const TextStyle(height: 1.8))],
        ))),
        actions: [
          TextButton.icon(onPressed: () {
            Clipboard.setData(ClipboardData(text: title + '\n\n' + body));
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم نسخ النص')));
          }, icon: const Icon(Icons.copy), label: const Text('نسخ')),
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إغلاق')),
        ],
      ),
    ));
  }

  Widget _heading(String title, String subtitle, IconData icon) => Padding(
    padding: const EdgeInsets.fromLTRB(2, 22, 2, 10),
    child: Row(children: [
      CircleAvatar(backgroundColor: accent.withOpacity(.16), foregroundColor: accent, child: Icon(icon)),
      const SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        Text(subtitle, style: TextStyle(fontSize: 12, color: Theme.of(context).hintColor)),
      ])),
    ]),
  );

  Widget _card(IconData icon, String title, String subtitle, VoidCallback action) => Card(
    clipBehavior: Clip.antiAlias,
    child: ListTile(
      leading: Icon(icon, color: accent), title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle), trailing: const Icon(Icons.chevron_left),
      onTap: action,
    ),
  );

  Widget _entries(List<Map<String, dynamic>> data, String key,
      ValueChanged<List<Map<String, dynamic>>> update, String empty, IconData icon) {
    if (data.isEmpty) return Card(child: Padding(
      padding: const EdgeInsets.all(16), child: Text(empty)));
    return Column(children: List.generate(data.length, (i) {
      final item = data[i]; final title = item['title']?.toString() ?? 'بدون عنوان';
      final body = item['body']?.toString() ?? '';
      return Card(child: ListTile(
        leading: Icon(icon, color: accent), title: Text(title),
        subtitle: Text(_date(item['createdAt']) + ' • ' + body, maxLines: 2, overflow: TextOverflow.ellipsis),
        onTap: () => _reader(title, body, 'من دفترك الخاص'),
        trailing: PopupMenuButton<String>(
          onSelected: (v) {
            if (v == 'copy') {
              Clipboard.setData(ClipboardData(text: title + '\n\n' + body));
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم النسخ')));
            } else { _delete(key, data, i, update); }
          },
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'copy', child: Text('نسخ')),
            PopupMenuItem(value: 'delete', child: Text('حذف')),
          ],
        ),
      ));
    }));
  }

  @override
  Widget build(BuildContext context) {
    final prompt = prompts[DateTime.now().day % prompts.length];
    return Directionality(textDirection: TextDirection.rtl, child: Scaffold(
      appBar: AppBar(title: const Text('عالم المستقبل V56'), actions: [
        IconButton(onPressed: _load, icon: const Icon(Icons.refresh), tooltip: 'تحديث'),
      ]),
      body: loading ? const Center(child: CircularProgressIndicator()) : ListView(
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 30),
        children: [
          Container(padding: const EdgeInsets.all(18), decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: const LinearGradient(colors: [Color(0xFF292052), Color(0xFF171936), Color(0xFF153B55)]),
          ), child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('مساحة جديدة لأفكارك وذكرياتك', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('دفاتر خاصة، قصص أصلية، واختصارات لمراكز الترفيه الموجودة.', style: TextStyle(color: Colors.white70, height: 1.5)),
          ])),
          _heading('حلمي والذكريات', 'دفاتر نصية خاصة على هذا الجهاز', Icons.auto_awesome),
          _card(Icons.nightlight_round, 'دفتر الأحلام', 'سجل حلمك واحتفظ به كذكرى خاصة', () => _add('تسجيل حلم', 'dreams', dreams, (v) => setState(() => dreams = v), 'اكتب تفاصيل الحلم...')),
          _entries(dreams, 'dreams', (v) => setState(() => dreams = v), 'دفتر الأحلام فارغ. أضف أول حلم من الزر أعلاه.', Icons.nightlight_outlined),
          _card(Icons.photo_album, 'ألبوم الذكريات', 'احفظ المواقف والنصوص المهمة', () => _add('ذكرى جديدة', 'memories', memories, (v) => setState(() => memories = v), 'اكتب الذكرى...')),
          _entries(memories, 'memories', (v) => setState(() => memories = v), 'ألبومك فارغ حالياً.', Icons.bookmark_added),
          _card(Icons.mail_lock, 'رسالة إلى المستقبل', 'اكتب رسالة لنفسك واحتفظ بها في دفتر الذكريات', () => _add('رسالة إلى المستقبل', 'memories', memories, (v) => setState(() => memories = v), 'شنو تحب تكول لنفسك بالمستقبل؟')),
          _heading('مكتبة القصص والروايات', 'قصص أصلية قصيرة وكتاباتك الخاصة', Icons.menu_book),
          ...samples.map((s) => _card(Icons.auto_stories, s[0], s[1], () {
            _reader(s[0], s[2], s[1]);
            final next = readCount + 1;
            setState(() => readCount = next);
            SharedPreferences.getInstance().then((p) => p.setInt(prefix + 'read_count', next));
          })),
          _card(Icons.edit_note, 'أضف قصتك الخاصة', 'اكتب قصة واحفظها محلياً', () => _add('قصة جديدة', 'stories', stories, (v) => setState(() => stories = v), 'اكتب قصتك الأصلية...')),
          _entries(stories, 'stories', (v) => setState(() => stories = v), 'ما أضفت قصصك بعد.', Icons.book),
          Card(child: ListTile(leading: const Icon(Icons.local_fire_department, color: accent),
            title: const Text('تحدي القراءة'), subtitle: Text('فتحت ' + readCount.toString() + ' نصوص من المكتبة على هذا الجهاز'))),
          _heading('مركز الترفيه والاكتشاف', 'اختصارات للأنظمة الموجودة بدون استبدالها', Icons.explore),
          _card(Icons.live_tv, 'مركز IPTV والقنوات', 'افتح قوائم M3U وEPG ومركز القنوات الموجود', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const IptvCenterPage()))),
          _card(Icons.movie_filter, 'مكتبة الوسائط والمشغّل', 'الصوت والفيديو ومكتبتك الحالية', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PremiumMediaHubPage()))),
          _card(Icons.public, 'عالم المجتمع V54', 'الإشعارات والفعاليات والإنجازات', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const V54WorldCommunityPage()))),
          _card(Icons.lightbulb_outline, 'ركن المعرفة', 'الاستكشاف والمحتوى المعرفي', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const KnowledgeCornerPage()))),
          _card(Icons.event_available, 'فعاليات الملتقى', 'تقويم الفعاليات والأنشطة', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CommunityEventsPage()))),
          _heading('سؤال اليوم', 'فكرة للنقاش أو الكتابة', Icons.question_answer),
          Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(prompt, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 10),
              Align(alignment: Alignment.centerLeft, child: OutlinedButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: prompt));
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم نسخ سؤال اليوم')));
                }, icon: const Icon(Icons.copy), label: const Text('نسخ السؤال'),
              )),
            ],
          ))),
          const SizedBox(height: 12),
          Text('الخصوصية: هذه الدفاتر تحفظ محلياً على جهازك ولا تُنشر تلقائياً. لا توجد مزامنة سحابية أو نسخ احتياطي لها في هذا الإصدار؛ قد تفقدها عند حذف بيانات التطبيق أو تبديل الجهاز.',
            style: TextStyle(fontSize: 12, color: Theme.of(context).hintColor, height: 1.5)),
        ],
      ),
    ));
  }
}
