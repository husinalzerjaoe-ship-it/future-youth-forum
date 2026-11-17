import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class IraqiRecipesPage extends StatefulWidget {
  const IraqiRecipesPage({super.key});
  @override
  State<IraqiRecipesPage> createState() => _IraqiRecipesPageState();
}

class _IraqiRecipesPageState extends State<IraqiRecipesPage> {
  final _search = TextEditingController();
  String _category = 'الكل';
  Set<String> _favorites = {};
  bool _loading = true;

  static const _categories = ['الكل','أكلات رئيسية','فطور','شوربات','مقبلات','معجنات','حلويات','مشروبات'];
  static const List<_Recipe> _recipes = [
    _Recipe('دولمة عراقية','أكلات رئيسية','90 دقيقة',['ورق عنب أو سلق','رز','لحم مفروم','بصل وطماطم','معجون طماطم','ليمون ودبس رمان'],['اخلط الرز واللحم والبصل والطماطم والتوابل.','احشِ الورق ولفّه باعتدال.','رتّب اللفائف في قدر وأضف الماء ومعجون الطماطم والليمون.','اطبخ على نار هادئة حتى ينضج الحشو.']),
    _Recipe('مسكوف عراقي','أكلات رئيسية','60 دقيقة',['سمك نهري منظف','ملح وبهارات','ليمون','بصل وطماطم'],['تبّل السمك بالملح والبهارات والليمون.','اشوه بحرارة مناسبة حتى ينضج من الداخل.','قدّمه مع البصل والطماطم والخبز والطرشي.']),
    _Recipe('قيمة نجفية','أكلات رئيسية','120 دقيقة',['حمص مجروش','لحم','بصل','معجون طماطم','ليمون أسود','بهارات'],['انقع الحمص ثم اسلقه حتى يلين.','اطبخ اللحم مع البصل والبهارات.','أضف الحمص ومعجون الطماطم والليمون الأسود.','اتركه حتى يتماسك وقدّمه مع الرز.']),
    _Recipe('تشريب لحم','أكلات رئيسية','75 دقيقة',['لحم','خبز تنور','حمص','بصل وطماطم','معجون طماطم'],['اطبخ اللحم مع البصل والحمص.','أضف الطماطم ومعجونها والماء حتى ينضج.','قطّع خبز التنور واسقه بالمرق.','أضف اللحم والحمص وقدّمه ساخناً.']),
    _Recipe('برياني عراقي','أكلات رئيسية','70 دقيقة',['رز بسمتي','دجاج','بطاطا','بازلاء','زبيب ولوز','بهارات برياني'],['اطبخ الدجاج مع البهارات.','حضّر البطاطا والبازلاء والزبيب واللوز.','اسلق الرز نصف استواء.','ضع طبقات الرز والدجاج والخضار وأكمل النضج.']),
    _Recipe('مرق بامية','أكلات رئيسية','65 دقيقة',['بامية','لحم','ثوم','طماطم','معجون طماطم','ليمون'],['اطبخ اللحم حتى يقترب من النضج.','أضف الثوم والطماطم ومعجونها.','أضف البامية واتركها تنضج.','وازن الحموضة بالليمون وقدّمها مع الرز.']),
    _Recipe('مرق فاصوليا','أكلات رئيسية','70 دقيقة',['فاصوليا بيضاء','لحم','بصل','طماطم','معجون طماطم'],['اطبخ اللحم والبصل.','أضف الطماطم ومعجونها والبهارات.','أضف الفاصوليا والماء واترك المرق يتسبك.','قدّمه مع الرز الأبيض.']),
    _Recipe('كبة حامض','أكلات رئيسية','90 دقيقة',['برغل ناعم','لحم مفروم','بصل','سلق أو سبانخ','حمص','ليمون'],['حضّر عجينة البرغل واعجنها.','حضّر حشوة اللحم والبصل.','شكّل الكبة واحشها وأغلقها.','اطبخها في مرق السلق والحمص والليمون.']),
    _Recipe('قوزي عراقي','أكلات رئيسية','150 دقيقة',['لحم غنم أو دجاج','رز','شعيرية','لوز وزبيب','بهارات'],['اطبخ اللحم مع البهارات حتى ينضج.','حضّر الرز بالشعيرية والمرق.','حمّص اللوز والزبيب.','رتّب الرز واللحم والمكسرات للتقديم.']),
    _Recipe('بيض وطماطم','فطور','15 دقيقة',['بيض','طماطم','بصل','ملح وفلفل'],['شوّح البصل بقليل من الزيت.','أضف الطماطم واتركها تلين.','أضف البيض واطهه حتى ينضج تماماً.']),
    _Recipe('كاهي وقيمر','فطور','35 دقيقة',['عجينة كاهي','قيمر','قطر أو عسل'],['افرد العجين إلى طبقات رقيقة.','اخبزه حتى يصبح مورقاً وذهبياً.','قدّمه دافئاً مع القيمر والقطر.']),
    _Recipe('عروك عراقية','فطور','35 دقيقة',['طحين','لحم مفروم','بصل','بقدونس','طماطم','بهارات'],['اخلط الطحين والماء لعجينة لينة.','أضف اللحم والخضار والبهارات.','شكّل أقراصاً صغيرة.','اطبخها على صاج حتى تنضج.']),
    _Recipe('شوربة عدس','شوربات','40 دقيقة',['عدس أحمر','بصل','جزر','كمون','ليمون'],['اغسل العدس واطبخه مع البصل والجزر.','أضف الكمون واتركه حتى يلين.','اخلطه بحذر حتى يصبح ناعماً.','قدّمه مع الليمون والخبز.']),
    _Recipe('شوربة لسان العصفور','شوربات','30 دقيقة',['لسان عصفور','مرق دجاج','جزر','بازلاء'],['حمّص لسان العصفور بقليل من الزيت.','أضف المرق والخضار.','اطبخ حتى تلين الحبات.']),
    _Recipe('طرشي عراقي','مقبلات','25 دقيقة + تخليل',['خيار','لفت','قرنبيط','شمندر','ماء','خل وملح'],['اغسل الخضار وقطّعها.','ضعها في مرطبان نظيف.','أضف الماء والخل والملح.','أغلقه واحفظه في الثلاجة حتى يتخلل.']),
    _Recipe('عمبة منزلية','مقبلات','20 دقيقة',['مانجو خضراء','خل','كركم','حلبة','ثوم','ملح'],['قطّع المانجو.','اخلط الخل مع التوابل والثوم.','أضف المانجو وامزج جيداً.','احفظها بوعاء نظيف في الثلاجة.']),
    _Recipe('سمبوسة باللحم','معجنات','45 دقيقة',['عجينة سمبوسة','لحم مفروم','بصل','بقدونس','بهارات'],['اطبخ اللحم مع البصل والبهارات واتركه يبرد.','احشِ العجين وأغلق الحواف.','اخبزها أو اطبخها حتى تنضج.']),
    _Recipe('صمون عراقي','معجنات','120 دقيقة',['طحين','خميرة','سكر','ملح','ماء دافئ'],['اخلط الخميرة والسكر بالماء.','أضف الطحين والملح واعجن.','اترك العجين يختمر ثم شكّله.','اخبزه حتى ينضج.']),
    _Recipe('كليجة عراقية','حلويات','90 دقيقة',['طحين','زبدة أو دهن','تمر معجون','هيل','سمسم'],['اخلط الطحين مع الدهن والهيل.','حضّر حشوة التمر.','احشِ العجين وشكّله.','اخبزه حتى يصبح ذهبياً.']),
    _Recipe('زلابية','حلويات','45 دقيقة',['طحين','نشا','خميرة','ماء','قطر'],['اخلط الطحين والنشا والخميرة والماء واتركه يختمر.','شكّل دوائر صغيرة.','اطبخها حتى تنضج وتصبح ذهبية.','صفّها وقدّمها مع القطر.']),
    _Recipe('دهينة نجفية','حلويات','50 دقيقة',['طحين','سكر','دبس تمر','دهن','جوز'],['اخلط الطحين مع الدهن.','أضف السكر ودبس التمر.','افرد الخليط في صينية وأضف الجوز.','اخبزه حتى يتماسك واتركه يبرد.']),
    _Recipe('شاي عراقي بالهيل','مشروبات','10 دقائق',['ماء','شاي أسود','هيل','سكر حسب الرغبة'],['اغلِ الماء مع الهيل.','أضف الشاي واتركه دقائق.','صفّه وقدّمه ساخناً.']),
    _Recipe('شنينة باردة','مشروبات','5 دقائق',['لبن رائب','ماء بارد','ملح','نعناع اختياري'],['اخلط اللبن مع الماء.','أضف الملح والنعناع.','قدّمه بارداً.']),
  ];

