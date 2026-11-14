import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';

class _Fact { final String q,a,e; final List<String> w; const _Fact(this.q,this.a,this.w,this.e); }
const _facts = <_Fact>[
_Fact('بطل كأس العالم 1930؟','أوروغواي',['الأرجنتين','إيطاليا','البرازيل'],'أوروغواي فازت بأول نسخة.'),
_Fact('بطل كأس العالم 1934؟','إيطاليا',['تشيكوسلوفاكيا','ألمانيا','المجر'],'إيطاليا فازت على تشيكوسلوفاكيا.'),
_Fact('بطل كأس العالم 1938؟','إيطاليا',['البرازيل','المجر','فرنسا'],'إيطاليا احتفظت باللقب.'),
_Fact('بطل كأس العالم 1950؟','أوروغواي',['البرازيل','السويد','إسبانيا'],'أوروغواي حسمت مجموعة النهائي.'),
_Fact('بطل كأس العالم 1954؟','ألمانيا الغربية',['المجر','النمسا','البرازيل'],'فازت في معجزة برن.'),
_Fact('بطل كأس العالم 1958؟','البرازيل',['السويد','فرنسا','ألمانيا الغربية'],'أول لقب للبرازيل.'),
_Fact('بطل كأس العالم 1962؟','البرازيل',['تشيكوسلوفاكيا','تشيلي','إنجلترا'],'البرازيل احتفظت باللقب.'),
_Fact('بطل كأس العالم 1966؟','إنجلترا',['ألمانيا الغربية','البرتغال','الاتحاد السوفيتي'],'فازت على ألمانيا الغربية.'),
_Fact('بطل كأس العالم 1970؟','البرازيل',['إيطاليا','ألمانيا الغربية','الأوروغواي'],'فازت على إيطاليا 4-1.'),
_Fact('بطل كأس العالم 1974؟','ألمانيا الغربية',['هولندا','بولندا','البرازيل'],'فازت على هولندا.'),
_Fact('بطل كأس العالم 1978؟','الأرجنتين',['هولندا','البرازيل','إيطاليا'],'أول لقب للأرجنتين.'),
_Fact('بطل كأس العالم 1982؟','إيطاليا',['ألمانيا الغربية','البرازيل','فرنسا'],'فازت على ألمانيا الغربية.'),
_Fact('بطل كأس العالم 1986؟','الأرجنتين',['ألمانيا الغربية','فرنسا','بلجيكا'],'قاد مارادونا المنتخب للقب.'),
_Fact('بطل كأس العالم 1990؟','ألمانيا الغربية',['الأرجنتين','إيطاليا','إنجلترا'],'فازت بهدف في النهائي.'),
_Fact('بطل كأس العالم 1994؟','البرازيل',['إيطاليا','السويد','بلغاريا'],'حسمت النهائي بركلات الترجيح.'),
_Fact('بطل كأس العالم 1998؟','فرنسا',['البرازيل','كرواتيا','هولندا'],'فازت 3-0 في النهائي.'),
_Fact('بطل كأس العالم 2002؟','البرازيل',['ألمانيا','تركيا','كوريا الجنوبية'],'رونالدو سجل هدفي النهائي.'),
_Fact('بطل كأس العالم 2006؟','إيطاليا',['فرنسا','ألمانيا','البرتغال'],'فازت بركلات الترجيح.'),
_Fact('بطل كأس العالم 2010؟','إسبانيا',['هولندا','ألمانيا','الأوروغواي'],'إنييستا سجل هدف النهائي.'),
_Fact('بطل كأس العالم 2014؟','ألمانيا',['الأرجنتين','البرازيل','هولندا'],'غوتزه سجل هدف النهائي.'),
_Fact('بطل كأس العالم 2018؟','فرنسا',['كرواتيا','بلجيكا','إنجلترا'],'فازت على كرواتيا 4-2.'),
_Fact('بطل كأس العالم 2022؟','الأرجنتين',['فرنسا','كرواتيا','المغرب'],'فازت بركلات الترجيح.'),
_Fact('من أول منتخب أفريقي بلغ ربع نهائي كأس العالم؟','الكاميرون',['السنغال','غانا','المغرب'],'الكاميرون حققت ذلك في 1990.'),
_Fact('من أول منتخب آسيوي بلغ نصف نهائي كأس العالم؟','كوريا الجنوبية',['اليابان','السعودية','أستراليا'],'بلغت نصف نهائي 2002.'),
_Fact('مستضيف كأس العالم 1994؟','الولايات المتحدة',['المكسيك','إيطاليا','فرنسا'],'أقيمت نسخة 1994 في أمريكا.'),
_Fact('الدولتان المستضيفتان لكأس العالم 2002؟','اليابان وكوريا الجنوبية',['الصين واليابان','كوريا والصين','اليابان وأستراليا'],'أول نسخة مشتركة الاستضافة.'),
_Fact('أول دولة أفريقية استضافت كأس العالم؟','جنوب أفريقيا',['مصر','المغرب','نيجيريا'],'استضافت نسخة 2010.'),
_Fact('مستضيف كأس العالم 2018؟','روسيا',['قطر','البرازيل','ألمانيا'],'روسيا استضافت نسخة 2018.'),
_Fact('مستضيف كأس العالم 2022؟','قطر',['الإمارات','السعودية','البحرين'],'قطر استضافت نسخة 2022.'),
_Fact('أول بطل لكأس أوروبا للأندية البطلة 1956؟','ريال مدريد',['ميلان','بنفيكا','برشلونة'],'ريال مدريد فاز بالنسخة الأولى.'),
_Fact('النادي الذي حقق أول خمسة ألقاب أوروبية متتالية؟','ريال مدريد',['ليفربول','بايرن ميونخ','أياكس'],'فاز من 1956 حتى 1960.'),
_Fact('بطل نهائي دوري الأبطال 1999؟','مانشستر يونايتد',['بايرن ميونخ','يوفنتوس','برشلونة'],'سجل هدفين في الوقت بدل الضائع.'),
_Fact('بطل نهائي إسطنبول 2005؟','ليفربول',['ميلان','تشيلسي','أرسنال'],'عاد من تأخر 0-3 أمام ميلان.'),
_Fact('بطل دوري الأبطال 2012؟','تشيلسي',['بايرن ميونخ','ريال مدريد','برشلونة'],'فاز على بايرن بركلات الترجيح.'),
_Fact('النادي الذي حقق ثلاثية دوري الأبطال 2016-2018؟','ريال مدريد',['برشلونة','بايرن ميونخ','ليفربول'],'ثلاثة ألقاب متتالية.'),
_Fact('بطل دوري الأبطال 2020؟','بايرن ميونخ',['باريس','مانشستر سيتي','ليفربول'],'فاز بهدف كومان.'),
_Fact('بطل دوري الأبطال 2023؟','مانشستر سيتي',['إنتر','ريال مدريد','ميلان'],'رودري سجل هدف النهائي.'),
_Fact('بطل دوري الأبطال 2024؟','ريال مدريد',['دورتموند','بايرن','باريس'],'فاز على دورتموند.'),
_Fact('من الملقب بالظاهرة؟','رونالدو نازاريو',['رونالدينيو','كاكا','ريفالدو'],'اللقب يعود للمهاجم البرازيلي.'),
_Fact('مسجل هدف إسبانيا في نهائي 2010؟','أندريس إنييستا',['دافيد فيا','تشافي','توريس'],'سجل في الوقت الإضافي.'),
_Fact('مسجل هدف ألمانيا في نهائي 2014؟','ماريو غوتزه',['توماس مولر','كلوزه','أوزيل'],'سجل في الوقت الإضافي.'),
_Fact('كم مرة فاز بيليه بكأس العالم كلاعب؟','ثلاث مرات',['مرتين','أربع مرات','مرة واحدة'],'أعوام 1958 و1962 و1970.'),
_Fact('بطل كأس العالم للسيدات 2023؟','إسبانيا',['إنجلترا','أمريكا','السويد'],'فازت على إنجلترا في النهائي.'),
_Fact('بطل يورو 2016؟','البرتغال',['فرنسا','ألمانيا','إسبانيا'],'فازت بهدف إيدر.'),
_Fact('بطل يورو 2020 المؤجلة إلى 2021؟','إيطاليا',['إنجلترا','إسبانيا','الدنمارك'],'فازت بركلات الترجيح.'),
_Fact('بطل يورو 2024؟','إسبانيا',['إنجلترا','فرنسا','ألمانيا'],'فازت على إنجلترا 2-1.'),
_Fact('بطل كوبا أمريكا 2024؟','الأرجنتين',['كولومبيا','أوروغواي','البرازيل'],'فازت على كولومبيا.'),
_Fact('بطل كأس آسيا 2019؟','قطر',['اليابان','السعودية','أستراليا'],'فازت على اليابان.'),
_Fact('بطل كأس آسيا 2023؟','قطر',['الأردن','اليابان','كوريا الجنوبية'],'فازت على الأردن في النهائي.'),
_Fact('من فاز بكأس العالم 5 مرات حتى نهاية نسخة 2022؟','البرازيل',['ألمانيا','إيطاليا','الأرجنتين'],'البرازيل تملك خمسة ألقاب.'),
];

