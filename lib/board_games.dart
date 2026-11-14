import 'dart:math';
import 'package:flutter/material.dart';

const _boardAccent = Color(0xFF6554D9);

class BoardGamesPage extends StatelessWidget {
  const BoardGamesPage({super.key});
  @override Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.rtl,
    child: Scaffold(appBar: AppBar(title: const Text('ألعاب الطاولة')),
      body: ListView(padding: const EdgeInsets.all(14), children: [
        const Text('ألعاب محلية لشخصين على نفس الجهاز. مرّروا الجهاز بينكم بعد كل دور.'),
        const SizedBox(height: 12),
        _tile(context, 'الدومينو', '28 قطعة • اسحب أو طابق القطع', Icons.view_week, const DominoGamePage()),
        _tile(context, 'الدامة', 'لوحة 8×8 • حركة وأكل وترقية إلى ملك', Icons.grid_4x4, const CheckersGamePage()),
      ])),
  );
  Widget _tile(BuildContext c,String title,String subtitle,IconData icon,Widget page)=>Card(child:ListTile(
    contentPadding:const EdgeInsets.all(14),leading:CircleAvatar(backgroundColor:_boardAccent.withValues(alpha:.12),child:Icon(icon,color:_boardAccent)),
    title:Text(title,style:const TextStyle(fontWeight:FontWeight.bold)),subtitle:Text(subtitle),trailing:const Icon(Icons.chevron_left),
    onTap:()=>Navigator.push(c,MaterialPageRoute(builder:(_)=>page))));
}

class _DominoTile {
  final int a,b;
  const _DominoTile(this.a,this.b);
  bool fits(int v)=>a==v||b==v;
  int other(int v)=>a==v?b:a;
  @override String toString()=>a.toString()+'|'+b.toString();
}

class DominoGamePage extends StatefulWidget {
  const DominoGamePage({super.key});
  @override State<DominoGamePage> createState()=>_DominoGamePageState();
}
class _DominoGamePageState extends State<DominoGamePage>{
  final rng=Random();
  late List<_DominoTile> pile,handA,handB;
  final chain=<_DominoTile>[];
  bool turnA=true;
  String notice='ابدأ بوضع أي قطعة من يدك';
  int scoreA=0,scoreB=0;
  @override void initState(){super.initState();newRound();}
  void newRound(){
    final all=<_DominoTile>[];
    for(var a=0;a<=6;a++){for(var b=a;b<=6;b++){all.add(_DominoTile(a,b));}}
    all.shuffle(rng);pile=all.sublist(14);handA=all.sublist(0,7);handB=all.sublist(7,14);
    chain.clear();turnA=true;notice='دور اللاعب الأول: ابدأ بأي قطعة';setState((){});
  }
  List<_DominoTile> get hand=>turnA?handA:handB;
  int? get left=>chain.isEmpty?null:chain.first.a;
  int? get right=>chain.isEmpty?null:chain.last.b;
  void play(int i,bool toLeft){
    if(i<0||i>=hand.length)return;
    final t=hand[i];
    if(chain.isEmpty){chain.add(t);}
    else if(toLeft&&t.fits(left!)){final v=left!;chain.insert(0,_DominoTile(t.other(v),v));}
    else if(!toLeft&&t.fits(right!)){final v=right!;chain.add(_DominoTile(v,t.other(v)));}
    else{notice='هذه القطعة لا تطابق الطرف المطلوب';setState((){});return;}
    hand.removeAt(i);
    if(hand.isEmpty){if(turnA){scoreA++;}else{scoreB++;}notice='فاز اللاعب '+(turnA?'الأول':'الثاني')+'! النتيجة '+scoreA.toString()+' - '+scoreB.toString();setState((){});return;}
    turnA=!turnA;notice='تم وضع القطعة. دور اللاعب '+(turnA?'الأول':'الثاني');setState((){});
  }
  void draw(){if(pile.isEmpty){notice='انتهت قطع السحب؛ حاول اللعب من الطرفين';}else{hand.add(pile.removeLast());notice='سحبت قطعة. دورك مستمر';}setState((){});}
  Widget tile(_DominoTile t)=>Container(width:54,height:30,margin:const EdgeInsets.all(3),decoration:BoxDecoration(color:Colors.white,border:Border.all(color:_boardAccent),borderRadius:BorderRadius.circular(7)),child:Row(children:[
    Expanded(child:Center(child:Text(t.a.toString(),style:const TextStyle(fontWeight:FontWeight.bold)))),
    Container(width:1,color:_boardAccent),Expanded(child:Center(child:Text(t.b.toString(),style:const TextStyle(fontWeight:FontWeight.bold)))),
  ]));
  @override Widget build(BuildContext c)=>Directionality(textDirection:TextDirection.rtl,child:Scaffold(
    appBar:AppBar(title:const Text('الدومينو'),actions:[IconButton(onPressed:newRound,icon:const Icon(Icons.refresh))]),
    body:ListView(padding:const EdgeInsets.all(12),children:[
      Card(child:Padding(padding:const EdgeInsets.all(12),child:Row(mainAxisAlignment:MainAxisAlignment.spaceAround,children:[
        Text('الأول: '+scoreA.toString()),Text('الثاني: '+scoreB.toString()),Text('السحب: '+pile.length.toString()),
      ]))),
      Center(child:Text(notice,textAlign:TextAlign.center)),const SizedBox(height:10),
      const Text('سلسلة القطع',style:TextStyle(fontWeight:FontWeight.bold)),
      Container(height:70,decoration:BoxDecoration(color:const Color(0xFFEDEAF6),borderRadius:BorderRadius.circular(12)),
        child:chain.isEmpty?const Center(child:Text('الطاولة فارغة')):ListView(scrollDirection:Axis.horizontal,reverse:true,children:chain.map((t)=>Center(child:tile(t))).toList())),
      Row(children:[Expanded(child:OutlinedButton.icon(onPressed:draw,icon:const Icon(Icons.add),label:const Text('اسحب قطعة'))),const SizedBox(width:8),Expanded(child:FilledButton(onPressed:newRound,child:const Text('إعادة الجولة')))]),
      const Divider(height:24),
      Text('يد اللاعب '+(turnA?'الأول':'الثاني'),style:const TextStyle(fontWeight:FontWeight.bold,fontSize:17)),
      const Text('اضغط قطعة ثم اختر الطرف الذي تريد وضعها فيه.'),
      Wrap(children:List.generate(hand.length,(i)=>InkWell(onTap:()=>showModalBottomSheet<void>(context:c,builder:(s)=>Directionality(textDirection:TextDirection.rtl,child:Wrap(children:[
        ListTile(title:Text('وضع القطعة '+hand[i].toString())),
        ListTile(title:const Text('الطرف الأيسر'),onTap:(){Navigator.pop(s);play(i,true);}),
        ListTile(title:const Text('الطرف الأيمن'),onTap:(){Navigator.pop(s);play(i,false);}),
      ]))),child:tile(hand[i])))),
    ]),
  ));
}

