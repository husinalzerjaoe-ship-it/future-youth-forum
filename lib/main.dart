import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:audio_service/audio_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'community_pages.dart';
import 'community_plus.dart';
import 'enhanced_public_chat.dart';
import 'advanced_features.dart';
import 'media_upload_service.dart';
import 'creative_library.dart';
import 'extra_community_features.dart';
import 'local_audio_handler.dart';
import 'youtube_video_player.dart';
import 'firebase_options.dart';
import 'football_news.dart';
import 'watch_party.dart';
import 'match_center.dart';
import 'game_center.dart';

const brand = Color(0xFF6554D9);
const darkBrand = Color(0xFF171936);
final db = FirebaseFirestore.instance;

Future<void> _notifyContentMentions({
  required String text,
  required String targetType,
  required String targetId,
  required String actorUid,
  required String actorName,
}) async {
  final tags = RegExp(r'@([^\s@]+)').allMatches(text)
      .map((m) => m.group(1)!.replaceAll('_', ' ')).toSet().take(10).toList();
  if (tags.isEmpty) return;
  final matches = await db.collection('publicProfiles').where('name', whereIn: tags).limit(10).get();
  for (final profile in matches.docs) {
    if (profile.id == actorUid) continue;
    await db.collection('notifications').add({
      'recipientId': profile.id, 'actorId': actorUid, 'actorName': actorName,
      'type': 'mention', 'text': 'أشار إليك في منشور',
      'read': false, 'targetType': targetType, 'targetId': targetId,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await Supabase.initialize(
    url: 'https://xwfzdiftlzrjsprnbwpf.supabase.co',
    anonKey: 'sb_publishable_kra9SFgnuh5CtvV2-2n4mQ_7q_iJzbY',
    // Forward the signed-in Firebase ID token so Supabase Storage RLS can
    // identify the same user. Configure Firebase as a Supabase Third-party Auth
    // provider; the current storage policies validate Firebase issuer, audience and UID.
    accessToken: () async => FirebaseAuth.instance.currentUser?.getIdToken(),
  );
  await initializeLocalAudioService();
  runApp(const FutureYouthApp());
}

class FutureYouthApp extends StatelessWidget {
  const FutureYouthApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'ملتقى شباب المستقبل',
    themeMode: ThemeMode.dark,
    theme: ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: brand, brightness: Brightness.light),
      textTheme: GoogleFonts.notoSansArabicTextTheme(),
      appBarTheme: const AppBarTheme(centerTitle: false, elevation: 0),
    ),
    darkTheme: ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: brand, brightness: Brightness.dark),
      textTheme: GoogleFonts.notoSansArabicTextTheme(ThemeData.dark().textTheme),
      scaffoldBackgroundColor: const Color(0xFF111321),
    ),
    home: const AnimatedIntroGate(),
  );
}


class AnimatedIntroGate extends StatefulWidget {
  const AnimatedIntroGate({super.key});
  @override
  State<AnimatedIntroGate> createState() => _AnimatedIntroGateState();
}

class _AnimatedIntroGateState extends State<AnimatedIntroGate> {
  bool _showIntro = true;

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(const Duration(milliseconds: 1700), () {
      if (mounted) setState(() => _showIntro = false);
    });
  }

  @override
  Widget build(BuildContext context) => AnimatedSwitcher(
    duration: const Duration(milliseconds: 650),
    switchInCurve: Curves.easeOutCubic,
    switchOutCurve: Curves.easeInCubic,
    transitionBuilder: (child, animation) => FadeTransition(
      opacity: animation,
      child: ScaleTransition(scale: Tween<double>(begin: .96, end: 1).animate(animation), child: child),
    ),
    child: _showIntro
      ? const _AnimatedIntroScreen(key: ValueKey('future-youth-intro'))
      : const AuthGate(key: ValueKey('future-youth-auth')),
  );
}

