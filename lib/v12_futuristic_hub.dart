import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'achievement_hub.dart';
import 'community_events.dart';
import 'community_polls.dart';
import 'creative_library.dart';
import 'friends_battle_arena.dart';
import 'future_dashboard.dart';
import 'game_center.dart';
import 'knowledge_corner.dart';
import 'premium_media_hub.dart';
import 'v6_community_suite.dart';
import 'v12_personal_studio.dart';
import 'v12_companion_center.dart';

const _navy=Color(0xFF0B1024),_purple=Color(0xFF927CFF),_cyan=Color(0xFF42D9E8);

class V12FuturisticHubPage extends StatefulWidget {
  const V12FuturisticHubPage({super.key});
  @override State<V12FuturisticHubPage> createState()=>_V12FuturisticHubPageState();
}
class _V12FuturisticHubPageState extends State<V12FuturisticHubPage>{
  static const _missions=['شارك بفكرة إيجابية مع المجتمع','أكمل تحدي المعرفة اليومي','تواصل مع صديق أو عضو جديد','استكشف قسماً جديداً في الملتقى'];
  static const _questions=[
    {'q':'ما الكوكب المعروف بالكوكب الأحمر؟','a':['الزهرة','المريخ','زحل'],'c':1},
    {'q':'كم ضلعاً للمسدس؟','a':['خمسة','ستة','ثمانية'],'c':1},
    {'q':'ما أكبر محيط على الأرض؟','a':['الهادئ','الأطلسي','الهندي'],'c':0},
    {'q':'أي عنصر رمزه O؟','a':['الذهب','الأكسجين','الفضة'],'c':1},
  ];
  int _xp=0,_correct=0,_q=0;
  bool _high=false,_loaded=false,_answered=false;
  List<bool> _done=List<bool>.filled(4,false);
  int get _level=>1+(_xp~/100);
  int get _progress=>_xp%100;
  @override void initState(){super.initState();_q=DateTime.now().day%_questions.length;_load();}
  Future<void> _load()async{
    final p=await SharedPreferences.getInstance();if(!mounted)return;
    setState((){_xp=p.getInt('v12_xp')??0;_high=p.getBool('v12_high')??false;_done=List<bool>.generate(4,(i)=>p.getBool('v12_mission_$i')??false);_loaded=true;});
  }
  Future<void> _save()async{final p=await SharedPreferences.getInstance();await p.setInt('v12_xp',_xp);for(var i=0;i<4;i++){await p.setBool('v12_mission_$i',_done[i]);}}
  Future<void> _mission(int i,bool v)async{setState((){_done[i]=v;_xp=math.max(0,_xp+(v?20:-20)).toInt();});await _save();}
  Future<void> _performance(bool v)async{setState(()=>_high=v);final p=await SharedPreferences.getInstance();await p.setBool('v12_high',v);}
  void _open(Widget page)=>Navigator.push(context,MaterialPageRoute(builder:(_)=>page));
  void _answer(int i){if(_answered)return;final ok=i==_questions[_q]['c'];setState((){_answered=true;if(ok){_correct++;_xp+=15;}});_save();ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(ok?'إجابة صحيحة! +15 XP':'مو مشكلة، جرّب تحدي باچر!')));}
  @override Widget build(BuildContext context){
    final q=_questions[_q],answers=q['a'] as List<String>;
    return Directionality(textDirection:TextDirection.rtl,child:Scaffold(backgroundColor:_navy,appBar:AppBar(title:const Text('V12 • عالم المستقبل'),backgroundColor:_navy,foregroundColor:Colors.white,actions:[IconButton(onPressed:_showPerformance,icon:const Icon(Icons.speed_rounded))]),body:!_loaded?const Center(child:CircularProgressIndicator(color:_cyan)):ListView(padding:const EdgeInsets.all(16),children:[
      _hero(),const SizedBox(height:16),_levelCard(),const SizedBox(height:20),_section('مهماتك اليومية','أنجز المهمات واجمع نقاط الخبرة'),
      ...List.generate(4,(i)=>CheckboxListTile(value:_done[i],onChanged:(v)=>_mission(i,v??false),activeColor:_purple,title:Text(_missions[i],style:const TextStyle(color:Colors.white,fontSize:13)),secondary:const CircleAvatar(backgroundColor:Color(0xFF30285F),child:Icon(Icons.bolt,color:_purple)),tileColor:const Color(0xFF171D36),shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(15)))),
      const SizedBox(height:18),_section('تحدي المعرفة اليومي','سؤال اليوم • نقاط إضافية للإجابة الصحيحة'),_quiz(q,answers),
      const SizedBox(height:20),_section('عوالم الملتقى','مداخل سريعة إلى أقسامك المفضلة'),
      _tile('استوديو المستقبل','هويتك ومسوداتك وذكرياتك وتفضيلاتك',Icons.dashboard_customize,_cyan,()=>_open(const V12PersonalStudioPage())),
      _tile('مركز المستقبل الشامل','صالات صوتية وبطولات وترجمة وأمان الحساب',Icons.hub,_purple,()=>_open(const V12CompanionCenterPage())),
      _tile('المجتمع والأندية','غرف واهتمامات ونقاشات',Icons.groups,_cyan,()=>_open(const V6CommunitySuitePage())),
      _tile('مركز الألعاب','ألعاب وتحديات متنوعة',Icons.sports_esports,_purple,()=>_open(const GameCenterPage())),
      _tile('منافسات الأصدقاء','تحديات ومواجهات جماعية',Icons.people_alt,Colors.greenAccent,()=>_open(const FriendsBattleArenaPage())),
      _tile('الإنجازات والمستويات','تابع أوسمتك وتقدمك',Icons.emoji_events,Colors.amber,()=>_open(const AchievementHubPage())),
      _tile('السينما والميديا','مكتبتك ومشغلاتك',Icons.movie_filter,Colors.pinkAccent,()=>_open(const PremiumMediaHubPage())),
      _tile('فعاليات المجتمع','أنشطة ومواعيد المجتمع',Icons.event,_cyan,()=>_open(const CommunityEventsPage())),
      _tile('ركن المعرفة','اكتشف وتعلّم كل يوم',Icons.lightbulb,Colors.amber,()=>_open(const KnowledgeCornerPage())),
      _tile('لوحة أهدافي','العادات والتركيز والملاحظات',Icons.track_changes,_purple,()=>_open(const FutureDashboardPage())),
      _tile('مكتبة الإبداع','عبارات وأفكار ومحتوى',Icons.auto_awesome,Colors.orangeAccent,()=>_open(const CreativeLibraryPage())),
      _tile('تصويتات المجتمع','صوت وشارك برأيك',Icons.poll,_cyan,()=>_open(const CommunityPollsPage())),
      const SizedBox(height:18),_section('مركز الأداء','اختر التجربة المناسبة لقدرات جهازك'),_performanceCard(),
      const SizedBox(height:16),const Center(child:Text('ملتقى شباب المستقبل • V12 FUTURISTIC',style:TextStyle(color:Colors.white38,fontSize:11))),
    ])));
  }
  Widget _hero()=>Container(padding:const EdgeInsets.all(22),decoration:BoxDecoration(borderRadius:BorderRadius.circular(26),gradient:const LinearGradient(begin:Alignment.topRight,end:Alignment.bottomLeft,colors:[Color(0xFF5542B8),Color(0xFF202B58),Color(0xFF123A50)]),border:Border.all(color:_cyan.withValues(alpha:.28)),boxShadow:[BoxShadow(color:_purple.withValues(alpha:.2),blurRadius:30,offset:const Offset(0,12))]),child:const Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Row(children:[Icon(Icons.auto_awesome,color:_cyan),SizedBox(width:8),Text('FUTURE EXPERIENCE • V12',style:TextStyle(color:Colors.white70,fontWeight:FontWeight.w800,fontSize:11))]),SizedBox(height:15),Text('مستقبلك يبدأ من هنا',style:TextStyle(color:Colors.white,fontSize:25,fontWeight:FontWeight.w900)),SizedBox(height:7),Text('اكتشف، نافس، تعلّم، واجمع الإنجازات مع مجتمعك.',style:TextStyle(color:Colors.white70))]));
  Widget _levelCard()=>Container(padding:const EdgeInsets.all(16),decoration:BoxDecoration(color:const Color(0xFF171D36),borderRadius:BorderRadius.circular(20)),child:Column(children:[Row(children:[const Icon(Icons.military_tech,color:Colors.amber,size:30),const SizedBox(width:10),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('المستوى $_level',style:const TextStyle(color:Colors.white,fontWeight:FontWeight.w900,fontSize:17)),Text(_xp.toString()+' XP • '+(100-_progress).toString()+' نقطة للمستوى التالي',style:const TextStyle(color:Colors.white60,fontSize:11))]))]),const SizedBox(height:12),ClipRRect(borderRadius:BorderRadius.circular(20),child:LinearProgressIndicator(value:_progress/100,minHeight:9,backgroundColor:Colors.white12,color:_cyan))]));
  Widget _section(String a,String b)=>Padding(padding:const EdgeInsets.only(bottom:10),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(a,style:const TextStyle(color:Colors.white,fontWeight:FontWeight.w900,fontSize:17)),Text(b,style:const TextStyle(color:Colors.white54,fontSize:11))]));
  Widget _quiz(Map<String,Object> q,List<String> a)=>Container(padding:const EdgeInsets.all(15),decoration:BoxDecoration(color:const Color(0xFF171D36),borderRadius:BorderRadius.circular(20)),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(q['q'] as String,style:const TextStyle(color:Colors.white,fontWeight:FontWeight.w800,fontSize:15)),const SizedBox(height:10),...List.generate(a.length,(i)=>Padding(padding:const EdgeInsets.only(bottom:6),child:OutlinedButton(onPressed:_answered?null:()=>_answer(i),style:OutlinedButton.styleFrom(foregroundColor:Colors.white,alignment:Alignment.centerRight),child:Align(alignment:Alignment.centerRight,child:Text(a[i]))))),Text('إجابات صحيحة: $_correct',style:const TextStyle(color:_cyan,fontSize:11))]));
  Widget _tile(String t,String s,IconData icon,Color c,VoidCallback fn)=>Padding(padding:const EdgeInsets.only(bottom:8),child:Material(color:const Color(0xFF171D36),borderRadius:BorderRadius.circular(17),child:InkWell(onTap:fn,borderRadius:BorderRadius.circular(17),child:Padding(padding:const EdgeInsets.all(13),child:Row(children:[Icon(icon,color:c,size:28),const SizedBox(width:12),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(t,style:const TextStyle(color:Colors.white,fontWeight:FontWeight.w800)),Text(s,style:const TextStyle(color:Colors.white54,fontSize:11))])),const Icon(Icons.chevron_left,color:Colors.white38)])))));
  Widget _performanceCard()=>SwitchListTile(value:_high,onChanged:_performance,activeColor:_cyan,title:Text(_high?'وضع الأداء العالي':'الوضع المتوازن',style:const TextStyle(color:Colors.white)),subtitle:Text(_high?'للأجهزة القوية':'استهلاك أخف لمعظم الأجهزة',style:const TextStyle(color:Colors.white54,fontSize:11)),tileColor:const Color(0xFF171D36),shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(16)));
  void _showPerformance()=>showModalBottomSheet<void>(context:context,backgroundColor:const Color(0xFF171D36),builder:(c)=>SafeArea(child:SwitchListTile(value:_high,onChanged:(v){Navigator.pop(c);_performance(v);},title:const Text('تفضيل وضع الأداء العالي',style:TextStyle(color:Colors.white)),activeColor:_cyan)));
}
