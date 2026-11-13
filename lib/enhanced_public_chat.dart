
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'advanced_features.dart';
import 'media_upload_service.dart';

const _chatBrand = Color(0xFF6554D9);
const _founderEmail = 'husinalzerjaoe@gmail.com';
final _chatDb = FirebaseFirestore.instance;
bool get _isFounder => FirebaseAuth.instance.currentUser?.email?.toLowerCase() == _founderEmail;

class EnhancedPublicChatPage extends StatefulWidget {
  const EnhancedPublicChatPage({super.key});
  @override State<EnhancedPublicChatPage> createState() => _EnhancedPublicChatPageState();
}

class _EnhancedPublicChatPageState extends State<EnhancedPublicChatPage> with WidgetsBindingObserver {
  final _text = TextEditingController();
  final _picker = ImagePicker();
  bool _sending = false;
  DateTime? _lastSuccessfulSend;
  String? _error;
  static const _blockedTerms = ['كسمك', 'كس امك', 'يلعن دينك', 'قحبة', 'شرموط', 'منيوك'];
  bool _containsBlockedTerm(String value) {
    final normalized = value.toLowerCase().replaceAll(RegExp(r'[\sـ]+'), '');
    return _blockedTerms.any((term) => normalized.contains(term.replaceAll(' ', '')));
  }
  DocumentSnapshot<Map<String, dynamic>>? _reply;
  int _background = 0xFFF5F3FF;
  static const _backgrounds = [0xFFF5F3FF,0xFFEAF6FF,0xFFFFF3E8,0xFFF0F7F1,0xFF171936,0xFFFFF0F5];
  static const _stickers = ['😂','❤️','🔥','😍','😭','👏','✨','🌹','🫶','🤣','🥹','💜','⚽','🐱','🎉','👍','🌟','💯','🥳','🤝'];
  String get _uid => FirebaseAuth.instance.currentUser!.uid;
  DocumentReference<Map<String,dynamic>> get _presence => _chatDb.collection('chatPresence').doc(_uid);

  @override void initState() { super.initState(); WidgetsBinding.instance.addObserver(this); _setPresence(true); _loadBackground(); }
  @override void didChangeAppLifecycleState(AppLifecycleState state) => _setPresence(state == AppLifecycleState.resumed);
  Future<void> _setPresence(bool online) async { try { await _presence.set({'uid':_uid,'online':online,'lastSeen':FieldValue.serverTimestamp()},SetOptions(merge:true)); } catch (_) {} }
  Future<void> _loadBackground() async {
    try { final d=await _chatDb.collection('chatPreferences').doc(_uid).get(); final c=d.data()?['background']; if(mounted && c is int && _backgrounds.contains(c)) setState(()=>_background=c); } catch (_) {}
  }
  @override void dispose() { WidgetsBinding.instance.removeObserver(this); _setPresence(false); _chatDb.collection('chatTyping').doc(_uid).delete().catchError((_){}); _text.dispose(); super.dispose(); }