class _AnimatedIntroScreen extends StatelessWidget {
  const _AnimatedIntroScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [Color(0xFF10152F), Color(0xFF29215D), Color(0xFF111321)],
        ),
      ),
      child: Center(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: .72, end: 1),
          duration: const Duration(milliseconds: 1100),
          curve: Curves.elasticOut,
          builder: (context, scale, child) => Transform.scale(scale: scale, child: child),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 104, height: 104,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .09),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: const Color(0xFFB9AEFF).withValues(alpha: .65)),
                boxShadow: [BoxShadow(color: brand.withValues(alpha: .35), blurRadius: 35, spreadRadius: 2)],
              ),
              child: const Icon(Icons.auto_awesome_rounded, color: Color(0xFFE4DEFF), size: 54),
            ),
            const SizedBox(height: 22),
            const Text('ملتقى شباب المستقبل',
              style: TextStyle(color: Colors.white, fontSize: 23, fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            const Text('مساحة تجمع الأصدقاء والإبداع',
              style: TextStyle(color: Colors.white70, fontSize: 13)),
            const SizedBox(height: 26),
            const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(
              strokeWidth: 2, color: Color(0xFFB9AEFF))),
          ]),
        ),
      ),
    ),
  );
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});
  @override
  Widget build(BuildContext context) => StreamBuilder<User?>(
    stream: FirebaseAuth.instance.authStateChanges(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }
      return snapshot.hasData ? const HomePage() : const AuthPage();
    },
  );
}

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});
  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final form = GlobalKey<FormState>();
  final name = TextEditingController();
  final email = TextEditingController();
  final password = TextEditingController();
  bool registering = true;
  bool busy = false;
  String? error;

  @override
  void dispose() { name.dispose(); email.dispose(); password.dispose(); super.dispose(); }

  Future<void> submit() async {
    if (!form.currentState!.validate()) return;
    setState(() { busy = true; error = null; });
    try {
      if (registering) {
        final result = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email.text.trim(), password: password.text);
        await result.user!.updateDisplayName(name.text.trim());
        await FirebaseFirestore.instance.collection('users').doc(result.user!.uid).set({
          'name': name.text.trim(), 'email': email.text.trim(), 'createdAt': FieldValue.serverTimestamp(),
        });
        await db.collection('publicProfiles').doc(result.user!.uid).set({
          'name': name.text.trim(), 'bio': '', 'photoUrl': '',
          'createdAt': FieldValue.serverTimestamp(),
        });
      } else {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email.text.trim(), password: password.text);
      }
    } on FirebaseAuthException catch (e) {
      setState(() => error = switch (e.code) {
        'email-already-in-use' => 'هذا البريد مسجل مسبقاً. سجّل دخولك.',
        'invalid-email' => 'البريد الإلكتروني غير صحيح.',
        'weak-password' => 'كلمة المرور لازم تكون 6 أحرف على الأقل.',
        'user-not-found' || 'wrong-password' || 'invalid-credential' => 'البريد أو كلمة المرور غير صحيحة.',
        'network-request-failed' => 'تأكد من اتصال الإنترنت.',
        _ => 'تعذر إكمال العملية. حاول مرة ثانية.',
      });
    } catch (_) {
      setState(() => error = 'صار خطأ. تأكد من اتصال الإنترنت وإعدادات قاعدة البيانات.');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.rtl,
    child: Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight, end: Alignment.bottomLeft,
            colors: [Color(0xFF11152F), Color(0xFF29245B), Color(0xFF6554D9)],
          ),
        ),
        child: Stack(children: [
          const Positioned.fill(child: _AuthStarfield()),
          Positioned(top: -75, left: -55, child: _authGlow(210, const Color(0xFF8E7CFF).withOpacity(.20))),
          Positioned(bottom: -90, right: -60, child: _authGlow(250, const Color(0xFF38C9D8).withOpacity(.14))),
          SafeArea(child: Center(child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Column(children: [
                Container(
                  width: 92, height: 92,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    gradient: const LinearGradient(colors: [Color(0xFF8C7CF0), Color(0xFF4D43B6)]),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(.25), blurRadius: 28, offset: const Offset(0, 12))],
                    border: Border.all(color: Colors.white.withOpacity(.28), width: 1.5),
                  ),
                  child: const Icon(Icons.groups_rounded, color: Colors.white, size: 54),
                ),
                const SizedBox(height: 18),
                const Text('ملتقى شباب المستقبل', textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontSize: 27, fontWeight: FontWeight.w900, letterSpacing: .2)),
                const SizedBox(height: 7),
                Text('مساحتك • أصدقاؤك • اهتماماتك', textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white.withOpacity(.72), fontSize: 13)),
                const SizedBox(height: 28),
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: const Color(0xFF171A38).withOpacity(.88),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: Colors.white.withOpacity(.13)),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(.24), blurRadius: 32, offset: const Offset(0, 16))],
                  ),
                  child: Form(key: form, child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    Text(registering ? 'انضم إلى مجتمعنا' : 'أهلاً بعودتك',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 7),
                    Text(registering ? 'أنشئ حسابك وابدأ رحلتك' : 'سجّل دخولك وتابع أصدقاءك',
                      textAlign: TextAlign.center, style: TextStyle(color: Colors.white.withOpacity(.65))),
                    const SizedBox(height: 24),
                    if (registering) ...[
                      _authField(name, 'الاسم الظاهر', Icons.person_outline,
                        validator: (v) => registering && (v == null || v.trim().isEmpty) ? 'اكتب اسمك' : null),
                      const SizedBox(height: 14),
                    ],
                    _authField(email, 'البريد الإلكتروني', Icons.alternate_email,
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) => v == null || !v.contains('@') ? 'اكتب بريد صحيح' : null),
                    const SizedBox(height: 14),
                    _authField(password, 'كلمة المرور', Icons.lock_outline,
                      obscureText: true,
                      validator: (v) => v == null || v.length < 6 ? 'اكتب 6 أحرف على الأقل' : null),
                    if (error != null) ...[
                      const SizedBox(height: 12),
                      Container(padding: const EdgeInsets.all(11),
                        decoration: BoxDecoration(color: Colors.red.withOpacity(.12), borderRadius: BorderRadius.circular(12)),
                        child: Text(error!, style: const TextStyle(color: Color(0xFFFF9C9C)), textAlign: TextAlign.center)),
                    ],
                    const SizedBox(height: 20),
                    SizedBox(height: 54, child: FilledButton(
                      onPressed: busy ? null : submit,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF8878F2), foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: busy
                        ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Text(registering ? 'إنشاء حساب جديد' : 'تسجيل الدخول',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    )),
                    if (!registering) TextButton(
                      onPressed: busy ? null : () async {
                        final address = email.text.trim();
                        if (!address.contains('@')) {
                          setState(() => error = 'اكتب بريدك الإلكتروني أولاً حتى نرسل رابط الاستعادة.');
                          return;
                        }
                        try {
                          await FirebaseAuth.instance.sendPasswordResetEmail(email: address);
                          if (mounted) setState(() => error = 'أرسلنا رابط إعادة تعيين كلمة المرور إلى بريدك.');
                        } on FirebaseAuthException catch (e) {
                          if (mounted) setState(() => error = e.code == 'user-not-found' ? 'هذا البريد غير مسجل.' : 'تعذر إرسال رابط الاستعادة. حاول لاحقاً.');
                        }
                      },
                      child: const Text('نسيت كلمة المرور؟', style: TextStyle(color: Color(0xFFC9C2FF))),
                    ),
                    const SizedBox(height: 6),
                    OutlinedButton(
                      onPressed: busy ? null : () => setState(() { registering = !registering; error = null; }),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white, side: BorderSide(color: Colors.white.withOpacity(.28)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)), padding: const EdgeInsets.all(14),
                      ),
                      child: Text(registering ? 'عندي حساب — تسجيل الدخول' : 'مستخدم جديد — إنشاء حساب'),
                    ),
                  ])),
                ),
                const SizedBox(height: 18),
                Text('الإصدار V3 • مجتمع يجمعنا ونصنع المستقبل', style: TextStyle(color: Colors.white.withOpacity(.68), fontSize: 11, fontWeight: FontWeight.w600)),
              ]),
            ),
          ))),
        ]),
      ),
    ),
  );

  Widget _authGlow(double size, Color color) => Container(
    width: size, height: size,
    decoration: BoxDecoration(shape: BoxShape.circle, color: color,
      boxShadow: [BoxShadow(color: color, blurRadius: 55, spreadRadius: 18)]),
  );

  Widget _authField(TextEditingController controller, String label, IconData icon, {
    TextInputType? keyboardType, bool obscureText = false, String? Function(String?)? validator,
  }) => TextFormField(
    controller: controller, keyboardType: keyboardType, obscureText: obscureText, validator: validator,
    style: const TextStyle(color: Colors.white),
    decoration: InputDecoration(
      labelText: label, prefixIcon: Icon(icon, color: const Color(0xFFB7AEFF)),
      labelStyle: TextStyle(color: Colors.white.withOpacity(.66)),
      filled: true, fillColor: Colors.white.withOpacity(.07),
      contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 17),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: Colors.white.withOpacity(.12))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: Colors.white.withOpacity(.12))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Color(0xFF9B8FFF), width: 1.5)),
    ),
  );

}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int selected = 0;

  @override
  Widget build(BuildContext context) {
    return Directionality(textDirection: TextDirection.rtl, child: Scaffold(
      appBar: AppBar(
        backgroundColor: darkBrand, foregroundColor: Colors.white,
        title: const Text('ملتقى شباب المستقبل'),
        actions: [
          IconButton(tooltip: 'موسيقى الخلفية', icon: const Icon(Icons.music_note),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ExtraCommunityFeaturesPage()))),
          IconButton(tooltip: 'البحث عن الأعضاء', icon: const Icon(Icons.search),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MemberSearchPage()))),
          IconButton(tooltip: 'الرسائل الخاصة', icon: const Icon(Icons.mail_outline),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DirectMessagesPage()))),
          IconButton(tooltip: 'الإشعارات', icon: const Icon(Icons.notifications_none),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsPage()))),
          PopupMenuButton<String>(
            tooltip: 'المزيد من الخدمات',
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              switch (value) {
                case 'games':
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const GameCenterPage()));
                  break;
                case 'communityPlus':
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const CommunityPlusPage()));
                  break;
                case 'saved':
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const SavedPostsPage()));
                  break;
                case 'inspiration':
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const CreativeLibraryPage()));
                  break;
                case 'extras':
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const ExtraCommunityFeaturesPage()));
                  break;
                case 'safety':
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const MemberSafetyPage()));
                  break;
                case 'reports':
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const FounderReportsPage()));
                  break;
                case 'moderation':
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const ModerationLogPage()));
                  break;
                case 'logout':
                  FirebaseAuth.instance.signOut();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'games', child: ListTile(leading: Icon(Icons.sports_esports), title: Text('مركز الألعاب والتحديات'), contentPadding: EdgeInsets.zero)),
              const PopupMenuItem(value: 'communityPlus', child: ListTile(leading: Icon(Icons.forum_outlined), title: Text('مجتمع الأوتاكو والنقاشات'), contentPadding: EdgeInsets.zero)),
              const PopupMenuItem(value: 'saved', child: ListTile(leading: Icon(Icons.bookmarks_outlined), title: Text('المحفوظات'), contentPadding: EdgeInsets.zero)),
              const PopupMenuItem(value: 'inspiration', child: ListTile(leading: Icon(Icons.auto_awesome), title: Text('مكتبة العبارات والأدعية'), contentPadding: EdgeInsets.zero)),
              const PopupMenuItem(value: 'extras', child: ListTile(leading: Icon(Icons.hub_outlined), title: Text('الغرف الخاصة والملفات والموسيقى'), contentPadding: EdgeInsets.zero)),
              const PopupMenuItem(value: 'safety', child: ListTile(leading: Icon(Icons.shield_outlined), title: Text('الأمان والحظر'), contentPadding: EdgeInsets.zero)),
              if (FirebaseAuth.instance.currentUser?.email?.toLowerCase() == 'husinalzerjaoe@gmail.com')
                const PopupMenuItem(value: 'reports', child: ListTile(leading: Icon(Icons.admin_panel_settings), title: Text('لوحة البلاغات'), contentPadding: EdgeInsets.zero)),
              if (FirebaseAuth.instance.currentUser?.email?.toLowerCase() == 'husinalzerjaoe@gmail.com')
                const PopupMenuItem(value: 'moderation', child: ListTile(leading: Icon(Icons.history), title: Text('سجل المشرفين'), contentPadding: EdgeInsets.zero)),
              const PopupMenuDivider(),
              const PopupMenuItem(value: 'logout', child: ListTile(leading: Icon(Icons.logout), title: Text('تسجيل الخروج'), contentPadding: EdgeInsets.zero)),
            ],
          ),
        ],
      ),
      body: IndexedStack(index: selected, children: [const PostsPage(), const EnhancedPublicChatPage(), const CommunityHubPage(), MyProfilePage()]),
      bottomNavigationBar: Column(mainAxisSize: MainAxisSize.min, children: [
        const MiniNowPlayingBar(),
        NavigationBar(
        selectedIndex: selected,
        onDestinationSelected: (index) => setState(() => selected = index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dynamic_feed_outlined), selectedIcon: Icon(Icons.dynamic_feed), label: 'المنشورات'),
          NavigationDestination(icon: Icon(Icons.forum_outlined), selectedIcon: Icon(Icons.forum), label: 'المحادثة العامة'),
          NavigationDestination(icon: Icon(Icons.grid_view_rounded), selectedIcon: Icon(Icons.grid_view), label: 'الأقسام'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'ملفي'),
        ],
      ),
      ]),
    ));
  }
}

class MiniNowPlayingBar extends StatelessWidget {
  const MiniNowPlayingBar({super.key});

