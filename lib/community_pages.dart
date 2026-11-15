import 'dart:io';
import 'package:gal/gal.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'youtube_video_player.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:record/record.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:video_player/video_player.dart';
import 'package:url_launcher/url_launcher.dart';
import 'local_bot.dart';
import 'engagement_features.dart';
import 'game_center.dart';
import 'anime_experience.dart';
import 'community_polls.dart';
import 'community_events.dart';
import 'media_upload_service.dart';
import 'creative_library.dart';
import 'extra_community_features.dart';
import 'watch_party.dart';
import 'arcade_hub.dart';
import 'inspiration_hub.dart';
import 'match_center.dart';
import 'livekit_calls.dart';
import 'daily_world.dart';
import 'v6_community_suite.dart';
import 'knowledge_corner.dart';

const p=Color(0xFF6554D9);
final db2=FirebaseFirestore.instance;
const founderEmail='husinalzerjaoe@gmail.com';
bool get isForumFounder => FirebaseAuth.instance.currentUser?.email?.toLowerCase()==founderEmail;

class CommunityHubPage extends StatefulWidget {
 const CommunityHubPage({super.key});
 @override State<CommunityHubPage> createState()=>_CommunityHubPageState();
}

class _CommunityHubPageState extends State<CommunityHubPage> {
 final TextEditingController _search=TextEditingController();
 String _category='الكل';

 late final List<({String title,String subtitle,String category,IconData icon,Widget page})> _items=[
  (title:'الستوريات',subtitle:'صور وفيديوهات لمدة 24 ساعة',category:'التواصل',icon:Icons.camera_alt,page:const StoriesPage()),
  (title:'دردشات الدول',subtitle:'العراق وسوريا وثلاث غرف أخرى',category:'التواصل',icon:Icons.forum,page:const RegionChatRoomsPage()),
  (title:'المشاهدة الجماعية',subtitle:'شاهدوا يوتيوب والبث المباشر معاً',category:'الترفيه',icon:Icons.groups_rounded,page:const WatchPartyLobbyPage()),
  (title:'يوتيوب والترفيه',subtitle:'أغانٍ وفيديوهات وروابط أفلام رسمية',category:'الترفيه',icon:Icons.play_circle_fill,page:const YouTubeShelfPage()),
  (title:'مكالمات الصوت والفيديو',subtitle:'مكالمات جماعية وخاصة عبر LiveKit',category:'التواصل',icon:Icons.video_call_rounded,page:const LiveKitCallsPage()),
  (title:'مركز الألعاب',subtitle:'ألعاب أصدقاء وأسئلة وتحديات ومنافسات',category:'الألعاب',icon:Icons.sports_esports,page:const GameCenterPage()),
  (title:'مدينة الألعاب',subtitle:'ألعاب مصغرة وتحديات جماعية وألعاب لوحية',category:'الألعاب',icon:Icons.videogame_asset_rounded,page:const ArcadeHubPage()),
  (title:'النقاط والتحديات',subtitle:'مكافآت يومية وأخبار وإنجازات',category:'الألعاب',icon:Icons.emoji_events,page:const EngagementHubPage()),
  (title:'مركز المباريات',subtitle:'مواعيد ونتائج ومتابعة أخبار الكرة',category:'الألعاب',icon:Icons.sports_soccer,page:const MatchCenterPage()),
  (title:'المساعد الذكي',subtitle:'مساعد مجاني داخل التطبيق',category:'المعرفة',icon:Icons.smart_toy,page:const LocalHelperBotPage()),
  (title:'ركن المعرفة والترفيه',subtitle:'معلومات يومية ونصائح وألغاز وكتابة إبداعية',category:'المعرفة',icon:Icons.auto_stories_rounded,page:const KnowledgeCornerPage()),
  (title:'عالمك اليومي',subtitle:'تحديات يومية ومزاجك وأدوات مفيدة',category:'المعرفة',icon:Icons.today_rounded,page:const DailyWorldPage()),
  (title:'إلهام يومي',subtitle:'أفكار واقتباسات ومحتوى إيجابي',category:'المعرفة',icon:Icons.lightbulb_outline,page:const InspirationHubPage()),
  (title:'الشعر',subtitle:'قصائد الأعضاء',category:'الثقافة',icon:Icons.auto_awesome,page:const PoetryPage()),
  (title:'الاقتباسات',subtitle:'انسخ أجمل العبارات',category:'الثقافة',icon:Icons.format_quote,page:const QuotesPage()),
  (title:'مكتبة الأدب والعبارات',subtitle:'شعر وأدعية وأذكار ونكت وبطاقات',category:'الثقافة',icon:Icons.menu_book,page:const CreativeLibraryPage()),
  (title:'عالم الأنمي',subtitle:'خلفيات مرخّصة وقائمة مشاهدة واختبارات',category:'الترفيه',icon:Icons.animation,page:const AnimeExperiencePage()),
  (title:'تصويتات الملتقى',subtitle:'استفتاءات وآراء الأعضاء',category:'المجتمع',icon:Icons.poll,page:const CommunityPollsPage()),
  (title:'فعاليات الملتقى',subtitle:'مسابقات ولقاءات وتسجيل مشاركة',category:'المجتمع',icon:Icons.event_available,page:const CommunityEventsPage()),
  (title:'أندية الاهتمامات',subtitle:'أنشئ نادياً أو انضم لأصحاب اهتماماتك',category:'المجتمع',icon:Icons.diversity_3_rounded,page:const V6CommunitySuitePage()),
  (title:'مساحة التركيز',subtitle:'مؤقت بومودورو وجلسات إنجاز واستراحات',category:'المعرفة',icon:Icons.timer_rounded,page:const FocusRoomPage()),
  (title:'مساحتي الشخصية',subtitle:'مزاجك وأهدافك وعاداتك ودفتر يومياتك',category:'المعرفة',icon:Icons.auto_graph_rounded,page:const PersonalGrowthPage()),
  (title:'الغرف والملفات والموسيقى',subtitle:'غرف بدعوات ورمز ومشاركة ملفات ومشغل محلي',category:'الترفيه',icon:Icons.hub,page:const ExtraCommunityFeaturesPage()),
  (title:'أبراج وحساب العمر',subtitle:'أدوات خفيفة ومعلومات ترفيهية',category:'المعرفة',icon:Icons.cake_outlined,page:const LifeToolsPage()),
 ];

