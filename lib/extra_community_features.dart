import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:audio_service/audio_service.dart';
import 'local_audio_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:image_picker/image_picker.dart';
import 'package:record/record.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'media_upload_service.dart';
import 'download_service.dart';


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
 Future<void> manageRoom(String roomId, Map<String,dynamic> room) async {
   final owner=room['ownerId']==uid;
   final admins=List<String>.from(room['roomAdmins']??[]);
   if(!owner&&!admins.contains(uid))return;
   final members=List<String>.from(room['members']??[]);
   final profiles=await db.collection('publicProfiles').get();
   if(!mounted)return;
   await showDialog<void>(context:context,builder:(ctx)=>AlertDialog(
    title:Text('إدارة الأعضاء • '+(room['name']??'الغرفة')),
    content:SizedBox(width:420,height:420,child:ListView(children:members.map((id){
     final matches=profiles.docs.where((p)=>p.id==id).toList();
     final data=matches.isEmpty?<String,dynamic>{}:matches.first.data();
     final isOwner=id==room['ownerId'], isAdmin=admins.contains(id);
     return ListTile(title:Text(data['name']??'عضو'),subtitle:Text(isOwner?'مالك الغرفة':isAdmin?'مشرف غرفة':'عضو'),
      trailing:isOwner?const Icon(Icons.workspace_premium):PopupMenuButton<String>(
       onSelected:(action)async{try{
        final ref=db.collection('privateRooms').doc(roomId);
        if(action=='promote')await ref.update({'roomAdmins':FieldValue.arrayUnion([id])});
        if(action=='demote')await ref.update({'roomAdmins':FieldValue.arrayRemove([id])});
        if(action=='kick')await ref.update({'members':FieldValue.arrayRemove([id]),'invitedUids':FieldValue.arrayRemove([id]),'roomAdmins':FieldValue.arrayRemove([id])});
        if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('تم تحديث صلاحيات العضو')));
       }catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('تعذر تنفيذ العملية: '+e.toString())));}},
       itemBuilder:(_)=>[if(owner&&!isAdmin)const PopupMenuItem(value:'promote',child:Text('ترقية إلى مشرف')),if(owner&&isAdmin)const PopupMenuItem(value:'demote',child:Text('تنزيل من الإشراف')),if(owner)const PopupMenuItem(value:'kick',child:Text('طرد من الغرفة'))],
      ));
    }).toList())),
    actions:[TextButton(onPressed:()=>Navigator.pop(ctx),child:const Text('إغلاق'))],
   ));
  }
  Future<void> createRoom() async {
  final name=TextEditingController();
  final meetUrl=TextEditingController();
  final selected=<String>{uid};
  String roomType='text';
  final result=await showDialog<bool>(context:context,builder:(ctx)=>StatefulBuilder(builder:(ctx,setD)=>AlertDialog(
   title:const Text('إنشاء غرفة خاصة'),
   content:SizedBox(width:420,height:500,child:Column(children:[
    TextField(controller:name,decoration:const InputDecoration(labelText:'اسم الغرفة')),
    const SizedBox(height:12),
    const Align(alignment:Alignment.centerRight,child:Text('نوع الغرفة')),
    Wrap(spacing:8,children:[
     ChoiceChip(label:const Text('محادثة كتابية'),selected:roomType=='text',onSelected:(_)=>setD(()=>roomType='text')),
     ChoiceChip(label:const Text('غرفة صوتية'),selected:roomType=='voice',onSelected:(_)=>setD(()=>roomType='voice')),
    ]),
    if(roomType=='voice')...[
     TextField(controller:meetUrl,keyboardType:TextInputType.url,decoration:const InputDecoration(labelText:'رابط Google Meet',hintText:'https://meet.google.com/...')),
     const Align(alignment:Alignment.centerRight,child:Text('أنشئ رابط الاجتماع في Google Meet ثم الصقه هنا',style:TextStyle(fontSize:11,color:Colors.grey))),
    ],
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
  if(result!=true){name.dispose();meetUrl.dispose();return;}
  final parsed=Uri.tryParse(meetUrl.text.trim());
  final validMeet=parsed!=null&&parsed.scheme=='https'&&parsed.host=='meet.google.com';
  if(name.text.trim().length<3||selected.length>30||(roomType=='voice'&&!validMeet)){
   if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(roomType=='voice'&&!validMeet?'أدخل رابط Google Meet صحيحاً يبدأ بـ https://meet.google.com/':'اكتب اسماً من 3 أحرف واختر حتى 30 عضواً')));
   name.dispose();meetUrl.dispose();return;
  }
  try{
   await db.collection('privateRooms').add({
    'name':name.text.trim(),'ownerId':uid,'roomAdmins':<String>[],'members':selected.toList(),'invitedUids':selected.toList(),
    'roomType':roomType,'meetUrl':roomType=='voice'?meetUrl.text.trim():'',
    'createdAt':FieldValue.serverTimestamp(),'lastMessage':roomType=='voice'?'غرفة صوتية خاصة جاهزة':'الغرفة جاهزة'
   });
   if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(roomType=='voice'?'تم إنشاء الغرفة الصوتية الخاصة بالدعوات':'تم إنشاء الغرفة الخاصة وإرسال الدعوات')));
  }catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('تعذر إنشاء الغرفة: $e')));}
  name.dispose();meetUrl.dispose();
 }
 @override Widget build(BuildContext context)=>Scaffold(
  floatingActionButton:FloatingActionButton.extended(onPressed:createRoom,icon:const Icon(Icons.add),label:const Text('غرفة جديدة')),
  body:StreamBuilder<QuerySnapshot<Map<String,dynamic>>>(stream:db.collection('privateRooms').where('members',arrayContains:uid).limit(100).snapshots(),builder:(context,s){
   if(s.hasError)return const Center(child:Text('تعذر تحميل الغرف. تأكد من نشر قواعد Firestore.'));
   if(!s.hasData)return const Center(child:CircularProgressIndicator());
   if(s.data!.docs.isEmpty)return const Center(child:Text('ما عندك غرف خاصة بعد. أنشئ غرفة وادعُ أصدقاءك.'));
   return ListView(children:s.data!.docs.map((d){
    final x=d.data();
    final voice=x['roomType']=='voice';
    final meet=(x['meetUrl'] as String? ?? '').trim();
    return Card(margin:const EdgeInsets.symmetric(horizontal:12,vertical:6),child:ListTile(
     leading:CircleAvatar(child:Icon(voice?Icons.mic:Icons.lock_outline)),
     title:Text(x['name'] as String? ?? 'غرفة خاصة'),
     subtitle:Text((voice?'غرفة صوتية • ':'محادثة كتابية • ')+'الأعضاء: '+((x['members'] as List? ?? []).length).toString()+' • '+(x['lastMessage'] ?? ''),maxLines:1,overflow:TextOverflow.ellipsis),
     trailing:Row(mainAxisSize:MainAxisSize.min,children:[
       if(x['ownerId']==uid||List<String>.from(x['roomAdmins']??[]).contains(uid))
        IconButton(tooltip:'إدارة الأعضاء',icon:const Icon(Icons.groups_2_outlined),onPressed:()=>manageRoom(d.id,x)),
       if(voice)IconButton(tooltip:'انضم للمكالمة الصوتية',icon:const Icon(Icons.call,color:Colors.green),onPressed:meet.isEmpty?null:()=>launchUrl(Uri.parse(meet),mode:LaunchMode.externalApplication))
       else const Icon(Icons.chevron_left),
      ]),
     onTap:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>PrivateRoomChatPage(roomId:d.id,roomName:x['name'] as String? ?? 'غرفة خاصة'))),
    ));
   }).toList());
  })
 );
}

