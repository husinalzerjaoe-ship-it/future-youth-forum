import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import 'livekit_calls.dart';
import 'local_bot.dart';

const _v12Ink = Color(0xFF10162E);
const _v12Panel = Color(0xFF1A2342);
const _v12Violet = Color(0xFF927CFF);
const _v12Aqua = Color(0xFF42D9E8);

class V12CompanionCenterPage extends StatefulWidget {
  const V12CompanionCenterPage({super.key});

  @override
  State<V12CompanionCenterPage> createState() => _V12CompanionCenterPageState();
}

class _V12CompanionCenterPageState extends State<V12CompanionCenterPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  final _room = TextEditingController();
  final _translation = TextEditingController();
  final _tournamentTitle = TextEditingController();
  final _tournamentDescription = TextEditingController();
  String _targetLanguage = 'en';
  bool _creatingTournament = false;

  User? get _user => FirebaseAuth.instance.currentUser;
  String get _uid => _user?.uid ?? '';

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);
    _room.text = _newRoomCode();
  }

  @override
  void dispose() {
    _tabs.dispose();
    _room.dispose();
    _translation.dispose();
    _tournamentTitle.dispose();
    _tournamentDescription.dispose();
    super.dispose();
  }

  String _newRoomCode() {
    const chars = 'abcdefghjkmnpqrstuvwxyz23456789';
    final random = Random.secure();
    return 'fyf-${List.generate(10, (_) => chars[random.nextInt(chars.length)]).join()}';
  }

  void _message(String value) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value)));
  }

  Future<void> _joinVoiceRoom() async {
    final code = _room.text.trim();
    if (!RegExp(r'^[A-Za-z0-9_-]{3,64}$').hasMatch(code)) {
      _message('رمز الغرفة لازم يكون 3 إلى 64 حرفاً أو رقماً.');
      return;
    }
    await Navigator.push(context, MaterialPageRoute(
      builder: (_) => LiveKitCallsPage(initialRoom: code),
    ));
  }

  Future<void> _copyRoom() async {
    await Clipboard.setData(ClipboardData(text: _room.text.trim()));
    _message('نسخنا رمز الغرفة. أرسله لأصدقائك حتى يدخلون نفس الروم.');
  }

  Future<void> _createTournament() async {
    final title = _tournamentTitle.text.trim();
    final description = _tournamentDescription.text.trim();
    if (title.length < 3 || description.isEmpty || _uid.isEmpty) {
      _message('اكتب اسم المسابقة ووصفها أولاً.');
      return;
    }
    setState(() => _creatingTournament = true);
    try {
      await FirebaseFirestore.instance.collection('communityTournaments').add({
        'title': title,
        'description': description,
        'game': 'تحديات عامة',
        'createdBy': _uid,
        'createdByName': _user?.displayName ?? 'منظم',
        'status': 'open',
        'createdAt': FieldValue.serverTimestamp(),
        'startsAt': Timestamp.fromDate(DateTime.now().add(const Duration(days: 1))),
      });
      _tournamentTitle.clear();
      _tournamentDescription.clear();
      if (mounted) Navigator.pop(context);
      _message('تم إنشاء المسابقة وفتح التسجيل للأعضاء.');
    } on FirebaseException catch (e) {
      _message('تعذر إنشاء المسابقة: ${e.code}. قد تحتاج نشر قواعد Firestore المحدّثة.');
    } catch (_) {
      _message('تعذر إنشاء المسابقة حالياً.');
    } finally {
      if (mounted) setState(() => _creatingTournament = false);
    }
  }

  Future<void> _showCreateTournament() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => Directionality(
        textDirection: TextDirection.rtl,
        child: Padding(
          padding: EdgeInsets.fromLTRB(18, 10, 18, MediaQuery.viewInsetsOf(sheetContext).bottom + 20),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('إنشاء بطولة جديدة', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900)),
            const SizedBox(height: 12),
            TextField(controller: _tournamentTitle, maxLength: 80,
              decoration: const InputDecoration(labelText: 'اسم البطولة', border: OutlineInputBorder())),
            const SizedBox(height: 8),
            TextField(controller: _tournamentDescription, maxLength: 500, minLines: 2, maxLines: 4,
              decoration: const InputDecoration(labelText: 'القوانين والوصف', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            SizedBox(width: double.infinity, child: FilledButton.icon(
              onPressed: _creatingTournament ? null : _createTournament,
              icon: const Icon(Icons.emoji_events),
              label: Text(_creatingTournament ? 'جارٍ الإنشاء...' : 'إنشاء وفتح التسجيل'),
            )),
          ]),
        ),
      ),
    );
  }

  Future<void> _toggleTournamentEntry(
    DocumentSnapshot<Map<String, dynamic>> tournament,
    bool joined,
    int count,
  ) async {
    final data = tournament.data() ?? {};
    if (data['status'] != 'open') {
      _message('التسجيل مغلق لهذه البطولة.');
      return;
    }
    final ref = tournament.reference.collection('players').doc(_uid);
    try {
      if (joined) {
        await ref.delete();
        _message('تم إلغاء تسجيلك.');
      } else {
        final profile = await FirebaseFirestore.instance.collection('publicProfiles').doc(_uid).get();
        final name = (profile.data()?['name'] ?? _user?.displayName ?? 'عضو').toString();
        await ref.set({
          'uid': _uid,
          'name': name.length > 60 ? name.substring(0, 60) : name,
          'joinedAt': FieldValue.serverTimestamp(),
        });
        _message('تم تسجيلك بالبطولة. بالتوفيق! 🏆');
      }
    } on FirebaseException catch (e) {
      _message('تعذر تحديث التسجيل: ${e.code}.');
    }
  }

  Future<void> _closeTournament(DocumentSnapshot<Map<String, dynamic>> doc) async {
    try {
      await doc.reference.update({
        'status': 'closed',
        'updatedAt': FieldValue.serverTimestamp(),
      });
      _message('تم إغلاق التسجيل.');
    } catch (_) {
      _message('تعذر إغلاق التسجيل.');
    }
  }

  Future<void> _generateBracket(
    DocumentSnapshot<Map<String, dynamic>> tournament,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> playerDocs,
  ) async {
    if (playerDocs.length < 2 || playerDocs.length > 32) {
      _message('تكوين الجدول يحتاج من لاعبين إلى 32 مشاركاً.');
      return;
    }
    final matches = <Map<String, dynamic>>[];
    for (var i = 0; i < playerDocs.length; i += 2) {
      final first = playerDocs[i].data();
      if (i + 1 < playerDocs.length) {
        final second = playerDocs[i + 1].data();
        matches.add({
          'round': 1,
          'homeUid': first['uid'],
          'homeName': first['name'],
          'awayUid': second['uid'],
          'awayName': second['name'],
        });
      } else {
        matches.add({
          'round': 1,
          'byeUid': first['uid'],
          'byeName': first['name'],
        });
      }
    }
    try {
      await tournament.reference.update({
        'roundOne': matches,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      _message('تم إنشاء جدول المواجهات الأولية.');
    } on FirebaseException catch (e) {
      _message('تعذر إنشاء الجدول: ${e.code}. انشر قواعد Firestore المحدّثة.');
    }
  }

  Future<void> _translate() async {
    final text = _translation.text.trim();
    if (text.isEmpty) {
      _message('اكتب النص الذي تريد ترجمته أولاً.');
      return;
    }
    final uri = Uri.https('translate.google.com', '/m', {
      'sl': 'auto',
      'tl': _targetLanguage,
      'q': text,
    });
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened) _message('تعذر فتح خدمة الترجمة على جهازك.');
  }

  Future<void> _signOutThisDevice() async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (c) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('تسجيل الخروج من هذا الجهاز؟'),
          content: const Text('سيتم إنهاء جلستك الحالية فقط. هذا الإجراء لا يسجّل خروج الأجهزة الأخرى.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('إلغاء')),
            FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('تسجيل الخروج')),
          ],
        ),
      ),
    );
    if (yes != true) return;
    await FirebaseAuth.instance.signOut();
    if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.rtl,
    child: Scaffold(
      backgroundColor: _v12Ink,
      appBar: AppBar(
        title: const Text('مركز المستقبل الشامل'),
        backgroundColor: _v12Ink,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabs,
          isScrollable: true,
          indicatorColor: _v12Aqua,
          tabs: const [
            Tab(text: 'الصوت', icon: Icon(Icons.mic)),
            Tab(text: 'البطولات', icon: Icon(Icons.emoji_events)),
            Tab(text: 'الترجمة', icon: Icon(Icons.translate)),
            Tab(text: 'الأمان', icon: Icon(Icons.shield)),
          ],
        ),
      ),
      body: TabBarView(controller: _tabs, children: [
        _voiceTab(),
        _tournamentsTab(),
        _translationTab(),
        _securityTab(),
      ]),
    ),
  );

  Widget _voiceTab() => ListView(padding: const EdgeInsets.all(16), children: [
    _banner(Icons.graphic_eq, 'صالات صوتية للأصدقاء', 'استخدم غرفة LiveKit نفسها حتى يجتمع الأصدقاء بالصوت، مع أدوات المايك والكاميرا ومكبر الصوت داخل المكالمة.'),
    const SizedBox(height: 16),
    TextField(
      controller: _room,
      textDirection: TextDirection.ltr,
      decoration: InputDecoration(
        labelText: 'رمز الغرفة',
        filled: true,
        fillColor: _v12Panel,
        suffixIcon: IconButton(
          tooltip: 'إنشاء رمز جديد',
          onPressed: () => setState(() => _room.text = _newRoomCode()),
          icon: const Icon(Icons.refresh),
        ),
      ),
    ),
    const SizedBox(height: 10),
    OutlinedButton.icon(onPressed: _copyRoom, icon: const Icon(Icons.copy), label: const Text('نسخ رمز الغرفة')),
    const SizedBox(height: 8),
    FilledButton.icon(onPressed: _joinVoiceRoom, icon: const Icon(Icons.mic), label: const Text('دخول الصالة الصوتية')),
    const SizedBox(height: 14),
    const _InfoTile(icon: Icons.people_alt, title: 'شلون يدخلون أصدقاؤك؟', body: 'يروحون إلى مركز المستقبل، يكتبون نفس الرمز، ثم يضغطون دخول. لازم يكون رابط خادم LiveKit مضبوطاً ويعمل.'),
    const _InfoTile(icon: Icons.privacy_tip_outlined, title: 'الخصوصية', body: 'لا تشارك رمز الغرفة إلا مع الأشخاص الذين تريدهم. رمز الغرفة وحده ليس بديلاً عن إعدادات وصول آمنة على الخادم.'),
  ]);

  Widget _tournamentsTab() => Column(children: [
    Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      child: Row(children: [
        const Expanded(child: Text('بطولات المجتمع', style: TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w900))),
        FilledButton.tonalIcon(onPressed: _showCreateTournament, icon: const Icon(Icons.add), label: const Text('إنشاء')),
      ]),
    ),
    const Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Text('أنشئ بطولة، افتح التسجيل، وشاهد قائمة المشاركين مباشرة.', style: TextStyle(color: Colors.white60, fontSize: 12)),
    ),
    Expanded(child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('communityTournaments')
          .orderBy('createdAt', descending: true).limit(30).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return const Center(child: Text('تعذر تحميل البطولات. تحقق من نشر قواعد Firestore.'));
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data!.docs;
        if (docs.isEmpty) return const Center(child: Text('ماكو بطولات حالياً. أنشئ أول بطولة للملتقى!'));
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 18),
          itemCount: docs.length,
          itemBuilder: (context, index) => _tournamentCard(docs[index]),
        );
      },
    )),
  ]);

  Widget _tournamentCard(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final players = doc.reference.collection('players');
    final owner = data['createdBy'] == _uid;
    final open = data['status'] == 'open';
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: players.orderBy('joinedAt').snapshots(),
      builder: (context, snapshot) {
        final count = snapshot.data?.docs.length ?? 0;
        return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: players.doc(_uid).snapshots(),
          builder: (context, mine) {
            final joined = mine.data?.exists == true;
            return Card(
              color: _v12Panel,
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    const Icon(Icons.emoji_events, color: Colors.amber, size: 28),
                    const SizedBox(width: 8),
                    Expanded(child: Text((data['title'] ?? 'بطولة').toString(),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16))),
                    _status(open),
                  ]),
                  const SizedBox(height: 8),
                  Text((data['description'] ?? '').toString(), style: const TextStyle(color: Colors.white70)),
                  const SizedBox(height: 8),
                  Text('المنظم: ${data['createdByName'] ?? 'عضو'}  •  المشاركون: $count',
                    style: const TextStyle(color: _v12Aqua, fontSize: 12)),
                  if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(spacing: 6, runSpacing: 6, children: snapshot.data!.docs.take(12).map((p) =>
                      Chip(avatar: const Icon(Icons.person, size: 15), label: Text((p.data()['name'] ?? 'عضو').toString()))).toList()),
                  ],
                  if (data['roundOne'] is List && (data['roundOne'] as List).isNotEmpty) ...[
                    const SizedBox(height: 10),
                    const Text('مواجهات الدور الأول', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                    ...((data['roundOne'] as List).whereType<Map>().map((m) => Padding(
                      padding: const EdgeInsets.only(top: 5),
                      child: Text(
                        m['byeName'] != null
                          ? 'تأهل مباشر: ${m['byeName']}'
                          : '${m['homeName'] ?? 'لاعب'}  ×  ${m['awayName'] ?? 'لاعب'}',
                        style: const TextStyle(color: _v12Aqua, fontSize: 12),
                      ),
                    ))),
                  ],
                  if (owner && open && count >= 2 && data['roundOne'] is! List)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: OutlinedButton.icon(
                        onPressed: () => _generateBracket(doc, snapshot.data!.docs),
                        icon: const Icon(Icons.account_tree_outlined),
                        label: const Text('تكوين جدول المواجهات الأولية'),
                      ),
                    ),
                  const SizedBox(height: 8),
                  Row(children: [
                    Expanded(child: FilledButton.tonal(
                      onPressed: open ? () => _toggleTournamentEntry(doc, joined, count) : null,
                      child: Text(joined ? 'إلغاء تسجيلي' : 'انضم للبطولة'),
                    )),
                    if (owner && open) ...[
                      const SizedBox(width: 8),
                      IconButton(
                        tooltip: 'إغلاق التسجيل',
                        onPressed: () => _closeTournament(doc),
                        icon: const Icon(Icons.lock_outline, color: Colors.amber),
                      ),
                    ],
                  ]),
                ]),
              ),
            );
          },
        );
      },
    );
  }

  Widget _status(bool open) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
    decoration: BoxDecoration(
      color: open ? Colors.green.withValues(alpha: .18) : Colors.white10,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(open ? 'التسجيل مفتوح' : 'مغلق',
      style: TextStyle(color: open ? Colors.greenAccent : Colors.white60, fontSize: 10)),
  );

  Widget _translationTab() => ListView(padding: const EdgeInsets.all(16), children: [
    _banner(Icons.translate, 'مركز الترجمة', 'اكتب النص وحدد اللغة، ثم افتح خدمة الترجمة الخارجية. لن نرسل النص قبل ضغطك على زر الترجمة.'),
    const SizedBox(height: 14),
    TextField(
      controller: _translation,
      minLines: 5,
      maxLines: 10,
      maxLength: 4000,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: 'اكتب النص الذي تريد ترجمته...',
        hintStyle: const TextStyle(color: Colors.white38),
        filled: true,
        fillColor: _v12Panel,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
    const SizedBox(height: 8),
    DropdownButtonFormField<String>(
      value: _targetLanguage,
      dropdownColor: _v12Panel,
      decoration: const InputDecoration(labelText: 'ترجم إلى'),
      items: const [
        DropdownMenuItem(value: 'en', child: Text('الإنجليزية')),
        DropdownMenuItem(value: 'ar', child: Text('العربية')),
        DropdownMenuItem(value: 'tr', child: Text('التركية')),
        DropdownMenuItem(value: 'fr', child: Text('الفرنسية')),
        DropdownMenuItem(value: 'es', child: Text('الإسبانية')),
        DropdownMenuItem(value: 'ja', child: Text('اليابانية')),
        DropdownMenuItem(value: 'ko', child: Text('الكورية')),
        DropdownMenuItem(value: 'de', child: Text('الألمانية')),
      ],
      onChanged: (value) => setState(() => _targetLanguage = value ?? 'en'),
    ),
    const SizedBox(height: 12),
    FilledButton.icon(onPressed: _translate, icon: const Icon(Icons.open_in_new), label: const Text('ترجمة النص')),
    const SizedBox(height: 8),
    OutlinedButton.icon(
      onPressed: () async {
        await Clipboard.setData(ClipboardData(text: _translation.text));
        _message('تم نسخ النص.');
      },
      icon: const Icon(Icons.copy),
      label: const Text('نسخ النص'),
    ),
    const SizedBox(height: 8),
    const Text('ملاحظة: الترجمة تتم في خدمة خارجية عند فتحها؛ تجنب إدخال كلمات المرور أو المعلومات الحساسة.',
      style: TextStyle(color: Colors.white54, fontSize: 11)),
  ]);

  Widget _securityTab() {
    final user = _user;
    return ListView(padding: const EdgeInsets.all(16), children: [
      _banner(Icons.shield_moon, 'أمان الحساب والجلسة', 'معلومات حسابك وخيار تسجيل الخروج من هذا الجهاز.'),
      const SizedBox(height: 12),
      _InfoTile(icon: Icons.email_outlined, title: 'البريد الإلكتروني', body: user?.email ?? 'غير متوفر'),
      _InfoTile(icon: Icons.verified_user_outlined, title: 'حالة التحقق', body: user?.emailVerified == true ? 'البريد مؤكد' : 'البريد لم يؤكد بعد'),
      _InfoTile(icon: Icons.fingerprint, title: 'معرّف الحساب', body: user == null ? 'غير مسجل' : '${user.uid.substring(0, min(12, user.uid.length))}…'),
      const SizedBox(height: 10),
      FilledButton.tonalIcon(onPressed: user == null ? null : _signOutThisDevice,
        icon: const Icon(Icons.logout), label: const Text('تسجيل الخروج من هذا الجهاز')),
      const SizedBox(height: 10),
      const Text('إدارة الجلسات الأخرى وإبطالها عن بُعد غير مفعّل في هذه النسخة؛ لا نعرضه كميزة مكتملة حتى نوفر خدمة خادمية آمنة.',
        style: TextStyle(color: Colors.white54, fontSize: 11, height: 1.5)),
      const SizedBox(height: 18),
      OutlinedButton.icon(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LocalHelperBotPage())),
        icon: const Icon(Icons.smart_toy_outlined),
        label: const Text('افتح مساعد الملتقى المحلي'),
      ),
    ]);
  }

  Widget _banner(IconData icon, String title, String subtitle) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(22),
      gradient: const LinearGradient(colors: [Color(0xFF3C337F), Color(0xFF1C3554), Color(0xFF11606A)]),
      border: Border.all(color: _v12Aqua.withValues(alpha: .3)),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, color: _v12Aqua, size: 34),
      const SizedBox(height: 10),
      Text(title, style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w900)),
      const SizedBox(height: 5),
      Text(subtitle, style: const TextStyle(color: Colors.white70, height: 1.5)),
    ]),
  );
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  const _InfoTile({required this.icon, required this.title, required this.body});

  @override
  Widget build(BuildContext context) => Card(
    color: _v12Panel,
    child: ListTile(
      leading: Icon(icon, color: _v12Aqua),
      title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
      subtitle: Text(body, style: const TextStyle(color: Colors.white60)),
    ),
  );
}
