
import 'dart:io';
import 'package:record/record.dart';
import 'package:just_audio/just_audio.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:video_player/video_player.dart';
import 'advanced_features.dart';
import 'media_upload_service.dart';
import 'v31_member_titles.dart';
import 'local_bot.dart';

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
  final _searchController = TextEditingController();
  bool _showSearchBar = false;
  final _picker = ImagePicker();
  bool _sending = false;
  bool _mentionPickerOpen = false;
  final AudioRecorder _voiceRecorder = AudioRecorder();
  bool _recordingVoice = false;
  DateTime? _voiceStartedAt;
  String? _voiceTempPath;
  DateTime? _lastSuccessfulSend;
  String? _error;
  String? _pulseMessageId;
  String _searchQuery = '';
  static const _blockedTerms = ['كسمك', 'كس امك', 'يلعن دينك', 'قحبة', 'شرموط', 'منيوك'];
  bool _containsBlockedTerm(String value) {
    final normalized = value.toLowerCase().replaceAll(RegExp(r'[\sـ]+'), '');
    return _blockedTerms.any((term) => normalized.contains(term.replaceAll(' ', '')));
  }
  DocumentSnapshot<Map<String, dynamic>>? _reply;
  int _background = 0xFFF5F3FF;
  static const _backgrounds = [0xFFF5F3FF,0xFFEAF6FF,0xFFFFF3E8,0xFFF0F7F1,0xFF171936,0xFFFFF0F5,0xFFEDE7F6,0xFFE0F2F1,0xFFFFF8E1,0xFFE3F2FD,0xFF263238,0xFFFCE4EC];
  static const _stickers = ['😂','❤️','🔥','😍','😭','👏','✨','🌹','🫶','🤣','🥹','💜','⚽','🐱','🎉','👍','🌟','💯','🥳','🤝'];
  String get _uid => FirebaseAuth.instance.currentUser!.uid;
  DocumentReference<Map<String,dynamic>> get _presence => _chatDb.collection('chatPresence').doc(_uid);

  @override void initState() { super.initState(); WidgetsBinding.instance.addObserver(this); _setPresence(true); _loadBackground(); }
  @override void didChangeAppLifecycleState(AppLifecycleState state) => _setPresence(state == AppLifecycleState.resumed);
  Future<void> _setPresence(bool online) async { try { await _presence.set({'uid':_uid,'online':online,'lastSeen':FieldValue.serverTimestamp()},SetOptions(merge:true)); } catch (_) {} }
  Future<void> _loadBackground() async {
    try { final d=await _chatDb.collection('chatPreferences').doc(_uid).get(); final c=d.data()?['background']; if(mounted && c is int && _backgrounds.contains(c)) setState(()=>_background=c); } catch (_) {}
  }
  @override void dispose() { WidgetsBinding.instance.removeObserver(this); _setPresence(false); _chatDb.collection('chatTyping').doc(_uid).delete().catchError((_){}); _text.dispose(); _searchController.dispose(); _voiceRecorder.dispose(); super.dispose(); }

  Future<String> _name() async {
    final p=await _chatDb.collection('publicProfiles').doc(_uid).get();
    return p.data()?['name'] as String? ?? FirebaseAuth.instance.currentUser?.displayName ?? 'عضو';
  }
  Future<void> _showMentionPicker() async {
    _mentionPickerOpen = true;
    try {
      final profiles = await _chatDb.collection('publicProfiles').limit(80).get();
      if (!mounted) return;
      final selected = await showModalBottomSheet<Map<String, dynamic>>(
        context: context, isScrollControlled: true, showDragHandle: true,
        builder: (sheetContext) => Directionality(
          textDirection: TextDirection.rtl,
          child: SafeArea(child: SizedBox(height: MediaQuery.of(sheetContext).size.height * .62,
            child: Column(children: [
              const Padding(padding: EdgeInsets.all(14), child: Text('اختَر عضواً للإشارة إليه', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
              Expanded(child: ListView(children: profiles.docs.where((p) => p.id != _uid).map((p) {
                final d = p.data();
                final name = (d['name'] ?? 'عضو').toString();
                final photo = (d['photoUrl'] ?? '').toString();
                return ListTile(
                  leading: CircleAvatar(backgroundImage: photo.startsWith('http') ? NetworkImage(photo) : null,
                    child: !photo.startsWith('http') ? const Icon(Icons.person) : null),
                  title: Text(name),
                  subtitle: const Text('إضافة منشن إلى الرسالة'),
                  onTap: () => Navigator.pop(sheetContext, {'uid': p.id, 'name': name}),
                );
              }).toList())),
            ]),
          )),
        ),
      );
      if (selected != null && mounted) {
        final current = _text.text;
        final at = current.lastIndexOf('@');
        final prefix = at >= 0 ? current.substring(0, at) : current;
        final mentionName = (selected['name'] ?? 'عضو').toString().replaceAll(RegExp(r'\s+'), '_');
        final insertion = '@$mentionName ';
        final next = prefix + insertion;
        _text.value = TextEditingValue(text: next, selection: TextSelection.collapsed(offset: next.length));
        await _chatDb.collection('chatTyping').doc(_uid).set({
          'uid': _uid, 'typing': true, 'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    } catch (_) {
      if (mounted) _snack('تعذر تحميل قائمة الأعضاء حالياً');
    } finally {
      _mentionPickerOpen = false;
    }
  }

  Future<void> _send({String body='',String? mediaUrl,String type='text',bool uploadInProgress=false,int? durationSeconds,String? mediaFormat}) async {
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
      final controls = (await _chatDb.collection('chatControls').doc('main').get()).data() ?? {};
      if (controls['publicChatEnabled'] == false) {
        if (mounted) setState(() => _error = 'الدردشة العامة متوقفة مؤقتاً من الإدارة.');
        return;
      }
      if (type != 'text' && type != 'sticker' && controls['allowMedia'] == false) {
        if (mounted) setState(() => _error = 'إرسال الوسائط متوقف حالياً من الإدارة.');
        return;
      }
      if (type == 'text' && controls['allowLinks'] == false && RegExp(r'https?://', caseSensitive: false).hasMatch(body)) {
        if (mounted) setState(() => _error = 'نشر الروابط متوقف حالياً من الإدارة.');
        return;
      }
      final sanction = (await _chatDb.collection('userSanctions').doc(_uid).get()).data() ?? {};
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      final muteUntil = sanction['muteUntil'] is Timestamp ? (sanction['muteUntil'] as Timestamp).millisecondsSinceEpoch : 0;
      final banUntil = sanction['banUntil'] is Timestamp ? (sanction['banUntil'] as Timestamp).millisecondsSinceEpoch : 0;
      if (sanction['permanentBan'] == true || banUntil > nowMs) {
        if (mounted) setState(() => _error = 'حسابك محظور من المشاركة حالياً. راجع الإدارة.');
        return;
      }
      if (sanction['permanentMute'] == true || muteUntil > nowMs) {
        if (mounted) setState(() => _error = 'تم كتم حسابك مؤقتاً أو دائماً، لا يمكنك إرسال الرسائل.');
        return;
      }
      final senderName = await _name();
      final membership = (await _chatDb.collection('memberships').doc(_uid).get()).data() ?? {};
      final expiry = membership['expiresAt'];
      final membershipTier = expiry is Timestamp && expiry.toDate().isAfter(DateTime.now()) ? (membership['tier'] ?? 'premium').toString() : '';
      final sentMessage = await _chatDb.collection('messages').add({
        'text':body.trim(),'type':type,if(mediaUrl!=null)(type=='voice'?'audioUrl':type=='video'?'videoUrl':type=='gif'?'gifUrl':'imageUrl'):mediaUrl,if(mediaFormat!=null)'mediaFormat':mediaFormat,if(durationSeconds!=null)'durationSeconds':durationSeconds,
        'senderId':_uid,'senderRole':_isFounder?'founder':'member','senderName':senderName,
        if (membershipTier.isNotEmpty) 'membershipTier': membershipTier,
        'createdAt':FieldValue.serverTimestamp(),
        if(_reply!=null)'replyTo':{'messageId':_reply!.id,'senderName':_reply!.data()?['senderName']??'عضو','text':_reply!.data()?['text']??''},
      });
      if (type == 'text') {
        final tags = RegExp(r'@([^\s@]+)').allMatches(body).map((m)=>m.group(1)!.replaceAll('_', ' ')).toSet().take(10).toList();
        if (tags.isNotEmpty) {
          final matches = await _chatDb.collection('publicProfiles').where('name', whereIn: tags).limit(10).get();
          for (final profile in matches.docs) {
            if (profile.id == _uid) continue;
            await _chatDb.collection('notifications').add({
              'recipientId':profile.id,'actorId':_uid,'actorName':senderName,
              'type':'mention','text':'أشار إليك في الدردشة العامة','read':false,
              'targetType':'publicMessage','targetId':sentMessage.id,'messageId':sentMessage.id,
              'createdAt':FieldValue.serverTimestamp(),
            });
          }
        }
      }
      _lastSuccessfulSend = DateTime.now();
      _text.clear(); _reply=null;
      await _chatDb.collection('chatTyping').doc(_uid).delete().catchError((_) => null);
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
  Future<void> _handleKeyboardMedia(KeyboardInsertedContent content) async {
    final bytes = content.data;
    if (bytes == null || bytes.isEmpty) {
      _snack('لوحة المفاتيح لم توفر بيانات الملصق؛ استخدم زر GIF داخل التطبيق');
      return;
    }
    final ext = content.mimeType == 'image/gif' ? 'gif'
        : content.mimeType == 'image/webp' ? 'webp'
        : content.mimeType == 'image/png' ? 'png' : 'jpg';
    try {
      if (mounted) setState(() { _sending = true; _error = null; });
      final dir = await Directory.systemTemp.createTemp('forum_keyboard_media_');
      final file = File('${dir.path}/keyboard_sticker.$ext');
      await file.writeAsBytes(bytes, flush: true);
      final url = await uploadForumMedia(XFile(file.path, name: 'keyboard_sticker.$ext'), folder: 'public-chat');
      await _send(body: 'ملصق من لوحة المفاتيح', mediaUrl: url, type: 'image',
        uploadInProgress: true, mediaFormat: content.mimeType);
      try { await file.delete(); await dir.delete(); } catch (_) {}
    } catch (e) {
      if (mounted) setState(() => _error = 'تعذر إرسال ملصق لوحة المفاتيح: $e');
    } finally { if (mounted) setState(() => _sending = false); }
  }

  Future<void> _sendGif() async {
    if (_sending) return;
    try {
      final picked = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['gif'],
        allowMultiple: false,
        withData: false,
      );
      final file = picked?.files.single;
      final path = file?.path;
      if (file == null || path == null) {
        if (file != null) _snack('تعذر قراءة ملف GIF من الجهاز');
        return;
      }
      if (file.size > 15 * 1024 * 1024) {
        _snack('حجم GIF يجب ألا يتجاوز 15 ميغابايت');
        return;
      }
      if (mounted) setState(() { _sending = true; _error = null; });
      final url = await uploadForumMedia(XFile(path, name: file.name), folder: 'public-chat');
      await _send(body: 'GIF متحرك', mediaUrl: url, type: 'image',
        mediaFormat: 'gif', uploadInProgress: true);
    } catch (e) {
      if (mounted) setState(() => _error = 'تعذر إرسال GIF: $e');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _sendVideo() async {
    if (_sending) return;
    try {
      final file = await _picker.pickVideo(source: ImageSource.gallery, maxDuration: const Duration(minutes: 3));
      if (file == null) return;
      if (mounted) setState(() { _sending = true; _error = null; });
      final url = await uploadForumMedia(file, folder: 'public-chat');
      await _send(body: 'فيديو', mediaUrl: url, type: 'video', uploadInProgress: true);
    } catch (e) { if (mounted) setState(() => _error = 'تعذر إرسال الفيديو: $e'); }
    finally { if (mounted) setState(() => _sending = false); }
  }

  Future<void> _toggleVoiceRecording() async {
    if (_sending) return;
    if (!_recordingVoice) {
      try {
        if (!await _voiceRecorder.hasPermission()) {
          _snack('اسمح للتطبيق باستخدام المايك حتى تسجل فويس');
          return;
        }
        final dir = await Directory.systemTemp.createTemp('forum_voice_');
        final path = '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
        await _voiceRecorder.start(
          const RecordConfig(encoder: AudioEncoder.aacLc, bitRate: 64000, sampleRate: 44100),
          path: path,
        );
        if (mounted) setState(() { _recordingVoice = true; _voiceStartedAt = DateTime.now(); _voiceTempPath = path; });
      } catch (e) {
        _snack('تعذر تشغيل التسجيل: $e');
      }
      return;
    }
    try {
      final path = await _voiceRecorder.stop();
      final started = _voiceStartedAt;
      if (mounted) setState(() { _recordingVoice = false; _voiceStartedAt = null; });
      final filePath = path ?? _voiceTempPath;
      if (filePath == null || started == null) return;
      final seconds = DateTime.now().difference(started).inSeconds;
      if (seconds < 1) { _snack('التسجيل قصير جداً'); return; }
      if (seconds > 180) { _snack('الحد الأقصى للرسالة الصوتية 3 دقائق'); return; }
      final file = File(filePath);
      if (!await file.exists() || await file.length() == 0) { _snack('ملف التسجيل فارغ'); return; }
      if (mounted) setState(() => _sending = true);
      final url = await uploadForumMedia(
        XFile(filePath, name: 'voice_${DateTime.now().millisecondsSinceEpoch}.m4a'),
        folder: 'public-chat',
      );
      await _send(body: 'رسالة صوتية', mediaUrl: url, type: 'voice', uploadInProgress: true, durationSeconds: seconds);
      try { await file.delete(); } catch (_) {}
    } catch (e) {
      if (mounted) setState(() { _recordingVoice = false; _voiceStartedAt = null; _error = 'تعذر إرسال الفويس: $e'; });
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  static const Map<String, List<String>> _stickerPacks = {
    'ضحك ومشاعر': ['😂','🤣','😹','🥹','😭','😍','🥰','😘','😎','🤩','😱','🤯','😴','🤔','🙄','😅','😆','😇','🥳','🤗','🫠','😤','😡','🤫','🫣','😏','🤭','😋','😜','🤪'],
    'حب وقلوب': ['❤️','🩷','🧡','💛','💚','💙','💜','🖤','🤍','🤎','💖','💗','💓','💞','💕','💘','💝','💟','❣️','💌','🌹','🌷','🌸','💐','🫶','😘','💋','✨','💍','🥰'],
    'ردود وتفاعل': ['👍','👎','👏','🙌','🤝','🙏','💪','👌','✌️','🤟','🫡','🫰','🖐️','👋','🫵','💯','🔥','⭐','🌟','🎉','🎊','🏆','🥇','✅','❌','💡','📌','👀','🤌','🫂'],
    'حيوانات ولطافة': ['🐱','🐈','🐶','🐼','🐻','🐨','🦊','🐸','🐵','🐰','🐹','🐣','🐥','🦄','🐧','🦋','🐢','🐬','🦁','🐯','🐮','🐷','🐙','🦖','🐾','🌈','🍓','🍉','🍒','🍕'],
    'العاب ورياضة': ['⚽','🏀','🏐','🎮','🕹️','🎯','🎲','♟️','🏓','🎧','🎤','🎬','🎨','🚀','🌙','☀️','⚡','💎','👑','🛸','🏁','🎸','🥁','🎹','🏅','🏹','🧩','🪄','📚','🎓'],
  };

  Future<void> _showStickers() async {
    final selected = await showModalBottomSheet<String>(
      context: context, isScrollControlled: true, showDragHandle: true,
      builder: (c) => Directionality(
        textDirection: TextDirection.rtl,
        child: SizedBox(
          height: MediaQuery.of(c).size.height * .62,
          child: DefaultTabController(
            length: _stickerPacks.length,
            child: Column(children: [
              const Padding(padding: EdgeInsets.all(12), child: Text('حزم الملصقات',
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold))),
              TabBar(isScrollable: true, tabs: _stickerPacks.keys.map((name) => Tab(text: name)).toList()),
              Expanded(child: TabBarView(children: _stickerPacks.values.map((pack) =>
                GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 5, mainAxisSpacing: 8, crossAxisSpacing: 8),
                  itemCount: pack.length,
                  itemBuilder: (ctx, i) => InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => Navigator.pop(c, pack[i]),
                    child: Container(
                      decoration: BoxDecoration(color: const Color(0xFFF1EDFF),
                        borderRadius: BorderRadius.circular(14)),
                      alignment: Alignment.center,
                      child: Text(pack[i], style: const TextStyle(fontSize: 31)),
                    ),
                  ),
                )).toList())),
              const Padding(padding: EdgeInsets.only(bottom: 12),
                child: Text('وتكدر ترسل GIF متحرك من ملفات جهازك', style: TextStyle(color: Colors.grey))),
            ]),
          ),
        ),
      ),
    );
    if (selected != null) await _send(body: selected, type: 'sticker');
  }
  Future<void> _react(String id,String emoji) async {
    final r=_chatDb.collection('messages').doc(id).collection('reactions').doc(_uid);
    final old=await r.get(); if(old.data()?['emoji']==emoji){await r.delete();}else{await r.set({'uid':_uid,'emoji':emoji,'updatedAt':FieldValue.serverTimestamp()});}
  }
  Future<void> _menu(DocumentSnapshot<Map<String,dynamic>> doc) async {
    final d=doc.data()??{}; final mine=d['senderId']==_uid; final staff=_isFounder || (await _chatDb.collection('chatModerators').doc(_uid).get()).exists;
    final a=await showModalBottomSheet<String>(context:context,showDragHandle:true,builder:(c)=>Directionality(textDirection:TextDirection.rtl,child:Column(mainAxisSize:MainAxisSize.min,children:[
      ListTile(leading:const Icon(Icons.reply),title:const Text('رد'),onTap:()=>Navigator.pop(c,'reply')),
      if((d['text'] as String? ?? '').trim().isNotEmpty)ListTile(leading:const Icon(Icons.copy),title:const Text('نسخ الرسالة'),onTap:()=>Navigator.pop(c,'copy')),
      if(!mine)ListTile(leading:const Icon(Icons.flag_outlined,color:Colors.deepOrange),title:const Text('إبلاغ عن الرسالة'),onTap:()=>Navigator.pop(c,'report')),
      if(mine&&d['type']=='text')ListTile(leading:const Icon(Icons.edit),title:const Text('تعديل'),onTap:()=>Navigator.pop(c,'edit')),
      if(staff)ListTile(leading:const Icon(Icons.push_pin),title:Text(d['isPinned']==true?'إلغاء التثبيت':'تثبيت'),onTap:()=>Navigator.pop(c,'pin')),
      if(mine||staff)ListTile(leading:const Icon(Icons.delete,color:Colors.red),title:const Text('حذف'),onTap:()=>Navigator.pop(c,'delete')),
    ])));
    if(a=='reply'&&mounted)setState(()=>_reply=doc);
    if(a=='copy'){
      await Clipboard.setData(ClipboardData(text:(d['text'] as String? ?? '').trim()));
      _snack('تم نسخ الرسالة');
    }
    if(a=='report'&&!mine&&mounted){
      final reason=TextEditingController();
      final selected=await showDialog<String>(context:context,builder:(c)=>Directionality(textDirection:TextDirection.rtl,child:AlertDialog(
        title:const Text('الإبلاغ عن رسالة'),
        content:Column(mainAxisSize:MainAxisSize.min,children:[
          const Text('اختر سبب الإبلاغ أو اكتب تفاصيل إضافية'),
          const SizedBox(height:8),
          Wrap(spacing:6,children:['إساءة أو تنمّر','محتوى غير لائق','إزعاج أو رسائل متكررة','انتحال شخصية'].map((v)=>ActionChip(label:Text(v),onPressed:()=>Navigator.pop(c,v))).toList()),
          TextField(controller:reason,maxLength:180,maxLines:2,decoration:const InputDecoration(labelText:'تفاصيل إضافية (اختياري)')),
        ]),
        actions:[TextButton(onPressed:()=>Navigator.pop(c),child:const Text('إلغاء')),FilledButton(onPressed:()=>Navigator.pop(c,reason.text.trim()),child:const Text('إرسال البلاغ'))],
      )));
      if(selected!=null){
        final reportReason='رسالة ${doc.id}: ${selected.isEmpty?'مراجعة الرسالة':selected}';
        await _chatDb.collection('reports').add({
          'reporterId':_uid,'targetId':(d['senderId']??'').toString(),
          'reason':reportReason.substring(0,reportReason.length.clamp(0,300)),
          'status':'new','createdAt':FieldValue.serverTimestamp(),
        });
        _snack('وصل بلاغك للإدارة، شكراً لتنبيهنا');
      }
      reason.dispose();
    }
    if(a=='pin'&&staff)await doc.reference.update({'isPinned':d['isPinned']!=true,'pinnedBy':_uid});
    if(a=='delete'&&(mine||staff)){
      final mediaUrl = (d['imageUrl'] ?? d['audioUrl'] ?? d['videoUrl'])?.toString();
      if (mine && mediaUrl != null && mediaUrl.startsWith('https://')) { try { await deleteForumMedia(mediaUrl); } catch (_) {} }
      await doc.reference.delete();
    }
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
    final uid=TextEditingController(text:presetUid??''); final days=TextEditingController(text:'7'); final reason=TextEditingController(text:'هدية من المؤسس'); final tier=TextEditingController(text:'gold');
    final ok=await showDialog<bool>(context:context,builder:(c)=>Directionality(textDirection:TextDirection.rtl,child:AlertDialog(title:const Text('منح عضوية مجانية'),content:Column(mainAxisSize:MainAxisSize.min,children:[
      DropdownButtonFormField<String>(isExpanded:true,decoration:const InputDecoration(labelText:'اختيار عضو'),items:profiles.docs.map((p)=>DropdownMenuItem(value:p.id,child:Text(p.data()['name'] as String? ?? p.id,overflow:TextOverflow.ellipsis))).toList(),onChanged:(v){if(v!=null)uid.text=v;}),
      TextField(controller:uid,decoration:const InputDecoration(labelText:'UID العضو (يُملأ عند الاختيار)')),
      DropdownButtonFormField<String>(value:'gold',decoration:const InputDecoration(labelText:'نوع العضوية'),items:const [DropdownMenuItem(value:'silver',child:Text('فضية')),DropdownMenuItem(value:'gold',child:Text('ذهبية')),DropdownMenuItem(value:'diamond',child:Text('ماسية'))],onChanged:(v){if(v!=null)tier.text=v;}),
      TextField(controller:days,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'المدة بالأيام')),
      TextField(controller:reason,decoration:const InputDecoration(labelText:'السبب')),
    ]),actions:[TextButton(onPressed:()=>Navigator.pop(c,false),child:const Text('إلغاء')),FilledButton(onPressed:()=>Navigator.pop(c,true),child:const Text('منح'))])));
    if(ok==true){
      final n=int.tryParse(days.text.trim())??0;
      if(uid.text.trim().isEmpty||n<1||n>365){_snack('UID مطلوب والمدة من 1 إلى 365 يوماً');}
      else{
        await _chatDb.collection('memberships').doc(uid.text.trim()).set({
          'uid':uid.text.trim(),'tier':tier.text,'source':'founder_gift','reason':reason.text.trim(),'grantedBy':_uid,
          'startedAt':FieldValue.serverTimestamp(),'expiresAt':Timestamp.fromDate(DateTime.now().add(Duration(days:n))),
          'updatedAt':FieldValue.serverTimestamp(),
        });
        final target=uid.text.trim();
        final profile=(await _chatDb.collection('publicProfiles').doc(target).get()).data()??{};
        final targetName=(profile['name']??'عضو').toString();
        final tierName={'silver':'الفضية','gold':'الذهبية','diamond':'الماسية'}[tier.text]??'المميزة';
        final founderName=await _name();
        await _chatDb.collection('messages').add({'text':'🎉 أعلنوا معنا! قام $founderName بمنح $targetName العضوية $tierName لمدة $n يوم. مبارك له!','type':'text','senderId':_uid,'senderRole':'founder','senderName':founderName,'createdAt':FieldValue.serverTimestamp()});
        await _chatDb.collection('adminLogs').add({'actorId':_uid,'targetId':target,'action':'grant_membership_${tier.text}','durationDays':n,'createdAt':FieldValue.serverTimestamp()});
        _snack('تم منح العضوية $tierName لمدة '+n.toString()+' يوم');
      }
    }
    uid.dispose();days.dispose();reason.dispose();tier.dispose();
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

  Future<void> _moderateMember(String targetUid, String targetName, String kind) async {
    final options = <String, Duration?>{
      'ساعة واحدة': const Duration(hours: 1),
      '24 ساعة': const Duration(hours: 24),
      '7 أيام': const Duration(days: 7),
      'دائم': null,
    };
    final selected = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (c) => Directionality(
        textDirection: TextDirection.rtl,
        child: SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(title: Text(kind == 'mute' ? 'كتم $targetName' : 'حظر $targetName')),
          ...options.keys.map((label) => ListTile(
            leading: const Icon(Icons.timer_outlined),
            title: Text(label),
            onTap: () => Navigator.pop(c, label),
          )),
        ])),
      ),
    );
    if (selected == null) return;
    final duration = options[selected];
    final now = DateTime.now();
    final until = duration == null ? null : Timestamp.fromDate(now.add(duration));
    final ref = _chatDb.collection('userSanctions').doc(targetUid);
    final fields = <String, dynamic>{
      'uid': targetUid,
      'updatedBy': _uid,
      'reason': 'إجراء إداري من الدردشة',
      'updatedAt': FieldValue.serverTimestamp(),
      if (kind == 'mute') ...{
        'permanentMute': duration == null,
        'muteUntil': until,
      } else ...{
        'permanentBan': duration == null,
        'banUntil': until,
      },
    };
    await ref.set(fields, SetOptions(merge: true));
    await _chatDb.collection('adminLogs').add({
      'actorId': _uid,
      'targetId': targetUid,
      'action': kind == 'mute' ? 'mute' : 'ban',
      'duration': selected,
      'createdAt': FieldValue.serverTimestamp(),
    });
    _snack(kind == 'mute'
        ? 'تم كتم $targetName ($selected)'
        : 'تم حظر $targetName ($selected)');
  }

  Future<void> _showMemberActions(Map<String, dynamic> data) async {
    final memberUid = (data['senderId'] ?? '').toString();
    final memberName = (data['senderName'] ?? 'عضو').toString();
    if (memberUid.isEmpty || memberUid == _uid) return;
    final staff = _isFounder || (await _chatDb.collection('chatModerators').doc(_uid).get()).exists;
    final action = await showModalBottomSheet<String>(
      context: context, showDragHandle: true,
      builder: (c) => Directionality(textDirection: TextDirection.rtl,
        child: SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(leading: const CircleAvatar(child: Icon(Icons.person)), title: Text(memberName), subtitle: const Text('اختر الإجراء')),
          ListTile(leading: const Icon(Icons.account_circle_outlined), title: const Text('عرض الملف الشخصي'), onTap: () => Navigator.pop(c, 'profile')),
          ListTile(leading: const Icon(Icons.chat_bubble_outline), title: const Text('مراسلة خاصة'), onTap: () => Navigator.pop(c, 'message')),
          ListTile(leading: const Icon(Icons.flag_outlined), title: const Text('إبلاغ عن العضو'), onTap: () => Navigator.pop(c, 'report')),
          ListTile(leading: const Icon(Icons.block_outlined), title: const Text('حظر العضو عندي'), onTap: () => Navigator.pop(c, 'block')),
          if (staff) ListTile(leading: const Icon(Icons.volume_off_outlined), title: const Text('كتم العضو'), onTap: () => Navigator.pop(c, 'mute')),
          if (staff) ListTile(leading: const Icon(Icons.gavel_outlined), title: const Text('حظر العضو من الملتقى'), onTap: () => Navigator.pop(c, 'ban')),
          if (staff) ListTile(leading: const Icon(Icons.lock_open_outlined), title: const Text('رفع الكتم والحظر'), onTap: () => Navigator.pop(c, 'clear')),
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
        await _chatDb.collection('reports').add({'type': 'user', 'targetId': memberUid, 'reporterId': _uid, 'reason': reason, 'status': 'new', 'createdAt': FieldValue.serverTimestamp()});
        _snack('وصل بلاغك للإدارة');
      }
    } else if (action == 'block') {
      await _chatDb.collection('userBlocks').doc('${_uid}_${memberUid}').set({'blockerId': _uid, 'blockedId': memberUid, 'blockedName': memberName, 'createdAt': FieldValue.serverTimestamp()});
      _snack('تم حظر العضو عندك');
    } else if (action == 'mute' && staff) {
      await _moderateMember(memberUid, memberName, 'mute');
    } else if (action == 'ban' && staff) {
      await _moderateMember(memberUid, memberName, 'ban');
    } else if (action == 'clear' && staff) {
      await _chatDb.collection('userSanctions').doc(memberUid).set({
        'uid': memberUid,
        'permanentMute': false,
        'permanentBan': false,
        'muteUntil': FieldValue.delete(),
        'banUntil': FieldValue.delete(),
        'updatedBy': _uid,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      await _chatDb.collection('adminLogs').add({
        'actorId': _uid, 'targetId': memberUid, 'targetName': memberName,
        'action': 'clear_sanctions', 'createdAt': FieldValue.serverTimestamp(),
        'source': 'public_chat',
      });
      _snack('تم رفع الكتم والحظر عن $memberName');
    }
  }

  Widget _bubble(DocumentSnapshot<Map<String,dynamic>> doc){
    final d=doc.data()??{};final mine=d['senderId']==_uid;final sender=(d['senderId']??'').toString();
    final founder=d['senderRole']=='founder' || (d['senderEmail']??'').toString().toLowerCase()==_founderEmail;
    final tier=(d['membershipTier']??'').toString().toLowerCase();
    final tierColor = switch (tier) { 'gold' => const Color(0xFFD49A16), 'silver' => const Color(0xFF8795A1), 'diamond' => const Color(0xFF24A6C7), 'legendary' => const Color(0xFF9A62D8), _ => null };
    final tierLabel = switch (tier) { 'gold' => 'ذهبية', 'silver' => 'فضية', 'diamond' => 'ماسية', 'legendary' => 'أسطورية', _ => 'مميزة' };
    final type=d['type'] as String? ?? 'text';final body=d['text'] as String? ?? '';
    final reply=d['replyTo'] as Map<String,dynamic>?;
    return GestureDetector(onTap:()=>setState(()=>_pulseMessageId=doc.id),onDoubleTap:()=>_react(doc.id,'❤️'),onHorizontalDragEnd:(details){if(details.primaryVelocity!=null&&details.primaryVelocity!.abs()>250){setState(()=>_reply=doc);}},onLongPress:()=>_menu(doc),child:AnimatedScale(scale:_pulseMessageId==doc.id?1.025:1,duration:const Duration(milliseconds:180),curve:Curves.easeOutBack,child:Align(alignment:mine?Alignment.centerRight:Alignment.centerLeft,child:Container(
      constraints:BoxConstraints(maxWidth:MediaQuery.of(context).size.width*.84),margin:EdgeInsetsDirectional.only(top:5,bottom:7,start:mine?42:4,end:mine?4:42),padding:const EdgeInsets.symmetric(horizontal:13,vertical:11),
      decoration:BoxDecoration(gradient:LinearGradient(begin:Alignment.topLeft,end:Alignment.bottomRight,colors:founder?const [Color(0xFFFFFAEA),Color(0xFFFFE9B8)]:(tierColor!=null?[tierColor.withValues(alpha:.22),tierColor.withValues(alpha:.10)]:(mine?const [Color(0xFFF6F2FF),Color(0xFFE3DCFF)]:[Colors.white.withValues(alpha:.94),const Color(0xFFEAF3FF).withValues(alpha:.88)]))),borderRadius:BorderRadius.only(topLeft:const Radius.circular(20),topRight:const Radius.circular(20),bottomLeft:Radius.circular(mine?20:5),bottomRight:Radius.circular(mine?5:20)),border:Border.all(color:founder?const Color(0xFFFFB52E):(tierColor??_chatBrand).withValues(alpha:founder?1:.55),width:founder?2.4:(tierColor!=null?1.8:1)),boxShadow:founder?const [BoxShadow(color:Color(0x33D99A16),blurRadius:12,spreadRadius:1,offset:Offset(0,3))]:[BoxShadow(color:(mine?_chatBrand:Colors.black).withValues(alpha:.09),blurRadius:12,offset:const Offset(0,4))]),
      child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        if(d['isPinned']==true)const Text('📌 مثبتة',style:TextStyle(fontSize:10)),
        Row(mainAxisSize:MainAxisSize.min,children:[
          GestureDetector(onTap:()=>_showMemberActions(d),child:StreamBuilder<DocumentSnapshot<Map<String,dynamic>>>(
            stream:_chatDb.collection('publicProfiles').doc(sender).snapshots(),
            builder:(context,profile){final profileData=profile.data?.data()??{};final photo=profileData['photoUrl'] as String? ?? d['senderPhoto'] as String?;return Container(
              padding:EdgeInsets.all(founder?2:1),decoration:BoxDecoration(shape:BoxShape.circle,border:Border.all(color:founder?const Color(0xFFFFC94A):_chatBrand,width:founder?2:1)),
              child:CircleAvatar(radius:19,backgroundColor:_chatBrand.withValues(alpha:.12),backgroundImage:photo!=null&&photo.startsWith('http')?NetworkImage(photo):null,child:photo==null||!photo.startsWith('http')?Text((d['senderName'] as String? ?? 'ع').characters.first):null));
            }),
          ),
          const SizedBox(width:8),
          Flexible(child:GestureDetector(onTap:()=>_showMemberActions(d),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
            Text(d['senderName'] as String? ?? 'عضو',style:TextStyle(fontWeight:FontWeight.w900,fontSize:founder?14:13,color:founder?const Color(0xFF7A3E00):(tierColor??const Color(0xFF4532A8)))),
            if(founder)const Text('المؤسس والمالك',style:TextStyle(fontSize:10,color:Color(0xFFB77900),fontWeight:FontWeight.bold)),
            if(!founder && tier.isNotEmpty)Text('عضوية $tierLabel',style:TextStyle(fontSize:10,color:tierColor,fontWeight:FontWeight.w900)),
            StreamBuilder<DocumentSnapshot<Map<String,dynamic>>>(stream:_chatDb.collection('publicProfiles').doc(sender).snapshots(),builder:(context,titleProfile){final titleData=titleProfile.data?.data()??{};final customTitle=(titleData['customTitle']??'').toString().trim();return customTitle.isEmpty?const SizedBox.shrink():Padding(padding:const EdgeInsets.only(top:3),child:MemberTitleBadge.fromProfile(title:customTitle,profile:titleData,compact:true));}),
            if(d['edited']==true)const Text('معدّلة',style:TextStyle(fontSize:10,color:Colors.grey)),
          ]))),
          if(founder)const Icon(Icons.workspace_premium,color:Color(0xFFFFB52E),size:19),
        ]),
        const SizedBox(height:6),
        if(reply!=null)Text('رد على '+(reply['senderName']??'عضو').toString()+': '+(reply['text']??'مرفق').toString(),maxLines:2,overflow:TextOverflow.ellipsis,style:const TextStyle(fontSize:11)),
        if(type=='voice'&&d['audioUrl'] is String)_VoiceMessagePlayer(url:d['audioUrl'] as String,durationSeconds:(d['durationSeconds'] as num?)?.toInt()??0),
        if((type=='image'&&d['imageUrl'] is String)||(type=='gif'&&d['gifUrl'] is String))ClipRRect(borderRadius:BorderRadius.circular(12),child:Image.network((type=='gif'?d['gifUrl']:d['imageUrl']) as String,width:230,fit:BoxFit.contain,errorBuilder:(_,__,___)=>const Text('تعذر عرض الصورة'))),
        if(type=='video'&&d['videoUrl'] is String)_ChatVideoMessage(url:d['videoUrl'] as String),
        if(type=='sticker')Center(child:Text(body,style:const TextStyle(fontSize:48))),
        if(type=='text'&&body.isNotEmpty)Text(body,style:TextStyle(fontSize:founder?19:18,height:1.7,color:founder?const Color(0xFF54227A):const Color(0xFF172033),fontWeight:founder?FontWeight.w800:FontWeight.w600,letterSpacing: founder ? 0.15 : 0)),
        Row(mainAxisSize:MainAxisSize.min,children:[
          ...['❤️','😂','🔥','👏','😍','🥹','💜','🎉'].map((e)=>InkWell(onTap:()=>_react(doc.id,e),child:Padding(padding:const EdgeInsets.all(3),child:Text(e)))),
          StreamBuilder<QuerySnapshot<Map<String,dynamic>>>(stream:doc.reference.collection('reactions').snapshots(),builder:(c,s){
            final counts=<String,int>{};for(final r in s.data?.docs??[]){final e=r.data()['emoji'] as String? ?? '';counts[e]=(counts[e]??0)+1;}
            return Text(counts.entries.map((e)=>e.key+e.value.toString()).join(' '),style:const TextStyle(fontSize:11));
          }),
          if (d['createdAt'] is Timestamp)
            Padding(padding: const EdgeInsetsDirectional.only(start: 5, end: 2),
              child: Text(() {
                final date = (d['createdAt'] as Timestamp).toDate().toLocal();
                final hour = (date.hour % 12 == 0 ? 12 : date.hour % 12).toString().padLeft(2, '0');
                final minute = date.minute.toString().padLeft(2, '0');
                return '$hour:$minute ${date.hour >= 12 ? 'م' : 'ص'}';
              }(), style: const TextStyle(fontSize: 10, color: Colors.black54))),
          IconButton(visualDensity:VisualDensity.compact,onPressed:()=>_menu(doc),icon:const Icon(Icons.more_horiz,size:17)),
        ]),
      ]),
    ))));
  }


  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Column(children: [
        Container(
          height: 52,
          padding: const EdgeInsetsDirectional.only(start: 12, end: 6),
          decoration: const BoxDecoration(
            gradient: LinearGradient(begin: Alignment.topRight, end: Alignment.bottomLeft,
              colors: [Color(0xFF11162F), Color(0xFF30286F), Color(0xFF6554D9)]),
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(14)),
            boxShadow: [BoxShadow(color: Color(0x200F1230), blurRadius: 7, offset: Offset(0, 2))],
          ),
          child: Row(children: [
            const Icon(Icons.forum_rounded, color: Colors.white, size: 21),
            const SizedBox(width: 8),
            const Expanded(child: Text('الساحة العامة', maxLines: 1, overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 15))),
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _chatDb.collection('chatPresence').where('online', isEqualTo: true).snapshots(),
              builder: (c, s) => Row(mainAxisSize: MainAxisSize.min, children: [
                Container(width: 7, height: 7, decoration: const BoxDecoration(color: Color(0xFF63E6A5), shape: BoxShape.circle)),
                const SizedBox(width: 4),
                Text('${s.data?.docs.length ?? 0}', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
              ]),
            ),
            IconButton(
              tooltip: 'اسأل مساعد المستقبل',
              visualDensity: VisualDensity.compact,
              constraints: const BoxConstraints.tightFor(width: 38, height: 38),
              onPressed: () => Navigator.push(context, MaterialPageRoute(
                builder: (_) => const LocalHelperBotPage(),
              )),
              icon: const Icon(Icons.smart_toy_rounded, color: Color(0xFFD9D1FF), size: 21),
            ),
            IconButton(
              tooltip: _showSearchBar ? 'إغلاق البحث' : 'بحث في الدردشة',
              visualDensity: VisualDensity.compact,
              constraints: const BoxConstraints.tightFor(width: 38, height: 38),
              onPressed: () => setState(() {
                _showSearchBar = !_showSearchBar;
                if (!_showSearchBar) { _searchController.clear(); _searchQuery = ''; }
              }),
              icon: Icon(_showSearchBar ? Icons.search_off_rounded : Icons.search_rounded, color: Colors.white, size: 20),
            ),
            PopupMenuButton<String>(
              padding: EdgeInsets.zero,
              icon: const Icon(Icons.more_vert, color: Colors.white, size: 21),
              onSelected: (value) {
                if (value == 'background') {
                  showModalBottomSheet<void>(
                    context: context, showDragHandle: true,
                    builder: (c) => Directionality(textDirection: TextDirection.rtl,
                      child: SafeArea(child: Wrap(children: _backgrounds.map((color) => ListTile(
                        dense: true,
                        leading: CircleAvatar(radius: 13, backgroundColor: Color(color)),
                        title: const Text('اختيار خلفية الدردشة'),
                        onTap: () {
                          Navigator.pop(c);
                          setState(() => _background = color);
                          _chatDb.collection('chatPreferences').doc(_uid).set({'background': color}, SetOptions(merge: true));
                        },
                      )).toList())),
                    ),
                  );
                } else if (value == 'admin') { _founderTools(); }
              },
              itemBuilder: (c) => [
                const PopupMenuItem(value: 'background', child: Text('تغيير الخلفية')),
                if (_isFounder) const PopupMenuItem(value: 'admin', child: Text('لوحة المؤسس')),
              ],
            ),
          ]),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          child: _showSearchBar ? Padding(
            padding: const EdgeInsets.fromLTRB(8, 5, 8, 2),
            child: SizedBox(height: 36, child: TextField(
              controller: _searchController, autofocus: true,
              onChanged: (value) => setState(() => _searchQuery = value.trim().toLowerCase()),
              decoration: InputDecoration(
                isDense: true, hintText: 'ابحث باسم العضو أو نص الرسالة...',
                prefixIcon: const Icon(Icons.search_rounded, size: 18),
                prefixIconConstraints: const BoxConstraints(minWidth: 34, minHeight: 32),
                suffixIcon: IconButton(visualDensity: VisualDensity.compact,
                  onPressed: () { _searchController.clear(); setState(() => _searchQuery = ''); },
                  icon: const Icon(Icons.close_rounded, size: 17)),
                contentPadding: const EdgeInsets.symmetric(vertical: 5, horizontal: 8),
                filled: true, fillColor: const Color(0xFFF1EEFF),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(11), borderSide: BorderSide.none),
              ),
            )),
          ) : const SizedBox.shrink(),
        ),
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _chatDb.collection('messages').where('isPinned', isEqualTo: true).limit(5).snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const SizedBox.shrink();
            final pinned = snapshot.data!.docs;
            return Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(8, 3, 8, 3),
              child: Align(alignment: AlignmentDirectional.centerStart,
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () => showModalBottomSheet<void>(
                    context: context, isScrollControlled: true, showDragHandle: true,
                    builder: (sheetContext) => Directionality(textDirection: TextDirection.rtl,
                      child: SafeArea(child: SizedBox(
                        height: MediaQuery.of(sheetContext).size.height * .48,
                        child: Column(children: [
                          const Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                            child: Row(children: [
                              Icon(Icons.push_pin_rounded, color: _chatBrand, size: 18),
                              SizedBox(width: 7),
                              Text('الرسائل المثبتة', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
                            ])),
                          Expanded(child: ListView.builder(
                            itemCount: pinned.length,
                            itemBuilder: (c, index) {
                              final d = pinned[index].data();
                              final messageText = d['text'] as String? ?? (d['type'] == 'image' ? '📷 صورة' : d['type'] == 'voice' ? '🎙️ رسالة صوتية' : 'مرفق');
                              return ListTile(dense: true,
                                leading: const Icon(Icons.bookmark_outline_rounded, color: _chatBrand, size: 19),
                                title: Text(d['senderName'] as String? ?? 'عضو',
                                  style: const TextStyle(fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                                subtitle: Text(messageText, maxLines: 2, overflow: TextOverflow.ellipsis),
                                onTap: () {
                                  Navigator.pop(sheetContext);
                                  showDialog<void>(context: context, builder: (dialogContext) => AlertDialog(
                                    title: Text(d['senderName'] as String? ?? 'رسالة مثبتة'),
                                    content: Text(messageText),
                                    actions: [TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('إغلاق'))],
                                  ));
                                },
                              );
                            },
                          )),
                        ]),
                      )),
                    ),
                  ),
                  child: Container(height: 29, padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(color: const Color(0xFFEDE8FF), borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: _chatBrand.withValues(alpha: .22))),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.push_pin_rounded, color: _chatBrand, size: 15),
                      const SizedBox(width: 5),
                      Text('المثبتة ${pinned.length}', style: const TextStyle(color: Color(0xFF34266F), fontSize: 11, fontWeight: FontWeight.w800)),
                      const SizedBox(width: 3),
                      const Icon(Icons.keyboard_arrow_down_rounded, color: _chatBrand, size: 16),
                    ]),
                  ),
                ),
              ),
            );
          },
        ),
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _chatDb.collection('weeklyContests').where('status', isEqualTo: 'open').limit(3).snapshots(),
          builder: (c, s) {
            if (!s.hasData || s.data!.docs.isEmpty) return const SizedBox.shrink();
            return SizedBox(height: 39, child: ListView(
              scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              children: s.data!.docs.map((d) {
                final data = d.data();
                return Padding(padding: const EdgeInsetsDirectional.only(end: 6),
                  child: GestureDetector(
                    onLongPress: _isFounder ? () => _entries(d.id) : null,
                    child: ActionChip(
                      visualDensity: VisualDensity.compact,
                      avatar: const Icon(Icons.emoji_events_rounded, color: Colors.orange, size: 16),
                      label: Text(data['title'] as String? ?? 'مسابقة الأسبوع', maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      onPressed: () => _join(d.id),
                    ),
                  ));
              }).toList(),
            ));
          },
        ),
        Expanded(child: AnimatedContainer(
          duration: const Duration(milliseconds: 450), curve: Curves.easeInOutCubic,
          decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topRight, end: Alignment.bottomLeft,
            colors: [Color(_background), Color(_background).withOpacity(.78), Color(_background).withOpacity(.92)])),
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _chatDb.collection('userBlocks').where('blockerId', isEqualTo: _uid).snapshots(),
            builder: (context, blocks) {
              if (blocks.hasError) return const Center(child: Text('تعذر تحميل قائمة الحظر.'));
              if (!blocks.hasData) return const Center(child: CircularProgressIndicator());
              final blockedIds = blocks.data!.docs.map((d) => (d.data()['blockedId'] ?? '').toString())
                .where((id) => id.isNotEmpty).toSet();
              return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: _chatDb.collection('messages').orderBy('createdAt', descending: true).limit(100).snapshots(),
                builder: (c, s) {
                  if (s.hasError) return const Center(child: Text('تعذر تحميل الدردشة. راجع قواعد Firestore.'));
                  if (!s.hasData) return const Center(child: CircularProgressIndicator());
                  final visible = s.data!.docs.where((d) {
                    final data = d.data();
                    if (blockedIds.contains((data['senderId'] ?? '').toString())) return false;
                    if (_searchQuery.isEmpty) return true;
                    final text = '${data['text'] ?? ''} ${data['senderName'] ?? ''}'.toLowerCase();
                    return text.contains(_searchQuery);
                  }).toList();
                  if (visible.isEmpty) return Center(child: Text(_searchQuery.isEmpty ? 'ابدأ أول محادثة في الساحة ✨' : 'ما لقينا رسائل تطابق بحثك 🔎'));
                  return ListView(reverse: true, padding: const EdgeInsets.fromLTRB(8, 5, 8, 5),
                    children: visible.map(_bubble).toList());
                },
              );
            },
          ),
        )),
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _chatDb.collection('chatTyping').where('typing', isEqualTo: true).snapshots(),
          builder: (c, s) {
            final n = (s.data?.docs ?? []).where((d) => d.id != _uid).length;
            return n > 0 ? const Padding(padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              child: Align(alignment: AlignmentDirectional.centerStart,
                child: Text('أحد الأعضاء يكتب الآن...', style: TextStyle(fontSize: 10, color: _chatBrand))))
              : const SizedBox.shrink();
          },
        ),
        if (_reply != null) Container(height: 30, padding: const EdgeInsetsDirectional.only(start: 10, end: 4),
          color: const Color(0xFFEDE8FF), child: Row(children: [
            const Icon(Icons.reply_rounded, size: 16, color: _chatBrand), const SizedBox(width: 5),
            Expanded(child: Text('الرد على ${(_reply!.data()?['senderName'] ?? 'عضو')}',
              maxLines: 1, overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF34266F)))),
            IconButton(visualDensity: VisualDensity.compact, constraints: const BoxConstraints.tightFor(width: 28, height: 28),
              onPressed: () => setState(() => _reply = null), icon: const Icon(Icons.close, size: 16)),
          ])),
        if (_error != null) Padding(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          child: Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 10))),
        Container(
          decoration: const BoxDecoration(gradient: LinearGradient(colors: [Colors.white, Color(0xFFF1EDFF)]),
            border: Border(top: BorderSide(color: _chatBrand, width: 1))),
          padding: const EdgeInsets.fromLTRB(5, 3, 5, 3),
          child: SafeArea(top: false, child: Row(children: [
            PopupMenuButton<String>(
              tooltip: 'مرفقات وخيارات الرسالة', padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 42, minHeight: 42),
              icon: Icon(_recordingVoice ? Icons.stop_circle_rounded : Icons.add_circle_outline_rounded,
                color: _recordingVoice ? Colors.red : _chatBrand, size: 25),
              onSelected: (value) {
                if (value == 'image') _sendImage();
                if (value == 'video') _sendVideo();
                if (value == 'gif') _sendGif();
                if (value == 'stickers') _showStickers();
                if (value == 'voice') _toggleVoiceRecording();
              },
              itemBuilder: (c) => [
                const PopupMenuItem(value: 'image', child: Row(children: [Icon(Icons.image_outlined, size: 19), SizedBox(width: 9), Text('إرسال صورة')])),
                const PopupMenuItem(value: 'video', child: Row(children: [Icon(Icons.video_library_outlined, size: 19), SizedBox(width: 9), Text('إرسال فيديو')])),
                const PopupMenuItem(value: 'gif', child: Row(children: [Icon(Icons.gif_box_outlined, size: 19), SizedBox(width: 9), Text('إرسال GIF متحرك')])),
                const PopupMenuItem(value: 'stickers', child: Row(children: [Icon(Icons.emoji_emotions_outlined, size: 19), SizedBox(width: 9), Text('ملصقات وإيموجي')])),
                PopupMenuItem(value: 'voice', child: Row(children: [
                  Icon(_recordingVoice ? Icons.stop_circle : Icons.mic_none, color: _recordingVoice ? Colors.red : _chatBrand, size: 19),
                  const SizedBox(width: 9), Text(_recordingVoice ? 'إيقاف وإرسال الفويس' : 'تسجيل رسالة صوتية'),
                ])),
              ],
            ),
            Expanded(child: Container(
              constraints: const BoxConstraints(minHeight: 40, maxHeight: 68),
              margin: const EdgeInsets.symmetric(horizontal: 4), padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22),
                border: Border.all(color: _chatBrand.withValues(alpha: .20)),
                boxShadow: const [BoxShadow(color: Color(0x0C000000), blurRadius: 5, offset: Offset(0, 1))]),
              alignment: Alignment.center,
              child: TextField(
                controller: _text, maxLength: 1000, minLines: 1, maxLines: 2,
                textInputAction: TextInputAction.send,
                onChanged: (v) {
                  _chatDb.collection('chatTyping').doc(_uid).set({
                    'uid': _uid, 'typing': v.trim().isNotEmpty, 'updatedAt': FieldValue.serverTimestamp(),
                  }, SetOptions(merge: true)).catchError((_) {});
                  if (v.endsWith('@') && !_mentionPickerOpen) _showMentionPicker();
                },
                onSubmitted: (_) => _send(body: _text.text),
                decoration: const InputDecoration(hintText: 'اكتب رسالتك...', counterText: '',
                  isDense: true, border: InputBorder.none, contentPadding: EdgeInsets.symmetric(vertical: 8)),
              ),
            )),
            SizedBox(width: 39, height: 39, child: IconButton.filled(
              padding: EdgeInsets.zero, onPressed: _sending ? null : () => _send(body: _text.text),
              style: IconButton.styleFrom(backgroundColor: _chatBrand, foregroundColor: Colors.white),
              icon: _sending
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.send_rounded, size: 19),
            )),
          ])),
        ),
      ]),
    );
  }
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
        StreamBuilder<DocumentSnapshot<Map<String,dynamic>>>(
          stream:_chatDb.collection('memberships').doc(uid).snapshots(),
          builder:(context,m){
            final data=m.data?.data();
            final expiry=data?['expiresAt'];
            final active=data!=null && expiry is Timestamp && expiry.toDate().isAfter(DateTime.now());
            if(!active)return const SizedBox.shrink();
            final tier=(data['tier']??'premium').toString();
            final label={'silver':'العضوية الفضية','gold':'العضوية الذهبية','diamond':'العضوية الماسية','premium':'العضوية المميزة'}[tier]??'العضوية المميزة';
            final color={'silver':const Color(0xFF8795A1),'gold':const Color(0xFFD49A16),'diamond':const Color(0xFF24A6C7)}[tier]??const Color(0xFF8B70D6);
            final days=expiry.toDate().difference(DateTime.now()).inDays;
            return Card(color:color.withOpacity(.10),child:ListTile(
              leading:Icon(Icons.workspace_premium,color:color,size:30),
              title:Text(label,style:TextStyle(color:color,fontWeight:FontWeight.bold)),
              subtitle:Text('عضوية مميزة • متبقي ${days<1?1:days} يوم'),
              trailing:const Icon(Icons.verified,color:Color(0xFF24A36A)),
            ));
          },
        ),
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