  String _clock(Duration value) {
    final minutes = value.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = value.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '${value.inHours > 0 ? '${value.inHours}:' : ''}$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) => StreamBuilder<MediaItem?>(
    stream: appAudioHandler.mediaItem,
    builder: (context, itemSnapshot) {
      final item = itemSnapshot.data;
      if (item == null) return const SizedBox.shrink();
      final duration = item.duration ?? Duration.zero;
      return StreamBuilder<PlaybackState>(
        stream: appAudioHandler.playbackState,
        builder: (context, stateSnapshot) {
          final playing = stateSnapshot.data?.playing ?? false;
          return Material(
            color: const Color(0xFF211B45),
            child: Container(
              padding: const EdgeInsetsDirectional.fromSTEB(12, 7, 8, 5),
              decoration: BoxDecoration(border: Border(top: BorderSide(color: const Color(0xFF9B8BFF).withOpacity(.35)))),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Row(children: [
                  Container(width: 38, height: 38, decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF806BEE), Color(0xFF3D8DBB)]), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.music_note_rounded, color: Colors.white)),
                  const SizedBox(width: 10),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                    Text(item.artist ?? item.album ?? 'ملتقى شباب المستقبل', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white70, fontSize: 11)),
                  ])),
                  IconButton(visualDensity: VisualDensity.compact, tooltip: 'السابق', onPressed: appAudioHandler.skipToPrevious, icon: const Icon(Icons.skip_previous_rounded, color: Colors.white)),
                  IconButton(visualDensity: VisualDensity.compact, tooltip: playing ? 'إيقاف مؤقت' : 'تشغيل', onPressed: playing ? appAudioHandler.pause : appAudioHandler.play, icon: Icon(playing ? Icons.pause_circle_filled_rounded : Icons.play_circle_fill_rounded, color: const Color(0xFFC5B9FF), size: 31)),
                  IconButton(visualDensity: VisualDensity.compact, tooltip: 'التالي', onPressed: appAudioHandler.skipToNext, icon: const Icon(Icons.skip_next_rounded, color: Colors.white)),
                ]),
                StreamBuilder<Duration>(
                  stream: AudioService.position,
                  builder: (context, positionSnapshot) {
                    final position = positionSnapshot.data ?? Duration.zero;
                    final maxMs = duration.inMilliseconds > 0 ? duration.inMilliseconds.toDouble() : 1.0;
                    return Row(children: [
                      Text(_clock(position), style: const TextStyle(color: Colors.white60, fontSize: 9)),
                      Expanded(child: SliderTheme(data: SliderTheme.of(context).copyWith(trackHeight: 2, thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5), overlayShape: SliderComponentShape.noOverlay), child: Slider(min: 0, max: maxMs, value: position.inMilliseconds.clamp(0, maxMs.toInt()).toDouble(), onChanged: duration == Duration.zero ? null : (v) => appAudioHandler.seek(Duration(milliseconds: v.round())), activeColor: const Color(0xFFB8A8FF), inactiveColor: Colors.white24))),
                      Text(_clock(duration), style: const TextStyle(color: Colors.white60, fontSize: 9)),
                    ]);
                  },
                ),
              ]),
            ),
          );
        },
      );
    },
  );
}

class PostsPage extends StatelessWidget {
  const PostsPage({super.key});

  Future<void> addPost(BuildContext context) async {
    final text = TextEditingController();
    final video = TextEditingController();
    final user = FirebaseAuth.instance.currentUser!;
    final ok = await showDialog<bool>(context: context, builder: (ctx) => Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(title: const Text('منشور جديد'),
        content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: text, maxLines: 4, maxLength: 1000,
            decoration: const InputDecoration(labelText: 'اكتب منشورك', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          TextField(controller: video, keyboardType: TextInputType.url,
            decoration: const InputDecoration(labelText: 'رابط فيديو (اختياري)', hintText: 'https://', border: OutlineInputBorder())),
        ])),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('نشر'))],
      )));
    if (ok == true && (text.text.trim().isNotEmpty || video.text.trim().isNotEmpty)) {
      final profile = await db.collection('publicProfiles').doc(user.uid).get();
      final authorName = (profile.data()?['name'] ?? user.displayName ?? 'عضو').toString();
      final post = await db.collection('posts').add({
        'text': text.text.trim(), 'videoUrl': video.text.trim(), 'authorId': user.uid,
        'authorName': authorName,
        'authorPhoto': profile.data()?['photoUrl'] ?? '',
        'createdAt': FieldValue.serverTimestamp(),
      });
      await _notifyContentMentions(
        text: text.text.trim(), targetType: 'post', targetId: post.id,
        actorUid: user.uid, actorName: authorName,
      );
    }
    text.dispose();
    video.dispose();
  }
  Future<void> addPhotoPost(BuildContext context) async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery, imageQuality: 88);
    if (file == null) return;
    final caption = TextEditingController();
    final publish = await showDialog<bool>(context: context, builder: (ctx) => Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        title: const Text('نشر صورة'),
        content: TextField(controller: caption, maxLines: 3, maxLength: 500,
          decoration: const InputDecoration(labelText: 'اكتب تعليقاً للصورة (اختياري)', border: OutlineInputBorder())),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('نشر الصورة')),
        ],
      ),
    ));
    if (publish != true) { caption.dispose(); return; }
    try {
      final user = FirebaseAuth.instance.currentUser!;
      final profile = await db.collection('publicProfiles').doc(user.uid).get();
      final imageUrl = await uploadForumMedia(file, folder: 'posts');
      await db.collection('posts').add({
        'text': caption.text.trim(),
        'imageUrl': imageUrl,
        'mediaType': 'image',
        'authorId': user.uid,
        'authorName': profile.data()?['name'] ?? user.displayName ?? 'عضو',
        'authorPhoto': profile.data()?['photoUrl'] ?? '',
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم نشر الصورة بنجاح')));
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تعذر نشر الصورة: $e')));
    } finally {
      caption.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: db.collection('posts').orderBy('createdAt', descending: true).limit(70).snapshots(),
      builder: (context, s) {
        if (s.hasError) return const Center(child: Text('تعذر تحميل المنشورات.'));
        if (!s.hasData) return const Center(child: CircularProgressIndicator());
        final posts = s.data!.docs;
        return Scaffold(
          body: ListView(padding: const EdgeInsets.all(14), children: [
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF17102F), Color(0xFF5123A8), Color(0xFF24134B)]),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF9C70FF), width: 1.2),
                boxShadow: const [BoxShadow(color: Color(0x445D2DB5), blurRadius: 16, offset: Offset(0, 5))],
              ),
              child: Theme(
                data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  initiallyExpanded: false,
                  iconColor: Colors.white,
                  collapsedIconColor: const Color(0xFFD6B7FF),
                  leading: const Icon(Icons.workspace_premium_rounded, color: Color(0xFFFFD66B), size: 30),
                  title: const Text('رسالة ترحيب من المطوّر ألفريدو 👑',
                    style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
                  subtitle: Text('أهلاً بك ${user.displayName ?? 'صديقنا'}… نورت الملتقى',
                    style: const TextStyle(color: Color(0xFFE2D7FF))),
                  childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
                  children: const [
                    Text('«أنا لا أبحث عن مكانٍ بين النجوم؛ أنا السماء التي تتعلّم النجوم كيف تلمع فيها.»',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Color(0xFFFFD66B), fontSize: 16, fontWeight: FontWeight.bold, height: 1.6)),
                    SizedBox(height: 12),
                    Text(
                      'أنا ألفريدو، مطوّر هذا الملتقى. لم أصنع هذا المكان لأكون اسماً عابراً بين الأسماء، بل لأترك في كل زاوية بصمة من فكري وطموحي. لا أحتاج إلى مقارنة نفسي بأحد؛ فلكل شخص طريقه، وأنا اخترت لنفسي طريقاً لا يشبه طرق الآخرين. حين أضع فكرة في رأسي أسعى لتحويلها إلى واقع، وحين أختار التميّز لا أنتظر إذناً من أحد.\\n\\n'
                      'وأنت عزيزي العضو، أهلاً بك في عالمنا. لا تجعل وجودك مجرد اسم في قائمة الأعضاء؛ شارك، اكتب، ساعد غيرك، واصنع لك حكاية جميلة. هنا نلتقي على حب الأنمي، ونتبادل الأفكار والضحكات والذكريات. احترم الآخرين، واجعل اختلافك مساحة للتعلّم لا سبباً للخصام.\\n\\n'
                      'قد أعتز بما صنعت، لكن قيمة الملتقى الحقيقية تكبر بوجودكم وتفاعلكم. أتمنى لكم وقتاً ممتعاً وتجربة تليق بكم.\\n— Alfredo | المطوّر 👑',
                      style: TextStyle(color: Colors.white, fontSize: 14, height: 1.8)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: ListTile(
                leading: const CircleAvatar(backgroundColor: Color(0xFFEDE9FF), child: Icon(Icons.sports_soccer_rounded, color: Color(0xFF6554D9))),
                title: const Text('أخبار كرة القدم', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('آخر الأخبار والانتقالات والعراق والدوريات والمنتخبات'),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FootballNewsPage())),
              ),
            ),
            Card(
              child: ListTile(
                leading: const CircleAvatar(backgroundColor: Color(0xFFEAF7EF), child: Icon(Icons.scoreboard_rounded, color: Color(0xFF16834A))),
                title: const Text('مركز المباريات والنتائج', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('مواعيد ونتائج بطولات كرة القدم'),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MatchCenterPage())),
              ),
            ),
            Card(
              child: ListTile(
                leading: const CircleAvatar(backgroundColor: Color(0xFFEDE9FF), child: Icon(Icons.live_tv_rounded, color: Color(0xFF6554D9))),
                title: const Text('غرف يوتيوب والمشاهدة الجماعية', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('يوتيوب وروابط فيديو وأفلام ومسلسلات متاحة للتضمين مع مزامنة ودردشة'),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WatchPartyLobbyPage())),
              ),
            ),
            Card(
              child: ListTile(
                leading: const CircleAvatar(backgroundColor: Color(0xFFFFF0E4), child: Icon(Icons.camera_alt_rounded, color: Color(0xFFB96A28))),
                title: const Text('ستوريات الملتقى', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('شاهد قصص الأعضاء أو انشر صورة وفيديو لمدة 24 ساعة'),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StoriesPage())),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 4,
              children: [
                const Text('آخر المنشورات', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                Wrap(spacing: 4, children: [
                  TextButton.icon(onPressed: () => addPost(context), icon: const Icon(Icons.edit_outlined), label: const Text('اكتب منشوراً')),
                  TextButton.icon(onPressed: () => addPhotoPost(context), icon: const Icon(Icons.add_photo_alternate_outlined), label: const Text('نشر صورة')),
                ]),
              ],
            ),
            if (posts.isEmpty) const Card(child: Padding(padding: EdgeInsets.all(18), child: Text('ماكو منشورات بعد. كن أول من ينشر!'))),
            ...posts.map((doc) {
              final d = doc.data();
              return Card(child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                ListTile(contentPadding: EdgeInsets.zero, leading: UserAvatar(url: d['authorPhoto'] as String?),
                  title: Text(d['authorName'] as String? ?? 'عضو', style: const TextStyle(fontWeight: FontWeight.bold)),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => MemberProfilePage(uid: d['authorId'] as String? ?? '', fallbackName: d['authorName'] as String? ?? 'عضو')))),
                if ((d['text'] as String? ?? '').isNotEmpty) Text(d['text'] as String, style: const TextStyle(fontSize: 16)),
                if ((d['imageUrl'] as String? ?? '').isNotEmpty)
                  Padding(padding: const EdgeInsets.only(top: 10), child: ClipRRect(borderRadius: BorderRadius.circular(14), child: Image.network(d['imageUrl'] as String, width: double.infinity, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Padding(padding: EdgeInsets.all(12), child: Text('تعذر تحميل الصورة'))))),
                if ((d['videoUrl'] as String? ?? '').trim().isNotEmpty)
                  Padding(padding: const EdgeInsets.only(top: 10), child: YouTubeVideoPlayer(url: d['videoUrl'] as String)),
                PostSocialActions(postId: doc.id, authorId: d['authorId'] as String? ?? ''),
              ])));
            }),
          ]),
          floatingActionButton: FloatingActionButton(backgroundColor: brand, foregroundColor: Colors.white,
            onPressed: () => addPost(context), child: const Icon(Icons.add)),
        );
      },
    );
  }
}