class PrivateRoomChatPage extends StatefulWidget {
 final String roomId,roomName;
 const PrivateRoomChatPage({super.key,required this.roomId,required this.roomName});
 @override State<PrivateRoomChatPage> createState()=>_PrivateRoomChatPageState();
}
class _PrivateRoomChatPageState extends State<PrivateRoomChatPage> {
 final db=FirebaseFirestore.instance;final text=TextEditingController();final recorder=AudioRecorder();bool busy=false;bool recordingVoice=false;DateTime? voiceStartedAt;
 int _background=0xFFF5F3FF;
 static const _roomBackgrounds=[0xFFF5F3FF,0xFFEAF6FF,0xFFFFF3E8,0xFFF0F7F1,0xFF171936,0xFFFFF0F5,0xFFEDE7F6,0xFFE0F2F1,0xFFFFF8E1,0xFFE3F2FD,0xFF263238,0xFFFCE4EC];
 String get uid=>FirebaseAuth.instance.currentUser!.uid;
 Future<void> send({String? imageUrl,String? audioUrl,int? durationSeconds}) async {
   final value=text.text.trim();if((value.isEmpty&&imageUrl==null&&audioUrl==null)||busy)return;setState(()=>busy=true);
   try{
    final type=audioUrl!=null?'voice':imageUrl!=null?'image':'text';
    await db.collection('privateRooms').doc(widget.roomId).collection('messages').add({
     'senderId':uid,'text':value,'type':type,
     if(imageUrl!=null)'imageUrl':imageUrl,
     if(audioUrl!=null)'audioUrl':audioUrl,
     if(durationSeconds!=null)'durationSeconds':durationSeconds,
     'createdAt':FieldValue.serverTimestamp()
    });
    final last=audioUrl!=null?'🎙️ رسالة صوتية':imageUrl!=null?'📷 صورة':value;
    await db.collection('privateRooms').doc(widget.roomId).update({'lastMessage':last.length>200?last.substring(0,200):last,'updatedAt':FieldValue.serverTimestamp()});
    text.clear();
   }catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('تعذر الإرسال: '+e.toString())));}
   finally{if(mounted)setState(()=>busy=false);}
  }
  Future<void> sendImage() async {
   final picked=await ImagePicker().pickImage(source:ImageSource.gallery,imageQuality:85,maxWidth:1600);
   if(picked==null||!mounted)return;
   setState(()=>busy=true);
   try{final url=await uploadForumMedia(picked,folder:'private-chat');if(mounted)setState(()=>busy=false);await send(imageUrl:url);}
   catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('تعذر رفع الصورة: '+e.toString())));}
   finally{if(mounted)setState(()=>busy=false);}
  }
  Future<void> toggleVoice() async {
   if(busy)return;
   if(!recordingVoice){
    try{
     if(!await recorder.hasPermission()){if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('اسمح للتطبيق باستخدام المايكروفون أولاً.')));return;}
     final dir=await getTemporaryDirectory();
     final path=dir.path+'/private_room_voice_'+DateTime.now().microsecondsSinceEpoch.toString()+'.m4a';
     await recorder.start(const RecordConfig(encoder:AudioEncoder.aacLc,bitRate:64000,sampleRate:44100),path:path);
     if(mounted)setState(() { recordingVoice=true; voiceStartedAt=DateTime.now(); });
    }catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('تعذر بدء التسجيل: '+e.toString())));}
    return;
   }
   try{
    final started=voiceStartedAt;final path=await recorder.stop();
    if(mounted)setState(() { recordingVoice=false; voiceStartedAt=null; });
    if(path==null||started==null)return;
    final seconds=DateTime.now().difference(started).inSeconds.clamp(1,180).toInt();
    if(mounted)setState(()=>busy=true);
    final url=await uploadForumMedia(XFile(path,name:'private_room_voice.m4a'),folder:'private-chat');
    if(mounted)setState(()=>busy=false);
    await send(audioUrl:url,durationSeconds:seconds);
   }catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('تعذر إرسال الفويس: '+e.toString())));}
   finally{if(mounted)setState(() { busy=false; recordingVoice=false; voiceStartedAt=null; });}
  }
 @override void dispose(){text.dispose();recorder.dispose();super.dispose();}
 @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:Text(widget.roomName),actions:[
  IconButton(tooltip:'خلفية المحادثة',icon:const Icon(Icons.palette_outlined),onPressed:()=>showModalBottomSheet<void>(context:context,builder:(c)=>Wrap(children:_roomBackgrounds.map((v)=>ListTile(leading:CircleAvatar(backgroundColor:Color(v)),title:const Text('اختيار هذه الخلفية'),onTap:(){Navigator.pop(c);setState(()=>_background=v);})).toList())))
 ]),body:Column(children:[
  Expanded(child:Container(color:Color(_background),child:StreamBuilder<QuerySnapshot<Map<String,dynamic>>>(stream:db.collection('privateRooms').doc(widget.roomId).collection('messages').orderBy('createdAt').limit(300).snapshots(),builder:(context,s){
   if(s.hasError)return const Center(child:Text('تعذر تحميل الرسائل'));if(!s.hasData)return const Center(child:CircularProgressIndicator());
   return ListView(padding:const EdgeInsets.all(12),children:s.data!.docs.map((d){final x=d.data();final mine=x['senderId']==uid;return Align(alignment:mine?Alignment.centerLeft:Alignment.centerRight,child:Container(margin:const EdgeInsets.symmetric(vertical:4),padding:const EdgeInsets.all(12),constraints:const BoxConstraints(maxWidth:320),decoration:BoxDecoration(color:mine?const Color(0xFFE8E2FF):Colors.white,borderRadius:BorderRadius.circular(14),border:Border.all(color:const Color(0xFFBBBBCC))),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[if(x['type']=='image'&&x['imageUrl'] is String)ClipRRect(borderRadius:BorderRadius.circular(10),child:Image.network(x['imageUrl'] as String,width:220,fit:BoxFit.cover)),if(x['type']=='voice'&&x['audioUrl'] is String)_PrivateRoomVoicePlayer(url:x['audioUrl'] as String,durationSeconds:(x['durationSeconds'] as num?)?.toInt()??0),if((x['text'] as String? ?? '').isNotEmpty)Text(x['text'] as String,style:const TextStyle(fontSize:17,color:Color(0xFF171717),height:1.5))])));}).toList());
  }))),
  SafeArea(child:Padding(padding:const EdgeInsets.all(10),child:Row(children:[IconButton(onPressed:busy?null:sendImage,icon:const Icon(Icons.image_outlined)),IconButton(onPressed:busy?null:toggleVoice,tooltip:recordingVoice?'إيقاف وإرسال الفويس':'تسجيل فويس',icon:Icon(recordingVoice?Icons.stop_circle:Icons.mic,color:recordingVoice?Colors.red:Colors.deepPurple)),Expanded(child:TextField(controller:text,minLines:1,maxLines:4,decoration:InputDecoration(hintText:recordingVoice?'جاري تسجيل الفويس...':'اكتب رسالة واضحة...',border:const OutlineInputBorder()))),const SizedBox(width:8),IconButton.filled(onPressed:busy?null:()=>send(),icon:const Icon(Icons.send))])))
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
 Future<PlatformFile?> _resolvePickedFile(PlatformFile file) async {
  if(file.path!=null)return file;
  final bytes=file.bytes;
  if(bytes==null||bytes.isEmpty)return null;
  final dir=await getTemporaryDirectory();
  final folder=Directory(dir.path+'/future_youth_files');
  await folder.create(recursive:true);
  final safeName=file.name.replaceAll(RegExp(r'[^A-Za-z0-9._-]'),'_');
  final path=folder.path+'/'+DateTime.now().microsecondsSinceEpoch.toString()+'_'+safeName;
  await File(path).writeAsBytes(bytes,flush:true);
  return PlatformFile(name:file.name,size:file.size,path:path);
 }
 Future<void> downloadFile(String url,String name) async {
  try{await ForumDownloadService.download(url,name);if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('بدأ التنزيل. تابع إشعارات الهاتف ومجلد Downloads.')));}
  catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('تعذر تنزيل الملف: $e')));}
 }
 Future<void> upload() async {
  final picked=await FilePicker.platform.pickFiles(type:FileType.any,withData:true);
  if(picked==null||picked.files.isEmpty)return;
  final f=await _resolvePickedFile(picked.files.first);
  if(f==null){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('تعذر قراءة الملف من الجهاز')));return;}
  final ext=f.extension?.toLowerCase()??'';
  if(!['apk','zip','pdf','xapk','mp3','m4a','aac','wav','ogg','flac'].contains(ext)){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('المسموح APK أو ZIP أو PDF أو XAPK أو صوت MP3/M4A/AAC/WAV/OGG/FLAC')));return;}
  if(f.size>100*1024*1024){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('الحد الأقصى 100 ميغابايت')));return;}
  setState(()=>uploading=true);
  try{
   final url=await uploadForumMedia(XFile(f.path!,name:f.name),folder:'shared-files');
   await db.collection('sharedFiles').add({'uploaderId':uid,'title':f.name,'fileName':f.name,'extension':ext,'size':f.size,'fileUrl':url,'status':'pending','createdAt':FieldValue.serverTimestamp(),'safetyNote':'بانتظار مراجعة المشرف. ارفع فقط ملفات تملك حق توزيعها.'});
   if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('تم رفع الملف وهو بانتظار مراجعة المشرف')));
  }catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('فشل الرفع: '+e.toString())));}
  finally{if(mounted)setState(()=>uploading=false);}
 }
 @override Widget build(BuildContext context)=>Scaffold(
  floatingActionButton:FloatingActionButton.extended(onPressed:uploading?null:upload,icon:uploading?const SizedBox(width:18,height:18,child:CircularProgressIndicator(strokeWidth:2)):const Icon(Icons.upload_file),label:Text(uploading?'جاري الرفع':'مشاركة ملف')),
  body:Column(children:[
   const Padding(padding:EdgeInsets.all(12),child:Text('شارك التطبيقات والملفات والمقاطع الصوتية التي تملك حق توزيعها. الملفات الجديدة لا تظهر للناس إلا بعد مراجعة المشرف. لا تثبّت ملفات APK من مصدر غير موثوق.',style:TextStyle(height:1.5))),
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
    return ListView(children:s.data!.docs.map((d){final x=d.data();return Card(child:ListTile(leading:const Icon(Icons.insert_drive_file),title:Text(x['title'] as String? ?? 'ملف'),subtitle:Text((x['extension']??'').toString()+' • '+(x['size']??0).toString()+' بايت'),trailing:IconButton(tooltip:'تنزيل إلى مجلد Downloads',icon:const Icon(Icons.download_for_offline),onPressed:()=>downloadFile(x['fileUrl'] as String,x['fileName'] as String? ?? x['title'] as String? ?? 'forum-file'))));}).toList());
   }))
  ])
 );
}

