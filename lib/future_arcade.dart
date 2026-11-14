import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const _arcadeGames = <_ArcadeGame>[
  _ArcadeGame('ludo','لودو 2D','ارمِ النرد وحرّك أحجارك إلى خط النهاية',Icons.casino_rounded,'طاولة'),
  _ArcadeGame('jackaroo','جاكارو','اسحب الأوراق وحرّك أحجارك على المسار',Icons.style_rounded,'طاولة'),
  _ArcadeGame('chess','الشطرنج','تحدي تركيز وتخطيط على رقعة 8×8',Icons.grid_4x4_rounded,'ذكاء'),
  _ArcadeGame('mafia','المافيا','أدوار سرية ونقاش وتصويت بين الأصدقاء',Icons.visibility_off_rounded,'جماعية'),
  _ArcadeGame('racing','سباق السيارات','تفادى الحواجز واجمع أكبر عدد من النقاط',Icons.directions_car_rounded,'2D'),
  _ArcadeGame('snake','الثعبان المتنافس','كبّر ثعبانك واجمع الطعام على الشبكة',Icons.gesture_rounded,'2D'),
  _ArcadeGame('space','حرب الفضاء','قد سفينتك وأسقط الأهداف الفضائية',Icons.rocket_launch_rounded,'2D'),
  _ArcadeGame('platform','مغامرة المنصات','اقفز فوق العقبات واجمع النجوم',Icons.sports_martial_arts_rounded,'2D'),
  _ArcadeGame('tower','الدفاع عن القلعة','ابنِ الأبراج وصد موجات الأعداء',Icons.castle_rounded,'استراتيجية'),
  _ArcadeGame('fishing','صيد السمك','ارمِ السنارة وحاول صيد الأسماك النادرة',Icons.phishing_rounded,'خفيفة'),
  _ArcadeGame('millionaire','من سيربح المليون؟','أجب عن الأسئلة وتصاعد إلى الجائزة الكبرى',Icons.workspace_premium_rounded,'أسئلة'),
  _ArcadeGame('sudoku','سودوكو','املأ الشبكة بالأرقام دون تكرار',Icons.numbers_rounded,'ذكاء'),
  _ArcadeGame('wordsearch','البحث عن الكلمات','اكتشف الكلمات المخفية داخل الشبكة',Icons.search_rounded,'ذكاء'),
  _ArcadeGame('bomb','ساحة القنابل','تحرك بذكاء وضع القنابل لتفتح الطريق',Icons.whatshot_rounded,'2D'),
];

class _ArcadeGame {
  final String id, title, subtitle, category;
  final IconData icon;
  const _ArcadeGame(this.id,this.title,this.subtitle,this.icon,this.category);
}

class FutureArcadePage extends StatefulWidget {
  const FutureArcadePage({super.key});
  @override State<FutureArcadePage> createState()=>_FutureArcadePageState();
}

class _FutureArcadePageState extends State<FutureArcadePage> {
  String _filter='الكل';
  String _query='';
  final _search=TextEditingController();
  @override void dispose(){_search.dispose();super.dispose();}
  @override Widget build(BuildContext context){
    final shown=_arcadeGames.where((g)=>( _filter=='الكل'||g.category==_filter) && (g.title+g.subtitle).contains(_query)).toList();
    return Directionality(textDirection:TextDirection.rtl,child:Scaffold(
      appBar:AppBar(title:const Text('Future Arcade'),centerTitle:true,actions:[IconButton(tooltip:'الإنجازات',onPressed:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const ArcadeAchievementsPage())),icon:const Icon(Icons.emoji_events_rounded))]),
      body:CustomScrollView(slivers:[
        SliverToBoxAdapter(child:Padding(padding:const EdgeInsets.all(14),child:Container(
          padding:const EdgeInsets.all(20),decoration:BoxDecoration(borderRadius:BorderRadius.circular(26),gradient:const LinearGradient(colors:[Color(0xFF171936),Color(0xFF6554D9),Color(0xFF13A89E)],begin:Alignment.topRight,end:Alignment.bottomLeft)),
          child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
            const Row(children:[Icon(Icons.sports_esports_rounded,color:Colors.white,size:30),Spacer(),Text('PLAY • LEVEL UP • WIN',style:TextStyle(color:Colors.white70,fontWeight:FontWeight.w900))]),
            const SizedBox(height:14),const Text('عالمك، لعبك، تحدّيك! 🎮',style:TextStyle(color:Colors.white,fontWeight:FontWeight.w900,fontSize:23)),
            const SizedBox(height:6),const Text('14 لعبة جديدة بتجارب متنوعة — العب ونافس وحقق أرقاماً جديدة.',style:TextStyle(color:Colors.white70,height:1.5)),
            const SizedBox(height:16),Row(children:[
              Expanded(child:_stat('14','لعبة')),const SizedBox(width:8),Expanded(child:_stat('6','أنواع')),const SizedBox(width:8),Expanded(child:_stat('2D','أركيد')),
            ]),
            const SizedBox(height:14),Wrap(spacing:8,runSpacing:8,children:[
              OutlinedButton.icon(onPressed:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const ArcadeAchievementsPage())),icon:const Icon(Icons.military_tech_rounded),label:const Text('إنجازاتي'),style:OutlinedButton.styleFrom(foregroundColor:Colors.white,side:const BorderSide(color:Colors.white54))),
              OutlinedButton.icon(onPressed:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const ArcadeRoomsPage())),icon:const Icon(Icons.meeting_room_rounded),label:const Text('الغرف الخاصة'),style:OutlinedButton.styleFrom(foregroundColor:Colors.white,side:const BorderSide(color:Colors.white54))),
            ]),
          ]),
        ))),
        SliverToBoxAdapter(child:Padding(padding:const EdgeInsets.symmetric(horizontal:14),child:TextField(controller:_search,onChanged:(v)=>setState(()=>_query=v.trim()),decoration:InputDecoration(hintText:'ابحث عن لعبة...',prefixIcon:const Icon(Icons.search_rounded),filled:true,border:OutlineInputBorder(borderRadius:BorderRadius.circular(16),borderSide:BorderSide.none))))),
        SliverToBoxAdapter(child:SizedBox(height:55,child:ListView(scrollDirection:Axis.horizontal,padding:const EdgeInsets.symmetric(horizontal:12,vertical:7),children:['الكل','2D','طاولة','ذكاء','جماعية','استراتيجية','أسئلة','خفيفة'].map((f)=>Padding(padding:const EdgeInsets.symmetric(horizontal:4),child:ChoiceChip(label:Text(f),selected:_filter==f,onSelected:(_)=>setState(()=>_filter=f))).toList()))),
        SliverPadding(padding:const EdgeInsets.all(14),sliver:SliverGrid(delegate:SliverChildBuilderDelegate((c,i)=>_ArcadeCard(game:shown[i]),childCount:shown.length),gridDelegate:const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount:2,mainAxisSpacing:11,crossAxisSpacing:11,childAspectRatio:.88))),
        if(shown.isEmpty)const SliverToBoxAdapter(child:Padding(padding:EdgeInsets.all(30),child:Center(child:Text('ما لقينا لعبة بهذا الاسم.')))),
      ]),
    ));
  }
  Widget _stat(String v,String label)=>Container(padding:const EdgeInsets.symmetric(vertical:9),decoration:BoxDecoration(color:Colors.white.withValues(alpha:.13),borderRadius:BorderRadius.circular(13)),child:Column(children:[Text(v,style:const TextStyle(color:Colors.white,fontWeight:FontWeight.w900,fontSize:18)),Text(label,style:const TextStyle(color:Colors.white70,fontSize:11))]));
}

