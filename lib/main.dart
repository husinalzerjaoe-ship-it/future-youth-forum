import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';

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
    theme: ThemeData(useMaterial3: true, colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6554D9))),
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
      setState(() => error = 'صار خطأ. تأكد من إعدادات قاعدة البيانات وحاول مرة ثانية.');
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
              const Icon(Icons.groups_rounded, size: 58, color: Color(0xFF6554D9)),
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
                style: FilledButton.styleFrom(backgroundColor: const Color(0xFF6554D9), padding: const EdgeInsets.all(15)),
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

class HomePage extends StatelessWidget {
  const HomePage({super.key});
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;
    return Directionality(textDirection: TextDirection.rtl, child: Scaffold(
      appBar: AppBar(backgroundColor: const Color(0xFF171936), foregroundColor: Colors.white,
        title: const Text('ملتقى شباب المستقبل'),
        actions: [IconButton(onPressed: () => FirebaseAuth.instance.signOut(), icon: const Icon(Icons.logout), tooltip: 'تسجيل الخروج')]),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('posts').orderBy('createdAt', descending: true).limit(50).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return const Center(child: Padding(padding: EdgeInsets.all(20),
            child: Text('قاعدة البيانات تحتاج تفعيل قواعد الأمان. أكمل الخطوة التالية حسب التعليمات.')));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final posts = snapshot.data!.docs;
          return ListView(padding: const EdgeInsets.all(16), children: [
            Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF171936), Color(0xFF6554D9), Color(0xFF35BCEB)]),
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
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF6554D9), foregroundColor: Colors.white,
        onPressed: () async {
          final controller = TextEditingController();
          final text = await showDialog<String>(context: context, builder: (context) => Directionality(
            textDirection: TextDirection.rtl, child: AlertDialog(title: const Text('منشور جديد'),
              content: TextField(controller: controller, maxLines: 4, maxLength: 1000,
                decoration: const InputDecoration(hintText: 'شنو تحب تشارك؟', border: OutlineInputBorder())),
              actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
                FilledButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: const Text('نشر'))])));
          if (text != null && text.isNotEmpty) {
            await FirebaseFirestore.instance.collection('posts').add({
              'text': text, 'authorId': user.uid, 'authorName': user.displayName ?? user.email ?? 'عضو',
              'createdAt': FieldValue.serverTimestamp(),
            });
          }
          controller.dispose();
        },
        child: const Icon(Icons.add),
      ),
    ));
  }
}
