import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _knowledgeBrand = Color(0xFF6554D9);

class _CornerEntry {
  final String category, title, body, tag;
  const _CornerEntry(this.category, this.title, this.body, this.tag);
}

const _cornerEntries = <_CornerEntry>[
  _CornerEntry('معلومات عامة','لماذا السماء زرقاء؟','يتشتت ضوء الشمس في الغلاف الجوي، ويتشتت اللون الأزرق أكثر من الألوان ذات الأطوال الموجية الأطول.','علوم'),
  _CornerEntry('معلومات عامة','كم عظمة في جسم الإنسان البالغ؟','يحتوي جسم الإنسان البالغ عادةً على 206 عظمات، وقد يختلف العدد قليلاً بين الأشخاص.','جسم الإنسان'),
  _CornerEntry('معلومات عامة','ما أكبر محيط على الأرض؟','المحيط الهادئ هو أكبر محيط على كوكب الأرض.','جغرافيا'),
  _CornerEntry('معلومات عامة','لماذا نرى البرق قبل سماع الرعد؟','لأن الضوء ينتقل أسرع بكثير من الصوت، فيصل ضوء البرق إلى أعيننا قبل صوت الرعد.','فيزياء'),
  _CornerEntry('معلومات عامة','ما اللغة ذات أكبر عدد من المتحدثين الأصليين؟','اللغة الصينية المندرينية من أكثر اللغات عدداً في المتحدثين الأصليين.','لغات'),
  _CornerEntry('تقنية','ما وظيفة المصادقة الثنائية؟','تضيف خطوة تحقق ثانية إلى كلمة المرور، مثل رمز مؤقت أو مفتاح أمان، لتصعّب الاستيلاء على الحساب.','أمان رقمي'),
  _CornerEntry('تقنية','هل الشحن طوال الليل يضر الهاتف دائماً؟','الهواتف الحديثة تدير الشحن تلقائياً، لكن الحرارة المرتفعة هي عامل مهم في تدهور البطارية؛ استخدم شاحناً موثوقاً وأبعد الهاتف عن الحرارة.','هواتف'),
  _CornerEntry('تقنية','ما الفرق بين Wi‑Fi والإنترنت؟','Wi‑Fi اتصال لاسلكي بين جهازك والشبكة المحلية، أما الإنترنت فهو شبكة عالمية يمكن الوصول إليها عبر هذا الاتصال أو غيره.','شبكات'),
  _CornerEntry('تقنية','كيف تتعرف على رابط مشبوه؟','تحقق من اسم النطاق حرفاً بحرف، ولا تثق بالرسائل المستعجلة أو الجوائز المجهولة، ولا تدخل كلمة المرور من رابط غير متوقع.','حماية'),
  _CornerEntry('نصائح وعادات','قاعدة العشر دقائق','إذا كانت المهمة ثقيلة، ابدأ بها عشر دقائق فقط. البداية الصغيرة تقلل التسويف وتساعدك على الاستمرار.','إنتاجية'),
  _CornerEntry('نصائح وعادات','استراحة العين','عند استخدام الشاشة طويلاً، جرّب قاعدة 20-20-20: كل 20 دقيقة انظر إلى شيء يبعد نحو 20 قدماً لمدة 20 ثانية.','عادات'),
  _CornerEntry('نصائح وعادات','رتّب يومك بثلاث أولويات','اكتب أهم ثلاث مهام لليوم، وابدأ بالأكثر أهمية قبل الانشغال بالتفاصيل الصغيرة.','تنظيم'),
  _CornerEntry('نصائح وعادات','استمع قبل أن تجيب','اترك للطرف الآخر فرصة إكمال فكرته، ثم أعد صياغة ما فهمته قبل الرد. هذا يقلل سوء الفهم.','تواصل'),
  _CornerEntry('دراسة وتعلّم','طريقة الاسترجاع النشط','أغلق الكتاب وحاول تذكر الفكرة بصوتك أو كتابتها. اختبار الذاكرة غالباً أنفع من إعادة القراءة وحدها.','دراسة'),
  _CornerEntry('دراسة وتعلّم','قسّم المادة','حوّل الدرس إلى أجزاء صغيرة، وراجعها على فترات متباعدة بدلاً من حشر كل شيء في جلسة واحدة.','مذاكرة'),
  _CornerEntry('دراسة وتعلّم','علّم غيرك','اشرح الفكرة لشخص آخر بكلمات بسيطة. إذا تعثرت في الشرح، فهذه إشارة إلى الجزء الذي يحتاج مراجعة.','تعلم'),
  _CornerEntry('لغة وأدب','ما الفرق بين التشبيه والاستعارة؟','التشبيه يذكر طرفين أو أداة تشبيه غالباً، أما الاستعارة فتقوم على تشبيه حُذف أحد طرفيه.','بلاغة'),
  _CornerEntry('لغة وأدب','ما معنى السجع؟','هو توافق أواخر الجمل في الحرف أو النغمة في النثر، ويمنح العبارة إيقاعاً موسيقياً.','أدب'),
  _CornerEntry('لغة وأدب','كلمة اليوم: يتأمّل','يتأمّل: ينظر أو يفكر بعمق وروية، ويقال تأمّل المشهد أي أمعن النظر فيه.','مفردات'),
  _CornerEntry('ألغاز','شيء كلما أخذت منه كبر، ما هو؟','الحفرة.','لغز'),
  _CornerEntry('ألغاز','له أسنان ولا يعض، ما هو؟','المشط.','لغز'),
  _CornerEntry('ألغاز','ما الشيء الذي يكتب ولا يقرأ؟','القلم.','لغز'),
  _CornerEntry('أسئلة للنقاش','هل النجاح حظ أم استمرارية؟','شارك رأيك بمثال من الحياة، وهل تعتقد أن الاستمرارية تستطيع تعويض البداية الصعبة؟','نقاش'),
  _CornerEntry('أسئلة للنقاش','ما المهارة التي تتمنى تعلمها؟','اذكر مهارة واحدة، ولماذا اخترتها، وما أول خطوة عملية لتعلمها؟','نقاش'),
  _CornerEntry('أسئلة للنقاش','هل تفضّل الكتب أم التعلم بالفيديو؟','قارن بين التركيز وسهولة الوصول وتثبيت المعلومات، واذكر طريقتك المفضلة.','نقاش'),
  _CornerEntry('تحديات إبداعية','اكتب قصة من ثلاثة أسطر','ابدأ القصة بهذه العبارة: «وجدت رسالة قديمة تحت الباب…» واجعل لها نهاية مفاجئة.','كتابة'),
  _CornerEntry('تحديات إبداعية','تحدي وصف بلا اسم','صف مكانك المفضل بخمس جمل من دون ذكر اسمه، ودع الآخرين يخمّنون.','كتابة'),
  _CornerEntry('تحديات إبداعية','اصنع اقتباسك الخاص','اكتب عبارة قصيرة تشجع شخصاً يمر بيوم صعب، وشاركها في مكتبة الاقتباسات.','إبداع'),
];

