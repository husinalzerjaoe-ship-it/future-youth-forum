import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:video_player/video_player.dart';
import 'package:url_launcher/url_launcher.dart';
import 'local_bot.dart';

const p=Color(0xFF6554D9);
final db2=FirebaseFirestore.instance;
const founderEmail='husinalzerjaoe@gmail.com';
bool get isForumFounder => FirebaseAuth.instance.currentUser?.email?.toLowerCase()==founderEmail;

class CommunityHubPage extends StatelessWidget {
 const CommunityHubPage({super.key});
 @override Widget build(BuildContext context) {
  final items=[
   ('الشعر','قصائد الأعضاء',Icons.auto_awesome,const PoetryPage()),
   ('الاقتباسات','انسخ أجمل العبارات',Icons.format_quote,const QuotesPage()),
   ('الستوريات','صور وفيديوهات لمدة 24 ساعة',Icons.camera_alt,const StoriesPage()),
   ('دردشات الدول','العراق وسوريا وثلاث غرف أخرى',Icons.forum,const RegionChatRoomsPage()),
   ('المساعد الذكي','مساعد مجاني داخل التطبيق',Icons.smart_toy,const LocalHelperBotPage()),
   ('يوتيوب والترفيه','أغانٍ وفيديوهات وروابط أفلام رسمية',Icons.play_circle_fill,const YouTubeShelfPage()),
  ];
  return Directionality(textDirection:TextDirection.rtl,child:ListView(padding:const EdgeInsets.all(16),children:[
   Container(padding:const EdgeInsets.all(20),decoration:BoxDecoration(
    gradient:const LinearGradient(colors:[Color(0xFF171936),p,Color(0xFF35BCEB)]),borderRadius:BorderRadius.circular(20)),
    child:const Text('مساحات ملتقى شباب المستقبل ✨\nشارك إبداعك وتواصل مع الجميع',style:TextStyle(color:Colors.white,fontSize:20,fontWeight:FontWeight.bold))),
   const SizedBox(height:14),
   GridView.builder(shrinkWrap:true,physics:const NeverScrollableScrollPhysics(),itemCount:items.length,
    gridDelegate:const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount:2,childAspectRatio:1.1,crossAxisSpacing:10,mainAxisSpacing:10),
    itemBuilder:(c,i)=>Card(child:InkWell(borderRadius:BorderRadius.circular(16),onTap:()=>Navigator.push(c,MaterialPageRoute(builder:(_)=>items[i].$4)),
     child:Column(mainAxisAlignment:MainAxisAlignment.center,children:[
      Icon(items[i].$3,size:38,color:p),const SizedBox(height:8),
      Text(items[i].$1,style:const TextStyle(fontWeight:FontWeight.bold,fontSize:18)),
      Padding(padding:const EdgeInsets.all(6),child:Text(items[i].$2,textAlign:TextAlign.center,style:const TextStyle(fontSize:12,color:Colors.black54)))
     ]))))
  ]));
 }
}

