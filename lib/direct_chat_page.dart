import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

const _directBrand = Color(0xFF6554D9);

class DirectChatPage extends StatefulWidget {
  final String conversationId;
  final String otherUid;
  final String otherName;
  const DirectChatPage({super.key, required this.conversationId, required this.otherUid, required this.otherName});
  @override State<DirectChatPage> createState() => _DirectChatPageState();
}

class _DirectChatPageState extends State<DirectChatPage> {
  final _db = FirebaseFirestore.instance;
  final _text = TextEditingController();
  bool _sending = false;
  String? _sendError;
  String get _uid => FirebaseAuth.instance.currentUser!.uid;
  CollectionReference<Map<String, dynamic>> get _messages =>
      _db.collection('conversations').doc(widget.conversationId).collection('messages');

  @override
  void dispose() { _text.dispose(); super.dispose(); }

  Future<void> _send() async {
    final value = _text.text.trim();
    if (value.isEmpty || _sending) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    setState(() { _sending = true; _sendError = null; });
    try {
      final profile = await _db.collection('publicProfiles').doc(user.uid).get();
      final name = profile.data()?['name'] as String? ?? user.displayName ?? 'عضو';
      final founder = user.email?.toLowerCase() == 'husinalzerjaoe@gmail.com';
      await _messages.add({
        'text': value, 'type': 'text', 'senderId': user.uid,
        'senderRole': founder ? 'founder' : 'member',
        'senderName': name, 'createdAt': FieldValue.serverTimestamp(),
      });
      _text.clear();
    } on FirebaseException catch (e) {
      if (mounted) setState(() => _sendError = 'تعذر إرسال الرسالة (\${e.code}): \${e.message ?? ''}');
    } catch (e) {
      if (mounted) setState(() => _sendError = 'تعذر إرسال الرسالة: $e');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  String _time(dynamic value) {
    if (value is! Timestamp) return '';
    final d = value.toDate().toLocal();
    return '\${d.hour.toString().padLeft(2, '0')}:\${d.minute.toString().padLeft(2, '0')}';
  }

  Widget _bubble(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final mine = data['senderId'] == _uid;
    final founder = data['senderRole'] == 'founder';
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * .82),
        margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 12),
        padding: const EdgeInsets.fromLTRB(13, 9, 13, 7),
        decoration: BoxDecoration(
          color: mine ? const Color(0xFFE9E4FF) : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(17), topRight: const Radius.circular(17),
            bottomLeft: Radius.circular(mine ? 17 : 4), bottomRight: Radius.circular(mine ? 4 : 17),
          ),
          border: Border.all(color: founder ? const Color(0xFFFFC857) : _directBrand.withValues(alpha: .16)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (!mine) Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(data['senderName'] as String? ?? widget.otherName,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold,
                color: founder ? const Color(0xFFB77900) : _directBrand)),
          ),
          Text(data['text'] as String? ?? '', style: const TextStyle(fontSize: 15)),
          Align(alignment: Alignment.bottomLeft,
            child: Text(_time(data['createdAt']), style: TextStyle(fontSize: 10, color: Colors.grey.shade600))),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.rtl,
    child: Scaffold(
      appBar: AppBar(title: Row(children: [
        CircleAvatar(radius: 17, child: Text(widget.otherName.isNotEmpty ? widget.otherName.characters.first : '؟')),
        const SizedBox(width: 10),
        Expanded(child: Text(widget.otherName, maxLines: 1, overflow: TextOverflow.ellipsis)),
      ])),
      body: Column(children: [
        Expanded(child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _messages.orderBy('createdAt', descending: true).limit(150).snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              final error = snapshot.error;
              final code = error is FirebaseException ? error.code : 'unknown';
              return Center(child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.lock_outline, size: 42, color: Colors.redAccent),
                  const SizedBox(height: 10),
                  const Text('تعذر تحميل الرسائل الخاصة'),
                  const SizedBox(height: 5),
                  Text('رمز الخطأ: $code', style: const TextStyle(fontSize: 12, color: Colors.redAccent)),
                  const SizedBox(height: 8),
                  const Text('تأكد من نشر قواعد Firestore المحدّثة وأن حسابك عضو بالمحادثة.',
                    textAlign: TextAlign.center, style: TextStyle(fontSize: 12)),
                ]),
              ));
            }
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
            final docs = snapshot.data!.docs;
            if (docs.isEmpty) return const Center(child: Text('ابدأ المحادثة برسالة لطيفة 👋'));
            return ListView.builder(reverse: true, padding: const EdgeInsets.symmetric(vertical: 12),
              itemCount: docs.length, itemBuilder: (context, index) => _bubble(docs[index]));
          },
        )),
        if (_sendError != null) Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Text(_sendError!, style: const TextStyle(color: Colors.red, fontSize: 12))),
        SafeArea(top: false, child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 7, 10, 9),
          child: Row(children: [
            Expanded(child: TextField(
              controller: _text, minLines: 1, maxLines: 4, maxLength: 1000,
              textInputAction: TextInputAction.send, onSubmitted: (_) => _send(),
              decoration: InputDecoration(hintText: 'اكتب رسالة خاصة...', counterText: '', filled: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none)),
            )),
            const SizedBox(width: 7),
            CircleAvatar(backgroundColor: _directBrand, child: IconButton(
              onPressed: _sending ? null : _send,
              icon: _sending ? const SizedBox(width: 18, height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.send_rounded, color: Colors.white),
            )),
          ]),
        )),
      ]),
    ),
  );
}
