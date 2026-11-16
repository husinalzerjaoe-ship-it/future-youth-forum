import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _v12Ink=Color(0xFF11162D),_v12Violet=Color(0xFF927CFF),_v12Aqua=Color(0xFF42D9E8);

class V12PersonalStudioPage extends StatefulWidget{
  const V12PersonalStudioPage({super.key});
  @override State<V12PersonalStudioPage> createState()=>_V12PersonalStudioPageState();
}
class _V12PersonalStudioPageState extends State<V12PersonalStudioPage> with SingleTickerProviderStateMixin{
  late final TabController _tabs;
  final _name=TextEditingController(),_bio=TextEditingController(),_title=TextEditingController(),_draft=TextEditingController(),_diary=TextEditingController();
  List<String> _drafts=[],_entries=[];
  bool _dailyDigest=true,_eventAlerts=true,_socialAlerts=true,_ready=false;
  int _frame=0;
  static const _frames=[Color(0xFF927CFF),Color(0xFF42D9E8),Color(0xFFFFC56E),Color(0xFFFF83B5)];
  @override void initState(){super.initState();_tabs=TabController(length:4,vsync:this);_load();}
  @override void dispose(){_tabs.dispose();_name.dispose();_bio.dispose();_title.dispose();_draft.dispose();_diary.dispose();super.dispose();}
  Future<void> _load()async{
    final p=await SharedPreferences.getInstance();if(!mounted)return;
    setState((){
      _name.text=p.getString('v12_profile_name')??'';
      _bio.text=p.getString('v12_profile_bio')??'';
      _title.text=p.getString('v12_profile_title')??'';
      _frame=p.getInt('v12_profile_frame')??0;
      _drafts=p.getStringList('v12_creator_drafts')??[];
      _entries=p.getStringList('v12_private_diary')??[];
      _dailyDigest=p.getBool('v12_daily_digest')??true;
      _eventAlerts=p.getBool('v12_event_alerts')??true;
      _socialAlerts=p.getBool('v12_social_alerts')??true;
      _ready=true;
    });
  }
  Future<void> _saveProfile()async{
    final p=await SharedPreferences.getInstance();
    await p.setString('v12_profile_name',_name.text.trim());
    await p.setString('v12_profile_bio',_bio.text.trim());
    await p.setString('v12_profile_title',_title.text.trim());
    await p.setInt('v12_profile_frame',_frame);
    final user=FirebaseAuth.instance.currentUser;
    if(user!=null){
      try{
        final ref=FirebaseFirestore.instance.collection('publicProfiles').doc(user.uid);
        final snap=await ref.get();
        final payload={
          'name':_name.text.trim().isEmpty?(user.displayName??'عضو'):_name.text.trim(),
          'bio':_bio.text.trim(),
          'photoUrl':(snap.data()?['photoUrl']??'').toString(),
        };
        if(snap.exists){
          await ref.update(payload);
        }else{
          await ref.set({...payload,'createdAt':FieldValue.serverTimestamp()});
        }
        if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('تم حفظ الاسم والنبذة في ملفك العام، والإطار واللقب محلياً.')));
      }catch(_){
        if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('حُفظت المعاينة على الجهاز، لكن تعذرت مزامنة الملف العام. تحقق من قواعد Firestore.')));
      }
    }else if(mounted){
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('تم حفظ معاينة ملفك محلياً على هذا الجهاز')));
    }
  }
  Future<void> _publishDraft(int index)async{
    if(index<0||index>=_drafts.length)return;
    final user=FirebaseAuth.instance.currentUser;
    if(user==null){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('سجّل الدخول أولاً حتى تنشر المسودة.')));return;}
    final value=_drafts[index].trim();
    if(value.isEmpty||value.length>1000){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('المنشور لازم يكون بين حرف واحد و1000 حرف.')));return;}
    try{
      await FirebaseFirestore.instance.collection('posts').add({
        'authorId':user.uid,
        'authorName':user.displayName??(_name.text.trim().isNotEmpty?_name.text.trim():'عضو'),
        'text':value,
        'createdAt':FieldValue.serverTimestamp(),
      });
      setState(()=>_drafts.removeAt(index));
      final p=await SharedPreferences.getInstance();
      await p.setStringList('v12_creator_drafts',_drafts);
      if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('تم نشر المسودة في المنشورات وإزالتها من قائمة المسودات.')));
    }catch(error){
      if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('تعذر نشر المسودة. تحقق من قواعد Firestore.')));
    }
  }
  Future<void> _addDraft()async{
    final value=_draft.text.trim();if(value.isEmpty)return;
    setState(()=>_drafts.insert(0,value));_draft.clear();
    final p=await SharedPreferences.getInstance();await p.setStringList('v12_creator_drafts',_drafts);
  }
  Future<void> _addDiary()async{
    final value=_diary.text.trim();if(value.isEmpty)return;
    setState(()=>_entries.insert(0,value));_diary.clear();
    final p=await SharedPreferences.getInstance();await p.setStringList('v12_private_diary',_entries);
  }
  Future<void> _setPref(String key,bool value)async{
    final p=await SharedPreferences.getInstance();await p.setBool(key,value);
    if(!mounted)return;setState((){
      if(key=='v12_daily_digest')_dailyDigest=value;
      if(key=='v12_event_alerts')_eventAlerts=value;
      if(key=='v12_social_alerts')_socialAlerts=value;
    });
  }
  @override Widget build(BuildContext context)=>Directionality(textDirection:TextDirection.rtl,child:Scaffold(
    backgroundColor:_v12Ink,
    appBar:AppBar(title:const Text('استوديو المستقبل'),backgroundColor:_v12Ink,foregroundColor:Colors.white,bottom:TabBar(controller:_tabs,indicatorColor:_v12Aqua,labelColor:Colors.white,unselectedLabelColor:Colors.white54,tabs:const[Tab(text:'هويتي',icon:Icon(Icons.person_outline)),Tab(text:'المحتوى',icon:Icon(Icons.create)),Tab(text:'يومياتي',icon:Icon(Icons.book_outlined)),Tab(text:'التنبيهات',icon:Icon(Icons.notifications_outlined))])),
    body:!_ready?const Center(child:CircularProgressIndicator()):TabBarView(controller:_tabs,children:[_profileTab(),_creatorTab(),_diaryTab(),_notificationsTab()]),
  ));
  Widget _profileTab()=>ListView(padding:const EdgeInsets.all(16),children:[
    const Text('صمّم بطاقة هويتك',style:TextStyle(color:Colors.white,fontSize:19,fontWeight:FontWeight.w900)),
    const SizedBox(height:12),
    Container(padding:const EdgeInsets.all(18),decoration:BoxDecoration(borderRadius:BorderRadius.circular(22),gradient:LinearGradient(colors:[_frames[_frame].withValues(alpha:.35),const Color(0xFF202746)]),border:Border.all(color:_frames[_frame])),child:Column(children:[
      CircleAvatar(radius:35,backgroundColor:_frames[_frame],child:const Icon(Icons.person,size:38,color:Colors.white)),
      const SizedBox(height:10),Text(_name.text.isEmpty?'اسمك المستعار':_name.text,style:const TextStyle(color:Colors.white,fontSize:19,fontWeight:FontWeight.w900)),
      Text(_title.text.isEmpty?'لقبك':_title.text,style:TextStyle(color:_frames[_frame],fontWeight:FontWeight.w700)),
      if(_bio.text.isNotEmpty)Padding(padding:const EdgeInsets.only(top:8),child:Text(_bio.text,textAlign:TextAlign.center,style:const TextStyle(color:Colors.white70))),
    ])),
    const SizedBox(height:16),_field(_name,'الاسم الظاهر',Icons.badge_outlined),_field(_title,'لقب أو وصف قصير',Icons.military_tech),_field(_bio,'نبذة عنك',Icons.notes,max:3),
    const Text('لون إطار البطاقة',style:TextStyle(color:Colors.white,fontWeight:FontWeight.bold)),
    const SizedBox(height:8),Wrap(spacing:12,children:List.generate(_frames.length,(i)=>InkWell(onTap:(){setState(()=>_frame=i);},child:CircleAvatar(radius:19,backgroundColor:_frames[i],child:_frame==i?const Icon(Icons.check,color:Colors.white):null)))),
    const SizedBox(height:16),FilledButton.icon(onPressed:_saveProfile,icon:const Icon(Icons.save),label:const Text('حفظ الهوية على هذا الجهاز')),
    const Padding(padding:EdgeInsets.only(top:8),child:Text('الاسم والنبذة يتزامنان مع ملفك العام عند نجاح الاتصال؛ اللقب ولون الإطار محفوظان محلياً.',style:TextStyle(color:Colors.white54,fontSize:11))),
  ]);
  Widget _field(TextEditingController c,String label,IconData icon,{int max=1})=>Padding(padding:const EdgeInsets.only(bottom:10),child:TextField(controller:c,maxLines:max,style:const TextStyle(color:Colors.white),decoration:InputDecoration(labelText:label,labelStyle:const TextStyle(color:Colors.white60),prefixIcon:Icon(icon,color:_v12Aqua),onChanged:(_)=>setState((){}),filled:true,fillColor:const Color(0xFF1B223E),border:OutlineInputBorder(borderRadius:BorderRadius.circular(14),borderSide:BorderSide.none))));
  Widget _creatorTab()=>ListView(padding:const EdgeInsets.all(16),children:[
    const Text('ورشة صناعة المحتوى',style:TextStyle(color:Colors.white,fontSize:19,fontWeight:FontWeight.w900)),
    const Text('اكتب أفكار منشورات أو سيناريوهات أو مسابقات واحفظ مسوداتك محلياً.',style:TextStyle(color:Colors.white60)),
    const SizedBox(height:14),TextField(controller:_draft,maxLines:4,style:const TextStyle(color:Colors.white),decoration:InputDecoration(hintText:'اكتب فكرتك هنا...',hintStyle:const TextStyle(color:Colors.white38),filled:true,fillColor:const Color(0xFF1B223E),border:OutlineInputBorder(borderRadius:BorderRadius.circular(16)))),
    const SizedBox(height:10),FilledButton.icon(onPressed:_addDraft,icon:const Icon(Icons.add),label:const Text('حفظ المسودة')),
    const SizedBox(height:16),..._drafts.asMap().entries.map((e)=>Card(color:const Color(0xFF1B223E),child:ListTile(title:Text(e.value,style:const TextStyle(color:Colors.white)),leading:const Icon(Icons.lightbulb_outline,color:_v12Aqua),trailing:Wrap(children:[IconButton(tooltip:'نشر المسودة',icon:const Icon(Icons.send_rounded,color:_v12Aqua),onPressed:()=>_publishDraft(e.key)),IconButton(icon:const Icon(Icons.delete_outline,color:Colors.white54),onPressed:()async{setState(()=>_drafts.removeAt(e.key));final p=await SharedPreferences.getInstance();await p.setStringList('v12_creator_drafts',_drafts);})]))))
  ]);

  Widget _notificationsTab()=>ListView(padding:const EdgeInsets.all(16),children:[
    const Text('تفضيلات التنبيهات',style:TextStyle(color:Colors.white,fontSize:19,fontWeight:FontWeight.w900)),
    const Text('احفظ اختياراتك لتجربة تنبيهات أكثر ملاءمة. هذه مفاتيح تفضيل محلية حالياً وليست نظام إشعارات دفع.',style:TextStyle(color:Colors.white60)),
    const SizedBox(height:12),
    SwitchListTile(value:_dailyDigest,onChanged:(v)=>_setPref('v12_daily_digest',v),title:const Text('ملخص النشاط اليومي',style:TextStyle(color:Colors.white)),activeColor:_v12Aqua),
    SwitchListTile(value:_eventAlerts,onChanged:(v)=>_setPref('v12_event_alerts',v),title:const Text('تذكيرات الفعاليات',style:TextStyle(color:Colors.white)),activeColor:_v12Aqua),
    SwitchListTile(value:_socialAlerts,onChanged:(v)=>_setPref('v12_social_alerts',v),title:const Text('تنبيهات التفاعل الاجتماعي',style:TextStyle(color:Colors.white)),activeColor:_v12Aqua),
  ]);
  Widget _diaryTab()=>ListView(padding:const EdgeInsets.all(16),children:[
    const Text('دفتر ذكرياتي الخاص',style:TextStyle(color:Colors.white,fontSize:19,fontWeight:FontWeight.w900)),
    const Text('ملاحظات شخصية محفوظة محلياً على جهازك.',style:TextStyle(color:Colors.white60)),
    const SizedBox(height:14),TextField(controller:_diary,maxLines:4,style:const TextStyle(color:Colors.white),decoration:InputDecoration(hintText:'اكتب ذكرى أو فكرة تريد الاحتفاظ بها...',hintStyle:const TextStyle(color:Colors.white38),filled:true,fillColor:const Color(0xFF1B223E),border:OutlineInputBorder(borderRadius:BorderRadius.circular(16)))),
    const SizedBox(height:10),FilledButton.icon(onPressed:_addDiary,icon:const Icon(Icons.bookmark_add_outlined),label:const Text('حفظ الذكرى')),
    const SizedBox(height:14),..._entries.asMap().entries.map((e)=>Card(color:const Color(0xFF1B223E),child:ListTile(title:Text(e.value,style:const TextStyle(color:Colors.white)),leading:const Icon(Icons.favorite_border,color:_v12Violet),trailing:IconButton(icon:const Icon(Icons.delete_outline,color:Colors.white54),onPressed:()async{setState(()=>_entries.removeAt(e.key));final p=await SharedPreferences.getInstance();await p.setStringList('v12_private_diary',_entries);}))))
  ]);
}
