import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';


class ArcadeHubPage extends StatefulWidget {
  const ArcadeHubPage({super.key});
  @override State<ArcadeHubPage> createState()=>_ArcadeHubPageState();
}

class _ArcadeHubPageState extends State<ArcadeHubPage> {
  final _random=Random();
  int _score=0;
  int _questionIndex=0;
  int? _selected;
  int _wins=0;
  int _losses=0;
  String _riddle='';
  String _answer='';
  String _guess='';
  bool _dailyClaimed=false;
  bool _busy=false;

  static const _questions=[
    {'q':'في أنمي ناروتو، ما اسم القرية التي ينتمي إليها ناروتو؟','a':['قرية الورق','قرية الرمل','قرية المطر','قرية الضباب'],'c':0,'why':'ناروتو من قرية الورق المخفية.'},
    {'q':'ما اسم صديق لوفي الذي يستخدم السيوف؟','a':['سانجي','زورو','أوسوب','فرانكي'],'c':1,'why':'رورونوا زورو سياف طاقم قبعة القش.'},
    {'q':'في Pokémon، ما اسم أشهر بوكيمون أصفر؟','a':['شارizard','بيكاتشو','إيفي','سكويرتل'],'c':1,'why':'بيكاتشو هو رفيق آش الأشهر.'},
    {'q':'ما اسم دفتر الموت في Death Note؟','a':['دفتر الظلال','Death Note','دفتر الأرواح','Black Book'],'c':1,'why':'الاسم هو Death Note.'},
    {'q':'أي شخصية تقول غالباً: أنا ملك القراصنة؟','a':['لوفي','غوكو','إيتاتشي','تانجيرو'],'c':0,'why':'حلم لوفي أن يصبح ملك القراصنة.'},
    {'q':'ما اسم بطل Demon Slayer؟','a':['إينوسكي','زينيتسو','تانجيرو','غيو'],'c':2,'why':'تانجيرو كامادو هو بطل القصة.'},
    {'q':'في Dragon Ball، ما اسم التحول الذهبي الشهير؟','a':['نينجا مود','سوبر سايان','Bankai','Gear 5'],'c':1,'why':'التحول هو سوبر سايان.'},
  ];

  static const _riddles=[
    ['شيء كلما أخذت منه كبر، ما هو؟','الحفرة'],
    ['له أسنان ولا يعض، ما هو؟','المشط'],
    ['يمشي بلا قدمين ويبكي بلا عينين، ما هو؟','السحاب'],
    ['ما الشيء الذي يكتب ولا يقرأ؟','القلم'],
    ['بيت بلا أبواب ولا نوافذ، ما هو؟','البيضة'],
  ];

  @override void initState(){super.initState();_nextRiddle();_loadDaily();}
  String get _uid=>FirebaseAuth.instance.currentUser!.uid;
  String get _today=>DateTime.now().toIso8601String().substring(0,10);