class TextShelf extends StatelessWidget {
 final String collection,title,hint;
 const TextShelf({super.key,required this.collection,required this.title,required this.hint});
 Future<void> add(BuildContext c) async {
  final t=TextEditingController();
  final ok=await showDialog<bool>(context:c,builder:(x)=>Directionality(textDirection:TextDirection.rtl,child:AlertDialog(
   title:Text('إضافة $title'),content:TextField(controller:t,minLines:4,maxLines:10,maxLength:3000,decoration:InputDecoration(hintText:hint,border:const OutlineInputBorder())),
   actions:[TextButton(onPressed:()=>Navigator.pop(x,false),child:const Text('إلغاء')),FilledButton(onPressed:()=>Navigator.pop(x,true),child:const Text('نشر') )])));
  final value=t.text.trim();t.dispose();if(ok!=true||value.isEmpty)return;
  final u=FirebaseAuth.instance.currentUser!;final profile=await db2.collection('publicProfiles').doc(u.uid).get();
  await db2.collection(collection).add({'text':value,'authorId':u.uid,'authorName':profile.data()?['name']??u.displayName??'عضو','createdAt':FieldValue.serverTimestamp()});
 }
 @override Widget build(BuildContext context)=>Directionality(textDirection:TextDirection.rtl,child:Scaffold(
  appBar:AppBar(title:Text(title)),
  body:StreamBuilder<QuerySnapshot<Map<String,dynamic>>>(stream:db2.collection(collection).orderBy('createdAt',descending:true).limit(100).snapshots(),builder:(c,s){
   if(s.hasError)return const Center(child:Text('تعذر التحميل. تأكد من نشر قواعد Firestore.'));
   if(!s.hasData)return const Center(child:CircularProgressIndicator());
   if(s.data!.docs.isEmpty)return Center(child:Text('لا يوجد $title بعد.'));
   return ListView(padding:const EdgeInsets.all(12),children:s.data!.docs.map((doc){
    final d=doc.data();final value=d['text'] as String? ??'';
    return Card(child:Padding(padding:const EdgeInsets.all(14),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
     Row(children:[const Icon(Icons.person,color:p),const SizedBox(width:8),Expanded(child:Text(d['authorName'] as String? ??'عضو',style:const TextStyle(fontWeight:FontWeight.bold))),
      IconButton(tooltip:'نسخ',icon:const Icon(Icons.copy),onPressed:(){Clipboard.setData(ClipboardData(text:value));ScaffoldMessenger.of(c).showSnackBar(const SnackBar(content:Text('تم نسخ النص')));})]),
     SelectableText(value,style:const TextStyle(fontSize:17,height:1.6))
    ])));
   }).toList());
  }),
  floatingActionButton:FloatingActionButton.extended(backgroundColor:p,foregroundColor:Colors.white,onPressed:()=>add(context),icon:const Icon(Icons.add),label:Text('أضف $title')),
 ));
}
class PoetryPage extends StatelessWidget {const PoetryPage({super.key});@override Widget build(BuildContext c)=>const TextShelf(collection:'poems',title:'الشعر',hint:'اكتب قصيدتك هنا...');}
class QuotesPage extends StatelessWidget {const QuotesPage({super.key});@override Widget build(BuildContext c)=>const TextShelf(collection:'quotes',title:'الاقتباسات',hint:'اكتب اقتباسك هنا...');}

