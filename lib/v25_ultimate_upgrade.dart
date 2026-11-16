import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'game_room_social.dart';

const _v25Purple=Color(0xFF806BFF),_v25Navy=Color(0xFF171936);

class V25UltimateUpgradePage extends StatelessWidget{
 const V25UltimateUpgradePage({super.key});
 @override Widget build(BuildContext context)=>DefaultTabController(length:4,child:Directionality(textDirection:TextDirection.rtl,child:Scaffold(
  appBar:AppBar(title:const Text('عالم المستقبل V25'),bottom:const TabBar(isScrollable:true,tabs:[
   Tab(icon:Icon(Icons.sports_esports),text:'ألعاب ثنائية'),Tab(icon:Icon(Icons.storefront),text:'المتجر'),Tab(icon:Icon(Icons.workspace_premium),text:'العضويات'),Tab(icon:Icon(Icons.speed),text:'الأداء')
  ])),
  body:const TabBarView(children:[V25DuoArcadePage(embedded:true),V25CoinStorePage(),V25MembershipPage(),V25PerformancePage(embedded:true)]),
 )));
}

class V25DuoArcadePage extends StatefulWidget{
 const V25DuoArcadePage({super.key,this.embedded=false});final bool embedded;
 @override State<V25DuoArcadePage> createState()=>_V25DuoArcadePageState();
}
class _V25DuoArcadePageState extends State<V25DuoArcadePage>{
 final db=FirebaseFirestore.instance,code=TextEditingController();bool busy=false;
 String get uid=>FirebaseAuth.instance.currentUser?.uid??'';
 String get name=>FirebaseAuth.instance.currentUser?.displayName??'لاعب';
 @override void dispose(){code.dispose();super.dispose();}
 void msg(String s){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(s)));}
 Future<void> create()async{
  if(uid.isEmpty||busy){msg('سجّل الدخول أولاً.');return;}setState(()=>busy=true);
  try{
   final id=(100000+Random.secure().nextInt(900000)).toString();
   await db.collection('gameRooms').doc(id).set({'game':'xo','gameMode':'neon_xo','hostId':uid,'roomCode':id,'members':[uid],'memberNames':{uid:name},'status':'waiting','board':List<String>.filled(9,''),'turn':uid,'winner':'','createdAt':FieldValue.serverTimestamp(),'updatedAt':FieldValue.serverTimestamp()});
   await Clipboard.setData(ClipboardData(text:id));if(!mounted)return;msg('تم إنشاء الغرفة ونسخ الرمز '+id);
   await Navigator.push(context,MaterialPageRoute(builder:(_)=>V25DuoXoRoomPage(roomId:id)));
  }on FirebaseException catch(e){msg('تعذر إنشاء الغرفة: '+e.code);}finally{if(mounted)setState(()=>busy=false);}
 }
 Future<bool> join([String? raw])async{
  final id=(raw??code.text).trim();if(uid.isEmpty||!RegExp(r'^\d{6}$').hasMatch(id)||busy){msg('سجّل الدخول واكتب رمزاً من 6 أرقام.');return false;}
  setState(()=>busy=true);
  try{
   final ref=db.collection('gameRooms').doc(id);
   await db.runTransaction((tx)async{
    final s=await tx.get(ref);if(!s.exists)throw Exception('الغرفة غير موجودة.');
    final d=s.data()!,members=List<String>.from(d['members']??[]);
    if(members.contains(uid))return;
    if(d['game']!='xo'||d['status']!='waiting'||members.length!=1)throw Exception('الغرفة بدأت أو اكتملت.');
    tx.update(ref,{'members':FieldValue.arrayUnion([uid]),'memberNames.$uid':name,'status':'playing','updatedAt':FieldValue.serverTimestamp()});
   });
   if(!mounted)return true;code.clear();await Navigator.push(context,MaterialPageRoute(builder:(_)=>V25DuoXoRoomPage(roomId:id)));return true;
  }catch(e){msg(e.toString().replaceFirst('Exception: ',''));return false;}finally{if(mounted)setState(()=>busy=false);}
 }
 Widget body()=>ListView(padding:const EdgeInsets.all(14),children:[
  Container(padding:const EdgeInsets.all(18),decoration:BoxDecoration(borderRadius:BorderRadius.circular(20),gradient:const LinearGradient(colors:[_v25Navy,Color(0xFF5B35B5),Color(0xFF087E91)])),child:const Text('ساحة التحدي الثنائي\nغرف أونلاين برمز ودعوات، مع دردشة وفويس داخل اللعبة.',style:TextStyle(color:Colors.white,fontSize:18,fontWeight:FontWeight.bold))),
  Card(child:Padding(padding:const EdgeInsets.all(14),child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
   const Text('⚡ XO نيون — أونلاين',style:TextStyle(fontSize:18,fontWeight:FontWeight.w900)),
   FilledButton.icon(onPressed:busy?null:create,icon:const Icon(Icons.add),label:Text(busy?'جارٍ الإنشاء...':'إنشاء غرفة')),
   TextField(controller:code,keyboardType:TextInputType.number,maxLength:6,textAlign:TextAlign.center,decoration:const InputDecoration(labelText:'رمز غرفة صديقك',counterText:'',border:OutlineInputBorder())),
   OutlinedButton.icon(onPressed:busy?null:()=>join(),icon:const Icon(Icons.login),label:const Text('انضم إلى الغرفة')),
  ]))),
  Card(child:Padding(padding:const EdgeInsets.all(12),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
   const Text('دعوات الألعاب الواردة',style:TextStyle(fontWeight:FontWeight.w900)),
   if(uid.isEmpty)const Text('سجّل الدخول لعرض الدعوات.')else StreamBuilder<QuerySnapshot<Map<String,dynamic>>>(stream:db.collection('gameInvites').where('to',isEqualTo:uid).limit(40).snapshots(),builder:(c,s){
    if(s.hasError)return const Text('تعذر تحميل الدعوات.');if(!s.hasData)return const LinearProgressIndicator();
    final docs=s.data!.docs.where((d)=>d.data()['game']=='xo'&&d.data()['status']=='pending').toList();
    if(docs.isEmpty)return const Text('لا توجد دعوات جديدة.');
    return Column(children:docs.map((d)=>ListTile(title:Text('دعوة من '+(d.data()['fromName']??'صديق').toString()),subtitle:Text('غرفة '+(d.data()['roomCode']??d.data()['roomId']??'').toString()),trailing:FilledButton(onPressed:busy?null:()async{final ok=await join((d.data()['roomId']??'').toString());if(ok){try{await d.reference.update({'status':'accepted'});}catch(_){}}},child:const Text('العب')))).toList());
   }),
  ]))),
  const Text('ألعاب ثنائية إضافية',style:TextStyle(fontSize:18,fontWeight:FontWeight.w900)),
  Card(child:ListTile(leading:const Text('🧠',style:TextStyle(fontSize:24)),title:const Text('ذاكرة الألوان'),subtitle:const Text('طابق الأزواج وتناوبوا على جهاز واحد.'),onTap:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const V25MemoryDuelPage())))),
  Card(child:ListTile(leading:const Text('⚡',style:TextStyle(fontSize:24)),title:const Text('سباق التركيز'),subtitle:const Text('عشر جولات لكل لاعب.'),onTap:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const V25FocusDuelPage())))),
  const Text('مغامرة كنز الأصدقاء 2D موجودة مسبقاً ضمن بطولات الأصدقاء.',style:TextStyle(fontSize:11,color:Colors.grey)),
 ]);
 @override Widget build(BuildContext context)=>widget.embedded?body():Directionality(textDirection:TextDirection.rtl,child:Scaffold(appBar:AppBar(title:const Text('ألعاب الأصدقاء V25')),body:body()));
}

