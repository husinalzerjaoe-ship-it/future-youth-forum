import 'dart:async';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:livekit_client/livekit_client.dart' as lk;
import 'package:shared_preferences/shared_preferences.dart';

class LiveKitCallsPage extends StatefulWidget {
  final String? initialRoom;
  final VoidCallback? onContinue;
  const LiveKitCallsPage({super.key, this.initialRoom, this.onContinue});

  @override
  State<LiveKitCallsPage> createState() => _LiveKitCallsPageState();
}

class _LiveKitCallsPageState extends State<LiveKitCallsPage> {
  static const _endpointKey = 'livekit_token_endpoint';
  static const _defaultEndpoint = 'https://future-youth-forum-livekit-token.husinalzerjaoe.workers.dev';
  static const _serverUrl = 'wss://youth-forum-future-lu43byvc.livekit.cloud';
  final _roomController = TextEditingController();
  final _endpointController = TextEditingController();
  lk.Room? _room;
  lk.EventsListener<lk.RoomEvent>? _listener;
  bool _connecting = false;
  bool _videoEnabled = false;
  bool _microphoneEnabled = true;
  bool _speakerEnabled = true;
  int _videoFilter = 0;
  String? _error;
  String? _endpoint;
  OverlayEntry? _miniCallOverlay;
  final _friendUidController = TextEditingController();
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _incomingCalls;
  String? _activeCallId;
  bool _showIncomingDialog = false;

  @override
  void initState() {
    super.initState();
    _roomController.text = widget.initialRoom ?? '';
    _loadEndpoint();
    _listenForIncomingCalls();
  }

