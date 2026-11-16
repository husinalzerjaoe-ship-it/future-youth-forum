import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Opens the Godot runtime bundled in this Android application.
/// The Android build workflow installs the matching Godot 4.7.2 library.
class GodotGameLauncherPage extends StatefulWidget {
  const GodotGameLauncherPage({super.key});

  @override
  State<GodotGameLauncherPage> createState() => _GodotGameLauncherPageState();
}

class _GodotGameLauncherPageState extends State<GodotGameLauncherPage> {
  static const _channel = MethodChannel('future_youth/godot');
  bool _opening = false;
  String? _error;

  Future<void> _openGame() async {
    if (_opening) return;
    setState(() { _opening = true; _error = null; });
    try {
      await _channel.invokeMethod<bool>('openGame');
    } on PlatformException catch (error) {
      if (mounted) setState(() => _error = error.message ?? 'تعذر تشغيل محرك الألعاب.');
    } on MissingPluginException {
      if (mounted) setState(() => _error = 'محرك Godot غير مضمّن في نسخة Android الحالية. ابنِ النسخة من فرع التحديث الشامل.');
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF6554D9);
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('مغامرات Godot 3D')),
        body: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: const LinearGradient(
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                  colors: [Color(0xFF171936), accent, Color(0xFF078D91)],
                ),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.view_in_ar_rounded, color: Colors.white, size: 42),
                  SizedBox(height: 14),
                  Text('عالم ثلاثي الأبعاد داخل الملتقى',
                    style: TextStyle(color: Colors.white, fontSize: 23, fontWeight: FontWeight.w900)),
                  SizedBox(height: 8),
                  Text('شغّل محرك Godot المضمّن في تطبيق Android، وتحكم باللاعب من أزرار اللمس.',
                    style: TextStyle(color: Colors.white70, height: 1.5)),
                ],
              ),
            ),
            const SizedBox(height: 18),
            _GameModeTile(icon: Icons.diamond_rounded, title: 'كنز الجزر', detail: 'استكشف الساحة واجمع 12 جوهرة مضيئة'),
            _GameModeTile(icon: Icons.directions_run_rounded, title: 'سباق الحواجز', detail: 'اقفز فوق الحواجز واجمع الشارات'),
            _GameModeTile(icon: Icons.track_changes_rounded, title: 'صياد الأهداف', detail: 'تحرك داخل الساحة واجمع الأهداف المضيئة'),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: _opening ? null : _openGame,
              icon: _opening
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.play_arrow_rounded),
              label: Text(_opening ? 'جاري فتح اللعبة...' : 'تشغيل ألعاب Godot 3D'),
              style: FilledButton.styleFrom(backgroundColor: accent, padding: const EdgeInsets.symmetric(vertical: 16)),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: Colors.redAccent)),
            ],
            const SizedBox(height: 10),
            const Text('ملاحظة: هذه التجارب الثلاث تعمل حالياً بشكل فردي. اللعب الجماعي ثلاثي الأبعاد يحتاج ربط ومزامنة خادم واختبار جهازين، ولا نعرضه كميزة جاهزة قبل نجاح ذلك.',
              style: TextStyle(color: Colors.grey, height: 1.5)),
          ],
        ),
      ),
    );
  }
}

class _GameModeTile extends StatelessWidget {
  final IconData icon;
  final String title, detail;
  const _GameModeTile({required this.icon, required this.title, required this.detail});

  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      leading: CircleAvatar(backgroundColor: const Color(0xFF6554D9).withValues(alpha: .14),
        child: Icon(icon, color: const Color(0xFF8B7BFF))),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
      subtitle: Text(detail),
    ),
  );
}
