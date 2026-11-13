import 'dart:io';
import 'package:gal/gal.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:video_player/video_player.dart';
import 'package:url_launcher/url_launcher.dart';
import 'local_bot.dart';
import 'engagement_features.dart';
import 'game_center.dart';

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
   ('النقاط والتحديات','مكافآت يومية وأخبار',Icons.emoji_events,const EngagementHubPage()),
   ('مركز الألعاب','كرة قدم وأسئلة وتحديات الأصدقاء',Icons.sports_esports,const GameCenterPage()),
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

class TextShelf extends StatefulWidget {
 final String collection,title,hint;
 const TextShelf({super.key,required this.collection,required this.title,required this.hint});
 @override State<TextShelf> createState()=>_TextShelfState();
}
class _TextShelfState extends State<TextShelf> {
 String category='الكل';
 static const _poemOpen=['يا صاحبي لا تنحني لو جار بك وقت','على ضفاف الحلم نمضي والمنى معنا','بغداد يا نبضاً يسافر في دمي','أحب الحياة إذا ابتسمت لخطوتي','يا ليل خبرني عن أحبابٍ مضوا','في القلب نافذة تطل على الأمل','نمضي وتبقى في المواقف سيرتنا','ما ضاق دربٌ والرجاء دليلنا','يا نجمةً خبأت في الليل أغنيتي','أمي دعاءٌ لا يغيب عن المدى','أكتب على وجه الصباح حكايتي','للصبر بابٌ لا يضيع طارقه','يا صاحبي خذ من وفائك موطناً','في كل عثرة حكمة متخفية','إن المحبة موطن الأرواح','للعمر فصلٌ لا يعيده الحنين','لا تسأل الأيام عن سر المدى','أرض الرافدين بقلبي قصيدة','والروح تعرف من يبادلها الوفا','سنظل نزرع في التراب محبة'];
 static const _poemEnds=['وأظل أزرع في الطريق خطاي وأملي.','فالفجر يولد كلما اشتد الظلام.','والطيب يبقى رغم تبدل كل شيء.','والقلب يعرف وجهته مهما ابتعد.','ومن الوفاء تصير أيامنا أجمل.','ما دام فينا للغد نفسٌ جديد.','وتظل أحلام الشباب هي الدليل.','فالحب أصدق ما يضيء من الكلام.','والذكر يبقى طيباً بين البشر.','ونعود أقوى كلما هبّت رياح.'];
 static const _quoteOpen=['لا تؤجل فرحتك','القوة ليست في ألا تسقط','الأصدقاء الحقيقيون','كل بداية صغيرة','لا تقارن رحلتك','الكلمة الطيبة','احفظ قلبك','النجاح يحتاج','من يعرف قيمة وقته','الأمل لا يطرق','كن لطيفاً','الهدوء أحياناً','لا تجعل رأي الناس','التجارب تعلمنا','الوفاء موقف','أجمل الانتصارات','حين تتعب','لا تخف من التغيير','العقل الهادئ','ازرع خيراً','الطموح','الكرامة','الاعتذار','القراءة','الإنسان الجميل','الصبر','لا تبحث عن الكمال','الذكريات','من يزرع المعروف','الحياة'];
 static const _quoteEnds=['فالحياة لا تنتظر اكتمال الظروف.','بل في قدرتك على النهوض من جديد.','يظهرون وقت الحاجة لا وقت المصلحة.','قد تفتح باباً واسعاً للمستقبل.','فلكل إنسان توقيته وطريقه.','قد تغيّر يوماً كاملاً في حياة أحدهم.','ولا تمنح ثقتك إلا لمن يصونها.','صبر وعمل واستمرار لا ضجيج.','يصنع من الدقائق إنجازاً.','إلا لقلب قرر أن يثق بالله.','فلا تعرف ما الذي يمر به الآخرون.','يكون أبلغ من ألف جواب.','مقياساً لقيمتك أو نجاحك.','ما لا تعلمه الكتب وحدها.','لا يحتاج إلى جمهور كي يثبت نفسه.','أن تنتصر على ضعف الأمس.','تذكر كم مرة تجاوزت ما ظننته مستحيلاً.','فقد يكون خلفها باب أجمل.','يرى الحل قبل أن يرى المشكلة.','فقد تحصد خيراً لم تتوقعه.','يبدأ بخطوة صادقة كل يوم.','لا تعني القسوة بل معرفة حدودك.','شجاعة حين يكون الخطأ واضحاً.','تمنحك عالماً أوسع من مكانك.','يترك أثراً طيباً دون أن يتكلم.','ليس انتظاراً بل ثبات مع السعي.','فالجمال في الصدق والبساطة.','تسكن التفاصيل الصغيرة أكثر من الصور.','يجد الخير في طريقه يوماً.','تستحق أن تعاش بقلب حاضر.'];
 List<Map<String,String>> get _builtIns {
  if(widget.collection=='poems') return List.generate(200,(i)=>{'text':'${_poemOpen[i%_poemOpen.length]}، ${_poemEnds[(i ~/ _poemOpen.length + i)%_poemEnds.length]}','category':i.isEven?'فصحى':'شعبي','authorName':'مكتبة الملتقى','id':'builtin-poem-$i'});
  return List.generate(300,(i)=>{'text':'${_quoteOpen[i%_quoteOpen.length]}، ${_quoteEnds[(i ~/ _quoteOpen.length + i)%_quoteEnds.length]}','category':'اقتباسات','authorName':'مكتبة الملتقى','id':'builtin-quote-$i'});
 }
 Future<void> add(BuildContext c) async {
  final t=TextEditingController(); String selected=widget.collection=='poems'?'فصحى':'اقتباسات';
  final ok=await showDialog<bool>(context:c,builder:(x)=>StatefulBuilder(builder:(x,setDialog)=>Directionality(textDirection:TextDirection.rtl,child:AlertDialog(
   title:Text('إضافة ${widget.title}'),content:Column(mainAxisSize:MainAxisSize.min,children:[
    if(widget.collection=='poems') DropdownButtonFormField<String>(value:selected,items:const [DropdownMenuItem(value:'شعبي',child:Text('شعر شعبي')),DropdownMenuItem(value:'فصحى',child:Text('شعر فصحى'))],onChanged:(v)=>setDialog(()=>selected=v??'فصحى')),
    TextField(controller:t,minLines:4,maxLines:10,maxLength:3000,decoration:InputDecoration(hintText:widget.hint,border:const OutlineInputBorder()))
   ]),actions:[TextButton(onPressed:()=>Navigator.pop(x,false),child:const Text('إلغاء')),FilledButton(onPressed:()=>Navigator.pop(x,true),child:const Text('نشر'))]))));
  final value=t.text.trim();t.dispose();if(ok!=true||value.isEmpty)return;
  final u=FirebaseAuth.instance.currentUser!;final profile=await db2.collection('publicProfiles').doc(u.uid).get();
  await db2.collection(widget.collection).add({'text':value,'category':selected,'authorId':u.uid,'authorName':profile.data()?['name']??u.displayName??'عضو','createdAt':FieldValue.serverTimestamp()});
 }
 @override Widget build(BuildContext context)=>Directionality(textDirection:TextDirection.rtl,child:Scaffold(
  appBar:AppBar(title:Text(widget.title)),body:Column(children:[
   if(widget.collection=='poems') Padding(padding:const EdgeInsets.fromLTRB(12,8,12,2),child:Wrap(spacing:8,children:['الكل','شعبي','فصحى'].map((v)=>ChoiceChip(label:Text(v),selected:category==v,onSelected:(_)=>setState(()=>category=v))).toList())),
   Expanded(child:StreamBuilder<QuerySnapshot<Map<String,dynamic>>>(stream:db2.collection(widget.collection).orderBy('createdAt',descending:true).limit(150).snapshots(),builder:(c,s){
    if(s.hasError)return const Center(child:Text('تعذر تحميل المشاركات. تأكد من قواعد Firestore.'));
    if(!s.hasData)return const Center(child:CircularProgressIndicator());
    final userItems=s.data!.docs.map((doc)=>{'text':doc.data()['text'] as String? ??'','category':doc.data()['category'] as String? ??(widget.collection=='poems'?'فصحى':'اقتباسات'),'authorName':doc.data()['authorName'] as String? ??'عضو','id':doc.id}).where((d)=>category=='الكل'||d['category']==category).toList();
    final built=_builtIns.where((d)=>category=='الكل'||d['category']==category).toList(); final items=[...userItems,...built];
    if(items.isEmpty)return Center(child:Text('لا توجد ${widget.title} بهذا التصنيف بعد.'));
    return ListView.builder(padding:const EdgeInsets.all(12),itemCount:items.length,itemBuilder:(c,i){final d=items[i];final value=d['text']!;
     return Card(child:Padding(padding:const EdgeInsets.all(14),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      Row(children:[const Icon(Icons.auto_awesome,color:p),const SizedBox(width:8),Expanded(child:Text(d['authorName']!,style:const TextStyle(fontWeight:FontWeight.bold))),Chip(label:Text(d['category']!))]),
      SelectableText(value,style:const TextStyle(fontSize:17,height:1.7)),
      Align(alignment:Alignment.centerLeft,child:Wrap(children:[
       IconButton(tooltip:'نسخ النص',icon:const Icon(Icons.copy),onPressed:(){Clipboard.setData(ClipboardData(text:value));ScaffoldMessenger.of(c).showSnackBar(const SnackBar(content:Text('تم نسخ النص')));}),
       IconButton(tooltip:'مشاركة عبر النسخ',icon:const Icon(Icons.share_outlined),onPressed:(){Clipboard.setData(ClipboardData(text:value));ScaffoldMessenger.of(c).showSnackBar(const SnackBar(content:Text('انسخ النص وشاركه بأي تطبيق')));})
      ]))
     ])));
    });
   }))
  ]),floatingActionButton:FloatingActionButton.extended(backgroundColor:p,foregroundColor:Colors.white,onPressed:()=>add(context),icon:const Icon(Icons.add),label:Text('أضف ${widget.title}')),
 ));
}
class PoetryPage extends StatelessWidget {const PoetryPage({super.key});@override Widget build(BuildContext c)=>const TextShelf(collection:'poems',title:'مكتبة الشعر',hint:'اكتب قصيدتك هنا...');}
class QuotesPage extends StatelessWidget {const QuotesPage({super.key});@override Widget build(BuildContext c)=>const TextShelf(collection:'quotes',title:'مكتبة الاقتباسات',hint:'اكتب اقتباسك هنا...');}