  Future<void> _loadEndpoint() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_endpointKey) ?? _defaultEndpoint;
    if (!prefs.containsKey(_endpointKey)) await prefs.setString(_endpointKey, saved);
    if (!mounted) return;
    setState(() {
      _endpoint = saved;
      _endpointController.text = saved;
    });
  }

  Future<void> _configureEndpoint() async {
    _endpointController.text = _endpoint ?? '';
    final saved = await showDialog<String>(
      context: context,
      builder: (dialogContext) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('رابط خادم المكالمات'),
          content: TextField(
            controller: _endpointController,
            keyboardType: TextInputType.url,
            decoration: const InputDecoration(
              labelText: 'Cloudflare Worker URL',
              hintText: 'https://your-worker.workers.dev',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('إلغاء')),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, _endpointController.text.trim()),
              child: const Text('حفظ'),
            ),
          ],
        ),
      ),
    );
    if (saved == null) return;
    final uri = Uri.tryParse(saved);
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty || uri.host.toLowerCase() == 'meet.jit.si') {
      setState(() => _error = 'هذا ليس رابط خادم LiveKit. رابط Jitsi يُستخدم في صفحة المكالمات الاحتياطية، أما هنا فأدخل رابط Cloudflare Worker الذي ينتهي بـ workers.dev.');
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_endpointKey, saved.replaceFirst(RegExp(r'/+$'), ''));
    if (!mounted) return;
    setState(() {
      _endpoint = saved.replaceFirst(RegExp(r'/+$'), '');
      _error = null;
    });
  }


  void _listenForIncomingCalls() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    _incomingCalls = FirebaseFirestore.instance
        .collection('callSessions')
        .where('calleeId', isEqualTo: user.uid)
        .where('status', isEqualTo: 'ringing')
        .limit(1)
        .snapshots()
        .listen((snapshot) {
      if (!mounted || _showIncomingDialog || _room != null || snapshot.docs.isEmpty) return;
      final call = snapshot.docs.first;
      final data = call.data();
      if (data['callerId'] == user.uid) return;
      _showIncomingDialog = true;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        final callerName = (data['callerName'] ?? 'عضو من الملتقى').toString();
        final video = data['videoEnabled'] == true;
        final accepted = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) => Directionality(
            textDirection: TextDirection.rtl,
            child: AlertDialog(
              title: Text(video ? 'مكالمة فيديو واردة' : 'مكالمة صوتية واردة'),
              content: Text('$callerName يتصل بك الآن'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('رفض'),
                ),
                FilledButton.icon(
                  onPressed: () => Navigator.pop(dialogContext, true),
                  icon: const Icon(Icons.call_rounded),
                  label: const Text('قبول'),
                ),
              ],
            ),
          ),
        );
        _showIncomingDialog = false;
        if (!mounted) return;
        if (accepted == true) {
          try {
            await call.reference.update({
              'status': 'accepted',
              'acceptedAt': FieldValue.serverTimestamp(),
            });
            _activeCallId = call.id;
            _roomController.text = (data['roomName'] ?? '').toString();
            _videoEnabled = video;
            if (mounted) setState(() {});
            await _joinRoom();
          } catch (error) {
            if (mounted) setState(() => _error = 'تعذر قبول المكالمة: $error');
          }
        } else {
          await call.reference.update({
            'status': 'rejected',
            'endedAt': FieldValue.serverTimestamp(),
          });
        }
      });
    }, onError: (Object error) {
      if (mounted) setState(() => _error = 'تعذر استقبال المكالمات داخل التطبيق: $error');
    });
  }

  Future<void> _startDirectCall() async {
    final user = FirebaseAuth.instance.currentUser;
    final friendUid = _friendUidController.text.trim();
    if (user == null) {
      setState(() => _error = 'سجّل الدخول أولاً.');
      return;
    }
    if (!RegExp(r'^[A-Za-z0-9:_-]{10,128}$').hasMatch(friendUid) || friendUid == user.uid) {
      setState(() => _error = 'أدخل معرّف Firebase الصحيح لصديقك.');
      return;
    }
    try {
      final callRef = FirebaseFirestore.instance.collection('callSessions').doc();
      final roomName = 'fyf-call-${callRef.id}';
      await callRef.set({
        'callerId': user.uid,
        'callerName': user.displayName ?? 'عضو',
        'calleeId': friendUid,
        'roomName': roomName,
        'videoEnabled': _videoEnabled,
        'status': 'ringing',
        'createdAt': FieldValue.serverTimestamp(),
      });
      _activeCallId = callRef.id;
      _roomController.text = roomName;
      await _joinRoom();
      if (_room == null) {
        await callRef.update({
          'status': 'failed',
          'endedAt': FieldValue.serverTimestamp(),
        });
        _activeCallId = null;
      }
    } catch (error) {
      if (mounted) setState(() => _error = 'تعذر بدء الاتصال: $error');
    }
  }

  Future<void> _copyMyUid() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || uid.isEmpty) {
      if (mounted) setState(() => _error = 'سجّل الدخول أولاً.');
      return;
    }
    await Clipboard.setData(ClipboardData(text: uid));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم نسخ معرّف حسابك؛ أرسله لصديقك حتى يتصل بك.')),
      );
    }
  }

  Future<void> _finishCallSignal() async {
    final id = _activeCallId;
    _activeCallId = null;
    if (id == null) return;
    try {
      await FirebaseFirestore.instance.collection('callSessions').doc(id).update({
        'status': 'ended',
        'endedAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {}
  }

  Future<void> _joinRoom() async {
    final user = FirebaseAuth.instance.currentUser;
    final roomName = _roomController.text.trim();
    if (user == null) {
      setState(() => _error = 'سجّل الدخول أولاً.');
      return;
    }
    if (!RegExp(r'^[A-Za-z0-9_-]{3,64}$').hasMatch(roomName)) {
      setState(() => _error = 'رمز الغرفة يجب أن يكون 3 إلى 64 حرفاً إنكليزياً أو رقماً أو - أو _.');
      return;
    }
    if ((_endpoint ?? '').isEmpty) {
      await _configureEndpoint();
      if ((_endpoint ?? '').isEmpty) return;
    }
    setState(() {
      _connecting = true;
      _error = null;
    });
    try {
      final idToken = await user.getIdToken(true);
      final response = await http.post(
        Uri.parse(_endpoint!),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
        body: jsonEncode({
          'roomName': roomName,
          'participantName': user.displayName ?? 'عضو',
          'videoEnabled': _videoEnabled,
        }),
      ).timeout(const Duration(seconds: 25));
      final contentType = response.headers['content-type']?.toLowerCase() ?? '';
      final responseBody = response.body.trimLeft();
      if (!contentType.contains('application/json') || responseBody.startsWith('<')) {
        throw Exception('خادم المكالمات رجّع صفحة HTML بدل JSON. تأكد أن الرابط هو Cloudflare Worker الخاص بـ LiveKit وليس رابط meet.jit.si أو صفحة ويب.');
      }
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        throw Exception('استجابة خادم المكالمات غير مفهومة.');
      }
      final data = decoded;
      if (response.statusCode != 200) {
        throw Exception(data['error']?.toString() ?? 'تعذر إصدار رمز المكالمة.');
      }
      final serverUrl = data['serverUrl']?.toString() ?? _serverUrl;
      final token = data['participantToken']?.toString() ?? '';
      if (token.isEmpty || !serverUrl.startsWith('wss://')) {
        throw Exception('استجابة خادم المكالمات غير مكتملة.');
      }
      final room = lk.Room(roomOptions: const lk.RoomOptions(adaptiveStream: true, dynacast: true));
      final listener = room.createListener();
      listener.on<lk.RoomDisconnectedEvent>((_) {
        if (mounted && identical(_room, room)) {
          setState(() => _error = 'انقطع الاتصال بالغرفة.');
        }
      });
      await room.connect(serverUrl, token);
      await room.localParticipant?.setMicrophoneEnabled(true);
      if (_videoEnabled) {
        await room.localParticipant?.setCameraEnabled(true);
      }
      if (!mounted) {
        await listener.dispose();
        await room.dispose();
        return;
      }
      setState(() {
        _room = room;
        _listener = listener;
        _microphoneEnabled = true;
        _connecting = false;
      });
      room.addListener(_onRoomChanged);
      await lk.AudioManager.instance.setSpeakerOutputPreferred(true);
    } catch (error) {
      if (mounted) {
        setState(() {
          _connecting = false;
          _error = error.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  void _onRoomChanged() {
    if (mounted) setState(() {});
    _miniCallOverlay?.markNeedsBuild();
  }

  void _removeMiniCallOverlay() {
    _miniCallOverlay?.remove();
    _miniCallOverlay?.dispose();
    _miniCallOverlay = null;
  }

  void _continueInApp() {
    if (_room == null || _miniCallOverlay != null) return;
    _miniCallOverlay = OverlayEntry(
      builder: (overlayContext) => Positioned(
        top: MediaQuery.paddingOf(overlayContext).top + 8,
        left: 12,
        right: 12,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF24204F), Color(0xFF5142A8), Color(0xFF167F91)],
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withValues(alpha: .22)),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .28), blurRadius: 18, offset: const Offset(0, 7))],
            ),
            child: Row(children: [
              const Icon(Icons.call_rounded, color: Colors.white, size: 19),
              const SizedBox(width: 8),
              Expanded(
                child: InkWell(
                  onTap: _returnToCall,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('المكالمة مستمرة ❤️', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12)),
                      Text('الغرفة: ${_room?.name ?? ''} • اضغط للرجوع', maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white70, fontSize: 10)),
                    ],
                  ),
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                tooltip: _microphoneEnabled ? 'كتم المايك' : 'تشغيل المايك',
                onPressed: _toggleMicrophone,
                icon: Icon(_microphoneEnabled ? Icons.mic_rounded : Icons.mic_off_rounded, color: Colors.white),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                tooltip: 'إنهاء المكالمة',
                onPressed: _leaveRoom,
                icon: const Icon(Icons.call_end_rounded, color: Colors.white),
              ),
            ]),
          ),
        ),
      ),
    );
    Overlay.of(context, rootOverlay: true).insert(_miniCallOverlay!);
    widget.onContinue?.call();
  }

  void _returnToCall() {
    final callRoute = ModalRoute.of(context);
    _removeMiniCallOverlay();
    if (callRoute != null) {
      Navigator.of(context, rootNavigator: true).popUntil((route) => route == callRoute);
    }
  }

  Future<void> _toggleMicrophone() async {
    final room = _room;
    if (room == null) return;
    final next = !_microphoneEnabled;
    try {
      await room.localParticipant?.setMicrophoneEnabled(next);
      if (mounted) setState(() => _microphoneEnabled = next);
      _miniCallOverlay?.markNeedsBuild();
    } catch (error) {
      if (mounted) setState(() => _error = 'تعذر تغيير المايكروفون: $error');
    }
  }

  Future<void> _toggleCamera() async {
    final room = _room;
    if (room == null) return;
    final next = !_videoEnabled;
    try {
      await room.localParticipant?.setCameraEnabled(next);
      if (mounted) setState(() => _videoEnabled = next);
    } catch (error) {
      if (mounted) setState(() => _error = 'تعذر تشغيل الكاميرا: $error');
    }
  }

  Future<void> _leaveRoom() async {
    final room = _room;
    final listener = _listener;
    await _finishCallSignal();
    _removeMiniCallOverlay();
    setState(() {
      _room = null;
      _listener = null;
    });
    if (room != null) {
      room.removeListener(_onRoomChanged);
      await room.disconnect();
      await room.dispose();
    }
    await listener?.dispose();
    if (mounted) setState(() => _error = null);
  }

  ColorFilter _selectedVideoFilter() {
    switch (_videoFilter) {
      case 1:
        return const ColorFilter.matrix(<double>[
          .2126,.7152,.0722,0,0, .2126,.7152,.0722,0,0,
          .2126,.7152,.0722,0,0, 0,0,0,1,0,
        ]);
      case 2:
        return const ColorFilter.matrix(<double>[
          1.12,.04,0,0,8, .02,1.02,0,0,2, 0,.02,.88,0,-5, 0,0,0,1,0,
        ]);
      case 3:
        return const ColorFilter.matrix(<double>[
          .92,0,.08,0,8, 0,.94,.06,0,2, .08,0,1.12,0,10, 0,0,0,1,0,
        ]);
      case 4:
        return const ColorFilter.matrix(<double>[
          1.08,0,.04,0,5, .02,.92,.08,0,0, .08,.04,1.12,0,8, 0,0,0,1,0,
        ]);
      default:
        return const ColorFilter.mode(Colors.transparent, BlendMode.dst);
    }
  }

  Future<void> _copyRoomCode() async {
    final code = _room?.name ?? _roomController.text.trim();
    if (code.isEmpty) return;
    await SystemChannels.platform.invokeMethod<void>('Clipboard.setData', <String, String>{'text': code});
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم نسخ رمز الغرفة، أرسله لأصدقائك')),
    );
  }

  Future<void> _toggleSpeaker() async {
    final next = !_speakerEnabled;
    try {
      await lk.AudioManager.instance.setSpeakerOutputPreferred(next);
      if (mounted) setState(() => _speakerEnabled = next);
    } catch (error) {
      if (mounted) setState(() => _error = 'تعذر تغيير مخرج الصوت: $error');
    }
  }

  Widget _participantTile(lk.Participant participant, {required bool local}) {
    Widget? video;
    for (final publication in participant.videoTrackPublications) {
      final track = publication.track;
      if (publication.subscribed && track is lk.VideoTrack && !publication.isScreenShare) {
        video = ColorFiltered(colorFilter: _selectedVideoFilter(), child: lk.VideoTrackRenderer(track));
        break;
      }
    }
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF202443),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF6554D9).withValues(alpha: .55)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (video != null) video else const Center(
            child: Icon(Icons.account_circle_rounded, size: 76, color: Colors.white54),
          ),
          Positioned(
            right: 10,
            bottom: 10,
            child: DecoratedBox(
              decoration: BoxDecoration(color: Colors.black.withValues(alpha: .62), borderRadius: BorderRadius.circular(9)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                child: Text(local ? 'أنت' : participant.identity, style: const TextStyle(color: Colors.white, fontSize: 12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _removeMiniCallOverlay();
    _room?.removeListener(_onRoomChanged);
    _room?.disconnect();
    _room?.dispose();
    _listener?.dispose();
    _incomingCalls?.cancel();
    _friendUidController.dispose();
    _roomController.dispose();
    _endpointController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final room = _room;
    final connected = room != null && room.connectionState == lk.ConnectionState.connected;
    final participants = <lk.Participant>[
      if (room?.localParticipant != null) room!.localParticipant!,
      ...?room?.remoteParticipants.values,
    ];
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('مكالمات الصوت والفيديو'),
          actions: [
            IconButton(
              tooltip: 'إعداد رابط الخادم',
              onPressed: _configureEndpoint,
              icon: const Icon(Icons.settings_outlined),
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: connected
              ? Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF171936),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(children: [
                        const Icon(Icons.groups_rounded, color: Colors.white70),
                        const SizedBox(width: 8),
                        Expanded(child: Text('الغرفة: ${room.name}  •  المشاركون: ${participants.length}',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                        IconButton(onPressed: _copyRoomCode, tooltip: 'نسخ رمز الغرفة',
                          icon: const Icon(Icons.copy_rounded, color: Colors.white)),
                      ]),
                    ),
                    const SizedBox(height: 12),
                    if (_videoFilter != 0 || participants.any((p) => p.videoTrackPublications.isNotEmpty))
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Wrap(alignment: WrapAlignment.center, spacing: 7, children: [
                          ChoiceChip(label: const Text('طبيعي'), selected: _videoFilter == 0, onSelected: (_) => setState(() => _videoFilter = 0)),
                          ChoiceChip(label: const Text('أبيض وأسود'), selected: _videoFilter == 1, onSelected: (_) => setState(() => _videoFilter = 1)),
                          ChoiceChip(label: const Text('دافئ'), selected: _videoFilter == 2, onSelected: (_) => setState(() => _videoFilter = 2)),
                          ChoiceChip(label: const Text('بارد'), selected: _videoFilter == 3, onSelected: (_) => setState(() => _videoFilter = 3)),
                          ChoiceChip(label: const Text('بنفسجي'), selected: _videoFilter == 4, onSelected: (_) => setState(() => _videoFilter = 4)),
                        ]),
                      ),
                    Expanded(
                      child: GridView.builder(
                        itemCount: participants.length,
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2, crossAxisSpacing: 10, mainAxisSpacing: 10,
                        ),
                        itemBuilder: (context, index) => _participantTile(
                          participants[index],
                          local: participants[index].identity == FirebaseAuth.instance.currentUser?.uid,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 12,
                      children: [
                        IconButton.filledTonal(
                          tooltip: _microphoneEnabled ? 'كتم المايكروفون' : 'تشغيل المايكروفون',
                          onPressed: _toggleMicrophone,
                          icon: Icon(_microphoneEnabled ? Icons.mic : Icons.mic_off),
                        ),
                        IconButton.filledTonal(
                          tooltip: _speakerEnabled ? 'تحويل الصوت للسماعة' : 'تشغيل مكبر الصوت',
                          onPressed: _toggleSpeaker,
                          icon: Icon(_speakerEnabled ? Icons.volume_up_rounded : Icons.hearing_rounded),
                        ),
                        IconButton.filledTonal(
                          tooltip: _videoEnabled ? 'إيقاف الكاميرا' : 'تشغيل الكاميرا',
                          onPressed: _toggleCamera,
                          icon: Icon(_videoEnabled ? Icons.videocam : Icons.videocam_off),
                        ),
                        IconButton.filled(
                          tooltip: 'إنهاء المكالمة',
                          style: IconButton.styleFrom(backgroundColor: Colors.red),
                          onPressed: _leaveRoom,
                          icon: const Icon(Icons.call_end),
                        ),
                      ],
                    ),
                    if (widget.onContinue != null) ...[
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: _continueInApp,
                        icon: const Icon(Icons.open_in_new_rounded),
                        label: const Text('تصغير المكالمة ومتابعة استخدام التطبيق'),
                      ),
                    ],
                  ],
                )
              : ListView(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFF171936), Color(0xFF6554D9), Color(0xFF35BCEB)]),
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.video_call_rounded, color: Colors.white, size: 42),
                          SizedBox(height: 12),
                          Text('اجتمعوا بالصوت والصورة', style: TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.bold)),
                          SizedBox(height: 6),
                          Text('أنشئ رمز غرفة وشاركه مع أصدقائك ليدخلوا نفس المكالمة.', style: TextStyle(color: Colors.white70)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    TextField(
                      controller: _roomController,
                      textDirection: TextDirection.ltr,
                      decoration: const InputDecoration(
                        labelText: 'رمز الغرفة',
                        hintText: 'future-youth-01',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.meeting_room_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('مكالمة فيديو'),
                      subtitle: const Text('أوقفها للمكالمة الصوتية فقط'),
                      value: _videoEnabled,
                      onChanged: (value) => setState(() => _videoEnabled = value),
                    ),
                    const SizedBox(height: 8),
                    FilledButton.icon(
                      onPressed: _connecting ? null : _joinRoom,
                      icon: _connecting
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.call),
                      label: Text(_connecting ? 'جارٍ الاتصال...' : 'دخول المكالمة'),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: _configureEndpoint,
                      icon: const Icon(Icons.settings_outlined),
                      label: const Text('إعداد رابط خادم المكالمات المجاني'),
                    ),

                    const SizedBox(height: 18),
                    const Divider(),
                    const Text('اتصال مباشر بصديق', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _friendUidController,
                      textDirection: TextDirection.ltr,
                      decoration: const InputDecoration(
                        labelText: 'معرّف حساب الصديق (UID)',
                        hintText: 'الصق UID الذي أرسله لك صديقك',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person_search_rounded),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: _copyMyUid,
                        icon: const Icon(Icons.copy_rounded, size: 18),
                        label: const Text('نسخ معرّف حسابي لمشاركته مع الأصدقاء'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    FilledButton.icon(
                      onPressed: _connecting ? null : _startDirectCall,
                      icon: const Icon(Icons.call_rounded),
                      label: Text(_videoEnabled ? 'اتصال فيديو مباشر' : 'اتصال صوتي مباشر'),
                    ),
                    const Text(
                      'الاتصال المباشر يرسل طلباً لحساب الصديق ويعرض نافذة قبول أو رفض عندما يكون فاتحاً شاشة المكالمات داخل التطبيق. استقبال الاتصال والتطبيق مغلق يحتاج إشعارات دفع مهيأة على Firebase.',
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Text(_error!, style: const TextStyle(color: Colors.redAccent)),
                    ],
                    const SizedBox(height: 18),
                    const Text(
                      'ملاحظة: كل شخص يريد الانضمام يستخدم رمز الغرفة نفسه. لا تشارك رابط خادم المكالمات السري؛ الرابط وحده ليس مفتاحاً سرياً.',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