class _ArcadeCard extends StatelessWidget {
  final _ArcadeGame game;
  const _ArcadeCard({required this.game});
  @override Widget build(BuildContext context)=>Card(clipBehavior:Clip.antiAlias,child:InkWell(onTap:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>ArcadePlayPage(game:game))),child:Padding(padding:const EdgeInsets.all(13),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
    Container(width:48,height:48,decoration:BoxDecoration(color:Theme.of(context).colorScheme.primaryContainer,borderRadius:BorderRadius.circular(15)),child:Icon(game.icon,size:27)),
    const Spacer(),Text(game.title,style:const TextStyle(fontWeight:FontWeight.w900,fontSize:15)),
    const SizedBox(height:5),Text(game.subtitle,maxLines:2,overflow:TextOverflow.ellipsis,style:TextStyle(fontSize:11,color:Theme.of(context).colorScheme.onSurfaceVariant)),
    const SizedBox(height:9),Row(children:[Text('ابدأ اللعب',style:TextStyle(color:Theme.of(context).colorScheme.primary,fontWeight:FontWeight.w900)),const Spacer(),const Icon(Icons.arrow_back_rounded,size:17)]),
  ]))));
}

class ArcadePlayPage extends StatefulWidget {
  final _ArcadeGame game;
  const ArcadePlayPage({super.key,required this.game});
  @override State<ArcadePlayPage> createState()=>_ArcadePlayPageState();
}