 @override void dispose(){_search.dispose();super.dispose();}

 @override Widget build(BuildContext context){
  final cs=Theme.of(context).colorScheme;
  final q=_search.text.trim().toLowerCase();
  final visible=_items.where((e)=>(_category=='الكل'||e.category==_category)&&
    (q.isEmpty||('${e.title} ${e.subtitle} ${e.category}').toLowerCase().contains(q))).toList();
  const categories=['الكل','التواصل','الألعاب','الترفيه','المجتمع','المعرفة','الثقافة'];
  return Directionality(textDirection:TextDirection.rtl,child:CustomScrollView(slivers:[
   SliverToBoxAdapter(child:Padding(padding:const EdgeInsets.fromLTRB(14,14,14,10),child:Container(
    padding:const EdgeInsets.all(20),
    decoration:BoxDecoration(
     gradient:const LinearGradient(begin:Alignment.topRight,end:Alignment.bottomLeft,colors:[Color(0xFF171936),p,Color(0xFF35BCEB)]),
     borderRadius:BorderRadius.circular(24),
     boxShadow:[BoxShadow(color:p.withValues(alpha:.2),blurRadius:18,offset:const Offset(0,8))]),
    child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
     Row(children:[Container(width:48,height:48,decoration:BoxDecoration(color:Colors.white.withValues(alpha:.14),borderRadius:BorderRadius.circular(15)),child:const Icon(Icons.hub_rounded,color:Colors.white,size:28)),const Spacer(),const Text('FUTURE YOUTH • COMMUNITY',style:TextStyle(color:Colors.white70,fontSize:10,fontWeight:FontWeight.w900,letterSpacing:.6))]),
     const SizedBox(height:14),
     const Text('كل عالم الملتقى بمكان واحد ✨',style:TextStyle(color:Colors.white,fontSize:22,fontWeight:FontWeight.w900)),
     const SizedBox(height:6),
     const Text('تواصل، العب، شاهد، تعلّم وشارك أصدقاءك لحظاتك.',style:TextStyle(color:Colors.white70,height:1.5)),
     const SizedBox(height:15),
     Row(children:[
      _hubStat(_items.length.toString(),'قسم وخدمة'),
      const SizedBox(width:9),
      _hubStat('24/7','مجتمعك'),
      const SizedBox(width:9),
      _hubStat('LIVE','مع الأصدقاء'),
     ]),
    ]),
   ))),
   SliverToBoxAdapter(child:Padding(padding:const EdgeInsets.fromLTRB(14,4,14,8),child:TextField(
    controller:_search,onChanged:(_)=>setState(()=>{}),
    decoration:InputDecoration(hintText:'ابحث عن قسم أو ميزة...',prefixIcon:const Icon(Icons.search_rounded),filled:true,fillColor:cs.surfaceContainerLow,
     border:OutlineInputBorder(borderRadius:BorderRadius.circular(16),borderSide:BorderSide.none),
     suffixIcon:_search.text.isEmpty?null:IconButton(onPressed:()=>setState(_search.clear),icon:const Icon(Icons.close_rounded))),
   ))),
   SliverToBoxAdapter(child:SizedBox(height:52,child:ListView(scrollDirection:Axis.horizontal,padding:const EdgeInsets.symmetric(horizontal:10,vertical:5),children:categories.map((c)=>Padding(
    padding:const EdgeInsets.symmetric(horizontal:4),child:ChoiceChip(label:Text(c),selected:_category==c,onSelected:(_)=>setState(()=>_category=c)),
   )).toList()))),
   SliverPadding(padding:const EdgeInsets.fromLTRB(12,8,12,24),sliver:visible.isEmpty
    ?SliverToBoxAdapter(child:Padding(padding:const EdgeInsets.all(30),child:Center(child:Text('ما لقينا قسم بهذا الاسم. جرّب كلمة ثانية.',style:TextStyle(color:cs.onSurfaceVariant)))))
    :SliverGrid(delegate:SliverChildBuilderDelegate((c,i){
      final item=visible[i];
      final colors=[p,const Color(0xFF168E9B),const Color(0xFFB65BC8),const Color(0xFF2878C7)];
      final accent=colors[i%colors.length];
      return Card(elevation:0,color:cs.surfaceContainerLow,shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(20),side:BorderSide(color:cs.outlineVariant.withValues(alpha:.5))),
       child:InkWell(borderRadius:BorderRadius.circular(20),onTap:()=>Navigator.push(c,MaterialPageRoute(builder:(_)=>item.page)),
        child:Padding(padding:const EdgeInsets.all(13),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
         Container(width:48,height:48,decoration:BoxDecoration(color:accent.withValues(alpha:.13),borderRadius:BorderRadius.circular(15)),child:Icon(item.icon,color:accent,size:27)),
         const Spacer(),
         Text(item.title,style:TextStyle(fontWeight:FontWeight.w900,fontSize:14,color:cs.onSurface),maxLines:2,overflow:TextOverflow.ellipsis),
         const SizedBox(height:5),
         Text(item.subtitle,style:TextStyle(fontSize:11,height:1.35,color:cs.onSurfaceVariant),maxLines:2,overflow:TextOverflow.ellipsis),
         const SizedBox(height:7),
         Row(children:[Container(padding:const EdgeInsets.symmetric(horizontal:8,vertical:3),decoration:BoxDecoration(color:accent.withValues(alpha:.1),borderRadius:BorderRadius.circular(20)),child:Text(item.category,style:TextStyle(color:accent,fontSize:10,fontWeight:FontWeight.bold))),const Spacer(),Icon(Icons.arrow_back_rounded,size:17,color:accent)]),
        ]))),
      );
    },childCount:visible.length),gridDelegate:const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount:2,childAspectRatio:.93,crossAxisSpacing:10,mainAxisSpacing:10))),
  ]));
 }
 Widget _hubStat(String value,String label)=>Expanded(child:Container(padding:const EdgeInsets.symmetric(horizontal:8,vertical:9),decoration:BoxDecoration(color:Colors.white.withValues(alpha:.12),borderRadius:BorderRadius.circular(13)),child:Column(children:[Text(value,style:const TextStyle(color:Colors.white,fontWeight:FontWeight.w900,fontSize:15)),const SizedBox(height:2),Text(label,style:const TextStyle(color:Colors.white70,fontSize:10))])));
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
 static const _freshPoems = [
  'إذا ضاقت بك الدنيا تذكّر\nبأن الفجر يولد من عتمة الليل.',
  'بغداد يا شمساً على كتف الفرات\nفي كل زقاقٍ منك حكاية وبيت.',
  'نمضي وفي أرواحنا حلمٌ كبير\nلا ينحني مهما تثاقلنا المسير.',
  'يا صاحبي خذ من المواقف عبرة\nفالطيب يظهر حين تضيق السبل.',
  'أحببت فيك الصدق لا زيف الكلام\nفالروح تعرف من يصون لها السلام.',
  'على باب الأمل انتظر صباحاً\nفما بعد التعب إلا اتساع.',
  'يمّه دعاؤك في دروبي نجمة\nتهدي خطاي إذا تعثّر بي الطريق.',
  'لا تحسبنّ الصمت ضعفاً دائماً\nفالبحر يخفي في سكونه ألف موج.',
  'سنزرع الورد في أرضٍ أتعبتها\nأقدام يأسٍ، والرجاء هو المطر.',
  'يا دجلة الخير احملي أحلامنا\nنحو الغد الموعود بالأمنيات.',
  'من عاش للناس الكرامة منهجاً\nترك القلوب تردّد الإحسان.',
  'إذا تعثّرت الخطى لا تنكسر\nفالدرب يفتح للصبور منافذاً.',
  'أصدقاء صدقٍ لا تغيّرهم مسافة\nيبقون في القلب الجميل منارة.',
  'وما الحياة سوى فصولٍ عابرة\nفاجعل جميل الذكر آخر سطرها.',
  'تعلمت أن العزّ فعلٌ ثابتٌ\nلا أن يكون المرء أعلى صوتاً.',
  'يا نجمةً في ليل غربتنا أضيئي\nفالحلم يكبر كلما اشتد الظلام.',
 ];
 static const _freshQuotes = [
  'لا تجعل يوماً صعباً يقنعك أن حياتك كلها صعبة.',
  'بعض الإنجازات تبدأ بقرار صغير لا يراه أحد.',
  'كن واضحاً في نيتك، لطيفاً في كلامك، ثابتاً في مواقفك.',
  'الوقت الذي تستثمره في نفسك لا يضيع.',
  'لا تقِس قيمتك بسرعة وصولك؛ لكل رحلة إيقاعها.',
  'الصديق الحقيقي مساحة أمان، لا ساحة منافسة.',
  'حين لا تستطيع تغيير الظروف، ابدأ بتغيير خطوتك التالية.',
  'ليس كل تأخير خسارة؛ أحياناً هو فرصة للاستعداد.',
  'احفظ الود، لكن لا تهمل كرامتك.',
  'الاعتذار الصادق شجاعة، وتغيير السلوك هو الدليل.',
  'اقرأ قليلاً كل يوم، فالمعرفة تتراكم بهدوء.',
  'لا تسخر من بداية أحد؛ كل خبير كان مبتدئاً.',
  'اجعل حضورك خفيفاً وأثرك عميقاً.',
  'النجاح الذي لا يسلبك إنسانيتك هو الأجمل.',
  'لا تنتظر الحافز دائماً؛ اصنع عادة تساعدك على البدء.',
  'الهدوء ليس غياب المشاعر، بل حسن إدارتها.',
  'من يحترم اختلافك يستحق أن يسمع رأيك.',
  'لا تترك كلمة طيبة في قلبك؛ قلها في وقتها.',
  'التواضع لا يقلل من قيمتك، بل يرفع قدرك.',
  'كل يوم فرصة لتتعلم شيئاً وتصلح شيئاً وتفرح بشيء.',
  'لا تجعل المقارنة تسرق منك متعة التقدم.',
  'أجمل ما في الإنسان أن يكون مأمون الجانب.',
  'اسأل لتفهم، لا لتنتصر في النقاش.',
  'الأمل ليس انتظاراً؛ إنه عمل مع ثقة.',
  'حين تتعب، استرح قليلاً ولا تتخلّ عن الطريق.',
 ];
 List<Map<String,String>> get _builtIns {
  if(widget.collection=='poems') return [
   ...List.generate(200,(i)=>{'text':'${_poemOpen[i%_poemOpen.length]}، ${_poemEnds[(i ~/ _poemOpen.length + i)%_poemEnds.length]}','category':i.isEven?'فصحى':'شعبي','authorName':'مكتبة الملتقى','id':'builtin-poem-$i'}),
   ..._freshPoems.asMap().entries.map((e)=>{'text':e.value,'category':e.key%3==0?'شعبي':'فصحى','authorName':'مكتبة الملتقى • جديد','id':'fresh-poem-${e.key}'}),
  ];
  return [
   ...List.generate(300,(i)=>{'text':'${_quoteOpen[i%_quoteOpen.length]}، ${_quoteEnds[(i ~/ _quoteOpen.length + i)%_quoteEnds.length]}','category':'اقتباسات','authorName':'مكتبة الملتقى','id':'builtin-quote-$i'}),
   ..._freshQuotes.asMap().entries.map((e)=>{'text':e.value,'category':'اقتباسات','authorName':'مكتبة الملتقى • جديد','id':'fresh-quote-${e.key}'}),
  ];
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
   await Gal.putVideo(file.path, album: 'ملتقى الأنمي');
   if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('تم حفظ الفيديو في معرض الجهاز')));
  } catch (_) {
   if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('تعذر تنزيل الفيديو. تحقق من الصلاحية ومساحة الجهاز.')));
  } finally {
   client?.close(force: true);
   if (file != null && await file.exists()) await file.delete();
  }
 }
 Future<void> deleteStory(String id, Map<String,dynamic> data) async {
   final me = FirebaseAuth.instance.currentUser;
   if (me == null || data['authorId'] != me.uid) return;
   final confirm = await showDialog<bool>(context: context, builder: (c) => AlertDialog(
    title: const Text('حذف الستوري؟'), content: const Text('سيتم حذف القصة من الملتقى.'),
    actions: [TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('إلغاء')), FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('حذف'))],
   ));
   if (confirm != true) return;
   try {
    final url = (data['mediaUrl'] ?? '').toString();
    if (url.startsWith('https://')) { try { await deleteForumMedia(url); } catch (_) {} }
    await db2.collection('stories').doc(id).delete();
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حذف الستوري')));
   } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تعذر حذف الستوري: $e'))); }
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
   final u=FirebaseAuth.instance.currentUser!;
   final url=await uploadForumMedia(file,folder:'stories');
   final profile=await db2.collection('publicProfiles').doc(u.uid).get();
   await db2.collection('stories').add({'mediaUrl':url,'mediaType':type,'authorId':u.uid,'authorName':profile.data()?['name']??u.displayName??'عضو','createdAt':FieldValue.serverTimestamp(),'expiresAt':Timestamp.fromDate(DateTime.now().add(const Duration(hours:24)))});
   if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('تم نشر الستوري لمدة 24 ساعة')));
  }on StorageException catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('فشل تخزين الستوري: ${e.message}')));}catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('تعذر نشر الستوري: $e')));}
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
     ListTile(leading:const CircleAvatar(child:Icon(Icons.person)),title:Text(d['authorName'] as String? ??'عضو'),trailing: (d['authorId'] == FirebaseAuth.instance.currentUser?.uid) ? PopupMenuButton<String>(onSelected: (v) { if (v == 'delete') deleteStory(doc.id, d); }, itemBuilder: (_) => const [PopupMenuItem(value:'delete',child:Text('حذف الستوري'))]) : null),
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
 final voiceRecorder=AudioRecorder();
 bool recordingVoice=false;
 DateTime? voiceStartedAt;
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

 Future<void> send({String text='',String? imageUrl,String? audioUrl,int? durationSeconds,String type='text'}) async {
  if((text.trim().isEmpty&&imageUrl==null&&audioUrl==null)||busy)return;
  final me=FirebaseAuth.instance.currentUser!;
  if(await blocked(me.uid)){if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('أنت ممنوع من هذه الغرفة حالياً.')));return;}
  setState(()=>busy=true);
  try{
   final profile=await db2.collection('publicProfiles').doc(me.uid).get();
   await db2.collection('regionalChats').doc(widget.id).collection('messages').add({
    'text':text.trim(),'type':type,if(imageUrl!=null)'imageUrl':imageUrl,if(audioUrl!=null)'audioUrl':audioUrl,if(durationSeconds!=null)'durationSeconds':durationSeconds,
    'senderId':me.uid,'senderRole':founder?'founder':'member',
    'senderName':profile.data()?['name']??me.displayName??'عضو',
    'senderPhoto':profile.data()?['photoUrl']??'',
    'createdAt':FieldValue.serverTimestamp()});
   if(text.isNotEmpty)t.clear();
  }catch(_){if(mounted)setState(()=>error='تعذر الإرسال. تأكد من نشر قواعد Firestore الجديدة.');}
  finally{if(mounted)setState(()=>busy=false);}
 }

 Future<void> sendImage() async {
  try{
   final file=await picker.pickImage(source:ImageSource.gallery);
   if(file==null)return;
   final url=await uploadForumMedia(file,folder:'regional-chat',roomId:widget.id);
   await send(imageUrl:url,type:'image');
  }on StorageException catch(e){if(mounted)setState(()=>error='فشل رفع الصورة (${e.statusCode ?? 'Storage'}): ${e.message}');}catch(e){if(mounted)setState(()=>error='تعذر رفع الصورة: $e');}
 }

 Future<void> toggleVoiceRecording() async {
  if(busy)return;
  if(!recordingVoice){
   try{
    if(!await voiceRecorder.hasPermission()){if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('اسمح للتطبيق باستخدام المايكروفون أولاً.')));return;}
    final dir=await getTemporaryDirectory();
    final path=dir.path+'/regional_voice_'+DateTime.now().microsecondsSinceEpoch.toString()+'.m4a';
    await voiceRecorder.start(const RecordConfig(encoder:AudioEncoder.aacLc,bitRate:64000,sampleRate:44100),path:path);
    if(mounted)setState((){recordingVoice=true;voiceStartedAt=DateTime.now();});
   }catch(e){if(mounted)setState(()=>error='تعذر بدء التسجيل: '+e.toString());}
   return;
  }
  try{
   final started=voiceStartedAt;
   final path=await voiceRecorder.stop();
   if(mounted)setState((){recordingVoice=false;voiceStartedAt=null;});
   if(path==null||started==null)return;
   final elapsed=DateTime.now().difference(started).inSeconds;
   final seconds=elapsed.clamp(1,180).toInt();
   if(mounted)setState(()=>busy=true);
   final url=await uploadForumMedia(XFile(path,name:'regional_voice_'+DateTime.now().microsecondsSinceEpoch.toString()+'.m4a'),folder:'regional-chat',roomId:widget.id);
   if(mounted)setState(()=>busy=false);
   await send(text:'رسالة صوتية',audioUrl:url,durationSeconds:seconds,type:'voice');
  }catch(e){
   if(mounted)setState(()=>error='تعذر إرسال الفويس: '+e.toString());
  }finally{if(mounted)setState(()=>busy=false);}
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
  final audio=d['audioUrl'] as String?;
  final senderPhoto=d['senderPhoto'] as String?;
  return Align(alignment:mine?Alignment.centerRight:Alignment.centerLeft,child:Container(
   margin:const EdgeInsets.symmetric(vertical:5),padding:const EdgeInsets.all(11),
   constraints:BoxConstraints(maxWidth:MediaQuery.of(context).size.width*.88),
   decoration:BoxDecoration(color:mine?const Color(0xFFE8E2FF):Colors.white,borderRadius:BorderRadius.circular(16),
    border:Border.all(color:isFounder?const Color(0xFFE0A72E):const Color(0xFFB9B9C8),width:isFounder?2:1),
    boxShadow:const [BoxShadow(color:Color(0x14000000),blurRadius:5,offset:Offset(0,2))]),
   child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
    if(!mine)Row(mainAxisSize:MainAxisSize.min,children:[
     CircleAvatar(radius:14,backgroundColor:const Color(0xFFEAE6FF),backgroundImage:senderPhoto!=null&&senderPhoto.startsWith('https://')?NetworkImage(senderPhoto):null,child:senderPhoto==null||!senderPhoto.startsWith('https://')?const Icon(Icons.person,size:16,color:Color(0xFF6554D9)):null),
     const SizedBox(width:6),
     Flexible(child:Text(d['senderName'] as String? ?? 'عضو',style:TextStyle(color:isFounder?const Color(0xFF8A5A00):const Color(0xFF4532A8),fontWeight:FontWeight.bold,fontSize:14))),
     if(isFounder)const Padding(padding:EdgeInsets.only(right:4),child:Icon(Icons.workspace_premium,color:Color(0xFFFFB52E),size:15)),
     if(founder)IconButton(visualDensity:VisualDensity.compact,tooltip:'إدارة العضو',icon:const Icon(Icons.admin_panel_settings,size:18),onPressed:()=>moderate(d['senderId'] as String? ?? '',d['senderName'] as String? ?? 'عضو'))
    ]),
    if(type=='voice'&&audio!=null)_RegionVoicePlayer(url:audio,durationSeconds:(d['durationSeconds'] as num?)?.toInt()??0),
    if(type=='image'&&url!=null)ClipRRect(borderRadius:BorderRadius.circular(12),child:Image.network(url,width:230,fit:BoxFit.cover,errorBuilder:(c,e,s)=>const Text('تعذر عرض الصورة'))),
    if(type=='sticker')Center(child:Text(txt,style:const TextStyle(fontSize:46))),
    if(type!='sticker'&&txt.isNotEmpty)Text(txt,style:const TextStyle(fontSize:18,height:1.65,color:Color(0xFF171717),fontWeight:FontWeight.w500))
   ])));
 }

 @override void dispose(){t.dispose();voiceRecorder.dispose();super.dispose();}
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
    IconButton(onPressed:busy?null:toggleVoiceRecording,tooltip:recordingVoice?'إيقاف وإرسال الفويس':'تسجيل فويس',icon:Icon(recordingVoice?Icons.stop_circle:Icons.mic,color:recordingVoice?Colors.red:p)),
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
 static const featuredTracks=[
  {'title':"موسيقى عراقية تراثية",'artist':"تراث عراقي",'category':"عراقي وتراث"},
  {'title':"مقام عراقي – مقام اللامي",'artist':"مقام عراقي",'category':"عراقي وتراث"},
  {'title':"مقام عراقي – مقام الحجاز",'artist':"مقام عراقي",'category':"عراقي وتراث"},
  {'title':"جورج وسوف – كلام الناس",'artist':"جورج وسوف",'category':"طرب عربي"},
  {'title':"كاظم الساهر – زيديني عشقاً",'artist':"كاظم الساهر",'category':"طرب عربي"},
  {'title':"كاظم الساهر – مدرسة الحب",'artist':"كاظم الساهر",'category':"طرب عربي"},
  {'title':"ماجدة الرومي – كلمات",'artist':"ماجدة الرومي",'category':"طرب عربي"},
  {'title':"فيروز – نسم علينا الهوى",'artist':"فيروز",'category':"طرب عربي"},
  {'title':"فيروز – كان عنا طاحون",'artist':"فيروز",'category':"طرب عربي"},
  {'title':"أم كلثوم – ألف ليلة وليلة",'artist':"أم كلثوم",'category':"طرب عربي"},
  {'title':"عبد الحليم حافظ – قارئة الفنجان",'artist':"عبد الحليم حافظ",'category':"طرب عربي"},
  {'title':"محمد عبده – الأماكن",'artist':"محمد عبده",'category':"خليجي"},
  {'title':"راشد الماجد – المسافر",'artist':"راشد الماجد",'category':"خليجي"},
  {'title':"عبد المجيد عبد الله – تتنفسك دنياي",'artist':"عبد المجيد عبد الله",'category':"خليجي"},
  {'title':"أصالة – عيش سكر وطن",'artist':"أصالة",'category':"عربي حديث"},
  {'title':"شيرين – مشاعر",'artist':"شيرين",'category':"عربي حديث"},
  {'title':"عمرو دياب – تملي معاك",'artist':"عمرو دياب",'category':"عربي حديث"},
  {'title':"عمرو دياب – نور العين",'artist':"عمرو دياب",'category':"عربي حديث"},
  {'title':"محمد حماقي – أجمل يوم",'artist':"محمد حماقي",'category':"عربي حديث"},
  {'title':"إليسا – عايشالك",'artist':"إليسا",'category':"عربي حديث"},
  {'title':"نانسي عجرم – يا سلام",'artist':"نانسي عجرم",'category':"عربي حديث"},
  {'title':"حمزة نمرة – داري يا قلبي",'artist':"حمزة نمرة",'category':"عربي حديث"},
  {'title':"أدهم نابلسي – هو الحب",'artist':"أدهم نابلسي",'category':"عربي حديث"},
  {'title':"سيف نبيل – فدوه اروحلك",'artist':"سيف نبيل",'category':"عراقي حديث"},
  {'title':"ماجد المهندس – تناديك",'artist':"ماجد المهندس",'category':"عراقي حديث"},
  {'title':"رحمة رياض – وعد مني",'artist':"رحمة رياض",'category':"عراقي حديث"},
  {'title':"إلهام المدفعي – خيّال",'artist':"إلهام المدفعي",'category':"عراقي وتراث"},
  {'title':"ناظم الغزالي – طالعة من بيت أبوها",'artist':"ناظم الغزالي",'category':"عراقي وتراث"},
  {'title':"سعدون جابر – يا طيور الطايرة",'artist':"سعدون جابر",'category':"عراقي وتراث"},
  {'title':"فؤاد سالم – غريبة الروح",'artist':"فؤاد سالم",'category':"عراقي وتراث"},
  {'title':"The Beatles – Here Comes the Sun",'artist':"The Beatles",'category':"عالمي"},
  {'title':"Queen – Bohemian Rhapsody",'artist':"Queen",'category':"عالمي"},
  {'title':"Coldplay – Viva La Vida",'artist':"Coldplay",'category':"عالمي"},
  {'title':"Ed Sheeran – Perfect",'artist':"Ed Sheeran",'category':"عالمي"},
  {'title':"Adele – Someone Like You",'artist':"Adele",'category':"عالمي"},
  {'title':"Imagine Dragons – Demons",'artist':"Imagine Dragons",'category':"عالمي"},
  {'title':"Ludovico Einaudi – Nuvole Bianche",'artist':"Ludovico Einaudi",'category':"هادئ وآلات"},
  {'title':"Yiruma – River Flows in You",'artist':"Yiruma",'category':"هادئ وآلات"},
  {'title':"Debussy – Clair de Lune",'artist':"Claude Debussy",'category':"كلاسيكي"},
  {'title':"Beethoven – Moonlight Sonata",'artist':"Ludwig van Beethoven",'category':"كلاسيكي"},
  {'title':"Mozart – Eine kleine Nachtmusik",'artist':"Wolfgang Amadeus Mozart",'category':"كلاسيكي"},
  {'title':"Vivaldi – The Four Seasons Spring",'artist':"Antonio Vivaldi",'category':"كلاسيكي"},
  {'title':"Bach – Air on the G String",'artist':"Johann Sebastian Bach",'category':"كلاسيكي"},
  {'title':"Chopin – Nocturne Op.9 No.2",'artist':"Frédéric Chopin",'category':"كلاسيكي"},
  {'title':"Tchaikovsky – Swan Lake",'artist':"Pyotr Ilyich Tchaikovsky",'category':"كلاسيكي"},
  {'title':"Erik Satie – Gymnopédie No.1",'artist':"Erik Satie",'category':"هادئ وآلات"},
  {'title':"Kevin MacLeod – Carefree",'artist':"Kevin MacLeod",'category':"موسيقى مجانية"},
  {'title':"Kevin MacLeod – Monkeys Spinning Monkeys",'artist':"Kevin MacLeod",'category':"موسيقى مجانية"},
  {'title':"Scott Buckley – Signal to Noise",'artist':"Scott Buckley",'category':"موسيقى مجانية"},
  {'title':"Scott Buckley – The Illusionist",'artist':"Scott Buckley",'category':"موسيقى مجانية"},
  {'title':"Chris Zabriskie – Cylinder Seven",'artist':"Chris Zabriskie",'category':"موسيقى مجانية"},
  {'title':"كاظم الساهر – أنا وليلى",'artist':"كاظم الساهر",'category':"طرب عربي"},
  {'title':"كاظم الساهر – هل عندك شك",'artist':"كاظم الساهر",'category':"طرب عربي"},
  {'title':"فيروز – كيفك إنت",'artist':"فيروز",'category':"طرب عربي"},
  {'title':"فيروز – رجعت الشتوية",'artist':"فيروز",'category':"طرب عربي"},
  {'title':"أم كلثوم – أنت عمري",'artist':"أم كلثوم",'category':"طرب عربي"},
  {'title':"أم كلثوم – سيرة الحب",'artist':"أم كلثوم",'category':"طرب عربي"},
  {'title':"عبد الحليم حافظ – جانا الهوى",'artist':"عبد الحليم حافظ",'category':"طرب عربي"},
  {'title':"وردة الجزائرية – بتونس بيك",'artist':"وردة الجزائرية",'category':"طرب عربي"},
  {'title':"صباح فخري – قدك المياس",'artist':"صباح فخري",'category':"طرب عربي"},
  {'title':"ملحم بركات – على بابي واقف قمرين",'artist':"ملحم بركات",'category':"طرب عربي"},
  {'title':"محمد عبده – الأماكن",'artist':"محمد عبده",'category':"خليجي"},
  {'title':"محمد عبده – مذهلة",'artist':"محمد عبده",'category':"خليجي"},
  {'title':"راشد الماجد – ويلي",'artist':"راشد الماجد",'category':"خليجي"},
  {'title':"عبد الله الرويشد – رحلتي",'artist':"عبد الله الرويشد",'category':"خليجي"},
  {'title':"أحلام – تدري ليش",'artist':"أحلام",'category':"خليجي"},
  {'title':"نوال الكويتية – أنت طيب",'artist':"نوال الكويتية",'category':"خليجي"},
  {'title':"حسين الجسمي – أحبك",'artist':"حسين الجسمي",'category':"عربي حديث"},
  {'title':"بلقيس – انتهى",'artist':"بلقيس",'category':"عربي حديث"},
  {'title':"تامر حسني – قرب حبيبي",'artist':"تامر حسني",'category':"عربي حديث"},
  {'title':"مصطفى قمر – السود عيونه",'artist':"مصطفى قمر",'category':"عربي حديث"},
  {'title':"رامي صبري – يمكن خير",'artist':"رامي صبري",'category':"عربي حديث"},
  {'title':"أبو – 3 دقات",'artist':"أبو",'category':"عربي حديث"},
  {'title':"مسار إجباري – نهايات الحكاوي",'artist':"مسار إجباري",'category':"عربي حديث"},
  {'title':"ويجز – البخت",'artist':"ويجز",'category':"عربي حديث"},
  {'title':"عزيز مرقة – مين قال",'artist':"عزيز مرقة",'category':"عربي حديث"},
  {'title':"كاظم الساهر – بغداد",'artist':"كاظم الساهر",'category':"عراقي حديث"},
  {'title':"نصرت البدر – تعال",'artist':"نصرت البدر",'category':"عراقي حديث"},
  {'title':"حسام الرسام – هذا العراق",'artist':"حسام الرسام",'category':"عراقي حديث"},
  {'title':"علي جاسم – عندي احساس",'artist':"علي جاسم",'category':"عراقي حديث"},
  {'title':"محمد السالم – قلب قلب",'artist':"محمد السالم",'category':"عراقي حديث"},
  {'title':"أصيل هميم – سر الحياة",'artist':"أصيل هميم",'category':"عراقي حديث"},
  {'title':"رحمة رياض – أصعد للكمر",'artist':"رحمة رياض",'category':"عراقي حديث"},
  {'title':"سعدون جابر – اعبر على جفوني",'artist':"سعدون جابر",'category':"عراقي وتراث"},
  {'title':"فاضل عواد – لا خبر",'artist':"فاضل عواد",'category':"عراقي وتراث"},
  {'title':"ناظم الغزالي – ميحانة",'artist':"ناظم الغزالي",'category':"عراقي وتراث"},
  {'title':"Elton John – Your Song",'artist':"Elton John",'category':"عالمي"},
  {'title':"Michael Jackson – Billie Jean",'artist':"Michael Jackson",'category':"عالمي"},
  {'title':"ABBA – Dancing Queen",'artist':"ABBA",'category':"عالمي"},
  {'title':"Eagles – Hotel California",'artist':"Eagles",'category':"عالمي"},
  {'title':"John Lennon – Imagine",'artist':"John Lennon",'category':"عالمي"},
  {'title':"Whitney Houston – I Will Always Love You",'artist':"Whitney Houston",'category':"عالمي"},
  {'title':"Bruno Mars – Just the Way You Are",'artist':"Bruno Mars",'category':"عالمي"},
  {'title':"Taylor Swift – Love Story",'artist':"Taylor Swift",'category':"عالمي"},
  {'title':"OneRepublic – Counting Stars",'artist':"OneRepublic",'category':"عالمي"},
  {'title':"Hans Zimmer – Time",'artist':"Hans Zimmer",'category':"موسيقى تصويرية"},
  {'title':"Hans Zimmer – Interstellar Main Theme",'artist':"Hans Zimmer",'category':"موسيقى تصويرية"},
  {'title':"John Williams – Hedwig's Theme",'artist':"John Williams",'category':"موسيقى تصويرية"},
  {'title':"Ennio Morricone – Gabriel's Oboe",'artist':"Ennio Morricone",'category':"موسيقى تصويرية"},
  {'title':"Ramin Djawadi – Light of the Seven",'artist':"Ramin Djawadi",'category':"موسيقى تصويرية"},
 ];
 List<Widget> _featuredCards()=>featuredTracks.map((track)=>Card(child:ListTile(
  leading:const CircleAvatar(child:Icon(Icons.music_note)),
  title:Text(track['title']!),
  subtitle:Text('${track['artist']} • ${track['category']}'),
  trailing:const Icon(Icons.open_in_new),
  onTap:()=>openFeatured(track),
 ))).toList();
 Future<void> openFeatured(Map<String,String> track) async {
  final query='${track['artist']} ${track['title']} official audio';
  final uri=Uri.https('www.youtube.com','/results',{'search_query':query});
  try { await launchUrl(uri,mode:LaunchMode.externalApplication); }
  catch (_) { if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('تعذر فتح نتائج الموسيقى'))); }
 }

 bool validYoutube(String value) => isSupportedYoutubeUrl(value);
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
 Future<void> openVideo(String value, String videoTitle) async {
  if(!validYoutube(value) || !mounted) return;
  Navigator.push(context,MaterialPageRoute(builder:(_)=>YouTubeWatchPage(url:value,title:videoTitle)));
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
     if(s.hasError)return ListView(padding:const EdgeInsets.all(12),children:[const Text('تعذر تحميل روابط الأعضاء حالياً؛ دليل الموسيقى الجاهز متاح أدناه.'),..._featuredCards()]);
     if(!s.hasData)return const Center(child:CircularProgressIndicator());
          return ListView(padding:const EdgeInsets.all(12),children:[
     Card(color:Theme.of(c).colorScheme.primaryContainer,child:const Padding(padding:EdgeInsets.all(14),child:Text('دليل موسيقي جاهز • 100 اختيار من الطرب العراقي والعربي والخليجي والعالمي والكلاسيكي. افتح أي اختيار للبحث عن النسخة الرسمية أو المرخّصة على يوتيوب.',style:TextStyle(fontWeight:FontWeight.w600)))),
     ..._featuredCards(),
     ...s.data!.docs.map((doc){
      final d=doc.data();
      return Card(child:ListTile(
       leading:const CircleAvatar(child:Icon(Icons.play_arrow)),
       title:Text(d['title'] as String? ??'فيديو'),
       subtitle:Text('${d['category']??'متنوع'} • ${d['authorName']??'عضو'}'),
       trailing:IconButton(icon:const Icon(Icons.open_in_new),onPressed:()=>openVideo(d['url'] as String? ??'',d['title'] as String? ?? 'فيديو')),
       onTap:()=>openVideo(d['url'] as String? ??'',d['title'] as String? ?? 'فيديو'),
      ));
     }),
    ]);
    },
   ),
  ),
 );
}


