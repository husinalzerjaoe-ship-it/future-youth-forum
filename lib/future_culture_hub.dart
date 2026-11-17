import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FutureCultureHubPage extends StatefulWidget {
  const FutureCultureHubPage({super.key});

  @override
  State<FutureCultureHubPage> createState() => _FutureCultureHubPageState();
}

class _FutureCultureHubPageState extends State<FutureCultureHubPage> {
  static const _items = <({String category, String title, String text, String author})>[
    (category:'شعر',title:'درب الأمل',text:'نمضي ولو طال الطريقُ أمامنا\nفالفجر يولد من صميم ظلامِ',author:'من إبداع ملتقى المستقبل'),
    (category:'شعر',title:'أهل الدار',text:'يا دجلة الخير احفظي أحبابنا\nفالدار تكبر بالقلوب الطيبة',author:'من إبداع ملتقى المستقبل'),
    (category:'شعر',title:'صديق الطريق',text:'الصاحب اللي بالشدائد يبين\nيبقى أثره لو غاب عنك سنين',author:'من إبداع ملتقى المستقبل'),
    (category:'شعر',title:'حلم الشباب',text:'نرسم غداً بأيدينا ونبنيه\nوالعلم نور الدرب نهتدي بيه',author:'من إبداع ملتقى المستقبل'),
    (category:'شعر',title:'لغة الضاد',text:'حرفٌ إذا نطق الجمال تفتّحا\nوبكل بيتٍ للمعاني موطنا',author:'من إبداع ملتقى المستقبل'),
    (category:'شعر',title:'سلام للناس',text:'سلامٌ على قلبٍ يداوي خاطراً\nويزرع في درب المتعبين أمانا',author:'من إبداع ملتقى المستقبل'),
    (category:'اقتباسات',title:'عن البداية',text:'لا تنتظر الظروف المثالية؛ ابدأ بخطوة صغيرة واجعلها عادة.',author:'ملتقى المستقبل'),
    (category:'اقتباسات',title:'عن الصداقة',text:'الصداقة موقف يتكرر، لا كلمة تُقال مرة واحدة.',author:'ملتقى المستقبل'),
    (category:'اقتباسات',title:'عن التعلم',text:'كل سؤال صادق يفتح باباً جديداً للمعرفة.',author:'ملتقى المستقبل'),
    (category:'اقتباسات',title:'عن الوقت',text:'امنح وقتك لما يبنيك، لا لما يستهلك انتباهك.',author:'ملتقى المستقبل'),
    (category:'اقتباسات',title:'عن الاختلاف',text:'اختلاف الآراء فرصة للفهم، ما دام الاحترام حاضراً.',author:'ملتقى المستقبل'),
    (category:'اقتباسات',title:'عن النجاح',text:'الإنجاز الكبير يتكوّن من محاولات صغيرة متواصلة.',author:'ملتقى المستقبل'),
    (category:'أمثال وحكم',title:'مثل عراقي',text:'إيد وحده ما تصفّگ.',author:'من التراث الشعبي'),
    (category:'أمثال وحكم',title:'مثل عراقي',text:'الجار قبل الدار.',author:'من التراث الشعبي'),
    (category:'أمثال وحكم',title:'مثل شامي',text:'الصبر مفتاح الفرج.',author:'من التراث الشعبي'),
    (category:'أمثال وحكم',title:'مثل عربي',text:'من جدّ وجد، ومن زرع حصد.',author:'من التراث الشعبي'),
    (category:'أمثال وحكم',title:'حكمة',text:'الكلمة الطيبة تفتح باباً لا يفتحه العتاب.',author:'ملتقى المستقبل'),
    (category:'أمثال وحكم',title:'حكمة',text:'اسأل لتتعلم، وأنصت لتفهم.',author:'ملتقى المستقبل'),
    (category:'خواطر',title:'مساحة هدوء',text:'خذ استراحة قصيرة، رتّب أفكارك، ثم أكمل يومك بخطوة واضحة.',author:'ملتقى المستقبل'),
    (category:'خواطر',title:'رسالة لصديق',text:'وجودك الطيب يترك أثراً جميلاً حتى في الأيام العادية.',author:'ملتقى المستقبل'),
    (category:'خواطر',title:'رسالة للمستقبل',text:'إلى نفسي القادمة: أتمنى أن تجدي في هذه الأيام سبباً للفخر.',author:'ملتقى المستقبل'),
    (category:'خواطر',title:'بغداد',text:'في الأزقة حكايات، وعلى ضفاف النهر ذاكرة لا تشبه غيرها.',author:'ملتقى المستقبل'),
    (category:'خواطر',title:'الشام',text:'للشام حكاية في الياسمين، ولأهلها دفء في الكلام.',author:'ملتقى المستقبل'),
    (category:'تحديات كتابة',title:'تحدي الدقيقة',text:'اكتب قصة من ثلاثة أسطر تبدأ بعبارة: في ذلك الصباح تغيّر كل شيء.',author:'تحدي المجتمع'),
    (category:'تحديات كتابة',title:'تحدي الوصف',text:'صف مدينتك بخمس كلمات فقط، من دون ذكر اسمها.',author:'تحدي المجتمع'),
    (category:'تحديات كتابة',title:'تحدي الخيال',text:'تخيّل أن بإمكانك اختراع تطبيق واحد يفيد الناس؛ ما فكرته؟',author:'تحدي المجتمع'),
    (category:'تحديات كتابة',title:'تحدي الشعر',text:'اكتب بيتين عن الصداقة مستخدماً كلمتي نور وطريق.',author:'تحدي المجتمع'),
    (category:'تحديات كتابة',title:'تحدي الامتنان',text:'اكتب ثلاثة أشياء بسيطة جعلت يومك أفضل.',author:'تحدي المجتمع'),
  ];