  Future<String> _name() async {
    final p=await _chatDb.collection('publicProfiles').doc(_uid).get();
    return p.data()?['name'] as String? ?? FirebaseAuth.instance.currentUser?.displayName ?? 'عضو';
  }
  Future<void> _send({String body='',String? mediaUrl,String type='text',bool uploadInProgress=false}) async {
    if((_sending && !uploadInProgress) || (body.trim().isEmpty && mediaUrl==null)) return;
    final now = DateTime.now();
    final last = _lastSuccessfulSend;
    if (last != null && now.difference(last) < const Duration(seconds: 5)) {
      final remaining = 5 - now.difference(last).inSeconds;
      if (mounted) setState(() => _error = 'حتى نحافظ على هدوء الرومات، انتظر $remaining ثواني قبل الرسالة التالية.');
      return;
    }
    if (type == 'text' && _containsBlockedTerm(body)) {
      if (mounted) setState(() => _error = 'رسالتك تحتوي كلمات ممنوعة. عدّلها قبل الإرسال.');
      return;
    }
    setState(()=>_sending=true); setState(()=>_error=null);
    try {
      final senderName = await _name();
      await _chatDb.collection('messages').add({
        'text':body.trim(),'type':type,if(mediaUrl!=null)'imageUrl':mediaUrl,
        'senderId':_uid,'senderRole':_isFounder?'founder':'member','senderName':senderName,
        'createdAt':FieldValue.serverTimestamp(),
        if(_reply!=null)'replyTo':{'messageId':_reply!.id,'senderName':_reply!.data()?['senderName']??'عضو','text':_reply!.data()?['text']??''},
      });
      if (type == 'text') {
        final tags = RegExp(r'@([^\s@]+)').allMatches(body).map((m)=>m.group(1)!).toSet().take(10).toList();
        if (tags.isNotEmpty) {
          final matches = await _chatDb.collection('publicProfiles').where('name', whereIn: tags).limit(10).get();
          for (final profile in matches.docs) {
            if (profile.id == _uid) continue;
            await _chatDb.collection('notifications').add({
              'recipientId':profile.id,'actorId':_uid,'actorName':senderName,
              'type':'mention','text':'أشار إليك في الدردشة العامة','read':false,
              'createdAt':FieldValue.serverTimestamp(),
            });
          }
        }
      }
      _lastSuccessfulSend = DateTime.now();
      _text.clear(); _reply=null;
      await _chatDb.collection('chatTyping').doc(_uid).delete().catchError((_) {});
    } catch (_) { if(mounted)setState(()=>_error='تعذر إرسال الرسالة. تحقق من قواعد Firestore والتخزين.'); }
    finally { if(mounted)setState(()=>_sending=false); }
  }
  Future<void> _sendImage() async {
    try {
      final f=await _picker.pickImage(source:ImageSource.gallery); if(f==null)return;
      setState(()=>_sending=true);
      final url=await uploadForumMedia(f,folder:'public-chat');
      await _send(mediaUrl:url,type:'image',uploadInProgress:true);
    } on StorageException catch(e) { if(mounted)setState(()=>_error='فشل رفع الصورة: ${e.message}'); } catch(e) { if(mounted)setState(()=>_error='تعذر رفع الصورة: $e'); }
    finally { if(mounted)setState(()=>_sending=false); }
  }
  Future<void> _showStickers() async {
    final v=await showModalBottomSheet<String>(context:context,showDragHandle:true,builder:(c)=>Directionality(textDirection:TextDirection.rtl,child:Padding(padding:const EdgeInsets.all(16),child:Column(mainAxisSize:MainAxisSize.min,children:[
      const Text('الملصقات',style:TextStyle(fontSize:18,fontWeight:FontWeight.bold)),
      GridView.count(shrinkWrap:true,crossAxisCount:5,physics:const NeverScrollableScrollPhysics(),children:_stickers.map((e)=>InkWell(onTap:()=>Navigator.pop(c,e),child:Center(child:Text(e,style:const TextStyle(fontSize:32))))).toList())
    ]))));
    if(v!=null)await _send(body:v,type:'sticker');
  }
  Future<void> _react(String id,String emoji) async {
    final r=_chatDb.collection('messages').doc(id).collection('reactions').doc(_uid);
    final old=await r.get(); if(old.data()?['emoji']==emoji){await r.delete();}else{await r.set({'uid':_uid,'emoji':emoji,'updatedAt':FieldValue.serverTimestamp()});}
  }
  Future<void> _menu(DocumentSnapshot<Map<String,dynamic>> doc) async {
    final d=doc.data()??{}; final mine=d['senderId']==_uid; final staff=_isFounder || (await _chatDb.collection('chatModerators').doc(_uid).get()).exists;
    final a=await showModalBottomSheet<String>(context:context,showDragHandle:true,builder:(c)=>Directionality(textDirection:TextDirection.rtl,child:Column(mainAxisSize:MainAxisSize.min,children:[
      ListTile(leading:const Icon(Icons.reply),title:const Text('رد'),onTap:()=>Navigator.pop(c,'reply')),
      if(mine&&d['type']=='text')ListTile(leading:const Icon(Icons.edit),title:const Text('تعديل'),onTap:()=>Navigator.pop(c,'edit')),
      if(staff)ListTile(leading:const Icon(Icons.push_pin),title:Text(d['isPinned']==true?'إلغاء التثبيت':'تثبيت'),onTap:()=>Navigator.pop(c,'pin')),
      if(mine||staff)ListTile(leading:const Icon(Icons.delete,color:Colors.red),title:const Text('حذف'),onTap:()=>Navigator.pop(c,'delete')),
    ])));
    if(a=='reply'&&mounted)setState(()=>_reply=doc);
    if(a=='pin'&&staff)await doc.reference.update({'isPinned':d['isPinned']!=true,'pinnedBy':_uid});
    if(a=='delete'&&(mine||staff))await doc.reference.delete();
    if(a=='edit'&&mounted){
      final t=TextEditingController(text:d['text'] as String? ?? '');
      final v=await showDialog<String>(context:context,builder:(c)=>Directionality(textDirection:TextDirection.rtl,child:AlertDialog(title:const Text('تعديل الرسالة'),content:TextField(controller:t,maxLength:1000,maxLines:3),actions:[
        TextButton(onPressed:()=>Navigator.pop(c),child:const Text('إلغاء')),FilledButton(onPressed:()=>Navigator.pop(c,t.text.trim()),child:const Text('حفظ'))
      ])));
      if(v!=null&&v.isNotEmpty)await doc.reference.update({'text':v,'edited':true,'editedAt':FieldValue.serverTimestamp()});t.dispose();
    }
  }
  void _snack(String s){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(s)));}

  Future<void> _grant({String? presetUid}) async {
    final profiles=await _chatDb.collection('publicProfiles').limit(100).get();
    final uid=TextEditingController(text:presetUid??''); final days=TextEditingController(text:'7'); final reason=TextEditingController(text:'هدية من المؤسس');
    final ok=await showDialog<bool>(context:context,builder:(c)=>Directionality(textDirection:TextDirection.rtl,child:AlertDialog(title:const Text('منح عضوية مجانية'),content:Column(mainAxisSize:MainAxisSize.min,children:[
      DropdownButtonFormField<String>(isExpanded:true,decoration:const InputDecoration(labelText:'اختيار عضو'),items:profiles.docs.map((p)=>DropdownMenuItem(value:p.id,child:Text(p.data()['name'] as String? ?? p.id,overflow:TextOverflow.ellipsis))).toList(),onChanged:(v){if(v!=null)uid.text=v;}),
      TextField(controller:uid,decoration:const InputDecoration(labelText:'UID العضو (يُملأ عند الاختيار)')),
      TextField(controller:days,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'المدة بالأيام')),
      TextField(controller:reason,decoration:const InputDecoration(labelText:'السبب')),
    ]),actions:[TextButton(onPressed:()=>Navigator.pop(c,false),child:const Text('إلغاء')),FilledButton(onPressed:()=>Navigator.pop(c,true),child:const Text('منح'))])));
    if(ok==true){
      final n=int.tryParse(days.text.trim())??0;
      if(uid.text.trim().isEmpty||n<1||n>365){_snack('UID مطلوب والمدة من 1 إلى 365 يوماً');}
      else{
        await _chatDb.collection('memberships').doc(uid.text.trim()).set({
          'uid':uid.text.trim(),'tier':'premium','source':'founder_gift','reason':reason.text.trim(),'grantedBy':_uid,
          'startedAt':FieldValue.serverTimestamp(),'expiresAt':Timestamp.fromDate(DateTime.now().add(Duration(days:n))),
          'updatedAt':FieldValue.serverTimestamp(),
        });
        _snack('تم منح العضوية لمدة '+n.toString()+' يوم');
      }
    }
    uid.dispose();days.dispose();reason.dispose();
  }
  Future<void> _contest() async {
    final title=TextEditingController(text:'مسابقة الأسبوع');final details=TextEditingController();
    final ok=await showDialog<bool>(context:context,builder:(c)=>Directionality(textDirection:TextDirection.rtl,child:AlertDialog(title:const Text('إنشاء مسابقة'),content:Column(mainAxisSize:MainAxisSize.min,children:[
      TextField(controller:title,decoration:const InputDecoration(labelText:'العنوان')),
      TextField(controller:details,maxLines:3,decoration:const InputDecoration(labelText:'الشروط والتفاصيل')),
    ]),actions:[TextButton(onPressed:()=>Navigator.pop(c,false),child:const Text('إلغاء')),FilledButton(onPressed:()=>Navigator.pop(c,true),child:const Text('إنشاء'))])));
    if(ok==true&&title.text.trim().isNotEmpty){
      await _chatDb.collection('weeklyContests').add({'title':title.text.trim(),'details':details.text.trim(),'createdBy':_uid,'createdAt':FieldValue.serverTimestamp(),'endsAt':Timestamp.fromDate(DateTime.now().add(const Duration(days:7))),'status':'open'});
      _snack('تم نشر المسابقة لمدة أسبوع');
    }
    title.dispose();details.dispose();
  }
  Future<void> _entries(String id) async {
    final s=await _chatDb.collection('weeklyContests').doc(id).collection('entries').get();if(!mounted)return;
    await showModalBottomSheet<void>(context:context,showDragHandle:true,builder:(c)=>Directionality(textDirection:TextDirection.rtl,child:ListView(shrinkWrap:true,children:[
      const ListTile(title:Text('المشاركون')),
      ...s.docs.map((e)=>ListTile(title:Text(e.id,overflow:TextOverflow.ellipsis),trailing:TextButton(onPressed:()async{
        Navigator.pop(c);await _grant(presetUid:e.id);
        await _chatDb.collection('weeklyContests').doc(id).update({'status':'completed','winnerUid':e.id,'winnerChosenAt':FieldValue.serverTimestamp()});
      },child:const Text('اختيار الفائز ومنحه 7 أيام'))))
    ])));
  }
  Future<void> _join(String id) async {
    await _chatDb.collection('weeklyContests').doc(id).collection('entries').doc(_uid).set({'uid':_uid,'joinedAt':FieldValue.serverTimestamp()});
    _snack('تم تسجيل اشتراكك');
  }
  Future<void> _moderator() async {
    final uid=TextEditingController();final ok=await showDialog<bool>(context:context,builder:(c)=>Directionality(textDirection:TextDirection.rtl,child:AlertDialog(title:const Text('إضافة مشرف'),content:TextField(controller:uid,decoration:const InputDecoration(labelText:'UID العضو')),actions:[
      TextButton(onPressed:()=>Navigator.pop(c,false),child:const Text('إلغاء')),FilledButton(onPressed:()=>Navigator.pop(c,true),child:const Text('إضافة'))
    ])));
    if(ok==true&&uid.text.trim().isNotEmpty)await _chatDb.collection('chatModerators').doc(uid.text.trim()).set({'uid':uid.text.trim(),'grantedBy':_uid,'createdAt':FieldValue.serverTimestamp()});
    uid.dispose();
  }
  Future<void> _founderTools() async {
    await showModalBottomSheet<void>(context:context,showDragHandle:true,builder:(c)=>Directionality(textDirection:TextDirection.rtl,child:SafeArea(child:Wrap(children:[
      const ListTile(title:Text('لوحة المؤسس',style:TextStyle(fontWeight:FontWeight.bold))),
      ListTile(leading:const Icon(Icons.card_membership),title:const Text('منح عضوية مجانية'),onTap:(){Navigator.pop(c);_grant();}),
      ListTile(leading:const Icon(Icons.emoji_events),title:const Text('إنشاء مسابقة أسبوعية'),onTap:(){Navigator.pop(c);_contest();}),
      ListTile(leading:const Icon(Icons.people),title:const Text('إضافة مشرف'),onTap:(){Navigator.pop(c);_moderator();}),
    ]))));
  }

  Future<void> _showMemberActions(Map<String, dynamic> data) async {
    final memberUid = (data['senderId'] ?? '').toString();
    final memberName = (data['senderName'] ?? 'عضو').toString();
    if (memberUid.isEmpty || memberUid == _uid) return;
    final action = await showModalBottomSheet<String>(
      context: context, showDragHandle: true,
      builder: (c) => Directionality(textDirection: TextDirection.rtl,
        child: SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(leading: const CircleAvatar(child: Icon(Icons.person)), title: Text(memberName), subtitle: const Text('اختر الإجراء')),
          ListTile(leading: const Icon(Icons.account_circle_outlined), title: const Text('عرض الملف الشخصي'), onTap: () => Navigator.pop(c, 'profile')),
          ListTile(leading: const Icon(Icons.chat_bubble_outline), title: const Text('مراسلة خاصة'), onTap: () => Navigator.pop(c, 'message')),
          ListTile(leading: const Icon(Icons.flag_outlined), title: const Text('إبلاغ عن العضو'), onTap: () => Navigator.pop(c, 'report')),
          ListTile(leading: const Icon(Icons.block_outlined), title: const Text('حظر العضو'), onTap: () => Navigator.pop(c, 'block')),
        ])),
      ),
    );
    if (!mounted || action == null) return;
    if (action == 'profile') {
      Navigator.push(context, MaterialPageRoute(builder: (_) => ChatMemberProfilePage(uid: memberUid, fallbackName: memberName)));
    } else if (action == 'message') {
      final id = _uid.compareTo(memberUid) < 0 ? '${_uid}_${memberUid}' : '${memberUid}_${_uid}';
      final ref = _chatDb.collection('conversations').doc(id);
      final existing = await ref.get();
      if (!existing.exists) {
        final me = await _chatDb.collection('publicProfiles').doc(_uid).get();
        await ref.set({'members': [_uid, memberUid], 'memberNames': {
          _uid: me.data()?['name'] ?? FirebaseAuth.instance.currentUser?.displayName ?? 'عضو',
          memberUid: memberName,
        }, 'updatedAt': FieldValue.serverTimestamp()});
      }
      if (mounted) Navigator.push(context, MaterialPageRoute(builder: (_) => DirectChatPage(conversationId: id, otherUid: memberUid, otherName: memberName)));
    } else if (action == 'report') {
      final reason = await showDialog<String>(context: context, builder: (c) => Directionality(textDirection: TextDirection.rtl,
        child: SimpleDialog(title: const Text('سبب الإبلاغ'), children: ['إساءة أو تنمّر', 'محتوى غير مناسب', 'إزعاج أو رسائل مزعجة', 'سبب آخر']
          .map((v) => SimpleDialogOption(onPressed: () => Navigator.pop(c, v), child: Text(v))).toList())));
      if (reason != null) {
        await _chatDb.collection('reports').add({'type': 'user', 'reportedUserId': memberUid, 'reporterId': _uid, 'reason': reason, 'status': 'new', 'createdAt': FieldValue.serverTimestamp()});
        _snack('وصل بلاغك للإدارة');
      }
    } else if (action == 'block') {
      await _chatDb.collection('users').doc(_uid).collection('blockedUsers').doc(memberUid).set({'uid': memberUid, 'name': memberName, 'createdAt': FieldValue.serverTimestamp()});
      _snack('تم حظر العضو');
    }
  }

  Widget _bubble(DocumentSnapshot<Map<String,dynamic>> doc){
    final d=doc.data()??{};final mine=d['senderId']==_uid;final sender=(d['senderId']??'').toString();
    final founder=d['senderRole']=='founder' || (d['senderEmail']??'').toString().toLowerCase()==_founderEmail;
    final type=d['type'] as String? ?? 'text';final body=d['text'] as String? ?? '';
    final reply=d['replyTo'] as Map<String,dynamic>?;
    return GestureDetector(onLongPress:()=>_menu(doc),child:Align(alignment:mine?Alignment.centerRight:Alignment.centerLeft,child:Container(
      constraints:BoxConstraints(maxWidth:MediaQuery.of(context).size.width*.90),margin:const EdgeInsets.symmetric(vertical:6),padding:const EdgeInsets.all(10),
      decoration:BoxDecoration(color:mine?const Color(0xFFE8E2FF):Colors.white,borderRadius:BorderRadius.circular(17),border:Border.all(color:founder?const Color(0xFFE0A72E):_chatBrand.withValues(alpha:.42),width:founder?2:1),boxShadow:const [BoxShadow(color:Color(0x14000000),blurRadius:5,offset:Offset(0,2))]),
      child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        if(d['isPinned']==true)const Text('📌 مثبتة',style:TextStyle(fontSize:10)),
        Row(mainAxisSize:MainAxisSize.min,children:[
          GestureDetector(onTap:()=>_showMemberActions(d),child:StreamBuilder<DocumentSnapshot<Map<String,dynamic>>>(
            stream:_chatDb.collection('publicProfiles').doc(sender).snapshots(),
            builder:(context,profile){final photo=profile.data?.data()?['photoUrl'] as String? ?? d['senderPhoto'] as String?;return Container(
              padding:EdgeInsets.all(founder?2:1),decoration:BoxDecoration(shape:BoxShape.circle,border:Border.all(color:founder?const Color(0xFFFFC94A):_chatBrand,width:founder?2:1)),
              child:CircleAvatar(radius:19,backgroundColor:_chatBrand.withValues(alpha:.12),backgroundImage:photo!=null&&photo.startsWith('http')?NetworkImage(photo):null,child:photo==null||!photo.startsWith('http')?Text((d['senderName'] as String? ?? 'ع').characters.first):null));
            }),
          ),
          const SizedBox(width:8),
          Flexible(child:GestureDetector(onTap:()=>_showMemberActions(d),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
            Text(d['senderName'] as String? ?? 'عضو',style:TextStyle(fontWeight:FontWeight.bold,fontSize:13,color:founder?const Color(0xFF8A5A00):const Color(0xFF4532A8))),
            if(founder)const Text('المؤسس والمالك',style:TextStyle(fontSize:10,color:Color(0xFFB77900),fontWeight:FontWeight.bold)),
            if(d['edited']==true)const Text('معدّلة',style:TextStyle(fontSize:10,color:Colors.grey)),
          ]))),
          if(founder)const Icon(Icons.workspace_premium,color:Color(0xFFFFB52E),size:19),
        ]),
        const SizedBox(height:6),
        if(reply!=null)Text('رد على '+(reply['senderName']??'عضو').toString()+': '+(reply['text']??'مرفق').toString(),maxLines:2,overflow:TextOverflow.ellipsis,style:const TextStyle(fontSize:11)),
        if(type=='image'&&d['imageUrl'] is String)ClipRRect(borderRadius:BorderRadius.circular(12),child:Image.network(d['imageUrl'] as String,width:230,fit:BoxFit.cover,errorBuilder:(_,__,___)=>const Text('تعذر عرض الصورة'))),
        if(type=='sticker')Center(child:Text(body,style:const TextStyle(fontSize:48))),
        if(type=='text'&&body.isNotEmpty)Text(body,style:const TextStyle(fontSize:18,height:1.65,color:Color(0xFF171717),fontWeight:FontWeight.w500)),
        Row(mainAxisSize:MainAxisSize.min,children:[
          ...['❤️','😂','🔥','👏'].map((e)=>InkWell(onTap:()=>_react(doc.id,e),child:Padding(padding:const EdgeInsets.all(3),child:Text(e)))),
          StreamBuilder<QuerySnapshot<Map<String,dynamic>>>(stream:doc.reference.collection('reactions').snapshots(),builder:(c,s){
            final counts=<String,int>{};for(final r in s.data?.docs??[]){final e=r.data()['emoji'] as String? ?? '';counts[e]=(counts[e]??0)+1;}
            return Text(counts.entries.map((e)=>e.key+e.value.toString()).join(' '),style:const TextStyle(fontSize:11));
          }),
          IconButton(visualDensity:VisualDensity.compact,onPressed:()=>_menu(doc),icon:const Icon(Icons.more_horiz,size:17)),
        ]),
      ]),
    )));
  }

  @override Widget build(BuildContext context)=>Directionality(textDirection:TextDirection.rtl,child:Column(children:[
    Container(padding:const EdgeInsets.symmetric(horizontal:12,vertical:10),decoration:const BoxDecoration(gradient:LinearGradient(colors:[Color(0xFF171936),Color(0xFF5144B8),Color(0xFF8C7CF0)])),child:Row(children:[
      const Icon(Icons.forum,color:Colors.white,size:30),const SizedBox(width:9),
      const Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('الساحة العامة',style:TextStyle(color:Colors.white,fontWeight:FontWeight.bold,fontSize:17)),Text('صور • GIF • ملصقات • مسابقات',style:TextStyle(color:Colors.white70,fontSize:11))])),
      StreamBuilder<QuerySnapshot<Map<String,dynamic>>>(stream:_chatDb.collection('chatPresence').where('online',isEqualTo:true).snapshots(),builder:(c,s)=>Text((s.data?.docs.length??0).toString()+' متصل',style:const TextStyle(color:Colors.white,fontSize:11))),
      IconButton(onPressed:()=>showModalBottomSheet<void>(context:context,builder:(c)=>Wrap(children:_backgrounds.map((v)=>ListTile(leading:CircleAvatar(backgroundColor:Color(v)),title:Text('خلفية الدردشة'),onTap:(){Navigator.pop(c);setState(()=>_background=v);_chatDb.collection('chatPreferences').doc(_uid).set({'background':v},SetOptions(merge:true));})).toList())),icon:const Icon(Icons.palette,color:Colors.white)),
      if(_isFounder)IconButton(onPressed:_founderTools,icon:const Icon(Icons.admin_panel_settings,color:Color(0xFFFFD166))),
    ])),
    StreamBuilder<QuerySnapshot<Map<String,dynamic>>>(stream:_chatDb.collection('weeklyContests').where('status',isEqualTo:'open').limit(3).snapshots(),builder:(c,s){
      if(!s.hasData||s.data!.docs.isEmpty)return const SizedBox.shrink();
      return Column(children:s.data!.docs.map((d)=>Container(color:const Color(0xFFFFF3CD),child:ListTile(dense:true,leading:const Icon(Icons.emoji_events,color:Colors.orange),title:Text(d.data()['title'] as String? ?? 'مسابقة الأسبوع'),subtitle:Text(d.data()['details'] as String? ?? 'شارك واربح عضوية'),trailing:TextButton(onPressed:()=>_join(d.id),child:const Text('اشترك')),onLongPress:_isFounder?()=>_entries(d.id):null))).toList());
    }),
    Expanded(child:Container(color:Color(_background),child:StreamBuilder<QuerySnapshot<Map<String,dynamic>>>(stream:_chatDb.collection('messages').orderBy('createdAt',descending:true).limit(100).snapshots(),builder:(c,s){
      if(s.hasError)return const Center(child:Text('تعذر تحميل الدردشة. راجع قواعد Firestore.'));
      if(!s.hasData)return const Center(child:CircularProgressIndicator());
      if(s.data!.docs.isEmpty)return const Center(child:Text('ابدأ أول محادثة في الساحة ✨'));
      return ListView(reverse:true,padding:const EdgeInsets.all(12),children:s.data!.docs.map(_bubble).toList());
    }))),
    StreamBuilder<QuerySnapshot<Map<String,dynamic>>>(stream:_chatDb.collection('chatTyping').where('typing',isEqualTo:true).snapshots(),builder:(c,s){
      final n=(s.data?.docs??[]).where((d)=>d.id!=_uid).length;
      return n>0?const Padding(padding:EdgeInsets.all(3),child:Text('أحد الأعضاء يكتب الآن...',style:TextStyle(fontSize:11,color:_chatBrand))):const SizedBox.shrink();
    }),
    if(_reply!=null)ListTile(dense:true,leading:const Icon(Icons.reply),title:Text('الرد على '+(_reply!.data()?['senderName']??'عضو').toString()),trailing:IconButton(onPressed:()=>setState(()=>_reply=null),icon:const Icon(Icons.close))),
    if(_error!=null)Text(_error!,style:const TextStyle(color:Colors.red,fontSize:11)),
    Container(color:Colors.white,padding:const EdgeInsets.symmetric(horizontal:5,vertical:4),child:SafeArea(top:false,child:Row(children:[
      IconButton(onPressed:_sending?null:_sendImage,icon:const Icon(Icons.image,color:_chatBrand)),
      IconButton(onPressed:_sending?null:_showStickers,icon:const Icon(Icons.emoji_emotions,color:Colors.orange)),
      Expanded(child:TextField(controller:_text,maxLength:1000,minLines:1,maxLines:4,textInputAction:TextInputAction.send,
        onChanged:(v)=>_chatDb.collection('chatTyping').doc(_uid).set({'uid':_uid,'typing':v.trim().isNotEmpty,'updatedAt':FieldValue.serverTimestamp()},SetOptions(merge:true)).catchError((_){}),
        onSubmitted:(_)=>_send(body:_text.text),decoration:const InputDecoration(hintText:'اكتب رسالتك... استخدم @ للإشارة',counterText:'',border:InputBorder.none))),
      IconButton(onPressed:_sending?null:()=>_send(body:_text.text),icon:_sending?const CircularProgressIndicator():const Icon(Icons.send,color:_chatBrand)),
    ]))),
  ]));
}