class V25DuoXoRoomPage extends StatefulWidget{const V25DuoXoRoomPage({super.key,required this.roomId});final String roomId;@override State<V25DuoXoRoomPage> createState()=>_V25DuoXoRoomPageState();}
class _V25DuoXoRoomPageState extends State<V25DuoXoRoomPage>{
 final db=FirebaseFirestore.instance;bool busy=false;String get uid=>FirebaseAuth.instance.currentUser?.uid??'';DocumentReference<Map<String,dynamic>> get room=>db.collection('gameRooms').doc(widget.roomId);
 String winner(List<String>b){const lines=[[0,1,2],[3,4,5],[6,7,8],[0,3,6],[1,4,7],[2,5,8],[0,4,8],[2,4,6]];for(final l in lines){final x=b[l[0]];if(x.isNotEmpty&&x==b[l[1]]&&x==b[l[2]])return x;}return '';}
 void msg(String s){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(s)));}
 Future<void> move(int i)async{if(busy)return;setState(()=>busy=true);try{
  await db.runTransaction((tx)async{final s=await tx.get(room);if(!s.exists)throw Exception('الغرفة غير موجودة.');final d=s.data()!,b=List<String>.from(d['board']??List<String>.filled(9,'')),ps=List<String>.from(d['members']??[]);
   if(d['status']!='playing'||d['turn']!=uid||!ps.contains(uid)||b[i].isNotEmpty)throw Exception('انتظر دورك واختَر خانة فارغة.');
   final mark=ps.first==uid?'X':'O';b[i]=mark;final w=winner(b),end=w.isNotEmpty||b.every((x)=>x.isNotEmpty);
   tx.update(room,{'board':b,'winner':w.isNotEmpty?mark:(end?'draw':''),'turn':end?'':ps.firstWhere((x)=>x!=uid),'status':end?'finished':'playing','updatedAt':FieldValue.serverTimestamp()});
  });
 }catch(e){msg(e.toString().replaceFirst('Exception: ',''));}finally{if(mounted)setState(()=>busy=false);}}

 Future<void> inviteFriend()async{
  try{
   final profiles=await db.collection('publicProfiles').limit(100).get();if(!mounted)return;
   final target=await showModalBottomSheet<String>(context:context,builder:(c)=>Directionality(textDirection:TextDirection.rtl,child:ListView(shrinkWrap:true,children:[
    const Padding(padding:EdgeInsets.all(16),child:Text('اختَر صديقاً لدعوته')),
    ...profiles.docs.where((p)=>p.id!=uid).map((p)=>ListTile(title:Text((p.data()['name']??'عضو').toString()),onTap:()=>Navigator.pop(c,p.id))),
   ])));
   if(target==null)return;
   final me=await db.collection('publicProfiles').doc(uid).get();
   await db.collection('gameInvites').add({'from':uid,'to':target,'fromName':me.data()?['name']??'صديق','game':'xo','roomId':widget.roomId,'roomCode':widget.roomId,'status':'pending','createdAt':FieldValue.serverTimestamp()});
   msg('تم إرسال دعوة اللعبة.');
  }on FirebaseException catch(e){msg('تعذر إرسال الدعوة: '+e.code);}
 }
 Future<void> reset(String host)async{if(uid==host&&!busy)await room.update({'board':List<String>.filled(9,''),'winner':'','turn':host,'status':'playing','updatedAt':FieldValue.serverTimestamp()});}
 @override Widget build(BuildContext context)=>Directionality(textDirection:TextDirection.rtl,child:Scaffold(appBar:AppBar(title:Text('XO نيون • '+widget.roomId)),body:StreamBuilder<DocumentSnapshot<Map<String,dynamic>>>(stream:room.snapshots(),builder:(c,s){
  if(s.hasError)return const Center(child:Text('تعذر الاتصال بالغرفة.'));if(!s.hasData)return const Center(child:CircularProgressIndicator());if(!s.data!.exists)return const Center(child:Text('الغرفة غير موجودة.'));
  final d=s.data!.data()!,ps=List<String>.from(d['members']??[]),names=Map<String,dynamic>.from(d['memberNames']??{}),b=List<String>.from(d['board']??List<String>.filled(9,'')),status=(d['status']??'waiting').toString(),w=(d['winner']??'').toString(),host=(d['hostId']??'').toString(),mine=status=='playing'&&d['turn']==uid;
  final result=w=='draw'?'تعادل!':w=='X'?'فاز '+(names[ps.isNotEmpty?ps.first:'']??'الأول').toString():w=='O'?'فاز '+(names[ps.length>1?ps[1]:'']??'الثاني').toString():'';
  return ListView(padding:const EdgeInsets.all(14),children:[
   Card(child:Padding(padding:const EdgeInsets.all(12),child:Row(mainAxisAlignment:MainAxisAlignment.spaceAround,children:[Text('✕ '+(names[ps.isNotEmpty?ps.first:'']??'المضيف').toString(),style:const TextStyle(color:Colors.cyan,fontWeight:FontWeight.bold)),Text('◯ '+(names[ps.length>1?ps[1]:'']??'بانتظار صديق').toString(),style:const TextStyle(color:Colors.pinkAccent,fontWeight:FontWeight.bold))]))),
   Card(child:Padding(padding:const EdgeInsets.all(12),child:Text(status=='waiting'?'شارك الرمز '+widget.roomId+' أو ادعُ صديقاً.':status=='finished'?result:mine?'دورك! اختَر خانة.':'انتظر حركة صديقك…',textAlign:TextAlign.center,style:const TextStyle(fontSize:17,fontWeight:FontWeight.w900)))),
   AspectRatio(aspectRatio:1,child:GridView.builder(physics:const NeverScrollableScrollPhysics(),itemCount:9,gridDelegate:const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount:3,crossAxisSpacing:9,mainAxisSpacing:9),itemBuilder:(c,i){final m=b[i],color=m=='X'?Colors.cyanAccent:Colors.pinkAccent;return InkWell(onTap:status=='playing'&&mine&&m.isEmpty&&!busy?()=>move(i):null,child:Container(decoration:BoxDecoration(color:_n25,borderRadius:BorderRadius.circular(17),border:Border.all(color:m.isEmpty?Colors.white24:color,width:2)),child:Center(child:Text(m=='X'?'✕':m=='O'?'◯':'',style:TextStyle(fontSize:58,color:color,fontWeight:FontWeight.w900)))));})),
   if(status=='waiting'&&uid==host)FilledButton.icon(onPressed:inviteFriend,icon:const Icon(Icons.person_add),label:const Text('دعوة صديق')),
   if(status=='finished'&&uid==host)FilledButton(onPressed:()=>reset(host),child:const Text('جولة جديدة')),
   GameRoomSocialPanel(roomId:widget.roomId),SelectableText('رمز الغرفة: '+widget.roomId,textAlign:TextAlign.center),
   TextButton.icon(onPressed:()=>Clipboard.setData(ClipboardData(text:widget.roomId)),icon:const Icon(Icons.copy),label:const Text('نسخ الرمز')),
  ]);
 })));
}

