import 'dart:convert';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:crypto/crypto.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:audio_service/audio_service.dart';
import 'local_audio_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:image_picker/image_picker.dart';
import 'media_upload_service.dart';


class ExtraCommunityFeaturesPage extends StatelessWidget {
 const ExtraCommunityFeaturesPage({super.key});
 @override Widget build(BuildContext context)=>Directionality(textDirection:TextDirection.rtl,child:DefaultTabController(length:3,child:Scaffold(
  appBar:AppBar(title:const Text('مساحات المجتمع الإضافية'),bottom:const TabBar(tabs:[
   Tab(icon:Icon(Icons.lock),text:'الغرف الخاصة'),Tab(icon:Icon(Icons.apps),text:'مشاركة الملفات'),Tab(icon:Icon(Icons.music_note),text:'موسيقاي')
  ])),
  body:const TabBarView(children:[PrivateRoomsPage(),SharedFilesPage(),LocalMusicPage()])
 )));
}

class PrivateRoomsPage extends StatefulWidget {
 const PrivateRoomsPage({super.key});
 @override State<PrivateRoomsPage> createState()=>_PrivateRoomsPageState();
}
class _PrivateRoomsPageState extends State<PrivateRoomsPage> {
 final db=FirebaseFirestore.instance;
 String get uid=>FirebaseAuth.instance.currentUser!.uid;
 Future<void> createRoom() async {
  final name=TextEditingController(),code=TextEditingController();
  final selected=<String>{uid};
  final result=await showDialog<bool>(context:context,builder:(ctx)=>StatefulBuilder(builder:(ctx,setD)=>AlertDialog(
   title:const Text('إنشاء غرفة بالدعوة والرمز'),
   content:SizedBox(width:420,height:460,child:Column(children:[
    TextField(controller:name,decoration:const InputDecoration(labelText:'اسم الغرفة')),
    TextField(controller:code,obscureText:true,decoration:const InputDecoration(labelText:'رمز الدخول (4 أحرف على الأقل)')),
    const SizedBox(height:12),const Align(alignment:Alignment.centerRight,child:Text('اختر الأعضاء المدعوين')),
    Expanded(child:StreamBuilder<QuerySnapshot<Map<String,dynamic>>>(stream:db.collection('publicProfiles').limit(200).snapshots(),builder:(ctx,s){
     if(!s.hasData)return const Center(child:CircularProgressIndicator());
     return ListView(children:s.data!.docs.where((d)=>d.id!=uid).map((d){
      final n=d.data()['name'] as String? ?? 'عضو';
      return CheckboxListTile(dense:true,value:selected.contains(d.id),title:Text(n),onChanged:(v)=>setD(()=>v==true?selected.add(d.id):selected.remove(d.id)));
     }).toList());
    }))
   ])),
   actions:[TextButton(onPressed:()=>Navigator.pop(ctx,false),child:const Text('إلغاء')),FilledButton(onPressed:()=>Navigator.pop(ctx,true),child:const Text('إنشاء'))]
  )));
  if(result!=true)return;
  if(name.text.trim().length<3||code.text.trim().length<4||selected.length>30){
   if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('اكتب اسماً من 3 أحرف ورمزاً من 4 واختر حتى 30 عضواً')));
   return;
  }
  final salt=List<int>.generate(16,(_)=>Random.secure().nextInt(256));
  final saltHex=salt.map((b)=>b.toRadixString(16).padLeft(2,'0')).join();
  final hash=sha256.convert(utf8.encode(saltHex+'|'+code.text.trim())).toString();
  final room=await db.collection('privateRooms').add({
   'name':name.text.trim(),'ownerId':uid,'members':selected.toList(),'invitedUids':selected.toList(),
   'passcodeSalt':saltHex,'passcodeHash':hash,'createdAt':FieldValue.serverTimestamp(),'lastMessage':'الغرفة جاهزة'
  });
  await FirebaseFunctions.instance.httpsCallable('verifyPrivateRoomPasscode').call({'roomId':room.id,'passcode':code.text.trim()});
  name.dispose();code.dispose();
  if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('تم إنشاء الغرفة وإرسال الدعوات للأعضاء المحددين')));
 }
 @override Widget build(BuildContext context)=>Scaffold(
  floatingActionButton:FloatingActionButton.extended(onPressed:createRoom,icon:const Icon(Icons.add),label:const Text('غرفة جديدة')),
  body:StreamBuilder<QuerySnapshot<Map<String,dynamic>>>(stream:db.collection('privateRooms').where('members',arrayContains:uid).limit(100).snapshots(),builder:(context,s){
   if(s.hasError)return const Center(child:Text('تعذر تحميل الغرف. تأكد من نشر قواعد Firestore.'));
   if(!s.hasData)return const Center(child:CircularProgressIndicator());
   if(s.data!.docs.isEmpty)return const Center(child:Text('ما عندك غرف خاصة بعد. أنشئ غرفة وادعُ أصدقاءك.'));
   return ListView(children:s.data!.docs.map((d){
    final x=d.data();
    return Card(margin:const EdgeInsets.symmetric(horizontal:12,vertical:6),child:ListTile(
     leading:const CircleAvatar(child:Icon(Icons.lock_outline)),title:Text(x['name'] as String? ?? 'غرفة خاصة'),
     subtitle:Text('الأعضاء: '+((x['members'] as List? ?? []).length).toString()+' • '+(x['lastMessage'] ?? ''),maxLines:1,overflow:TextOverflow.ellipsis),
     trailing:const Icon(Icons.chevron_left),
     onTap:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>PrivateRoomChatPage(roomId:d.id,roomName:x['name'] as String? ?? 'غرفة خاصة',passcodeSalt:x['passcodeSalt'] as String? ?? '',passcodeHash:x['passcodeHash'] as String? ?? ''))),
    ));
   }).toList());
  })
 );
}

