import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

/// Browser-based Jitsi fallback. Keeping Jitsi outside the native app avoids
/// bundling a second incompatible WebRTC engine alongside LiveKit.
class JitsiBackupCallsPage extends StatefulWidget {
  const JitsiBackupCallsPage({super.key});

  @override
  State<JitsiBackupCallsPage> createState() => _JitsiBackupCallsPageState();
}

class _JitsiBackupCallsPageState extends State<JitsiBackupCallsPage> {
  final _roomController = TextEditingController();
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

  String _roomFromInput(String input) {
    final parsed = Uri.tryParse(input);
    if (parsed != null && parsed.host.toLowerCase() == 'meet.jit.si') {
      final segments = parsed.pathSegments.where((part) => part.isNotEmpty).toList();
      if (segments.isNotEmpty) return segments.first;
    }
    return input.trim();
  }

  Future<void> _joinRoom() async {
    final user = FirebaseAuth.instance.currentUser;
    final room = _roomFromInput(_roomController.text.trim());
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
      final uri = Uri.parse(
        'https://meet.jit.si/$room#config.startWithVideoMuted=${!_videoEnabled}',
      );
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!opened && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذر فتح Jitsi. جرّب Chrome أو انسخ الرابط وافتحه يدوياً.')),
        );
      }
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
                    'مكالمة صوت وصورة احتياطية عبر Jitsi في المتصفح، مع دردشة الاجتماع وأدواته حسب دعم المتصفح.',
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
                labelText: 'رمز الغرفة أو رابط Jitsi',
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
              title: const Text('تشغيل الفيديو عند الدخول'),
              subtitle: const Text('تگدر تغيّر الكاميرا والمايك من داخل اجتماع Jitsi'),
              value: _videoEnabled,
              onChanged: (value) => setState(() => _videoEnabled = value),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _joining ? null : _joinRoom,
              icon: _joining
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.call_rounded),
              label: Text(_joining ? 'جارٍ فتح الاتصال...' : 'فتح غرفة Jitsi'),
            ),
            const SizedBox(height: 18),
            const Card(
              child: Padding(
                padding: EdgeInsets.all(14),
                child: Text(
                  'تنبيه: المكالمة تفتح في المتصفح أو تطبيق Jitsi إن كان مثبتاً، وليست مدمجة داخل واجهة الملتقى. الخادم meet.jit.si عام وبأفضل جهد، وقد يطلب من منشئ الغرفة تسجيل الدخول. رمز الغرفة ليس بديلاً عن كلمة مرور الاجتماع؛ لا تستخدم الخادم العام للمحادثات الحساسة.',
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
