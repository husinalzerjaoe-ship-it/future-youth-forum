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
    final q = raw.toLowerCase().replaceAll('أ','ا').replaceAll('إ','ا').replaceAll('آ','ا').replaceAll('ة','ه');
    bool has(List<String> words) => words.any(q.contains);
    if (has(['مرحبا','هلا','السلام','اهلا','شلونك'])) return 'هلا وغلا بيك 🌟 نورت ملتقى شباب المستقبل! اسألني عن أي قسم أو ميزة بالتطبيق.';
    if (has(['شكرا','مشكور','تسلم'])) return 'تدلل، هذا واجبي 💜';
    if (has(['روم','غرفه','غرفة','دردشه','محادث'])) return 'عندنا خمس غرف: العراق 🇮🇶، سوريا 🇸🇾، فلسطين 🇵🇸، الخليج 🌴، والأصدقاء 🌍. افتح الأقسام ثم دردشات الدول واختار الغرفة. حافظ على الاحترام ولا تنشر بياناتك الشخصية.';
    if (has(['شعر','قصيد','قصيده'])) return 'افتح الأقسام ← الشعر ← أضف الشعر. اكتب قصيدتك واضغط نشر. خلي القصيدة من كتابتك أو اذكر صاحبها إذا كانت منقولة.';
    if (has(['اقتباس','عباره','عبارة'])) return 'من الأقسام افتح الاقتباسات. تگدر تضيف عبارة جديدة أو تستخدم زر النسخ حتى تنسخ اقتباس يعجبك.';
    if (has(['ستوري','ستوريات','قصه','قصة'])) return 'افتح الأقسام ← الستوريات ← إضافة ستوري. اختار صورة أو فيديو من المعرض. الستوري تنتهي بعد 24 ساعة.';
    if (has(['فيديو','تيك','ريلز'])) return 'حالياً التطبيق يدعم نشر رابط فيديو بالمنشور وفيديوهات الستوريات حتى دقيقة. صفحة فيديوهات عمودية مثل تيك توك ضمن التطوير وليست متاحة بعد.';
    if (has(['منشور','بوست','نشر'])) return 'من تبويب المنشورات اضغط زر + أو «اكتب منشوراً»، اكتب كلامك أو أضف رابط فيديو، وبعدها انشر. تگدر تستقبل إعجابات وتعليقات على المنشور.';
    if (has(['اعجاب','لايك','قلب'])) return 'اضغط زر القلب أسفل المنشور حتى تسجل إعجابك، واضغط مرة ثانية لإزالته. عدد الإعجابات يظهر بجانبه.';
    if (has(['تعليق','تعليقات'])) return 'اضغط «تعليقات» أسفل المنشور، اكتب تعليقك في الحقل واضغط إرسال. خليك محترم وابتعد عن الإساءة.';
    if (has(['ابلاغ','إبلاغ','تبليغ','شكوى'])) return 'من أسفل المنشور اضغط رمز العلم واختار سبب الإبلاغ. البلاغ يوصل لسجل الإدارة للمراجعة. لا تستخدم البلاغات للمزاح.';
    if (has(['ملف','بروفايل','صوره شخصيه','نبذه'])) return 'افتح تبويب «ملفي» ثم «تعديل الملف الشخصي». تگدر تغير الاسم والنبذة ورابط الصورة.';
    if (has(['تقييم','نجوم'])) return 'افتح صفحة عضو واضغط النجوم لتقييمه من نجمة إلى خمس نجوم. قيّم التعامل الحقيقي وبإنصاف.';
    if (has(['حساب','تسجيل','دخول','كلمه المرور','كلمة المرور','ايميل','بريد'])) return 'أنشئ حساباً ببريد إلكتروني وكلمة مرور لا تقل عن 6 أحرف. لا تشارك كلمة المرور مع أي شخص. إذا نسيتها استخدم استعادة كلمة المرور من شاشة الدخول إذا كانت متاحة.';
    if (has(['حذف حساب','اغلاق حساب','إغلاق حساب'])) return 'حذف الحساب نهائياً غير متاح من داخل التطبيق حالياً. تواصل مع إدارة الملتقى لطلب المساعدة، ولا ترسل كلمة مرورك لأي شخص.';
    if (has(['خصوصيه','خصوصية','امان','أمان','حمايه','حماية'])) return 'نصائح الأمان: لا تنشر رقمك أو عنوانك أو كلمات المرور، لا تفتح روابط مجهولة، لا ترسل صوراً خاصة للغرباء، واحظر/بلّغ عن أي إساءة عند توفر أدواتها.';
    if (has(['تنمر','سب','شتيمه','اساءه','إساءة','مضايقه'])) return 'إذا تعرضت لإساءة لا ترد بإساءة. احتفظ بلقطة شاشة، استخدم الإبلاغ إن توفر، وابتعد عن مشاركة معلوماتك الشخصية. البلاغات الحالية تُسجل للمراجعة وليست حظراً آلياً.';
    if (has(['اداره','مدير','مشرف','قوانين','قانون'])) return 'قواعد الملتقى: الاحترام، عدم التنمر أو التهديد، عدم نشر بيانات الآخرين، عدم الاحتيال أو الروابط الضارة، واحترام حقوق النشر. بعض إجراءات الإشراف ما زالت قيد التطوير.';
    if (has(['العراق','سوريا','فلسطين','الخليج'])) return 'غرف الدول موجودة ضمن الأقسام ← دردشات الدول. اختار الغرفة المناسبة وتواصل بأدب مع الأعضاء.';
    if (has(['صباح الخير','مساء الخير','تصبح'])) return 'صباح النور أو مساء الورد 🌷 نتمنى لك وقتاً جميلاً داخل الملتقى.';
    if (has(['نصيحه','نصيحة','دراسه','دراسة','نجاح'])) return 'نصيحتي: حدد هدفاً صغيراً لليوم، قسّمه لخطوات، وداوم عليه. التقدم المستمر أهم من الحماس المؤقت ✨';
    if (has(['صديق','اصدقاء','تعارف'])) return 'تگدر تتعرف على الأعضاء من المنشورات والغرف العامة. لا تستعجل الثقة ولا تشارك بياناتك أو صورك الخاصة مع أشخاص ما تعرفهم.';
    if (has(['انترنت','بدون نت','اوفلاين'])) return 'البوت نفسه يعمل بدون إنترنت لأنه مبرمج داخل التطبيق. أما المحادثات والمنشورات والستوريات فتحتاج اتصالاً بالإنترنت وخدمات Firebase.';
    if (has(['ذكاء اصطناعي','ai','chatgpt'])) return 'أنا مساعد محلي مجاني، ما أستخدم مفتاح API ولا أرسل أسئلتك لخدمة ذكاء اصطناعي. إجاباتي مبنية على معلومات وقواعد مضافة مسبقاً، لذلك قد لا أفهم كل سؤال.';
    if (has(['اقتراح','فكره','فكرة','ميزة','مميزات'])) return 'أفكار نطمح نضيفها: رسائل خاصة، متابعة الأصدقاء، إشعارات، بث مباشر، تحديات ومسابقات، شارات إنجاز، بحث متقدم، ومقاطع فيديو عمودية. بعض هذه الميزات لم تُنفذ بعد.';
    if (has(['وقت','24 ساعه','24 ساعة'])) return 'الستوريات مصممة للظهور 24 ساعة، وبعدها يخفيها التطبيق من العرض. التنظيف النهائي للملفات القديمة يحتاج مهمة خلفية على الخادم.';
    return 'أريد أساعدك 💜 حالياً أفهم أسئلة عن: الحساب، الملف الشخصي، المنشورات، الإعجابات، التعليقات، الإبلاغ، الغرف، الشعر، الاقتباسات، الستوريات، الفيديو، الخصوصية، الأمان، وقوانين الملتقى. جرّب تصيغ سؤالك بكلمات من هالمواضيع. أنا بوت محلي مجاني وليس ذكاءً اصطناعياً عاماً.';
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
