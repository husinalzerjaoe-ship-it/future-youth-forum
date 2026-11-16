import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FutureUniversePage extends StatefulWidget {
  final ValueChanged<String> onOpen;
  const FutureUniversePage({super.key, required this.onOpen});
  @override State<FutureUniversePage> createState() => _FutureUniversePageState();
}

class _FutureUniversePageState extends State<FutureUniversePage> {
  String mode = 'balanced', theme = 'violet', query = '';
  bool loading = true;
  Set<String> visible = {'growth','community','knowledge','games','studio','events','media','safety','scores','friends','watch'};
  final entries = const <_Entry>[
    _Entry('مسار التطور والأهداف اليومية', Icons.track_changes, 'growth', 'أهدافك ومهامك اليومية'),
    _Entry('مجتمع الأصدقاء والنقاشات', Icons.groups, 'communityPlus', 'الأندية والمجتمعات'),
    _Entry('المعرفة والاكتشاف', Icons.auto_awesome, 'knowledge', 'محتوى وأفكار جديدة'),
    _Entry('مدينة الألعاب والتحديات', Icons.sports_esports, 'futureArcade', 'ألعاب وتحديات'),
    _Entry('استوديو الإبداع', Icons.palette, 'studio', 'تصميم وبطاقات'),
    _Entry('فعاليات المجتمع', Icons.event, 'events', 'الفعاليات والتقويم'),
    _Entry('الموسيقى والوسائط', Icons.library_music, 'media', 'مكتبة ومشغل الوسائط'),
    _Entry('الأمان والخصوصية', Icons.shield, 'safety', 'حماية الحساب والخصوصية'),
    _Entry('الإنجازات ولوحة الصدارة', Icons.emoji_events, 'engagement', 'النقاط والمكافآت'),
    _Entry('منافسات الأصدقاء', Icons.people, 'friendsArena', 'تحديات جماعية'),
    _Entry('غرف المجتمع والمشاهدة', Icons.live_tv, 'expansion', 'ميزات المجتمع الحالية'),
    _Entry('الأكاديمية والتعلم', Icons.school, 'growth', 'مهارات وخطوات تعلم'),
    _Entry('التصويتات والاستطلاعات', Icons.poll, 'polls', 'شارك رأيك بالمجتمع'),
  ];

