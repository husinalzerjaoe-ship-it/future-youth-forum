import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import 'media_upload_service.dart';

/// Permanent member clips. Unlike stories, clips do not expire automatically.
class CommunityReelsPage extends StatefulWidget {
  const CommunityReelsPage({super.key});

  @override
  State<CommunityReelsPage> createState() => _CommunityReelsPageState();
}

class _CommunityReelsPageState extends State<CommunityReelsPage> {
  final _pages = PageController();
  bool _uploading = false;
  int _activeIndex = 0;

  Future<void> _publishClip() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _uploading) return;
    final picker = ImagePicker();
    final file = await picker.pickVideo(
      source: ImageSource.gallery,
      maxDuration: const Duration(seconds: 120),
    );
    if (file == null || !mounted) return;

    final caption = TextEditingController();
    final publish = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('نشر مقطع للملتقى'),
        content: TextField(
          controller: caption,
          maxLength: 500,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'اكتب وصفاً للمقطع (اختياري)',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('متابعة'),
          ),
        ],
      ),
    );
    if (publish != true || !mounted) {
      caption.dispose();
      return;
    }

    setState(() => _uploading = true);
    try {
      final url = await uploadForumMedia(file, folder: 'stories');
      final profile = await FirebaseFirestore.instance
          .collection('publicProfiles')
          .doc(user.uid)
          .get();
      await FirebaseFirestore.instance.collection('communityClips').add({
        'authorId': user.uid,
        'authorName': profile.data()?['name'] ?? user.displayName ?? 'عضو',
        'authorPhoto': profile.data()?['photoUrl'] ?? '',
        'caption': caption.text.trim(),
        'videoUrl': url,
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم نشر المقطع في مقاطع الملتقى')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تعذر نشر المقطع: $error')),
        );
      }
    } finally {
      caption.dispose();
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            title: const Text('مقاطع الملتقى'),
            actions: [
              IconButton(
                tooltip: 'نشر مقطع',
                onPressed: _uploading ? null : _publishClip,
                icon: _uploading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.add_box_outlined),
              ),
            ],
          ),
          body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('communityClips')
                .orderBy('createdAt', descending: true)
                .limit(100)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const Center(
                  child: Text(
                    'تعذر تحميل المقاطع. تحقق من الاتصال وقواعد Firestore.',
                    style: TextStyle(color: Colors.white70),
                    textAlign: TextAlign.center,
                  ),
                );
              }
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final clips = snapshot.data!.docs;
              if (clips.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.video_library_outlined,
                            color: Colors.white54, size: 64),
                        const SizedBox(height: 14),
                        const Text(
                          'مقاطع الملتقى بانتظار أول فيديو!',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        FilledButton.icon(
                          onPressed: _uploading ? null : _publishClip,
                          icon: const Icon(Icons.add),
                          label: const Text('انشر أول مقطع'),
                        ),
                      ],
                    ),
                  ),
                );
              }
              return PageView.builder(
                controller: _pages,
                scrollDirection: Axis.vertical,
                itemCount: clips.length,
                onPageChanged: (index) => setState(() => _activeIndex = index),
                itemBuilder: (context, index) => _CommunityReelTile(
                  key: ValueKey(clips[index].id),
                  clip: clips[index],
                  active: index == _activeIndex,
                ),
              );
            },
          ),
        ),
      );
}

class _CommunityReelTile extends StatefulWidget {
  final QueryDocumentSnapshot<Map<String, dynamic>> clip;
  final bool active;
  const _CommunityReelTile({super.key, required this.clip, required this.active});

  @override
  State<_CommunityReelTile> createState() => _CommunityReelTileState();
}

class _CommunityReelTileState extends State<_CommunityReelTile> {
  VideoPlayerController? _video;
  bool _loading = true;
  bool _muted = false;
  bool _busy = false;
  final AudioRecorder _commentRecorder = AudioRecorder();
  bool _recordingComment = false;
  DateTime? _commentVoiceStarted;

  String get _uid => FirebaseAuth.instance.currentUser!.uid;
  CollectionReference<Map<String, dynamic>> get _likes => FirebaseFirestore
      .instance
      .collection('communityClips')
      .doc(widget.clip.id)
      .collection('likes');
  CollectionReference<Map<String, dynamic>> get _comments => FirebaseFirestore
      .instance
      .collection('communityClips')
      .doc(widget.clip.id)
      .collection('comments');

  @override
  void initState() {
    super.initState();
    if (widget.active) _initializeVideo();
  }