class PrivateRoomChatPage extends StatefulWidget {
 final String roomId,roomName,passcodeSalt,passcodeHash;
 const PrivateRoomChatPage({super.key,required this.roomId,required this.roomName,required this.passcodeSalt,required this.passcodeHash});
 @override State<PrivateRoomChatPage> createState()=>_PrivateRoomChatPageState();
}
class _PrivateRoomChatPageState extends State<PrivateRoomChatPage> {
 final db=FirebaseFirestore.instance;final text=TextEditingController();bool unlocked=false,busy=false;
 String get uid=>FirebaseAuth.instance.currentUser!.uid;
 Future<void> unlock() async {
  final code=TextEditingController();
  final ok=await showDialog<bool>(context:context,builder:(ctx)=>AlertDialog(title:const Text('رمز الغرفة'),content:TextField(controller:code,obscureText:true,decoration:const InputDecoration(hintText:'اكتب الرمز')),actions:[TextButton(onPressed:()=>Navigator.pop(ctx,false),child:const Text('رجوع')),FilledButton(onPressed:()=>Navigator.pop(ctx,true),child:const Text('دخول'))]));
  if(ok!=true)return;
  try{
   await FirebaseFunctions.instance.httpsCallable('verifyPrivateRoomPasscode').call({'roomId':widget.roomId,'passcode':code.text.trim()});
   if(mounted)setState(()=>unlocked=true);
  }catch(_){if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('الرمز غير صحيح أو أنك لست ضمن المدعوين')));}
  code.dispose();
 }
 Future<void> send() async {
  final value=text.text.trim();if(value.isEmpty||busy)return;setState(()=>busy=true);
  try{
   await db.collection('privateRooms').doc(widget.roomId).collection('messages').add({'senderId':uid,'text':value,'createdAt':FieldValue.serverTimestamp()});
   await db.collection('privateRooms').doc(widget.roomId).update({'lastMessage':value.length>200?value.substring(0,200):value,'updatedAt':FieldValue.serverTimestamp()});text.clear();
  }catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('تعذر الإرسال: '+e.toString())));}
  finally{if(mounted)setState(()=>busy=false);}
 }
 @override void dispose(){text.dispose();super.dispose();}
 @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:Text(widget.roomName)),body:!unlocked?Center(child:FilledButton.icon(onPressed:unlock,icon:const Icon(Icons.lock_open),label:const Text('إدخال رمز الغرفة'))):Column(children:[
  Expanded(child:StreamBuilder<QuerySnapshot<Map<String,dynamic>>>(stream:db.collection('privateRooms').doc(widget.roomId).collection('messages').orderBy('createdAt').limit(300).snapshots(),builder:(context,s){
   if(s.hasError)return const Center(child:Text('تعذر تحميل الرسائل'));if(!s.hasData)return const Center(child:CircularProgressIndicator());
   return ListView(padding:const EdgeInsets.all(12),children:s.data!.docs.map((d){final x=d.data();final mine=x['senderId']==uid;return Align(alignment:mine?Alignment.centerLeft:Alignment.centerRight,child:Container(margin:const EdgeInsets.symmetric(vertical:4),padding:const EdgeInsets.all(12),constraints:const BoxConstraints(maxWidth:320),decoration:BoxDecoration(color:mine?const Color(0xFFE8E2FF):Colors.white,borderRadius:BorderRadius.circular(14),border:Border.all(color:const Color(0xFFBBBBCC))),child:Text(x['text'] as String? ?? '',style:const TextStyle(fontSize:17,color:Color(0xFF171717),height:1.5))));}).toList());
  })),
  SafeArea(child:Padding(padding:const EdgeInsets.all(10),child:Row(children:[Expanded(child:TextField(controller:text,minLines:1,maxLines:4,decoration:const InputDecoration(hintText:'اكتب رسالة واضحة...',border:OutlineInputBorder()))),const SizedBox(width:8),IconButton.filled(onPressed:busy?null:send,icon:const Icon(Icons.send))])))
 ]));
}