class _VoiceMessagePlayer extends StatefulWidget {
  final String url;
  final int durationSeconds;
  const _VoiceMessagePlayer({required this.url,required this.durationSeconds});
  @override State<_VoiceMessagePlayer> createState()=>_VoiceMessagePlayerState();
}
class _VoiceMessagePlayerState extends State<_VoiceMessagePlayer> {
  late final AudioPlayer _player;
  @override void initState() {
    super.initState();
    _player=AudioPlayer();
    _player.setUrl(widget.url).catchError((_) => null);
  }
  @override void dispose() { _player.dispose(); super.dispose(); }
  String _time(Duration d) {
    final m=d.inMinutes.toString().padLeft(2,'0');
    final s=(d.inSeconds%60).toString().padLeft(2,'0');
    return '$m:$s';
  }
  @override Widget build(BuildContext context)=>Container(
    width:230,padding:const EdgeInsets.symmetric(horizontal:8,vertical:5),
    decoration:BoxDecoration(color:const Color(0xFFEEE9FF),borderRadius:BorderRadius.circular(14)),
    child:Row(children:[
      StreamBuilder<PlayerState>(stream:_player.playerStateStream,builder:(context,s){
        final playing=s.data?.playing??false;
        return IconButton(onPressed:()=>playing?_player.pause():_player.play(),icon:Icon(playing?Icons.pause_circle_filled:Icons.play_circle_fill,color:_chatBrand,size:34));
      }),
      Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        const Text('رسالة صوتية',style:TextStyle(fontWeight:FontWeight.bold,fontSize:12)),
        StreamBuilder<Duration>(stream:_player.positionStream,builder:(context,s){
          final pos=s.data??Duration.zero;
          final total=_player.duration??Duration(seconds:widget.durationSeconds);
          return Column(children:[
            Slider(value:pos.inMilliseconds.toDouble().clamp(0,total.inMilliseconds>0?total.inMilliseconds.toDouble():1).toDouble(),min:0,max:total.inMilliseconds>0?total.inMilliseconds.toDouble():1,onChanged:(v)=>_player.seek(Duration(milliseconds:v.toInt()))),
            Row(mainAxisAlignment:MainAxisAlignment.spaceBetween,children:[Text(_time(pos),style:const TextStyle(fontSize:10)),Text(_time(total),style:const TextStyle(fontSize:10))]),
          ]);
        }),
      ])),
    ]),
  );
}


class _ChatVideoMessage extends StatefulWidget {
  final String url;
  const _ChatVideoMessage({required this.url});
  @override State<_ChatVideoMessage> createState() => _ChatVideoMessageState();
}
class _ChatVideoMessageState extends State<_ChatVideoMessage> {
  late final VideoPlayerController _controller;
  @override void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url))..initialize().then((_) { if (mounted) setState(() {}); });
  }
  @override void dispose() { _controller.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(12),
    child: Container(width: 250, color: Colors.black,
      child: _controller.value.isInitialized
        ? AspectRatio(aspectRatio: _controller.value.aspectRatio, child: Stack(alignment: Alignment.center, children: [
            VideoPlayer(_controller),
            IconButton(color: Colors.white, iconSize: 54, icon: Icon(_controller.value.isPlaying ? Icons.pause_circle : Icons.play_circle),
              onPressed: () => setState(() => _controller.value.isPlaying ? _controller.pause() : _controller.play())),
          ]))
        : const SizedBox(height: 150, child: Center(child: CircularProgressIndicator(color: Colors.white))),
    ),
  );
}
