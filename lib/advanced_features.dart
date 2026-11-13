import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const _brand = Color(0xFF6554D9);
final _db = FirebaseFirestore.instance;
String get _uid => FirebaseAuth.instance.currentUser!.uid;

String _chatId(String a, String b) => a.compareTo(b) < 0 ? '${a}_${b}' : '${b}_${a}';

class DirectMessagesPage extends StatelessWidget {
  const DirectMessagesPage({super.key});

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.rtl,
    child: Scaffold(
      appBar: AppBar(title: const Text('الرسائل الخاصة')),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: _brand, foregroundColor: Colors.white,
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StartDirectMessagePage())),
        icon: const Icon(Icons.edit), label: const Text('محادثة جديدة'),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _db.collection('conversations').where('members', arrayContains: _uid).snapshots(),
        builder: (context, s) {
          if (s.hasError) return const Center(child: Text('تعذر تحميل الرسائل. تأكد من نشر قواعد Firestore.'));
          if (!s.hasData) return const Center(child: CircularProgressIndicator());
          if (s.data!.docs.isEmpty) return const Center(child: Text('ما عندك محادثات بعد. ابدأ محادثة جديدة.'));
          final conversations = [...s.data!.docs]..sort((a, b) {
            final av = a.data()['updatedAt'];
            final bv = b.data()['updatedAt'];
            final at = av is Timestamp ? av : Timestamp(0, 0);
            final bt = bv is Timestamp ? bv : Timestamp(0, 0);
            return bt.compareTo(at);
          });
          return ListView(children: conversations.map((doc) {
            final d = doc.data();
            final members = List<String>.from(d['members'] ?? []);
            final other = members.firstWhere((x) => x != _uid, orElse: () => '');
            final names = Map<String, dynamic>.from(d['memberNames'] ?? {});
            final name = names[other] as String? ?? 'عضو';
            return ListTile(
              leading: const CircleAvatar(child: Icon(Icons.person)),
              title: Text(name),
              subtitle: Text(d['lastMessage'] as String? ?? 'ابدأ المحادثة'),
              trailing: const Icon(Icons.chevron_left),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DirectChatPage(conversationId: doc.id, otherUid: other, otherName: name))),
            );
          }).toList());
        },
      ),
    ),
  );
}

class StartDirectMessagePage extends StatefulWidget {
  const StartDirectMessagePage({super.key});
  @override State<StartDirectMessagePage> createState() => _StartDirectMessagePageState();
}
class _StartDirectMessagePageState extends State<StartDirectMessagePage> {
  String query = '';
  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.rtl,
    child: Scaffold(
      appBar: AppBar(title: const Text('اختيار عضو')),
      body: Column(children: [
        Padding(padding: const EdgeInsets.all(12), child: TextField(
          decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'ابحث عن عضو بالاسم', border: OutlineInputBorder()),
          onChanged: (v) => setState(() => query = v.trim().toLowerCase()),
        )),
        Expanded(child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _db.collection('publicProfiles').orderBy('name').limit(200).snapshots(),
          builder: (context, s) {
            if (s.hasError) return const Center(child: Text('تعذر البحث عن الأعضاء'));
            if (!s.hasData) return const Center(child: CircularProgressIndicator());
            final docs = s.data!.docs.where((d) => d.id != _uid && ((d.data()['name'] as String? ?? '').toLowerCase().contains(query))).toList();
            if (docs.isEmpty) return const Center(child: Text('ما لقينا أعضاء بهذا الاسم'));
            return ListView(children: docs.map((d) {
              final name = d.data()['name'] as String? ?? 'عضو';
              return ListTile(
                leading: const CircleAvatar(child: Icon(Icons.person)),
                title: Text(name),
                subtitle: const Text('ابدأ محادثة خاصة'),
                onTap: () async {
                  final id = _chatId(_uid, d.id);
                  final me = FirebaseAuth.instance.currentUser!;
                  final myProfile = await _db.collection('publicProfiles').doc(_uid).get();
                  await _db.collection('conversations').doc(id).set({
                    'members': [_uid, d.id],
                    'memberNames': {_uid: myProfile.data()?['name'] ?? me.displayName ?? 'عضو', d.id: name},
                    'updatedAt': FieldValue.serverTimestamp(),
                  }, SetOptions(merge: true));
                  if (!context.mounted) return;
                  Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => DirectChatPage(conversationId: id, otherUid: d.id, otherName: name)));
                },
              );
            }).toList());
          },
        )),
      ]),
    ),
  );
}

