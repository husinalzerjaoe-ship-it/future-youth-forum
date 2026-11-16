import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class V28GamingLibraryPage extends StatefulWidget {
  const V28GamingLibraryPage({super.key});
  @override State<V28GamingLibraryPage> createState() => _V28GamingLibraryPageState();
}

class _V28GamingLibraryPageState extends State<V28GamingLibraryPage> {
  static const base = 'https://mlbbdex.com/api/v1';
  static const violet = Color(0xFF7047C8);
  String game = 'Mobile Legends', tab = 'الأبطال', query = '', role = 'الكل';
  bool loading = false, detailLoading = false;
  String? error;
  List<Map<String,dynamic>> heroes=[], ranks=[], emblems=[], spells=[], patches=[], counters=[];
  Map<String,dynamic>? selected, selectedRank;

  @override void initState(){ super.initState(); load(); }

  Future<dynamic> getData(String path) async {
    final r=await http.get(Uri.parse(base+path),headers: const {'Accept':'application/json'}).timeout(const Duration(seconds:18));
    if(r.statusCode!=200) throw Exception('HTTP');
    return jsonDecode(utf8.decode(r.bodyBytes));
  }
  List<Map<String,dynamic>> asList(dynamic v){
    dynamic d=v is Map?v['data']:v;
    if(d is Map && d['heroes'] is List) d=d['heroes'];
    if(d is! List) return [];
    return d.whereType<Map>().map((e)=>Map<String,dynamic>.from(e)).toList();
  }
  Map<String,dynamic> asMap(dynamic v){final d=v is Map?v['data']:v; return d is Map?Map<String,dynamic>.from(d):{};}
  String val(dynamic v){
    if(v==null)return '';
    if(v is String||v is num||v is bool)return v.toString();
    if(v is List)return v.map(val).where((s)=>s.isNotEmpty).join(' • ');
    if(v is Map){for(final k in ['name','title','label','value','text','en']){final s=val(v[k]);if(s.isNotEmpty)return s;}}
    return '';
  }
  String field(Map<String,dynamic> m,List<String> keys,[String fallback='—']){
    for(final k in keys){final s=val(m[k]);if(s.isNotEmpty)return s;}return fallback;
  }
  String? imageOf(Map<String,dynamic> m){
    for(final e in m.entries){
      final k=e.key.toLowerCase(),v=e.value;
      if((k.contains('image')||k.contains('portrait')||k.contains('art')||k.contains('avatar')||k.contains('icon'))&&v is String&&v.startsWith('http'))return v;
      if(v is Map){final s=imageOf(Map<String,dynamic>.from(v));if(s!=null)return s;}
    }
    return null;
  }
  Future<void> load() async {
    setState(()=>loading=true); error=null;
    try{
      final r=await Future.wait([getData('/heroes'),getData('/rankings'),getData('/emblems?locale=en'),getData('/spells?locale=en'),getData('/patches')]);
      if(!mounted)return;
      setState((){
        heroes=asList(r[0]);ranks=asList(r[1]);emblems=asList(r[2]);spells=asList(r[3]);patches=asList(r[4]);loading=false;
      });
    }catch(_){if(mounted)setState(()=>loading=false);error='تعذر تحديث المكتبة من المصدر حالياً. افحص الإنترنت وحاول مرة ثانية.';}
  }
  Map<String,dynamic>? rankFor(Map<String,dynamic> h){
    final slug=field(h,['slug','id'],'').toLowerCase(),name=field(h,['name','title'],'').toLowerCase();
    for(final r in ranks){if(field(r,['slug','heroSlug','id'],'').toLowerCase()==slug||field(r,['name','hero','title'],'').toLowerCase()==name)return r;}
    return null;
  }
  Future<void> openHero(Map<String,dynamic> h) async {
    final slug=field(h,['slug','id'],'');if(slug.isEmpty)return;
    setState(() { selected=h; selectedRank=rankFor(h); detailLoading=true; counters=[]; });
    try{
      final r=await Future.wait([getData('/heroes/'+slug),getData('/heroes/'+slug+'/counters')]);
      if(!mounted)return;
      setState(() { selected=asMap(r[0]).isEmpty?h:asMap(r[0]); counters=asList(r[1]); detailLoading=false; });
    }catch(_){if(mounted)setState(()=>detailLoading=false);}
  }
  List<String> flatten(dynamic v,[int depth=0]){
    if(depth>2||v==null)return [];
    if(v is String||v is num||v is bool)return [v.toString()];
    if(v is List)return v.expand((e)=>flatten(e,depth+1)).take(30).toList();
    if(v is Map)return v.entries.where((e)=>!['id','slug','url','image','icon','portrait','artwork'].contains(e.key.toLowerCase())).take(18).expand((e)=>[e.key+': '+flatten(e.value,depth+1).join('، ')]).toList();
    return [];
  }
  List<Map<String,dynamic>> get visibleHeroes=>heroes.where((h){
    final n=field(h,['name','title','slug'],'');
    final r=field(h,['role','roles','class'],'');
    return (role=='الكل'||r.toLowerCase().contains(role.toLowerCase()))&&('$n $r '+field(h,['lane','specialty'],'')).toLowerCase().contains(query.toLowerCase());
  }).toList();
  @override Widget build(BuildContext context)=>Directionality(textDirection:TextDirection.rtl,child:Scaffold(
    backgroundColor:const Color(0xFFF4F5FB),
    appBar:AppBar(title:const Text('مكتبة الألعاب الاحترافية'),backgroundColor:const Color(0xFF10152E),foregroundColor:Colors.white,actions:[IconButton(onPressed:load,icon:const Icon(Icons.refresh))]),
    body:ListView(padding:const EdgeInsets.all(14),children:[
      Container(padding:const EdgeInsets.all(18),decoration:BoxDecoration(borderRadius:BorderRadius.circular(22),gradient:const LinearGradient(colors:[Color(0xFF10152E),Color(0xFF5635A0),Color(0xFF087F91)])),child:const Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        Text('GAME COMPANION',style:TextStyle(color:Color(0xFFBEEBFF),letterSpacing:2,fontWeight:FontWeight.bold)),
        SizedBox(height:8),Text('موسوعة الأبطال والتحديثات',style:TextStyle(color:Colors.white,fontSize:21,fontWeight:FontWeight.w900)),
        SizedBox(height:5),Text('صور • أدوار • ميتا • عدادات • إيمبلم • تعاويذ • تحديثات',style:TextStyle(color:Colors.white70)),
      ])),
      const SizedBox(height:12),
      SegmentedButton<String>(segments:const [ButtonSegment(value:'Mobile Legends',label:Text('Mobile Legends'),icon:Icon(Icons.shield_moon)),ButtonSegment(value:'PUBG Mobile',label:Text('PUBG'),icon:Icon(Icons.sports_esports))],selected:{game},onSelectionChanged:(v)=>setState(() { game=v.first; selected=null; })),
      const SizedBox(height:10),
      if(game=='Mobile Legends') ...mlbbWidgets() else ...pubgWidgets(),
      const SizedBox(height:14),
      const Text('مصدر بيانات MLBB: MLBBDex وموسوعة Mobile Legends Wiki (CC BY-SA). الإحصاءات مجتمعية وقد تتأخر عن تحديث اللعبة.',style:TextStyle(fontSize:11,color:Colors.black54)),
    ]),
  ));

  Widget chip(String n,String label)=>Chip(avatar:const Icon(Icons.auto_awesome,size:16,color:violet),label:Text(n+' '+label),backgroundColor:Colors.white);
  Widget errorCard()=>Card(child:Padding(padding:const EdgeInsets.all(14),child:Column(children:[Text(error??''),FilledButton.icon(onPressed:load,icon:const Icon(Icons.refresh),label:const Text('إعادة المحاولة'))])));
  List<Widget> mlbbWidgets(){
    if(selected!=null)return [heroDetail()];
    if(loading&&heroes.isEmpty)return [const Center(child:CircularProgressIndicator())];
    return [
      if(error!=null)errorCard(),
      Wrap(spacing:6,children:[chip(heroes.length.toString(),'بطل'),chip(ranks.length.toString(),'إحصائية ميتا'),chip(patches.length.toString(),'تحديث')]),
      const SizedBox(height:10),
      Wrap(spacing:6,runSpacing:6,children:['الأبطال','الميتا','الإيمبلم','التعاويذ','التحديثات'].map((s)=>ChoiceChip(label:Text(s),selected:tab==s,onSelected:(_)=>setState(()=>tab=s))).toList()),
      const SizedBox(height:8),
      if(tab=='الأبطال') ...heroesTab(),
      if(tab=='الميتا') ...metaTab(),
      if(tab=='الإيمبلم') ...dataCards(emblems,'لا توجد بيانات إيمبلم'),
      if(tab=='التعاويذ') ...dataCards(spells,'لا توجد بيانات تعاويذ'),
      if(tab=='التحديثات') ...dataCards(patches.take(30).toList(),'لا توجد تحديثات'),
      if(loading)const LinearProgressIndicator(),
    ];
  }
  List<Widget> heroesTab()=>[
    TextField(decoration:InputDecoration(prefixIcon:const Icon(Icons.search),hintText:'ابحث عن أي بطل أو دور...',filled:true,fillColor:Colors.white,border:OutlineInputBorder(borderRadius:BorderRadius.circular(14),borderSide:BorderSide.none)),onChanged:(v)=>setState(()=>query=v)),
    const SizedBox(height:8),
    DropdownButtonFormField<String>(value:role,decoration:const InputDecoration(labelText:'الدور',filled:true,fillColor:Colors.white),items:['الكل','Tank','Fighter','Assassin','Mage','Marksman','Support'].map((s)=>DropdownMenuItem(value:s,child:Text(s=='الكل'?'كل الأدوار':s))).toList(),onChanged:(v)=>setState(()=>role=v??'الكل')),
    const SizedBox(height:8),Text('عرض '+visibleHeroes.length.toString()+' من '+heroes.length.toString()+' بطل',style:const TextStyle(fontWeight:FontWeight.bold)),
    GridView.builder(shrinkWrap:true,physics:const NeverScrollableScrollPhysics(),itemCount:visibleHeroes.length,gridDelegate:const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount:2,childAspectRatio:.9,crossAxisSpacing:8,mainAxisSpacing:8),itemBuilder:(c,i){
      final h=visibleHeroes[i],img=imageOf(h),rank=rankFor(h);
      return InkWell(onTap:()=>openHero(h),child:Card(clipBehavior:Clip.antiAlias,margin:EdgeInsets.zero,child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
        Expanded(child:Stack(fit:StackFit.expand,children:[
          Container(color:const Color(0xFF10152E),child:img==null?const Icon(Icons.shield_moon,color:Colors.white54,size:44):Image.network(img,fit:BoxFit.cover,errorBuilder:(_,__,___)=>const Icon(Icons.shield_moon,color:Colors.white54,size:44))),
          if(rank!=null)Positioned(top:6,left:6,child:Container(padding:const EdgeInsets.symmetric(horizontal:8,vertical:4),decoration:BoxDecoration(color:const Color(0xFFE8CA77),borderRadius:BorderRadius.circular(16)),child:Text(field(rank,['tier','rank']),style:const TextStyle(fontWeight:FontWeight.bold)))),
        ])),
        Padding(padding:const EdgeInsets.all(8),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(field(h,['name','title','slug'],'Hero'),maxLines:1,overflow:TextOverflow.ellipsis,style:const TextStyle(fontWeight:FontWeight.w900)),Text(field(h,['role','roles','class']),maxLines:1,style:const TextStyle(fontSize:11,color:Colors.black54))])),
      ])));
    }),
  ];
  List<Widget> metaTab(){
    final sorted=[...ranks]..sort((a,b)=>tierOrder(field(a,['tier']))-tierOrder(field(b,['tier'])));
    return [const Text('الميتا حسب بيانات الإحصاءات المنشورة',style:TextStyle(fontWeight:FontWeight.w900,fontSize:17)),const Text('تتغير القوة حسب الرتبة والمنطقة والتحديث. هذه مؤشرات وليست ضماناً.',style:TextStyle(color:Colors.black54,fontSize:12)),...sorted.map((r)=>Card(child:ListTile(leading:Text(field(r,['tier','rank'])),title:Text(field(r,['name','hero','title'],'Hero')),subtitle:Text('فوز: '+field(r,['winRate','win_rate'])+' • اختيار: '+field(r,['pickRate','pick_rate'])+' • حظر: '+field(r,['banRate','ban_rate'])))))];
  }
  int tierOrder(String t){final s=t.toUpperCase();if(s.contains('S'))return 0;if(s.contains('A'))return 1;if(s.contains('B'))return 2;if(s.contains('C'))return 3;return 4;}
  List<Widget> dataCards(List<Map<String,dynamic>> data,String empty)=>data.isEmpty?[Card(child:Padding(padding:const EdgeInsets.all(14),child:Text(empty)))]:data.map((m)=>Card(child:ExpansionTile(leading:const CircleAvatar(child:Icon(Icons.auto_awesome)),title:Text(field(m,['name','title','version'],'تفصيل')),subtitle:Text(field(m,['role','category','date'],'')),children:[Padding(padding:const EdgeInsets.all(14),child:Text(flatten(m).join('\n')))]))).toList();

  Widget heroDetail(){
    final h=selected!,img=imageOf(h),r=selectedRank;
    return Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
      TextButton.icon(onPressed:()=>setState(()=>selected=null),icon:const Icon(Icons.arrow_forward),label:const Text('رجوع للأبطال')),
      Card(clipBehavior:Clip.antiAlias,child:Column(children:[
        SizedBox(height:190,width:double.infinity,child:Container(color:const Color(0xFF10152E),child:img==null?const Icon(Icons.shield_moon,color:Colors.white70,size:70):Image.network(img,fit:BoxFit.cover,errorBuilder:(_,__,___)=>const Icon(Icons.shield_moon,color:Colors.white70,size:70)))),
        Padding(padding:const EdgeInsets.all(14),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          Text(field(h,['name','title','slug'],'Hero'),style:const TextStyle(fontSize:22,fontWeight:FontWeight.w900)),
          Text(field(h,['role','roles'])+' • '+field(h,['lane','lanes'])),
          if(r!=null)Text('الميتا: '+field(r,['tier'])+' • نسبة الفوز: '+field(r,['winRate','win_rate'])),
        ])),
      ])),
      if(detailLoading)const LinearProgressIndicator(),
      detailCard('المهارات والخصائص',h),
      listCard('العدادات المقاسة',counters),
      listCard('المظاهر والصور',asList(h['skins'])),
    ]);
  }
  Widget detailCard(String title,Map<String,dynamic> m)=>Card(child:ExpansionTile(initiallyExpanded:true,title:Text(title,style:const TextStyle(fontWeight:FontWeight.bold)),children:[Padding(padding:const EdgeInsets.all(14),child:Text(flatten(m).join('\n')))]));
  Widget listCard(String title,List<Map<String,dynamic>> data)=>Card(child:ExpansionTile(title:Text(title+' ('+data.length.toString()+')',style:const TextStyle(fontWeight:FontWeight.bold)),children:data.isEmpty?[const Padding(padding:EdgeInsets.all(14),child:Text('لا توجد بيانات تفصيلية منشورة لهذا البطل حالياً.'))]:data.map((m)=>ListTile(title:Text(field(m,['name','hero','title'],'تفصيل')),subtitle:Text(flatten(m).join(' • '),maxLines:5,overflow:TextOverflow.ellipsis))).toList()));

  List<Widget> pubgWidgets()=>[
    const Text('مركز تجربة اللعبة والهاتف',style:TextStyle(fontWeight:FontWeight.w900,fontSize:18)),
    const Text('محتوى عام لتحسين راحة الشاشة وأداء الجهاز وحماية الحساب، من دون إرشادات قتالية أو توجيهات لاستخدام الأسلحة.',style:TextStyle(color:Colors.black54)),
    guide('وضوح الشاشة','اضبط السطوع وحجم الواجهة بما يريح العين، وفعّل خيارات تقليل الوهج إذا كانت متاحة على هاتفك.'),
    guide('السلاسة والحرارة','اختر إعدادات رسومية تناسب قدرة جهازك، أغلق التطبيقات غير الضرورية، واترك الهاتف يبرد إذا ارتفعت حرارته.'),
    guide('البطارية والتخزين','حافظ على مساحة تخزين كافية، وتجنب اللعب أثناء شحن الهاتف إذا كان يسبب ارتفاع حرارته.'),
    guide('الصوت والراحة','اضبط الصوت بمستوى مريح وخذ استراحة إذا شعرت بإجهاد العين أو السمع.'),
    guide('الشبكة والخصوصية','استخدم اتصالاً مستقراً، لا تشارك كلمة مرورك أو رموز التحقق، ولا تفتح روابط مجهولة.'),
    guide('توازن اللعب','خذ استراحة بين الجولات ولا تجعل اللعب يؤثر على النوم أو الدراسة أو نشاطك اليومي.'),
  ];
  Widget guide(String title,String body)=>Card(child:ExpansionTile(leading:const CircleAvatar(child:Icon(Icons.tips_and_updates)),title:Text(title,style:const TextStyle(fontWeight:FontWeight.bold)),children:[Padding(padding:const EdgeInsets.all(14),child:Text(body))]));
}