class FootballQuizPage extends StatefulWidget {
 const FootballQuizPage({super.key});
 @override State<FootballQuizPage> createState()=>_FootballQuizPageState();
}
class _FootballQuizPageState extends State<FootballQuizPage>{
 final _rng=Random();
 late final List<_Q> _bank;
 int _at=0,_points=0,_answered=0;
 int? _selected;
 static const _prefixes=['','تحدي الخبراء: ','سؤال صعب: ','اختبر ذاكرتك: ','جولة المحترفين: ','معلومة كروية: ','بدون تردد: ','سؤال البطولة: ','هل تعرف؟ '];
 @override void initState(){super.initState();_bank=_makeBank();}
 List<_Q> _makeBank(){
  final out=<_Q>[];
  for(final f in _facts){
   for(var i=0;i<_prefixes.length;i++){
    final opts=<String>[f.a,...f.w]..shuffle(Random(f.a.hashCode+i*97));
    out.add(_Q(_prefixes[i]+f.q,opts,opts.indexOf(f.a),f.e));
   }
  }
  return out..shuffle(_rng);
 }
 void _answer(int i){if(_selected!=null)return;setState(()=>_selected=i);if(i==_bank[_at].correct){_points+=10;}_answered++;}
 void _next(){setState((){_selected=null;if(_at+1<_bank.length){_at++;}else{_at=0;}});}
 @override Widget build(BuildContext context)=>Directionality(textDirection:TextDirection.rtl,child:Scaffold(
  appBar:AppBar(title:const Text('تحدي معلومات كرة القدم')),
  body:ListView(padding:const EdgeInsets.all(16),children:[
   Container(padding:const EdgeInsets.all(18),decoration:BoxDecoration(borderRadius:BorderRadius.circular(20),gradient:const LinearGradient(colors:[Color(0xFF075E54),Color(0xFF159A79)])),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
    const Text('بطولة الخبراء ⚽',style:TextStyle(color:Colors.white,fontSize:22,fontWeight:FontWeight.bold)),
    const SizedBox(height:8),Text('بنك التحديات: ${_bank.length} صيغة سؤال',style:const TextStyle(color:Colors.white)),
    const SizedBox(height:8),Text('نقاطك: $_points • أجبت: $_answered',style:const TextStyle(color:Colors.white,fontWeight:FontWeight.bold)),
   ])),
   const SizedBox(height:16),Text('السؤال ${_at+1} من ${_bank.length}',style:const TextStyle(color:Colors.grey)),
   Card(child:Padding(padding:const EdgeInsets.all(16),child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
    Text(_bank[_at].text,style:const TextStyle(fontSize:18,fontWeight:FontWeight.bold)),
    const SizedBox(height:14),
    ...List.generate(4,(i)=>Padding(padding:const EdgeInsets.only(bottom:7),child:OutlinedButton(
     style:OutlinedButton.styleFrom(backgroundColor:_selected==i?(_bank[_at].correct==i?Colors.green.withOpacity(.15):Colors.red.withOpacity(.12)):null,padding:const EdgeInsets.all(13)),
     onPressed:_selected==null?()=>_answer(i):null,child:Text(_bank[_at].options[i]),
    ))),
    if(_selected!=null)Padding(padding:const EdgeInsets.symmetric(vertical:8),child:Text((_selected==_bank[_at].correct?'إجابة صحيحة +10 🏆\n':'إجابة غير صحيحة.\n')+_bank[_at].explanation,style:const TextStyle(fontWeight:FontWeight.w600))),
    FilledButton(onPressed:_selected==null?null:_next,child:const Text('السؤال التالي')),
   ]))),
    const SizedBox(height:12),
    FilledButton.icon(
      onPressed:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const FootballQuizOnlinePage())),
      icon:const Icon(Icons.groups_rounded),
      label:const Text('تحدي كرة القدم أونلاين — 2 إلى 4 لاعبين'),
    ),
   const Text('الأسئلة مبنية على حقائق بطولات ونتائج تاريخية، مع صيغ تحدٍّ متعددة لكل معلومة.',style:TextStyle(color:Colors.grey,fontSize:12)),
  ]),
 ));
}
class _Q{final String text,explanation;final List<String> options;final int correct;const _Q(this.text,this.options,this.correct,this.explanation);}