class DirectChatPage extends StatefulWidget {
  final String conversationId, otherUid, otherName;
  const DirectChatPage({super.key, required this.conversationId, required this.otherUid, required this.otherName});
  @override State<DirectChatPage> createState() => _DirectChatPageState();
}
class _DirectChatPageState extends State<DirectChatPage> {
  final controller = TextEditingController();
  bool busy = false;
  bool changingBackground = false;
  String? backgroundUrl;
  @override void initState() { super.initState(); _loadBackground(); }
  Future<void> _loadBackground() async {
    try {
      final snap = await _db.collection('conversations').doc(widget.conversationId).get();
      final map = Map<String, dynamic>.from(snap.data()?['backgrounds'] ?? {});
      if (mounted && map[_uid] is String) setState(() => backgroundUrl = map[_uid] as String);
    } catch (_) {}
  }
  Future<void> _chooseBackground() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 82, maxWidth: 1600);
    if (picked == null || !mounted) return;
    setState(() => changingBackground = true);
    try {
      final bytes = await picked.readAsBytes();
      final path = 'chat-backgrounds/$_uid/${DateTime.now().millisecondsSinceEpoch}.jpg';
      await Supabase.instance.client.storage.from('forum-media').uploadBinary(
        path, bytes, fileOptions: const FileOptions(contentType: 'image/jpeg', upsert: false),
      );
      final url = Supabase.instance.client.storage.from('forum-media').getPublicUrl(path);
      await _db.collection('conversations').doc(widget.conversationId).set({
        'backgrounds': {_uid: url},
      }, SetOptions(merge: true));
      if (mounted) setState(() => backgroundUrl = url);
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تعذر تغيير الخلفية. تحقق من صلاحيات تخزين Supabase.')));
    } finally { if (mounted) setState(() => changingBackground = false); }
  }
  @override void dispose() { controller.dispose(); super.dispose(); }
  Future<void> send() async {
    final value = controller.text.trim();
    if (value.isEmpty || busy) return;
    setState(() => busy = true);
    try {
      final profile = await _db.collection('publicProfiles').doc(_uid).get();
      final name = profile.data()?['name'] ?? FirebaseAuth.instance.currentUser?.displayName ?? 'عضو';
      final batch = _db.batch();
      final convo = _db.collection('conversations').doc(widget.conversationId);
      final msg = convo.collection('messages').doc();
      batch.set(msg, {'senderId': _uid, 'senderName': name, 'senderRole': FirebaseAuth.instance.currentUser?.email?.toLowerCase() == 'husinalzerjaoe@gmail.com' ? 'founder' : 'member', 'text': value, 'createdAt': FieldValue.serverTimestamp()});
      batch.set(convo, {'lastMessage': value, 'updatedAt': FieldValue.serverTimestamp()}, SetOptions(merge: true));
      // Commit the message first. A notification failure must never cancel delivery.
      await batch.commit();
      controller.clear();
      try {
        await _db.collection('notifications').add({
          'recipientId': widget.otherUid, 'actorId': _uid, 'actorName': name,
          'type': 'message', 'text': 'أرسل لك رسالة خاصة', 'read': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      } catch (_) {
        // The conversation remains delivered even if notification rules reject this write.
      }
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تعذر إرسال الرسالة. افحص اتصال الإنترنت وصلاحيات المحادثة.')));
    } finally { if (mounted) setState(() => busy = false); }
  }
  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.rtl,
    child: Scaffold(
      appBar: AppBar(
        title: Row(children: [
          CircleAvatar(
            radius: 17,
            backgroundColor: const Color(0xFF6554D9).withValues(alpha: .18),
            child: Text(widget.otherName.isNotEmpty ? widget.otherName.characters.first : '؟',
                style: const TextStyle(color: _brand, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(widget.otherName)),
        ]),
        actions: [
          IconButton(
            tooltip: 'خلفية المحادثة',
            icon: changingBackground ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.wallpaper_outlined),
            onPressed: changingBackground ? null : _chooseBackground,
          ),
          IconButton(
            tooltip: 'معلومات المحادثة',
            icon: const Icon(Icons.info_outline),
            onPressed: () => showDialog<void>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('محادثة خاصة'),
                content: Text('محادثتك مع ${widget.otherName} خاصة بينكما. يمكنك استخدام الحظر والإبلاغ من ملف العضو.'),
                actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('حسناً'))],
              ),
            ),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          image: backgroundUrl != null
              ? DecorationImage(image: NetworkImage(backgroundUrl!), fit: BoxFit.cover, colorFilter: ColorFilter.mode(Colors.white.withValues(alpha: .18), BlendMode.lighten))
              : null,
          gradient: backgroundUrl == null ? const LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [Color(0xFFF4F0FF), Color(0xFFEAF5FF), Color(0xFFFFF0F7)],
          ) : null,
        ),
        child: Stack(children: [
          Positioned(top: 22, right: 18, child: Icon(Icons.auto_awesome, color: _brand.withValues(alpha: .10), size: 54)),
          Positioned(bottom: 90, left: 16, child: Icon(Icons.star_rounded, color: Colors.pink.withValues(alpha: .10), size: 68)),
          Column(children: [
        Expanded(child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _db.collection('conversations').doc(widget.conversationId).collection('messages').orderBy('createdAt', descending: true).limit(300).snapshots(),
          builder: (context, s) {
            if (s.hasError) return const Center(child: Text('تعذر تحميل المحادثة'));
            if (!s.hasData) return const Center(child: CircularProgressIndicator());
            return ListView(padding: const EdgeInsets.all(12), children: s.data!.docs.reversed.map((doc) {
              final d = doc.data(); final mine = d['senderId'] == _uid;
              return Align(alignment: mine ? Alignment.centerRight : Alignment.centerLeft, child: Container(
                margin: const EdgeInsets.symmetric(vertical: 4), padding: const EdgeInsets.all(12),
                constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * .78),
                decoration: BoxDecoration(color: mine ? const Color(0xFFE9E5FF) : Colors.white, borderRadius: BorderRadius.circular(14)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  if (!mine && (d['senderId'] as String? ?? '').isNotEmpty)
                    StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                      stream: _db.collection('publicProfiles').doc(d['senderId'] as String).snapshots(),
                      builder: (context, profile) {
                        final p = profile.data?.data() ?? {};
                        final senderId = d['senderId'] as String;
                        final name = p['name'] as String? ?? d['senderName'] as String? ?? 'عضو';
                        final photo = p['photoUrl'] as String?;
                        return InkWell(
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => _MemberMiniProfilePage(uid: senderId, fallbackName: name))),
                          child: Padding(padding: const EdgeInsets.only(bottom: 6), child: Row(mainAxisSize: MainAxisSize.min, children: [
                            CircleAvatar(radius: 13, backgroundImage: photo != null && photo.startsWith('https://') ? NetworkImage(photo) : null,
                              child: photo == null || !photo.startsWith('https://') ? const Icon(Icons.person, size: 15) : null),
                            const SizedBox(width: 6),
                            Text(name, style: const TextStyle(color: _brand, fontWeight: FontWeight.bold, fontSize: 12)),
                            if (d['senderRole'] == 'founder') ...[
                              const SizedBox(width: 5),
                              const Icon(Icons.workspace_premium, size: 15, color: Color(0xFFFFB52E)),
                              const Text('المؤسس', style: TextStyle(fontSize: 10, color: Color(0xFFB77900), fontWeight: FontWeight.bold)),
                            ],
                          ])),
                        );
                      },
                    ),
                  Text(d['text'] as String? ?? ''),
                ]),
              ));
            }).toList());
          },
        )),
        SafeArea(top: false, child: Padding(padding: const EdgeInsets.all(10), child: Row(children: [
          Expanded(child: TextField(controller: controller, minLines: 1, maxLines: 4, maxLength: 1000, decoration: const InputDecoration(counterText: '', hintText: 'اكتب رسالة...', border: OutlineInputBorder()), onSubmitted: (_) => send())),
          const SizedBox(width: 8),
          IconButton.filled(onPressed: busy ? null : send, icon: const Icon(Icons.send)),
        ]))),
          ]),
        ]),
      ),
    ),
  );
}

