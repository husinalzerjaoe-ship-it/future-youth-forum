import 'leaderboard_widget.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

const _c=Color(0xFF6554D9);
final _db=FirebaseFirestore.instance;
String get _uid=>FirebaseAuth.instance.currentUser!.uid;
bool get _founder=>FirebaseAuth.instance.currentUser?.email?.toLowerCase()=='husinalzerjaoe@gmail.com';

class EngagementHubPage extends StatelessWidget {
 const EngagementHubPage({super.key});
 @override Widget build(BuildContext context)=>Directionality(textDirection:TextDirection.rtl,child:Scaffold(
  appBar:AppBar(title:const Text('المرح والإنجازات')),
  body:ListView(padding:const EdgeInsets.all(14),children:[
   Container(padding:const EdgeInsets.all(18),decoration:BoxDecoration(gradient:const LinearGradient(colors:[Color(0xFF171936),_c,Color(0xFF20A8B8)]),borderRadius:BorderRadius.circular(18)),child:const Text('كل يوم بداية جديدة ✨\nاجمع النقاط وتحدَّ أصدقاءك واكتشف كلمات تلهمك',style:TextStyle(color:Colors.white,fontSize:20,fontWeight:FontWeight.bold))),
   const SizedBox(height:12),const _CheckIn(),const _Points(),const LeaderboardWidget(),const _WeeklyContests(),const _Quote(),const _Quiz(),const _SportsNews(),const _News(),
  ]),
 ));
}
class _CheckIn extends StatefulWidget {const _CheckIn();@override State<_CheckIn> createState()=>_CheckInState();}
class _CheckInState extends State<_CheckIn>{
 bool busy=false;String? msg;
 Future<void> claim()async{
  if(busy)return;
  setState(()=>busy=true);
  try{
   final result=await FirebaseFunctions.instance.httpsCallable('claimDailyCheckIn').call();
   final data=Map<String,dynamic>.from(result.data as Map);
   if(mounted)setState(()=>msg=data['awarded']==true?'مبروك! حصلت على 10 نقاط 🎉':'استلمت مكافأة اليوم بالفعل، ارجع باچر!');
  } on FirebaseFunctionsException catch(e){
   if(mounted)setState(()=>msg=e.code=='not-found'
     ?'خدمة المكافأة اليومية غير منشورة بعد على Firebase. يلزم نشر Cloud Functions.'
     :'تعذر استلام النقاط (${e.code}). حاول لاحقاً.');
  } catch(_){
   if(mounted)setState(()=>msg='تعذر تسجيل النقاط. تحقق من اتصالك بالخدمة.');
  } finally {if(mounted)setState(()=>busy=false);}
 }
 @override Widget build(BuildContext context)=>Card(child:Padding(padding:const EdgeInsets.all(14),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const Text('🎁 مكافأة الدخول اليومي',style:TextStyle(fontSize:18,fontWeight:FontWeight.bold)),const Text('كل يوم تدخل تحصل على 10 نقاط.'),FilledButton(onPressed:busy?null:claim,child:Text(busy?'لحظة...':'استلم نقاط اليوم')),if(msg!=null)Text(msg!)])));
}
class _Points extends StatelessWidget{const _Points();@override Widget build(BuildContext context)=>StreamBuilder<DocumentSnapshot<Map<String,dynamic>>>(stream:_db.collection('publicProfiles').doc(_uid).snapshots(),builder:(c,s){final d=s.data?.data()??{};return Card(child:ListTile(leading:const Icon(Icons.emoji_events,color:Colors.orange,size:32),title:Text('${d['points']??0} نقطة',style:const TextStyle(fontSize:20,fontWeight:FontWeight.bold)),subtitle:Text('أيام الحضور: ${d['checkInCount']??0}')));});}
const _sayings=['لا تؤجل حلمك؛ فالخطوة الصغيرة اليوم تصنع فرقاً كبيراً غداً.','كن لطيفاً، فكل إنسان يخوض معركة لا تعرف عنها شيئاً.','من سار على الدرب وصل، ومن زرع المعروف حصد المحبة.','ليس النجاح أن لا تسقط، بل أن تنهض كلما تعثرت.','ابتسم، فربما تكون ابتسامتك أجمل ما يحدث لشخص اليوم.','إذا غامرتَ في شرفٍ مرومِ فلا تقنعْ بما دونَ النجومِ.','وما نيل المطالب بالتمني ولكن تؤخذ الدنيا غلابا.','اجعل أثرك طيباً؛ فالأيام تمضي والذكرى تبقى.','تعلم فليس المرء يولد عالماً وليس أخو علم كمن هو جاهل.','العقول الكبيرة تناقش الأفكار، والقلوب الكبيرة تتسع للناس.'];
class _Quote extends StatefulWidget{const _Quote();@override State<_Quote> createState()=>_QuoteState();}
class _QuoteState extends State<_Quote>{int i=DateTime.now().day%_sayings.length;@override Widget build(BuildContext context)=>Card(color:const Color(0xFFF1EEFF),child:Padding(padding:const EdgeInsets.all(18),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const Text('ومضة اليوم ✨',style:TextStyle(fontSize:18,fontWeight:FontWeight.bold,color:Color(0xFF33265F))),const SizedBox(height:8),Text(_sayings[i],style:const TextStyle(fontSize:18,height:1.7,color:Color(0xFF29233D),fontWeight:FontWeight.w600)),Align(alignment:Alignment.centerLeft,child:TextButton(onPressed:()=>setState(()=>i=(i+1)%_sayings.length),style:TextButton.styleFrom(foregroundColor:const Color(0xFF5141A8)),child:const Text('عبارة أخرى')))])));}
class _Quiz extends StatefulWidget{const _Quiz();@override State<_Quiz> createState()=>_QuizState();}
class _QuizState extends State<_Quiz>{
 final qs=<({String q,List<String> a,int correct,String why})>[
 (q:'ما عاصمة العراق؟',a:['البصرة','بغداد','الموصل'],correct:1,why:'بغداد هي عاصمة العراق.'),
 (q:'كم عدد أيام الأسبوع؟',a:['5','6','7'],correct:2,why:'الأسبوع سبعة أيام.'),
 (q:'ما الكوكب الأحمر؟',a:['المريخ','الزهرة','زحل'],correct:0,why:'أكاسيد الحديد تمنح المريخ لونه الأحمر.'),
 (q:'ما ناتج 9 × 7؟',a:['56','63','72'],correct:1,why:'تسعة في سبعة تساوي 63.'),
 (q:'سفينة الصحراء؟',a:['الحصان','الجمل','الغزال'],correct:1,why:'الجمل يتحمل ظروف الصحراء.'),
 ];
 int n=0,score=0;int? choice;bool done=false;
 void pick(int x){if(choice!=null)return;setState((){choice=x;if(x==qs[n].correct)score+=2;});}
 Future<void> finish()async{setState(()=>done=true);try{final r=_db.collection('publicProfiles').doc(_uid);await _db.runTransaction((t)async{final s=await t.get(r);t.set(r,{'points':((s.data()?['points'] as num?)?.toInt()??0)+score},SetOptions(merge:true));});}catch(_){}}
 @override Widget build(BuildContext context){final q=qs[n];return Card(child:Padding(padding:const EdgeInsets.all(15),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const Text('🧠 تحدي المعلومات',style:TextStyle(fontSize:18,fontWeight:FontWeight.bold)),if(done)...[Text('نتيجتك $score من 10 نقاط 🎉'),TextButton(onPressed:()=>setState((){n=0;score=0;choice=null;done=false;}),child:const Text('إعادة اللعب'))]else...[
 Text('السؤال ${n+1} من 5: ${q.q}',style:const TextStyle(fontWeight:FontWeight.bold)),
 ...List.generate(q.a.length,(i)=>SizedBox(width:double.infinity,child:OutlinedButton(onPressed:choice==null?()=>pick(i):null,child:Text(q.a[i])))),
 if(choice!=null)...[Text(choice==q.correct?'إجابة صحيحة +2 ⭐':'الإجابة الصحيحة: ${q.a[q.correct]}'),Text(q.why),FilledButton(onPressed:(){if(n==4){finish();}else{setState((){n++;choice=null;});}},child:Text(n==4?'إنهاء':'التالي'))]
 ]])));}
}
class _News extends StatelessWidget{
 const _News();
 Future<void> add(BuildContext context)async{final title=TextEditingController(),body=TextEditingController();final ok=await showDialog<bool>(context:context,builder:(c)=>Directionality(textDirection:TextDirection.rtl,child:AlertDialog(title:const Text('إضافة خبر للمطور Alfredo'),content:Column(mainAxisSize:MainAxisSize.min,children:[TextField(controller:title,decoration:const InputDecoration(labelText:'العنوان')),TextField(controller:body,minLines:3,maxLines:5,decoration:const InputDecoration(labelText:'التفاصيل'))]),actions:[TextButton(onPressed:()=>Navigator.pop(c,false),child:const Text('إلغاء')),FilledButton(onPressed:()=>Navigator.pop(c,true),child:const Text('نشر'))])));if(ok==true&&title.text.trim().isNotEmpty&&body.text.trim().isNotEmpty){await _db.collection('forumAnnouncements').add({'title':title.text.trim(),'body':body.text.trim(),'author':'Alfredo','createdAt':FieldValue.serverTimestamp()});}title.dispose();body.dispose();}
 @override Widget build(BuildContext context)=>Card(child:Padding(padding:const EdgeInsets.all(14),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Row(children:[const Expanded(child:Text('أخبار الملتقى والمطور',style:TextStyle(fontSize:18,fontWeight:FontWeight.bold))),if(_founder)IconButton(onPressed:()=>add(context),icon:const Icon(Icons.add_circle,color:_c))]),StreamBuilder<QuerySnapshot<Map<String,dynamic>>>(stream:_db.collection('forumAnnouncements').orderBy('createdAt',descending:true).limit(20).snapshots(),builder:(c,s){if(s.hasError)return const Text('الأخبار غير متاحة حالياً؛ تحقق من قواعد Firestore.');if(!s.hasData)return const LinearProgressIndicator();if(s.data!.docs.isEmpty)return const Text('تابع هنا أخبار وتحديثات الملتقى.');return Column(children:s.data!.docs.map((x){final d=x.data();return ListTile(leading:const Icon(Icons.campaign,color:_c),title:Text(d['title']??'إعلان'),subtitle:Text('${d['body']??''}\n— ${d['author']??'إدارة الملتقى'}'));}).toList());})])));
}