class SharedFilesPage extends StatefulWidget {
 const SharedFilesPage({super.key});
 @override State<SharedFilesPage> createState()=>_SharedFilesPageState();
}
class _SharedFilesPageState extends State<SharedFilesPage> {
 final db=FirebaseFirestore.instance;bool uploading=false;
 String get uid=>FirebaseAuth.instance.currentUser!.uid;
 Future<void> review(String id,String status) async {
  await db.collection('sharedFiles').doc(id).update({'status':status,'reviewedBy':uid,'reviewedAt':FieldValue.serverTimestamp()});
 }
 Future<void> upload() async {
  final picked=await FilePicker.platform.pickFiles(type:FileType.any);
  if(picked==null||picked.files.isEmpty)return;final f=picked.files.first;
  if(f.path==null){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('تعذر قراءة مسار الملف من الجهاز')));return;}
  final ext=f.extension?.toLowerCase()??'';
  if(!['apk','zip','pdf','xapk'].contains(ext)){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('المسموح APK أو ZIP أو PDF أو XAPK فقط')));return;}
  if(f.size>100*1024*1024){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('الحد الأقصى 100 ميغابايت')));return;}
  setState(()=>uploading=true);
  try{
   final url=await uploadForumMedia(XFile(f.path!,name:f.name),folder:'shared-files');
   await db.collection('sharedFiles').add({'uploaderId':uid,'title':f.name,'fileName':f.name,'extension':ext,'size':f.size,'fileUrl':url,'status':'pending','createdAt':FieldValue.serverTimestamp(),'safetyNote':'بانتظار مراجعة المشرف'});
   if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('تم رفع الملف وهو بانتظار مراجعة المشرف')));
  }catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('فشل الرفع: '+e.toString())));}
  finally{if(mounted)setState(()=>uploading=false);}
 }
 @override Widget build(BuildContext context)=>Scaffold(
  floatingActionButton:FloatingActionButton.extended(onPressed:uploading?null:upload,icon:uploading?const SizedBox(width:18,height:18,child:CircularProgressIndicator(strokeWidth:2)):const Icon(Icons.upload_file),label:Text(uploading?'جاري الرفع':'مشاركة ملف')),
  body:Column(children:[
   const Padding(padding:EdgeInsets.all(12),child:Text('شارك التطبيقات والملفات التي تملك حق توزيعها. الملفات الجديدة لا تظهر للناس إلا بعد مراجعة المشرف. لا تثبّت ملفات APK من مصدر غير موثوق.',style:TextStyle(height:1.5))),
   if(FirebaseAuth.instance.currentUser?.email?.toLowerCase()=='husinalzerjaoe@gmail.com')
    SizedBox(height:180,child:StreamBuilder<QuerySnapshot<Map<String,dynamic>>>(stream:db.collection('sharedFiles').where('status',isEqualTo:'pending').limit(50).snapshots(),builder:(context,s){
     if(!s.hasData)return const Center(child:CircularProgressIndicator());
     return ListView(children:s.data!.docs.map((d){final x=d.data();return Card(child:ListTile(title:Text(x['title'] as String? ?? 'ملف'),subtitle:Text('مراجعة • '+(x['uploaderId']??'')),trailing:Wrap(children:[
      IconButton(tooltip:'قبول',icon:const Icon(Icons.check_circle,color:Colors.green),onPressed:()=>review(d.id,'approved')),
      IconButton(tooltip:'رفض',icon:const Icon(Icons.cancel,color:Colors.red),onPressed:()=>review(d.id,'rejected'))
     ])));}).toList());
    })),
   Expanded(child:StreamBuilder<QuerySnapshot<Map<String,dynamic>>>(stream:db.collection('sharedFiles').where('status',isEqualTo:'approved').limit(100).snapshots(),builder:(context,s){
    if(s.hasError)return const Center(child:Text('تعذر تحميل الملفات'));if(!s.hasData)return const Center(child:CircularProgressIndicator());
    if(s.data!.docs.isEmpty)return const Center(child:Text('ماكو ملفات منشورة حالياً'));
    return ListView(children:s.data!.docs.map((d){final x=d.data();return Card(child:ListTile(leading:const Icon(Icons.insert_drive_file),title:Text(x['title'] as String? ?? 'ملف'),subtitle:Text((x['extension']??'').toString()+' • '+(x['size']??0).toString()+' بايت'),trailing:IconButton(icon:const Icon(Icons.download),onPressed:()=>launchUrl(Uri.parse(x['fileUrl'] as String),mode:LaunchMode.externalApplication))));}).toList());
   }))
  ])
 );
}