class _MemberMiniProfilePage extends StatelessWidget {
  final String uid, fallbackName;
  const _MemberMiniProfilePage({required this.uid, required this.fallbackName});
  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.rtl,
    child: Scaffold(
      appBar: AppBar(title: const Text('الملف الشخصي')),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: _db.collection('publicProfiles').doc(uid).snapshots(),
        builder: (context, s) {
          if (!s.hasData) return const Center(child: CircularProgressIndicator());
          final d = s.data!.data() ?? {};
          final photo = d['photoUrl'] as String?;
          return ListView(padding: const EdgeInsets.all(20), children: [
            Center(child: CircleAvatar(radius: 48,
              backgroundImage: photo != null && photo.startsWith('https://') ? NetworkImage(photo) : null,
              child: photo == null || !photo.startsWith('https://') ? const Icon(Icons.person, size: 48) : null)),
            const SizedBox(height: 12),
            Center(child: Text(d['name'] as String? ?? fallbackName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold))),
            const SizedBox(height: 8),
            const Text('السيرة الذاتية', style: TextStyle(fontWeight: FontWeight.bold)),
            Text((d['bio'] as String?)?.trim().isNotEmpty == true ? d['bio'] as String : 'لم يضف العضو سيرة ذاتية بعد'),
          ]);
        },
      ),
    ),
  );
}

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});
  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.rtl,
    child: Scaffold(
      appBar: AppBar(title: const Text('الإشعارات')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _db.collection('notifications').where('recipientId', isEqualTo: _uid).limit(100).snapshots(),
        builder: (context, s) {
          if (s.hasError) return const Center(child: Text('تعذر تحميل الإشعارات'));
          if (!s.hasData) return const Center(child: CircularProgressIndicator());
          if (s.data!.docs.isEmpty) return const Center(child: Text('ما عندك إشعارات حالياً'));
          return ListView(children: s.data!.docs.map((doc) {
            final d = doc.data();
            return ListTile(
              leading: CircleAvatar(child: Icon(d['type'] == 'message' ? Icons.mail : Icons.notifications)),
              title: Text(d['text'] as String? ?? 'إشعار جديد'),
              subtitle: Text(d['actorName'] as String? ?? 'الملتقى'),
              trailing: d['read'] == true ? const Icon(Icons.done, color: Colors.green) : const Icon(Icons.circle, size: 9, color: _brand),
              onTap: () => doc.reference.update({'read': true}),
            );
          }).toList());
        },
      ),
    ),
  );
}


