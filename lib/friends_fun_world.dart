import 'dart:math';
import 'package:flutter/material.dart';

/// Offline-friendly party games. These activities work on one device;
/// online rooms are intentionally not advertised until backed by realtime sync.
class FriendsFunWorldPage extends StatefulWidget {
  const FriendsFunWorldPage({super.key});

  @override
  State<FriendsFunWorldPage> createState() => _FriendsFunWorldPageState();
}

class _FriendsFunWorldPageState extends State<FriendsFunWorldPage> {
  final _random = Random();
  int _score = 0;
  int _round = 0;

  static const _questions = <({String q, List<String> a, int correct})>[
    (q: 'ما هو أكبر كوكب في المجموعة الشمسية؟', a: ['الأرض', 'المشتري', 'المريخ', 'الزهرة'], correct: 1),
    (q: 'كم عدد ألوان قوس قزح التقليدية؟', a: ['5', '6', '7', '8'], correct: 2),
    (q: 'أي حيوان يُعرف بسفينة الصحراء؟', a: ['الحصان', 'الجمل', 'الغزال', 'الفيل'], correct: 1),
    (q: 'ما عاصمة العراق؟', a: ['البصرة', 'أربيل', 'بغداد', 'الموصل'], correct: 2),
    (q: 'أي مادة تمتصها النباتات من الهواء؟', a: ['الأوكسجين فقط', 'ثاني أوكسيد الكربون', 'الهيليوم', 'الهيدروجين'], correct: 1),
    (q: 'كم ضلعاً للمثلث؟', a: ['2', '3', '4', '5'], correct: 1),
    (q: 'ما أسرع حيوان بري؟', a: ['الفهد', 'الأسد', 'الحصان', 'الذئب'], correct: 0),
    (q: 'أي محيط هو الأكبر؟', a: ['الهندي', 'الأطلسي', 'الهادئ', 'المتجمد'], correct: 2),
  ];

  static const _wouldYouRather = [
    'تسافر حول العالم لو تعيش سنة كاملة في مدينة أحلامك؟',
    'تقدر تتكلم كل لغات العالم لو تعزف كل الآلات الموسيقية؟',
    'تعيش مغامرة فضائية لو رحلة إلى أعماق المحيط؟',
    'تكون عبقري اختراعات لو بطل ألعاب إلكترونية؟',
    'تختار يوم مليان مغامرات لو أسبوع كله راحة؟',
    'تقدر توقف الوقت لو ترجع تشوف لحظة تاريخية؟',
  ];

  static const _charades = [
    'مثّل روبوتاً يحاول يتعلم الرقص',
    'مثّل لاعب كرة سجل هدفاً بالدقيقة الأخيرة',
    'مثّل قطة تطلب الطعام',
    'مثّل مذيع أخبار يعلن خبراً عجيباً',
    'مثّل شخصاً يحاول يفتح مظلة بالهواء',
    'مثّل رائد فضاء اكتشف كوكباً جديداً',
    'مثّل طباخاً نسي وصفته',
  ];

  static const _wordStarts = ['مستقبل', 'نجمة', 'كتاب', 'نهر', 'حديقة', 'صداقة', 'مغامرة', 'عراق'];