class _SportsNews extends StatelessWidget {
 const _SportsNews({super.key});
 Future<void> _add(BuildContext context) async {
  final title=TextEditingController(), body=TextEditingController(), source=TextEditingController();
  final ok=await showDialog<bool>(context:context,builder:(c)=>Directionality(textDirection:TextDirection.rtl,child:AlertDialog(
   title:const Text('نشر خبر رياضي'),
   content:SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min,children:[
    TextField(controller:title,maxLength:120,decoration:const InputDecoration(labelText:'عنوان الخبر')),
    TextField(controller:body,minLines:3,maxLines:6,maxLength:1500,decoration:const InputDecoration(labelText:'تفاصيل الخبر')),
    TextField(controller:source,keyboardType:TextInputType.url,decoration:const InputDecoration(labelText:'رابط المصدر (اختياري)')),
   ])),
   actions:[TextButton(onPressed:()=>Navigator.pop(c,false),child:const Text('إلغاء')),FilledButton(onPressed:()=>Navigator.pop(c,true),child:const Text('نشر'))]
  )));
  if(ok==true && title.text.trim().isNotEmpty && body.text.trim().isNotEmpty){
   final link=Uri.tryParse(source.text.trim());
   if(source.text.trim().isNotEmpty && (link==null || link.scheme!='https' || link.host.isEmpty)){
    if(context.mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('رابط المصدر يجب أن يبدأ بـ https://')));
   } else {
    await _db.collection('sportsNews').add({'title':title.text.trim(),'body':body.text.trim(),'sourceUrl':source.text.trim(),'authorId':_uid,'author':'Alfredo','createdAt':FieldValue.serverTimestamp()});
   }
  }
  title.dispose();body.dispose();source.dispose();
 }
 @override Widget build(BuildContext context)=>Card(child:Padding(padding:const EdgeInsets.all(14),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
  Row(children:[const Expanded(child:Text('أخبار الرياضة وكرة القدم ⚽',style:TextStyle(fontSize:18,fontWeight:FontWeight.bold))),if(_founder)IconButton(onPressed:()=>_add(context),icon:const Icon(Icons.add_circle,color:_c),tooltip:'نشر خبر')]),
  const Text('أخبار ينشرها فريق الملتقى مع رابط المصدر عند توفره.',style:TextStyle(fontSize:12,color:Colors.grey)),
  StreamBuilder<QuerySnapshot<Map<String,dynamic>>>(stream:_db.collection('sportsNews').orderBy('createdAt',descending:true).limit(30).snapshots(),builder:(c,s){
   if(s.hasError)return const Text('تعذر تحميل الأخبار. تحقق من نشر قواعد Firestore.');
   if(!s.hasData)return const LinearProgressIndicator();
   if(s.data!.docs.isEmpty)return const Padding(padding:EdgeInsets.symmetric(vertical:12),child:Text('لا توجد أخبار منشورة حالياً.'));
   return Column(children:s.data!.docs.map((doc){final d=doc.data();final url=(d['sourceUrl']??'').toString();return ListTile(
    contentPadding:EdgeInsets.zero,leading:const Icon(Icons.sports_soccer,color:_c),
    title:Text((d['title']??'خبر رياضي').toString(),style:const TextStyle(fontWeight:FontWeight.bold)),
    subtitle:Text((d['body']??'').toString()),
    trailing:url.startsWith('https://')?IconButton(icon:const Icon(Icons.open_in_new),tooltip:'فتح المصدر',onPressed:()=>launchUrl(Uri.parse(url),mode:LaunchMode.externalApplication)):null,
   );}).toList());
  })
 ])));
}