class _ArcadePlayPageState extends State<ArcadePlayPage> {
  final _random=Random();
  int _score=0,_step=0,_turn=0,_lane=1,_position=0,_wave=1,_fish=0;
  int? _selected;
  bool _revealed=false,_ended=false,_rewardClaimed=false;
  String _message='ابدأ التحدي!';
  final List<int> _snake=[27,28,29];
  final List<int> _bombs=[];
  final List<String> _roles=['مواطن','مافيا','طبيب','محقق'];
  final List<String> _millionAnswers=['بغداد','المريخ','المحيط الهادئ','البرتغالية'];
  final List<String> _millionQuestions=['ما عاصمة العراق؟','ما الكوكب الأحمر؟','ما أكبر محيط؟','ما لغة البرازيل الرسمية؟'];
  final List<List<int>> _sudoku=[
    [1,0,0,4],[0,4,1,0],[0,1,4,0],[4,0,0,1]
  ];
  final List<List<int>> _solution=[
    [1,2,3,4],[3,4,1,2],[2,1,4,3],[4,3,2,1]
  ];
  final List<String> _wordGrid=['ك','ت','ا','ب','س','م','د','ر','س','ة','ق','ل','م','ن','و','ب','ي','ت','ر','ف','ش','م','س','ج','ل'];
  final List<String> _words=['كتاب','مدرسة','قلم','بيت','شمس'];
  String _wordInput='';
  @override Widget build(BuildContext context){
    final g=widget.game;
    return Directionality(textDirection:TextDirection.rtl,child:Scaffold(
      appBar:AppBar(title:Text(g.title),actions:[Padding(padding:const EdgeInsets.symmetric(horizontal:14),child:Center(child:Text('النقاط: '+_score.toString(),style:const TextStyle(fontWeight:FontWeight.w900))))]),
      body:SafeArea(child:ListView(padding:const EdgeInsets.all(16),children:[
        Container(padding:const EdgeInsets.all(16),decoration:BoxDecoration(borderRadius:BorderRadius.circular(20),gradient:const LinearGradient(colors:[Color(0xFF24204F),Color(0xFF6554D9)])),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          Text(g.subtitle,style:const TextStyle(color:Colors.white,height:1.5)),const SizedBox(height:10),
          Text(_message,style:const TextStyle(color:Colors.white,fontWeight:FontWeight.w800,fontSize:16)),
        ])),
        const SizedBox(height:16),_buildGame(g.id),
        if(_score>0&&!_rewardClaimed)Padding(padding:const EdgeInsets.only(bottom:8),child:FilledButton.icon(onPressed:_claimReward,icon:const Icon(Icons.card_giftcard_rounded),label:const Text('إنهاء الجولة واستلام النقاط والعملات'))),
        const SizedBox(height:18),OutlinedButton.icon(onPressed:_reset,icon:const Icon(Icons.refresh_rounded),label:const Text('إعادة اللعبة')),
        const SizedBox(height:8),const Text('نسخة لعب محلية أولية: اللعب على نفس الجهاز. الغرف المتزامنة والدردشة تُدار من صفحة الغرف.',textAlign:TextAlign.center,style:TextStyle(fontSize:11,color:Colors.grey)),
      ])),
    ));
  }
  Widget _buildGame(String id){
    switch(id){
      case 'ludo': return _panel('🎲 النرد والقطع',[
        Text('موقع حجرك: '+_position.toString()+' / 30',style:_big),
        _button('ارمِ النرد',(){final n=_random.nextInt(6)+1;setState((){_step=n;_message='ظهر الرقم '+n.toString()+' — حرّك حجرك.';});}),
        _button('حرّك الحجر',(){if(_step==0)return;setState((){_position=min(30,_position+_step);_score+=_step;_message=_position>=30?'وصلت للنهاية! فزت بالجولة 🏆':'تقدم حجرك إلى '+_position.toString();_step=0;});}),
      ]);
      case 'jackaroo': return _panel('🃏 أوراق جاكارو',[
        Text('تقدمك على المسار: '+_position.toString()+' / 40',style:_big),
        _button('اسحب ورقة',(){final n=_random.nextInt(13)+1;setState((){_step=n;_message='سحبت ورقة بقيمة '+n.toString()+'.';});}),
        _button('حرّك الحجر',(){if(_step==0)return;setState((){_position=min(40,_position+_step);_score+=_step;_step=0;_message='تحركت على المسار.';});}),
      ]);
      case 'chess': return _chessBoard();
      case 'mafia': return _panel('🕵️ توزيع الأدوار السرية',[
        Text('اللاعب '+(_turn+1).toString()+' من 4',style:_big),
        if(!_revealed)_button('اكشف دوري',(){setState((){_revealed=true;_message='دورك: '+_roles[_turn%_roles.length];});}),
        if(_revealed)Text('دورك هو: '+_roles[_turn%_roles.length],style:_big),
        _button('إخفاء وتسليم الهاتف',(){setState((){_revealed=false;_turn=(_turn+1)%4;_message='مرر الجهاز للاعب التالي.';});}),
        _button('ابدأ التصويت',(){setState((){_score++;_message='تم تسجيل جولة تصويت تجريبية.';});}),
      ]);
      case 'racing': return _panel('🏎️ حلبة السباق',[
        Text('المسار: '+_position.toString()+' • المسار الجانبي: '+(_lane+1).toString(),style:_big),
        _button('تحرك يسار',(){setState((){_lane=max(0,_lane-1);_position++;_score++;_message='غيرت المسار.';});}),
        _button('تقدم للأمام',(){setState((){_position++;if(_random.nextInt(4)==0){_message='اصطدمت بعائق! حاول تفاديه.';_score=max(0,_score-1);}else{_score+=2;_message='تجاوزت العائق بنجاح!';}});}),
        _button('تحرك يمين',(){setState((){_lane=min(2,_lane+1);_position++;_score++;_message='غيرت المسار.';});}),
      ]);
      case 'snake': return _panel('🐍 شبكة الثعبان 6×6',[
        _snakeBoard(),
        Wrap(spacing:8,children:['أعلى','أسفل','يمين','يسار'].map((d)=>_button(d,()=>_moveSnake(d))).toList()),
        _button('التقط الطعام',(){setState((){_score+=5;_message='أكلت الطعام وكبر الثعبان!';});}),
      ]);
      case 'space': return _panel('🚀 سفينة الفضاء',[
        Text('طاقة السفينة: '+(100-min(100,_step*8)).toString()+'%',style:_big),
        _button('تحرك يسار',(){setState((){_lane=max(0,_lane-1);_message='تحركت يساراً.';});}),
        _button('أطلق النار',(){setState((){_step++;_score+=_random.nextInt(3)+1;_message='إصابة الهدف! مجموع الأهداف '+_step.toString();});}),
        _button('تحرك يمين',(){setState((){_lane=min(4,_lane+1);_message='تحركت يميناً.';});}),
      ]);
      case 'platform': return _panel('⭐ مسار المغامرة',[
        Text('المستوى: '+(_wave).toString()+' • النجوم: '+_score.toString(),style:_big),
        _button('اقفز',(){setState((){_position++;if(_random.nextInt(5)==0){_message='اصطدمت بعقبة. حاول مرة ثانية!';}else{_score++;_message='قفزة ناجحة وجمعت نجمة!';if(_position%5==0)_wave++;}});}),
        _button('اندفاع سريع',(){setState((){_position+=2;_score+=2;_message='اندفاع ممتاز!';});}),
      ]);
      case 'tower': return _panel('🏰 الدفاع عن القلعة',[
        Text('الموجة: '+_wave.toString()+' • قوة القلعة: '+(100-_step*5).toString(),style:_big),
        _button('ابنِ برجاً',(){setState((){_step++;_message='تم بناء برج دفاعي.';});}),
        _button('أطلق الأبراج',(){setState((){_score+=_step*2;_wave++;_message='تم صد الموجة '+(_wave-1).toString()+'!';});}),
        _button('طوّر القلعة',(){setState((){_step++;_score=max(0,_score-2);_message='زادت قوة الدفاع.';});}),
      ]);
      case 'fishing': return _panel('🎣 رحلة الصيد',[
        Text('الأسماك المصطادة: '+_fish.toString(),style:_big),
        _button('ارمِ السنارة',(){setState((){_step=1;_message='انتظر الإشارة ثم اسحب السنارة!';});}),
        _button('اسحب السنارة',(){if(_step==0)return;setState((){_step=0;final rare=_random.nextInt(5)==0;_fish++;_score+=rare?10:2;_message=rare?'اصطدت سمكة نادرة! 🐠':'اصطدت سمكة جديدة.';});}),
      ]);
      case 'millionaire': return _millionaire();
      case 'sudoku': return _sudokuBoard();
      case 'wordsearch': return _wordSearch();
      case 'bomb': return _bombBoard();
      default:return const SizedBox.shrink();
    }
  }
  Widget _panel(String title,List<Widget> children)=>Container(padding:const EdgeInsets.all(15),decoration:BoxDecoration(borderRadius:BorderRadius.circular(20),color:Theme.of(context).colorScheme.surfaceContainer),child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[Text(title,style:_big),const SizedBox(height:12),...children]));
  TextStyle get _big=>const TextStyle(fontSize:17,fontWeight:FontWeight.w900);
  Widget _button(String label,VoidCallback onTap)=>Padding(padding:const EdgeInsets.only(top:8),child:FilledButton(onPressed:_ended?null:onTap,child:Text(label)));
  void _moveSnake(String direction){
    setState((){final head=_snake.last;int next=head;if(direction=='أعلى')next=max(0,head-6);if(direction=='أسفل')next=min(35,head+6);if(direction=='يمين')next=(head%6==5)?head:head+1;if(direction=='يسار')next=(head%6==0)?head:head-1;if(_snake.contains(next)){_message='اصطدمت بنفسك! أعد المحاولة.';_score=max(0,_score-1);}else{_snake.add(next);if(_random.nextBool())_snake.removeAt(0);_score++;_message='تحرك الثعبان.';}});
  }
  Widget _snakeBoard()=>GridView.builder(shrinkWrap:true,physics:const NeverScrollableScrollPhysics(),itemCount:36,gridDelegate:const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount:6),itemBuilder:(c,i)=>Container(margin:const EdgeInsets.all(2),decoration:BoxDecoration(color:_snake.contains(i)?Colors.green: i==5?Colors.red:Theme.of(context).colorScheme.surfaceContainerHighest,borderRadius:BorderRadius.circular(5)),child:Center(child:Text(_snake.contains(i)?'●':i==5?'●':'',style:const TextStyle(color:Colors.white)))));
  Widget _chessBoard(){
    const pieces=['♜','♞','♝','♛','♚','♝','♞','♜'];
    return _panel('♟ رقعة الشطرنج',[
      GridView.builder(shrinkWrap:true,physics:const NeverScrollableScrollPhysics(),itemCount:64,gridDelegate:const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount:8),itemBuilder:(c,i){final row=i~/8,col=i%8;final dark=(row+col).isOdd;final initial=(row==0)?pieces[col]:(row==1?'♟':row==6?'♙':row==7?pieces[col].replaceAll('♜','♖').replaceAll('♞','♘').replaceAll('♝','♗').replaceAll('♛','♕').replaceAll('♚','♔'):'');return InkWell(onTap:(){setState((){if(_selected==null){_selected=i;_message='اخترت خانة. اضغط خانة أخرى لنقل القطعة.';}else{_selected=null;_score++;_message='تم تسجيل الحركة المحلية. تحقق من قواعد الحركة بين اللاعبين.';}});},child:Container(color:_selected==i?Colors.amber:dark?const Color(0xFF7D8B9C):const Color(0xFFE8E1D5),child:Center(child:Text(initial,style:TextStyle(fontSize:22,color:row<2?Colors.black:Colors.black87)))));}),
      const Text('لوحة تدريب محلية للحركات؛ التحقق الكامل من قواعد كش مات والتبييت والترقية يحتاج محرك شطرنج مخصصاً.',style:TextStyle(fontSize:11,color:Colors.grey)),
    ]);
  }
  Widget _millionaire(){
    final i=min(_step,_millionQuestions.length-1);
    return _panel('💰 السؤال '+(i+1).toString()+' من 4',[
      Text(_millionQuestions[i],style:_big),
      ...(_millionOptions[i]).map((a)=>_button(a,(){setState((){if(a==_millionAnswers[i]){_score+=10;_message='إجابة صحيحة!';}else{_message='إجابة غير صحيحة. حاول بالسؤال التالي.';}_step++;if(_step>=_millionQuestions.length){_ended=true;_message='انتهت المسابقة! نقاطك '+_score.toString();}});})),
    ]);
  }
  final List<List<String>> _millionOptions=[
    ['البصرة','بغداد','أربيل','الموصل'],['الزهرة','المريخ','زحل','عطارد'],['الأطلسي','الهندي','الهادئ','المتجمد'],['الإسبانية','البرتغالية','الفرنسية','الإنجليزية']
  ];
  Widget _sudokuBoard(){
    return _panel('🔢 سودوكو 4×4',[
      const Text('اختر الخانة الفارغة ثم اختر الرقم المناسب.',style:TextStyle(fontSize:12)),
      GridView.builder(shrinkWrap:true,physics:const NeverScrollableScrollPhysics(),itemCount:16,gridDelegate:const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount:4),itemBuilder:(c,i){final v=_sudoku[i~/4][i%4];return InkWell(onTap:(){setState(()=>_selected=i);},child:Container(margin:const EdgeInsets.all(2),decoration:BoxDecoration(color:_selected==i?Colors.amber.withValues(alpha:.3):Theme.of(context).colorScheme.surface,border:Border.all(color:Colors.grey)),child:Center(child:Text(v==0?'':v.toString(),style:_big))));}),
      Wrap(spacing:8,children:[1,2,3,4].map((n)=>_button(n.toString(),(){if(_selected==null)return;setState((){final i=_selected!;_sudoku[i~/4][i%4]=n;_message='تم إدخال الرقم.';});})).toList()),
      _button('تحقق من الحل',(){setState((){bool ok=true;for(var r=0;r<4;r++){for(var c=0;c<4;c++){if(_sudoku[r][c]!=_solution[r][c])ok=false;}}_message=ok?'ممتاز! أكملت السودوكو.':'بعض الأرقام تحتاج مراجعة.';if(ok){_score+=20;_ended=true;}});}),
    ]);
  }
  Widget _wordSearch(){
    return _panel('🔎 شبكة الكلمات',[
      const Text('الكلمات المطلوبة: كتاب • مدرسة • قلم • بيت • شمس',style:TextStyle(fontWeight:FontWeight.w800)),
      GridView.builder(shrinkWrap:true,physics:const NeverScrollableScrollPhysics(),itemCount:25,gridDelegate:const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount:5),itemBuilder:(c,i)=>InkWell(onTap:(){setState((){_wordInput+=_wordGrid[i];_message='الحروف المختارة: '+_wordInput;});},child:Container(margin:const EdgeInsets.all(2),decoration:BoxDecoration(color:Theme.of(context).colorScheme.surfaceContainerHighest,borderRadius:BorderRadius.circular(6)),child:Center(child:Text(_wordGrid[i],style:_big)))),
      Text('اختيارك: '+_wordInput,style:_big),
      _button('تحقق من الكلمة',(){setState((){if(_words.contains(_wordInput)){_score+=5;_message='وجدت كلمة صحيحة!';_wordInput='';}else{_message='ليست كلمة من القائمة بعد.';}});}),
      _button('مسح الاختيار',(){setState(()=>_wordInput='');}),
    ]);
  }
  Widget _bombBoard(){
    return _panel('💣 ساحة 5×5',[
      const Text('تحرك على الخانات وضع القنابل في طريقك.',style:TextStyle(fontSize:12)),
      GridView.builder(shrinkWrap:true,physics:const NeverScrollableScrollPhysics(),itemCount:25,gridDelegate:const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount:5),itemBuilder:(c,i)=>InkWell(onTap:(){setState((){if(_bombs.contains(i)){_bombs.remove(i);_score+=3;_message='انفجرت القنبلة وفتحت الطريق!';}else{_selected=i;_message='انتقلت إلى خانة '+(i+1).toString();}});},child:Container(margin:const EdgeInsets.all(3),decoration:BoxDecoration(color:_selected==i?Colors.green:_bombs.contains(i)?Colors.deepOrange:Theme.of(context).colorScheme.surfaceContainerHighest,borderRadius:BorderRadius.circular(7)),child:Center(child:Text(_bombs.contains(i)?'💣':i==_selected?'🧍':'',style:_big)))),
      _button('ضع قنبلة',(){if(_selected==null)return;setState((){_bombs.add(_selected!);_message='وضعت قنبلة.';});}),
    ]);
  }
  Future<void> _claimReward() async {
    try {
      final id=widget.game.id;
      final result=await FirebaseFunctions.instance.httpsCallable('claimArcadeReward').call({
        'gameId':'arcade_'+id,
        'resultId':DateTime.now().microsecondsSinceEpoch.toString()+'_'+Random().nextInt(999999).toString(),
        'score':min(_score,500),
      });
      final data=Map<String,dynamic>.from(result.data as Map);
      if(!mounted)return;
      setState(()=>_rewardClaimed=true);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('حصلت على '+(data['xp']??0).toString()+' XP و '+(data['coins']??0).toString()+' عملة!')));
    } catch(e) {
      if(!mounted)return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('تعذر استلام المكافأة. تأكد من نشر Cloud Function: '+e.toString())));
    }
  }
  void _reset(){setState((){_score=0;_step=0;_turn=0;_lane=1;_position=0;_wave=1;_fish=0;_selected=null;_revealed=false;_ended=false;_rewardClaimed=false;_message='ابدأ التحدي!';_snake..clear()..addAll([27,28,29]);_bombs.clear();_sudoku..clear()..addAll([[1,0,0,4],[0,4,1,0],[0,1,4,0],[4,0,0,1]]);_wordInput='';});}
}