class StoriesPage extends StatefulWidget {const StoriesPage({super.key});@override State<StoriesPage> createState()=>_StoriesPageState();}
class _StoriesPageState extends State<StoriesPage>{
 bool busy=false;
 Future<void> add()async{
  final pick=ImagePicker();
  final type=await showModalBottomSheet<String>(context:context,builder:(c)=>SafeArea(child:Wrap(children:[
   ListTile(leading:const Icon(Icons.image),title:const Text('صورة'),onTap:()=>Navigator.pop(c,'image')),
   ListTile(leading:const Icon(Icons.video_library),title:const Text('فيديو (حتى دقيقة)'),onTap:()=>Navigator.pop(c,'video'))
  ])));
  if(type==null)return;
  final file=type=='image'?await pick.pickImage(source:ImageSource.gallery,imageQuality:85):await pick.pickVideo(source:ImageSource.gallery,maxDuration:const Duration(seconds:60));
  if(file==null)return;setState(()=>busy=true);
  try{
   final u=FirebaseAuth.instance.currentUser!;final ext=file.path.split('.').last;
   final objectPath='stories/'+u.uid+'/'+DateTime.now().millisecondsSinceEpoch.toString()+'.'+ext;
   final contentType=type=='video'?'video/mp4':'image/jpeg';
   await Supabase.instance.client.storage.from('forum-media').uploadBinary(
    objectPath, await file.readAsBytes(),
    fileOptions: FileOptions(contentType:contentType,upsert:true),
   );
   final url=Supabase.instance.client.storage.from('forum-media').getPublicUrl(objectPath);
   final profile=await db2.collection('publicProfiles').doc(u.uid).get();
   await db2.collection('stories').add({'mediaUrl':url,'mediaType':type,'authorId':u.uid,'authorName':profile.data()?['name']??u.displayName??'عضو','createdAt':FieldValue.serverTimestamp(),'expiresAt':Timestamp.fromDate(DateTime.now().add(const Duration(hours:24)))});
   if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('تم نشر الستوري لمدة 24 ساعة')));
  }catch(_){if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('تعذر رفع الستوري. تأكد من سياسة الرفع في Supabase Storage والإنترنت.')));}
  finally{if(mounted)setState(()=>busy=false);}
 }
 @override Widget build(BuildContext context)=>Directionality(textDirection:TextDirection.rtl,child:Scaffold(
  appBar:AppBar(title:const Text('الستوريات')),
  body:StreamBuilder<QuerySnapshot<Map<String,dynamic>>>(stream:db2.collection('stories').orderBy('createdAt',descending:true).limit(100).snapshots(),builder:(c,s){
   if(s.hasError)return const Center(child:Text('تعذر تحميل الستوريات'));
   if(!s.hasData)return const Center(child:CircularProgressIndicator());
   final docs=s.data!.docs.where((d){final x=d.data()['expiresAt'] as Timestamp?;return x==null||x.toDate().isAfter(DateTime.now());}).toList();
   if(docs.isEmpty)return const Center(child:Text('ماكو ستوريات حالياً'));
   return ListView(children:docs.map((doc){final d=doc.data();final video=d['mediaType']=='video';final url=d['mediaUrl'] as String;
    return Card(clipBehavior:Clip.antiAlias,child:Column(children:[
     ListTile(leading:const CircleAvatar(child:Icon(Icons.person)),title:Text(d['authorName'] as String? ??'عضو')),
     if(video)Container(height:220,color:Colors.black,child:IconButton(color:Colors.white,iconSize:60,icon:const Icon(Icons.play_circle),onPressed:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>StoryVideoPage(url:url)))))
     else Image.network(url,width:double.infinity,height:250,fit:BoxFit.cover),
     const Padding(padding:EdgeInsets.all(8),child:Text('تختفي بعد 24 ساعة',style:TextStyle(color:Colors.black54,fontSize:12)))
    ]));
   }).toList());
  }),
  floatingActionButton:FloatingActionButton.extended(backgroundColor:p,foregroundColor:Colors.white,onPressed:busy?null:add,icon:busy?const CircularProgressIndicator(color:Colors.white):const Icon(Icons.add_a_photo),label:Text(busy?'جارٍ الرفع':'إضافة ستوري'))
 ));
}
class StoryVideoPage extends StatefulWidget{final String url;const StoryVideoPage({super.key,required this.url});@override State<StoryVideoPage> createState()=>_StoryVideoPageState();}
class _StoryVideoPageState extends State<StoryVideoPage>{
 late VideoPlayerController v;
 @override void initState(){super.initState();v=VideoPlayerController.networkUrl(Uri.parse(widget.url))..initialize().then((_){if(mounted)setState((){});});}
 @override void dispose(){v.dispose();super.dispose();}
 @override Widget build(BuildContext c)=>Scaffold(backgroundColor:Colors.black,appBar:AppBar(backgroundColor:Colors.black,foregroundColor:Colors.white,title:const Text('الفيديو')),
 body:Center(child:v.value.isInitialized?AspectRatio(aspectRatio:v.value.aspectRatio,child:Stack(alignment:Alignment.center,children:[VideoPlayer(v),IconButton(color:Colors.white,iconSize:60,icon:Icon(v.value.isPlaying?Icons.pause_circle:Icons.play_circle),onPressed:()=>setState(()=>v.value.isPlaying?v.pause():v.play()))])):const CircularProgressIndicator(color:Colors.white)));
}