  @override
  void didUpdateWidget(covariant _CommunityReelTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.active != widget.active) {
      if (widget.active) {
        _initializeVideo();
      } else {
        _video?.pause();
        _video?.dispose();
        _video = null;
      }
    }
  }

  Future<void> _initializeVideo() async {
    final url = (widget.clip.data()['videoUrl'] ?? '').toString();
    if (!url.startsWith('https://')) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    final controller = VideoPlayerController.networkUrl(Uri.parse(url));
    try {
      await controller.initialize().timeout(const Duration(seconds: 25));
      await controller.setLooping(true);
      await controller.setVolume(_muted ? 0 : 1);
      if (!mounted) {
        await controller.dispose();
        return;
      }
      _video = controller;
      setState(() => _loading = false);
      await controller.play();
    } catch (_) {
      await controller.dispose();
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggleLike() async {
    final ref = _likes.doc(_uid);
    final existing = await ref.get();
    if (existing.exists) {
      await ref.delete();
    } else {
      await ref.set({
        'uid': _uid,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> _showComments() async {
    final input = TextEditingController();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => Directionality(
        textDirection: TextDirection.rtl,
        child: Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 18,
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 16,
          ),
          child: SizedBox(
            height: MediaQuery.of(sheetContext).size.height * .62,
            child: Column(
              children: [
                const Text('تعليقات المقطع',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Expanded(
                  child: StreamBuilder<
                      QuerySnapshot<Map<String, dynamic>>>(
                    stream: _comments
                        .orderBy('createdAt', descending: true)
                        .limit(100)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(
                            child: CircularProgressIndicator());
                      }
                      if (snapshot.data!.docs.isEmpty) {
                        return const Center(child: Text('لا توجد تعليقات بعد'));
                      }
                      return ListView(
                        children: snapshot.data!.docs.map((doc) {
                          final data = doc.data();
                          return ListTile(
                            leading: const CircleAvatar(
                                child: Icon(Icons.person_outline)),
                            title: Text(
                                (data['authorName'] ?? 'عضو').toString()),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if ((data['text'] ?? '').toString().isNotEmpty)
                                  Text((data['text'] ?? '').toString()),
                                if (data['mediaType'] == 'audio' && data['audioUrl'] is String)
                                  _ReelCommentAudio(url: data['audioUrl'] as String),
                                if ((data['mediaType'] == 'image' || data['mediaType'] == 'gif') && data['mediaUrl'] is String)
                                  Padding(padding: const EdgeInsets.only(top: 6),
                                    child: ClipRRect(borderRadius: BorderRadius.circular(10),
                                      child: Image.network(data['mediaUrl'] as String, width: 190, height: 150,
                                        fit: BoxFit.contain,
                                        errorBuilder: (_, __, ___) => const Text('تعذر عرض المرفق')))),
                              ],
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                ),
                Row(
                  children: [
                    IconButton(tooltip: 'إرفاق صورة', onPressed: () => _sendCommentMedia(kind: 'image'),
                      icon: const Icon(Icons.image_outlined)),
                    IconButton(tooltip: 'إرفاق GIF متحرك', onPressed: () => _sendCommentMedia(kind: 'gif'),
                      icon: const Icon(Icons.gif_box_outlined)),
                    IconButton(tooltip: _recordingComment ? 'إيقاف وإرسال الفويس' : 'تسجيل فويس',
                      color: _recordingComment ? Colors.red : null, onPressed: _toggleCommentVoice,
                      icon: Icon(_recordingComment ? Icons.stop_circle : Icons.mic_none)),
                    Expanded(
                      child: TextField(
                        controller: input,
                        maxLength: 300,
                        decoration: const InputDecoration(
                          hintText: 'اكتب تعليقاً...',
                          counterText: '',
                        ),
                      ),
                    ),
                    IconButton.filled(
                      onPressed: () async {
                        final text = input.text.trim();
                        if (text.isEmpty) return;
                        final profile = await FirebaseFirestore.instance
                            .collection('publicProfiles')
                            .doc(_uid)
                            .get();
                        await _comments.add({
                          'authorId': _uid,
                          'authorName':
                              profile.data()?['name'] ?? 'عضو',
                          'text': text,
                          'createdAt': FieldValue.serverTimestamp(),
                        });
                        input.clear();
                      },
                      icon: const Icon(Icons.send),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
    input.dispose();
  }

  Future<void> _shareClipPrivately() async {
    final profiles = await FirebaseFirestore.instance.collection('publicProfiles').limit(100).get();
    if (!mounted) return;
    final candidates = profiles.docs.where((p) => p.id != _uid).toList();
    final recipient = await showModalBottomSheet<QueryDocumentSnapshot<Map<String, dynamic>>>(
      context: context, isScrollControlled: true,
      builder: (sheetContext) => Directionality(
        textDirection: TextDirection.rtl,
        child: SafeArea(child: SizedBox(
          height: MediaQuery.of(sheetContext).size.height * .65,
          child: Column(children: [
            const Padding(padding: EdgeInsets.all(16), child: Text('مشاركة المقطع برسالة خاصة',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18))),
            Expanded(child: ListView.builder(
              itemCount: candidates.length,
              itemBuilder: (context, index) {
                final profile = candidates[index];
                final data = profile.data();
                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: (data['photoUrl'] is String && (data['photoUrl'] as String).startsWith('https://'))
                      ? NetworkImage(data['photoUrl'] as String) : null,
                    child: const Icon(Icons.person_outline)),
                  title: Text((data['name'] ?? 'عضو').toString()),
                  onTap: () => Navigator.pop(sheetContext, profile));
              })),
          ]),
        )),
      ),
    );
    if (recipient == null) return;
    final otherUid = recipient.id;
    final otherName = (recipient.data()['name'] ?? 'عضو').toString();
    final members = <String>[_uid, otherUid]..sort();
    final conversationId = members.join('_');
    final db = FirebaseFirestore.instance;
    final me = await db.collection('publicProfiles').doc(_uid).get();
    final myName = (me.data()?['name'] ?? FirebaseAuth.instance.currentUser?.displayName ?? 'عضو').toString();
    final conversation = db.collection('conversations').doc(conversationId);
    await conversation.set({
      'members': members, 'memberA': members[0], 'memberB': members[1],
      'memberNames': {_uid: myName, otherUid: otherName},
      'lastMessage': '🎬 تمت مشاركة مقطع من مقاطع الملتقى',
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    await conversation.collection('messages').add({
      'text': '🎬 شاهد هذا المقطع من ملتقى شباب المستقبل',
      'type': 'video', 'videoUrl': widget.clip.data()['videoUrl'],
      'senderId': _uid, 'senderRole': 'member', 'senderName': myName,
      'createdAt': FieldValue.serverTimestamp(),
      'sharedClipId': widget.clip.id,
    });
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('تمت مشاركة المقطع مع $otherName')));
  }

  Future<void> _sendCommentMedia({required String kind}) async {
    try {
      XFile? file;
      if (kind == 'gif') {
        final picked = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: const ['gif']);
        final path = picked?.files.single.path;
        if (path != null) file = XFile(path, name: picked!.files.single.name);
      } else {
        file = await ImagePicker().pickImage(source: ImageSource.gallery);
      }
      if (file == null) return;
      final url = await uploadForumMedia(file, folder: 'stories');
      final profile = await FirebaseFirestore.instance.collection('publicProfiles').doc(_uid).get();
      await _comments.add({
        'authorId': _uid, 'authorName': profile.data()?['name'] ?? 'عضو',
        'text': '', 'mediaType': kind == 'gif' ? 'gif' : 'image',
        'mediaUrl': url, 'mediaFormat': kind == 'gif' ? 'gif' : 'image',
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر إرفاق الصورة: $error')));
    }
  }

  Future<void> _toggleCommentVoice() async {
    try {
      if (!_recordingComment) {
        if (!await _commentRecorder.hasPermission()) throw StateError('يلزم السماح باستخدام الميكروفون.');
        final dir = await getTemporaryDirectory();
        final path = '${dir.path}/reel_comment_${DateTime.now().millisecondsSinceEpoch}.m4a';
        await _commentRecorder.start(
          const RecordConfig(encoder: AudioEncoder.aacLc, bitRate: 64000, sampleRate: 44100),
          path: path);
        if (mounted) setState(() { _recordingComment = true; _commentVoiceStarted = DateTime.now(); });
        return;
      }
      final path = await _commentRecorder.stop();
      final started = _commentVoiceStarted;
      if (mounted) setState(() { _recordingComment = false; _commentVoiceStarted = null; });
      if (path == null || started == null) return;
      final seconds = DateTime.now().difference(started).inSeconds.clamp(1, 180);
      final url = await uploadForumMedia(
        XFile(path, name: 'reel_comment_${DateTime.now().millisecondsSinceEpoch}.m4a'),
        folder: 'voice-messages');
      final profile = await FirebaseFirestore.instance.collection('publicProfiles').doc(_uid).get();
      await _comments.add({
        'authorId': _uid, 'authorName': profile.data()?['name'] ?? 'عضو',
        'text': '', 'mediaType': 'audio', 'audioUrl': url,
        'durationSeconds': seconds, 'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (error) {
      if (mounted) setState(() => _recordingComment = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر تسجيل التعليق الصوتي: $error')));
    }
  }

  Future<void> _reportClip() async {
    final reason = await showDialog<String>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: const Text('الإبلاغ عن المقطع'),
        children: [
          for (final item in [
            'محتوى غير مناسب',
            'تنمّر أو إساءة',
            'انتحال أو تضليل',
            'سبب آخر',
          ])
            SimpleDialogOption(
              onPressed: () => Navigator.pop(dialogContext, item),
              child: Text(item),
            ),
        ],
      ),
    );
    if (reason == null) return;
    await FirebaseFirestore.instance.collection('reports').add({
      'reporterId': _uid,
      'targetId': widget.clip.id,
      'targetType': 'communityClip',
      'reason': reason,
      'status': 'new',
      'createdAt': FieldValue.serverTimestamp(),
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم إرسال البلاغ للمراجعة')),
      );
    }
  }

  Future<void> _deleteClip() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('حذف المقطع؟'),
        content: const Text('سيتم حذف المقطع من مقاطع الملتقى.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final data = widget.clip.data();
    final url = (data['videoUrl'] ?? '').toString();
    if (url.startsWith('https://')) {
      try {
        await deleteForumMedia(url);
      } catch (_) {}
    }
    await widget.clip.reference.delete();
  }

  @override
  void dispose() {
    _video?.dispose();
    _commentRecorder.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.clip.data();
    final authorId = (data['authorId'] ?? '').toString();
    final isOwner = authorId == _uid;
    return Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: Colors.black),
        if (widget.active && _video?.value.isInitialized == true)
          Center(
            child: AspectRatio(
              aspectRatio: _video!.value.aspectRatio,
              child: VideoPlayer(_video!),
            ),
          )
        else if (_loading)
          const Center(
              child: CircularProgressIndicator(color: Colors.white))
        else
          const Center(
            child: Icon(Icons.video_library_outlined,
                color: Colors.white54, size: 64),
          ),
        Positioned(
          right: 14,
          left: 14,
          bottom: 24,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Colors.black.withValues(alpha: .88),
                  Colors.transparent,
                ],
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 48, 8, 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '@${data['authorName'] ?? 'عضو'}',
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold),
                        ),
                        if ((data['caption'] ?? '').toString().isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              data['caption'].toString(),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        const SizedBox(height: 8),
                        const Text(
                          'مقاطع دائمة لمجتمع ملتقى شباب المستقبل',
                          style:
                              TextStyle(color: Colors.white70, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                        stream: _likes.doc(_uid).snapshots(),
                        builder: (context, snapshot) => IconButton(
                          color: Colors.white,
                          onPressed: _toggleLike,
                          icon: Icon(snapshot.data?.exists == true
                              ? Icons.favorite
                              : Icons.favorite_border),
                        ),
                      ),
                      StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                        stream: _likes.snapshots(),
                        builder: (context, snapshot) => Text(
                          '${snapshot.data?.docs.length ?? 0}',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      IconButton(
                        color: Colors.white,
                        onPressed: _showComments,
                        icon: const Icon(Icons.mode_comment_outlined),
                      ),
                      IconButton(
                        color: Colors.white,
                        tooltip: 'مشاركة برسالة خاصة',
                        onPressed: _shareClipPrivately,
                        icon: const Icon(Icons.send_outlined),
                      ),
                      IconButton(
                        color: Colors.white,
                        onPressed: _reportClip,
                        icon: const Icon(Icons.flag_outlined),
                      ),
                      if (isOwner)
                        IconButton(
                          color: Colors.white,
                          onPressed: _busy
                              ? null
                              : () async {
                                  setState(() => _busy = true);
                                  try {
                                    await _deleteClip();
                                  } finally {
                                    if (mounted) setState(() => _busy = false);
                                  }
                                },
                          icon: const Icon(Icons.delete_outline),
                        ),
                      IconButton(
                        color: Colors.white,
                        tooltip: _muted ? 'تشغيل الصوت' : 'كتم الصوت',
                        onPressed: () async {
                          _muted = !_muted;
                          await _video?.setVolume(_muted ? 0 : 1);
                          if (mounted) setState(() {});
                        },
                        icon: Icon(
                            _muted ? Icons.volume_off : Icons.volume_up),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