class FootballQuizOnlinePage extends StatefulWidget {
 const FootballQuizOnlinePage({super.key});
 @override State<FootballQuizOnlinePage> createState()=>_FootballQuizOnlinePageState();
}
class _FootballQuizOnlinePageState extends State<FootballQuizOnlinePage>{
 final _db=FirebaseFirestore.instance;
 final _code=TextEditingController();
 bool _busy=false;
 String get _uid=>FirebaseAuth.instance.currentUser!.uid;
 String get _name=>FirebaseAuth.instance.currentUser?.displayName??'لاعب';
 void _msg(String s)=>ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(s)));
 @override void dispose(){_code.dispose();super.dispose();}
 Future<void> _create()async{
  if(_busy)return;setState(()=>_busy=true);
  try{
   final ref=_db.collection('gameRooms').doc();
   await ref.set({'game':'football_quiz','hostId':_uid,'members':[_uid],'memberNames':{_uid:_name},'status':'waiting','round':0,'answers':{},'scores':{_uid:0},'createdAt':FieldValue.serverTimestamp(),'updatedAt':FieldValue.serverTimestamp()});
   if(!mounted)return;Navigator.push(context,MaterialPageRoute(builder:(_)=>_FootballQuizMatchPage(roomId:ref.id)));
  }catch(e){_msg('تعذر إنشاء الغرفة: '+e.toString());}finally{if(mounted)setState(()=>_busy=false);}
 }
 Future<void> _join()async{
  final id=_code.text.trim();if(id.isEmpty||_busy)return;setState(()=>_busy=true);
  try{
   final ref=_db.collection('gameRooms').doc(id);
   await _db.runTransaction((tx)async{
    final snap=await tx.get(ref);if(!snap.exists)throw Exception('الغرفة غير موجودة');
    final d=snap.data()!;final members=List<String>.from(d['members']??[]);
    if(d['game']!='football_quiz'||d['status']!='waiting'||members.length>=4)throw Exception('الغرفة مكتملة أو بدأت');
    if(!members.contains(_uid)){tx.update(ref,{'members':FieldValue.arrayUnion([_uid]),'memberNames.'+_uid:_name,'scores.'+_uid:0,'updatedAt':FieldValue.serverTimestamp()});}
   });
   if(!mounted)return;Navigator.push(context,MaterialPageRoute(builder:(_)=>_FootballQuizMatchPage(roomId:id)));
  }catch(e){_msg('تعذر الانضمام: '+e.toString().replaceFirst('Exception: ',''));}finally{if(mounted)setState(()=>_busy=false);}
 }
 @override Widget build(BuildContext context)=>Directionality(textDirection:TextDirection.rtl,child:Scaffold(
  appBar:AppBar(title:const Text('تحدي كرة القدم الجماعي')),
  body:ListView(padding:const EdgeInsets.all(16),children:[
   const Text('كوّن فريقاً من 2 إلى 4 لاعبين. كل لاعب يجاوب من جهازه، والنقاط تتحدث مباشرة.',style:TextStyle(fontSize:16)),
   const SizedBox(height:14),
   FilledButton.icon(onPressed:_busy?null:_create,icon:const Icon(Icons.add),label:const Text('إنشاء غرفة تحدي')),
   const SizedBox(height:12),
   TextField(controller:_code,decoration:const InputDecoration(labelText:'رمز غرفة صديقك',border:OutlineInputBorder())),
   const SizedBox(height:8),
   OutlinedButton.icon(onPressed:_busy?null:_join,icon:const Icon(Icons.login),label:const Text('انضم للغرفة')),
  ]),
 ));
}