class V25MemoryDuelPage extends StatefulWidget{const V25MemoryDuelPage({super.key});@override State<V25MemoryDuelPage> createState()=>_V25MemoryDuelPageState();}
class _V25MemoryDuelPageState extends State<V25MemoryDuelPage>{
 static const faces=['🌙','🚀','🐼','🎮','🌟','🦊'];late List<String> cards;final Set<int> open={},matched={};final scores=[0,0];int player=0;bool locked=false;
 @override void initState(){super.initState();reset();}
 void reset(){cards=[...faces,...faces]..shuffle(Random());open.clear();matched.clear();scores[0]=0;scores[1]=0;player=0;locked=false;if(mounted)setState((){});}
 Future<void> flip(int i)async{if(locked||open.contains(i)||matched.contains(i))return;setState(()=>open.add(i));if(open.length<2)return;final pair=open.toList();if(cards[pair[0]]==cards[pair[1]]){setState((){matched.addAll(pair);scores[player]++;open.clear();});if(matched.length==cards.length){await showDialog<void>(context:context,builder:(c)=>AlertDialog(title:Text(scores[0]==scores[1]?'تعادل':scores[0]>scores[1]?'فاز الأول':'فاز الثاني'),content:Text(scores[0].toString()+' - '+scores[1].toString()),actions:[TextButton(onPressed:()=>Navigator.pop(c),child:const Text('حلو'))]));}}else{locked=true;await Future<void>.delayed(const Duration(milliseconds:850));if(!mounted)return;setState((){open.clear();player=1-player;locked=false;});}}
 @override Widget build(BuildContext context)=>Directionality(textDirection:TextDirection.rtl,child:Scaffold(appBar:AppBar(title:const Text('ذاكرة الألوان • لاعبان'),actions:[IconButton(onPressed:reset,icon:const Icon(Icons.refresh))]),body:ListView(padding:const EdgeInsets.all(14),children:[
  Text('الأول: '+scores[0].toString()+' • الثاني: '+scores[1].toString()+' • الدور: '+(player+1).toString(),textAlign:TextAlign.center,style:const TextStyle(fontWeight:FontWeight.bold)),
  GridView.builder(shrinkWrap:true,physics:const NeverScrollableScrollPhysics(),itemCount:cards.length,gridDelegate:const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount:3,crossAxisSpacing:8,mainAxisSpacing:8),itemBuilder:(c,i){final show=open.contains(i)||matched.contains(i);return InkWell(onTap:show?null:()=>flip(i),child:Container(decoration:BoxDecoration(color:show?const Color(0xFF51418F):_n25,borderRadius:BorderRadius.circular(15),border:Border.all(color:show?Colors.amber:Colors.white24)),child:Center(child:Text(show?cards[i]:'✦',style:const TextStyle(fontSize:34,color:Colors.white)))));}),
  OutlinedButton(onPressed:reset,child:const Text('إعادة اللعبة')),const Text('لعب محلي على جهاز واحد؛ مرّروا الجهاز بين الأدوار.',textAlign:TextAlign.center,style:TextStyle(fontSize:11,color:Colors.grey)),
 ])));
}

