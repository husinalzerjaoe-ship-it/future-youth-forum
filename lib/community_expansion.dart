import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

const _interestNames = ['الأنمي والمانغا', 'كرة القدم', 'الشعر والأدب', 'الألعاب', 'التقنية', 'التصوير والفن'];
const _interestIcons = [Icons.movie_filter_outlined, Icons.sports_soccer, Icons.menu_book_outlined, Icons.sports_esports_outlined, Icons.memory_outlined, Icons.palette_outlined];

class CommunityExpansionPage extends StatelessWidget {
  const CommunityExpansionPage({super.key});
  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.rtl,
    child: DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(title: const Text('مجتمعنا وفعالياتنا'), bottom: const TabBar(isScrollable: true, tabs: [
          Tab(icon: Icon(Icons.stadium_outlined), text: 'استاد الأصدقاء'),
          Tab(icon: Icon(Icons.event_available_outlined), text: 'الفعاليات'),
          Tab(icon: Icon(Icons.question_answer_outlined), text: 'صندوق المجتمع'),
          Tab(icon: Icon(Icons.groups_2_outlined), text: 'المجتمعات'),
        ])),
        body: const TabBarView(children: [WatchPartiesPage(), CommunityEventsPage(), CommunityQuestionPage(), CommunityDirectoryPage()]),
      ),
    ),
  );
}

class WatchPartiesPage extends StatefulWidget {
  const WatchPartiesPage({super.key});
  @override
  State<WatchPartiesPage> createState() => _WatchPartiesPageState();
}
class _WatchPartiesPageState extends State<WatchPartiesPage> {
  final db = FirebaseFirestore.instance;
  String get uid => FirebaseAuth.instance.currentUser!.uid;
  Future<void> createParty() async {
    final title = TextEditingController();
    final match = TextEditingController();
    final stream = TextEditingController();
    final form = GlobalKey<FormState>();
    final ok = await showDialog<bool>(context: context, builder: (ctx) => Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(title: const Text('إنشاء جلسة مشاهدة'),
        content: Form(key: form, child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextFormField(controller: title, maxLength: 60, decoration: const InputDecoration(labelText: 'اسم الجلسة'), validator: (v) => v == null || v.trim().length < 3 ? 'اكتب اسماً من 3 أحرف' : null),
          TextFormField(controller: match, maxLength: 100, decoration: const InputDecoration(labelText: 'المباراة')),
          TextFormField(controller: stream, keyboardType: TextInputType.url, decoration: const InputDecoration(labelText: 'رابط البث الرسمي أو المرخّص', hintText: 'https://...'), validator: (v) { final u = Uri.tryParse((v ?? '').trim()); return u == null || u.scheme != 'https' || u.host.isEmpty ? 'أدخل رابط HTTPS صحيحاً' : null; }),
          const Text('البث يفتح عبر الجهة المالكة للحقوق، والدردشة الجماعية تبقى داخل التطبيق.', style: TextStyle(fontSize: 12, color: Colors.grey)),
        ]))),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')), FilledButton(onPressed: () => Navigator.pop(ctx, form.currentState?.validate() ?? false), child: const Text('إنشاء'))],
      ),
    ));
    if (ok == true) {
      try {
        await db.collection('watchParties').add({
          'title': title.text.trim(), 'match': match.text.trim().isEmpty ? title.text.trim() : match.text.trim(),
          'streamUrl': stream.text.trim(), 'hostId': uid, 'members': [uid],
          'createdAt': FieldValue.serverTimestamp(), 'status': 'open',
        });
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إنشاء جلسة المشاهدة')));
      } catch (_) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تعذر الإنشاء. انشر قواعد Firestore أولاً.')));
      }
    }
    title.dispose(); match.dispose(); stream.dispose();
  }
  @override
  Widget build(BuildContext context) => Scaffold(
    floatingActionButton: FloatingActionButton.extended(onPressed: createParty, icon: const Icon(Icons.add), label: const Text('جلسة جديدة')),
    body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: db.collection('watchParties').where('status', isEqualTo: 'open').limit(50).snapshots(),
      builder: (context, s) {
        if (s.hasError) return const Center(child: Text('تعذر تحميل الجلسات. تحقق من قواعد Firestore.'));
        if (!s.hasData) return const Center(child: CircularProgressIndicator());
        if (s.data!.docs.isEmpty) return const _EmptyCommunity(icon: Icons.stadium_outlined, text: 'ماكو جلسات حالياً. أنشئ جلسة وادعُ أصدقاءك.');
        return ListView(padding: const EdgeInsets.all(12), children: [
          const Card(child: Padding(padding: EdgeInsets.all(14), child: Text('⚽ اجتمعوا على المباراة، افتحوا البث المرخّص، وتناقشوا مباشرة داخل غرفة الجلسة.'))),
          ...s.data!.docs.map((d) => Card(child: ListTile(
            leading: const CircleAvatar(child: Icon(Icons.live_tv_rounded)),
            title: Text(d.data()['title'] ?? 'جلسة مشاهدة'),
            subtitle: Text((d.data()['match'] ?? '') + ' • ' + (List<String>.from(d.data()['members'] ?? []).length.toString()) + ' مشارك'),
            trailing: const Icon(Icons.chevron_left),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => WatchPartyRoomPage(partyId: d.id, party: d.data()))),
          ))),
        ]);
      },
    ),
  );
}