  @override
  void initState() {
    super.initState();
    _search.addListener(() { if (mounted) setState(() {}); });
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _favorites = (prefs.getStringList('v36_iraqi_recipe_favorites') ?? <String>[]).toSet();
      _loading = false;
    });
  }

  Future<void> _toggleFavorite(_Recipe recipe) async {
    setState(() {
      if (_favorites.contains(recipe.name)) {
        _favorites.remove(recipe.name);
      } else {
        _favorites.add(recipe.name);
      }
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('v36_iraqi_recipe_favorites', _favorites.toList());
  }

  List<_Recipe> get _filtered => _recipes.where((recipe) {
    final categoryMatch = _category == 'الكل' || recipe.category == _category;
    final q = _search.text.trim().toLowerCase();
    final textMatch = q.isEmpty || recipe.name.toLowerCase().contains(q) ||
        recipe.ingredients.any((item) => item.toLowerCase().contains(q));
    return categoryMatch && textMatch;
  }).toList();

  void _showRecipe(_Recipe recipe) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF191B30),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(26))),
      builder: (sheetContext) => Directionality(
        textDirection: TextDirection.rtl,
        child: DraggableScrollableSheet(
          expand: false,
          initialChildSize: .82,
          maxChildSize: .95,
          builder: (context, controller) => ListView(
            controller: controller,
            padding: const EdgeInsets.all(20),
            children: [
              Row(children: [
                Expanded(child: Text(recipe.name, style: const TextStyle(fontSize: 23, fontWeight: FontWeight.bold))),
                IconButton(onPressed: () { _toggleFavorite(recipe); Navigator.pop(sheetContext); },
                  icon: Icon(_favorites.contains(recipe.name) ? Icons.favorite : Icons.favorite_border, color: Colors.pinkAccent)),
              ]),
              Text(recipe.category + ' • ' + recipe.duration, style: const TextStyle(color: Colors.white70)),
              const SizedBox(height: 20),
              const Text('المكونات', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ...recipe.ingredients.map((item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(children: [const Icon(Icons.check_circle_outline, size: 18, color: Color(0xFF9D8BFF)), const SizedBox(width: 8), Expanded(child: Text(item))]),
              )),
              const SizedBox(height: 18),
              const Text('طريقة التحضير', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ...recipe.steps.asMap().entries.map((entry) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 7),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  CircleAvatar(radius: 13, child: Text((entry.key + 1).toString(), style: const TextStyle(fontSize: 12))),
                  const SizedBox(width: 10), Expanded(child: Text(entry.value)),
                ]),
              )),
              const SizedBox(height: 16),
              const Text('تختلف المقادير ومدة الطبخ حسب عدد الحصص ونوع المكونات. تأكد من نضج اللحوم والدجاج جيداً.',
                style: TextStyle(color: Colors.white60, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() { _search.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final recipes = _filtered;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('مطبخ المستقبل العراقي')),
        body: _loading ? const Center(child: CircularProgressIndicator()) : CustomScrollView(slivers: [
          SliverToBoxAdapter(child: Container(
            margin: const EdgeInsets.all(14), padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(22),
              gradient: const LinearGradient(colors: [Color(0xFF34245F), Color(0xFF14505A)], begin: Alignment.topRight, end: Alignment.bottomLeft)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Icon(Icons.restaurant_menu_rounded, size: 34, color: Color(0xFFFFD18A)),
              const SizedBox(height: 8),
              const Text('نكهات من مطبخنا العراقي', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
              const SizedBox(height: 5),
              const Text('وصفات شعبية وبيتية بمكونات واضحة وخطوات مرتبة.'),
              const SizedBox(height: 12),
              Text(_recipes.length.toString() + ' وصفة • ' + _favorites.length.toString() + ' محفوظة',
                style: const TextStyle(color: Color(0xFFFFD18A), fontWeight: FontWeight.bold)),
            ]),
          )),
          SliverToBoxAdapter(child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: TextField(controller: _search, decoration: InputDecoration(
              hintText: 'ابحث عن أكلة أو مكوّن...', prefixIcon: const Icon(Icons.search),
              suffixIcon: IconButton(onPressed: _search.clear, icon: const Icon(Icons.close)),
              filled: true, border: OutlineInputBorder(borderRadius: BorderRadius.circular(16))),
            ),
          )),
          SliverToBoxAdapter(child: SizedBox(height: 58, child: ListView(
            scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            children: _categories.map((category) => Padding(
              padding: const EdgeInsetsDirectional.only(end: 8),
              child: ChoiceChip(label: Text(category), selected: _category == category,
                onSelected: (_) => setState(() => _category = category)),
            )).toList(),
          ))),
          if (recipes.isEmpty)
            const SliverFillRemaining(hasScrollBody: false, child: Center(child: Text('ما لقينا وصفات مطابقة. جرّب كلمة ثانية.')))
          else
            SliverPadding(padding: const EdgeInsets.fromLTRB(14, 4, 14, 24),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, mainAxisSpacing: 10, crossAxisSpacing: 10, childAspectRatio: 1.12),
                delegate: SliverChildBuilderDelegate((context, index) {
                  final recipe = recipes[index];
                  final favorite = _favorites.contains(recipe.name);
                  return Card(clipBehavior: Clip.antiAlias, child: InkWell(
                    onTap: () => _showRecipe(recipe),
                    child: Padding(padding: const EdgeInsets.all(12), child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [const Icon(Icons.restaurant, color: Color(0xFFFFC77D)), const Spacer(),
                          Icon(favorite ? Icons.favorite : Icons.favorite_border, size: 19,
                            color: favorite ? Colors.pinkAccent : Colors.white54)]),
                        const Spacer(),
                        Text(recipe.name, maxLines: 2, overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        const SizedBox(height: 5),
                        Text(recipe.category, style: const TextStyle(color: Colors.white70, fontSize: 11)),
                        const SizedBox(height: 5),
                        Text(recipe.duration, style: const TextStyle(color: Color(0xFFFFD18A), fontSize: 10)),
                      ],
                    )),
                  ));
                }, childCount: recipes.length),
              )),
        ]),
      ),
    );
  }
}

class _Recipe {
  const _Recipe(this.name, this.category, this.duration, this.ingredients, this.steps);
  final String name;
  final String category;
  final String duration;
  final List<String> ingredients;
  final List<String> steps;
}
