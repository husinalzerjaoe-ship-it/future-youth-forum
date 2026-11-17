import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FutureLifeHubPage extends StatefulWidget {
  const FutureLifeHubPage({super.key});
  @override
  State<FutureLifeHubPage> createState() => _FutureLifeHubPageState();
}

class _FutureLifeHubPageState extends State<FutureLifeHubPage> {
  static const _names = <String>[
    'مخطط اليوم','أهدافي الكبيرة','متابعة العادات','دفتر اليوميات','قائمة القراءة',
    'مسار التعلّم','أفكار إبداعية','قائمة المشاهدة','قائمة الألعاب','قائمة الوصفات',
    'قائمة المشتريات','أماكن أتمنى زيارتها','لحظات ممتنة لها','رسائل تشجيع لنفسي',
    'مشاريع صغيرة','تحديات أسبوعية','أسئلة أبحث عنها','مفكرة المناسبات','دفتر الاقتباسات','أفكار للملتقى',
    'مخطط الدراسة','مراجعة الامتحانات','متابعة المشاريع','ميزانية شخصية','مصروفاتي اليومية',
    'أهداف القراءة','مفردات اللغة','كلمات جديدة','أفكار محتوى','مخطط السفر',
    'قائمة تجهيز السفر','أعمال المنزل','تنظيم الغرفة','العناية بالنباتات','رعاية الحيوانات الأليفة',
    'وجبات الأسبوع','تحضير وجبات','مكونات ناقصة','دعوات ومناسبات','هدايا وأفكار',
    'أفلام العائلة','بودكاست أسمعه','قنوات مفيدة','روابط مهمة','ملاحظات سريعة',
    'أسماء ومصطلحات','أفكار ألعاب','أسئلة مسابقات','ألغاز أحلها','إنجازات الأسبوع',
    'أشياء أتعلمها','مهارات أتدرب عليها','أشخاص أود شكرهم','أعمال تطوعية','مبادرات مجتمعية',
    'اقتراحات تطوير','ذكريات جميلة','أهداف الشهر'
  ];
  static const _descriptions = <String>[
    'رتّب يومك على شكل مهام','قسّم الهدف إلى خطوات صغيرة','تابع العادات الإيجابية',
    'احتفظ بأفكارك الخاصة على جهازك','سجّل الكتب والقصص','اجمع المهارات التي تتعلمها',
    'لا تدع الأفكار الجميلة تضيع','رتّب ما تريد مشاهدته','احفظ الألعاب التي تريد تجربتها',
    'احفظ وصفات تريد تجربتها','جهّز قائمة احتياجاتك','دوّن الأماكن التي تحلم بزيارتها',
    'سجّل الأشياء الجميلة في يومك','اكتب عبارات تشجيع لنفسك','تابع أفكار مشاريعك وهواياتك',
    'اختر تحديات بسيطة','اجمع الأسئلة التي تريد جوابها','دوّن المناسبات المهمة',
    'احتفظ بالعبارات التي تعجبك','اقترح تطويرات للمجتمع',
    'نظّم الدروس والواجبات','تابع المواد والمواضيع التي تراجعها','قسّم مشروعك إلى مهام','سجّل ميزانيتك وخطط الإنفاق','دوّن مصروفاتك لتراجعها',
    'تابع الكتب التي أنهيتها','اجمع الكلمات التي تتعلمها','احفظ الكلمات ومعانيها','خطط لمنشوراتك وأفكارك','رتّب رحلتك القادمة',
    'جهّز مستلزمات الرحلة','تابع المهام المنزلية','رتّب احتياجات غرفتك','سجّل مواعيد العناية بالنباتات','نظّم احتياجات حيوانك الأليف',
    'خطط لوجبات الأسبوع','حضّر قائمة الوجبات مسبقاً','دوّن ما ينقصك من مكونات','تابع الدعوات والمناسبات','اجمع أفكار الهدايا',
    'قائمة مشاهدة عائلية','احفظ حلقات البودكاست','اجمع القنوات المفيدة','احفظ الروابط المهمة','دوّن ملاحظاتك السريعة',
    'احفظ الأسماء والمصطلحات','ابتكر أفكاراً لألعاب جديدة','جهّز أسئلة للمسابقات','اجمع الألغاز التي تريد حلها','سجّل إنجازاتك',
    'دوّن الأشياء الجديدة التي تتعلمها','تابع المهارات التي تتدرب عليها','اكتب أسماء من تريد شكرهم','نظّم أفكار التطوع','خطط لمبادرات تخدم المجتمع',
    'اجمع اقتراحات تحسين الملتقى','احتفظ بالذكريات التي تحبها','خطط لأهداف الشهر القادم'
  ];
  final Map<String, List<String>> _items = {};
  bool _loading = true;
  String _query = '';

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    for (final name in _names) {
      _items[name] = prefs.getStringList('v36_life_' + name) ?? <String>[];
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('v36_life_' + name, _items[name] ?? <String>[]);
  }