class StoriesPage extends StatefulWidget {const StoriesPage({super.key});@override State<StoriesPage> createState()=>_StoriesPageState();}
class _StoriesPageState extends State<StoriesPage>{
 bool busy=false;
 Future<void> downloadStory(String url) async {
  HttpClient? client;
  File? file;
  try {
   if (!await Gal.hasAccess()) {
    final granted = await Gal.requestAccess();
    if (!granted) throw Exception('permission');
   }
   client = HttpClient();
   final request = await client.getUrl(Uri.parse(url));
   final response = await request.close();
   if (response.statusCode != 200) throw Exception('download');
   final bytes = await response.fold<List<int>>(<int>[], (a, b) => a..addAll(b));
   file = File('${Directory.systemTemp.path}/forum_story_${DateTime.now().millisecondsSinceEpoch}.mp4');
   await file.writeAsBytes(bytes, flush: true);
   await Gal.putVideo(file.path, album: 'ملتقى شباب المستقبل');
   if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('تم حفظ الفيديو في معرض الجهاز')));
  } catch (_) {
   if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('تعذر تنزيل الفيديو. تحقق من الصلاحية ومساحة الجهاز.')));
  } finally {
   client?.close(force: true);
   if (file != null && await file.exists()) await file.delete();
  }
 }
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
     if(video) Align(alignment:Alignment.centerLeft,child:TextButton.icon(onPressed:()=>downloadStory(url),icon:const Icon(Icons.download),label:const Text('تنزيل الفيديو للجهاز'))),
     const Padding(padding:EdgeInsets.all(8),child:Text('تختفي بعد 24 ساعة',style:TextStyle(color:Colors.black54,fontSize:12))),
     StoryInteractionPanel(storyId:doc.id,authorId:(d['authorId']??'').toString())
    ]));
   }).toList());
  }),
  floatingActionButton:FloatingActionButton.extended(backgroundColor:p,foregroundColor:Colors.white,onPressed:busy?null:add,icon:busy?const CircularProgressIndicator(color:Colors.white):const Icon(Icons.add_a_photo),label:Text(busy?'جارٍ الرفع':'إضافة ستوري'))
 ));
}
class StoryInteractionPanel extends StatefulWidget {
  final String storyId, authorId;
  const StoryInteractionPanel({super.key, required this.storyId, required this.authorId});
  @override State<StoryInteractionPanel> createState() => _StoryInteractionPanelState();
}
class _StoryInteractionPanelState extends State<StoryInteractionPanel> {
  final _reply = TextEditingController();
  bool _sending = false;
  String get _uid => FirebaseAuth.instance.currentUser!.uid;
  CollectionReference<Map<String,dynamic>> get _views => db2.collection('stories').doc(widget.storyId).collection('views');
  CollectionReference<Map<String,dynamic>> get _replies => db2.collection('stories').doc(widget.storyId).collection('replies');
  @override void initState() { super.initState(); _views.doc(_uid).set({'viewerId':_uid,'viewedAt':FieldValue.serverTimestamp()},SetOptions(merge:true)).catchError((_){}); }
  @override void dispose() { _reply.dispose(); super.dispose(); }
  Future<void> _send() async {
    final text = _reply.text.trim(); if (text.isEmpty || _sending) return;
    setState(()=>_sending=true);
    try {
      final profile = await db2.collection('publicProfiles').doc(_uid).get();
      await _replies.add({'authorId':_uid,'authorName':profile.data()?['name']??'عضو','text':text,'createdAt':FieldValue.serverTimestamp()});
      if (widget.authorId.isNotEmpty && widget.authorId != _uid) {
        await db2.collection('notifications').add({'recipientId':widget.authorId,'actorId':_uid,'actorName':profile.data()?['name']??'عضو','type':'story_reply','text':'رد على قصتك','read':false,'createdAt':FieldValue.serverTimestamp()});
      }
      _reply.clear();
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('تعذر إرسال الرد')));
    } finally { if(mounted)setState(()=>_sending=false); }
  }
  @override Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(12,0,12,12),
    child: Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
      StreamBuilder<QuerySnapshot<Map<String,dynamic>>>(stream:_views.snapshots(),builder:(c,s)=>Row(children:[
        const Icon(Icons.visibility_outlined,size:18),const SizedBox(width:5),Text('${s.data?.docs.length??0} مشاهدة'),
        const Spacer(),const Icon(Icons.chat_bubble_outline,size:17),const SizedBox(width:4),
        StreamBuilder<QuerySnapshot<Map<String,dynamic>>>(stream:_replies.snapshots(),builder:(c,r)=>Text('${r.data?.docs.length??0} رد')),
      ])),
      StreamBuilder<QuerySnapshot<Map<String,dynamic>>>(stream:_replies.orderBy('createdAt',descending:true).limit(10).snapshots(),builder:(c,s){
        if(!s.hasData||s.data!.docs.isEmpty)return const SizedBox.shrink();
        return Column(children:s.data!.docs.map((doc){final d=doc.data();return ListTile(dense:true,leading:const Icon(Icons.reply,size:18),title:Text(d['authorName']??'عضو'),subtitle:Text(d['text']??''));}).toList());
      }),
      Row(children:[
        Expanded(child:TextField(controller:_reply,maxLength:300,minLines:1,maxLines:2,decoration:const InputDecoration(hintText:'رد على الستوري...',counterText:'',isDense:true))),
        IconButton.filled(onPressed:_sending?null:_send,icon:_sending?const SizedBox(width:16,height:16,child:CircularProgressIndicator(strokeWidth:2)):const Icon(Icons.send)),
      ]),
    ]),
  );
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
class RegionChatPage extends StatefulWidget {
 final String id,title;
 const RegionChatPage({super.key,required this.id,required this.title});
 @override State<RegionChatPage> createState()=>_RegionChatPageState();
}
class _RegionChatPageState extends State<RegionChatPage> {
 final t=TextEditingController();
 final picker=ImagePicker();
 bool busy=false;
 String? error;
 int backgroundIndex=0;
 bool get founder=>isForumFounder;
 static const backgrounds=[Color(0xFFF5F3FF),Color(0xFFEAF6FF),Color(0xFFFFF3E8),Color(0xFFF0F7F1),Color(0xFF171936)];
 static const stickers=['😂','❤️','🔥','😍','😭','👏','✨','🌹','🫶','🤣','🥹','💜','⚽','🐱','🎉','👍'];