class _RegionVoicePlayer extends StatefulWidget {
 final String url;
 final int durationSeconds;
 const _RegionVoicePlayer({required this.url,required this.durationSeconds});
 @override State<_RegionVoicePlayer> createState()=>_RegionVoicePlayerState();
}
class _RegionVoicePlayerState extends State<_RegionVoicePlayer>{
 late final AudioPlayer player;
 @override void initState(){super.initState();player=AudioPlayer();player.setUrl(widget.url).catchError((Object _) => Duration.zero);}
 @override void dispose(){player.dispose();super.dispose();}
 @override Widget build(BuildContext context)=>SizedBox(width:220,child:Row(children:[
  StreamBuilder<PlayerState>(stream:player.playerStateStream,builder:(c,s){
   final playing=s.data?.playing??false;
   return IconButton(onPressed:()async{if(playing){await player.pause();}else{await player.play();}},icon:Icon(playing?Icons.pause_circle:Icons.play_circle,color:p,size:30));
  }),
  Expanded(child:StreamBuilder<Duration?>(stream:player.durationStream,builder:(c,d){
   final total=d.data??Duration(seconds:widget.durationSeconds);
   return StreamBuilder<Duration>(stream:player.positionStream,builder:(c,pos){
    final current=pos.data??Duration.zero,maximum=total.inMilliseconds;
    return Column(mainAxisSize:MainAxisSize.min,children:[
     Slider(value:maximum<=0?0:current.inMilliseconds.clamp(0,maximum).toDouble(),max:maximum<=0?1:maximum.toDouble(),onChanged:maximum<=0?null:(v)=>player.seek(Duration(milliseconds:v.round()))),
     Text(current.inSeconds.toString()+'s / '+total.inSeconds.toString()+'s',style:const TextStyle(fontSize:10)),
    ]);
   });
  })),
 ]));
}


