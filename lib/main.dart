import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'community_pages.dart';
import 'community_plus.dart';
import 'enhanced_public_chat.dart';
import 'direct_chat_page.dart';
import 'advanced_features.dart';
import 'media_upload_service.dart';
import 'creative_library.dart';
import 'extra_community_features.dart';
import 'local_audio_handler.dart';
import 'daily_world.dart';
import 'arcade_hub.dart';
import 'football_news.dart';
import 'community_expansion.dart';
import 'match_center.dart';
import 'achievement_hub.dart';
import 'anime_experience.dart';
import 'firebase_options.dart';

const brand = Color(0xFF6554D9);
const darkBrand = Color(0xFF171936);
final db = FirebaseFirestore.instance;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await Supabase.initialize(
    url: 'https://xwfzdiftlzrjsprnbwpf.supabase.co',
    anonKey: 'sb_publishable_kra9SFgnuh5CtvV2-2n4mQ_7q_iJzbY',
    // Forward the signed-in Firebase ID token so Supabase Storage RLS can
    // identify the same user. Configure Firebase as a Supabase Third-party Auth
    // provider and add role=authenticated to Firebase ID tokens.
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
    themeMode: ThemeMode.system,
    theme: ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: brand, brightness: Brightness.light),
      textTheme: GoogleFonts.notoSansArabicTextTheme(),
      pageTransitionsTheme: const PageTransitionsTheme(builders: {
        TargetPlatform.android: ZoomPageTransitionsBuilder(),
        TargetPlatform.iOS: ZoomPageTransitionsBuilder(),
        TargetPlatform.windows: ZoomPageTransitionsBuilder(),
        TargetPlatform.macOS: ZoomPageTransitionsBuilder(),
        TargetPlatform.linux: ZoomPageTransitionsBuilder(),
      }),
      appBarTheme: const AppBarTheme(centerTitle: false, elevation: 0, scrolledUnderElevation: 0),
    ),
    darkTheme: ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: brand, brightness: Brightness.dark),
      textTheme: GoogleFonts.notoSansArabicTextTheme(ThemeData.dark().textTheme),
      pageTransitionsTheme: const PageTransitionsTheme(builders: {
        TargetPlatform.android: ZoomPageTransitionsBuilder(),
        TargetPlatform.iOS: ZoomPageTransitionsBuilder(),
        TargetPlatform.windows: ZoomPageTransitionsBuilder(),
        TargetPlatform.macOS: ZoomPageTransitionsBuilder(),
        TargetPlatform.linux: ZoomPageTransitionsBuilder(),
      }),
      scaffoldBackgroundColor: const Color(0xFF111321),
    ),
    home: const AuthGate(),
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
      backgroundColor: const Color(0xFFF5F6FC),
      body: SafeArea(child: Center(child: SingleChildScrollView(
        padding: const EdgeInsets.all(22),
        child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 440),
          child: Card(color: Colors.white, child: Padding(padding: const EdgeInsets.all(22),
            child: Form(key: form, child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              const Icon(Icons.groups_rounded, size: 58, color: brand),
              const SizedBox(height: 12),
              const Text('ملتقى شباب المستقبل', textAlign: TextAlign.center,
                style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(registering ? 'أنشئ حسابك وابدأ المشاركة' : 'سجّل دخولك للمتابعة',
                textAlign: TextAlign.center, style: const TextStyle(color: Colors.black54)),
              const SizedBox(height: 24),
              if (registering) ...[
                TextFormField(controller: name, decoration: const InputDecoration(labelText: 'الاسم', border: OutlineInputBorder()),
                  validator: (v) => registering && (v == null || v.trim().isEmpty) ? 'اكتب اسمك' : null),
                const SizedBox(height: 14),
              ],
              TextFormField(controller: email, keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'البريد الإلكتروني', border: OutlineInputBorder()),
                validator: (v) => v == null || !v.contains('@') ? 'اكتب بريد صحيح' : null),
              const SizedBox(height: 14),
              TextFormField(controller: password, obscureText: true,
                decoration: const InputDecoration(labelText: 'كلمة المرور', border: OutlineInputBorder()),
                validator: (v) => v == null || v.length < 6 ? 'اكتب 6 أحرف على الأقل' : null),
              if (error != null) ...[const SizedBox(height: 12), Text(error!, style: const TextStyle(color: Colors.red), textAlign: TextAlign.center)],
              const SizedBox(height: 18),
              FilledButton(onPressed: busy ? null : submit,
                style: FilledButton.styleFrom(backgroundColor: brand, padding: const EdgeInsets.all(15)),
                child: busy ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(registering ? 'إنشاء حساب' : 'تسجيل الدخول')),
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
                child: const Text('نسيت كلمة المرور؟'),
              ),
              TextButton(onPressed: busy ? null : () => setState(() { registering = !registering; error = null; }),
                child: Text(registering ? 'عندك حساب؟ سجّل دخولك' : 'ما عندك حساب؟ أنشئ حساب')),
            ])),
          )),
        ),
      ))),
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
        backgroundColor: darkBrand, foregroundColor: Colors.white, toolbarHeight: 68,
        flexibleSpace: const DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.centerRight, end: Alignment.centerLeft, colors: [Color(0xFF171936), Color(0xFF40378F), Color(0xFF168E9B)]))),
        title: Row(children: [
          Container(width: 38, height: 38, decoration: BoxDecoration(color: Colors.white.withValues(alpha: .14), borderRadius: BorderRadius.circular(13), border: Border.all(color: Colors.white24)), child: const Icon(Icons.auto_awesome_rounded, color: Color(0xFF8FE8FF), size: 23)),
          const SizedBox(width: 9),
          const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            Text('ملتقى شباب المستقبل', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
            Text('مجتمعك • ترفيهك • أصدقاؤك', style: TextStyle(fontSize: 10, color: Colors.white70)),
          ])),
        ]),
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
                case 'dailyWorld':
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const DailyWorldPage()));
                  break;
                case 'arcade':
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const ArcadeHubPage()));
                  break;
                case 'achievements':
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const AchievementHubPage()));
                  break;
                case 'matchCenter':
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const MatchCenterPage()));
                  break;
                case 'anime':
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const AnimeExperiencePage()));
                  break;
                case 'communityExpansion':
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const CommunityExpansionPage()));
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
              const PopupMenuItem(value: 'communityPlus', child: ListTile(leading: Icon(Icons.forum_outlined), title: Text('مجتمع الأوتاكو والنقاشات'), contentPadding: EdgeInsets.zero)),
              const PopupMenuItem(value: 'saved', child: ListTile(leading: Icon(Icons.bookmarks_outlined), title: Text('المحفوظات'), contentPadding: EdgeInsets.zero)),
              const PopupMenuItem(value: 'inspiration', child: ListTile(leading: Icon(Icons.auto_awesome), title: Text('مكتبة العبارات والأدعية'), contentPadding: EdgeInsets.zero)),
              const PopupMenuItem(value: 'extras', child: ListTile(leading: Icon(Icons.hub_outlined), title: Text('الغرف الخاصة والملفات والموسيقى'), contentPadding: EdgeInsets.zero)),
              const PopupMenuItem(value: 'dailyWorld', child: ListTile(leading: Icon(Icons.auto_awesome), title: Text('عالمك اليومي: العمر والأبراج والاستخارة'), contentPadding: EdgeInsets.zero)),
              const PopupMenuItem(value: 'arcade', child: ListTile(leading: Icon(Icons.sports_esports), title: Text('مدينة الترفيه والألعاب والنقاط'), contentPadding: EdgeInsets.zero)),
              const PopupMenuItem(value: 'achievements', child: ListTile(leading: Icon(Icons.workspace_premium_outlined), title: Text('إنجازاتي والحضور اليومي'), contentPadding: EdgeInsets.zero)),
              const PopupMenuItem(value: 'matchCenter', child: ListTile(leading: Icon(Icons.scoreboard_outlined), title: Text('مركز المباريات والنتائج'), contentPadding: EdgeInsets.zero)),
              const PopupMenuItem(value: 'anime', child: ListTile(leading: Icon(Icons.movie_filter_outlined), title: Text('عالم الأنمي والخلفيات وقائمتي'), contentPadding: EdgeInsets.zero)),
              const PopupMenuItem(value: 'communityExpansion', child: ListTile(leading: Icon(Icons.stadium), title: Text('استاد الأصدقاء والفعاليات والمجتمعات'), contentPadding: EdgeInsets.zero)),
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
      body: IndexedStack(index: selected, children: const [FootballNewsPage(), PostsPage(), EnhancedPublicChatPage(), CommunityHubPage(), AnimeExperiencePage(), MyProfilePage()]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selected,
        onDestinationSelected: (index) => setState(() => selected = index),
        height: 70,
        indicatorColor: brand.withValues(alpha: .16),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.sports_soccer_outlined), selectedIcon: Icon(Icons.sports_soccer), label: 'الأخبار'),
          NavigationDestination(icon: Icon(Icons.dynamic_feed_outlined), selectedIcon: Icon(Icons.dynamic_feed), label: 'المنشورات'),
          NavigationDestination(icon: Icon(Icons.forum_outlined), selectedIcon: Icon(Icons.forum), label: 'المحادثة'),
          NavigationDestination(icon: Icon(Icons.grid_view_rounded), selectedIcon: Icon(Icons.grid_view), label: 'الأقسام'),
          NavigationDestination(icon: Icon(Icons.movie_filter_outlined), selectedIcon: Icon(Icons.movie_filter), label: 'الأنمي'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'ملفي'),
        ],
      ),
    ));
  }
}

