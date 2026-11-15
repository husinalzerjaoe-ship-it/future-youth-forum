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
  String get _uid => FirebaseAuth.instance.currentUser!.uid;
  CollectionReference<Map<String, dynamic>> get _messages =>
      FirebaseFirestore.instance.collection('gameRooms').doc(widget.roomId).collection('chat');

  @override void dispose() { _controller.dispose(); super.dispose(); }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      final user = FirebaseAuth.instance.currentUser!;
      final profile = await FirebaseFirestore.instance.collection('publicProfiles').doc(_uid).get();
      await _messages.add({
        'uid': _uid,
        'name': profile.data()?['name'] ?? user.displayName ?? 'لاعب',
        'text': text,
        'createdAt': FieldValue.serverTimestamp(),
      });
      _controller.clear();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تعذر إرسال رسالة اللعبة: $e')));
    } finally { if (mounted) setState(() => _sending = false); }
  }

  @override Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.symmetric(vertical: 10),
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          const Expanded(child: Text('دردشة اللاعبين', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16))),
          FilledButton.tonalIcon(
            onPressed: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => LiveKitCallsPage(initialRoom: 'game_${widget.roomId}'),
            )),
            icon: const Icon(Icons.mic_rounded),
            label: const Text('فويس اللعبة'),
          ),
        ]),
        const Text('احچوا ويّا بعض أثناء اللعب، أو ادخلوا غرفة الصوت المشتركة.'),
        const SizedBox(height: 8),
        SizedBox(height: 180, child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
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
                final data = docs[index].data();
                final mine = data['uid'] == _uid;
                return Align(
                  alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 3),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    decoration: BoxDecoration(
                      color: mine ? const Color(0xFFE9E3FF) : Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(data['name']?.toString() ?? 'لاعب', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF6554D9))),
                      Text(data['text']?.toString() ?? ''),
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
            maxLines: 2,
            maxLength: 500,
            decoration: const InputDecoration(counterText: '', hintText: 'رسالة للاعبين...', isDense: true),
            onSubmitted: (_) => _send(),
          )),
          const SizedBox(width: 6),
          IconButton.filled(onPressed: _sending ? null : _send, icon: const Icon(Icons.send_rounded)),
        ]),
      ]),
    ),
  );
}