class V25FocusDuelPage extends StatefulWidget{const V25FocusDuelPage({super.key});@override State<V25FocusDuelPage> createState()=>_V25FocusDuelPageState();}
class _V25FocusDuelPageState extends State<V25FocusDuelPage>{
 final rnd=Random();int player=0,round=1,a=0,b=0,target=0;bool active=true,done=false,finished=false;
 @override void initState(){super.initState();nextTurn();}
 void nextTurn(){target=rnd.nextInt(9);active=true;done=false;setState((){});}
 void tap(int i){if(!active)return;setState((){active=false;done=true;if(i==target){if(player==0)a++;else b++;}});}
 void next(){if(player==0){player=1;}else{player=0;round++;}if(round>10){finished=true;setState((){});return;}nextTurn();}
 void reset(){player=0;round=1;a=0;b=0;finished=false;nextTurn();}
 @override Widget build(BuildContext context)=>Directionality(textDirection:TextDirection.rtl,child:Scaffold(appBar:AppBar(title:const Text('سباق التركيز • لاعبان')),body:ListView(padding:const EdgeInsets.all(14),children:[
  Text(finished?(a==b?'تعادل':a>b?'فاز الأول':'فاز الثاني'):'الجولة '+round.toString()+' من 10 • دور اللاعب '+(player+1).toString(),textAlign:TextAlign.center,style:const TextStyle(fontSize:19,fontWeight:FontWeight.w900)),
  Text('النتيجة '+a.toString()+' - '+b.toString(),textAlign:TextAlign.center),
  if(!finished)Text(done?'انتهى دورك.':'اضغط المربع رقم '+(target+1).toString(),textAlign:TextAlign.center),
  GridView.builder(shrinkWrap:true,physics:const NeverScrollableScrollPhysics(),itemCount:9,gridDelegate:const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount:3,crossAxisSpacing:8,mainAxisSpacing:8),itemBuilder:(c,i)=>InkWell(onTap:active?()=>tap(i):null,child:Container(decoration:BoxDecoration(color:done&&i==target?Colors.green.withValues(alpha:.3):_n25,borderRadius:BorderRadius.circular(14),border:Border.all(color:done&&i==target?Colors.green:Colors.white24)),child:Center(child:Text(done&&i==target?'✓':(i+1).toString(),style:const TextStyle(fontSize:25,color:Colors.white)))))),
  if(done&&!finished)FilledButton(onPressed:next,child:const Text('الدور التالي')),if(finished)FilledButton(onPressed:reset,child:const Text('إعادة التحدي')),
 ])));
}