class LocalMusicPage extends StatefulWidget {
 const LocalMusicPage({super.key});
 @override State<LocalMusicPage> createState()=>_LocalMusicPageState();
}
class _LocalMusicPageState extends State<LocalMusicPage> {
 final tracks=<PlatformFile>[];int current=-1;bool loading=false;
 Future<void> addTracks() async {
  final result=await FilePicker.platform.pickFiles(type:FileType.audio,allowMultiple:true);
  if(result==null)return;setState(()=>tracks.addAll(result.files.where((f)=>f.path!=null)));
 }
 Future<void> play(int index) async {
  if(index<0||index>=tracks.length)return;setState(()=>loading=true);
  try{await appAudioHandler.loadLocalQueue(tracks.map((f)=>MediaItem(id:f.path!,title:f.name,album:'مكتبتي المحلية')).toList());await appAudioHandler.skipToQueueItem(index);await appAudioHandler.play();setState(()=>current=index);}
  catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('تعذر تشغيل الملف: '+e.toString())));}
  finally{if(mounted)setState(()=>loading=false);}
 }

 @override Widget build(BuildContext context)=>Scaffold(
  floatingActionButton:FloatingActionButton.extended(onPressed:addTracks,icon:const Icon(Icons.library_music),label:const Text('إضافة أغاني من جهازي')),
  body:Column(children:[
   Padding(padding:const EdgeInsets.all(12),child:StreamBuilder<PlaybackState>(stream:appAudioHandler.playbackState,builder:(context,s){final playing=s.data?.playing??false;return Card(child:ListTile(leading:const Icon(Icons.music_note,size:34),title:Text(current>=0?tracks[current].name:'مشغل الموسيقى المحلي'),subtitle:Text(loading?'جاري التحميل':playing?'يعمل الآن':'اختر أغنية من قائمتك'),trailing:IconButton(onPressed:current<0?null:()=>playing?appAudioHandler.pause():appAudioHandler.play(),icon:Icon(playing?Icons.pause_circle:Icons.play_circle))));})),
   Expanded(child:tracks.isEmpty?const Center(child:Text('أضف ملفات MP3 أو صوتية من جهازك')):ListView.builder(itemCount:tracks.length,itemBuilder:(context,i)=>ListTile(leading:Icon(current==i?Icons.equalizer:Icons.audiotrack),title:Text(tracks[i].name),onTap:()=>play(i),trailing:IconButton(icon:const Icon(Icons.close),onPressed:() async {setState(()=>tracks.removeAt(i));if(tracks.isEmpty){await appAudioHandler.stop();current=-1;}})))),
   const Padding(padding:EdgeInsets.all(12),child:Text('الموسيقى محلية ولا تُرفع إلى الخادم. التشغيل بالخلفية يعتمد على استمرار التطبيق ونظام Android وإعدادات توفير الطاقة.',style:TextStyle(fontSize:12)))
  ])
 );
}
