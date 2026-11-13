import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';

const brand = Color(0xFF6554D9);
const darkBrand = Color(0xFF171936);

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
        actions: [IconButton(onPressed: () => FirebaseAuth.instance.signOut(),
          icon: const Icon(Icons.logout), tooltip: 'تسجيل الخروج')],
      ),
      body: IndexedStack(index: selected, children: const [PostsPage(), PublicChatPage()]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selected,
        onDestinationSelected: (index) => setState(() => selected = index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dynamic_feed_outlined), selectedIcon: Icon(Icons.dynamic_feed), label: 'المنشورات'),
          NavigationDestination(icon: Icon(Icons.forum_outlined), selectedIcon: Icon(Icons.forum), label: 'المحادثة العامة'),
        ],
      ),
    ));
  }
}

class PostsPage extends StatelessWidget {
  const PostsPage({super.key});
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('posts').orderBy('createdAt', descending: true).limit(50).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return const Center(child: Padding(padding: EdgeInsets.all(20),
          child: Text('تعذر تحميل المنشورات. تحقق من اتصال الإنترنت وقواعد قاعدة البيانات.')));
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final posts = snapshot.data!.docs;
        return ListView(padding: const EdgeInsets.all(16), children: [
          Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [darkBrand, brand, Color(0xFF35BCEB)]),
            borderRadius: BorderRadius.circular(20)),
            child: Text('أهلاً بك ${user.displayName ?? user.email ?? ''} 👋\nمساحة تجمع الشباب والأفكار والطموحات.',
              style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.bold))),
          const SizedBox(height: 20),
          const Text('آخر المنشورات', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          if (posts.isEmpty) const Card(child: Padding(padding: EdgeInsets.all(18), child: Text('ماكو منشورات بعد. كن أول من ينشر!'))),
          ...posts.map((doc) => Card(child: ListTile(
            leading: const CircleAvatar(child: Icon(Icons.person)),
            title: Text(doc.data()['authorName'] as String? ?? 'عضو'),
            subtitle: Text(doc.data()['text'] as String? ?? ''),
          ))),
        ]);
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
        'senderName': user.displayName ?? user.email ?? 'عضو',
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