class PublicChatPage extends StatefulWidget {
  const PublicChatPage({super.key});
  @override
  State<PublicChatPage> createState() => _PublicChatPageState();
}

class _PublicChatPageState extends State<PublicChatPage> {
  final messageController = TextEditingController();
  final picker = ImagePicker();
  bool sending = false;
  String? sendError;
  int backgroundIndex = 0;
  static const chatBackgrounds = [Color(0xFFF5F3FF), Color(0xFFEAF6FF), Color(0xFFFFF3E8), Color(0xFFF0F7F1), Color(0xFF171936)];
  static const stickers = ['😂','❤️','🔥','😍','😭','👏','✨','🌹','🫶','🤣','🥹','💜','⚽','🐱','🎉','👍'];

  @override
  void dispose() { messageController.dispose(); super.dispose(); }

  Future<String> _senderName() async {
    final user = FirebaseAuth.instance.currentUser!;
    final profile = await db.collection('publicProfiles').doc(user.uid).get();
    return profile.data()?['name'] as String? ?? user.displayName ?? 'عضو';
  }

  Future<void> _send({String text = '', String? imageUrl, String type = 'text'}) async {
    if (sending || (text.trim().isEmpty && imageUrl == null)) return;
    final user = FirebaseAuth.instance.currentUser!;
    setState(() { sending = true; sendError = null; });
    try {
      await FirebaseFirestore.instance.collection('messages').add({
        'text': text.trim(), 'type': type, if (imageUrl != null) 'imageUrl': imageUrl,
        'senderId': user.uid,
        'senderRole': user.email?.toLowerCase() == 'husinalzerjaoe@gmail.com' ? 'founder' : 'member',
        'senderName': await _senderName(), 'createdAt': FieldValue.serverTimestamp(),
      });
      if (text.isNotEmpty) messageController.clear();
    } catch (_) {
      if (mounted) setState(() => sendError = 'ما انرسلت. تأكد من اتصالك وقواعد Firebase.');
    } finally { if (mounted) setState(() => sending = false); }
  }

  Future<void> sendMessage() => _send(text: messageController.text);

  Future<void> sendImage() async {
    try {
      final XFile? file = await picker.pickImage(source: ImageSource.gallery);
      if (file == null) return;
      final url = await uploadForumMedia(file, folder: 'public-chat');
      await _send(imageUrl: url, type: 'image');
    } on StorageException catch (e) { if (mounted) setState(() => sendError = 'فشل رفع الصورة (${e.statusCode ?? 'Storage'}): ${e.message}'); } catch (e) { if (mounted) setState(() => sendError = 'تعذر رفع الصورة: $e'); }
  }

