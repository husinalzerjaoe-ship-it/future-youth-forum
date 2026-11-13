import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'community_pages.dart';
import 'advanced_features.dart';
import 'firebase_options.dart';

const brand = Color(0xFF6554D9);
const darkBrand = Color(0xFF171936);
final db = FirebaseFirestore.instance;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const FutureYouthApp());
}

class FutureYouthApp extends StatelessWidget {
  const FutureYouthApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'ملتقى شباب المستقبل',
    theme: ThemeData(useMaterial3: true, colorScheme: ColorScheme.fromSeed(seedColor: brand)),
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
        backgroundColor: darkBrand, foregroundColor: Colors.white,
        title: const Text('ملتقى شباب المستقبل'),
        actions: [
          IconButton(tooltip: 'البحث عن الأعضاء', icon: const Icon(Icons.search),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MemberSearchPage()))),
          IconButton(tooltip: 'المحفوظات', icon: const Icon(Icons.bookmarks_outlined),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SavedPostsPage()))),
          IconButton(tooltip: 'الرسائل الخاصة', icon: const Icon(Icons.mail_outline),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DirectMessagesPage()))),
          IconButton(tooltip: 'الإشعارات', icon: const Icon(Icons.notifications_none),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsPage()))),
          IconButton(tooltip: 'الأمان والحظر', icon: const Icon(Icons.shield_outlined),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MemberSafetyPage()))),
          if (FirebaseAuth.instance.currentUser?.email?.toLowerCase() == 'husinalzerjaoe@gmail.com')
            IconButton(tooltip: 'مراجعة البلاغات', icon: const Icon(Icons.admin_panel_settings),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FounderReportsPage()))),
          IconButton(onPressed: () => FirebaseAuth.instance.signOut(),
            icon: const Icon(Icons.logout), tooltip: 'تسجيل الخروج'),
        ],
      ),
      body: IndexedStack(index: selected, children: const [PostsPage(), PublicChatPage(), CommunityHubPage(), MyProfilePage()]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selected,
        onDestinationSelected: (index) => setState(() => selected = index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dynamic_feed_outlined), selectedIcon: Icon(Icons.dynamic_feed), label: 'المنشورات'),
          NavigationDestination(icon: Icon(Icons.forum_outlined), selectedIcon: Icon(Icons.forum), label: 'المحادثة العامة'),
          NavigationDestination(icon: Icon(Icons.grid_view_rounded), selectedIcon: Icon(Icons.grid_view), label: 'الأقسام'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'ملفي'),
        ],
      ),
    ));
  }
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
            Container(padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(gradient: const LinearGradient(colors: [darkBrand, brand, Color(0xFF35BCEB)]), borderRadius: BorderRadius.circular(20)),
              child: Text('أهلاً بك ${user.displayName ?? 'صديقنا'} 👋\nشارك أفكارك وتعرّف على أعضاء الملتقى.',
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold))),
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
  bool sending = false;
  String? sendError;

  @override
  void dispose() { messageController.dispose(); super.dispose(); }

  Future<void> sendMessage() async {
    final text = messageController.text.trim();
    if (text.isEmpty || sending) return;
    final user = FirebaseAuth.instance.currentUser!;
    setState(() { sending = true; sendError = null; });
    try {
      await FirebaseFirestore.instance.collection('messages').add({
        'text': text,
        'senderId': user.uid,
        'senderName': (await db.collection('publicProfiles').doc(user.uid).get()).data()?['name'] ?? user.displayName ?? 'عضو',
        'createdAt': FieldValue.serverTimestamp(),
      });
      messageController.clear();
    } catch (_) {
      setState(() => sendError = 'ما انرسلت الرسالة. تأكد من نشر قواعد المحادثة العامة في Firebase.');
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }

  @override
  Widget build(BuildContext context) => Column(children: [
    Container(
      width: double.infinity, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: const Color(0xFFF0EEFF),
      child: const Row(children: [
        Icon(Icons.public, color: brand),
        SizedBox(width: 9),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('المحادثة العامة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          Text('احچي ويا جميع أعضاء الملتقى', style: TextStyle(color: Colors.black54, fontSize: 12)),
        ])),
        Icon(Icons.circle, color: Colors.green, size: 9),
        SizedBox(width: 5),
        Text('مباشر', style: TextStyle(fontSize: 12, color: Colors.green)),
      ]),
    ),
    Expanded(child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('messages').orderBy('createdAt', descending: true).limit(100).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return const Center(child: Padding(
          padding: EdgeInsets.all(22),
          child: Text('المحادثة تحتاج تفعيل قواعد الرسائل في Firebase.'),
        ));
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final messages = snapshot.data!.docs;
        if (messages.isEmpty) return const Center(child: Text('ماكو رسائل بعد. اكتب أول رسالة 👋'));
        final myId = FirebaseAuth.instance.currentUser!.uid;
        return ListView.builder(
          reverse: true, padding: const EdgeInsets.all(12), itemCount: messages.length,
          itemBuilder: (context, index) {
            final data = messages[index].data();
            final mine = data['senderId'] == myId;
            return Align(
              alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
                margin: const EdgeInsets.symmetric(vertical: 5),
                padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
                decoration: BoxDecoration(
                  color: mine ? const Color(0xFFE8E3FF) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: mine ? const Color(0xFFD5CCFF) : const Color(0xFFEAEAEA)),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  if (!mine) Text(data['senderName'] as String? ?? 'عضو',
                    style: const TextStyle(color: brand, fontWeight: FontWeight.bold, fontSize: 12)),
                  Text(data['text'] as String? ?? '', style: const TextStyle(fontSize: 15)),
                ]),
              ),
            );
          },
        );
      },
    )),
    if (sendError != null) Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Text(sendError!, style: const TextStyle(color: Colors.red, fontSize: 12)),
    ),
    SafeArea(top: false, child: Padding(
      padding: const EdgeInsets.fromLTRB(10, 7, 10, 8),
      child: Row(children: [
        Expanded(child: TextField(
          controller: messageController, minLines: 1, maxLines: 4, maxLength: 1000,
          textInputAction: TextInputAction.send, onSubmitted: (_) => sendMessage(),
          decoration: InputDecoration(
            hintText: 'اكتب رسالة للجميع...',
            counterText: '',
            filled: true, fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
          ),
        )),
        const SizedBox(width: 8),
        CircleAvatar(backgroundColor: brand, child: IconButton(
          onPressed: sending ? null : sendMessage,
          icon: sending ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : const Icon(Icons.send_rounded, color: Colors.white),
        )),
      ]),
    )),
  ]);
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
          Center(child: UserAvatar(url: d['photoUrl'] as String?)),
          const SizedBox(height: 8),
          Center(child: Text(d['name'] as String? ?? 'عضو', style: const TextStyle(fontSize: 21, fontWeight: FontWeight.bold))),
          Center(child: Text(d['bio'] as String? ?? 'أضف نبذة عن نفسك')),
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

class UserAvatar extends StatelessWidget {
  final String? url;
  const UserAvatar({super.key, this.url});
  @override
  Widget build(BuildContext context) => CircleAvatar(radius: 42,
    backgroundImage: url != null && url!.startsWith('https://') ? NetworkImage(url!) : null,
    child: url == null || !url!.startsWith('https://') ? const Icon(Icons.person, size: 42) : null);
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
            final uid = FirebaseAuth.instance.currentUser!.uid;
            final ref = FirebaseStorage.instance.ref().child('profiles/$uid/avatar.jpg');
            await ref.putData(await picked.readAsBytes(), SettableMetadata(contentType: 'image/jpeg'));
            photo.text = await ref.getDownloadURL();
            if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم رفع الصورة')));
          } catch (_) {
            if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تعذر رفع الصورة. تأكد من نشر قواعد التخزين.')));
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
      return Column(children: s.data!.docs.map((d) => Card(child: ListTile(
        leading: const Icon(Icons.article_outlined), title: Text(d.data()['text'] as String? ?? 'منشور')))).toList());
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