class LocalMusicPage extends StatefulWidget {
 const LocalMusicPage({super.key});
 @override State<LocalMusicPage> createState()=>_LocalMusicPageState();
}
class _LocalMusicPageState extends State<LocalMusicPage> {
 final tracks=<PlatformFile>[];
 int current=-1;
 bool loading=false,uploading=false;
 final db=FirebaseFirestore.instance;
 String get uid=>FirebaseAuth.instance.currentUser!.uid;
 Future<PlatformFile?> _resolveAudioFile(PlatformFile file) async {
  if(file.path!=null)return file;
  final bytes=file.bytes;
  if(bytes==null||bytes.isEmpty)return null;
  final dir=await getTemporaryDirectory();
  final folder=Directory(dir.path+'/future_youth_audio');
  await folder.create(recursive:true);
  final safeName=file.name.replaceAll(RegExp(r'[^A-Za-z0-9._-]'),'_');
  final path=folder.path+'/'+DateTime.now().microsecondsSinceEpoch.toString()+'_'+safeName;
  await File(path).writeAsBytes(bytes,flush:true);
  return PlatformFile(name:file.name,size:file.size,path:path);
 }
 Future<void> addTracks() async {
  final result=await FilePicker.platform.pickFiles(type:FileType.audio,allowMultiple:true,withData:true);
  if(result==null)return;
  final resolved=<PlatformFile>[];
  for(final file in result.files){
   final ext=(file.extension??'').toLowerCase();
   if(!['mp3','m4a','aac','wav','ogg','flac'].contains(ext))continue;
   final local=await _resolveAudioFile(file);
   if(local!=null)resolved.add(local);
  }
  if(!mounted)return;
  if(resolved.isEmpty){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('ما قدرنا نقرأ ملفات صوت مدعومة من الجهاز')));return;}
  setState(()=>tracks.addAll(resolved));
 }
 Future<void> uploadTracks() async {
  final result=await FilePicker.platform.pickFiles(type:FileType.audio,allowMultiple:true,withData:true);
  if(result==null||result.files.isEmpty)return;
  final chosen=<PlatformFile>[];
  for(final file in result.files){
   final ext=(file.extension??'').toLowerCase();
   if(!['mp3','m4a','aac','wav','ogg','flac'].contains(ext))continue;
   final local=await _resolveAudioFile(file);
   if(local!=null)chosen.add(local);
  }
  if(chosen.isEmpty){if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('تعذر قراءة ملفات الصوت من الجهاز')));return;}
  if(chosen.any((f)=>f.size>100*1024*1024)){if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('حجم الأغنية يتجاوز 100 ميغابايت')));return;}
  setState(()=>uploading=true);
  var success=0;
  try{
   for(final f in chosen){
    final ext=(f.extension??'').toLowerCase();
    if(!['mp3','m4a','aac','wav','ogg','flac'].contains(ext))continue;
    final url=await uploadForumMedia(XFile(f.path!,name:f.name),folder:'shared-files');
    await db.collection('sharedFiles').add({
     'uploaderId':uid,'title':f.name,'fileName':f.name,'extension':ext,
     'size':f.size,'fileUrl':url,'status':'approved','category':'music',
     'createdAt':FieldValue.serverTimestamp(),
     'safetyNote':'نشر مباشر دون مراجعة إدارية. ارفع فقط الملفات التي تملك حق مشاركتها.'
    });
    success++;
   }
   if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('تم نشر '+success.toString()+' أغنية مباشرة في مكتبة المجتمع')));
  }catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('تعذر رفع الأغاني: '+e.toString())));}
  finally{if(mounted)setState(()=>uploading=false);}
 }
 Future<void> play(int index) async {
  if(index<0||index>=tracks.length)return;
  setState(()=>loading=true);
  try{
   await appAudioHandler.loadLocalQueue(tracks.map((f)=>MediaItem(id:f.path!,title:f.name,album:'مكتبتي المحلية')).toList(),initialIndex:index);
   await appAudioHandler.play();
   if(mounted)setState(()=>current=index);
  }catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('تعذر تشغيل الملف: '+e.toString())));}
  finally{if(mounted)setState(()=>loading=false);}
 }
 Future<void> playShared(String url,String title) async {
  setState(()=>loading=true);
  try{await appAudioHandler.loadRemoteTrack(url,title);}
  catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('تعذر تشغيل الأغنية: '+e.toString())));}
  finally{if(mounted)setState(()=>loading=false);}
 }
 @override Widget build(BuildContext context)=>Scaffold(
  floatingActionButton:Column(mainAxisSize:MainAxisSize.min,crossAxisAlignment:CrossAxisAlignment.end,children:[
   FloatingActionButton.extended(heroTag:'upload_shared_music',onPressed:uploading?null:uploadTracks,icon:uploading?const SizedBox(width:18,height:18,child:CircularProgressIndicator(strokeWidth:2)):const Icon(Icons.cloud_upload),label:Text(uploading?'جاري الرفع':'رفع أغنية للمجتمع')),
   const SizedBox(height:10),
   FloatingActionButton.extended(heroTag:'add_local_music',onPressed:addTracks,icon:const Icon(Icons.library_music),label:const Text('أغاني من جهازي')),
  ]),
  body:Column(children:[
   Padding(padding:const EdgeInsets.all(12),child:StreamBuilder<PlaybackState>(stream:appAudioHandler.playbackState,builder:(context,s){
    final playing=s.data?.playing??false;
    return Card(child:ListTile(leading:const Icon(Icons.music_note,size:34),title:StreamBuilder<MediaItem?>(stream:appAudioHandler.mediaItem,builder:(context,m)=>Text(m.data?.title??(current>=0?tracks[current].name:'مشغل الموسيقى'),maxLines:1,overflow:TextOverflow.ellipsis)),subtitle:Text(loading?'جاري التحميل':playing?'يعمل الآن':'اختر أغنية للتشغيل'),trailing:IconButton(onPressed:playing?appAudioHandler.pause:appAudioHandler.play,icon:Icon(playing?Icons.pause_circle:Icons.play_circle))));
   })),
   const Padding(padding:EdgeInsets.fromLTRB(12,4,12,4),child:Align(alignment:Alignment.centerRight,child:Text('موسيقى المجتمع • نشر مباشر دون موافقة الإدارة'))),
   // Pending tracks remain visible to their uploader; the founder can review them here.
   StreamBuilder<QuerySnapshot<Map<String,dynamic>>>(
    stream: FirebaseAuth.instance.currentUser?.email?.toLowerCase()=='husinalzerjaoe@gmail.com'
      ? db.collection('sharedFiles').where('status',isEqualTo:'pending').limit(100).snapshots()
      : db.collection('sharedFiles').where('uploaderId',isEqualTo:uid).limit(100).snapshots(),
    builder:(context,pendingSnapshot){
     if(pendingSnapshot.hasError)return const SizedBox.shrink();
     if(!pendingSnapshot.hasData)return const SizedBox.shrink();
     final pendingDocs=pendingSnapshot.data!.docs.where((d){
      final x=d.data();
      final audio=['mp3','m4a','aac','wav','ogg','flac'].contains((x['extension']??'').toString().toLowerCase());
      return audio && x['status']=='pending' &&
        (FirebaseAuth.instance.currentUser?.email?.toLowerCase()=='husinalzerjaoe@gmail.com' || x['uploaderId']==uid);
     }).toList();
     if(pendingDocs.isEmpty)return const SizedBox.shrink();
     return Card(child:Padding(padding:const EdgeInsets.all(10),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      const Text('أغانٍ بانتظار الموافقة',style:TextStyle(fontWeight:FontWeight.bold)),
      ...pendingDocs.map((d){
       final x=d.data();
       final founder=FirebaseAuth.instance.currentUser?.email?.toLowerCase()=='husinalzerjaoe@gmail.com';
       return ListTile(
        dense:true,
        onTap:()=>playShared((x['fileUrl']??'').toString(),x['title'] as String? ?? 'ملف صوتي'),
        leading:const Icon(Icons.hourglass_top,color:Colors.orange),
        title:Text(x['title'] as String? ?? 'ملف صوتي',maxLines:1,overflow:TextOverflow.ellipsis),
        subtitle:Text(founder?'بانتظار مراجعتك':'بانتظار موافقة الإدارة'),
        trailing:founder?Wrap(children:[
         IconButton(tooltip:'قبول ونشر',icon:const Icon(Icons.check_circle,color:Colors.green),onPressed:()async{
          try{await d.reference.update({'status':'approved','reviewedBy':uid,'reviewedAt':FieldValue.serverTimestamp()});}
          catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('تعذر اعتماد الأغنية: $e')));}
         }),
         IconButton(tooltip:'رفض',icon:const Icon(Icons.cancel,color:Colors.red),onPressed:()async{
          try{await d.reference.update({'status':'rejected','reviewedBy':uid,'reviewedAt':FieldValue.serverTimestamp()});}
          catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('تعذر رفض الأغنية: $e')));}
         }),
        ]):const Icon(Icons.schedule,color:Colors.orange),
       );
      }),
     ])));
    },
   ),
   Expanded(child:StreamBuilder<QuerySnapshot<Map<String,dynamic>>>(stream:db.collection('sharedFiles').where('status',isEqualTo:'approved').limit(150).snapshots(),builder:(context,s){
    if(s.hasError)return const Center(child:Text('تعذر تحميل الأغاني المنشورة'));
    if(!s.hasData)return const Center(child:CircularProgressIndicator());
    final docs=s.data!.docs.where((d)=>['mp3','m4a','aac','wav','ogg','flac'].contains((d.data()['extension']??'').toString().toLowerCase())).toList();
    return ListView(children:[
     if(docs.isEmpty)const ListTile(title:Text('ماكو أغاني منشورة بعد'),subtitle:Text('ارفع أول أغنية وشاركها مع أعضاء الملتقى')),
     ...docs.map((d){final x=d.data();return Card(child:ListTile(
      leading:const CircleAvatar(child:Icon(Icons.audiotrack)),
      title:Text(x['title'] as String? ?? 'مقطع صوتي',maxLines:1,overflow:TextOverflow.ellipsis),
      subtitle:Text('من مكتبة المجتمع • '+(x['size']??0).toString()+' بايت'),
      trailing:IconButton(tooltip:'تشغيل',icon:const Icon(Icons.play_circle_fill),onPressed:()=>playShared(x['fileUrl'] as String,x['title'] as String? ?? 'مقطع صوتي'))
     ));})
    ]);
   })),
   const Divider(height:1),
   const Padding(padding:EdgeInsets.all(10),child:Align(alignment:Alignment.centerRight,child:Text('مكتبتي من الجهاز'))),
   SizedBox(height:tracks.isEmpty?64:160,child:tracks.isEmpty?const Center(child:Text('ما أضفت أغاني محلية بعد')):ListView.builder(itemCount:tracks.length,itemBuilder:(context,i)=>ListTile(leading:Icon(current==i?Icons.equalizer:Icons.audiotrack),title:Text(tracks[i].name,maxLines:1,overflow:TextOverflow.ellipsis),onTap:()=>play(i),trailing:IconButton(icon:const Icon(Icons.close),onPressed:() async {setState(()=>tracks.removeAt(i));if(tracks.isEmpty){await appAudioHandler.stop();current=-1;}})))),
   const Padding(padding:EdgeInsets.all(10),child:Text('التشغيل بالخلفية يستخدم مشغل Android. النشر المباشر مخصص للملفات التي تملك حق مشاركتها.',style:TextStyle(fontSize:12)))
  ])
 );
}


