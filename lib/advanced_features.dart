import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

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
        stream: _db.collection('conversations').where('members', arrayContains: _uid).orderBy('updatedAt', descending: true).snapshots(),
        builder: (context, s) {
          if (s.hasError) return const Center(child: Text('تعذر تحميل الرسائل. تأكد من نشر قواعد Firestore.'));
          if (!s.hasData) return const Center(child: CircularProgressIndicator());
          if (s.data!.docs.isEmpty) return const Center(child: Text('ما عندك محادثات بعد. ابدأ محادثة جديدة.'));
          return ListView(children: s.data!.docs.map((doc) {
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
      batch.set(msg, {'senderId': _uid, 'senderName': name, 'text': value, 'createdAt': FieldValue.serverTimestamp()});
      batch.set(convo, {'lastMessage': value, 'updatedAt': FieldValue.serverTimestamp()}, SetOptions(merge: true));
      batch.set(_db.collection('notifications').doc(), {
        'recipientId': widget.otherUid, 'actorId': _uid, 'actorName': name,
        'type': 'message', 'text': 'أرسل لك رسالة خاصة', 'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
      await batch.commit();
      controller.clear();
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تعذر إرسال الرسالة. تحقق من قواعد Firestore.')));
    } finally { if (mounted) setState(() => busy = false); }
  }
  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.rtl,
    child: Scaffold(
      appBar: AppBar(title: Text(widget.otherName)),
      body: Column(children: [
        Expanded(child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _db.collection('conversations').doc(widget.conversationId).collection('messages').orderBy('createdAt').limit(300).snapshots(),
          builder: (context, s) {
            if (s.hasError) return const Center(child: Text('تعذر تحميل المحادثة'));
            if (!s.hasData) return const Center(child: CircularProgressIndicator());
            return ListView(padding: const EdgeInsets.all(12), children: s.data!.docs.map((doc) {
              final d = doc.data(); final mine = d['senderId'] == _uid;
              return Align(alignment: mine ? Alignment.centerRight : Alignment.centerLeft, child: Container(
                margin: const EdgeInsets.symmetric(vertical: 4), padding: const EdgeInsets.all(12),
                constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * .78),
                decoration: BoxDecoration(color: mine ? const Color(0xFFE9E5FF) : Colors.white, borderRadius: BorderRadius.circular(14)),
                child: Text(d['text'] as String? ?? ''),
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
        stream: _db.collection('notifications').where('recipientId', isEqualTo: _uid).orderBy('createdAt', descending: true).limit(100).snapshots(),
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