class KnowledgeCornerPage extends StatefulWidget {
  const KnowledgeCornerPage({super.key});
  @override State<KnowledgeCornerPage> createState() => _KnowledgeCornerPageState();
}

class _KnowledgeCornerPageState extends State<KnowledgeCornerPage> {
  String _category = 'الكل';
  final Set<String> _saved = {};
  bool _ready = false;
  _CornerEntry? _daily;
  List<String> get _categories => ['الكل', ..._cornerEntries.map((e) => e.category).toSet()];
  List<_CornerEntry> get _visible => _cornerEntries.where((e) => _category == 'الكل' || e.category == _category).toList();

  @override void initState() { super.initState(); _load(); }
  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _saved.addAll(prefs.getStringList('knowledge_corner_saved') ?? []);
    final day = DateTime.now().year * 10000 + DateTime.now().month * 100 + DateTime.now().day;
    _daily = _cornerEntries[day % _cornerEntries.length];
    if (mounted) setState(() => _ready = true);
  }
  Future<void> _toggleSaved(_CornerEntry e) async {
    final key = e.title;
    setState(() { if (!_saved.add(key)) _saved.remove(key); });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('knowledge_corner_saved', _saved.toList());
  }
  void _copy(_CornerEntry e) {
    Clipboard.setData(ClipboardData(text: '${e.title}\n${e.body}'));
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم نسخ المعلومة')));
  }
  void _surprise() {
    final item = _cornerEntries[Random().nextInt(_cornerEntries.length)];
    showModalBottomSheet<void>(context: context, showDragHandle: true, builder: (c) => Directionality(
      textDirection: TextDirection.rtl,
      child: Padding(padding: const EdgeInsets.fromLTRB(20, 8, 20, 28), child: Column(
        mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Chip(avatar: const Icon(Icons.auto_awesome, size: 17), label: Text(item.category)),
          Text(item.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10), Text(item.body, style: const TextStyle(fontSize: 16, height: 1.6)),
          Align(alignment: Alignment.centerLeft, child: TextButton.icon(onPressed: () { Navigator.pop(c); _copy(item); }, icon: const Icon(Icons.copy), label: const Text('نسخ'))),
        ],
      )),
    ));
  }

  @override Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.rtl,
    child: Scaffold(
      appBar: AppBar(title: const Text('ركن المعرفة والترفيه'), actions: [
        IconButton(tooltip: 'المحفوظات', onPressed: () => setState(() => _category = 'المحفوظات'), icon: const Icon(Icons.bookmark_outline)),
        IconButton(tooltip: 'فاجئني', onPressed: _surprise, icon: const Icon(Icons.casino_outlined)),
      ]),
      body: !_ready ? const Center(child: CircularProgressIndicator()) : Column(children: [
        if (_daily != null) Container(
          width: double.infinity, margin: const EdgeInsets.fromLTRB(12, 12, 12, 8), padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF171936), _knowledgeBrand, Color(0xFF35BCEB)]), borderRadius: BorderRadius.circular(20)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Row(children: [Icon(Icons.wb_sunny_outlined, color: Colors.white), SizedBox(width: 8), Text('معلومة اليوم', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))]),
            const SizedBox(height: 9), Text(_daily!.title, style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w900)),
            const SizedBox(height: 6), Text(_daily!.body, style: const TextStyle(color: Colors.white, height: 1.55)),
            Align(alignment: Alignment.centerLeft, child: TextButton.icon(onPressed: () => _copy(_daily!), icon: const Icon(Icons.copy, color: Colors.white), label: const Text('نسخ المعلومة', style: TextStyle(color: Colors.white)))),
          ]),
        ),
        SizedBox(height: 48, child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 10), children: [
          ..._categories.map((v) => Padding(padding: const EdgeInsets.symmetric(horizontal: 3), child: ChoiceChip(label: Text(v), selected: _category == v, onSelected: (_) => setState(() => _category = v)))),
          Padding(padding: const EdgeInsets.symmetric(horizontal: 3), child: ChoiceChip(label: const Text('المحفوظات'), selected: _category == 'المحفوظات', onSelected: (_) => setState(() => _category = 'المحفوظات'))),
        ])),
        Expanded(child: Builder(builder: (context) {
          final items = _category == 'المحفوظات' ? _cornerEntries.where((e) => _saved.contains(e.title)).toList() : _visible;
          if (items.isEmpty) return const Center(child: Text('ماكو محفوظات بعد. اضغط علامة الحفظ على أي بطاقة.'));
          return ListView.builder(padding: const EdgeInsets.fromLTRB(12, 8, 12, 20), itemCount: items.length, itemBuilder: (context, i) {
            final e = items[i]; final saved = _saved.contains(e.title);
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(17)),
              child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [Expanded(child: Text(e.category, style: TextStyle(color: _knowledgeBrand, fontWeight: FontWeight.bold))), Text(e.tag, style: Theme.of(context).textTheme.labelSmall)]),
                const SizedBox(height: 6), Text(e.title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
                const SizedBox(height: 6), Text(e.body, style: const TextStyle(height: 1.55)),
                Align(alignment: Alignment.centerLeft, child: Wrap(spacing: 2, children: [
                  IconButton(tooltip: saved ? 'إزالة من المحفوظات' : 'حفظ', onPressed: () => _toggleSaved(e), icon: Icon(saved ? Icons.bookmark : Icons.bookmark_border, color: saved ? _knowledgeBrand : null)),
                  IconButton(tooltip: 'نسخ', onPressed: () => _copy(e), icon: const Icon(Icons.copy_all_outlined)),
                ])),
              ])),
            );
          });
        })),
      ]),
    ),
  );
}