class WatchPartyRoomPage extends StatefulWidget {
  const WatchPartyRoomPage({super.key, required this.partyId, required this.party});
  final String partyId;
  final Map<String, dynamic> party;
  @override
  State<WatchPartyRoomPage> createState() => _WatchPartyRoomPageState();
}
class _WatchPartyRoomPageState extends State<WatchPartyRoomPage> {
  final db = FirebaseFirestore.instance;
  final message = TextEditingController();
  bool busy = false;
  String get uid => FirebaseAuth.instance.currentUser!.uid;
  DocumentReference<Map<String, dynamic>> get party => db.collection('watchParties').doc(widget.partyId);
  @override
  void initState() { super.initState(); party.update({'members': FieldValue.arrayUnion([uid])}).catchError((_) {}); }
  @override
  void dispose() { message.dispose(); super.dispose(); }
  Future<void> send() async {
    final value = message.text.trim();
    if (value.isEmpty || busy) return;
    setState(() => busy = true);
    try {
      await party.collection('messages').add({
        'senderId': uid, 'senderName': FirebaseAuth.instance.currentUser?.displayName ?? 'عضو',
        'text': value, 'createdAt': FieldValue.serverTimestamp(),
      });
      message.clear();
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تعذر إرسال الرسالة.')));
    } finally { if (mounted) setState(() => busy = false); }
  }
  Future<void> openStream() async {
    final uri = Uri.tryParse(widget.party['streamUrl'] as String? ?? '');
    if (uri != null && uri.scheme == 'https') await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
  @override
  Widget build(BuildContext context) => Directionality(textDirection: TextDirection.rtl, child: Scaffold(
    appBar: AppBar(title: Text(widget.party['title'] ?? 'استاد الأصدقاء'), actions: [
      IconButton(tooltip: 'نسخ رمز الجلسة', icon: const Icon(Icons.copy), onPressed: () {
        Clipboard.setData(ClipboardData(text: widget.partyId));
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم نسخ رمز الجلسة')));
      }),
    ]),
    body: Column(children: [
      Card(margin: const EdgeInsets.all(12), child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(widget.party['match'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        FilledButton.icon(onPressed: openStream, icon: const Icon(Icons.play_circle_fill), label: const Text('افتح البث الرسمي')),
        const Text('يفتح البث في موقع أو تطبيق مزوّد الخدمة. الدردشة تبقى هنا.', style: TextStyle(fontSize: 11, color: Colors.grey)),
      ]))),
      Expanded(child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: party.collection('messages').orderBy('createdAt').limit(200).snapshots(),
        builder: (context, s) {
          if (s.hasError) return const Center(child: Text('تعذر تحميل دردشة الجلسة.'));
          if (!s.hasData) return const Center(child: CircularProgressIndicator());
          final docs = s.data!.docs;
          return ListView.builder(reverse: true, padding: const EdgeInsets.all(12), itemCount: docs.length, itemBuilder: (context, i) {
            final item = docs[docs.length - 1 - i].data();
            final mine = item['senderId'] == uid;
            return Align(alignment: mine ? Alignment.centerRight : Alignment.centerLeft, child: Container(
              margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(11),
              constraints: const BoxConstraints(maxWidth: 310),
              decoration: BoxDecoration(color: mine ? Theme.of(context).colorScheme.primaryContainer : Theme.of(context).colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(14)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                if (!mine) Text(item['senderName'] ?? 'عضو', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                Text(item['text'] ?? ''),
              ]),
            ));
          });
        },
      )),
      SafeArea(child: Padding(padding: const EdgeInsets.all(10), child: Row(children: [
        Expanded(child: TextField(controller: message, maxLength: 500, decoration: const InputDecoration(hintText: 'اكتب تعليقك على المباراة...', counterText: '', border: OutlineInputBorder()))),
        const SizedBox(width: 8),
        IconButton.filled(onPressed: busy ? null : send, icon: const Icon(Icons.send)),
      ]))),
    ]),
  ));
}