class _WeeklyContests extends StatelessWidget {
 const _WeeklyContests({super.key});
 Future<void> _create(BuildContext context) async {
  final title=TextEditingController();
  final ok=await showDialog<bool>(context:context,builder:(c)=>Directionality(textDirection:TextDirection.rtl,child:AlertDialog(
   title:const Text('إنشاء مسابقة أسبوعية'),
   content:TextField(controller:title,maxLength:120,decoration:const InputDecoration(labelText:'عنوان المسابقة')),
   actions:[TextButton(onPressed:()=>Navigator.pop(c,false),child:const Text('إلغاء')),FilledButton(onPressed:()=>Navigator.pop(c,true),child:const Text('إنشاء'))]
  )));
  if(ok==true && title.text.trim().isNotEmpty){
   try{
    await _db.collection('weeklyContests').add({
     'title':title.text.trim(),'status':'open','createdBy':_uid,
     'createdAt':FieldValue.serverTimestamp(),
     'endsAt':Timestamp.fromDate(DateTime.now().add(const Duration(days:7))),
    });
   }catch(e){if(context.mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('تعذر إنشاء المسابقة: $e')));}
  }
  title.dispose();
 }
 Future<void> _join(BuildContext context, String contestId) async {
  try{
   final profile=await _db.collection('publicProfiles').doc(_uid).get();
   await _db.collection('weeklyContests').doc(contestId).collection('entries').doc(_uid).set({
    'uid':_uid,'name':profile.data()?['name']??FirebaseAuth.instance.currentUser?.displayName??'عضو',
    'joinedAt':FieldValue.serverTimestamp(),
   });
   if(context.mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('تم تسجيل اشتراكك بالمسابقة!')));
  }catch(e){if(context.mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('تعذر الاشتراك: $e')));}
 }
 Future<void> _chooseWinner(BuildContext context, String contestId, List<QueryDocumentSnapshot<Map<String,dynamic>>> entries) async {
  if(entries.isEmpty)return;
  final winner=await showDialog<QueryDocumentSnapshot<Map<String,dynamic>>>(context:context,builder:(c)=>Directionality(textDirection:TextDirection.rtl,child:AlertDialog(
   title:const Text('اختيار الفائز ومنحه عضوية مجانية'),
   content:SizedBox(width:360,height:320,child:ListView(children:entries.map((e)=>ListTile(
    leading:const Icon(Icons.person),title:Text((e.data()['name']??'عضو').toString()),
    onTap:()=>Navigator.pop(c,e),
   )).toList())),
   actions:[TextButton(onPressed:()=>Navigator.pop(c),child:const Text('إلغاء'))]
  )));
  if(winner==null)return;
  final uid=(winner.data()['uid']??winner.id).toString();
  try{
   await _db.runTransaction((tx)async{
    final contest=_db.collection('weeklyContests').doc(contestId);
    final membership=_db.collection('memberships').doc(uid);
    final snap=await tx.get(contest);
    final oldMembership=await tx.get(membership);
    if(!snap.exists || snap.data()?['status']!='open') throw StateError('المسابقة مغلقة أو تم اختيار فائز مسبقاً.');
    final now=DateTime.now();
    final oldExpiry=oldMembership.data()?['expiresAt'];
    final baseExpiry=oldExpiry is Timestamp && oldExpiry.toDate().isAfter(now) ? oldExpiry.toDate() : now;
    final oldTier=(oldMembership.data()?['tier']??'premium').toString();
    final tier=['premium','silver','gold','diamond'].contains(oldTier)?oldTier:'premium';
    tx.update(contest,{'status':'completed','winnerUid':uid,'winnerChosenAt':FieldValue.serverTimestamp()});
    tx.set(membership,{
     'uid':uid,'tier':tier,
     'expiresAt':Timestamp.fromDate(baseExpiry.add(const Duration(days:7))),
     'grantedBy':_uid,'grantReason':'weeklyContest','grantedAt':FieldValue.serverTimestamp(),
    }, SetOptions(merge:true));
   });
   if(context.mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('تم اختيار الفائز ومنحه عضوية مجانية لمدة 7 أيام 🎉')));
  }catch(e){if(context.mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('تعذر منح العضوية: $e')));}
 }
 @override Widget build(BuildContext context)=>Card(child:Padding(padding:const EdgeInsets.all(14),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
  Row(children:[const Expanded(child:Text('🏅 المسابقات الأسبوعية والعضوية المجانية',style:TextStyle(fontSize:17,fontWeight:FontWeight.bold))),if(_founder)IconButton(onPressed:()=>_create(context),icon:const Icon(Icons.add_circle,color:_c),tooltip:'إنشاء مسابقة')]),
  const Text('اشترك بالمسابقة، والفائز يحصل على عضوية مميزة لمدة 7 أيام.',style:TextStyle(fontSize:12,color:Colors.grey)),
  StreamBuilder<QuerySnapshot<Map<String,dynamic>>>(stream:_db.collection('weeklyContests').orderBy('endsAt',descending:true).limit(10).snapshots(),builder:(c,s){
   if(s.hasError)return const Text('تعذر تحميل المسابقات. تحقق من قواعد Firestore.');
   if(!s.hasData)return const LinearProgressIndicator();
   if(s.data!.docs.isEmpty)return const Padding(padding:EdgeInsets.symmetric(vertical:12),child:Text('لا توجد مسابقات حالياً.'));
   return Column(children:s.data!.docs.map((doc){
    final d=doc.data();final open=d['status']=='open';
    return Column(children:[
     ListTile(contentPadding:EdgeInsets.zero,leading:const Icon(Icons.emoji_events,color:Colors.orange),
      title:Text((d['title']??'مسابقة أسبوعية').toString()),
      subtitle:Text(open?'تنتهي: ${(d['endsAt'] as Timestamp?)?.toDate().toLocal().toString().split('.').first??'قريباً'}':'انتهت المسابقة'),
      trailing:open?FilledButton.tonal(onPressed:()=>_join(context,doc.id),child:const Text('اشترك')):const Icon(Icons.check_circle,color:Colors.green)),
     if(_founder && open)
      StreamBuilder<QuerySnapshot<Map<String,dynamic>>>(stream:doc.reference.collection('entries').snapshots(),builder:(ctx,entries){
       final list=entries.data?.docs??[];
       return Align(alignment:Alignment.centerLeft,child:TextButton.icon(
        onPressed:list.isEmpty?null:()=>_chooseWinner(context,doc.id,list),
        icon:const Icon(Icons.workspace_premium),label:Text('اختيار الفائز (${list.length})')));
      }),
     if(d['winnerUid']!=null)Text('الفائز: ${d['winnerUid']} • عضوية مجانية 7 أيام',style:const TextStyle(color:Colors.green,fontWeight:FontWeight.bold)),
     const Divider(),
    ]);
   }).toList());
  })
 ])));
}