  void showStickers() {
    showModalBottomSheet<void>(context: context, showDragHandle: true, backgroundColor: Colors.white,
      builder: (sheet) => Directionality(textDirection: TextDirection.rtl, child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Row(children: [Icon(Icons.emoji_emotions_outlined, color: brand), SizedBox(width: 8), Text('ملصقات سريعة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17))]),
          const SizedBox(height: 12),
          GridView.count(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), crossAxisCount: 4, childAspectRatio: 1.35,
            children: stickers.map((sticker) => InkWell(borderRadius: BorderRadius.circular(16),
              onTap: () { Navigator.pop(sheet); _send(text: sticker, type: 'sticker'); },
              child: Center(child: Text(sticker, style: const TextStyle(fontSize: 34))))).toList()),
        ]),
      )));
  }

  void showChatOptions() {
    showModalBottomSheet<void>(context: context, showDragHandle: true,
      builder: (sheet) => Directionality(textDirection: TextDirection.rtl, child: SafeArea(child: Padding(
        padding: const EdgeInsets.all(18), child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('تخصيص المحادثة', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 14), const Text('اختار خلفية الدردشة'), const SizedBox(height: 10),
          Wrap(spacing: 12, children: List.generate(chatBackgrounds.length, (i) => InkWell(
            onTap: () { setState(() => backgroundIndex = i); Navigator.pop(sheet); },
            child: Container(width: 42, height: 42, decoration: BoxDecoration(color: chatBackgrounds[i], shape: BoxShape.circle,
              border: Border.all(color: backgroundIndex == i ? brand : Colors.black12, width: backgroundIndex == i ? 3 : 1)),
              child: backgroundIndex == i ? const Icon(Icons.check, size: 18) : null)))),
          const SizedBox(height: 14), const Text('الخلفية محفوظة لهذه الجلسة فقط حالياً.', style: TextStyle(color: Colors.black54, fontSize: 12)),
        ]),
      ))));
  }

  Widget _founderName(String name) => ShaderMask(
    shaderCallback: (bounds) => const LinearGradient(colors: [Color(0xFFFFB52E), Color(0xFFFF6B6B), Color(0xFF9B59D0)]).createShader(bounds),
    child: Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12)));

  Widget _messageBubble(Map<String, dynamic> data, bool mine) {
    final founder = data['senderRole'] == 'founder';
    final type = data['type'] as String? ?? 'text';
    final imageUrl = data['imageUrl'] as String?;
    final text = data['text'] as String? ?? '';
    return Align(alignment: mine ? Alignment.centerRight : Alignment.centerLeft, child: Container(
      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * .80),
      margin: const EdgeInsets.symmetric(vertical: 5), padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        gradient: mine ? const LinearGradient(colors: [Color(0xFFEDE8FF), Color(0xFFDCD5FF)]) : null,
        color: mine ? null : Colors.white.withValues(alpha: .96),
        borderRadius: BorderRadius.only(topLeft: const Radius.circular(18), topRight: const Radius.circular(18),
          bottomLeft: Radius.circular(mine ? 18 : 5), bottomRight: Radius.circular(mine ? 5 : 18)),
        border: Border.all(color: founder ? const Color(0xFFFFD77A) : const Color(0x1A6554D9)),
        boxShadow: const [BoxShadow(color: Color(0x0D171936), blurRadius: 8, offset: Offset(0, 3))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (!mine && (data['senderId'] as String? ?? '').isNotEmpty)
          StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(stream: db.collection('publicProfiles').doc(data['senderId'] as String).snapshots(),
            builder: (context, profile) {
              final p = profile.data?.data() ?? {};
              final senderId = data['senderId'] as String;
              final name = p['name'] as String? ?? data['senderName'] as String? ?? 'عضو';
              final photo = p['photoUrl'] as String?;
              return InkWell(borderRadius: BorderRadius.circular(22),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => MemberProfilePage(uid: senderId, fallbackName: name))),
                child: Padding(padding: const EdgeInsets.only(bottom: 7), child: Row(mainAxisSize: MainAxisSize.min, children: [
                  CircleAvatar(radius: 15, backgroundImage: photo != null && photo.startsWith('https://') ? NetworkImage(photo) : null,
                    child: photo == null || !photo.startsWith('https://') ? const Icon(Icons.person, size: 16) : null),
                  const SizedBox(width: 7), Flexible(child: founder ? _founderName(name) : Text(name, style: const TextStyle(color: brand, fontWeight: FontWeight.bold, fontSize: 12))),
                  if (founder) ...[const SizedBox(width: 5), const Icon(Icons.workspace_premium, size: 16, color: Color(0xFFFFB52E)),
                    const Text('المؤسس', style: TextStyle(fontSize: 10, color: Color(0xFFB77900), fontWeight: FontWeight.bold))],
                ])));
            }),
        if (type == 'image' && imageUrl != null)
          ClipRRect(borderRadius: BorderRadius.circular(13), child: Image.network(imageUrl, width: 230, fit: BoxFit.cover,
            loadingBuilder: (c, child, progress) => progress == null ? child : const SizedBox(width: 230, height: 150, child: Center(child: CircularProgressIndicator())),
            errorBuilder: (c, e, st) => const Padding(padding: EdgeInsets.all(12), child: Text('تعذر عرض الصورة')))),
        if (type == 'sticker') Center(child: Padding(padding: const EdgeInsets.symmetric(vertical: 3), child: Text(text, style: const TextStyle(fontSize: 48)))),
        if (type != 'sticker' && text.isNotEmpty) Text(text, style: const TextStyle(fontSize: 15, color: Color(0xFF24233A))),
      ])));
  }

  @override
  Widget build(BuildContext context) => Directionality(textDirection: TextDirection.rtl, child: Column(children: [
    Container(width: double.infinity, padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
      decoration: const BoxDecoration(gradient: LinearGradient(colors: [darkBrand, Color(0xFF5144B8), Color(0xFF8C7CF0)])),
      child: Row(children: [
        Container(width: 42, height: 42, decoration: BoxDecoration(color: Colors.white.withValues(alpha: .16), borderRadius: BorderRadius.circular(14)),
          child: const Icon(Icons.forum_rounded, color: Colors.white, size: 24)),
        const SizedBox(width: 10),
        const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('الساحة العامة', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17)),
          Text('دردشة الأصدقاء • شارك صورة وملصق', style: TextStyle(color: Colors.white70, fontSize: 11))])),
        IconButton(onPressed: showChatOptions, tooltip: 'تخصيص الدردشة', icon: const Icon(Icons.palette_outlined, color: Colors.white)),
        const Icon(Icons.circle, color: Color(0xFF6CF0A5), size: 9), const SizedBox(width: 5),
        const Text('مباشر', style: TextStyle(fontSize: 11, color: Colors.white)),
      ])),
    Expanded(child: Container(color: chatBackgrounds[backgroundIndex], child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('messages').orderBy('createdAt', descending: true).limit(100).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return const Center(child: Padding(padding: EdgeInsets.all(22), child: Text('تعذر تحميل المحادثة. تأكد من قواعد Firebase.')));
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final messages = snapshot.data!.docs;
        if (messages.isEmpty) return const Center(child: Text('الساحة هادئة حالياً… كن أول من يبدأ الحديث ✨'));
        final myId = FirebaseAuth.instance.currentUser!.uid;
        return ListView.builder(reverse: true, padding: const EdgeInsets.fromLTRB(12, 14, 12, 14), itemCount: messages.length,
          itemBuilder: (context, index) { final data = messages[index].data(); return _messageBubble(data, data['senderId'] == myId); });
      }))),
    if (sendError != null) Padding(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4), child: Text(sendError!, style: const TextStyle(color: Colors.red, fontSize: 12))),
    Container(padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
      decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .06), blurRadius: 12, offset: const Offset(0, -3))]),
      child: SafeArea(top: false, child: Row(children: [
        IconButton(onPressed: sending ? null : sendImage, tooltip: 'إرسال صورة أو GIF', icon: const Icon(Icons.image_rounded, color: brand, size: 25)),
        IconButton(onPressed: sending ? null : showStickers, tooltip: 'ملصقات', icon: const Icon(Icons.emoji_emotions_rounded, color: Color(0xFFE6A52C), size: 25)),
        Expanded(child: TextField(controller: messageController, minLines: 1, maxLines: 4, maxLength: 1000,
          textInputAction: TextInputAction.send, onSubmitted: (_) => sendMessage(),
          decoration: InputDecoration(hintText: 'اكتب رسالتك…', counterText: '', filled: true, fillColor: const Color(0xFFF4F2FA),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none)))),
        const SizedBox(width: 7),
        CircleAvatar(radius: 23, backgroundColor: brand, child: IconButton(onPressed: sending ? null : sendMessage,
          icon: sending ? const SizedBox(width: 17, height: 17, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : const Icon(Icons.send_rounded, color: Colors.white, size: 20))),
      ]))),
  ]));
}

class MyProfilePage extends StatelessWidget {
  const MyProfilePage({super.key});
  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: db.collection('publicProfiles').doc(uid).snapshots(),
      builder: (context, s) {
        if (!s.hasData) return const Center(child: CircularProgressIndicator());
        final d = s.data!.data() ?? {};
        return ListView(padding: const EdgeInsets.all(18), children: [
          const Text('ملفي الشخصي', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 15),
          Center(child: Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: FirebaseAuth.instance.currentUser?.email?.toLowerCase() == 'husinalzerjaoe@gmail.com' ? const Color(0xFFFFB52E) : brand, width: 4),
            ),
            child: UserAvatar(url: d['photoUrl'] as String?),
          )),
          const SizedBox(height: 8),
          Center(child: Text(d['name'] as String? ?? 'عضو', style: TextStyle(fontSize: 23, fontWeight: FontWeight.w900, color: FirebaseAuth.instance.currentUser?.email?.toLowerCase() == 'husinalzerjaoe@gmail.com' ? const Color(0xFFB77900) : darkBrand))),
          if (FirebaseAuth.instance.currentUser?.email?.toLowerCase() == 'husinalzerjaoe@gmail.com')
            const Center(child: Padding(padding: EdgeInsets.only(top: 5), child: Chip(avatar: Icon(Icons.workspace_premium, color: Color(0xFFB77900)), label: Text('المؤسس والمالك'), backgroundColor: Color(0xFFFFF1C9)))),
          Center(child: Text(d['bio'] as String? ?? 'أضف نبذة عن نفسك')),
          StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: db.collection('memberships').doc(uid).snapshots(),
            builder: (context, membership) {
              final m = membership.data?.data() ?? {};
              final tier = (m['tier'] ?? d['membershipTier'] ?? '').toString();
              final expiry = m['expiresAt'] ?? d['membershipExpiresAt'];
              if (tier.isEmpty) return const SizedBox.shrink();
              return Center(child: Padding(padding: const EdgeInsets.only(top: 10),
                child: _MembershipCard(tier: tier, expiresAt: expiry)));
            },
          ),
          if (FirebaseAuth.instance.currentUser?.email?.toLowerCase() == 'husinalzerjaoe@gmail.com')
            const Center(child: Text('تطوير التطبيق: Alfredo', style: TextStyle(color: brand, fontWeight: FontWeight.bold))),
          const SizedBox(height: 10),
          Center(child: RatingSummary(uid: uid)),
          FilledButton.icon(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfilePage())),
            icon: const Icon(Icons.edit), label: const Text('تعديل الملف الشخصي')),
          const SizedBox(height: 12),
          const Text('منشوراتي', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          MemberPosts(uid: uid),
        ]);
      },
    );
  }
}