class CommunityEventsPage extends StatefulWidget {
  const CommunityEventsPage({super.key});
  @override
  State<CommunityEventsPage> createState() => _CommunityEventsPageState();
}
class _CommunityEventsPageState extends State<CommunityEventsPage> {
  final db = FirebaseFirestore.instance;
  String get uid => FirebaseAuth.instance.currentUser!.uid;
  Future<void> createEvent() async {
    final title = TextEditingController();
    final details = TextEditingController();
    DateTime when = DateTime.now().add(const Duration(days: 1));
    final ok = await showDialog<bool>(context: context, builder: (ctx) => Directionality(textDirection: TextDirection.rtl, child: StatefulBuilder(builder: (ctx, setD) => AlertDialog(
      title: const Text('إضافة فعالية'),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: title, maxLength: 80, decoration: const InputDecoration(labelText: 'عنوان الفعالية')),
        TextField(controller: details, maxLength: 500, maxLines: 3, decoration: const InputDecoration(labelText: 'التفاصيل')),
        OutlinedButton.icon(icon: const Icon(Icons.calendar_month), label: Text(when.year.toString() + '/' + when.month.toString() + '/' + when.day.toString()), onPressed: () async {
          final date = await showDatePicker(context: ctx, initialDate: when, firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)));
          if (date != null) setD(() => when = date);
        }),
      ])),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')), FilledButton(onPressed: () => Navigator.pop(ctx, title.text.trim().length >= 3), child: const Text('نشر'))],
    ))));
    if (ok == true) {
      try {
        await db.collection('communityEvents').add({
          'title': title.text.trim(), 'details': details.text.trim(), 'startsAt': Timestamp.fromDate(when),
          'createdBy': uid, 'attendees': [uid], 'createdAt': FieldValue.serverTimestamp(),
        });
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم نشر الفعالية')));
      } catch (_) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تعذر النشر. تحقق من قواعد Firestore.')));
      }
    }
    title.dispose(); details.dispose();
  }
  @override
  Widget build(BuildContext context) => Scaffold(
    floatingActionButton: FloatingActionButton.extended(onPressed: createEvent, icon: const Icon(Icons.add), label: const Text('فعالية جديدة')),
    body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: db.collection('communityEvents').orderBy('startsAt').limit(60).snapshots(),
      builder: (context, s) {
        if (s.hasError) return const Center(child: Text('تعذر تحميل الفعاليات.'));
        if (!s.hasData) return const Center(child: CircularProgressIndicator());
        if (s.data!.docs.isEmpty) return const _EmptyCommunity(icon: Icons.event_available, text: 'لا توجد فعاليات بعد. كن أول من ينظم فعالية!');
        return ListView(padding: const EdgeInsets.all(12), children: s.data!.docs.map((d) {
          final data = d.data();
          final attendees = List<String>.from(data['attendees'] ?? []);
          final date = (data['startsAt'] as Timestamp?)?.toDate();
          final joined = attendees.contains(uid);
          return Card(child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(data['title'] ?? 'فعالية', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            if ((data['details'] ?? '').toString().isNotEmpty) Padding(padding: const EdgeInsets.only(top: 6), child: Text(data['details'])),
            const SizedBox(height: 8),
            Row(children: [
              const Icon(Icons.calendar_today, size: 15, color: Colors.grey), const SizedBox(width: 5),
              Text(date == null ? 'الموعد غير محدد' : date.year.toString() + '/' + date.month.toString() + '/' + date.day.toString()),
              const Spacer(), Text(attendees.length.toString() + ' مشارك'),
            ]),
            Align(alignment: Alignment.centerLeft, child: TextButton.icon(onPressed: () async {
              try { await d.reference.update({'attendees': joined ? FieldValue.arrayRemove([uid]) : FieldValue.arrayUnion([uid])}); }
              catch (_) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تعذر تحديث المشاركة.'))); }
            }, icon: Icon(joined ? Icons.check_circle : Icons.add_circle_outline), label: Text(joined ? 'إلغاء المشاركة' : 'سأشارك'))),
          ])));
        }).toList()),
      },
    ),
  );
}

