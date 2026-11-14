import 'package:cloud_firestore/cloud_firestore.dart';
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
 final db=FirebaseFirestore.instance;final text=TextEditingController();bool busy=false;
 int _background=0xFFF5F3FF;
 static const _roomBackgrounds=[0xFFF5F3FF,0xFFEAF6FF,0xFFFFF3E8,0xFFF0F7F1,0xFF171936,0xFFFFF0F5,0xFFEDE7F6,0xFFE0F2F1,0xFFFFF8E1,0xFFE3F2FD,0xFF263238,0xFFFCE4EC];
 String get uid=>FirebaseAuth.instance.currentUser!.uid;
 Future<void> send() async {
  final value=text.text.trim();if(value.isEmpty||busy)return;setState(()=>busy=true);
  try{
   await db.collection('privateRooms').doc(widget.roomId).collection('messages').add({'senderId':uid,'text':value,'createdAt':FieldValue.serverTimestamp()});
   await db.collection('privateRooms').doc(widget.roomId).update({'lastMessage':value.length>200?value.substring(0,200):value,'updatedAt':FieldValue.serverTimestamp()});text.clear();
  }catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('تعذر الإرسال: '+e.toString())));}
  finally{if(mounted)setState(()=>busy=false);}
 }
 @override void dispose(){text.dispose();super.dispose();}
 @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:Text(widget.roomName),actions:[
  IconButton(tooltip:'خلفية المحادثة',icon:const Icon(Icons.palette_outlined),onPressed:()=>showModalBottomSheet<void>(context:context,builder:(c)=>Wrap(children:_roomBackgrounds.map((v)=>ListTile(leading:CircleAvatar(backgroundColor:Color(v)),title:const Text('اختيار هذه الخلفية'),onTap:(){Navigator.pop(c);setState(()=>_background=v);})).toList())))
 ]),body:Column(children:[
  Expanded(child:Container(color:Color(_background),child:StreamBuilder<QuerySnapshot<Map<String,dynamic>>>(stream:db.collection('privateRooms').doc(widget.roomId).collection('messages').orderBy('createdAt').limit(300).snapshots(),builder:(context,s){
   if(s.hasError)return const Center(child:Text('تعذر تحميل الرسائل'));if(!s.hasData)return const Center(child:CircularProgressIndicator());
   return ListView(padding:const EdgeInsets.all(12),children:s.data!.docs.map((d){final x=d.data();final mine=x['senderId']==uid;return Align(alignment:mine?Alignment.centerLeft:Alignment.centerRight,child:Container(margin:const EdgeInsets.symmetric(vertical:4),padding:const EdgeInsets.all(12),constraints:const BoxConstraints(maxWidth:320),decoration:BoxDecoration(color:mine?const Color(0xFFE8E2FF):Colors.white,borderRadius:BorderRadius.circular(14),border:Border.all(color:const Color(0xFFBBBBCC))),child:Text(x['text'] as String? ?? '',style:const TextStyle(fontSize:17,color:Color(0xFF171717),height:1.5))));}).toList());
  }))),
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
 final tracks=<PlatformFile>[];
 int current=-1;
 bool loading=false,uploading=false;
 final db=FirebaseFirestore.instance;
 String get uid=>FirebaseAuth.instance.currentUser!.uid;
 Future<void> addTracks() async {
  final result=await FilePicker.platform.pickFiles(type:FileType.audio,allowMultiple:true);
  if(result==null)return;
  setState(()=>tracks.addAll(result.files.where((f)=>f.path!=null)));
 }
 Future<void> uploadTracks() async {
  final result=await FilePicker.platform.pickFiles(type:FileType.audio,allowMultiple:true);
  if(result==null||result.files.isEmpty)return;
  final chosen=result.files.where((f)=>f.path!=null).toList();
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
     'size':f.size,'fileUrl':url,'status':'pending','category':'music',
     'createdAt':FieldValue.serverTimestamp(),
     'safetyNote':'ملف صوتي بانتظار مراجعة المشرف. ارفع فقط ما تملك حق مشاركته.'
    });
    success++;
   }
   if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('تم رفع '+success.toString()+' أغنية، وهي بانتظار موافقة الإدارة')));
  }catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('تعذر رفع الأغاني: '+e.toString())));}
  finally{if(mounted)setState(()=>uploading=false);}
 }
 Future<void> play(int index) async {
  if(index<0||index>=tracks.length)return;
  setState(()=>loading=true);
  try{
   await appAudioHandler.loadLocalQueue(tracks.map((f)=>MediaItem(id:f.path!,title:f.name,album:'مكتبتي المحلية')).toList());
   await appAudioHandler.skipToQueueItem(index);
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
    return Card(child:ListTile(leading:const Icon(Icons.music_note,size:34),title:Text(current>=0?tracks[current].name:'مشغل الموسيقى'),subtitle:Text(loading?'جاري التحميل':playing?'يعمل الآن':'اختر أغنية للتشغيل'),trailing:IconButton(onPressed:playing?appAudioHandler.pause:appAudioHandler.play,icon:Icon(playing?Icons.pause_circle:Icons.play_circle))));
   })),
   const Padding(padding:EdgeInsets.fromLTRB(12,4,12,4),child:Align(alignment:Alignment.centerRight,child:Text('موسيقى المجتمع • الملفات المنشورة بعد موافقة الإدارة'))),
   Expanded(child:StreamBuilder<QuerySnapshot<Map<String,dynamic>>>(stream:db.collection('sharedFiles').where('status',isEqualTo:'approved').limit(150).snapshots(),builder:(context,s){
    if(s.hasError)return const Center(child:Text('تعذر تحميل الأغاني المنشورة'));
    if(!s.hasData)return const Center(child:CircularProgressIndicator());
    final docs=s.data!.docs.where((d)=>['mp3','m4a','aac','wav','ogg','flac'].contains((d.data()['extension']??'').toString().toLowerCase())).toList();
    return ListView(children:[
     if(docs.isEmpty)const ListTile(title:Text('ماكو أغاني منشورة بعد'),subtitle:Text('ارفع أغنية وانتظر موافقة الإدارة')),
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
   const Padding(padding:EdgeInsets.all(10),child:Text('التشغيل بالخلفية يستخدم مشغل Android. مشاركة الأغاني تمر بمراجعة الإدارة.',style:TextStyle(fontSize:12)))
  ])
 );
}
