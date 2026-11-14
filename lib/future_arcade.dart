import 'dart:math';
import 'package:flutter/material.dart';

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
  _ArcadeGame('millionaire','من سيربح المليون؟','أجب عن الأسئلة وتصاعد إلى الجائزة الكبرى',Icons.millionaires_rounded,'أسئلة'),
  _ArcadeGame('sudoku','سودوكو','املأ الشبكة بالأرقام دون تكرار',Icons.numbers_rounded,'ذكاء'),
  _ArcadeGame('wordsearch','البحث عن الكلمات','اكتشف الكلمات المخفية داخل الشبكة',Icons.search_rounded,'ذكاء'),
  _ArcadeGame('bomb','ساحة القنابل','تحرك بذكاء وضع القنابل لتفتح الطريق',Icons.bomb_rounded,'2D'),
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
  bool _revealed=false,_ended=false;
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
  void _reset(){setState((){_score=0;_step=0;_turn=0;_lane=1;_position=0;_wave=1;_fish=0;_selected=null;_revealed=false;_ended=false;_message='ابدأ التحدي!';_snake..clear()..addAll([27,28,29]);_bombs.clear();_sudoku..clear()..addAll([[1,0,0,4],[0,4,1,0],[0,1,4,0],[4,0,0,1]]);_wordInput='';});}
}

class ArcadeAchievementsPage extends StatelessWidget {
  const ArcadeAchievementsPage({super.key});
  @override Widget build(BuildContext context)=>Directionality(textDirection:TextDirection.rtl,child:Scaffold(appBar:AppBar(title:const Text('الإنجازات والمكافآت')),body:ListView(padding:const EdgeInsets.all(16),children:[
    Card(child:ListTile(leading:const Icon(Icons.stars_rounded,color:Colors.amber,size:34),title:const Text('جامع النقاط'),subtitle:const Text('اجمع النقاط من الألعاب والتحديات'),trailing:const Text('0 XP'))),
    Card(child:ListTile(leading:const Icon(Icons.military_tech_rounded,color:Colors.amber,size:34),title:const Text('بداية الأسطورة'),subtitle:const Text('أكمل أول لعبة'),trailing:const Text('مقفل'))),
    Card(child:ListTile(leading:const Icon(Icons.local_fire_department_rounded,color:Colors.deepOrange,size:34),title:const Text('سلسلة الفوز'),subtitle:const Text('حقق 3 انتصارات متتالية'),trailing:const Text('مقفل'))),
    const Padding(padding:EdgeInsets.all(12),child:Text('لوحة الإنجازات مع حفظ الحساب والمتجر والجوائز الموثقة تحتاج ربط خدمة المكافآت الموثوقة قبل إتاحة العملات القابلة للصرف.')),
    OutlinedButton.icon(onPressed:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const ArcadeRoomsPage())),icon:const Icon(Icons.groups_rounded),label:const Text('الغرف الخاصة والدردشة')),
  ])));
}

class ArcadeRoomsPage extends StatelessWidget {
  const ArcadeRoomsPage({super.key});
  @override Widget build(BuildContext context)=>Directionality(textDirection:TextDirection.rtl,child:Scaffold(appBar:AppBar(title:const Text('الغرف الخاصة')),body:const Center(child:Padding(padding:EdgeInsets.all(24),child:Text('واجهة الغرف قيد ربطها بمزامنة Firestore والدعوات والدردشة. الألعاب الجديدة تعمل حالياً محلياً على الجهاز.',textAlign:TextAlign.center))))));
}