/// أدوات شخصية خفيفة: حساب العمر والبرج الفلكي للترفيه فقط.
class LifeToolsPage extends StatefulWidget {
 const LifeToolsPage({super.key});
 @override State<LifeToolsPage> createState()=>_LifeToolsPageState();
}
class _LifeToolsPageState extends State<LifeToolsPage> {
 DateTime? birthday;
 String get ageDetail {
  final b=birthday!, now=DateTime.now();
  var years=now.year-b.year, months=now.month-b.month, days=now.day-b.day;
  if(days<0){final previous=DateTime(now.year,now.month,0);days+=previous.day;months--;}
  if(months<0){months+=12;years--;}
  return '$years سنة • $months شهر • $days يوم';
 }
 String get zodiac {
  final d=birthday!; final m=d.month, day=d.day;
  if((m==3&&day>=21)||(m==4&&day<=19))return 'الحمل ♈';
  if((m==4&&day>=20)||(m==5&&day<=20))return 'الثور ♉';
  if((m==5&&day>=21)||(m==6&&day<=20))return 'الجوزاء ♊';
  if((m==6&&day>=21)||(m==7&&day<=22))return 'السرطان ♋';
  if((m==7&&day>=23)||(m==8&&day<=22))return 'الأسد ♌';
  if((m==8&&day>=23)||(m==9&&day<=22))return 'العذراء ♍';
  if((m==9&&day>=23)||(m==10&&day<=22))return 'الميزان ♎';
  if((m==10&&day>=23)||(m==11&&day<=21))return 'العقرب ♏';
  if((m==11&&day>=22)||(m==12&&day<=21))return 'القوس ♐';
  if((m==12&&day>=22)||(m==1&&day<=19))return 'الجدي ♑';
  if((m==1&&day>=20)||(m==2&&day<=18))return 'الدلو ♒';
  return 'الحوت ♓';
 }
 Future<void> chooseBirthday() async {
  final now=DateTime.now();
  final picked=await showDatePicker(context:context,initialDate:birthday??DateTime(now.year-18,now.month,now.day),firstDate:DateTime(1900),lastDate:now,helpText:'اختر تاريخ ميلادك');
  if(picked!=null)setState(()=>birthday=picked);
 }
 @override Widget build(BuildContext context)=>Directionality(textDirection:TextDirection.rtl,child:Scaffold(
  appBar:AppBar(title:const Text('أدوات العمر والأبراج')),
  body:ListView(padding:const EdgeInsets.all(18),children:[
   Card(child:Padding(padding:const EdgeInsets.all(18),child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
    const Icon(Icons.cake_rounded,size:48,color:p),
    const SizedBox(height:8),
    const Text('حاسبة العمر',textAlign:TextAlign.center,style:TextStyle(fontSize:21,fontWeight:FontWeight.bold)),
    const Text('اعرف عمرك بالسنوات والأشهر والأيام',textAlign:TextAlign.center),
    const SizedBox(height:16),
    OutlinedButton.icon(onPressed:chooseBirthday,icon:const Icon(Icons.calendar_month),label:Text(birthday==null?'اختيار تاريخ الميلاد':'تاريخ الميلاد: ${birthday!.year}/${birthday!.month}/${birthday!.day}')),
    if(birthday!=null)...[
     const SizedBox(height:12),
     Text(ageDetail,textAlign:TextAlign.center,style:const TextStyle(fontSize:22,fontWeight:FontWeight.bold,color:p)),
     Text('عمرك بالأيام تقريباً: ${DateTime.now().difference(birthday!).inDays} يوم',textAlign:TextAlign.center),
     const Divider(height:28),
     Text('برجك: $zodiac',textAlign:TextAlign.center,style:const TextStyle(fontSize:24,fontWeight:FontWeight.bold)),
    ]
   ]))),
   const SizedBox(height:12),
   const Card(child:Padding(padding:EdgeInsets.all(16),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
    Text('عن الأبراج',style:TextStyle(fontSize:18,fontWeight:FontWeight.bold)),
    SizedBox(height:8),
    Text('الأبراج هنا للتسلية والتعرّف على التقسيمات الفلكية الشائعة فقط؛ لا تتنبأ بالمستقبل ولا تحدد الشخصية أو القرارات.'),
   ]))),
  ]),
 ));
}