class V25CoinStorePage extends StatefulWidget{const V25CoinStorePage({super.key});@override State<V25CoinStorePage> createState()=>_V25CoinStorePageState();}
class _V25CoinStorePageState extends State<V25CoinStorePage>{
 static const items=[
  _Item('star','لقب نجم الملتقى','ألقاب','⭐',40),_Item('legend','لقب أسطورة','ألقاب','👑',120),_Item('creator','لقب المبدع','ألقاب','🎨',60),
  _Item('neon','إطار نيون','إطارات','🟣',50),_Item('ocean','إطار المحيط','إطارات','🌊',50),_Item('gold','إطار ذهبي','إطارات','✨',140),
  _Item('cyan','فقاعة سماوية','فقاعات','💬',35),_Item('aurora','فقاعة الشفق','فقاعات','🌌',75),_Item('goldbubble','فقاعة ذهبية','فقاعات','💛',110),
  _Item('night','ثيم منتصف الليل','ثيمات','🌙',80),_Item('sakura','ثيم ساكورا','ثيمات','🌸',80),_Item('galaxy','ثيم المجرة','ثيمات','🌠',130),
 ];
 final uid=FirebaseAuth.instance.currentUser?.uid??'';final founder=FirebaseAuth.instance.currentUser?.email?.toLowerCase()=='husinalzerjaoe@gmail.com';
 String category='الكل';Set<String> owned={},equipped={};bool loaded=false;
 @override void initState(){super.initState();load();}
 Future<void> load()async{final p=await SharedPreferences.getInstance();if(mounted)setState((){owned=(p.getStringList('v25_owned')??[]).toSet();equipped=(p.getStringList('v25_equipped')??[]).toSet();loaded=true;});}
 Future<void> save()async{final p=await SharedPreferences.getInstance();await p.setStringList('v25_owned',owned.toList());await p.setStringList('v25_equipped',equipped.toList());}
 void msg(String s){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(s)));}
 Future<void> buy(_Item x,int balance)async{
  if(owned.contains(x.id)){setState(()=>equipped.contains(x.id)?equipped.remove(x.id):equipped.add(x.id));await save();return;}
  if(!founder&&balance<x.price){msg('رصيدك غير كافٍ. قدّم طلب إضافة عملات للمراجعة.');return;}
  if(!founder){try{final r=FirebaseFirestore.instance.collection('coinWallets').doc(uid);await FirebaseFirestore.instance.runTransaction((tx)async{final s=await tx.get(r);final n=(s.data()?['coins'] as num?)?.toInt()??0;if(n<x.price)throw Exception('الرصيد غير كافٍ.');tx.update(r,{'coins':n-x.price,'updatedAt':FieldValue.serverTimestamp()});});}catch(e){msg(e.toString().replaceFirst('Exception: ','تعذر الشراء: '));return;}}
  setState((){owned.add(x.id);equipped.add(x.id);});await save();msg('تم اقتناء '+x.name+' وتفعيله محلياً.');
 }
 Future<void> topup()async{
  final amount=await showModalBottomSheet<int>(context:context,builder:(c)=>Directionality(textDirection:TextDirection.rtl,child:Column(mainAxisSize:MainAxisSize.min,children:[const Padding(padding:EdgeInsets.all(16),child:Text('طلب إضافة عملات — لا يوجد دفع داخل التطبيق')),for(final n in [100,250,500,1000])ListTile(title:Text(n.toString()+' عملة'),onTap:()=>Navigator.pop(c,n))])));
  if(amount==null)return;try{await FirebaseFirestore.instance.collection('coinTopupRequests').add({'uid':uid,'amount':amount,'status':'pending','createdAt':FieldValue.serverTimestamp()});msg('تم إرسال طلب المراجعة؛ لا يتم سحب أموال.');}on FirebaseException catch(e){msg('تعذر إرسال الطلب: '+e.code+'. انشر قواعد V25 أولاً.');}
 }
 Future<void> grant()async{
  if(!founder)return;final u=TextEditingController(),a=TextEditingController(text:'100');
  final ok=await showDialog<bool>(context:context,builder:(c)=>Directionality(textDirection:TextDirection.rtl,child:AlertDialog(title:const Text('منح عملات لعضو'),content:Column(mainAxisSize:MainAxisSize.min,children:[TextField(controller:u,decoration:const InputDecoration(labelText:'UID العضو')),TextField(controller:a,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'عدد العملات'))]),actions:[TextButton(onPressed:()=>Navigator.pop(c,false),child:const Text('إلغاء')),FilledButton(onPressed:()=>Navigator.pop(c,true),child:const Text('منح'))])));
  final target=u.text.trim(),amount=int.tryParse(a.text.trim())??0;u.dispose();a.dispose();if(ok!=true||target.isEmpty||amount<1||amount>1000000)return;
  try{final r=FirebaseFirestore.instance.collection('coinWallets').doc(target);await FirebaseFirestore.instance.runTransaction((tx)async{final s=await tx.get(r);final old=(s.data()?['coins'] as num?)?.toInt()??0;tx.set(r,{'coins':old+amount,'grantedBy':uid,'updatedAt':FieldValue.serverTimestamp()},SetOptions(merge:true));});msg('تم منح '+amount.toString()+' عملة.');}on FirebaseException catch(e){msg('تعذر المنح: '+e.code+'. انشر قواعد V25 أولاً.');}
 }
 @override Widget build(BuildContext context){
  if(uid.isEmpty)return const Center(child:Text('سجّل الدخول لاستخدام المتجر.'));
  return StreamBuilder<DocumentSnapshot<Map<String,dynamic>>>(stream:FirebaseFirestore.instance.collection('coinWallets').doc(uid).snapshots(),builder:(c,s){
   final balance=(s.data?.data()?['coins'] as num?)?.toInt()??0,visible=items.where((x)=>category=='الكل'||x.category==category).toList();
   return ListView(padding:const EdgeInsets.all(14),children:[
    Container(padding:const EdgeInsets.all(17),decoration:BoxDecoration(borderRadius:BorderRadius.circular(18),gradient:const LinearGradient(colors:[_n25,Color(0xFF5B35B5)])),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const Text('محفظة الملتقى',style:TextStyle(color:Colors.white70)),Text(founder?'∞ عملات المؤسس':balance.toString()+' عملة',style:const TextStyle(color:Colors.white,fontSize:27,fontWeight:FontWeight.w900)),const Text('العملات منفصلة عن نقاط النشاط.',style:TextStyle(color:Colors.white70))])),
    Wrap(spacing:8,children:[OutlinedButton.icon(onPressed:topup,icon:const Icon(Icons.add_card),label:const Text('طلب شحن للمراجعة')),if(founder)FilledButton.icon(onPressed:grant,icon:const Icon(Icons.card_giftcard),label:const Text('منح عملات'))]),
    const Text('الطلب لا يسحب أموالاً. الموافقة يدوية من المؤسس؛ لا توجد بوابة دفع مفعّلة.',style:TextStyle(fontSize:11,color:Colors.grey)),
    const Text('الألقاب والإطارات وفقاعات الدردشة والثيمات',style:TextStyle(fontSize:18,fontWeight:FontWeight.w900)),
    SingleChildScrollView(scrollDirection:Axis.horizontal,child:Row(children:['الكل','ألقاب','إطارات','فقاعات','ثيمات'].map((v)=>Padding(padding:const EdgeInsetsDirectional.only(end:6),child:ChoiceChip(label:Text(v),selected:category==v,onSelected:(_)=>setState(()=>category=v)))).toList())),
    if(!loaded)const LinearProgressIndicator(),
    ...visible.map((x)=>Card(child:ListTile(leading:CircleAvatar(child:Text(x.emoji,style:const TextStyle(fontSize:22))),title:Text(x.name),subtitle:Text(x.category+' • '+x.price.toString()+' عملة'),trailing:owned.contains(x.id)?OutlinedButton(onPressed:()=>buy(x,balance),child:Text(equipped.contains(x.id)?'إلغاء':'تفعيل')):FilledButton(onPressed:loaded?()=>buy(x,balance):null,child:Text(founder?'اقتناء ∞':'شراء'))))),
    const Text('المظهر المقتنى يحفظ محلياً بهذا الإصدار؛ مزامنته مع ملفات الأعضاء والدردشة تحتاج ربطاً إضافياً.',style:TextStyle(fontSize:11,color:Colors.grey)),
    if(founder)const _TopupReview(),
   ]);
  });
 }
}
class _TopupReview extends StatelessWidget{
 const _TopupReview();
 Future<void> review(QueryDocumentSnapshot<Map<String,dynamic>> doc,bool approve,BuildContext c)async{
  final d=doc.data(),target=(d['uid']??'').toString(),amount=(d['amount'] as num?)?.toInt()??0;
  try{await FirebaseFirestore.instance.runTransaction((tx)async{final req=await tx.get(doc.reference);if(!req.exists||req.data()?['status']!='pending')throw Exception('تمت مراجعة الطلب.');if(approve){final r=FirebaseFirestore.instance.collection('coinWallets').doc(target);final w=await tx.get(r);final old=(w.data()?['coins'] as num?)?.toInt()??0;tx.set(r,{'coins':old+amount,'grantedBy':FirebaseAuth.instance.currentUser?.uid,'updatedAt':FieldValue.serverTimestamp()},SetOptions(merge:true));}tx.update(doc.reference,{'status':approve?'approved':'rejected','reviewedAt':FieldValue.serverTimestamp()});});if(c.mounted)ScaffoldMessenger.of(c).showSnackBar(SnackBar(content:Text(approve?'تمت الموافقة وإضافة العملات.':'تم رفض الطلب.')));}
  catch(e){if(c.mounted)ScaffoldMessenger.of(c).showSnackBar(SnackBar(content:Text('تعذرت المراجعة: '+e.toString())));}
 }
 @override Widget build(BuildContext context)=>Card(child:Padding(padding:const EdgeInsets.all(12),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
  const Text('طلبات الشحن المعلّقة — المؤسس',style:TextStyle(fontWeight:FontWeight.w900)),
  StreamBuilder<QuerySnapshot<Map<String,dynamic>>>(stream:FirebaseFirestore.instance.collection('coinTopupRequests').where('status',isEqualTo:'pending').limit(30).snapshots(),builder:(c,s){
   if(s.hasError)return const Text('تعذر تحميل الطلبات.');if(!s.hasData)return const LinearProgressIndicator();if(s.data!.docs.isEmpty)return const Text('لا توجد طلبات.');
   return Column(children:s.data!.docs.map((d)=>ListTile(title:Text((d.data()['amount']??0).toString()+' عملة'),subtitle:Text('UID: '+(d.data()['uid']??'').toString()),trailing:Wrap(children:[IconButton(onPressed:()=>review(d,true,context),icon:const Icon(Icons.check_circle,color:Colors.green)),IconButton(onPressed:()=>review(d,false,context),icon:const Icon(Icons.cancel,color:Colors.red))]))).toList());
  }),
 ])));
}