  final _search = TextEditingController();
  String _category = 'الكل';
  Set<String> _favorites = {};
  bool _loaded = false;

  List<String> get _categories => ['الكل', ..._items.map((e) => e.category).toSet()];
  List<({String category, String title, String text, String author})> get _filtered {
    final q = _search.text.trim().toLowerCase();
    return _items.where((e) =>
      (_category == 'الكل' || e.category == _category) &&
      (q.isEmpty || '${e.title} ${e.text} ${e.author}'.toLowerCase().contains(q))
    ).toList();
  }

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() { _favorites = (prefs.getStringList('culture_favorites_v38') ?? []).toSet(); _loaded = true; });
  }

  Future<void> _toggleFavorite(String title, String text) async {
    final key = '$title::$text';
    setState(() { if (!_favorites.add(key)) _favorites.remove(key); });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('culture_favorites_v38', _favorites.toList());
  }

  @override
  void dispose() { _search.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final items = _filtered;
    return Directionality(textDirection: TextDirection.rtl, child: Scaffold(
      appBar: AppBar(title: const Text('مكتبة الشعر والاقتباسات')),
      body: Column(children: [
        Padding(padding: const EdgeInsets.fromLTRB(14, 12, 14, 8), child: TextField(
          controller: _search,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(prefixIcon: const Icon(Icons.search), hintText: 'ابحث عن شعر أو حكمة أو خاطرة...', border: OutlineInputBorder(borderRadius: BorderRadius.circular(16))),
        )),
        SizedBox(height: 48, child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 10), children: _categories.map((c) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: ChoiceChip(label: Text(c), selected: _category == c, onSelected: (_) => setState(() => _category = c)),
        )).toList())),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4), child: Row(children: [
          Text('${items.length} نصوص ومشاركات', style: Theme.of(context).textTheme.labelLarge),
          const Spacer(),
          Icon(Icons.bookmark, size: 17, color: Theme.of(context).colorScheme.primary),
          Text(' ${_favorites.length} محفوظة'),
        ])),
        Expanded(child: !_loaded ? const Center(child: CircularProgressIndicator()) : items.isEmpty
          ? const Center(child: Text('ما لقينا نتائج. جرّب كلمة ثانية.'))
          : ListView.builder(padding: const EdgeInsets.all(12), itemCount: items.length, itemBuilder: (context, index) {
            final item = items[index];
            final key = '${item.title}::${item.text}';
            final favorite = _favorites.contains(key);
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Chip(label: Text(item.category), visualDensity: VisualDensity.compact),
                  const Spacer(),
                  IconButton(tooltip: favorite ? 'إزالة من المحفوظات' : 'حفظ', onPressed: () => _toggleFavorite(item.title, item.text), icon: Icon(favorite ? Icons.bookmark : Icons.bookmark_border, color: favorite ? Theme.of(context).colorScheme.primary : null)),
                  IconButton(tooltip: 'مشاركة النص', onPressed: () => showDialog<void>(context: context, builder: (c) => AlertDialog(title: Text(item.title), content: SelectableText('${item.text}\n— ${item.author}'), actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text('إغلاق'))])), icon: const Icon(Icons.share_outlined)),
                ]),
                Text(item.title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                const SizedBox(height: 9),
                SelectableText(item.text, style: const TextStyle(fontSize: 16, height: 1.7)),
                const SizedBox(height: 8),
                Text(item.author, style: Theme.of(context).textTheme.labelSmall),
              ])),
            );
          })),
      ]),
    ));
  }
}