class ArcadeAchievementsPage extends StatelessWidget {
  const ArcadeAchievementsPage({super.key});
  @override Widget build(BuildContext context){
    final uid=FirebaseAuth.instance.currentUser!.uid;
    return Directionality(textDirection:TextDirection.rtl,child:Scaffold(appBar:AppBar(title:const Text('الإنجازات والمكافآت')),body:StreamBuilder<DocumentSnapshot<Map<String,dynamic>>>(stream:FirebaseFirestore.instance.collection('arcadeProfiles').doc(uid).snapshots(),builder:(c,s){
      final p=s.data?.data()??{};
      return ListView(padding:const EdgeInsets.all(16),children:[
        Card(child:ListTile(leading:const Icon(Icons.stars_rounded,color:Colors.amber,size:34),title:const Text('رصيد الخبرة'),subtitle:Text('المستوى '+(p['level']??1).toString()),trailing:Text((p['xp']??0).toString()+' XP'))),
        Card(child:ListTile(leading:const Icon(Icons.monetization_on_rounded,color:Colors.amber,size:34),title:const Text('عملات Future Arcade'),subtitle:const Text('مكافآت اللعب اليومية محدودة'),trailing:Text((p['coins']??0).toString()))),
        Card(child:ListTile(leading:const Icon(Icons.sports_esports_rounded),title:const Text('الألعاب المكتملة'),trailing:Text((p['gamesPlayed']??0).toString()))),
        Card(child:ListTile(leading:const Icon(Icons.military_tech_rounded,color:Colors.amber,size:34),title:const Text('أوسمة المتجر'),subtitle:Text('تملك '+((p['inventory'] as List?)?.length??0).toString()+' أوسمة'),trailing:Text(p['equippedBadge']??'بدون'))),
        const SizedBox(height:10),
        OutlinedButton.icon(onPressed:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const ArcadeStorePage())),icon:const Icon(Icons.storefront_rounded),label:const Text('متجر الأوسمة')),
        OutlinedButton.icon(onPressed:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const ArcadeLeaderboardPage())),icon:const Icon(Icons.leaderboard_rounded),label:const Text('لوحة المتصدرين')),
        OutlinedButton.icon(onPressed:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const ArcadeTournamentsPage())),icon:const Icon(Icons.emoji_events_rounded),label:const Text('البطولات')),
        OutlinedButton.icon(onPressed:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const ArcadeRoomsPage())),icon:const Icon(Icons.groups_rounded),label:const Text('الغرف الخاصة والدردشة')),
      ]);
    })));
  }
}

