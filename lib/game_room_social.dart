import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:just_audio/just_audio.dart';
import 'package:record/record.dart';
import 'livekit_calls.dart';
import 'local_bot.dart';
import 'media_upload_service.dart';

/// Shared text/voice-note chat and live voice room for multiplayer game rooms.
class GameRoomSocialPanel extends StatefulWidget {
  final String roomId;
  const GameRoomSocialPanel({super.key, required this.roomId});
  @override State<GameRoomSocialPanel> createState() => _GameRoomSocialPanelState();
}

class _GameRoomSocialPanelState extends State<GameRoomSocialPanel> {
  final _controller = TextEditingController();
  final _recorder = AudioRecorder();
  bool _sending = false, _recording = false;
  DateTime? _recordingStarted;
  String? _recordingPath;
  String? get _uid => FirebaseAuth.instance.currentUser?.uid;
  CollectionReference<Map<String, dynamic>> get _messages =>
      FirebaseFirestore.instance.collection('gameRooms').doc(widget.roomId).collection('chat');

  @override
  void dispose() {
    _controller.dispose();
    _recorder.dispose();
    super.dispose();
  }

  void _showNotice(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<String> _memberName(String uid) async {
    final user = FirebaseAuth.instance.currentUser!;
    final profile = await FirebaseFirestore.instance.collection('publicProfiles').doc(uid).get();
    final raw = (profile.data()?['name'] ?? user.displayName ?? 'لاعب').toString();
    return raw.length > 60 ? raw.substring(0, 60) : raw;
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    final uid = _uid;
    if (uid == null) { _showNotice('سجّل الدخول حتى تراسل لاعبين الغرفة.'); return; }
    if (text.isEmpty || _sending) return;
    if (text.length > 500) { _showNotice('الرسالة طويلة؛ الحد الأقصى 500 حرف.'); return; }
    setState(() => _sending = true);
    try {
      await _messages.add({
        'uid': uid, 'name': await _memberName(uid), 'text': text,
        'createdAt': FieldValue.serverTimestamp(),
      });
      _controller.clear();
    } catch (e) {
      _showNotice('تعذر إرسال رسالة اللعبة: $e');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _toggleVoiceNote() async {
    final uid = _uid;
    if (uid == null || _sending) { if (uid == null) _showNotice('سجّل الدخول أولاً.'); return; }
    if (!_recording) {
      try {
        if (!await _recorder.hasPermission()) { _showNotice('اسمح للتطبيق باستخدام المايك لتسجيل الفويس.'); return; }
        final dir = await Directory.systemTemp.createTemp('forum_game_voice_');
        final path = '${dir.path}/game_voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
        await _recorder.start(
          const RecordConfig(encoder: AudioEncoder.aacLc, bitRate: 64000, sampleRate: 44100),
          path: path,
        );
        if (mounted) setState(() { _recording = true; _recordingStarted = DateTime.now(); _recordingPath = path; });
      } catch (e) { _showNotice('تعذر بدء التسجيل: $e'); }
      return;
    }
    try {
      final stoppedPath = await _recorder.stop();
      final started = _recordingStarted;
      final path = stoppedPath ?? _recordingPath;
      if (mounted) setState(() { _recording = false; _recordingStarted = null; });
      if (started == null || path == null) return;
      final seconds = DateTime.now().difference(started).inSeconds;
      if (seconds < 1) { _showNotice('التسجيل قصير جداً.'); return; }
      if (seconds > 180) { _showNotice('الحد الأقصى للفويس 3 دقائق.'); return; }
      final file = File(path);
      if (!await file.exists() || await file.length() == 0) { _showNotice('ملف التسجيل فارغ.'); return; }
      setState(() => _sending = true);
      final url = await uploadForumMedia(
        XFile(path, name: 'game_voice_${DateTime.now().millisecondsSinceEpoch}.m4a'),
        folder: 'public-chat',
      );
      await _messages.add({
        'uid': uid, 'name': await _memberName(uid), 'text': 'رسالة صوتية',
        'type': 'voice', 'audioUrl': url, 'durationSeconds': seconds,
        'createdAt': FieldValue.serverTimestamp(),
      });
      try { await file.delete(); } catch (_) {}
      _showNotice('تم إرسال الرسالة الصوتية 🎙️');
    } catch (e) {
      if (mounted) setState(() => _recording = false);
      _showNotice('تعذر إرسال الفويس: $e');
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
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('حذف')),
        ],
      ),
    );
    if (confirmed != true) return;
    try { await doc.reference.delete(); _showNotice('تم حذف رسالتك.'); }
    catch (e) { _showNotice('تعذر حذف الرسالة: $e'); }
  }

