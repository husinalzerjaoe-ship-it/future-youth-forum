import 'dart:math';
import 'package:flutter/material.dart';

class SocialPartyGamesPage extends StatelessWidget {
  const SocialPartyGamesPage({super.key});
  @override
  Widget build(BuildContext context) => Directionality(textDirection: TextDirection.rtl, child: Scaffold(
    appBar: AppBar(title: const Text('ألعاب السهرة الجماعية')),
    body: ListView(padding: const EdgeInsets.all(16), children: [
      const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('ألعاب جماعية محلية: مرّروا الهاتف بين اللاعبين للأدوار السرية. اللعب أونلاين المتزامن يحتاج ربط غرف منفصل.', style: TextStyle(fontSize: 16)))),
      _item(context, 'منو الجاسوس؟', 'كلمات سرية وجاسوس يحاول يكتشفها', '🕵️', const SpyGamePage()),
      _item(context, 'الذئب والمواطنون', 'وزّعوا الأدوار واكشفوا الذئب', '🐺', const WerewolfGamePage()),
      _item(context, 'ارسم وخمّن', 'ارسم كلمة وخلي أصدقاءك يخمنوها', '🎨', const DrawGuessPage()),
      _item(context, 'دمج الفواكه', 'ادمج الفواكه المتشابهة واجمع النقاط', '🍉', const FruitMergePage()),
      _item(context, 'سباق النرد', 'سباق من 2 إلى 4 لاعبين', '🎲', const DiceRacePage()),
      _item(context, 'تحدي الخداع', 'ادّعاء وكشف الخداع بين الأصدقاء', '🃏', const BluffPartyPage()),
    ]),
  ));
  Widget _item(BuildContext c, String t, String s, String e, Widget p) => Card(child: ListTile(
    leading: CircleAvatar(child: Text(e, style: const TextStyle(fontSize: 23))),
    title: Text(t, style: const TextStyle(fontWeight: FontWeight.bold)), subtitle: Text(s),
    trailing: const Icon(Icons.chevron_left), onTap: () => Navigator.push(c, MaterialPageRoute(builder: (_) => p)),
  ));
}

class _Setup extends StatefulWidget {
  final String title; final int min,max; final ValueChanged<List<String>> onStart;
  const _Setup(this.title,this.min,this.max,this.onStart);
  @override State<_Setup> createState()=>_SetupState();
}
class _SetupState extends State<_Setup>{
  int count=4; final names=<TextEditingController>[];
  void sync(){while(names.length<count)names.add(TextEditingController(text:'لاعب \${names.length+1}'));while(names.length>count)names.removeLast().dispose();}
  @override void initState(){super.initState();count=widget.min<4?4:widget.min;sync();}
  @override void dispose(){for(final n in names){n.dispose();}super.dispose();}
  @override Widget build(BuildContext c)=>Scaffold(appBar:AppBar(title:Text(widget.title)),body:ListView(padding:const EdgeInsets.all(18),children:[
    DropdownButton<int>(value:count,isExpanded:true,items:[for(int i=widget.min;i<=widget.max;i++)DropdownMenuItem(value:i,child:Text('\$i لاعبين'))],onChanged:(v){if(v!=null)setState((){count=v;sync();});}),
    for(int i=0;i<count;i++)Padding(padding:const EdgeInsets.only(bottom:8),child:TextField(controller:names[i],decoration:InputDecoration(labelText:'اسم اللاعب \${i+1}',border:const OutlineInputBorder()))),
    FilledButton(onPressed:()=>widget.onStart(names.asMap().entries.map((e)=>e.value.text.trim().isEmpty?'لاعب \${e.key+1}':e.value.text.trim()).toList()),child:const Text('ابدأ')),
  ]));
}