class ArcadeStorePage extends StatelessWidget {
  const ArcadeStorePage({super.key});
  static const _items=[
    ('bronze_star','نجمة برونزية','⭐',20),('flame','وسام اللهب','🔥',45),('crown','التاج الذهبي','👑',80),('rocket','وسام الصاروخ','🚀',65)
  ];
  @override Widget build(BuildContext context){
    final uid=FirebaseAuth.instance.currentUser!.uid;
    final ref=FirebaseFirestore.instance.collection('arcadeProfiles').doc(uid);
    return Directionality(textDirection:TextDirection.rtl,child:Scaffold(appBar:AppBar(title:const Text('متجر الأوسمة')),body:StreamBuilder<DocumentSnapshot<Map<String,dynamic>>>(stream:ref.snapshots(),builder:(c,s){
      final p=s.data?.data()??{};final coins=p['coins']??0;final inventory=List<String>.from(p['inventory']??[]);
      return ListView(padding:const EdgeInsets.all(14),children:[
        Card(child:ListTile(leading:const Icon(Icons.monetization_on_rounded,color:Colors.amber),title:const Text('رصيدك'),trailing:Text(coins.toString()+' عملة',style:const TextStyle(fontWeight:FontWeight.w900)))),
        ..._items.map((item){final owned=inventory.contains(item.$1);return Card(child:ListTile(leading:Text(item.$3,style:const TextStyle(fontSize:30)),title:Text(item.$2),subtitle:Text(item.$4.toString()+' عملة'),trailing:owned?FilledButton.tonal(onPressed:()=>ref.update({'equippedBadge':item.$1}),child:Text(p['equippedBadge']==item.$1?'مفعّل':'استخدم')):FilledButton(onPressed:()=>_buy(context,item.$1),child:const Text('شراء'))));}),
        if(!s.hasData||!s.data!.exists)const Padding(padding:EdgeInsets.all(12),child:Text('العب أولاً لتحصل على محفظة العملات.')),
      ]);
    })));
  }
  Future<void> _buy(BuildContext context,String badge) async {
    try{await FirebaseFunctions.instance.httpsCallable('purchaseArcadeBadge').call({'badgeId':badge});if(context.mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('تم شراء الوسام!')));}
    catch(e){if(context.mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('تعذر الشراء: '+e.toString())));}
  }
}