String? _youtubeVideoId(String raw) {
  final uri = Uri.tryParse(raw.trim());
  if (uri == null || !['http', 'https'].contains(uri.scheme)) return null;
  final host = uri.host.toLowerCase().replaceFirst(RegExp(r'^www\.'), '');
  if (host == 'youtu.be') return uri.pathSegments.isNotEmpty ? _validYoutubeId(uri.pathSegments.first) : null;
  if (!['youtube.com', 'm.youtube.com', 'music.youtube.com', 'youtube-nocookie.com'].contains(host)) return null;
  if (uri.path == '/watch') return _validYoutubeId(uri.queryParameters['v'] ?? '');
  if (uri.pathSegments.length >= 2 && ['embed', 'shorts', 'live', 'v'].contains(uri.pathSegments.first)) return _validYoutubeId(uri.pathSegments[1]);
  return null;
}
String? _validYoutubeId(String value) => RegExp(r'^[A-Za-z0-9_-]{11}
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
      await db.collection('posts').add({
        'text': text.text.trim(), 'videoUrl': video.text.trim(), 'authorId': user.uid,
        'authorName': profile.data()?['name'] ?? user.displayName ?? 'عضو',
        'authorPhoto': profile.data()?['photoUrl'] ?? '',
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
    text.dispose();
    video.dispose();
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
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('آخر المنشورات', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              TextButton.icon(onPressed: () => addPost(context), icon: const Icon(Icons.add), label: const Text('اكتب منشوراً')),
            ]),
            if (posts.isEmpty) const Card(child: Padding(padding: EdgeInsets.all(18), child: Text('ماكو منشورات بعد. كن أول من ينشر!'))),
            ...posts.map((doc) {
              final d = doc.data();
              return Card(child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                ListTile(contentPadding: EdgeInsets.zero, leading: UserAvatar(url: d['authorPhoto'] as String?),
                  title: Text(d['authorName'] as String? ?? 'عضو', style: const TextStyle(fontWeight: FontWeight.bold)),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => MemberProfilePage(uid: d['authorId'] as String? ?? '', fallbackName: d['authorName'] as String? ?? 'عضو')))),
                if ((d['text'] as String? ?? '').isNotEmpty) Text(d['text'] as String, style: const TextStyle(fontSize: 16)),
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
      'diamond' || 'ماسية' => 'عضوية ماسية',
      'legendary' || 'أسطورية' => 'عضوية أسطورية',
      'premium' || 'مميزة' => 'عضوية مميزة',
      _ => 'عضوية مشتركة',
    };
    final color = tier.toLowerCase() == 'gold' || tier == 'ذهبية' ? const Color(0xFFFFB52E)
      : tier.toLowerCase() == 'silver' || tier == 'فضية' ? const Color(0xFF8FA9C8)
      : tier.toLowerCase() == 'diamond' || tier == 'ماسية' ? const Color(0xFF24A6C7) : brand;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(color: color.withValues(alpha: .13), border: Border.all(color: color, width: 1.5), borderRadius: BorderRadius.circular(16)),
      child: Column(children: [
        Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.workspace_premium, color: color), const SizedBox(width: 6), Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold))]),
        if (date != null) Text(active ? 'تنتهي: ${date.year}/${date.month}/${date.day}' : 'انتهت العضوية', style: const TextStyle(fontSize: 12)),
        if (active) Padding(padding: const EdgeInsets.only(top: 7), child: Text(switch (tier.toLowerCase()) {
          'gold' || 'ذهبية' => 'شارة ذهبية • لون ذهبي للاسم والرسائل',
          'silver' || 'فضية' => 'شارة فضية • لون فضي لفقاعات الرسائل',
          'diamond' || 'ماسية' => 'شارة ماسية • لون سماوي للاسم والرسائل',
          'legendary' || 'أسطورية' => 'شارة أسطورية • لون بنفسجي مميز',
          _ => 'شارة العضوية • تمييز الاسم والرسائل',
        }, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11))),
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
            FollowControl(uid: uid),
            MemberSafetyActions(uid: uid, name: d['name'] as String? ?? fallbackName),
            StarRateControl(uid: uid),
            Center(child: RatingSummary(uid: uid)),
            const Divider(height: 28),
            const Text('منشوراته', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            MemberPosts(uid: uid),
          ]);
        },
      ),
    ));
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