class MemberSafetyPage extends StatelessWidget {
  const MemberSafetyPage({super.key});
  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.rtl,
    child: Scaffold(
      appBar: AppBar(title: const Text('الأمان والحظر')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _db.collection('userBlocks').where('blockerId', isEqualTo: _uid).snapshots(),
        builder: (context, s) {
          if (s.hasError) return const Center(child: Text('تعذر تحميل قائمة الحظر'));
          if (!s.hasData) return const Center(child: CircularProgressIndicator());
          if (s.data!.docs.isEmpty) return const Center(child: Text('قائمة الحظر فارغة'));
          return ListView(children: s.data!.docs.map((doc) {
            final d = doc.data();
            return ListTile(
              leading: const CircleAvatar(child: Icon(Icons.block)),
              title: Text(d['blockedName'] as String? ?? 'عضو'),
              subtitle: const Text('الحظر الحالي يمنع الرسائل الخاصة بينكما فقط'),
              trailing: TextButton(
                onPressed: () => doc.reference.delete(),
                child: const Text('إلغاء الحظر'),
              ),
            );
          }).toList());
        },
      ),
    ),
  );
}

class MemberSafetyActions extends StatelessWidget {
  final String uid, name;
  const MemberSafetyActions({super.key, required this.uid, required this.name});

  bool get _isFounder => FirebaseAuth.instance.currentUser?.email?.toLowerCase() == 'husinalzerjaoe@gmail.com';

  Future<bool> _isModerator() async => (await _db.collection('chatModerators').doc(_uid).get()).exists;