class ArcadeLeaderboardPage extends StatelessWidget {
  const ArcadeLeaderboardPage({super.key});
  @override Widget build(BuildContext context)=>Directionality(textDirection:TextDirection.rtl,child:Scaffold(appBar:AppBar(title:const Text('متصدرون Future Arcade')),body:StreamBuilder<QuerySnapshot<Map<String,dynamic>>>(stream:FirebaseFirestore.instance.collection('arcadeProfiles').orderBy('xp',descending:true).limit(50).snapshots(),builder:(c,s){if(s.hasError)return const Center(child:Text('تعذر تحميل الترتيب.'));if(!s.hasData)return const Center(child:CircularProgressIndicator());if(s.data!.docs.isEmpty)return const Center(child:Text('لا توجد نتائج بعد. العب واحصل على أول نقاطك!'));return ListView.builder(itemCount:s.data!.docs.length,itemBuilder:(c,i){final x=s.data!.docs[i].data();return ListTile(leading:CircleAvatar(child:Text((i+1).toString())),title:Text(x['displayName']??'لاعب'),subtitle:Text('المستوى '+(x['level']??1).toString()),trailing:Text((x['xp']??0).toString()+' XP'));});})));
}

class ArcadeTournamentsPage extends StatefulWidget {
  const ArcadeTournamentsPage({super.key});
  @override State<ArcadeTournamentsPage> createState()=>_ArcadeTournamentsPageState();
}
class _ArcadeTournamentsPageState extends State<ArcadeTournamentsPage> {
  final _db=FirebaseFirestore.instance;final _title=TextEditingController();String _game='arcade_ludo';bool _busy=false;
  String get _uid=>FirebaseAuth.instance.currentUser!.uid;
  static const _games={'arcade_ludo':'لودو 2D','arcade_jackaroo':'جاكارو','arcade_chess':'الشطرنج','arcade_mafia':'المافيا','arcade_racing':'سباق السيارات','arcade_snake':'الثعبان','arcade_space':'حرب الفضاء','arcade_platform':'مغامرة المنصات','arcade_tower':'الدفاع عن القلعة','arcade_fishing':'صيد السمك','arcade_millionaire':'من سيربح المليون؟','arcade_sudoku':'سودوكو','arcade_wordsearch':'البحث عن الكلمات','arcade_bomb':'ساحة القنابل'};
  Future<void> _create() async {
    if(_title.text.trim().length<3)return;
    setState(()=>_busy=true);
    try{await _db.collection('arcadeTournaments').add({'creatorId':_uid,'title':_title.text.trim(),'gameId':_game,'participants':[_uid],'status':'open','createdAt':FieldValue.serverTimestamp(),'updatedAt':FieldValue.serverTimestamp()});_title.clear();}
    catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('تعذر إنشاء البطولة: '+e.toString())));}
    finally{if(mounted)setState(()=>_busy=false);}
  }
  Future<void> _join(DocumentSnapshot<Map<String,dynamic>> doc) async {
    final x=doc.data()??{};final p=List<String>.from(x['participants']??[]);
    if(p.contains(_uid))return;
    try{await doc.reference.update({'participants':[...p,_uid],'updatedAt':FieldValue.serverTimestamp()});}
    catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('تعذر الانضمام: '+e.toString())));}
  }
  @override void dispose(){_title.dispose();super.dispose();}
  @override Widget build(BuildContext context)=>Directionality(textDirection:TextDirection.rtl,child:Scaffold(appBar:AppBar(title:const Text('بطولات الألعاب')),body:ListView(padding:const EdgeInsets.all(14),children:[
    Card(child:Padding(padding:const EdgeInsets.all(13),child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
      const Text('أنشئ بطولة جديدة',style:TextStyle(fontWeight:FontWeight.w900,fontSize:17)),
      TextField(controller:_title,decoration:const InputDecoration(labelText:'اسم البطولة')),
      const SizedBox(height:8),DropdownButtonFormField<String>(value:_game,items:_games.entries.map((e)=>DropdownMenuItem(value:e.key,child:Text(e.value))).toList(),onChanged:(v){if(v!=null)setState(()=>_game=v);},decoration:const InputDecoration(labelText:'اللعبة')),
      const SizedBox(height:8),FilledButton(onPressed:_busy?null:_create,child:const Text('إنشاء البطولة')),
    ]))),
    const SizedBox(height:12),const Text('البطولات المفتوحة',style:TextStyle(fontWeight:FontWeight.w900,fontSize:18)),
    StreamBuilder<QuerySnapshot<Map<String,dynamic>>>(stream:_db.collection('arcadeTournaments').where('status',isEqualTo:'open').snapshots(),builder:(c,s){if(s.hasError)return const Text('تعذر تحميل البطولات.');if(!s.hasData)return const Center(child:CircularProgressIndicator());return Column(children:s.data!.docs.map((d){final x=d.data();final joined=List<String>.from(x['participants']??[]).contains(_uid);return Card(child:ListTile(title:Text(x['title']??'بطولة'),subtitle:Text((_games[x['gameId']]??'لعبة')+' • '+List<String>.from(x['participants']??[]).length.toString()+' مشاركين'),trailing:joined?const Icon(Icons.check_circle,color:Colors.green):TextButton(onPressed:()=>_join(d),child:const Text('انضم'))));}).toList());}),
  ])));
}