class CommunityQuestionPage extends StatefulWidget {
  const CommunityQuestionPage({super.key});
  @override
  State<CommunityQuestionPage> createState() => _CommunityQuestionPageState();
}
class _CommunityQuestionPageState extends State<CommunityQuestionPage> {
  final db = FirebaseFirestore.instance;
  String get uid => FirebaseAuth.instance.currentUser!.uid;
  Future<void> addQuestion() async {
    final text = TextEditingController();
    final ok = await showDialog<bool>(context: context, builder: (ctx) => Directionality(textDirection: TextDirection.rtl, child: AlertDialog(
      title: const Text('سؤال أو اعتراف مجهول'),
      content: TextField(controller: text, maxLines: 5, maxLength: 700, decoration: const InputDecoration(hintText: 'لا تكتب معلومات شخصية حساسة...', border: OutlineInputBorder())),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')), FilledButton(onPressed: () => Navigator.pop(ctx, text.text.trim().isNotEmpty), child: const Text('نشر مجهول'))],
    )));
    if (ok == true) {
      try { await db.collection('communityQuestions').add({'text': text.text.trim(), 'authorId': uid, 'createdAt': FieldValue.serverTimestamp(), 'anonymous': true}); }
      catch (_) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تعذر النشر. تحقق من قواعد Firestore.'))); }
    }
    text.dispose();
  }
  @override
  Widget build(BuildContext context) => Scaffold(
    floatingActionButton: FloatingActionButton.extended(onPressed: addQuestion, icon: const Icon(Icons.add), label: const Text('اكتب بسرية')),
    body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: db.collection('communityQuestions').orderBy('createdAt', descending: true).limit(60).snapshots(),
      builder: (context, s) {
        if (s.hasError) return const Center(child: Text('تعذر تحميل المشاركات.'));
        if (!s.hasData) return const Center(child: CircularProgressIndicator());
        if (s.data!.docs.isEmpty) return const _EmptyCommunity(icon: Icons.question_answer_outlined, text: 'ابدأ أول سؤال أو اعتراف مجهول.');
        return ListView(padding: const EdgeInsets.all(12), children: [
          const Card(child: Padding(padding: EdgeInsets.all(12), child: Text('يظهر النص للجميع بدون اسم الناشر، لكن الإدارة قد تحتاج معرفة صاحب البلاغ عند إساءة الاستخدام. لا تكتب أسراراً أو بيانات شخصية.'))),
          ...s.data!.docs.map((d) => Card(child: ListTile(leading: const CircleAvatar(child: Icon(Icons.question_mark)), title: Text(d.data()['text'] ?? ''), subtitle: const Text('عضو مجهول')))),
        ]);
      },
    ),
  );
}

class CommunityDirectoryPage extends StatelessWidget {
  const CommunityDirectoryPage({super.key});
  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(12), children: [
    const Card(child: Padding(padding: EdgeInsets.all(14), child: Text('اختَر اهتمامك وتابع النقاشات والفعاليات الخاصة به.'))),
    ...List.generate(_interestNames.length, (i) => Card(child: ListTile(
      leading: CircleAvatar(child: Icon(_interestIcons[i])),
      title: Text(_interestNames[i]),
      subtitle: const Text('منشورات ونقاشات وأصدقاء بنفس الاهتمام'),
      trailing: const Icon(Icons.arrow_forward_ios, size: 15),
      onTap: () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تجد منشورات هذا الاهتمام ضمن تبويب المنشورات والأقسام.'))),
    ))),
    const _WritingAssistantCard(),
  ]);
}

class _WritingAssistantCard extends StatefulWidget {
  const _WritingAssistantCard();
  @override
  State<_WritingAssistantCard> createState() => _WritingAssistantCardState();
}
class _WritingAssistantCardState extends State<_WritingAssistantCard> {
  final input = TextEditingController();
  String suggestion = '';
  @override
  void dispose() { input.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => Card(child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
    const Text('مساعد صياغة المنشورات', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
    const Text('قالب محلي بسيط يرتب فكرتك دون إرسالها لخدمة خارجية.'),
    TextField(controller: input, maxLines: 3, decoration: const InputDecoration(labelText: 'اكتب فكرتك')),
    FilledButton(onPressed: () { if (input.text.trim().isNotEmpty) setState(() => suggestion = 'مساحة للنقاش 💬\n\n' + input.text.trim() + '\n\nشنو رأيكم؟ شاركونا أفكاركم باحترام.'); }, child: const Text('رتّب فكرتي')),
    if (suggestion.isNotEmpty) ...[
      SelectableText(suggestion),
      TextButton.icon(onPressed: () { Clipboard.setData(ClipboardData(text: suggestion)); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم نسخ النص'))); }, icon: const Icon(Icons.copy), label: const Text('نسخ')),
    ],
  ])));
}

class _EmptyCommunity extends StatelessWidget {
  const _EmptyCommunity({required this.icon, required this.text});
  final IconData icon;
  final String text;
  @override
  Widget build(BuildContext context) => Center(child: Padding(padding: const EdgeInsets.all(28), child: Column(mainAxisSize: MainAxisSize.min, children: [
    Icon(icon, size: 48, color: Colors.grey), const SizedBox(height: 12), Text(text, textAlign: TextAlign.center),
  ])));
}