  void _openQuiz() {
    final q = _questions[_random.nextInt(_questions.length)];
    showDialog<void>(context: context, builder: (dialogContext) => AlertDialog(
      title: const Text('تحدي المعلومات'),
      content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(q.q, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
        const SizedBox(height: 12),
        ...List.generate(q.a.length, (i) => Padding(
          padding: const EdgeInsets.only(bottom: 7),
          child: OutlinedButton(
            onPressed: () {
              final correct = i == q.correct;
              if (correct) setState(() { _score++; _round++; });
              else setState(() => _round++);
              Navigator.pop(dialogContext);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(correct ? 'إجابة صحيحة! +1 نقطة 🎉' : 'مو مشكلة، الجواب: ${q.a[q.correct]}'),
              ));
            },
            child: Text(q.a[i]),
          ),
        )),
      ]),
    ));
  }

  void _showRandom(String title, List<String> prompts, IconData icon) {
    final prompt = prompts[_random.nextInt(prompts.length)];
    showDialog<void>(context: context, builder: (c) => AlertDialog(
      title: Row(children: [Icon(icon, color: Theme.of(context).colorScheme.primary), const SizedBox(width: 8), Expanded(child: Text(title))]),
      content: Text(prompt, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w600)),
      actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text('تم'))],
    ));
  }

  void _wordChallenge() {
    final word = _wordStarts[_random.nextInt(_wordStarts.length)];
    final controller = TextEditingController();
    showDialog<void>(context: context, builder: (c) => AlertDialog(
      title: const Text('سلسلة الكلمات'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        Text('ابدأ بكلمة مرتبطة بـ «$word» ثم خلّوا كل لاعب يقول كلمة جديدة مرتبطة بالكلمة السابقة.'),
        const SizedBox(height: 12),
        TextField(controller: controller, decoration: const InputDecoration(labelText: 'كلمة البداية من المجموعة')),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(c), child: const Text('إلغاء')),
        FilledButton(onPressed: () {
          if (controller.text.trim().isNotEmpty) setState(() { _score++; _round++; });
          Navigator.pop(c);
        }, child: const Text('احتساب الجولة')),
      ],
    )).then((_) => controller.dispose());
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final games = <({String title, String subtitle, IconData icon, Color tint, VoidCallback play})>[
      (title: 'تحدي المعلومات', subtitle: 'أسئلة متنوعة واجمعوا النقاط', icon: Icons.quiz_rounded, tint: Colors.deepPurple, play: _openQuiz),
      (title: 'لو خيروك؟', subtitle: 'اختيارات غريبة تفتح سوالف', icon: Icons.swap_horiz_rounded, tint: Colors.teal, play: () => _showRandom('لو خيروك؟', _wouldYouRather, Icons.swap_horiz_rounded)),
      (title: 'مثّل وخمّن', subtitle: 'تمثيل بدون كلام والبقية تخمّن', icon: Icons.theater_comedy_rounded, tint: Colors.orange, play: () => _showRandom('مثّل وخمّن', _charades, Icons.theater_comedy_rounded)),
      (title: 'سلسلة الكلمات', subtitle: 'خلّوا الكلمات ترتبط ببعضها', icon: Icons.abc_rounded, tint: Colors.blue, play: _wordChallenge),
      (title: 'تحدي الذاكرة', subtitle: 'شوفوا القائمة وحاولوا تتذكروها', icon: Icons.psychology_alt_rounded, tint: Colors.pink, play: () => _memoryGame(context)),
      (title: 'منو يعرف أكثر؟', subtitle: 'اختاروا موضوع وتبادلوا الأسئلة', icon: Icons.groups_2_rounded, tint: Colors.green, play: () => _showRandom('منو يعرف أكثر؟', ['اذكروا 5 أكلات عراقية خلال 20 ثانية', 'اذكروا 4 مدن عراقية غير بغداد', 'اذكروا 5 أفلام أو مسلسلات تعرفوها', 'اذكروا 6 حيوانات تبدأ بحروف مختلفة'], Icons.groups_2_rounded)),
    ];
    return Directionality(textDirection: TextDirection.rtl, child: Scaffold(
      appBar: AppBar(title: const Text('عالم الوناسة والأصدقاء')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: const LinearGradient(colors: [Color(0xFF29215D), Color(0xFF6554D9)]),
          ),
          child: Row(children: [
            const Icon(Icons.celebration_rounded, color: Colors.white, size: 42),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('جمّع أصدقاءك وابدأوا التحدي!', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 5),
              const Text('ألعاب سوالف وضحك ومعلومات', style: TextStyle(color: Colors.white70)),
              const SizedBox(height: 10),
              Text('نقاطك: $_score  •  جولاتك: $_round', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ])),
          ]),
        ),
        const SizedBox(height: 12),
        Card(color: colors.surfaceContainerHighest, child: const Padding(
          padding: EdgeInsets.all(12),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(Icons.info_outline_rounded, size: 20),
            SizedBox(width: 8),
            Expanded(child: Text('الألعاب الحالية تعمل مباشرة على جهاز واحد حتى تلعبون بالتناوب. ربط غرف أونلاين ومزامنة النتائج يحتاج إعداد قاعدة البيانات واختباره قبل إعلانه كميزة متاحة.')),
          ]),
        )),
        const SizedBox(height: 10),
        ...games.map((game) => Card(
          clipBehavior: Clip.antiAlias,
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            leading: CircleAvatar(backgroundColor: game.tint.withValues(alpha: .16), child: Icon(game.icon, color: game.tint)),
            title: Text(game.title, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(game.subtitle),
            trailing: const Icon(Icons.play_circle_fill_rounded, size: 30),
            onTap: game.play,
          ),
        )),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () => setState(() { _score = 0; _round = 0; }),
          icon: const Icon(Icons.restart_alt_rounded),
          label: const Text('تصفير نقاط الجلسة'),
        ),
      ]),
    ));
  }

  void _memoryGame(BuildContext context) {
    const items = ['قمر', 'كتاب', 'تفاحة', 'مفتاح', 'نخلة', 'ساعة'];
    final shuffled = [...items]..shuffle(_random);
    showDialog<void>(context: context, builder: (c) => AlertDialog(
      title: const Text('تحدي الذاكرة'),
      content: Text('احفظوا هذه الكلمات لمدة قصيرة ثم غطّوها وحاولوا تذكّرها:\n\n${shuffled.join(' • ')}'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(c), child: const Text('حفظناها')),
        FilledButton(onPressed: () { setState(() { _score++; _round++; }); Navigator.pop(c); }, child: const Text('احتساب نقطة')),
      ],
    ));
  }
}