class ArcadeRoomsPage extends StatefulWidget {
  const ArcadeRoomsPage({super.key});
  @override State<ArcadeRoomsPage> createState()=>_ArcadeRoomsPageState();
}
class _ArcadeRoomsPageState extends State<ArcadeRoomsPage> {
  final _db=FirebaseFirestore.instance;
  final _code=TextEditingController();
  String _game='arcade_ludo';
  bool _busy=false;
  String get _uid=>FirebaseAuth.instance.currentUser!.uid;
  static const _options={
    'arcade_ludo':'لودو 2D','arcade_jackaroo':'جاكارو','arcade_chess':'الشطرنج','arcade_mafia':'المافيا',
    'arcade_racing':'سباق السيارات','arcade_snake':'الثعبان','arcade_space':'حرب الفضاء','arcade_platform':'مغامرة المنصات',
    'arcade_tower':'الدفاع عن القلعة','arcade_fishing':'صيد السمك','arcade_millionaire':'من سيربح المليون؟',
    'arcade_sudoku':'سودوكو','arcade_wordsearch':'البحث عن الكلمات','arcade_bomb':'ساحة القنابل'
  };
  @override void dispose(){_code.dispose();super.dispose();}
  Future<void> _create() async {
    setState(()=>_busy=true);
    try{
      final room=_db.collection('arcadeRooms').doc();
      final code=(Random().nextInt(900000)+100000).toString();
      await room.set({'hostId':_uid,'gameId':_game,'members':[_uid],'roomCode':code,'status':'waiting','visibility':'private','state':{},'createdAt':FieldValue.serverTimestamp(),'updatedAt':FieldValue.serverTimestamp()});
      if(mounted)Navigator.push(context,MaterialPageRoute(builder:(_)=>ArcadeRoomChatPage(roomId:room.id,title:_options[_game]??'غرفة ألعاب',roomCode:code)));
    }catch(e){_show('تعذر إنشاء الغرفة: '+e.toString());}
    finally{if(mounted)setState(()=>_busy=false);}
  }
  Future<void> _join() async {
    final code=_code.text.trim();
    if(!RegExp(r'^\d{6}).hasMatch(code)){_show('أدخل رمزاً من 6 أرقام.');return;}
    setState(()=>_busy=true);
    try{
      final found=await _db.collection('arcadeRooms').where('roomCode',isEqualTo:code).limit(1).get();
      if(found.docs.isEmpty){_show('الغرفة غير موجودة أو بدأت بالفعل.');return;}
      final doc=found.docs.first;final data=doc.data();final members=List<String>.from(data['members']??[]);
      if(members.contains(_uid)){if(mounted)Navigator.push(context,MaterialPageRoute(builder:(_)=>ArcadeRoomChatPage(roomId:doc.id,title:_options[data['gameId']]??'غرفة ألعاب',roomCode:code)));return;}
      if(members.length>=4){_show('الغرفة مكتملة.');return;}
      members.add(_uid);
      await doc.reference.update({'members':members,'status':'playing','updatedAt':FieldValue.serverTimestamp()});
      if(mounted)Navigator.push(context,MaterialPageRoute(builder:(_)=>ArcadeRoomChatPage(roomId:doc.id,title:_options[data['gameId']]??'غرفة ألعاب',roomCode:code)));
    }catch(e){_show('تعذر الانضمام: '+e.toString());}
    finally{if(mounted)setState(()=>_busy=false);}
  }
  void _show(String value){if(!mounted)return;ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(value)));}
  @override Widget build(BuildContext context)=>Directionality(textDirection:TextDirection.rtl,child:Scaffold(
    appBar:AppBar(title:const Text('الغرف الخاصة')),
    body:ListView(padding:const EdgeInsets.all(16),children:[
      Card(child:Padding(padding:const EdgeInsets.all(14),child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
        const Text('أنشئ غرفة وادعُ أصدقاءك',style:TextStyle(fontWeight:FontWeight.w900,fontSize:18)),
        const SizedBox(height:12),
        DropdownButtonFormField<String>(value:_game,decoration:const InputDecoration(labelText:'اختر اللعبة'),items:_options.entries.map((e)=>DropdownMenuItem(value:e.key,child:Text(e.value))).toList(),onChanged:(v){if(v!=null)setState(()=>_game=v);}),
        const SizedBox(height:10),FilledButton.icon(onPressed:_busy?null:_create,icon:const Icon(Icons.add_circle_outline),label:const Text('إنشاء غرفة خاصة')),
        const Divider(height:26),TextField(controller:_code,keyboardType:TextInputType.number,maxLength:6,decoration:const InputDecoration(labelText:'رمز الغرفة',counterText:'',prefixIcon:Icon(Icons.key_rounded))),
        OutlinedButton.icon(onPressed:_busy?null:_join,icon:const Icon(Icons.login_rounded),label:const Text('انضم إلى غرفة')),
      ]))),
      const SizedBox(height:8),const Text('غرفي',style:TextStyle(fontWeight:FontWeight.w900,fontSize:18)),
      StreamBuilder<QuerySnapshot<Map<String,dynamic>>>(stream:_db.collection('arcadeRooms').where('members',arrayContains:_uid).snapshots(),builder:(context,s){
        if(s.hasError)return const Padding(padding:EdgeInsets.all(18),child:Text('تعذر تحميل الغرف. تأكد من نشر قواعد Firestore الجديدة.'));
        if(!s.hasData)return const Center(child:CircularProgressIndicator());
        if(s.data!.docs.isEmpty)return const Padding(padding:EdgeInsets.all(18),child:Text('ما عندك غرف بعد. أنشئ غرفة وشارك الرمز.'));
        return Column(children:s.data!.docs.map((d){final x=d.data();return Card(child:ListTile(leading:const Icon(Icons.meeting_room_rounded),title:Text(_options[x['gameId']]??'غرفة ألعاب'),subtitle:Text('الرمز: '+(x['roomCode']??'')+' • '+(x['status']??'')),trailing:const Icon(Icons.chevron_left),onTap:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>ArcadeRoomChatPage(roomId:d.id,title:_options[x['gameId']]??'غرفة ألعاب',roomCode:x['roomCode']??''))));}).toList());
      }),
    ]),
  ));
}