  String _timeLabel(dynamic value) {
    if (value is! Timestamp) return 'الآن';
    final time = value.toDate();
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
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
            IconButton(
              tooltip: 'مساعد اللعبة',
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LocalHelperBotPage())),
              icon: const Icon(Icons.smart_toy_rounded),
            ),
            FilledButton.tonalIcon(
              onPressed: uid == null ? null : () => Navigator.push(context, MaterialPageRoute(
                builder: (_) => LiveKitCallsPage(initialRoom: 'game_${widget.roomId}'),
              )),
              icon: const Icon(Icons.mic_rounded), label: const Text('فويس مباشر'),
            ),
          ]),
          const Text('رسائل كتابية وصوتية، أو ادخلوا غرفة الصوت المباشرة أثناء اللعب.'),
          const SizedBox(height: 8),
          SizedBox(height: 230, child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _messages.orderBy('createdAt', descending: true).limit(40).snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) return const Center(child: Text('تعذر تحميل دردشة اللعبة'));
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              final docs = snapshot.data!.docs;
              if (docs.isEmpty) return const Center(child: Text('ابدأوا أول محادثة بين اللاعبين ✨'));
              return ListView.builder(
                reverse: true, itemCount: docs.length,
                itemBuilder: (context, index) {
                  final doc = docs[index], data = doc.data();
                  final mine = data['uid'] == uid;
                  final voiceUrl = data['audioUrl'] as String?;
                  final isVoice = data['type'] == 'voice' && voiceUrl != null;
                  final bubbleColor = mine ? Theme.of(context).colorScheme.primaryContainer : Theme.of(context).colorScheme.surfaceContainerHighest;
                  return Align(
                    alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * .82),
                      margin: const EdgeInsets.symmetric(vertical: 3),
                      padding: const EdgeInsetsDirectional.only(start: 11, end: 5, top: 7, bottom: 7),
                      decoration: BoxDecoration(
                        color: bubbleColor, borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: .35)),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Flexible(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(data['name']?.toString() ?? 'لاعب', maxLines: 1, overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
                          if (isVoice) _GameVoicePlayer(url: voiceUrl, durationSeconds: (data['durationSeconds'] as num?)?.toInt() ?? 0)
                          else Text(data['text']?.toString() ?? '', style: const TextStyle(height: 1.35)),
                          Align(alignment: AlignmentDirectional.centerEnd,
                            child: Text(_timeLabel(data['createdAt']), style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.onSurfaceVariant))),
                        ])),
                        if (mine) IconButton(
                          visualDensity: VisualDensity.compact, tooltip: 'حذف رسالتي',
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
            IconButton.filledTonal(
              tooltip: _recording ? 'إيقاف وإرسال الفويس' : 'تسجيل رسالة صوتية',
              onPressed: uid == null || _sending ? null : _toggleVoiceNote,
              icon: Icon(_recording ? Icons.stop_rounded : Icons.mic_rounded,
                color: _recording ? Theme.of(context).colorScheme.error : null),
            ),
            Expanded(child: TextField(
              controller: _controller, minLines: 1, maxLines: 3, maxLength: 500,
              enabled: uid != null && !_sending && !_recording,
              decoration: InputDecoration(counterText: '', hintText: _recording ? 'جاري تسجيل الفويس… اضغط إيقاف للإرسال' : 'رسالة للاعبين...', isDense: true),
              onSubmitted: (_) => _send(),
            )),
            const SizedBox(width: 6),
            IconButton.filled(
              onPressed: uid == null || _sending || _recording ? null : _send,
              icon: _sending ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.send_rounded),
            ),
          ]),
        ]),
      ),
    );
  }
}

class _GameVoicePlayer extends StatefulWidget {
  final String url;
  final int durationSeconds;
  const _GameVoicePlayer({required this.url, required this.durationSeconds});
  @override State<_GameVoicePlayer> createState() => _GameVoicePlayerState();
}

class _GameVoicePlayerState extends State<_GameVoicePlayer> {
  late final AudioPlayer _player;
  @override void initState() {
    super.initState();
    _player = AudioPlayer();
    _player.setUrl(widget.url).catchError((_) {});
  }
  @override void dispose() { _player.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) => SizedBox(
    width: 225,
    child: Row(children: [
      StreamBuilder<PlayerState>(
        stream: _player.playerStateStream,
        builder: (context, snapshot) {
          final playing = snapshot.data?.playing ?? false;
          return IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: () => playing ? _player.pause() : _player.play(),
            icon: Icon(playing ? Icons.pause_circle_filled_rounded : Icons.play_circle_fill_rounded, size: 32),
          );
        },
      ),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('رسالة صوتية', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        StreamBuilder<Duration>(
          stream: _player.positionStream,
          builder: (context, snapshot) {
            final position = snapshot.data ?? Duration.zero;
            final total = _player.duration ?? Duration(seconds: widget.durationSeconds);
            final max = total.inMilliseconds > 0 ? total.inMilliseconds.toDouble() : 1.0;
            return Column(children: [
              Slider(
                value: position.inMilliseconds.toDouble().clamp(0, max).toDouble(),
                min: 0, max: max, onChanged: (value) => _player.seek(Duration(milliseconds: value.toInt())),
              ),
              Text('${position.inSeconds}s / ${total.inSeconds}s', style: const TextStyle(fontSize: 10)),
            ]);
          },
        ),
      ])),
    ]),
  );
}
