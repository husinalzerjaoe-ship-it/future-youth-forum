import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FutureStyleStorePage extends StatefulWidget {
  const FutureStyleStorePage({super.key});
  @override
  State<FutureStyleStorePage> createState() => _FutureStyleStorePageState();
}

class _FutureStyleStorePageState extends State<FutureStyleStorePage> {
  static const _items = <({String id, String name, String category, String description, IconData icon, int color})>[
    (id:'nebula',name:'سديم بنفسجي',category:'ثيمات',description:'ألوان بنفسجية هادئة للعرض والمعاينة',icon:Icons.blur_on,color:0xFF8055D9),
    (id:'ocean',name:'محيط ليلي',category:'ثيمات',description:'درجات زرقاء عميقة',icon:Icons.water,color:0xFF1676B8),
    (id:'mint',name:'نعناع فضائي',category:'ثيمات',description:'لمسات خضراء منعشة',icon:Icons.eco,color:0xFF299B82),
    (id:'sunset',name:'غروب ذهبي',category:'ثيمات',description:'ألوان دافئة مستوحاة من الغروب',icon:Icons.wb_twilight,color:0xFFD17B35),
    (id:'rose',name:'وردي ملكي',category:'ثيمات',description:'طابع وردي أنيق',icon:Icons.local_florist,color:0xFFCA5B91),
    (id:'crown',name:'تاج القائد',category:'ألقاب',description:'شارة لقب للمعاينة الشخصية',icon:Icons.workspace_premium,color:0xFFE3AF35),
    (id:'star',name:'نجم المجتمع',category:'ألقاب',description:'شارة نجم للمعاينة الشخصية',icon:Icons.stars,color:0xFF4D9DDB),
    (id:'creator',name:'صانع الإبداع',category:'ألقاب',description:'شارة صانع محتوى',icon:Icons.draw,color:0xFF9A65D6),
    (id:'friend',name:'صديق الجميع',category:'ألقاب',description:'شارة اجتماعية ودية',icon:Icons.diversity_3,color:0xFF3EAA8A),
    (id:'goldframe',name:'إطار ذهبي',category:'إطارات',description:'إطار ذهبي للصورة الشخصية - معاينة',icon:Icons.crop_square,color:0xFFE0B34D),
    (id:'blueframe',name:'إطار سماوي',category:'إطارات',description:'إطار سماوي للصورة الشخصية - معاينة',icon:Icons.crop_square,color:0xFF48A9D8),
    (id:'purpleframe',name:'إطار بنفسجي',category:'إطارات',description:'إطار بنفسجي للصورة الشخصية - معاينة',icon:Icons.crop_square,color:0xFF9364D8),
    (id:'spark',name:'لمعة',category:'زخارف',description:'زخرفة نجوم للمعاينة',icon:Icons.auto_awesome,color:0xFFE5B94C),
    (id:'flame',name:'شعلة النشاط',category:'زخارف',description:'زخرفة حماسية للمعاينة',icon:Icons.local_fire_department,color:0xFFE87543),
    (id:'leaf',name:'ورقة هادئة',category:'زخارف',description:'زخرفة طبيعية للمعاينة',icon:Icons.spa,color:0xFF52A879),
    (id:'comet',name:'مذنب المستقبل',category:'زخارف',description:'زخرفة فضائية للمعاينة',icon:Icons.rocket_launch,color:0xFF6E81D9),
  ];

  String _category = 'الكل';
  String? _equipped;
  bool _ready = false;
  List<String> get _categories => ['الكل', ..._items.map((e) => e.category).toSet()];
  @override
  void initState() { super.initState(); _load(); }
  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() { _equipped = p.getString('future_style_equipped_v38'); _ready = true; });
  }
  Future<void> _equip(String id) async {
    final p = await SharedPreferences.getInstance();
    await p.setString('future_style_equipped_v38', id);
    if (!mounted) return;
    setState(() => _equipped = id);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم اختيار العنصر للمعاينة على هذا الجهاز')));
  }
  @override
  Widget build(BuildContext context) {
    final list = _items.where((e) => _category == 'الكل' || e.category == _category).toList();
    final matches = _items.where((e) => e.id == _equipped).toList();
    final selected = matches.isEmpty ? null : matches.first;
    return Directionality(textDirection: TextDirection.rtl, child: Scaffold(
      appBar: AppBar(title: const Text('متجر ستايل المستقبل')),
      body: !_ready ? const Center(child: CircularProgressIndicator()) : Column(children: [
        if (selected != null) Container(
          margin: const EdgeInsets.all(14), padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), color: Color(selected.color).withValues(alpha:.12), border: Border.all(color: Color(selected.color))),
          child: Row(children: [
            Icon(selected.icon, color: Color(selected.color), size: 34),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('اختيارك الحالي', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(selected.name),
            ])),
            const Icon(Icons.check_circle, color: Colors.green),
          ]),
        ),
        SizedBox(height: 48, child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 10), children: _categories.map((c) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: ChoiceChip(label: Text(c), selected: _category == c, onSelected: (_) => setState(() => _category = c)),
        )).toList())),
        Expanded(child: GridView.builder(
          padding: const EdgeInsets.all(12), itemCount: list.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: .92, crossAxisSpacing: 10, mainAxisSpacing: 10),
          itemBuilder: (context, i) {
            final item = list[i]; final active = item.id == _equipped;
            return Card(clipBehavior: Clip.antiAlias, child: InkWell(onTap: () => _equip(item.id), child: Padding(
              padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(child: Center(child: CircleAvatar(radius: 34, backgroundColor: Color(item.color).withValues(alpha:.16), child: Icon(item.icon, color: Color(item.color), size: 36)))),
                Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(item.description, maxLines: 2, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 6),
                SizedBox(width: double.infinity, child: FilledButton.tonal(
                  onPressed: () => _equip(item.id),
                  child: Text(active ? 'مختار ✓' : 'معاينة واختيار'),
                )),
              ]),
            )));
          },
        )),
        Padding(padding: const EdgeInsets.fromLTRB(14, 4, 14, 12), child: Text(
          'هذه نسخة أولية محلية للمعاينة والاختيار، وليست شراءً أو رصيداً حقيقياً. ربط العناصر بملف العضو ومزامنتها بين الأجهزة يحتاج توصيل قاعدة البيانات وقواعد الصلاحيات.',
          style: Theme.of(context).textTheme.bodySmall,
        )),
      ]),
    ));
  }
}