class ArcadeRoomChatPage extends StatefulWidget {
  final String roomId,title,roomCode;
  const ArcadeRoomChatPage({super.key,required this.roomId,required this.title,required this.roomCode});
  @override State<ArcadeRoomChatPage> createState()=>_ArcadeRoomChatPageState();
}
class _ArcadeRoomChatPageState extends State<ArcadeRoomChatPage> {
  final _db=FirebaseFirestore.instance;final _text=TextEditingController();
  String get _uid=>FirebaseAuth.instance.currentUser!.uid;
  Future<void> _send() async {
    final value=_text.text.trim();if(value.isEmpty)return;
    _text.clear();
    try{await _db.collection('arcadeRooms').doc(widget.roomId).collection('chat').add({'uid':_uid,'text':value,'createdAt':FieldValue.serverTimestamp()});}
    catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('تعذر إرسال الرسالة: '+e.toString())));}
  }
  Future<void> _invite() async {
    final controller=TextEditingController();
    final id=await showDialog<String>(context:context,builder:(c)=>AlertDialog(title:const Text('دعوة صديق'),content:TextField(controller:controller,decoration:const InputDecoration(hintText:'معرّف حساب الصديق UID')),actions:[TextButton(onPressed:()=>Navigator.pop(c),child:const Text('إلغاء')),FilledButton(onPressed:()=>Navigator.pop(c,controller.text.trim()),child:const Text('إرسال'))]));
    if(id==null||id.isEmpty||id==_uid)return;
    try{final room=(await _db.collection('arcadeRooms').doc(widget.roomId).get()).data()??{};await _db.collection('gameInvites').add({'from':_uid,'fromName':FirebaseAuth.instance.currentUser?.displayName??'عضو','to':id,'game':room['gameId'],'roomId':widget.roomId,'status':'pending','createdAt':FieldValue.serverTimestamp()});if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('تم إرسال الدعوة.')));}
    catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('تعذر إرسال الدعوة: '+e.toString())));}
  }
  @override void dispose(){_text.dispose();super.dispose();}
  @override Widget build(BuildContext context)=>Directionality(textDirection:TextDirection.rtl,child:Scaffold(
    appBar:AppBar(title:Text(widget.title),actions:[IconButton(onPressed:_invite,icon:const Icon(Icons.person_add_alt_1_rounded)),IconButton(onPressed:()=>Clipboard.setData(ClipboardData(text:widget.roomCode)),icon:const Icon(Icons.copy_rounded))]),
    body:Column(children:[
      Container(width:double.infinity,padding:const EdgeInsets.all(12),color:Theme.of(context).colorScheme.surfaceContainer,child:Text('رمز الغرفة: '+widget.roomCode,style:const TextStyle(fontWeight:FontWeight.w900))),
      Expanded(child:StreamBuilder<QuerySnapshot<Map<String,dynamic>>>(stream:_db.collection('arcadeRooms').doc(widget.roomId).collection('chat').orderBy('createdAt').limit(100).snapshots(),builder:(c,s){if(!s.hasData)return const Center(child:CircularProgressIndicator());return ListView(padding:const EdgeInsets.all(12),children:s.data!.docs.map((d){final x=d.data();final mine=x['uid']==_uid;return Align(alignment:mine?Alignment.centerLeft:Alignment.centerRight,child:Container(margin:const EdgeInsets.symmetric(vertical:4),padding:const EdgeInsets.all(11),constraints:const BoxConstraints(maxWidth:300),decoration:BoxDecoration(color:mine?Theme.of(context).colorScheme.primaryContainer:Theme.of(context).colorScheme.surfaceContainerHighest,borderRadius:BorderRadius.circular(14)),child:Text(x['text']??'')));}).toList());})),
      SafeArea(top:false,child:Padding(padding:const EdgeInsets.all(10),child:Row(children:[Expanded(child:TextField(controller:_text,onSubmitted:(_)=>_send(),decoration:const InputDecoration(hintText:'اكتب رسالة للغرفة...',border:OutlineInputBorder()))),const SizedBox(width:8),IconButton.filled(onPressed:_send,icon:const Icon(Icons.send_rounded))]))),
    ]),
  ));
}