class V25MembershipPage extends StatelessWidget{
 const V25MembershipPage({super.key});
 @override Widget build(BuildContext context)=>ListView(padding:const EdgeInsets.all(14),children:[
  const Text('مزايا العضويات',style:TextStyle(fontSize:21,fontWeight:FontWeight.w900)),
  const Text('العضوية تضيف امتيازات، لكنها لا تمنح صلاحيات إشراف تلقائياً.'),
  _tier('عادي','الملف الشخصي والدردشة والمنشورات والألعاب والفعاليات.',Icons.person,Colors.blueGrey),
  _tier('فضي','شارة فضية وإطار خاص ومفضلة موسعة وتحديات الأعضاء.',Icons.workspace_premium,Colors.blueGrey),
  _tier('ذهبي','شارة ذهبية وثيمات إضافية وأولوية فعاليات وأدوات ملف موسعة.',Icons.military_tech,Colors.amber),
  _tier('ماسي','شارة ماسية وإطارات وفقاعات حصرية وتخصيصات متقدمة.',Icons.diamond,Colors.cyan),
  const Card(child:Padding(padding:EdgeInsets.all(14),child:Text('هيكل الإشراف المقترح: مؤسس، مدير، مشرف عام، مشرف غرفة، مساعد إشراف. يلزم ربط الصلاحيات وسجل الإجراءات بقواعد Firestore؛ هذه الصفحة تعريفية ولا تغيّر رتب الأعضاء.'))),
 ]);
 Widget _tier(String n,String d,IconData i,Color c)=>Card(child:ListTile(leading:CircleAvatar(backgroundColor:c.withValues(alpha:.15),child:Icon(i,color:c)),title:Text('عضوية '+n,style:const TextStyle(fontWeight:FontWeight.w900)),subtitle:Text(d)));
}

