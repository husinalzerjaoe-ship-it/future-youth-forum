import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:jitsi_meet_flutter_sdk/jitsi_meet_flutter_sdk.dart';

/// Optional Jitsi route for calls when the configured LiveKit service is unavailable.
/// The public meet.jit.si service is best-effort and is not an unlimited/private hosted service.
class JitsiBackupCallsPage extends StatefulWidget {
  const JitsiBackupCallsPage({super.key});

  @override
  State<JitsiBackupCallsPage> createState() => _JitsiBackupCallsPageState();
}

class _JitsiBackupCallsPageState extends State<JitsiBackupCallsPage> {
  final _roomController = TextEditingController();
  final _jitsi = JitsiMeet();
  bool _videoEnabled = false;
  bool _joining = false;

  @override
  void initState() {
    super.initState();
    _roomController.text = _makeRoomCode();
  }

  String _makeRoomCode() {
    const alphabet = 'abcdefghjkmnpqrstuvwxyz23456789';
    final random = Random.secure();
    return 'fyf-${List.generate(16, (_) => alphabet[random.nextInt(alphabet.length)]).join()}';
  }

  Future<void> _copyRoomCode() async {
    final code = _roomController.text.trim();
    if (code.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: code));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم نسخ رمز الغرفة، أرسله لصديقك')),
    );
  }

  Future<void> _joinRoom() async {
    final user = FirebaseAuth.instance.currentUser;
    final room = _roomController.text.trim();
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('سجّل الدخول إلى الملتقى أولاً')),
      );
      return;
    }
    if (!RegExp(r'^[A-Za-z0-9_-]{6,64}$').hasMatch(room)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('رمز الغرفة يجب أن يكون من 6 إلى 64 حرفاً أو رقماً')),
      );
      return;
    }

    setState(() => _joining = true);
    try {
      final options = JitsiMeetConferenceOptions(
        serverURL: 'https://meet.jit.si',
        room: room,
        userInfo: JitsiMeetUserInfo(
          displayName: (user.displayName?.trim().isNotEmpty ?? false)
              ? user.displayName!.trim()
              : 'عضو الملتقى',
        ),
        configOverrides: {
          'subject': 'ملتقى شباب المستقبل',
          'startWithAudioMuted': false,
          'startWithVideoMuted': !_videoEnabled,
          'prejoinPageEnabled': true,
          'disableDeepLinking': true,
        },
        featureFlags: {
          FeatureFlags.chatEnabled: true,
          FeatureFlags.audioOnlyButtonEnabled: true,
          FeatureFlags.videoMuteEnabled: true,
          FeatureFlags.audioMuteButtonEnabled: true,
          FeatureFlags.tileViewEnabled: true,
          FeatureFlags.pipEnabled: true,
          FeatureFlags.meetingPasswordEnabled: true,
          FeatureFlags.preJoinPageEnabled: true,
          FeatureFlags.toolboxAlwaysVisible: true,
        },
      );
      await _jitsi.join(options);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تعذر فتح مكالمة Jitsi: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _joining = false);
    }
  }

  @override
  void dispose() {
    _roomController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('الاتصال الاحتياطي • Jitsi')),
        body: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF171936), Color(0xFF6554D9), Color(0xFF168E9B)],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                ),
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.video_call_rounded, color: Colors.white, size: 42),
                  SizedBox(height: 12),
                  Text(
                    'اتصل بأصدقائك حتى لو تعذّر خادم الاتصال الأساسي',
                    style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'مكالمة صوت وصورة مع دردشة الاجتماع ومشاركة رمز الغرفة. يعمل هذا الخيار كمسار احتياطي مستقل.',
                    style: TextStyle(color: Colors.white70, height: 1.5),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            TextField(
              controller: _roomController,
              textDirection: TextDirection.ltr,
              decoration: InputDecoration(
                labelText: 'رمز الغرفة',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  tooltip: 'إنشاء رمز جديد',
                  onPressed: () => setState(() => _roomController.text = _makeRoomCode()),
                  icon: const Icon(Icons.refresh_rounded),
                ),
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _copyRoomCode,
              icon: const Icon(Icons.copy_rounded),
              label: const Text('نسخ رمز الغرفة ومشاركته'),
            ),
            const SizedBox(height: 10),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('تشغيل الفيديو'),
              subtitle: const Text('أوقفه للانضمام بالصوت فقط، ويمكن تشغيل الكاميرا من داخل الاجتماع'),
              value: _videoEnabled,
              onChanged: (value) => setState(() => _videoEnabled = value),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _joining ? null : _joinRoom,
              icon: _joining
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.call_rounded),
              label: Text(_joining ? 'جارٍ فتح الاتصال...' : 'دخول مكالمة Jitsi'),
            ),
            const SizedBox(height: 18),
            const Card(
              child: Padding(
                padding: EdgeInsets.all(14),
                child: Text(
                  'تنبيه مهم: هذا الخيار يستخدم الخادم العام meet.jit.si وليس خادماً خاصاً بالملتقى. حسب سياسة الخدمة، أول شخص يبدأ الغرفة يحتاج تسجيل الدخول بحساب Google أو GitHub أو Facebook إذا طُلب منه ذلك؛ بقية الأصدقاء يستطيعون الانضمام بعد بدء الغرفة دون حساب Jitsi. الاجتماعات العامة محدودة حالياً إلى 95 دقيقة. رمز الغرفة الطويل لا يعادل كلمة مرور أو غرفة خاصة؛ فعّل كلمة مرور الاجتماع من أدوات Jitsi ولا تستخدم الخادم العام للمحادثات الحساسة.',
                  style: TextStyle(height: 1.5, fontSize: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