  Future<void> _report(BuildContext context) async {
    final reason = await showDialog<String>(context: context, builder: (c) => SimpleDialog(
      title: const Text('سبب الإبلاغ'),
      children: ['تنمّر أو إساءة', 'انتحال شخصية', 'محتوى غير مناسب', 'إزعاج أو رسائل مزعجة', 'احتيال أو تهديد']
        .map((v) => SimpleDialogOption(onPressed: () => Navigator.pop(c, v), child: Text(v))).toList(),
    ));
    if (reason == null) return;
    final me = await _db.collection('publicProfiles').doc(_uid).get();
    await _db.collection('reports').add({
      'type': 'user', 'targetId': uid, 'reportedUserId': uid,
      'reporterId': _uid, 'reporterName': me.data()?['name'] ?? 'عضو',
      'reportedName': name, 'reason': reason, 'status': 'new',
      'createdAt': FieldValue.serverTimestamp(),
    });
    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إرسال البلاغ للإدارة')));
  }

  Future<void> _moderate(BuildContext context) async {
    final choice = await showModalBottomSheet<String>(context: context, showDragHandle: true, builder: (c) => Directionality(
      textDirection: TextDirection.rtl,
      child: SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
        const ListTile(title: Text('إجراءات الإدارة', style: TextStyle(fontWeight: FontWeight.bold))),
        ListTile(leading: const Icon(Icons.volume_off), title: const Text('كتم دقيقة'), onTap: () => Navigator.pop(c, 'mute_1m')),
        ListTile(leading: const Icon(Icons.volume_off), title: const Text('كتم ساعة'), onTap: () => Navigator.pop(c, 'mute_1h')),
        ListTile(leading: const Icon(Icons.volume_off), title: const Text('كتم يوم'), onTap: () => Navigator.pop(c, 'mute_1d')),
        ListTile(leading: const Icon(Icons.volume_off), title: const Text('كتم دائم'), onTap: () => Navigator.pop(c, 'mute_forever')),
        ListTile(leading: const Icon(Icons.logout), title: const Text('طرد مؤقت 24 ساعة'), onTap: () => Navigator.pop(c, 'kick_1d')),
        ListTile(leading: const Icon(Icons.block, color: Colors.red), title: const Text('حظر نهائي', style: TextStyle(color: Colors.red)), onTap: () => Navigator.pop(c, 'ban')),
        ListTile(leading: const Icon(Icons.lock_open), title: const Text('رفع جميع العقوبات'), onTap: () => Navigator.pop(c, 'clear')),
      ])),
    ));
    if (choice == null) return;
    final now = DateTime.now();
    final mute = choice.startsWith('mute');
    final duration = switch (choice) {
      'mute_1m' => const Duration(minutes: 1),
      'mute_1h' => const Duration(hours: 1),
      'mute_1d' || 'kick_1d' => const Duration(days: 1),
      _ => Duration.zero,
    };
    final data = <String, dynamic>{
      'uid': uid, 'updatedAt': FieldValue.serverTimestamp(), 'updatedBy': _uid,
      'reason': 'إجراء إداري من صفحة العضو',
      if (choice == 'clear') 'muteUntil': FieldValue.delete(),
      if (choice == 'clear') 'permanentMute': false,
      if (choice == 'clear') 'banUntil': FieldValue.delete(),
      if (choice == 'clear') 'permanentBan': false,
      if (mute && duration != Duration.zero) 'muteUntil': Timestamp.fromDate(now.add(duration)),
      if (choice == 'mute_forever') 'permanentMute': true,
      if (choice == 'kick_1d') 'banUntil': Timestamp.fromDate(now.add(duration)),
      if (choice == 'ban') 'permanentBan': true,
    };
    await _db.collection('userSanctions').doc(uid).set(data, SetOptions(merge: true));
    await _db.collection('adminLogs').add({
      'actorId': _uid, 'targetId': uid, 'targetName': name,
      'action': choice, 'createdAt': FieldValue.serverTimestamp(),
      'source': 'member_profile',
    });
    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تسجيل الإجراء الإداري')));
  }

  @override
  Widget build(BuildContext context) {
    if (uid == _uid) return const SizedBox.shrink();
    final ref = _db.collection('userBlocks').doc('${_uid}_$uid');
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: ref.snapshots(),
      builder: (context, s) {
        final blocked = s.data?.exists ?? false;
        return Column(children: [
          OutlinedButton.icon(
            icon: Icon(blocked ? Icons.check_circle_outline : Icons.block),
            label: Text(blocked ? 'إلغاء حظر الرسائل الخاصة' : 'حظر الرسائل الخاصة لهذا العضو'),
            onPressed: () async {
              if (blocked) { await ref.delete(); }
              else { await ref.set({'blockerId': _uid, 'blockedId': uid, 'blockedName': name, 'createdAt': FieldValue.serverTimestamp()}); }
              if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(blocked ? 'تم إلغاء الحظر' : 'تم حظر العضو')));
            },
          ),
          TextButton.icon(
            icon: const Icon(Icons.flag_outlined),
            label: const Text('الإبلاغ عن العضو'),
            onPressed: () => _report(context),
          ),
          if (_isFounder) FilledButton.tonalIcon(
            icon: const Icon(Icons.gavel), label: const Text('إدارة العضو: كتم / طرد / حظر'),
            onPressed: () => _moderate(context),
          ) else FutureBuilder<bool>(
            future: _isModerator(),
            builder: (context, role) => role.data == true ? FilledButton.tonalIcon(
              icon: const Icon(Icons.gavel), label: const Text('إدارة العضو: كتم / طرد / حظر'),
              onPressed: () => _moderate(context),
            ) : const SizedBox.shrink(),
          ),
        ]);
      },
    );
  }
}