class _PrivateRoomVoicePlayer extends StatefulWidget {
 final String url;final int durationSeconds;
 const _PrivateRoomVoicePlayer({required this.url,required this.durationSeconds});
 @override State<_PrivateRoomVoicePlayer> createState()=>_PrivateRoomVoicePlayerState();
}
class _PrivateRoomVoicePlayerState extends State<_PrivateRoomVoicePlayer>{
 late final AudioPlayer player;
 @override void initState(){super.initState();player=AudioPlayer();player.setUrl(widget.url).catchError((Object _) => Duration.zero);}
 @override void dispose(){player.dispose();super.dispose();}
 @override Widget build(BuildContext context)=>SizedBox(width:220,child:Row(children:[
  StreamBuilder<PlayerState>(stream:player.playerStateStream,builder:(c,s){final playing=s.data?.playing??false;return IconButton(onPressed:()async{if(playing){await player.pause();}else{await player.play();}},icon:Icon(playing?Icons.pause_circle:Icons.play_circle,color:Colors.deepPurple,size:30));}),
  Expanded(child:StreamBuilder<Duration?>(stream:player.durationStream,builder:(c,d){final total=d.data??Duration(seconds:widget.durationSeconds);return StreamBuilder<Duration>(stream:player.positionStream,builder:(c,pos){final now=pos.data??Duration.zero,max=total.inMilliseconds;return Column(mainAxisSize:MainAxisSize.min,children:[Slider(value:max<=0?0:now.inMilliseconds.clamp(0,max).toDouble(),max:max<=0?1:max.toDouble(),onChanged:max<=0?null:(v)=>player.seek(Duration(milliseconds:v.round()))),Text(now.inSeconds.toString()+'s / '+total.inSeconds.toString()+'s',style:const TextStyle(fontSize:10))]);});})),
 ]));
}