class CheckersGamePage extends StatefulWidget {
  const CheckersGamePage({super.key});
  @override State<CheckersGamePage> createState()=>_CheckersGamePageState();
}
class _CheckersGamePageState extends State<CheckersGamePage>{
  late List<int> board;
  int turn=1,redScore=0,blackScore=0;
  int? selected;
  String message='دور الأحمر';
  @override void initState(){super.initState();reset();}
  void reset(){
    board=List.filled(64,0);
    for(var r=0;r<3;r++){for(var c=0;c<8;c++){if((r+c).isOdd)board[r*8+c]=2;}}
    for(var r=5;r<8;r++){for(var c=0;c<8;c++){if((r+c).isOdd)board[r*8+c]=1;}}
    turn=1;selected=null;message='دور الأحمر';setState((){});
  }
  bool mine(int p)=>p!=0&&((p==1||p==3)==(turn==1));
  bool king(int p)=>p==3||p==4;
  bool enemy(int a,int b)=>a!=0&&b!=0&&((a<=2&&b>=3)||(a>=3&&b<=2));
  void tap(int i){
    final p=board[i];
    if(selected==null){if(mine(p))setState(()=>selected=i);return;}
    if(mine(p)){setState(()=>selected=i);return;}
    final from=selected!,fr=from~/8,fc=from%8,tr=i~/8,tc=i%8,dr=tr-fr,dc=tc-fc,mover=board[from];
    if(p!=0||dc.abs()!=dr.abs()){setState(()=>selected=null);return;}
    final forward=turn==1?-1:1;var valid=false;var captured=-1;
    if(dr.abs()==1&&(king(mover)||dr==forward))valid=true;
    if(dr.abs()==2&&(king(mover)||dr.sign==forward)){
      final mid=((fr+tr)~/2)*8+((fc+tc)~/2);
      if(enemy(mover,board[mid])){valid=true;captured=mid;}
    }
    if(!valid){setState(()=>selected=null);return;}
    setState((){
      board[i]=mover;board[from]=0;if(captured>=0)board[captured]=0;
      if(mover==1&&tr==0)board[i]=3;if(mover==2&&tr==7)board[i]=4;
      selected=null;turn=turn==1?2:1;message='دور '+(turn==1?'الأحمر':'الأسود');
      final red=board.where((x)=>x==1||x==3).length,black=board.where((x)=>x==2||x==4).length;
      if(red==0){blackScore++;message='فاز الأسود!';}else if(black==0){redScore++;message='فاز الأحمر!';}
    });
  }
  @override Widget build(BuildContext c)=>Directionality(textDirection:TextDirection.rtl,child:Scaffold(
    appBar:AppBar(title:const Text('الدامة'),actions:[IconButton(onPressed:reset,icon:const Icon(Icons.refresh))]),
    body:Column(children:[
      Padding(padding:const EdgeInsets.all(12),child:Row(mainAxisAlignment:MainAxisAlignment.spaceAround,children:[
        Text('الأحمر '+redScore.toString(),style:const TextStyle(color:Colors.red)),Text(message,style:const TextStyle(fontWeight:FontWeight.bold)),Text('الأسود '+blackScore.toString()),
      ])),
      Expanded(child:Center(child:AspectRatio(aspectRatio:1,child:GridView.builder(
        physics:const NeverScrollableScrollPhysics(),gridDelegate:const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount:8),itemCount:64,
        itemBuilder:(context,i){
          final r=i~/8,col=i%8,piece=board[i],dark=(r+col).isOdd;
          return InkWell(onTap:()=>tap(i),child:Container(
            decoration:BoxDecoration(color:dark?const Color(0xFF765A45):const Color(0xFFE9D9BE),border:selected==i?Border.all(color:Colors.amber,width:3):null),
            child:piece==0?null:Center(child:Container(margin:const EdgeInsets.all(4),decoration:BoxDecoration(
              shape:BoxShape.circle,color:piece==1||piece==3?Colors.red.shade700:Colors.grey.shade900,border:Border.all(color:Colors.white70,width:2)),
              child:king(piece)?const Icon(Icons.workspace_premium,color:Colors.amber,size:18):null)),
          ));
        },
      )))),
      const Padding(padding:EdgeInsets.all(10),child:Text('الدامة المحلية: حركة قطرية وأكل القطع وترقية الملك. مرّروا الجهاز بين اللاعبين.')),
    ]),
  ));
}