class SpyGamePage extends StatefulWidget {const SpyGamePage({super.key});@override State<SpyGamePage> createState()=>_SpyGamePageState();}
class _SpyGamePageState extends State<SpyGamePage>{
  static const words=['مطار','مكتبة','ملعب','مستشفى','مطعم','مدرسة','شاطئ','سينما','سفينة','حديقة','قطار','متحف'];
  List<String>? players;int spy=0,index=0;String word='';bool reveal=false;
  void start(List<String> p){final r=Random();setState((){players=p;spy=r.nextInt(p.length);word=words[r.nextInt(words.length)];index=0;reveal=false;});}
  @override Widget build(BuildContext c)=>players==null?_Setup('منو الجاسوس؟',3,8,start):Scaffold(appBar:AppBar(title:const Text('منو الجاسوس؟')),body:Center(child:Padding(padding:const EdgeInsets.all(20),child:Column(mainAxisAlignment:MainAxisAlignment.center,children:[
    Text(reveal?'دور \${players![index]}':'مرّر الهاتف إلى \${players![index]}',style:const TextStyle(fontSize:22,fontWeight:FontWeight.bold)),
    const SizedBox(height:20),
    if(reveal)Text(index==spy?'أنت الجاسوس 🕵️':'الكلمة: \$word',style:const TextStyle(fontSize:30,fontWeight:FontWeight.bold)),
    FilledButton(onPressed:()=>setState(()=>reveal=!reveal),child:Text(reveal?'إخفاء الدور':'اكشف دوري')),
    if(reveal)FilledButton.tonal(onPressed:()=>setState((){if(index+1==players!.length){players=null;}else{index++;reveal=false;}}),child:Text(index+1==players!.length?'انتهى التوزيع':'اللاعب التالي')),
    const Text('بعد التوزيع: أعطوا تلميحات قصيرة، ناقشوا وصوّتوا على الجاسوس.',textAlign:TextAlign.center),
  ]))));
}

class WerewolfGamePage extends StatefulWidget {const WerewolfGamePage({super.key});@override State<WerewolfGamePage> createState()=>_WerewolfGamePageState();}
class _WerewolfGamePageState extends State<WerewolfGamePage>{
  List<String>? players;List<String> roles=[];int index=0;bool reveal=false;
  void start(List<String> p){final r=Random();final a=<String>['ذئب 🐺'];a.addAll(List.filled(p.length-1,'مواطن 🧑'));a.shuffle(r);setState((){players=p;roles=a;index=0;reveal=false;});}
  @override Widget build(BuildContext c)=>players==null?_Setup('الذئب والمواطنون',4,12,start):Scaffold(appBar:AppBar(title:const Text('الذئب والمواطنون')),body:Center(child:Padding(padding:const EdgeInsets.all(20),child:Column(mainAxisAlignment:MainAxisAlignment.center,children:[
    Text(reveal?'دور \${players![index]}':'سلّم الهاتف إلى \${players![index]}',style:const TextStyle(fontSize:22,fontWeight:FontWeight.bold)),
    if(reveal)Padding(padding:const EdgeInsets.all(20),child:Text(roles[index],style:const TextStyle(fontSize:34,fontWeight:FontWeight.bold))),
    FilledButton(onPressed:()=>setState(()=>reveal=!reveal),child:Text(reveal?'إخفاء الدور':'اكشف دوري')),
    if(reveal)FilledButton.tonal(onPressed:()=>setState((){if(index+1==players!.length){players=null;}else{index++;reveal=false;}}),child:Text(index+1==players!.length?'ابدأوا النقاش':'اللاعب التالي')),
    const Text('هذه نسخة توزيع أدوار محلية. اتفقوا على مرحلة ليل وتصويت نهاري.',textAlign:TextAlign.center),
  ]))));
}