class _MembershipCard extends StatelessWidget {
  final String tier;
  final dynamic expiresAt;
  const _MembershipCard({required this.tier, this.expiresAt});
  @override
  Widget build(BuildContext context) {
    final date = expiresAt is Timestamp ? (expiresAt as Timestamp).toDate() : null;
    final active = date == null || date.isAfter(DateTime.now());
    final label = switch (tier.toLowerCase()) {
      'gold' || 'ذهبية' => 'عضوية ذهبية',
      'silver' || 'فضية' => 'عضوية فضية',
      'legendary' || 'أسطورية' => 'عضوية أسطورية',
      'premium' || 'مميزة' => 'عضوية مميزة',
      _ => 'عضوية مشتركة',
    };
    final color = tier.toLowerCase() == 'gold' || tier == 'ذهبية' ? const Color(0xFFFFB52E)
      : tier.toLowerCase() == 'silver' || tier == 'فضية' ? const Color(0xFF8FA9C8) : brand;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(color: color.withValues(alpha: .13), border: Border.all(color: color, width: 1.5), borderRadius: BorderRadius.circular(16)),
      child: Column(children: [
        Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.workspace_premium, color: color), const SizedBox(width: 6), Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold))]),
        if (date != null) Text(active ? 'تنتهي: ${date.year}/${date.month}/${date.day}' : 'انتهت العضوية', style: const TextStyle(fontSize: 12)),
      ]),
    );
  }
}

class UserAvatar extends StatelessWidget {
  final String? url;
  final double radius;
  const UserAvatar({super.key, this.url, this.radius = 42});
  @override
  Widget build(BuildContext context) {
    final valid = url != null && url!.startsWith('https://');
    return CircleAvatar(
      radius: radius,
      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      child: valid
          ? ClipOval(
              child: Image.network(
                url!,
                width: radius * 2,
                height: radius * 2,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, progress) => progress == null
                    ? child
                    : SizedBox(width: radius * 2, height: radius * 2,
                        child: const Center(child: CircularProgressIndicator(strokeWidth: 2))),
                errorBuilder: (context, error, stack) => Icon(Icons.person, size: radius, color: Theme.of(context).colorScheme.onPrimaryContainer),
              ),
            )
          : Icon(Icons.person, size: radius, color: Theme.of(context).colorScheme.onPrimaryContainer),
    );
  }
}

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});
  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}
class _EditProfilePageState extends State<EditProfilePage> {
  final name = TextEditingController(), bio = TextEditingController(), photo = TextEditingController();
  bool loading = true, saving = false, uploadingPhoto = false;
  @override
  void initState() {
    super.initState();
    db.collection('publicProfiles').doc(FirebaseAuth.instance.currentUser!.uid).get().then((s) {
      final d = s.data() ?? {};
      name.text = d['name'] as String? ?? '';
      bio.text = d['bio'] as String? ?? '';
      photo.text = d['photoUrl'] as String? ?? '';
      if (mounted) setState(() => loading = false);
    });
  }
  @override
  void dispose() { name.dispose(); bio.dispose(); photo.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => Directionality(textDirection: TextDirection.rtl, child: Scaffold(
    appBar: AppBar(title: const Text('تعديل الملف الشخصي')),
    body: loading ? const Center(child: CircularProgressIndicator()) : ListView(padding: const EdgeInsets.all(18), children: [
      TextField(controller: name, decoration: const InputDecoration(labelText: 'الاسم الظاهر', border: OutlineInputBorder())),
      const SizedBox(height: 12),
      TextField(controller: bio, maxLines: 4, maxLength: 300, decoration: const InputDecoration(labelText: 'السيرة الذاتية', border: OutlineInputBorder())),
      const SizedBox(height: 12),
      TextField(controller: photo, keyboardType: TextInputType.url, decoration: const InputDecoration(labelText: 'رابط الصورة (اختياري)', border: OutlineInputBorder())),
      const SizedBox(height: 10),
      OutlinedButton.icon(
        onPressed: uploadingPhoto ? null : () async {
          try {
            final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 82, maxWidth: 1200);
            if (picked == null) return;
            setState(() => uploadingPhoto = true);
            photo.text = await uploadForumMedia(picked, folder: 'profiles');
            if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم رفع الصورة')));
          } on StorageException catch (e) {
            if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('فشل رفع صورة الحساب (${e.statusCode ?? 'Storage'}): ${e.message}')));
          } catch (e) {
            if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تعذر رفع صورة الحساب: $e')));
          } finally { if (mounted) setState(() => uploadingPhoto = false); }
        },
        icon: uploadingPhoto ? const SizedBox(width:18,height:18,child:CircularProgressIndicator(strokeWidth:2)) : const Icon(Icons.photo_library_outlined),
        label: Text(uploadingPhoto ? 'جارٍ رفع الصورة...' : 'اختيار صورة من الاستوديو'),
      ),
      const SizedBox(height: 16),
      FilledButton(onPressed: saving ? null : () async {
        if (name.text.trim().isEmpty) return;
        setState(() => saving = true);
        try {
          final u = FirebaseAuth.instance.currentUser!;
          await db.collection('publicProfiles').doc(u.uid).set({'name': name.text.trim(), 'bio': bio.text.trim(), 'photoUrl': photo.text.trim()}, SetOptions(merge: true));
          await u.updateDisplayName(name.text.trim());
          if (context.mounted) Navigator.pop(context);
        } catch (_) {
          if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تعذر الحفظ. تحقق من قواعد Firestore.')));
        } finally { if (mounted) setState(() => saving = false); }
      }, child: saving ? const CircularProgressIndicator(color: Colors.white) : const Text('حفظ')),
    ]),
  ));
}

class RatingSummary extends StatelessWidget {
  final String uid;
  const RatingSummary({super.key, required this.uid});
  @override
  Widget build(BuildContext context) => StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
    stream: db.collection('publicProfiles').doc(uid).collection('ratings').snapshots(),
    builder: (context, s) {
      final docs = s.data?.docs ?? [];
      final total = docs.fold<int>(0, (v, d) => v + ((d.data()['stars'] as num?)?.toInt() ?? 0));
      final avg = docs.isEmpty ? 0.0 : total / docs.length;
      return Text('⭐ ${avg.toStringAsFixed(1)} من 5  •  ${docs.length} تقييم');
    });
}

class MemberPosts extends StatelessWidget {
  final String uid;
  const MemberPosts({super.key, required this.uid});
  @override
  Widget build(BuildContext context) => StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
    stream: db.collection('posts').where('authorId', isEqualTo: uid).limit(50).snapshots(),
    builder: (context, s) {
      if (!s.hasData) return const Center(child: CircularProgressIndicator());
      if (s.data!.docs.isEmpty) return const Text('ماكو منشورات بعد.');
      final posts = [...s.data!.docs]..sort((a,b) {
        final at = a.data()['createdAt'] as Timestamp?;
        final bt = b.data()['createdAt'] as Timestamp?;
        return (bt?.millisecondsSinceEpoch ?? 0).compareTo(at?.millisecondsSinceEpoch ?? 0);
      });
      return Column(children: posts.map((post) {
        final data = post.data();
        final videoUrl = data['videoUrl'] as String? ?? '';
        return Card(clipBehavior: Clip.antiAlias, margin: const EdgeInsets.symmetric(vertical: 7),
          child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if ((data['text'] as String? ?? '').isNotEmpty) Text(data['text'] as String, style: const TextStyle(fontSize: 16)),
            if (videoUrl.trim().isNotEmpty)
              Padding(padding: const EdgeInsets.only(top: 10), child: YouTubeVideoPlayer(url: videoUrl)),
            PostSocialActions(postId: post.id, authorId: data['authorId'] as String? ?? ''),
          ])));
      }).toList());
    });
}


class MemberProfilePage extends StatelessWidget {
  final String uid, fallbackName;
  const MemberProfilePage({super.key, required this.uid, required this.fallbackName});
  @override
  Widget build(BuildContext context) {
    if (uid.isEmpty) return const Scaffold(body: Center(child: Text('الملف غير متوفر')));
    return Directionality(textDirection: TextDirection.rtl, child: Scaffold(
      appBar: AppBar(title: const Text('صفحة العضو')),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: db.collection('publicProfiles').doc(uid).snapshots(),
        builder: (context, s) {
          if (!s.hasData) return const Center(child: CircularProgressIndicator());
          final d = s.data!.data() ?? {};
          return ListView(padding: const EdgeInsets.all(18), children: [
            Center(child: UserAvatar(url: d['photoUrl'] as String?)),
            const SizedBox(height: 8),
            Center(child: Text(d['name'] as String? ?? fallbackName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold))),
            Center(child: Text(d['bio'] as String? ?? '')),
            const SizedBox(height: 12),
            if (uid != FirebaseAuth.instance.currentUser!.uid)
              FilledButton.icon(
                onPressed: () async {
                  final me = FirebaseAuth.instance.currentUser!.uid;
                  final id = me.compareTo(uid) < 0 ? '${me}_${uid}' : '${uid}_${me}';
                  final ref = db.collection('conversations').doc(id);
                  final old = await ref.get();
                  if (!old.exists) {
                    final mine = await db.collection('publicProfiles').doc(me).get();
                    await ref.set({'members': [me, uid], 'memberNames': {
                      me: mine.data()?['name'] ?? FirebaseAuth.instance.currentUser?.displayName ?? 'عضو',
                      uid: d['name'] ?? fallbackName,
                    }, 'updatedAt': FieldValue.serverTimestamp()});
                  }
                  if (context.mounted) Navigator.push(context, MaterialPageRoute(builder: (_) => DirectChatPage(
                    conversationId: id, otherUid: uid, otherName: d['name'] as String? ?? fallbackName)));
                },
                icon: const Icon(Icons.message), label: const Text('مراسلة خاصة'),
              ),
            MemberPointsCard(uid: uid),
            FollowControl(uid: uid),
            MemberSafetyActions(uid: uid, name: d['name'] as String? ?? fallbackName),
            StarRateControl(uid: uid),
            Center(child: RatingSummary(uid: uid)),
            const Divider(height: 28),
            MemberActivityStats(uid: uid, joinedAt: d['createdAt']),
            const SizedBox(height: 12),
            const Text('منشوراته', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            MemberPosts(uid: uid),
          ]);
        },
      ),
    ));
  }
}