class ChatMemberProfilePage extends StatelessWidget {
  final String uid, fallbackName;
  const ChatMemberProfilePage({super.key, required this.uid, required this.fallbackName});
  String get _uid => FirebaseAuth.instance.currentUser!.uid;
  @override Widget build(BuildContext context) => Directionality(textDirection: TextDirection.rtl, child: Scaffold(
    appBar: AppBar(title: const Text('الملف الشخصي')),
    body: StreamBuilder<DocumentSnapshot<Map<String,dynamic>>>(stream:_chatDb.collection('publicProfiles').doc(uid).snapshots(),builder:(context,s){
      if(!s.hasData)return const Center(child:CircularProgressIndicator());
      final d=s.data!.data()??{};
      final name=d['name'] as String? ?? fallbackName;
      final photo=d['photoUrl'] as String?;
      return ListView(padding:const EdgeInsets.all(20),children:[
        Center(child:CircleAvatar(radius:52,backgroundImage:photo!=null&&photo.startsWith('http')?NetworkImage(photo):null,child:photo==null||!photo.startsWith('http')?const Icon(Icons.person,size:52):null)),
        const SizedBox(height:12),Center(child:Text(name,style:const TextStyle(fontSize:23,fontWeight:FontWeight.bold))),
        if((d['bio'] as String? ?? '').isNotEmpty)Center(child:Text(d['bio'] as String)),
        const SizedBox(height:16),
        FilledButton.icon(onPressed:()async{
          final id=_uid.compareTo(uid)<0?'${_uid}_${uid}':'${uid}_${_uid}';
          final ref=_chatDb.collection('conversations').doc(id);final old=await ref.get();
          if(!old.exists){final me=await _chatDb.collection('publicProfiles').doc(_uid).get();await ref.set({'members':[_uid,uid],'memberNames':{_uid:me.data()?['name']??'عضو',uid:name},'updatedAt':FieldValue.serverTimestamp()});}
          if(context.mounted)Navigator.push(context,MaterialPageRoute(builder:(_)=>DirectChatPage(conversationId:id,otherUid:uid,otherName:name)));
        },icon:const Icon(Icons.message),label:const Text('مراسلة')),
      ]);
    }),
  ));
}