class DrawGuessPage extends StatefulWidget {const DrawGuessPage({super.key});@override State<DrawGuessPage> createState()=>_DrawGuessPageState();}
class _DrawGuessPageState extends State<DrawGuessPage>{
  final rng=Random();final words=['قطة','سيارة','كرة قدم','شمس','بيت','تنين','بيتزا','طائرة','نخلة','روبوت'];String word='';final strokes=<List<Offset>>[];bool shown=false;
  @override void initState(){super.initState();next();}
  void next(){setState((){word=words[rng.nextInt(words.length)];strokes.clear();shown=false;});}
  @override Widget build(BuildContext c)=>Scaffold(appBar:AppBar(title:const Text('ارسم وخمّن')),body:Padding(padding:const EdgeInsets.all(14),child:Column(children:[
    Text(shown?'الكلمة: \$word':'الرسام فقط يشوف الكلمة: \$word',style:const TextStyle(fontSize:19,fontWeight:FontWeight.bold)),
    const Text('ارسم بدون كتابة حروف، وخلي البقية يخمنون.'),
    Expanded(child:GestureDetector(onPanStart:(d)=>strokes.add([d.localPosition]),onPanUpdate:(d)=>setState(()=>strokes.last.add(d.localPosition)),child:Container(width:double.infinity,margin:const EdgeInsets.symmetric(vertical:12),decoration:BoxDecoration(color:Colors.white,border:Border.all(color:Colors.black26),borderRadius:BorderRadius.circular(12)),child:CustomPaint(painter:_DrawPainter(strokes))))),
    Row(children:[Expanded(child:OutlinedButton(onPressed:()=>setState(strokes.clear),child:const Text('مسح'))),Expanded(child:FilledButton(onPressed:()=>setState(()=>shown=true),child:const Text('كشف الكلمة'))),IconButton(onPressed:next,icon:const Icon(Icons.refresh))]),
  ])));
}
class _DrawPainter extends CustomPainter{
 final List<List<Offset>> lines;_DrawPainter(this.lines);
 @override void paint(Canvas c,Size s){final p=Paint()..color=Colors.black..strokeWidth=4..strokeCap=StrokeCap.round;for(final l in lines){for(int i=0;i<l.length-1;i++){c.drawLine(l[i],l[i+1],p);}}}
 @override bool shouldRepaint(covariant _DrawPainter old)=>true;
}

class FruitMergePage extends StatefulWidget {const FruitMergePage({super.key});@override State<FruitMergePage> createState()=>_FruitMergePageState();}
class _FruitMergePageState extends State<FruitMergePage>{
  final rng=Random();List<int> cells=List.filled(16,0);int score=0;
  static const fruit=['','🍒','🍓','🍊','🍋','🍏','🍉'];
  void spawn(){final e=[for(int i=0;i<16;i++)if(cells[i]==0)i];if(e.isNotEmpty)cells[e[rng.nextInt(e.length)]]=1;}
  void tap(int i){if(cells[i]==0){setState(()=>cells[i]=1);return;}final ns=[i%4>0?i-1:-1,i%4<3?i+1:-1,i>=4?i-4:-1,i<12?i+4:-1];for(final n in ns){if(n>=0&&cells[n]==cells[i]&&cells[i]<6){setState((){cells[i]++;cells[n]=0;score+=cells[i]*10;spawn();});return;}}}
  @override void initState(){super.initState();spawn();spawn();}
  @override Widget build(BuildContext c)=>Scaffold(appBar:AppBar(title:const Text('دمج الفواكه')),body:Padding(padding:const EdgeInsets.all(16),child:Column(children:[
    Text('النقاط: \$score',style:const TextStyle(fontSize:20,fontWeight:FontWeight.bold)),
    const Text('اضغط فاكهتين متجاورتين من النوع نفسه لدمجهما.'),
    Expanded(child:Center(child:AspectRatio(aspectRatio:1,child:GridView.builder(itemCount:16,gridDelegate:const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount:4,crossAxisSpacing:7,mainAxisSpacing:7),itemBuilder:(c,i)=>InkWell(onTap:()=>tap(i),child:Container(decoration:BoxDecoration(color:Theme.of(c).colorScheme.surfaceContainerHighest,borderRadius:BorderRadius.circular(12)),child:Center(child:Text(fruit[cells[i]],style:const TextStyle(fontSize:30))))))))),
    FilledButton(onPressed:()=>setState((){cells=List.filled(16,0);score=0;spawn();spawn();}),child:const Text('إعادة')),
  ])));
}