class MemberActivityStats extends StatelessWidget {
  final String uid;
  final dynamic joinedAt;
  const MemberActivityStats({super.key, required this.uid, this.joinedAt});

  @override
  Widget build(BuildContext context) {
    final joined = joinedAt is Timestamp ? (joinedAt as Timestamp).toDate() : null;
    final days = joined == null ? null : DateTime.now().difference(joined).inDays.clamp(0, 999999);
    final activity = Future.wait<int>([
      db.collection('posts').where('authorId', isEqualTo: uid).count().get()
          .then((value) => value.count ?? 0),
      db.collection('messages').where('senderId', isEqualTo: uid).count().get()
          .then((value) => value.count ?? 0),
    ]);
    return Card(
      elevation: 0,
      color: const Color(0xFF211D43),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: brand.withValues(alpha: .35)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('إحصائيات العضو', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 12),
          FutureBuilder<List<int>>(
            future: activity,
            builder: (context, snapshot) {
              final values = snapshot.data ?? const <int>[0, 0];
              return Row(children: [
                Expanded(child: _activityMetric(Icons.calendar_month, days?.toString() ?? '—', 'يوم منذ الانضمام')),
                Expanded(child: _activityMetric(Icons.article_outlined, snapshot.hasData ? values[0].toString() : '…', 'منشور')),
                Expanded(child: _activityMetric(Icons.forum_outlined, snapshot.hasData ? values[1].toString() : '…', 'رسالة عامة')),
              ]);
            },
          ),
          const SizedBox(height: 8),
          const Text('الإحصائيات تشمل المنشورات ورسائل المحادثة العامة فقط.', style: TextStyle(color: Colors.white60, fontSize: 11)),
        ]),
      ),
    );
  }

  Widget _activityMetric(IconData icon, String value, String label) => Column(children: [
    Icon(icon, color: const Color(0xFFB9AEFF), size: 21),
    const SizedBox(height: 5),
    Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18)),
    Text(label, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70, fontSize: 10)),
  ]);
}


class MemberPointsCard extends StatelessWidget {
  final String uid;
  const MemberPointsCard({super.key, required this.uid});

  static const String _founderEmail = 'husinalzerjaoe@gmail.com';

  @override
  Widget build(BuildContext context) {
    final current = FirebaseAuth.instance.currentUser;
    final isFounder = current?.email?.toLowerCase() == _founderEmail;
    final isOwn = current?.uid == uid;
    final balanceRef = db.collection('pointBalances').doc(uid);
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: balanceRef.snapshots(),
      builder: (context, snapshot) {
        final points = (snapshot.data?.data()?['balance'] as num?)?.toInt() ?? 0;
        return Card(
          elevation: 0,
          color: const Color(0xFF211D43),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(color: Colors.amber.withValues(alpha: .35)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(children: [
              const Icon(Icons.workspace_premium, color: Colors.amber, size: 30),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('نقاط العضو', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                Text(isFounder && isOwn ? 'رصيد المؤسس غير محدود' : '$points نقطة',
                  style: const TextStyle(color: Colors.white70)),
              ])),
              if (isFounder && !isOwn)
                FilledButton.tonalIcon(
                  onPressed: () => _grant(context, uid),
                  icon: const Icon(Icons.add),
                  label: const Text('منح نقاط'),
                ),
              if (isFounder && isOwn)
                const Chip(label: Text('مؤسس • غير محدود'), avatar: Icon(Icons.all_inclusive, size: 17)),
            ]),
          ),
        );
      },
    );
  }

  Future<void> _grant(BuildContext context, String targetUid) async {
    final controller = TextEditingController(text: '100');
    final amount = await showDialog<int>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('منح نقاط للعضو'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'عدد النقاط', hintText: 'مثلاً 100'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('إلغاء')),
          FilledButton(onPressed: () {
            final value = int.tryParse(controller.text.trim());
            if (value != null && value > 0 && value <= 1000000000) {
              Navigator.pop(dialogContext, value);
            }
          }, child: const Text('منح')),
        ],
      ),
    );
    controller.dispose();
    if (amount == null) return;
    final actor = FirebaseAuth.instance.currentUser;
    if (actor == null || actor.email?.toLowerCase() != _founderEmail) return;
    final balance = db.collection('pointBalances').doc(targetUid);
    final grant = db.collection('pointGrants').doc();
    final batch = db.batch();
    batch.set(balance, {
      'uid': targetUid,
      'balance': FieldValue.increment(amount),
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': actor.uid,
    }, SetOptions(merge: true));
    batch.set(grant, {
      'targetUid': targetUid,
      'amount': amount,
      'actorUid': actor.uid,
      'createdAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تم منح $amount نقطة للعضو')));
    }
  }
}

class StarRateControl extends StatelessWidget {
  final String uid;
  const StarRateControl({super.key, required this.uid});
  @override
  Widget build(BuildContext context) {
    final me = FirebaseAuth.instance.currentUser!.uid;
    if (uid == me) return const SizedBox.shrink();
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: db.collection('publicProfiles').doc(uid).collection('ratings').doc(me).snapshots(),
      builder: (context, s) {
        final current = (s.data?.data()?['stars'] as num?)?.toInt() ?? 0;
        return Column(children: [
          const Text('قيّم هذا العضو'),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(5, (i) => IconButton(
            onPressed: () => db.collection('publicProfiles').doc(uid).collection('ratings').doc(me).set({
              'stars': i + 1, 'from': me, 'createdAt': FieldValue.serverTimestamp(),
            }),
            icon: Icon(Icons.star, color: i < current ? Colors.amber : Colors.grey, size: 30),
          ))),
        ]);
      },
    );
  }
}