String? _youtubeVideoId(String raw) {
  final uri = Uri.tryParse(raw.trim());
  if (uri == null || !['http', 'https'].contains(uri.scheme)) return null;
  final host = uri.host.toLowerCase().replaceFirst(RegExp(r'^www\\.'), '');
  if (host == 'youtu.be') {
    return uri.pathSegments.isNotEmpty ? _validYoutubeId(uri.pathSegments.first) : null;
  }
  if (!['youtube.com', 'm.youtube.com', 'music.youtube.com', 'youtube-nocookie.com'].contains(host)) return null;
  if (uri.path == '/watch') return _validYoutubeId(uri.queryParameters['v'] ?? '');
  if (uri.pathSegments.length >= 2 &&
      ['embed', 'shorts', 'live', 'v'].contains(uri.pathSegments.first)) {
    return _validYoutubeId(uri.pathSegments[1]);
  }
  return null;
}

String? _validYoutubeId(String value) =>
    RegExp(r'^[A-Za-z0-9_-]{11}
class YouTubeVideoPlayer extends StatefulWidget {
  final String url;
  const YouTubeVideoPlayer({super.key, required this.url});
  @override State<YouTubeVideoPlayer> createState() => _YouTubeVideoPlayerState();
}

class _YouTubeVideoPlayerState extends State<YouTubeVideoPlayer> {
  WebViewController? _controller;
  bool _loading = true, _failed = false;
  String? get _id => _youtubeVideoId(widget.url);
  @override void initState() { super.initState(); _createPlayer(); }
  @override void didUpdateWidget(covariant YouTubeVideoPlayer oldWidget) { super.didUpdateWidget(oldWidget); if (oldWidget.url != widget.url) _createPlayer(); }
  void _createPlayer() {
    final id = _id;
    if (id == null) { _controller = null; _loading = false; _failed = true; return; }
    _loading = true; _failed = false;
    final controller = WebViewController()..setJavaScriptMode(JavaScriptMode.unrestricted)..setBackgroundColor(const Color(0xFF000000))..setNavigationDelegate(NavigationDelegate(
      onPageFinished: (_) { if (mounted) setState(() => _loading = false); },
      onWebResourceError: (error) { if (error.isForMainFrame == true && mounted) setState(() { _loading = false; _failed = true; }); },
    ));
    _controller = controller;
    controller.loadHtmlString('''<!doctype html><html><head><meta name="viewport" content="width=device-width,initial-scale=1,maximum-scale=1"><style>html,body{margin:0;padding:0;background:#000;width:100%;height:100%;overflow:hidden}iframe{position:absolute;inset:0;width:100%;height:100%;border:0}</style></head><body><iframe src="https://www.youtube.com/embed/$id?playsinline=1&rel=0&modestbranding=1" title="YouTube video player" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share" referrerpolicy="strict-origin-when-cross-origin" allowfullscreen></iframe></body></html>''', baseUrl: 'https://www.youtube.com');
  }
  Future<void> _openExternal() async { final uri = Uri.tryParse(widget.url); if (uri != null && ['https','http'].contains(uri.scheme)) await launchUrl(uri, mode: LaunchMode.externalApplication); }
  @override Widget build(BuildContext context) => ClipRRect(borderRadius: BorderRadius.circular(12), child: AspectRatio(aspectRatio: 16 / 9, child: Stack(fit: StackFit.expand, children: [
    if (_controller != null && !_failed) WebViewWidget(controller: _controller!) else ColoredBox(color: Colors.black87, child: Center(child: TextButton.icon(onPressed: _openExternal, icon: const Icon(Icons.open_in_new, color: Colors.white), label: const Text('افتح الفيديو في يوتيوب', style: TextStyle(color: Colors.white))))),
    if (_loading && !_failed) const ColoredBox(color: Colors.black45, child: Center(child: CircularProgressIndicator(color: Colors.white))),
    if (_failed && _id != null) ColoredBox(color: Colors.black87, child: Center(child: TextButton.icon(onPressed: _openExternal, icon: const Icon(Icons.play_circle_fill, color: Colors.white), label: const Text('تعذر التشغيل؟ افتحه في يوتيوب', style: TextStyle(color: Colors.white))))),
  ])));
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
      await db.collection('posts').add({
        'text': text.text.trim(), 'videoUrl': video.text.trim(), 'authorId': user.uid,
        'authorName': profile.data()?['name'] ?? user.displayName ?? 'عضو',
        'authorPhoto': profile.data()?['photoUrl'] ?? '',
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
    text.dispose();
    video.dispose();
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
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('آخر المنشورات', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              TextButton.icon(onPressed: () => addPost(context), icon: const Icon(Icons.add), label: const Text('اكتب منشوراً')),
            ]),
            if (posts.isEmpty) const Card(child: Padding(padding: EdgeInsets.all(18), child: Text('ماكو منشورات بعد. كن أول من ينشر!'))),
            ...posts.map((doc) {
              final d = doc.data();
              return Card(child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                ListTile(contentPadding: EdgeInsets.zero, leading: UserAvatar(url: d['authorPhoto'] as String?),
                  title: Text(d['authorName'] as String? ?? 'عضو', style: const TextStyle(fontWeight: FontWeight.bold)),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => MemberProfilePage(uid: d['authorId'] as String? ?? '', fallbackName: d['authorName'] as String? ?? 'عضو')))),
                if ((d['text'] as String? ?? '').isNotEmpty) Text(d['text'] as String, style: const TextStyle(fontSize: 16)),
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
      'diamond' || 'ماسية' => 'عضوية ماسية',
      'legendary' || 'أسطورية' => 'عضوية أسطورية',
      'premium' || 'مميزة' => 'عضوية مميزة',
      _ => 'عضوية مشتركة',
    };
    final color = tier.toLowerCase() == 'gold' || tier == 'ذهبية' ? const Color(0xFFFFB52E)
      : tier.toLowerCase() == 'silver' || tier == 'فضية' ? const Color(0xFF8FA9C8)
      : tier.toLowerCase() == 'diamond' || tier == 'ماسية' ? const Color(0xFF24A6C7) : brand;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(color: color.withValues(alpha: .13), border: Border.all(color: color, width: 1.5), borderRadius: BorderRadius.circular(16)),
      child: Column(children: [
        Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.workspace_premium, color: color), const SizedBox(width: 6), Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold))]),
        if (date != null) Text(active ? 'تنتهي: ${date.year}/${date.month}/${date.day}' : 'انتهت العضوية', style: const TextStyle(fontSize: 12)),
        if (active) Padding(padding: const EdgeInsets.only(top: 7), child: Text(switch (tier.toLowerCase()) {
          'gold' || 'ذهبية' => 'شارة ذهبية • لون ذهبي للاسم والرسائل',
          'silver' || 'فضية' => 'شارة فضية • لون فضي لفقاعات الرسائل',
          'diamond' || 'ماسية' => 'شارة ماسية • لون سماوي للاسم والرسائل',
          'legendary' || 'أسطورية' => 'شارة أسطورية • لون بنفسجي مميز',
          _ => 'شارة العضوية • تمييز الاسم والرسائل',
        }, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11))),
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
            FollowControl(uid: uid),
            MemberSafetyActions(uid: uid, name: d['name'] as String? ?? fallbackName),
            StarRateControl(uid: uid),
            Center(child: RatingSummary(uid: uid)),
            const Divider(height: 28),
            const Text('منشوراته', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            MemberPosts(uid: uid),
          ]);
        },
      ),
    ));
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
).hasMatch(value) ? value : null;