  Future<void> _add(String name) async {
    final controller = TextEditingController();
    final value = await showDialog<String>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: Text(name),
          content: TextField(controller: controller, autofocus: true, maxLines: 3,
            decoration: const InputDecoration(hintText: 'اكتب هنا...', border: OutlineInputBorder())),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
            FilledButton(onPressed: () => Navigator.pop(ctx, controller.text.trim()), child: const Text('حفظ')),
          ],
        ),
      ),
    );
    controller.dispose();
    if (value == null || value.isEmpty || !mounted) return;
    setState(() => (_items[name] ??= <String>[]).insert(0, value));
    await _save(name);
  }

  Future<void> _remove(String name, int index) async {
    setState(() => _items[name]?.removeAt(index));
    await _save(name);
  }

  IconData _icon(int i) {
    const icons = <IconData>[
      Icons.event_note,Icons.flag,Icons.repeat,Icons.book,Icons.menu_book,
      Icons.school,Icons.lightbulb,Icons.movie,Icons.sports_esports,Icons.restaurant,
      Icons.shopping_bag,Icons.place,Icons.favorite,Icons.auto_awesome,Icons.build,
      Icons.workspace_premium,Icons.quiz,Icons.calendar_month,Icons.format_quote,Icons.groups
    ];
    return icons[i % icons.length];
  }

  @override
  Widget build(BuildContext context) {
    final filtered = List<int>.generate(_names.length, (i) => i)
      .where((i) => _names[i].contains(_query) || _descriptions[i].contains(_query)).toList();
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('مركز حياة المستقبل')),
        body: _loading ? const Center(child: CircularProgressIndicator()) : CustomScrollView(slivers: [
          SliverToBoxAdapter(child: Container(
            margin: const EdgeInsets.all(14), padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(22),
              gradient: const LinearGradient(colors: [Color(0xFF34245F), Color(0xFF14505A)])),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Icon(Icons.auto_awesome, size: 34, color: Color(0xFFFFD18A)),
              const SizedBox(height: 8),
              const Text('مساحتك الخاصة للتخطيط والإبداع', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900)),
              const SizedBox(height: 5),
              const Text('57 أداة لتنظيم حياتك ودراستك وهواياتك ومشاريعك. تُحفظ بياناتك محلياً على جهازك.'),
              const SizedBox(height: 10),
              Text('مجموع العناصر المحفوظة: ' + _items.values.fold<int>(0, (sum, list) => sum + list.length).toString(),
                style: const TextStyle(color: Color(0xFFFFD18A), fontWeight: FontWeight.bold)),
            ]),
          )),
          SliverToBoxAdapter(child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: TextField(onChanged: (v) => setState(() => _query = v.trim()),
              decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'ابحث عن أداة...', border: OutlineInputBorder())),
          )),
          SliverPadding(padding: const EdgeInsets.all(14), sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, mainAxisSpacing: 10, crossAxisSpacing: 10, childAspectRatio: 1.12),
            delegate: SliverChildBuilderDelegate((context, index) {
              final i = filtered[index];
              final count = _items[_names[i]]?.length ?? 0;
              return Card(child: InkWell(
                onTap: () => _open(_names[i], _descriptions[i]),
                child: Padding(padding: const EdgeInsets.all(13), child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Icon(_icon(i), size: 27, color: const Color(0xFFFFC77D)),
                    const Spacer(),
                    Text(_names[i], maxLines: 2, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 4),
                    Text(_descriptions[i], maxLines: 2, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11, color: Colors.white70)),
                    const SizedBox(height: 5),
                    Text(count.toString() + ' محفوظ', style: const TextStyle(fontSize: 10, color: Color(0xFFFFD18A))),
                  ],
                )),
              ));
            }, childCount: filtered.length),
          )),
        ]),
      ),
    );
  }

  void _open(String name, String description) {
    showModalBottomSheet<void>(
      context: context, isScrollControlled: true, backgroundColor: const Color(0xFF191B30),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (sheet) => StatefulBuilder(builder: (context, refresh) {
        final list = _items[name] ?? <String>[];
        return Directionality(
          textDirection: TextDirection.rtl,
          child: SafeArea(child: Padding(
            padding: EdgeInsets.fromLTRB(18, 18, 18, MediaQuery.of(context).viewInsets.bottom + 18),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Row(children: [
                Expanded(child: Text(name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
                IconButton(onPressed: () => Navigator.pop(sheet), icon: const Icon(Icons.close)),
              ]),
              Text(description, style: const TextStyle(color: Colors.white70)),
              const SizedBox(height: 12),
              if (list.isEmpty)
                const Padding(padding: EdgeInsets.all(20), child: Text('ماكو عناصر محفوظة بعد. أضف أول عنصر!'))
              else
                ConstrainedBox(constraints: const BoxConstraints(maxHeight: 300),
                  child: ListView.builder(shrinkWrap: true, itemCount: list.length, itemBuilder: (context, i) =>
                    ListTile(leading: CircleAvatar(child: Text((i + 1).toString())),
                      title: Text(list[i]),
                      trailing: IconButton(icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                        onPressed: () async { await _remove(name, i); refresh(() {}); }))),
                ),
              const SizedBox(height: 10),
              SizedBox(width: double.infinity, child: FilledButton.icon(
                onPressed: () { Navigator.pop(sheet); _add(name); },
                icon: const Icon(Icons.add), label: const Text('إضافة عنصر'))),
            ]),
          )),
        );
      }),
    );
  }
}