class _FootballQuizMatchPage extends StatefulWidget{
 final String roomId;const _FootballQuizMatchPage({required this.roomId});
 @override State<_FootballQuizMatchPage> createState()=>_FootballQuizMatchPageState();
}
class _FootballQuizMatchPageState extends State<_FootballQuizMatchPage>{
 final _db=FirebaseFirestore.instance;bool _busy=false;
 String get _uid=>FirebaseAuth.instance.currentUser!.uid;
 DocumentReference<Map<String,dynamic>> get _ref=>_db.collection('gameRooms').doc(widget.roomId);
 Future<void> _start(Map<String,dynamic>d)async{
  if(d['hostId']!=_uid|| (d['members'] as List).length<2)return;
  await _ref.update({'status':'playing','updatedAt':FieldValue.serverTimestamp()});
 }
 Future<void> _answer(int choice,Map<String,dynamic>d,_Fact fact,List<String> options)async{
  if(_busy||d['status']!='playing')return;
  final answers=Map<String,dynamic>.from(d['answers']??{});
  if(answers.containsKey(_uid))return;
  setState(()=>_busy=true);
  try{
   await _db.runTransaction((tx)async{
    final snap=await tx.get(_ref);final x=snap.data()!;
    final a=Map<String,dynamic>.from(x['answers']??{});
    if(a.containsKey(_uid)||x['status']!='playing')return;
    final scores=Map<String,dynamic>.from(x['scores']??{});
    final old=(scores[_uid] as num?)?.toInt()??0;
    tx.update(_ref,{'answers.'+_uid:choice,'scores.'+_uid:old+(options[choice]==fact.a?10:0),'updatedAt':FieldValue.serverTimestamp()});
   });
  }catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('تعذر إرسال الإجابة: '+e.toString())));}
  finally{if(mounted)setState(()=>_busy=false);}
 }
 Future<void> _next(Map<String,dynamic>d)async{
  if(_busy||d['hostId']!=_uid)return;
  final members=List<String>.from(d['members']??[]);final answers=Map<String,dynamic>.from(d['answers']??{});
  if(answers.length<members.length)return;
  setState(()=>_busy=true);
  try{final round=(d['round'] as num? ??0).toInt()+1;await _ref.update({'round':round,'answers':{},'status':round>=20?'finished':'playing','updatedAt':FieldValue.serverTimestamp()});}
  finally{if(mounted)setState(()=>_busy=false);}
 }
 @override Widget build(BuildContext context)=>Directionality(textDirection:TextDirection.rtl,child:Scaffold(
  appBar:AppBar(title:const Text('مواجهة معلومات كرة القدم')),
  body:StreamBuilder<DocumentSnapshot<Map<String,dynamic>>>(stream:_ref.snapshots(),builder:(context,s){
   if(s.hasError)return const Center(child:Text('تعذر الاتصال بالغرفة؛ راجع قواعد Firestore.'));
   if(!s.hasData)return const Center(child:CircularProgressIndicator());
   if(!s.data!.exists)return const Center(child:Text('الغرفة غير موجودة.'));
   final d=s.data!.data()!;final members=List<String>.from(d['members']??[]);final names=Map<String,dynamic>.from(d['memberNames']??{});final scores=Map<String,dynamic>.from(d['scores']??{});final answers=Map<String,dynamic>.from(d['answers']??{});
   final round=(d['round'] as num? ??0).toInt();final fact=_facts[round%_facts.length];final opts=<String>[fact.a,...fact.w]..shuffle(Random(fact.a.length*997+round*97));
   final mine=answers.containsKey(_uid);final status=d['status'];
   return ListView(padding:const EdgeInsets.all(16),children:[
    Card(child:Padding(padding:const EdgeInsets.all(12),child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
     const Text('رمز الدعوة',textAlign:TextAlign.center),
     SelectableText(widget.roomId,textAlign:TextAlign.center,style:const TextStyle(fontSize:19,fontWeight:FontWeight.bold)),
     TextButton.icon(onPressed:(){Clipboard.setData(ClipboardData(text:widget.roomId));ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('تم نسخ الرمز')));},icon:const Icon(Icons.copy),label:const Text('نسخ الرمز')),
     Text('اللاعبون: ${members.length}/4'),
    ]))),
    const SizedBox(height:8),
    ...members.map((id)=>ListTile(dense:true,leading:const Icon(Icons.person),title:Text((names[id]??'لاعب').toString()),trailing:Text('${(scores[id] as num? ??0).toInt()} نقطة'))),
    if(status=='waiting')...[
     const Text('بانتظار بدء المضيف. تحتاج الغرفة لاعبين على الأقل.',textAlign:TextAlign.center),
     if(d['hostId']==_uid)FilledButton(onPressed:members.length>=2?_busy?null:()=>_start(d):null,child:const Text('ابدأ التحدي')),
    ]else if(status=='playing')...[
     Text('السؤال ${round+1} من 20',style:const TextStyle(color:Colors.grey)),
     Card(child:Padding(padding:const EdgeInsets.all(16),child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
      Text(fact.q,style:const TextStyle(fontSize:18,fontWeight:FontWeight.bold)),
      const SizedBox(height:12),
      ...List.generate(4,(i)=>Padding(padding:const EdgeInsets.only(bottom:7),child:OutlinedButton(onPressed:mine||_busy?null:()=>_answer(i,d,fact,opts),child:Text(opts[i])))),
      Text(mine?'تم تسجيل إجابتك. انتظر بقية اللاعبين.':'اختر إجابتك؛ بعد الاختيار لا يمكن تغييره.'),
      Text('الإجابات: ${answers.length}/${members.length}'),
      if(d['hostId']==_uid)FilledButton(onPressed:answers.length==members.length&&!_busy?()=>_next(d):null,child:const Text('السؤال التالي')),
     ]))),
    ]else const Center(child:Text('انتهى التحدي! راجعوا جدول النقاط أعلاه 🏆')),
   ]);
  }),
 ));
}