class ModerationLogPage extends StatelessWidget {
  const ModerationLogPage({super.key});
  bool get _isFounder => FirebaseAuth.instance.currentUser?.email?.toLowerCase() == 'husinalzerjaoe@gmail.com';
  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.rtl,
    child: Scaffold(
      appBar: AppBar(title: const Text('سجل المشرفين')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _db.collection('adminLogs').orderBy('createdAt', descending: true).limit(200).snapshots(),
        builder: (context, s) {
          if (s.hasError) return const Center(child: Text('تعذر تحميل السجل. تحقق من صلاحيات الإدارة.'));
          if (!s.hasData) return const Center(child: CircularProgressIndicator());
          if (s.data!.docs.isEmpty) return const Center(child: Text('لا توجد إجراءات مسجلة بعد'));
          return ListView(children: s.data!.docs.map((doc) {
            final d = doc.data();
            return ListTile(
              leading: const CircleAvatar(child: Icon(Icons.history)),
              title: Text('${d['action'] ?? 'إجراء إداري'} • ${d['targetName'] ?? d['targetId'] ?? ''}'),
              subtitle: Text('المشرف: ${d['actorId'] ?? '-'} • العضو: ${d['targetId'] ?? '-'}'),
              isThreeLine: true,
            );
          }).toList());
        },
      ),
    ),
  );
}


