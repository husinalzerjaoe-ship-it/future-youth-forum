import 'package:flutter/material.dart';

const _botColor = Color(0xFF6554D9);

class LocalHelperBotPage extends StatefulWidget {
  const LocalHelperBotPage({super.key});
  @override
  State<LocalHelperBotPage> createState() => _LocalHelperBotPageState();
}

class _LocalHelperBotPageState extends State<LocalHelperBotPage> {
  final input = TextEditingController();
  final scroll = ScrollController();
  final List<Map<String, String>> messages = [
    {'from': 'bot', 'text': 'هلا بيك! أنا مساعد ملتقى شباب المستقبل 🤖\nأكدر أساعدك بمعلومات عن التطبيق، الرومات، النشر، والخصوصية. اختار سؤال أو اكتب سؤالك.'},
  ];
  bool thinking = false;

  @override
  void dispose() {
    input.dispose();
    scroll.dispose();
    super.dispose();
  }

  String answer(String raw) {
    final q = raw.toLowerCase();
    if (q.contains('روم') || q.contains('دردشة') || q.contains('محادث')) {
      return 'تگدر تدخل من الأقسام ← دردشات الدول، وتختار غرفة العراق أو سوريا أو فلسطين أو الخليج أو الأصدقاء. تذكّر تحترم بقية الأعضاء ولا تشارك معلوماتك الخاصة.';
    }
    if (q.contains('شعر') || q.contains('قصيد')) {
      return 'من الأقسام افتح الشعر، واضغط إضافة حتى تنشر قصيدتك. وتگدر تنسخ النصوص من زر النسخ.';
    }
    if (q.contains('اقتباس') || q.contains('نسخ')) {
      return 'افتح قسم الاقتباسات من الأقسام. اضغط علامة النسخ بجانب العبارة حتى تنسخها.';
    }
    if (q.contains('ستوري') || q.contains('ستور') || q.contains('فيديو') || q.contains('صورة')) {
      return 'من الأقسام افتح الستوريات، ثم إضافة ستوري واختار صورة أو فيديو من جهازك. الستوريات تظهر لمدة 24 ساعة حسب إعداد التطبيق.';
    }
    if (q.contains('حساب') || q.contains('دخول') || q.contains('تسجيل') || q.contains('كلمة المرور')) {
      return 'لإنشاء حساب استخدم بريدك وكلمة مرور، واحتفظ بكلمة المرور لنفسك. إذا نسيتها، استخدم خيار استعادة كلمة المرور إذا كان متاحاً في شاشة الدخول.';
    }
    if (q.contains('خصوص') || q.contains('أمان') || q.contains('امان') || q.contains('حماية')) {
      return 'لا تنشر رقم هاتفك أو عنوانك أو كلمات المرور. لا تضغط روابط مجهولة، وإذا أزعجك عضو احتفظ بالدليل وتواصل مع إدارة التطبيق.';
    }
    if (q.contains('منشور') || q.contains('نشر') || q.contains('بوست')) {
      return 'من تبويب المنشورات تگدر تضيف منشورك وتشاركه مع أعضاء الملتقى. خليه محترم وابتعد عن نشر معلومات الآخرين بدون إذنهم.';
    }
    if (q.contains('مرحبا') || q.contains('هلا') || q.contains('السلام') || q.contains('اهلا')) {
      return 'أهلاً وسهلاً بيك 🌟 شنو تحب تعرف عن الملتقى؟';
    }
    if (q.contains('شكرا') || q.contains('مشكور')) {
      return 'تدلل، بالخدمة دائماً 💜';
    }
    return 'ما عندي جواب مؤكد عن هذا السؤال حالياً. جرّب تسألني عن الرومات أو الشعر أو الاقتباسات أو الستوريات أو الحساب والخصوصية. أنا بوت محلي بإجابات محددة، مو ذكاء اصطناعي متصل بالإنترنت.';
  }

  void send([String? suggestion]) {
    final value = (suggestion ?? input.text).trim();
    if (value.isEmpty || thinking) return;
    setState(() {
      messages.add({'from': 'user', 'text': value});
      input.clear();
      thinking = true;
    });
    Future<void>.delayed(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      setState(() {
        messages.add({'from': 'bot', 'text': answer(value)});
        thinking = false;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (scroll.hasClients) scroll.animateTo(
          scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      });
    });
  }

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.rtl,
    child: Scaffold(
      appBar: AppBar(
        title: const Row(children: [
          CircleAvatar(backgroundColor: Color(0xFFEAE6FF), child: Icon(Icons.smart_toy, color: _botColor)),
          SizedBox(width: 10),
          Text('مساعد الملتقى'),
        ]),
      ),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
          child: Wrap(spacing: 8, runSpacing: 8, children: [
            'شلون أدخل الرومات؟', 'شلون أنشر ستوري؟', 'شلون أحمي حسابي؟', 'شلون أنشر قصيدة؟',
          ].map((q) => ActionChip(label: Text(q), onPressed: () => send(q))).toList()),
        ),
        Expanded(child: ListView.builder(
          controller: scroll,
          padding: const EdgeInsets.all(12),
          itemCount: messages.length,
          itemBuilder: (context, index) {
            final item = messages[index];
            final isBot = item['from'] == 'bot';
            return Align(
              alignment: isBot ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * .84),
                margin: const EdgeInsets.symmetric(vertical: 5),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isBot ? const Color(0xFFEDEAFF) : const Color(0xFFE7F3FF),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(item['text'] ?? '', style: const TextStyle(height: 1.5)),
              ),
            );
          },
        )),
        if (thinking) const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Align(alignment: Alignment.centerRight, child: Text('المساعد يكتب...')),
        ),
        SafeArea(top: false, child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(children: [
            Expanded(child: TextField(
              controller: input,
              minLines: 1,
              maxLines: 4,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => send(),
              decoration: const InputDecoration(
                hintText: 'اكتب سؤالك...',
                border: OutlineInputBorder(),
              ),
            )),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed: thinking ? null : send,
              icon: const Icon(Icons.send),
              style: IconButton.styleFrom(backgroundColor: _botColor, foregroundColor: Colors.white),
            ),
          ]),
        )),
      ]),
    ),
  );
}