class RegionChatRoomsPage extends StatelessWidget{
 const RegionChatRoomsPage({super.key});
 static const rooms=[('iraq','دردشة أهل العراق','🇮🇶'),('syria','دردشة أهل سوريا','🇸🇾'),('palestine','دردشة فلسطين','🇵🇸'),('gulf','دردشة الخليج','🌴'),('general','دردشة الأصدقاء','🌍')];
 @override Widget build(BuildContext c)=>Directionality(textDirection:TextDirection.rtl,child:Scaffold(appBar:AppBar(title:const Text('دردشات الدول')),body:ListView(padding:const EdgeInsets.all(12),children:rooms.map((r)=>Card(child:ListTile(leading:Text(r.$3,style:const TextStyle(fontSize:28)),title:Text(r.$2,style:const TextStyle(fontWeight:FontWeight.bold)),subtitle:const Text('محادثة مباشرة'),trailing:const Icon(Icons.chevron_left),onTap:()=>Navigator.push(c,MaterialPageRoute(builder:(_)=>RegionChatPage(id:r.$1,title:r.$2)))))).toList())));
 }
class RegionChatPage extends StatefulWidget{final String id,title;const RegionChatPage({super.key,required this.id,required this.title});@override State<RegionChatPage> createState()=>_RegionChatPageState();}
class _RegionChatPageState extends State<RegionChatPage>{

 final t=TextEditingController();bool busy=false;
 bool get founder => isForumFounder;
 Future<bool> blocked(String uid) async {
  final snap=await db2.collection('regionalChats').doc(widget.id).collection('bans').doc(uid).get();
  if(!snap.exists)return false;
  final data=snap.data()??{};
  if(data['permanent']==true)return true;
  final until=data['expiresAt'] as Timestamp?;
  if(until==null || !until.toDate().isAfter(DateTime.now())) return false;
  return true;
 }
 Future<void> moderate(String uid,String name) async {
  if(!founder || uid==FirebaseAuth.instance.currentUser!.uid)return;
  final choice=await showDialog<String>(context:context,builder:(c)=>Directionality(
   textDirection:TextDirection.rtl,child:AlertDialog(
    title:Text('إدارة العضو: $name'),
    content:const Text('اختار مدة المنع من دخول هذه الغرفة.'),
    actions:[
     TextButton(onPressed:()=>Navigator.pop(c,'cancel'),child:const Text('إلغاء')),
     TextButton(onPressed:()=>Navigator.pop(c,'kick'),child:const Text('طرد مؤقت')),
     TextButton(onPressed:()=>Navigator.pop(c,'1h'),child:const Text('ساعة')),
     TextButton(onPressed:()=>Navigator.pop(c,'2h'),child:const Text('ساعتين')),
     TextButton(onPressed:()=>Navigator.pop(c,'1d'),child:const Text('يوم')),
     TextButton(onPressed:()=>Navigator.pop(c,'forever'),child:const Text('للأبد')),
     TextButton(onPressed:()=>Navigator.pop(c,'unban'),child:const Text('رفع الحظر')),
    ])));
  if(choice==null || choice=='cancel')return;
  final ref=db2.collection('regionalChats').doc(widget.id).collection('bans').doc(uid);
  if(choice=='unban') { await ref.delete(); }
  else {
   final duration=choice=='kick'?const Duration(minutes:1):choice=='1h'?const Duration(hours:1):choice=='2h'?const Duration(hours:2):choice=='1d'?const Duration(days:1):null;
   await ref.set({'permanent':duration==null,'expiresAt':duration==null?null:Timestamp.fromDate(DateTime.now().add(duration)),'by':FirebaseAuth.instance.currentUser!.uid,'updatedAt':FieldValue.serverTimestamp()});
  }
  if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(choice=='unban'?'تم رفع الحظر':choice=='kick'?'تم الطرد المؤقت':'تم تطبيق الحظر')));
 }
 @override void dispose(){t.dispose();super.dispose();}
 Future<void> send()async{final value=t.text.trim();if(value.isEmpty||busy)return;final me=FirebaseAuth.instance.currentUser!;if(await blocked(me.uid)){if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('أنت ممنوع من هذه الغرفة حالياً.')));return;}setState(()=>busy=true);
 try{final u=FirebaseAuth.instance.currentUser!;final profile=await db2.collection('publicProfiles').doc(u.uid).get();
 await db2.collection('regionalChats').doc(widget.id).collection('messages').add({'text':value,'senderId':u.uid,'senderName':profile.data()?['name']??u.displayName??'عضو','createdAt':FieldValue.serverTimestamp()});t.clear();}
 catch(_){if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('انشر قواعد Firestore الجديدة أولاً')));}
 finally{if(mounted)setState(()=>busy=false);}}
 @override Widget build(BuildContext c)=>Directionality(textDirection:TextDirection.rtl,child:Scaffold(appBar:AppBar(title:Text(widget.title),actions:[if(founder)const Padding(padding:EdgeInsets.symmetric(horizontal:8),child:Center(child:Text('👑 المؤسس',style:TextStyle(fontWeight:FontWeight.bold)))),IconButton(tooltip:'مساعد الملتقى',icon:const Icon(Icons.smart_toy),onPressed:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const LocalHelperBotPage()))) ]),body:Column(children:[
 Expanded(child:StreamBuilder<QuerySnapshot<Map<String,dynamic>>>(stream:db2.collection('regionalChats').doc(widget.id).collection('messages').orderBy('createdAt',descending:true).limit(150).snapshots(),builder:(c,s){
 if(s.hasError)return const Center(child:Text('الدردشة تحتاج قواعد Firestore الجديدة'));if(!s.hasData)return const Center(child:CircularProgressIndicator());
 if(s.data!.docs.isEmpty)return const Center(child:Text('ابدأ المحادثة 👋'));
 final me=FirebaseAuth.instance.currentUser!.uid;
 return ListView.builder(reverse:true,padding:const EdgeInsets.all(12),itemCount:s.data!.docs.length,itemBuilder:(c,i){final d=s.data!.docs[i].data();final mine=d['senderId']==me;final senderId=d['senderId'] as String? ?? '';final senderName=d['senderName'] as String? ?? 'عضو';
 return Align(alignment:mine?Alignment.centerRight:Alignment.centerLeft,child:Container(margin:const EdgeInsets.symmetric(vertical:5),padding:const EdgeInsets.all(12),constraints:BoxConstraints(maxWidth:MediaQuery.of(c).size.width*.8),decoration:BoxDecoration(color:mine?const Color(0xFFE8E3FF):Colors.white,borderRadius:BorderRadius.circular(14)),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[if(!mine)Row(mainAxisSize:MainAxisSize.min,children:[Flexible(child:Text(senderName,style:const TextStyle(color:p,fontWeight:FontWeight.bold,fontSize:12))),if(founder)IconButton(visualDensity:VisualDensity.compact,tooltip:'إدارة العضو',icon:const Icon(Icons.admin_panel_settings,size:18),onPressed:()=>moderate(senderId,senderName))]),Text(d['text'] as String? ??'')])));});
 })),
 SafeArea(top:false,child:Padding(padding:const EdgeInsets.all(10),child:Row(children:[Expanded(child:TextField(controller:t,minLines:1,maxLines:4,maxLength:1000,textInputAction:TextInputAction.send,onSubmitted:(_)=>send(),decoration:const InputDecoration(hintText:'اكتب رسالتك...',counterText:'',border:OutlineInputBorder()))),IconButton.filled(onPressed:busy?null:send,icon:const Icon(Icons.send))])))
 ])));
 }