 Future<bool> blocked(String uid) async {
  final snap=await db2.collection('regionalChats').doc(widget.id).collection('bans').doc(uid).get();
  if(!snap.exists)return false;
  final data=snap.data()??{};
  if(data['permanent']==true)return true;
  final until=data['expiresAt'] as Timestamp?;
  return until!=null && until.toDate().isAfter(DateTime.now());
 }

 Future<void> moderate(String uid,String name) async {
  if(!founder || uid==FirebaseAuth.instance.currentUser!.uid)return;
  final choice=await showDialog<String>(context:context,builder:(c)=>Directionality(textDirection:TextDirection.rtl,child:AlertDialog(
   title:Text('إدارة العضو: $name'),content:const Text('اختار مدة المنع من دخول هذه الغرفة.'),
   actions:[TextButton(onPressed:()=>Navigator.pop(c,'cancel'),child:const Text('إلغاء')),
    TextButton(onPressed:()=>Navigator.pop(c,'kick'),child:const Text('طرد مؤقت')),
    TextButton(onPressed:()=>Navigator.pop(c,'1h'),child:const Text('ساعة')),
    TextButton(onPressed:()=>Navigator.pop(c,'2h'),child:const Text('ساعتين')),
    TextButton(onPressed:()=>Navigator.pop(c,'1d'),child:const Text('يوم')),
    TextButton(onPressed:()=>Navigator.pop(c,'forever'),child:const Text('للأبد')),
    TextButton(onPressed:()=>Navigator.pop(c,'unban'),child:const Text('رفع الحظر'))])));
  if(choice==null||choice=='cancel')return;
  final ref=db2.collection('regionalChats').doc(widget.id).collection('bans').doc(uid);
  if(choice=='unban'){await ref.delete();}
  else{
   final duration=choice=='kick'?const Duration(minutes:1):choice=='1h'?const Duration(hours:1):choice=='2h'?const Duration(hours:2):choice=='1d'?const Duration(days:1):null;
   await ref.set({'permanent':duration==null,'expiresAt':duration==null?null:Timestamp.fromDate(DateTime.now().add(duration)),'by':FirebaseAuth.instance.currentUser!.uid,'updatedAt':FieldValue.serverTimestamp()});
  }
  if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(choice=='unban'?'تم رفع الحظر':choice=='kick'?'تم الطرد المؤقت':'تم تطبيق الحظر')));
 }

 Future<void> send({String text='',String? imageUrl,String type='text'}) async {
  if((text.trim().isEmpty&&imageUrl==null)||busy)return;
  final me=FirebaseAuth.instance.currentUser!;
  if(await blocked(me.uid)){if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('أنت ممنوع من هذه الغرفة حالياً.')));return;}
  setState(()=>busy=true);
  try{
   final profile=await db2.collection('publicProfiles').doc(me.uid).get();
   await db2.collection('regionalChats').doc(widget.id).collection('messages').add({
    'text':text.trim(),'type':type,if(imageUrl!=null)'imageUrl':imageUrl,
    'senderId':me.uid,'senderRole':founder?'founder':'member',
    'senderName':profile.data()?['name']??me.displayName??'عضو','createdAt':FieldValue.serverTimestamp()});
   if(text.isNotEmpty)t.clear();
  }catch(_){if(mounted)setState(()=>error='تعذر الإرسال. تأكد من نشر قواعد Firestore الجديدة.');}
  finally{if(mounted)setState(()=>busy=false);}
 }

 Future<void> sendImage() async {
  try{
   final file=await picker.pickImage(source:ImageSource.gallery);
   if(file==null)return;
   final ext=file.name.toLowerCase().split('.').last;
   final safe=['jpg','jpeg','png','webp','gif'].contains(ext)?ext:'jpg';
   final path='regional-chat/${widget.id}/${FirebaseAuth.instance.currentUser!.uid}/${DateTime.now().millisecondsSinceEpoch}.$safe';
   await Supabase.instance.client.storage.from('forum-media').uploadBinary(path,await file.readAsBytes(),
    fileOptions:FileOptions(contentType:safe=='gif'?'image/gif':'image/$safe',upsert:false));
   await send(imageUrl:Supabase.instance.client.storage.from('forum-media').getPublicUrl(path),type:'image');
  }catch(_){if(mounted)setState(()=>error='تعذر رفع الصورة. تحقق من صلاحيات مخزن الصور.');}
 }

 void showStickers()=>showModalBottomSheet<void>(context:context,showDragHandle:true,
  builder:(sheet)=>Directionality(textDirection:TextDirection.rtl,child:Padding(padding:const EdgeInsets.all(16),
   child:GridView.count(shrinkWrap:true,crossAxisCount:4,childAspectRatio:1.3,children:stickers.map((s)=>InkWell(
    onTap:(){Navigator.pop(sheet);send(text:s,type:'sticker');},
    child:Center(child:Text(s,style:const TextStyle(fontSize:34))))).toList()))));

 Future<void> chooseBackground() async {
  final selected=await showModalBottomSheet<int>(context:context,showDragHandle:true,
   builder:(sheet)=>Directionality(textDirection:TextDirection.rtl,child:Padding(padding:const EdgeInsets.all(20),
    child:Column(mainAxisSize:MainAxisSize.min,crossAxisAlignment:CrossAxisAlignment.start,children:[
     const Text('خلفية هذه الغرفة',style:TextStyle(fontSize:18,fontWeight:FontWeight.bold)),
     const SizedBox(height:16),
     Wrap(spacing:12,children:List.generate(backgrounds.length,(i)=>InkWell(
      onTap:()=>Navigator.pop(sheet,i),
      child:Container(width:46,height:46,decoration:BoxDecoration(color:backgrounds[i],shape:BoxShape.circle,border:Border.all(color:backgroundIndex==i?p:Colors.black12,width:backgroundIndex==i?3:1)))))),
     const SizedBox(height:8),const Text('التغيير يظهر لك داخل هذه الغرفة.',style:TextStyle(color:Colors.black54,fontSize:12))
    ]))));
  if(selected!=null&&mounted)setState(()=>backgroundIndex=selected);
 }

 Widget bubble(Map<String,dynamic> d,bool mine) {
  final isFounder=d['senderRole']=='founder';
  final type=d['type'] as String? ?? 'text';
  final txt=d['text'] as String? ?? '';
  final url=d['imageUrl'] as String?;
  return Align(alignment:mine?Alignment.centerRight:Alignment.centerLeft,child:Container(
   margin:const EdgeInsets.symmetric(vertical:5),padding:const EdgeInsets.all(11),
   constraints:BoxConstraints(maxWidth:MediaQuery.of(context).size.width*.8),
   decoration:BoxDecoration(gradient:mine?const LinearGradient(colors:[Color(0xFFEDE8FF),Color(0xFFDCD5FF)]):null,
    color:mine?null:Colors.white.withValues(alpha:.96),borderRadius:BorderRadius.circular(16),
    border:Border.all(color:isFounder?const Color(0xFFFFD77A):Colors.black12)),
   child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
    if(!mine)Row(mainAxisSize:MainAxisSize.min,children:[
     Flexible(child:Text(d['senderName'] as String? ?? 'عضو',style:TextStyle(color:isFounder?const Color(0xFFB77900):p,fontWeight:FontWeight.bold,fontSize:12))),
     if(isFounder)const Padding(padding:EdgeInsets.only(right:4),child:Icon(Icons.workspace_premium,color:Color(0xFFFFB52E),size:15)),
     if(founder)IconButton(visualDensity:VisualDensity.compact,tooltip:'إدارة العضو',icon:const Icon(Icons.admin_panel_settings,size:18),onPressed:()=>moderate(d['senderId'] as String? ?? '',d['senderName'] as String? ?? 'عضو'))
    ]),
    if(type=='image'&&url!=null)ClipRRect(borderRadius:BorderRadius.circular(12),child:Image.network(url,width:230,fit:BoxFit.cover,errorBuilder:(c,e,s)=>const Text('تعذر عرض الصورة'))),
    if(type=='sticker')Center(child:Text(txt,style:const TextStyle(fontSize:46))),
    if(type!='sticker'&&txt.isNotEmpty)Text(txt,style:const TextStyle(fontSize:15))
   ])));
 }

 @override void dispose(){t.dispose();super.dispose();}
 @override Widget build(BuildContext c)=>Directionality(textDirection:TextDirection.rtl,child:Scaffold(
  appBar:AppBar(title:Text(widget.title),actions:[
   IconButton(tooltip:'خلفية الغرفة',icon:const Icon(Icons.wallpaper),onPressed:chooseBackground),
   if(founder)const Padding(padding:EdgeInsets.symmetric(horizontal:8),child:Center(child:Text('👑 المؤسس',style:TextStyle(fontWeight:FontWeight.bold)))),
   IconButton(tooltip:'مساعد الملتقى',icon:const Icon(Icons.smart_toy),onPressed:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const LocalHelperBotPage())))
  ]),
  body:Column(children:[
   Expanded(child:Container(color:backgrounds[backgroundIndex],child:StreamBuilder<QuerySnapshot<Map<String,dynamic>>>(
    stream:db2.collection('regionalChats').doc(widget.id).collection('messages').orderBy('createdAt',descending:true).limit(150).snapshots(),
    builder:(c,s){
     if(s.hasError)return const Center(child:Text('الدردشة تحتاج قواعد Firestore الجديدة'));
     if(!s.hasData)return const Center(child:CircularProgressIndicator());
     if(s.data!.docs.isEmpty)return const Center(child:Text('ابدأ المحادثة 👋'));
     final me=FirebaseAuth.instance.currentUser!.uid;
     return ListView.builder(reverse:true,padding:const EdgeInsets.all(12),itemCount:s.data!.docs.length,
      itemBuilder:(c,i){final d=s.data!.docs[i].data();return bubble(d,d['senderId']==me);});
    }))),
   if(error!=null)Padding(padding:const EdgeInsets.symmetric(horizontal:10,vertical:3),child:Text(error!,style:const TextStyle(color:Colors.red,fontSize:11))),
   Container(color:Colors.white,padding:const EdgeInsets.symmetric(horizontal:6,vertical:6),child:SafeArea(top:false,child:Row(children:[
    IconButton(onPressed:busy?null:sendImage,tooltip:'صورة أو GIF',icon:const Icon(Icons.image,color:p)),
    IconButton(onPressed:busy?null:showStickers,tooltip:'ملصقات',icon:const Icon(Icons.emoji_emotions,color:Color(0xFFE6A52C))),
    Expanded(child:TextField(controller:t,minLines:1,maxLines:4,maxLength:1000,textInputAction:TextInputAction.send,onSubmitted:(_)=>send(text:t.text),
     decoration:const InputDecoration(hintText:'اكتب رسالتك...',counterText:'',border:OutlineInputBorder()))),
    IconButton.filled(onPressed:busy?null:()=>send(text:t.text),icon:const Icon(Icons.send))
   ])))
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