class DiceRacePage extends StatefulWidget {const DiceRacePage({super.key});@override State<DiceRacePage> createState()=>_DiceRacePageState();}
class _DiceRacePageState extends State<DiceRacePage>{
  List<String> names=['الأحمر','الأزرق'];List<int> pos=[0,0];int turn=0,dice=1;String? winner;final rng=Random();
  void roll(){if(winner!=null)return;setState((){dice=rng.nextInt(6)+1;pos[turn]=min(30,pos[turn]+dice);if(pos[turn]>=30)winner=names[turn];else turn=(turn+1)%names.length;});}
  @override Widget build(BuildContext c)=>Scaffold(appBar:AppBar(title:const Text('سباق النرد')),body:ListView(padding:const EdgeInsets.all(16),children:[
    Text('الدور: \${winner??names[turn]} • النرد: \$dice',style:const TextStyle(fontSize:19,fontWeight:FontWeight.bold)),
    for(int i=0;i<names.length;i++)Card(child:ListTile(title:Text(names[i]),subtitle:LinearProgressIndicator(value:pos[i]/30),trailing:Text('\${pos[i]}/30'))),
    FilledButton(onPressed:winner==null?roll:null,child:Text(winner==null?'ارمِ النرد 🎲':'الفائز: \$winner')),
    TextButton(onPressed:()=>setState((){pos=List.filled(names.length,0);turn=0;winner=null;}),child:const Text('إعادة السباق')),
    const Text('نسخة سباق خفيفة على نفس الجهاز، من 2 إلى 4 لاعبين بالإصدار الحالي.'),
  ]));
}

class BluffPartyPage extends StatefulWidget {const BluffPartyPage({super.key});@override State<BluffPartyPage> createState()=>_BluffPartyPageState();}
class _BluffPartyPageState extends State<BluffPartyPage>{
  int turn=0,round=1;final names=['لاعب 1','لاعب 2','لاعب 3','لاعب 4'];final rng=Random();late List<int> cards;String result='';bool revealed=false;
  @override void initState(){super.initState();cards=List.generate(4,(_)=>rng.nextInt(4));}
  @override Widget build(BuildContext c)=>Scaffold(appBar:AppBar(title:const Text('تحدي الخداع')),body:Padding(padding:const EdgeInsets.all(16),child:Column(children:[
    const Text('كل لاعب يشوف بطاقته سراً ويدّعي أنها تطابق رمز الجولة. اللاعب التالي يصدّق أو يتحدّى.'),
    Text('الجولة \$round • الدور: \${names[turn]}',style:const TextStyle(fontSize:20,fontWeight:FontWeight.bold)),
    const SizedBox(height:16),Text(revealed?'بطاقتك: \${['🍎','⭐','🎲','👑'][cards[turn]]}':'البطاقة مخفية',style:const TextStyle(fontSize:30)),
    FilledButton(onPressed:()=>setState(()=>revealed=!revealed),child:Text(revealed?'إخفاء البطاقة':'اكشف بطاقتي')),
    Row(children:[Expanded(child:OutlinedButton(onPressed:()=>setState(()=>result='تم كشف البطاقة. راجعوا هل كان الادعاء صحيحاً.'),child:const Text('أتحداك'))),Expanded(child:FilledButton(onPressed:()=>setState((){turn=(turn+1)%4;if(turn==0){round++;cards=List.generate(4,(_)=>rng.nextInt(4));}revealed=false;}),child:const Text('أصدّق وأمرّر')))]),
    Text(result),TextButton(onPressed:()=>setState((){turn=0;round=1;cards=List.generate(4,(_)=>rng.nextInt(4));revealed=false;result='';}),child:const Text('جولة جديدة')),
  ])));
}