class YouTubeVideoPlayer extends StatefulWidget {
  final String url;
  const YouTubeVideoPlayer({super.key, required this.url});
  @override State<YouTubeVideoPlayer> createState() => _YouTubeVideoPlayerState();
}

class _YouTubeVideoPlayerState extends State<YouTubeVideoPlayer> {
  WebViewController? _controller;
  bool _loading = true, _failed = false;
  String? get _id => _youtubeVideoId(widget.url);
  @override void initState() { super.initState(); _createPlayer(); }
  @override void didUpdateWidget(covariant YouTubeVideoPlayer oldWidget) { super.didUpdateWidget(oldWidget); if (oldWidget.url != widget.url) _createPlayer(); }
  void _createPlayer() {
    final id = _id;
    if (id == null) { _controller = null; _loading = false; _failed = true; return; }
    _loading = true; _failed = false;
    final controller = WebViewController()..setJavaScriptMode(JavaScriptMode.unrestricted)..setBackgroundColor(const Color(0xFF000000))..setNavigationDelegate(NavigationDelegate(
      onPageFinished: (_) { if (mounted) setState(() => _loading = false); },
      onWebResourceError: (error) { if (error.isForMainFrame == true && mounted) setState(() { _loading = false; _failed = true; }); },
    ));
    _controller = controller;
    controller.loadHtmlString('''<!doctype html><html><head><meta name="viewport" content="width=device-width,initial-scale=1,maximum-scale=1"><style>html,body{margin:0;padding:0;background:#000;width:100%;height:100%;overflow:hidden}iframe{position:absolute;inset:0;width:100%;height:100%;border:0}</style></head><body><iframe src="https://www.youtube-nocookie.com/embed/$id?playsinline=1&rel=0" title="YouTube video player" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share" referrerpolicy="strict-origin-when-cross-origin" allowfullscreen></iframe></body></html>''', baseUrl: 'https://www.youtube-nocookie.com');
  }
  Future<void> _openExternal() async { final uri = Uri.tryParse(widget.url); if (uri != null && ['https','http'].contains(uri.scheme)) await launchUrl(uri, mode: LaunchMode.externalApplication); }
  @override Widget build(BuildContext context) => ClipRRect(borderRadius: BorderRadius.circular(12), child: AspectRatio(aspectRatio: 16 / 9, child: Stack(fit: StackFit.expand, children: [
    if (_controller != null && !_failed) WebViewWidget(controller: _controller!) else ColoredBox(color: Colors.black87, child: Center(child: TextButton.icon(onPressed: _openExternal, icon: const Icon(Icons.open_in_new, color: Colors.white), label: const Text('افتح الفيديو في يوتيوب', style: TextStyle(color: Colors.white))))),
    if (_loading && !_failed) const ColoredBox(color: Colors.black45, child: Center(child: CircularProgressIndicator(color: Colors.white))),
    if (_failed && _id != null) ColoredBox(color: Colors.black87, child: Center(child: TextButton.icon(onPressed: _openExternal, icon: const Icon(Icons.play_circle_fill, color: Colors.white), label: const Text('تعذر التشغيل؟ افتحه في يوتيوب', style: TextStyle(color: Colors.white))))),
  ])));
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
      await db.collection('posts').add({
        'text': text.text.trim(), 'videoUrl': video.text.trim(), 'authorId': user.uid,
        'authorName': profile.data()?['name'] ?? user.displayName ?? 'عضو',
        'authorPhoto': profile.data()?['photoUrl'] ?? '',
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
    text.dispose();
    video.dispose();
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
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('آخر المنشورات', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              TextButton.icon(onPressed: () => addPost(context), icon: const Icon(Icons.add), label: const Text('اكتب منشوراً')),
            ]),
            if (posts.isEmpty) const Card(child: Padding(padding: EdgeInsets.all(18), child: Text('ماكو منشورات بعد. كن أول من ينشر!'))),
            ...posts.map((doc) {
              final d = doc.data();
              return Card(child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                ListTile(contentPadding: EdgeInsets.zero, leading: UserAvatar(url: d['authorPhoto'] as String?),
                  title: Text(d['authorName'] as String? ?? 'عضو', style: const TextStyle(fontWeight: FontWeight.bold)),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => MemberProfilePage(uid: d['authorId'] as String? ?? '', fallbackName: d['authorName'] as String? ?? 'عضو')))),
                if ((d['text'] as String? ?? '').isNotEmpty) Text(d['text'] as String, style: const TextStyle(fontSize: 16)),
                if ((d['videoUrl'] as String? ?? '').startsWith('https://'))
                  Padding(padding: const EdgeInsets.only(top: 8), child: SelectableText('🎬 رابط الفيديو: ${d['videoUrl']}')),
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
      'diamond' || 'ماسية' => 'عضوية ماسية',
      'legendary' || 'أسطورية' => 'عضوية أسطورية',
      'premium' || 'مميزة' => 'عضوية مميزة',
      _ => 'عضوية مشتركة',
    };
    final color = tier.toLowerCase() == 'gold' || tier == 'ذهبية' ? const Color(0xFFFFB52E)
      : tier.toLowerCase() == 'silver' || tier == 'فضية' ? const Color(0xFF8FA9C8)
      : tier.toLowerCase() == 'diamond' || tier == 'ماسية' ? const Color(0xFF24A6C7) : brand;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(color: color.withValues(alpha: .13), border: Border.all(color: color, width: 1.5), borderRadius: BorderRadius.circular(16)),
      child: Column(children: [
        Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.workspace_premium, color: color), const SizedBox(width: 6), Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold))]),
        if (date != null) Text(active ? 'تنتهي: ${date.year}/${date.month}/${date.day}' : 'انتهت العضوية', style: const TextStyle(fontSize: 12)),
        if (active) Padding(padding: const EdgeInsets.only(top: 7), child: Text(switch (tier.toLowerCase()) {
          'gold' || 'ذهبية' => 'شارة ذهبية • لون ذهبي للاسم والرسائل',
          'silver' || 'فضية' => 'شارة فضية • لون فضي لفقاعات الرسائل',
          'diamond' || 'ماسية' => 'شارة ماسية • لون سماوي للاسم والرسائل',
          'legendary' || 'أسطورية' => 'شارة أسطورية • لون بنفسجي مميز',
          _ => 'شارة العضوية • تمييز الاسم والرسائل',
        }, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11))),
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
            if (videoUrl.startsWith('https://'))
              ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(Icons.play_circle_fill, color: brand, size: 34),
                title: const Text('فيديو منشور'), subtitle: const Text('افتح رابط الفيديو'),
                onTap: () async { final uri = Uri.tryParse(videoUrl); if (uri != null) await launchUrl(uri, mode: LaunchMode.externalApplication); }),
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
            FollowControl(uid: uid),
            MemberSafetyActions(uid: uid, name: d['name'] as String? ?? fallbackName),
            StarRateControl(uid: uid),
            Center(child: RatingSummary(uid: uid)),
            const Divider(height: 28),
            const Text('منشوراته', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            MemberPosts(uid: uid),
          ]);
        },
      ),
    ));
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
