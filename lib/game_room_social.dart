import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'livekit_calls.dart';

/// Shared live text chat and voice-room entry for multiplayer game rooms.
class GameRoomSocialPanel extends StatefulWidget {
  final String roomId;
  const GameRoomSocialPanel({super.key, required this.roomId});
  @override State<GameRoomSocialPanel> createState() => _GameRoomSocialPanelState();
}

class _GameRoomSocialPanelState extends State<GameRoomSocialPanel> {
  final _controller = TextEditingController();
  bool _sending = false;
  String? get _uid => FirebaseAuth.instance.currentUser?.uid;
  CollectionReference<Map<String, dynamic>> get _messages =>
      FirebaseFirestore.instance.collection('gameRooms').doc(widget.roomId).collection('chat');

  @override
  void dispose() { _controller.dispose(); super.dispose(); }

  void _showNotice(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    final uid = _uid;
    if (uid == null) {
      _showNotice('سجّل الدخول حتى تراسل لاعبين الغرفة.');
      return;
    }
    if (text.isEmpty || _sending) return;
    if (text.length > 500) {
      _showNotice('الرسالة طويلة؛ الحد الأقصى 500 حرف.');
      return;
    }
    setState(() => _sending = true);
    try {
      final user = FirebaseAuth.instance.currentUser!;
      final profile = await FirebaseFirestore.instance.collection('publicProfiles').doc(uid).get();
      await _messages.add({
        'uid': uid,
        'name': (profile.data()?['name'] ?? user.displayName ?? 'لاعب').toString().substring(
          0,
          (profile.data()?['name'] ?? user.displayName ?? 'لاعب').toString().length.clamp(0, 60),
        ),
        'text': text,
        'createdAt': FieldValue.serverTimestamp(),
      });
      _controller.clear();
    } catch (e) {
      _showNotice('تعذر إرسال رسالة اللعبة: $e');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _deleteMessage(QueryDocumentSnapshot<Map<String, dynamic>> doc) async {
    final uid = _uid;
    if (uid == null || doc.data()['uid'] != uid) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('حذف رسالة اللعبة؟'),
        content: const Text('سيتم حذف الرسالة من دردشة هذه الغرفة.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('إلغاء')),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await doc.reference.delete();
      _showNotice('تم حذف رسالتك.');
    } catch (e) {
      _showNotice('تعذر حذف الرسالة: $e');
    }
  }

  String _timeLabel(dynamic value) {
    if (value is! Timestamp) return 'الآن';
    final time = value.toDate();
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  @override Widget build(BuildContext context) {
    final uid = _uid;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            const Expanded(child: Text('دردشة اللاعبين', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16))),
            FilledButton.tonalIcon(
              onPressed: uid == null ? null : () => Navigator.push(context, MaterialPageRoute(
                builder: (_) => LiveKitCallsPage(initialRoom: 'game_${widget.roomId}'),
              )),
              icon: const Icon(Icons.mic_rounded),
              label: const Text('فويس اللعبة'),
            ),
          ]),
          const Text('احچوا ويّا بعض أثناء اللعب، أو ادخلوا غرفة الصوت المشتركة.'),
          const SizedBox(height: 8),
          SizedBox(height: 210, child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _messages.orderBy('createdAt', descending: true).limit(40).snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) return const Center(child: Text('تعذر تحميل دردشة اللعبة'));
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              final docs = snapshot.data!.docs;
              if (docs.isEmpty) return const Center(child: Text('ابدأوا أول محادثة بين اللاعبين ✨'));
              return ListView.builder(
                reverse: true,
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final doc = docs[index];
                  final data = doc.data();
                  final mine = data['uid'] == uid;
                  final bubbleColor = mine
                    ? Theme.of(context).colorScheme.primaryContainer
                    : Theme.of(context).colorScheme.surfaceContainerHighest;
                  return Align(
                    alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * .78),
                      margin: const EdgeInsets.symmetric(vertical: 3),
                      padding: const EdgeInsetsDirectional.only(start: 11, end: 5, top: 7, bottom: 7),
                      decoration: BoxDecoration(
                        color: bubbleColor,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: .35)),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Flexible(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(
                            data['name']?.toString() ?? 'لاعب',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary),
                          ),
                          Text(data['text']?.toString() ?? '', style: const TextStyle(height: 1.35)),
                          Align(
                            alignment: AlignmentDirectional.centerEnd,
                            child: Text(_timeLabel(data['createdAt']), style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                          ),
                        ])),
                        if (mine)
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            tooltip: 'حذف رسالتي',
                            onPressed: () => _deleteMessage(doc),
                            icon: Icon(Icons.delete_outline_rounded, size: 18, color: Theme.of(context).colorScheme.error),
                          ),
                      ]),
                    ),
                  );
                },
              );
            },
          )),
          Row(children: [
            Expanded(child: TextField(
              controller: _controller,
              minLines: 1,
              maxLines: 3,
              maxLength: 500,
              enabled: uid != null && !_sending,
              decoration: const InputDecoration(counterText: '', hintText: 'رسالة للاعبين...', isDense: true),
              onSubmitted: (_) => _send(),
            )),
            const SizedBox(width: 6),
            IconButton.filled(
              onPressed: uid == null || _sending ? null : _send,
              icon: _sending
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.send_rounded),
            ),
          ]),
        ]),
      ),
    );
  }
}