class FounderReportsPage extends StatelessWidget {
  const FounderReportsPage({super.key});
  bool get _isFounder => FirebaseAuth.instance.currentUser?.email?.toLowerCase() == 'husinalzerjaoe@gmail.com';
  @override
  Widget build(BuildContext context) {
    if (!_isFounder) return const Scaffold(body: Center(child: Text('هذه الصفحة للمؤسس فقط')));
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('مراجعة البلاغات')),
        body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _db.collection('reports').limit(150).snapshots(),
          builder: (context, s) {
            if (s.hasError) return const Center(child: Text('تعذر تحميل البلاغات. انشر قواعد Firestore المحدّثة.'));
            if (!s.hasData) return const Center(child: CircularProgressIndicator());
            if (s.data!.docs.isEmpty) return const Center(child: Text('ماكو بلاغات حالياً'));
            return ListView(children: s.data!.docs.map((doc) {
              final d = doc.data();
              final done = d['status'] == 'reviewed';
              return Card(child: ListTile(
                leading: Icon(d['type'] == 'user' ? Icons.person : Icons.article, color: _brand),
                title: Text(d['reason'] as String? ?? 'بلاغ'),
                subtitle: Text('النوع: ${d['type'] ?? 'محتوى'} • المبلّغ: ${d['reporterName'] ?? d['reporterId'] ?? '-'}\\nالحساب المبلّغ عليه: ${d['reportedName'] ?? d['reportedUserId'] ?? d['targetId'] ?? '-'}\\nالسبب: ${d['reason'] ?? '-'}'),
                isThreeLine: true,
                trailing: PopupMenuButton<String>(
                  tooltip: 'إجراء إداري',
                  icon: Icon(done ? Icons.check_circle : Icons.gavel, color: done ? Colors.green : _brand),
                  onSelected: (action) async {
                    final target = (d['reportedUserId'] ?? d['targetId'] ?? '').toString();
                    if (action == 'review') {
                      await doc.reference.update({'status': 'reviewed', 'reviewedAt': FieldValue.serverTimestamp(), 'reviewedBy': _uid});
                    } else if (target.isNotEmpty) {
                      final sanction = <String, dynamic>{'uid': target, 'updatedBy': _uid, 'updatedAt': FieldValue.serverTimestamp(), 'reason': d['reason'] ?? 'بلاغ عضو'};
                      if (action == 'mute') sanction['muteUntil'] = Timestamp.fromDate(DateTime.now().add(const Duration(days: 1)));
                      if (action == 'ban') sanction['permanentBan'] = true;
                      if (action == 'clear') { sanction['muteUntil'] = FieldValue.delete(); sanction['permanentMute'] = false; sanction['banUntil'] = FieldValue.delete(); sanction['permanentBan'] = false; }
                      await _db.collection('userSanctions').doc(target).set(sanction, SetOptions(merge: true));
                      await _db.collection('adminLogs').add({'actorId': _uid, 'targetId': target, 'targetName': d['reportedName'] ?? target, 'action': action, 'createdAt': FieldValue.serverTimestamp(), 'source': 'report_review', 'reportId': doc.id});
                      await doc.reference.update({'status': 'reviewed', 'reviewedAt': FieldValue.serverTimestamp(), 'reviewedBy': _uid});
                    }
                  },
                  itemBuilder: (c) => [
                    const PopupMenuItem(value: 'review', child: Text('تحديد كمراجع')),
                    const PopupMenuItem(value: 'mute', child: Text('كتم يوم')),
                    const PopupMenuItem(value: 'ban', child: Text('حظر نهائي')),
                    const PopupMenuItem(value: 'clear', child: Text('رفع العقوبات')),
                  ],
                ),
              ));
            }).toList());
          },
        ),
      ),
    );
  }
}


class SavedPostsPage extends StatelessWidget {
  const SavedPostsPage({super.key});
  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.rtl,
    child: Scaffold(
      appBar: AppBar(title: const Text('المنشورات المحفوظة')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _db.collection('users').doc(_uid).collection('savedPosts').orderBy('savedAt', descending: true).limit(100).snapshots(),
        builder: (context, s) {
          if (s.hasError) return const Center(child: Text('تعذر تحميل المحفوظات'));
          if (!s.hasData) return const Center(child: CircularProgressIndicator());
          if (s.data!.docs.isEmpty) return const Center(child: Text('ما حفظت أي منشور لحد الآن'));
          return ListView(children: s.data!.docs.map((doc) {
            return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              future: _db.collection('posts').doc(doc.id).get(),
              builder: (context, post) {
                if (!post.hasData || !post.data!.exists) return const ListTile(title: Text('المنشور غير متاح'));
                final p = post.data!.data()!;
                return Card(child: ListTile(
                  leading: const Icon(Icons.bookmark, color: _brand),
                  title: Text(p['authorName'] as String? ?? 'عضو'),
                  subtitle: Text(p['text'] as String? ?? p['videoUrl'] as String? ?? 'منشور محفوظ', maxLines: 2, overflow: TextOverflow.ellipsis),
                  trailing: IconButton(icon: const Icon(Icons.bookmark_remove_outlined), onPressed: () => doc.reference.delete()),
                ));
              },
            );
          }).toList());
        },
      ),
    ),
  );
}

class SavePostControl extends StatelessWidget {
  final String postId;
  const SavePostControl({super.key, required this.postId});
  @override
  Widget build(BuildContext context) {
    final ref = _db.collection('users').doc(_uid).collection('savedPosts').doc(postId);
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: ref.snapshots(),
      builder: (context, s) {
        final saved = s.data?.exists ?? false;
        return IconButton(
          tooltip: saved ? 'إزالة من المحفوظات' : 'حفظ المنشور',
          onPressed: () async {
            if (saved) {
              await ref.delete();
            } else {
              await ref.set({'postId': postId, 'savedAt': FieldValue.serverTimestamp()});
            }
          },
          icon: Icon(saved ? Icons.bookmark : Icons.bookmark_border, color: saved ? _brand : null),
        );
      },
    );
  }
}