  Future<void> _loadDaily() async {
    try {
      final doc=await FirebaseFirestore.instance.collection('users').doc(_uid).get();
      if(!mounted)return;
      setState(()=>_dailyClaimed=doc.data()?['arcadeDailyDate']==_today);
      setState(()=>_score=(doc.data()?['arcadePoints'] as num?)?.toInt()??0);
    }catch(_){}
  }
  Future<void> _addPoints(int amount) async {
    setState(()=>_score+=amount);
    try {
      await FirebaseFirestore.instance.collection('users').doc(_uid).set({
        'arcadePoints':FieldValue.increment(amount),
        'arcadeUpdatedAt':FieldValue.serverTimestamp(),
      },SetOptions(merge:true));
    }catch(_){}
  }
  Future<void> _claimDaily() async {
    if(_dailyClaimed||_busy)return;
    setState(()=>_busy=true);
    final ref=FirebaseFirestore.instance.collection('users').doc(_uid);
    try{
      await FirebaseFirestore.instance.runTransaction((tx)async{
        final snap=await tx.get(ref);
        if(snap.data()?['arcadeDailyDate']==_today)throw Exception('claimed');
        tx.set(ref,{'arcadeDailyDate':_today,'arcadePoints':FieldValue.increment(10),'arcadeUpdatedAt':FieldValue.serverTimestamp()},SetOptions(merge:true));
      });
      if(!mounted)return;
      setState(()=>_dailyClaimed=true);
      _addLocalOnly(10);
      _toast('حصلت على 10 نقاط هدية! 🎁');
    }catch(e){if(mounted)_toast(e.toString().contains('claimed')?'أخذت مكافأة اليوم مسبقاً':'تعذر استلام المكافأة');}
    finally{if(mounted)setState(()=>_busy=false);}
  }
  void _addLocalOnly(int n){setState(()=>_score+=n);}
  void _toast(String s)=>ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(s)));
  void _nextRiddle(){final r=_riddles[_random.nextInt(_riddles.length)];_riddle=r[0];_answer=r[1];_guess='';}
  void _nextQuestion(){setState(()=>_questionIndex=_random.nextInt(_questions.length));}
  void _answerQuestion(int index){
    if(_selected!=null)return;
    final q=_questions[_questionIndex];
    final correct=index==q['c'];
    setState(()=>_selected=index);
    if(correct){_addPoints(5);_wins++;}else{_losses++;}
  }
  void _playRps(String user){
    const choices=['حجر','ورقة','مقص'];
    final bot=choices[_random.nextInt(3)];
    final win=(user=='حجر'&&bot=='مقص')||(user=='ورقة'&&bot=='حجر')||(user=='مقص'&&bot=='ورقة');
    final draw=user==bot;
    if(win){_addPoints(3);_wins++;}
    else if(!draw){_losses++;}
    _toast(draw?'تعادل! اختر مرة ثانية':'أنت: $user • الكمبيوتر: $bot • ${win?'فزت +3 نقاط':'خسرت'}');
  }
  @override Widget build(BuildContext context)=>Scaffold(
    appBar:AppBar(title:const Text('مدينة الترفيه والألعاب'),centerTitle:true),
    body:ListView(padding:const EdgeInsets.all(16),children:[
      Container(padding:const EdgeInsets.all(18),decoration:BoxDecoration(gradient:const LinearGradient(colors:[Color(0xFF4F46A5),Color(0xFF9B59B6)]),borderRadius:BorderRadius.circular(22)),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        const Text('أهلاً بك في مدينة المرح 🎮',style:TextStyle(color:Colors.white,fontSize:20,fontWeight:FontWeight.bold)),
        const SizedBox(height:8),const Text('العب، اجمع النقاط، وارجع كل يوم حتى تحصل على هداياك',style:TextStyle(color:Colors.white70)),
        const SizedBox(height:16),Row(children:[const Icon(Icons.stars,color:Colors.amber,size:30),const SizedBox(width:8),Text('$_score نقطة',style:const TextStyle(color:Colors.white,fontSize:23,fontWeight:FontWeight.bold)),const Spacer(),FilledButton.tonal(onPressed:_dailyClaimed||_busy?null:_claimDaily,child:Text(_dailyClaimed?'استلمت هدية اليوم':'هدية اليوم +10 🎁'))])
      ])),
      const SizedBox(height:18),
      _section('اختبر معلوماتك بالأنمي','جاوب صح واجمع 5 نقاط لكل سؤال',Icons.quiz_outlined,Colors.deepPurple, _quizCard()),
      _section('حجر ورقة مقص','تحدّى الكمبيوتر واربح 3 نقاط',Icons.sports_esports,Colors.orange,_rpsCard()),
      _section('لغز اليوم','فكّر قبل ما تشوف الحل',Icons.lightbulb_outline,Colors.teal,_riddleCard()),
      _section('تحدي السرعة','اضغط الزر 10 مرات بأسرع وقت',Icons.bolt,Colors.pink,_speedCard()),
      const SizedBox(height:10),
      Card(child:Padding(padding:const EdgeInsets.all(14),child:Row(children:[const Icon(Icons.emoji_events,color:Colors.amber,size:30),const SizedBox(width:10),Expanded(child:Text('نتائج جلستك: $_wins فوز • $_losses خسارة',style:const TextStyle(fontWeight:FontWeight.bold)))]))),
      const Padding(padding:EdgeInsets.all(8),child:Text('النقاط تُحفظ في حسابك. الألعاب ترفيهية، وقد تختلف الأسئلة والتحديات مع التحديثات.',textAlign:TextAlign.center,style:TextStyle(fontSize:11,color:Colors.grey))),
    ]),
  );

  Widget _section(String title,String sub,IconData icon,Color color,Widget child)=>Padding(padding:const EdgeInsets.only(bottom:14),child:Card(clipBehavior:Clip.antiAlias,child:Column(children:[
    ListTile(leading:CircleAvatar(backgroundColor:color.withOpacity(.13),child:Icon(icon,color:color)),title:Text(title,style:const TextStyle(fontWeight:FontWeight.bold)),subtitle:Text(sub)),
    Padding(padding:const EdgeInsets.fromLTRB(14,0,14,14),child:child),
  ])));
  Widget _quizCard(){
    final q=_questions[_questionIndex];final answers=q['a'] as List<String>;
    return Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
      Text(q['q'] as String,style:const TextStyle(fontWeight:FontWeight.w600)),
      const SizedBox(height:10),
      ...List.generate(answers.length,(i)=>Padding(padding:const EdgeInsets.only(bottom:6),child:OutlinedButton(
        style:OutlinedButton.styleFrom(backgroundColor:_selected==i?((i==q['c'])?Colors.green.withOpacity(.15):Colors.red.withOpacity(.12)):null),
        onPressed:_selected==null?()=>_answerQuestion(i):null,child:Text(answers[i])))),
      if(_selected!=null)Padding(padding:const EdgeInsets.symmetric(vertical:8),child:Text('${_selected==q['c']?'إجابة صحيحة! +5 نقاط 🎉':'مو صحيح، حاول بالسؤال الجاي.'} ${q['why']}',style:const TextStyle(fontWeight:FontWeight.bold))),
      Align(alignment:Alignment.centerLeft,child:TextButton.icon(onPressed:(){setState(()=>_selected=null);_nextQuestion();},icon:const Icon(Icons.refresh),label:const Text('سؤال جديد'))),
    ]);
  }
  Widget _rpsCard()=>Wrap(spacing:8,runSpacing:8,children:[
    for(final x in ['حجر','ورقة','مقص'])FilledButton.tonal(onPressed:()=>_playRps(x),child:Text({'حجر':'✊ حجر','ورقة':'✋ ورقة','مقص':'✌️ مقص'}[x]!))
  ]);
  Widget _riddleCard()=>Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
    Text(_riddle,style:const TextStyle(fontWeight:FontWeight.w600)),
    const SizedBox(height:8),
    TextField(onChanged:(v)=>_guess=v,decoration:const InputDecoration(hintText:'اكتب جوابك هنا',border:OutlineInputBorder(),isDense:true)),
    const SizedBox(height:8),
    Row(children:[Expanded(child:FilledButton(onPressed:(){if(_guess.trim().isEmpty)return;if(_guess.trim().toLowerCase()==_answer.toLowerCase()){_addPoints(4);_toast('صح! +4 نقاط 🧠');}else{_toast('مو هذا الجواب، جرّب مرة ثانية');}},child:const Text('تحقق من الجواب'))),const SizedBox(width:8),IconButton(onPressed:()=>setState(_nextRiddle),icon:const Icon(Icons.refresh))]),
    TextButton(onPressed:()=>_toast('الحل: $_answer'),child:const Text('إظهار الحل')),
  ]);
  Widget _speedCard()=>_SpeedChallenge(onWin:(){_addPoints(5);_wins++;_toast('بطل! +5 نقاط ⚡');});
}

class _SpeedChallenge extends StatefulWidget {
  final VoidCallback onWin;
  const _SpeedChallenge({required this.onWin});
  @override State<_SpeedChallenge> createState()=>_SpeedChallengeState();
}
class _SpeedChallengeState extends State<_SpeedChallenge>{
  int _count=0;DateTime? _start;bool _done=false;
  @override Widget build(BuildContext context)=>Column(children:[
    Text(_done?'أنهيتها خلال ${DateTime.now().difference(_start!).inSeconds} ثانية!': 'اضغط 10 مرات • $_count/10',style:const TextStyle(fontWeight:FontWeight.bold)),
    const SizedBox(height:8),
    SizedBox(width:double.infinity,child:FilledButton(onPressed:_done?null:(){setState((){_start??=DateTime.now();_count++;if(_count>=10){_done=true;widget.onWin();}});},child:Text(_done?'أحسنت!':'اضغط بسرعة ⚡'))),
    TextButton(onPressed:()=>setState((){_count=0;_start=null;_done=false;}),child:const Text('إعادة التحدي')),
  ]);
}