class PostSocialActions extends StatelessWidget {
  final String postId, authorId;
  const PostSocialActions({super.key, required this.postId, required this.authorId});
  @override
  Widget build(BuildContext context) {
    final me = FirebaseAuth.instance.currentUser!.uid;
    final likes = db.collection('posts').doc(postId).collection('likes');
    final comments = db.collection('posts').doc(postId).collection('comments');
    return Column(children: [
      const Divider(),
      Row(children: [
        StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: likes.doc(me).snapshots(),
          builder: (context, mine) => StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: likes.snapshots(),
            builder: (context, all) {
              final liked = mine.data?.exists ?? false;
              return TextButton.icon(
                onPressed: () async {
                  if (liked) { await likes.doc(me).delete(); }
                  else {
                    await likes.doc(me).set({'userId': me, 'createdAt': FieldValue.serverTimestamp()});
                    if (authorId.isNotEmpty && authorId != me) {
                      final profile = await db.collection('publicProfiles').doc(me).get();
                      await db.collection('notifications').add({
                        'recipientId': authorId, 'actorId': me,
                        'actorName': profile.data()?['name'] ?? 'عضو',
                        'type': 'like', 'text': 'أعجب بمنشورك',
                        'read': false, 'createdAt': FieldValue.serverTimestamp(),
                      });
                    }
                  }
                },
                icon: Icon(liked ? Icons.favorite : Icons.favorite_border, color: liked ? Colors.red : brand),
                label: Text('إعجاب ${all.data?.docs.length ?? 0}'),
              );
            }),
        ),
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: comments.snapshots(),
          builder: (context, snap) => TextButton.icon(
            onPressed: () => _openComments(context, comments),
            icon: const Icon(Icons.mode_comment_outlined),
            label: Text('تعليقات ${snap.data?.docs.length ?? 0}')),
        ),
        SavePostControl(postId: postId),
        const Spacer(),
        IconButton(icon: const Icon(Icons.flag_outlined), tooltip: 'إبلاغ',
          onPressed: () async {
            final reason = await showDialog<String>(context: context, builder: (c) => SimpleDialog(
              title: const Text('سبب الإبلاغ'),
              children: ['محتوى مسيء', 'تنمّر أو إزعاج', 'محتوى غير مناسب', 'سبب آخر']
                .map((v) => SimpleDialogOption(onPressed: () => Navigator.pop(c, v), child: Text(v))).toList()));
            if (reason == null) return;
            await db.collection('reports').add({'type':'post','targetId':postId,'reportedUserId':authorId,
              'reporterId':me,'reason':reason,'createdAt':FieldValue.serverTimestamp(),'status':'new'});
            if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('وصل بلاغك للإدارة، شكراً.')));
          }),
      ]),
    ]);
  }
  Future<void> _openComments(BuildContext context, CollectionReference<Map<String,dynamic>> comments) async {
    final controller = TextEditingController();
    await showModalBottomSheet<void>(context:context,isScrollControlled:true,builder:(sc)=>Directionality(
      textDirection:TextDirection.rtl,
      child: Padding(padding:EdgeInsets.only(bottom:MediaQuery.of(sc).viewInsets.bottom),
        child:SizedBox(height:MediaQuery.of(sc).size.height*.72,child:Column(children:[
          const Padding(padding:EdgeInsets.all(14),child:Text('التعليقات',style:TextStyle(fontSize:19,fontWeight:FontWeight.bold))),
          Expanded(child:StreamBuilder<QuerySnapshot<Map<String,dynamic>>>(stream:comments.orderBy('createdAt',descending:true).limit(100).snapshots(),builder:(c,s){
            if(!s.hasData)return const Center(child:CircularProgressIndicator());
            if(s.data!.docs.isEmpty)return const Center(child:Text('كن أول من يعلّق'));
            return ListView(children:s.data!.docs.map((doc){final d=doc.data();return ListTile(
              leading:const CircleAvatar(child:Icon(Icons.person)),title:Text(d['authorName'] as String? ?? 'عضو'),
              subtitle:Text(d['text'] as String? ?? ''));}).toList());
          })),
          SafeArea(child:Padding(padding:const EdgeInsets.all(10),child:Row(children:[
            Expanded(child:TextField(controller:controller,maxLength:500,decoration:const InputDecoration(hintText:'اكتب تعليقك...',counterText:'',border:OutlineInputBorder()))),
            IconButton.filled(onPressed:() async {
              final value=controller.text.trim();if(value.isEmpty)return;
              final user=FirebaseAuth.instance.currentUser!;
              final profile=await db.collection('publicProfiles').doc(user.uid).get();
              await comments.add({'text':value,'authorId':user.uid,'authorName':profile.data()?['name'] ?? user.displayName ?? 'عضو','createdAt':FieldValue.serverTimestamp()});
              if (authorId.isNotEmpty && authorId != user.uid) {
                await db.collection('notifications').add({
                  'recipientId': authorId, 'actorId': user.uid,
                  'actorName': profile.data()?['name'] ?? user.displayName ?? 'عضو',
                  'type': 'comment', 'text': 'علّق على منشورك',
                  'read': false, 'createdAt': FieldValue.serverTimestamp(),
                });
              }
              controller.clear();
            },icon:const Icon(Icons.send)),
          ]))),
        ]))),
    ));
    controller.dispose();
  }
}


class FollowControl extends StatelessWidget {
  final String uid;
  const FollowControl({super.key, required this.uid});
  @override
  Widget build(BuildContext context) {
    final me = FirebaseAuth.instance.currentUser!.uid;
    if (me == uid) return const SizedBox.shrink();
    final followerRef = db.collection('publicProfiles').doc(uid).collection('followers').doc(me);
    final followingRef = db.collection('publicProfiles').doc(me).collection('following').doc(uid);
    return StreamBuilder<DocumentSnapshot<Map<String,dynamic>>>(
      stream: followerRef.snapshots(),
      builder: (context, snap) {
        final following = snap.data?.exists ?? false;
        return Column(children: [
          FilledButton.icon(
            onPressed: () async {
              final batch = db.batch();
              if (following) {
                batch.delete(followerRef);
                batch.delete(followingRef);
              } else {
                batch.set(followerRef, {'userId':me,'createdAt':FieldValue.serverTimestamp()});
                batch.set(followingRef, {'userId':uid,'createdAt':FieldValue.serverTimestamp()});
                final myProfile = await db.collection('publicProfiles').doc(me).get();
                batch.set(db.collection('notifications').doc(), {
                  'recipientId': uid, 'actorId': me,
                  'actorName': myProfile.data()?['name'] ?? 'عضو',
                  'type': 'follow', 'text': 'بدأ بمتابعتك',
                  'read': false, 'createdAt': FieldValue.serverTimestamp(),
                });
              }
              await batch.commit();
            },
            icon: Icon(following ? Icons.person_remove_alt_1 : Icons.person_add_alt_1),
            label: Text(following ? 'إلغاء المتابعة' : 'متابعة'),
          ),
          StreamBuilder<QuerySnapshot<Map<String,dynamic>>>(
            stream: db.collection('publicProfiles').doc(uid).collection('followers').snapshots(),
            builder: (c, count) => Text('المتابعون: ${count.data?.docs.length ?? 0}'),
          ),
        ]);
      },
    );
  }
}


class MemberSearchPage extends StatefulWidget {
  const MemberSearchPage({super.key});
  @override
  State<MemberSearchPage> createState() => _MemberSearchPageState();
}

class _MemberSearchPageState extends State<MemberSearchPage> {
  final search = TextEditingController();
  @override
  void dispose() { search.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final me = FirebaseAuth.instance.currentUser!.uid;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('اكتشف الأعضاء')),
        body: Column(children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: TextField(
              controller: search,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'ابحث باسم العضو...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: search.text.isEmpty ? null : IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () { search.clear(); setState(() {}); },
                ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: db.collection('publicProfiles').orderBy('name').limit(200).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) return const Center(child: Text('تعذر تحميل الأعضاء. تحقق من قواعد Firestore.'));
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final query = search.text.trim().toLowerCase();
                final members = snapshot.data!.docs.where((doc) {
                  if (doc.id == me) return false;
                  final name = (doc.data()['name'] as String? ?? '').toLowerCase();
                  final bio = (doc.data()['bio'] as String? ?? '').toLowerCase();
                  return query.isEmpty || name.contains(query) || bio.contains(query);
                }).toList();
                if (members.isEmpty) return const Center(child: Text('ما لقينا أعضاء بهذا الاسم.'));
                return ListView.builder(
                  itemCount: members.length,
                  itemBuilder: (context, index) {
                    final doc = members[index];
                    final data = doc.data();
                    final name = data['name'] as String? ?? 'عضو';
                    return ListTile(
                      leading: UserAvatar(url: data['photoUrl'] as String?),
                      title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(data['bio'] as String? ?? '', maxLines: 1, overflow: TextOverflow.ellipsis),
                      trailing: const Icon(Icons.chevron_left),
                      onTap: () => Navigator.push(context, MaterialPageRoute(
                        builder: (_) => MemberProfilePage(uid: doc.id, fallbackName: name),
                      )),
                    );
                  },
                );
              },
            ),
          ),
        ]),
      ),
    );
  }
}


/// Lightweight animated anime-night atmosphere; uses no remote image or asset.
class _AuthStarfield extends StatefulWidget {
  const _AuthStarfield();

  @override
  State<_AuthStarfield> createState() => _AuthStarfieldState();
}

class _AuthStarfieldState extends State<_AuthStarfield>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 18),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => CustomPaint(
        painter: _AnimeNightPainter(_controller.value),
        child: const SizedBox.expand(),
      ),
    ),
  );
}

class _AnimeNightPainter extends CustomPainter {
  _AnimeNightPainter(this.phase);
  final double phase;

  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(29);
    for (var i = 0; i < 72; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final radius = .45 + random.nextDouble() * 1.25;
      final wave = (math.sin((phase * math.pi * 2) + i * .71) + 1) / 2;
      final alpha = (.12 + wave * .48).clamp(0.0, .62).toDouble();
      final paint = Paint()
        ..color = Color.lerp(
          const Color(0xFFB9C9FF),
          const Color(0xFFE4C8FF),
          (i % 4) / 3,
        )!.withOpacity(alpha);
      canvas.drawCircle(Offset(x, y), radius, paint);
    }

    final cometPhase = (phase * 1.35) % 1;
    final cometX = size.width * (1.15 - cometPhase * 1.45);
    final cometY = size.height * (.18 + .24 * cometPhase);
    final cometPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          const Color(0x00B8C8FF),
          const Color(0x88C6C8FF),
          const Color(0x00FFFFFF),
        ],
      ).createShader(Rect.fromLTWH(cometX - 70, cometY - 2, 70, 4));
    canvas.drawLine(
      Offset(cometX - 70, cometY - 2),
      Offset(cometX, cometY),
      cometPaint..strokeWidth = 2,
    );
    canvas.drawCircle(
      Offset(cometX, cometY),
      2,
      Paint()..color = const Color(0x99E5DCFF),
    );
  }

  @override
  bool shouldRepaint(covariant _AnimeNightPainter oldDelegate) =>
      oldDelegate.phase != phase;
}