class V25PerformancePage extends StatefulWidget{const V25PerformancePage({super.key,this.embedded=false});final bool embedded;@override State<V25PerformancePage> createState()=>_V25PerformancePageState();}
class _V25PerformancePageState extends State<V25PerformancePage>{
 String profile='balanced',media='auto';bool effects=true,motion=true,preload=false,loaded=false;
 @override void initState(){super.initState();load();}
 Future<void> load()async{final p=await SharedPreferences.getInstance();if(!mounted)return;setState((){profile=p.getString('v25_profile')??'balanced';media=p.getString('v25_media')??'auto';effects=p.getBool('v25_effects')??true;motion=p.getBool('v25_motion')??true;preload=p.getBool('v25_preload')??false;loaded=true;});apply();}
 void apply(){final c=PaintingBinding.instance.imageCache;c.maximumSize=profile=='high'?700:profile=='battery'?120:320;c.maximumSizeBytes=profile=='high'?128*1024*1024:profile=='battery'?24*1024*1024:64*1024*1024;}
 Future<void> save()async{final p=await SharedPreferences.getInstance();await p.setString('v25_profile',profile);await p.setString('v25_media',media);await p.setBool('v25_effects',effects);await p.setBool('v25_motion',motion);await p.setBool('v25_preload',preload);apply();if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('تم حفظ ملف الأداء وتطبيق حجم الذاكرة المؤقتة.')));}
 Widget body()=>!loaded?const Center(child:CircularProgressIndicator()):ListView(padding:const EdgeInsets.all(14),children:[
  const Text('ملفات أداء حسب قوة الجهاز',style:TextStyle(fontSize:21,fontWeight:FontWeight.w900)),
  const Text('الأداء العالي يزيد استخدام الذاكرة ولا يرفع تردد الشاشة؛ الهاتف يحدد الحد الفعلي.'),
  RadioListTile<String>(value:'high',groupValue:profile,onChanged:(v)=>setState(()=>profile=v??'high'),title:const Text('أداء فائق — للأجهزة القوية')),
  RadioListTile<String>(value:'balanced',groupValue:profile,onChanged:(v)=>setState(()=>profile=v??'balanced'),title:const Text('متوازن — موصى به')),
  RadioListTile<String>(value:'battery',groupValue:profile,onChanged:(v)=>setState(()=>profile=v??'battery'),title:const Text('توفير — للأجهزة الأضعف')),
  DropdownButtonFormField<String>(value:media,decoration:const InputDecoration(labelText:'جودة الوسائط المفضلة'),items:const[DropdownMenuItem(value:'auto',child:Text('تلقائية')),DropdownMenuItem(value:'high',child:Text('عالية عند توفرها')),DropdownMenuItem(value:'data',child:Text('توفير البيانات'))],onChanged:(v)=>setState(()=>media=v??'auto')),
  SwitchListTile(value:effects,onChanged:(v)=>setState(()=>effects=v),title:const Text('المؤثرات البصرية')),
  SwitchListTile(value:motion,onChanged:(v)=>setState(()=>motion=v),title:const Text('الحركات والانتقالات')),
  SwitchListTile(value:preload,onChanged:(v)=>setState(()=>preload=v),title:const Text('تحميل مسبق عند توفر الاتصال')),
  FilledButton.icon(onPressed:save,icon:const Icon(Icons.save),label:const Text('حفظ وتطبيق')),
  const Text('بعض تفضيلات الوسائط والحركات تحتاج ربطاً في الأقسام نفسها. معدل الإطارات يحدده الهاتف والنظام.',style:TextStyle(fontSize:11,color:Colors.grey)),
 ]);
 @override Widget build(BuildContext context)=>embedded?body():Directionality(textDirection:TextDirection.rtl,child:Scaffold(appBar:AppBar(title:const Text('أداء الأجهزة V25')),body:body()));
}
class _Item{const _Item(this.id,this.name,this.category,this.emoji,this.price);final String id,name,category,emoji;final int price;}
