import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:livekit_client/livekit_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LiveKitCallsPage extends StatefulWidget {
  const LiveKitCallsPage({super.key});

  @override
  State<LiveKitCallsPage> createState() => _LiveKitCallsPageState();
}

class _LiveKitCallsPageState extends State<LiveKitCallsPage> {
  static const _endpointKey = 'livekit_token_endpoint';
  static const _serverUrl = 'wss://youth-forum-future-lu43byvc.livekit.cloud';
  final _roomController = TextEditingController();
  final _endpointController = TextEditingController();
  Room? _room;
  EventsListener<RoomEvent>? _listener;
  bool _connecting = false;
  bool _videoEnabled = false;
  bool _microphoneEnabled = true;
  String? _error;
  String? _endpoint;

  @override
  void initState() {
    super.initState();
    _loadEndpoint();
  }

  Future<void> _loadEndpoint() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_endpointKey) ?? '';
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
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) {
      setState(() => _error = 'أدخل رابط HTTPS صحيحاً لخادم المكالمات.');
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
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode != 200) {
        throw Exception(data['error']?.toString() ?? 'تعذر إصدار رمز المكالمة.');
      }
      final serverUrl = data['serverUrl']?.toString() ?? _serverUrl;
      final token = data['participantToken']?.toString() ?? '';
      if (token.isEmpty || !serverUrl.startsWith('wss://')) {
        throw Exception('استجابة خادم المكالمات غير مكتملة.');
      }
      final room = Room();
      final listener = room.createListener();
      listener.on<RoomDisconnectedEvent>((_) {
        if (mounted && identical(_room, room)) {
          setState(() => _error = 'انقطع الاتصال بالغرفة.');
        }
      });
      await room.connect(
        serverUrl,
        token,
        roomOptions: const RoomOptions(adaptiveStream: true, dynacast: true),
      );
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
      await AudioManager.instance.setSpeakerOutputPreferred(true);
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
  }

  Future<void> _toggleMicrophone() async {
    final room = _room;
    if (room == null) return;
    final next = !_microphoneEnabled;
    try {
      await room.localParticipant?.setMicrophoneEnabled(next);
      if (mounted) setState(() => _microphoneEnabled = next);
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

  Widget _participantTile(Participant participant, {required bool local}) {
    Widget? video;
    for (final publication in participant.videoTracks.values) {
      final track = publication.track;
      if (publication.subscribed && track is VideoTrack && !publication.isScreenShare) {
        video = VideoTrackRenderer(track);
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
    _room?.removeListener(_onRoomChanged);
    _room?.disconnect();
    _room?.dispose();
    _listener?.dispose();
    _roomController.dispose();
    _endpointController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final room = _room;
    final connected = room != null && room.connectionState == ConnectionState.connected;
    final participants = <Participant>[
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
                      child: Text('الغرفة: ${room.name}  •  المشاركون: ${participants.length}',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 12),
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