class YouTubeShelfPage extends StatefulWidget {
 const YouTubeShelfPage({super.key});
 @override State<YouTubeShelfPage> createState()=>_YouTubeShelfPageState();
}
class _YouTubeShelfPageState extends State<YouTubeShelfPage> {
 final title=TextEditingController();
 final url=TextEditingController();
 String category='أغاني';
 bool busy=false;
 static const categories=['أغاني','فيديوهات','أفلام ومقاطع رسمية','تعليم','متنوع'];
 bool validYoutube(String value) {
  final uri=Uri.tryParse(value.trim());
  if(uri==null||uri.scheme!='https') return false;
  return ['youtube.com','www.youtube.com','m.youtube.com','youtu.be','www.youtu.be'].contains(uri.host.toLowerCase());
 }
 Future<void> add() async {
  if(title.text.trim().isEmpty||!validYoutube(url.text)) {
   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('اكتب عنواناً ورابط يوتيوب صحيحاً يبدأ بـ https')));
   return;
  }
  setState(()=>busy=true);
  try {
   final user=FirebaseAuth.instance.currentUser!;
   final profile=await db2.collection('publicProfiles').doc(user.uid).get();
   await db2.collection('mediaLinks').add({
    'title':title.text.trim(),'url':url.text.trim(),'category':category,
    'authorId':user.uid,'authorName':profile.data()?['name']??user.displayName??'عضو',
    'createdAt':FieldValue.serverTimestamp(),
   });
   title.clear();url.clear();
   if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('تمت إضافة الرابط')));
  } catch (_) {
   if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('تعذرت الإضافة. تأكد من نشر قواعد Firestore')));
  } finally {if(mounted)setState(()=>busy=false);}
 }
 Future<void> openVideo(String value) async {
  final uri=Uri.tryParse(value);
  if(uri==null||!validYoutube(value)) return;
  if(!await launchUrl(uri,mode:LaunchMode.externalApplication) && mounted) {
   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('تعذر فتح يوتيوب')));
  }
 }
 @override void dispose(){title.dispose();url.dispose();super.dispose();}
 @override Widget build(BuildContext context)=>Directionality(
  textDirection:TextDirection.rtl,
  child:Scaffold(
   appBar:AppBar(title:const Text('يوتيوب والترفيه')),
   floatingActionButton:FloatingActionButton.extended(
    onPressed:busy?null:()=>showModalBottomSheet<void>(context:context,isScrollControlled:true,builder:(c)=>Directionality(
     textDirection:TextDirection.rtl,
     child:Padding(padding:EdgeInsets.only(left:18,right:18,top:18,bottom:MediaQuery.of(c).viewInsets.bottom+18),
      child:Column(mainAxisSize:MainAxisSize.min,children:[
       const Text('إضافة رابط يوتيوب',style:TextStyle(fontSize:18,fontWeight:FontWeight.bold)),
       const SizedBox(height:12),
       TextField(controller:title,decoration:const InputDecoration(labelText:'عنوان الأغنية أو الفيديو',border:OutlineInputBorder())),
       const SizedBox(height:10),
       TextField(controller:url,keyboardType:TextInputType.url,decoration:const InputDecoration(labelText:'رابط YouTube',hintText:'https://youtu.be/...',border:OutlineInputBorder())),
       const SizedBox(height:10),
       DropdownButtonFormField<String>(value:category,decoration:const InputDecoration(labelText:'القسم'),items:categories.map((x)=>DropdownMenuItem(value:x,child:Text(x))).toList(),onChanged:(x){if(x!=null)setState(()=>category=x);}),
       const SizedBox(height:12),
       FilledButton(onPressed:busy?null:()async{Navigator.pop(c);await add();},child:const Text('حفظ الرابط')),
      ]),
     ),
    )),
    icon:const Icon(Icons.add),label:const Text('أضف رابطاً'),
   ),
   body:StreamBuilder<QuerySnapshot<Map<String,dynamic>>>(
    stream:db2.collection('mediaLinks').orderBy('createdAt',descending:true).limit(100).snapshots(),
    builder:(c,s){
     if(s.hasError)return const Center(child:Text('تعذر تحميل الروابط. انشر قواعد Firestore الجديدة'));
     if(!s.hasData)return const Center(child:CircularProgressIndicator());
     if(s.data!.docs.isEmpty)return const Center(child:Text('ماكو روابط بعد. أضف أول أغنية أو فيديو'));
     return ListView(padding:const EdgeInsets.all(12),children:s.data!.docs.map((doc){
      final d=doc.data();
      return Card(child:ListTile(
       leading:const CircleAvatar(child:Icon(Icons.play_arrow)),
       title:Text(d['title'] as String? ??'فيديو'),
       subtitle:Text('${d['category']??'متنوع'} • ${d['authorName']??'عضو'}'),
       trailing:IconButton(icon:const Icon(Icons.open_in_new),onPressed:()=>openVideo(d['url'] as String? ??'')),
       onTap:()=>openVideo(d['url'] as String? ??''),
      ));
     }).toList());
    },
   ),
  ),
 );
}