  @override void initState() { super.initState(); loadPrefs(); }
  Future<void> loadPrefs() async {
    final p = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      mode = p.getString('v33_mode') ?? 'balanced';
      theme = p.getString('v33_theme') ?? 'violet';
      visible = (p.getStringList('v33_cards') ?? visible.toList()).toSet();
      loading = false;
    });
    applyMode(mode, save: false);
  }

  Future<void> applyMode(String value, {bool save = true}) async {
    final cache = PaintingBinding.instance.imageCache;
    if (value == 'high') { cache.maximumSize = 1200; cache.maximumSizeBytes = 250 << 20; }
    else if (value == 'economy') { cache.maximumSize = 180; cache.maximumSizeBytes = 48 << 20; }
    else { cache.maximumSize = 500; cache.maximumSizeBytes = 100 << 20; }
    if (save) await (await SharedPreferences.getInstance()).setString('v33_mode', value);
    if (mounted) setState(() => mode = value);
  }

  Color get accent => theme == 'ocean' ? const Color(0xFF00A6B7) : theme == 'sunset' ? const Color(0xFFE47755) : theme == 'emerald' ? const Color(0xFF239B79) : const Color(0xFF7565E8);

  @override Widget build(BuildContext context) {
    final found = entries.where((e) => (e.title + e.subtitle).contains(query.trim())).toList();
    final shown = found.where((e) => visible.contains(e.route)).toList();
    return Directionality(textDirection: TextDirection.rtl, child: Scaffold(
      appBar: AppBar(title: const Text('كون المستقبل V33'), backgroundColor: const Color(0xFF171936), foregroundColor: Colors.white,
        actions: [IconButton(onPressed: cardsSheet, icon: const Icon(Icons.tune), tooltip: 'تخصيص البطاقات')]),
      body: loading ? const Center(child: CircularProgressIndicator()) : ListView(padding: const EdgeInsets.all(16), children: [
        Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(borderRadius: BorderRadius.circular(24), gradient: LinearGradient(colors: [accent,const Color(0xFF171936)])),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('مستقبلك يبدأ من هنا', style: TextStyle(color: Colors.white,fontSize: 24,fontWeight: FontWeight.w900)),
            const SizedBox(height: 8), const Text('مركز موحّد لاكتشاف أقسام الملتقى وتخصيص تجربتك.',style: TextStyle(color: Colors.white)),
            const SizedBox(height: 12), Text('وضع الجهاز: ' + (mode == 'high' ? 'أداء مرتفع' : mode == 'economy' ? 'توفير الذاكرة' : 'متوازن') + '  •  بطاقاتك: ' + visible.length.toString(),style: const TextStyle(color: Colors.white)),
          ])),
        const SizedBox(height: 16),
        TextField(onChanged: (v)=>setState(()=>query=v),decoration: InputDecoration(prefixIcon: const Icon(Icons.search),hintText:'ابحث عن قسم أو ميزة...',filled:true,border:OutlineInputBorder(borderRadius:BorderRadius.circular(15),borderSide:BorderSide.none))),
        const SizedBox(height: 14), const Text('مساحتك المختارة',style:TextStyle(fontSize:18,fontWeight:FontWeight.bold)),
        ...shown.map((e)=>Card(child:ListTile(onTap:()=>widget.onOpen(e.route),leading:CircleAvatar(backgroundColor:accent.withOpacity(.13),child:Icon(e.icon,color:accent)),title:Text(e.title,style:const TextStyle(fontWeight:FontWeight.bold)),subtitle:Text(e.subtitle),trailing:const Icon(Icons.arrow_back_ios,size:16)))),
        const SizedBox(height: 16), const Text('تحكم بأداء الجهاز',style:TextStyle(fontSize:18,fontWeight:FontWeight.bold)),
        Card(child:Column(children:[
          RadioListTile<String>(value:'high',groupValue:mode,onChanged:(v){if(v!=null)applyMode(v);},title:const Text('أداء مرتفع'),subtitle:const Text('ذاكرة صور أكبر وسرعة إعادة عرض أعلى؛ قد يستخدم RAM أكثر')),
          RadioListTile<String>(value:'balanced',groupValue:mode,onChanged:(v){if(v!=null)applyMode(v);},title:const Text('متوازن'),subtitle:const Text('إعداد مناسب لمعظم الأجهزة')),
          RadioListTile<String>(value:'economy',groupValue:mode,onChanged:(v){if(v!=null)applyMode(v);},title:const Text('توفير الذاكرة'),subtitle:const Text('تقليل ذاكرة الصور للأجهزة محدودة الموارد')),
        ])),
        const SizedBox(height:14),const Text('ألوان مركز الكون',style:TextStyle(fontSize:18,fontWeight:FontWeight.bold)),
        Wrap(spacing:8,children:[
          themeChip('violet','بنفسجي',const Color(0xFF7565E8)),
          themeChip('ocean','محيطي',const Color(0xFF00A6B7)),
          themeChip('sunset','غروب',const Color(0xFFE47755)),
          themeChip('emerald','زمردي',const Color(0xFF239B79)),
        ]),
        const SizedBox(height:14),const Card(child:Padding(padding:EdgeInsets.all(14),child:Text('إعدادات هذا المركز محفوظة على جهازك. البحث هنا محلي ولا يحتاج مشاركة موقعك الدقيق.'))),
      ]),
    ));
  }

  Widget themeChip(String value,String label,Color color)=>ChoiceChip(selected:theme==value,label:Text(label),avatar:CircleAvatar(backgroundColor:color,radius:8),onSelected:(_)async{await (await SharedPreferences.getInstance()).setString('v33_theme',value);if(mounted)setState(()=>theme=value);});

  Future<void> cardsSheet() async {
    await showModalBottomSheet<void>(context:context,isScrollControlled:true,builder:(ctx)=>StatefulBuilder(builder:(ctx,refresh)=>SafeArea(child:Padding(padding:const EdgeInsets.all(16),child:Column(mainAxisSize:MainAxisSize.min,children:[
      const Text('تخصيص لوحة الكون',style:TextStyle(fontSize:20,fontWeight:FontWeight.bold)),
      const Text('اختار الأقسام التي تريد ظهورها.'),
      Flexible(child:ListView(shrinkWrap:true,children:entries.map((e)=>CheckboxListTile(value:visible.contains(e.route),title:Text(e.title),onChanged:(v)async{
        final next={...visible}; if(v==true){next.add(e.route);}else{next.remove(e.route);}
        await (await SharedPreferences.getInstance()).setStringList('v33_cards',next.toList());
        if(mounted)setState(()=>visible=next);refresh(()=>{});
      })).toList())),
    ])))));
  }
}

class _Entry {
  final String title, subtitle, route;
  final IconData icon;
  const _Entry(this.title,this.icon,this.route,this.subtitle);
}
