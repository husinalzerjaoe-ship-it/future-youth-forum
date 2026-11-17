import 'dart:math';
import 'package:flutter/material.dart';
import 'friends_quiz.dart';

/// V40: a curated 100-card party deck. Local pass-and-play cards are clearly
/// separated from the existing Firebase-backed online quiz room.
class V40PartyDeckPage extends StatefulWidget {
  const V40PartyDeckPage({super.key});
  @override State<V40PartyDeckPage> createState() => _V40PartyDeckPageState();
}

class _V40PartyDeckPageState extends State<V40PartyDeckPage> {
  static const Map<String, List<String>> _decks = {
    'معلومات عامة': [
      'اذكر ثلاث عواصم عربية خلال 15 ثانية',
      'ما أكبر محيط على الأرض؟',
      'اذكر كواكب المجموعة الشمسية بالترتيب',
      'ما اسم العملة الرسمية للعراق؟',
      'اذكر ثلاثة اختراعات غيّرت العالم',
      'ما الحيوان المعروف بسفينة الصحراء؟',
      'كم ضلعاً للشكل السداسي؟',
      'اذكر ثلاث لغات تُكتب من اليمين إلى اليسار',
      'ما اسم المجرة التي نعيش فيها؟',
      'اذكر ثلاثة مصادر للطاقة المتجددة',
    ],
    'ألغاز وذكاء': [
      'شيء له مفاتيح ولا يفتح الأقفال، ما هو؟',
      'ما العدد التالي: 3، 6، 12، 24؟',
      'شيء كلما أخذت منه كبر، ما هو؟',
      'لديك ثلاثة صناديق وكل ملصقاتها خاطئة؛ كيف تبدأ حل اللغز؟',
      'ما الذي يكتب ولا يقرأ؟',
      'إذا تجاوزت صاحب المركز الثاني في سباق، فما مركزك؟',
      'ما الشيء الذي يسمع بلا أذن ويتكلم بلا لسان؟',
      'كم شهراً في السنة يحتوي على 28 يوماً؟',
      'ما العدد الذي إذا ضربته بنفسه ثم أضفت إليه نفسه صار 12؟',
      'شيء يملأ الغرفة ولا يشغل حيزاً، ما هو؟',
    ],
    'عراق وحضارات': [
      'اذكر نهري العراق الرئيسيين',
      'ما اسم الكتابة القديمة في بلاد الرافدين؟',
      'اذكر مدينة أثرية عراقية',
      'من الملك المرتبط بمسلة القوانين البابلية؟',
      'ما اسم الزقورة الشهيرة في أور؟',
      'اذكر ثلاثة أكلات عراقية معروفة',
      'ما اسم بوابة بابل الشهيرة؟',
      'اذكر محافظة عراقية تقع شمال البلاد',
      'ما اسم الأهوار المدرجة على قائمة التراث العالمي؟',
      'اذكر شاعراً عراقياً معروفاً',
    ],
    'فضاء وعلوم': [
      'ما أقرب كوكب إلى الشمس؟',
      'ما اسم النجم في مركز مجموعتنا الشمسية؟',
      'اذكر ثلاث حالات للمادة',
      'ما الغاز الذي تمتصه النباتات في البناء الضوئي؟',
      'ما الكوكب المعروف بحلقاته؟',
      'ما وحدة قياس شدة التيار الكهربائي؟',
      'اذكر ثلاثة أعضاء في جسم الإنسان',
      'ما اسم المجرة الأقرب الكبيرة إلى درب التبانة؟',
      'ما الجهاز الذي يقيس درجة الحرارة؟',
      'اذكر ثلاثة حيوانات ثديية تعيش في الماء',
    ],
    'أنمي وشخصيات': [
      'اذكر ثلاثة أعمال أنمي تعرفها',
      'من هو قائد طاقم قبعة القش؟',
      'اذكر شخصية أنمي تستخدم سيفاً',
      'ما اسم القرية التي ينتمي إليها ناروتو؟',
      'اذكر ثلاثة أنواع من قوى الشخصيات الخيالية',
      'ما اسم دفتر الأمنيات في Death Note؟',
      'اذكر شخصية أنمي ذات شعر أزرق',
      'ما اسم أخ تانجيرو؟',
      'اذكر ثلاثة أبطال من أعمال استوديو غيبلي',
      'اخترع اسماً وقدرة لشخصية أنمي جديدة',
    ],
    'ألعاب فيديو': [
      'اذكر ثلاث ألعاب بناء واستكشاف',
      'ما اسم السباك الشهير في ألعاب نينتندو؟',
      'اذكر لعبة تعتمد على حل الألغاز',
      'ما اسم القنفذ الأزرق السريع؟',
      'اذكر ثلاث منصات ألعاب معروفة',
      'ما نوع لعبة الشطرنج؟',
      'اخترع مرحلة جديدة للعبة منصات',
      'اذكر لعبة سباق سيارات',
      'ما الأداة الأساسية لجمع الموارد في Minecraft؟',
      'صف لعبة فيديو من دون ذكر اسمها ودع الآخرين يخمنون',
    ],
    'رياضة وكرة': [
      'كم لاعباً يبدأ به فريق كرة القدم داخل الملعب؟',
      'كم نقطة يمنح الفوز في أغلب الدوريات؟',
      'اذكر ثلاثة مراكز في كرة القدم',
      'ما مدة المباراة الأصلية بالدقائق؟',
      'اذكر ثلاث رياضات جماعية',
      'ما اسم البطولة القارية للمنتخبات الأوروبية؟',
      'اذكر مهارتين أساسيتين لحارس المرمى',
      'ما الرياضة التي تستخدم مضرباً وريشة؟',
      'اذكر ثلاثة أندية من قارات مختلفة',
      'اخترع اسم بطولة رياضية وشعاراً لها',
    ],
    'خيال وإبداع': [
      'اخترع اسماً لكوكب جديد وصف طقسه',
      'صمم مقهى للألعاب بثلاث ميزات',
      'لو فتحت متحفاً، ما أول شيء تعرضه؟',
      'اخترع تطبيقاً يحل مشكلة يومية',
      'صف مدينة مستقبلية في ثلاث جمل',
      'اخترع وجبة لمطعم على القمر',
      'لو صنعت لعبة لوحية، ما هدفها؟',
      'اخترع روبوتاً يساعد الطلاب',
      'اختر عنواناً لفيلم مغامرات من خيالك',
      'ابتكر شعاراً جديداً لملتقى شباب المستقبل',
    ],
    'تمثيل وتخمين': [
      'مثّل مذيعاً يعلن خبراً سعيداً',
      'مثّل روبوتاً يتعلم المشي',
      'مثّل لاعباً يحتفل بفوز فريقه',
      'مثّل طباخاً يشرح وصفة بلا كلام',
      'مثّل رائد فضاء يرى الأرض لأول مرة',
      'مثّل قطة تبحث عن مكان دافئ',
      'مثّل مخرجاً يوجّه مشهداً سينمائياً',
      'مثّل شخصاً يحاول تذكر كلمة نسيها',
      'مثّل حكماً يشرح قراراً في مباراة',
      'مثّل شخصية كرتونية وعلى الآخرين تخمينها',
    ],
    'لو خيروك': [
      'تسافر إلى الفضاء أم إلى أعماق المحيط؟ ولماذا؟',
      'تتقن كل اللغات أم كل الآلات الموسيقية؟',
      'تعيش قرب البحر أم وسط غابة؟',
      'تصمم لعبة أم تخرج فيلماً؟',
      'تزور الماضي أم مدينة مستقبلية؟',
      'تقرأ أفكار الحيوانات أم تتحدث معها؟',
      'تملك مكتبة ضخمة أم استوديو ألعاب؟',
      'تسافر بالقطار حول العالم أم بسفينة بين الجزر؟',
      'تتعلم مهارة جديدة كل أسبوع أم لغة كل سنة؟',
      'تختار مغامرة يومية أم هدوءاً وروتيناً مريحاً؟',
    ],
    'تحديات سريعة': [
      'اذكر خمسة أشياء تبدأ بحرف م خلال عشر ثوانٍ',
      'اذكر أربع مدن عراقية بسرعة',
      'اذكر خمسة ألوان من دون تكرار',
      'اذكر أربعة حيوانات تعيش في الماء',
      'قل جملة مفيدة تحتوي على خمس كلمات تبدأ بحرف ب',
      'اذكر ستة أشياء موجودة في الصف',
      'اذكر أربعة أطعمة عراقية خلال عشر ثوانٍ',
      'اذكر خمس مهن من دون تكرار',
      'اذكر أربعة كواكب غير الأرض',
      'قل ثلاث كلمات متتالية تنتهي بالحرف نفسه',
    ],
  };

  final _random = Random();
  String _category = 'الكل';
  String? _card;
  final Set<String> _used = {};
  int _points = 0;
  int _rounds = 0;

  List<String> get _all => _decks.values.expand((items) => items).toList();
  List<String> get _available {
    final source = _category == 'الكل' ? _all : (_decks[_category] ?? const <String>[]);
    final fresh = source.where((item) => !_used.contains(item)).toList();
    return fresh.isEmpty ? source : fresh;
  }

  void _next() {
    final pool = _available;
    if (pool.isEmpty) return;
    setState(() {
      _card = pool[_random.nextInt(pool.length)];
      _used.add(_card!);
      _rounds++;
    });
  }

  @override Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final categories = ['الكل', ..._decks.keys];
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('عالم الوناسة • مكتبة 100 تحدي')),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                gradient: const LinearGradient(colors: [Color(0xFF171936), Color(0xFF6554D9), Color(0xFF168E9B)]),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('100 بطاقة لعب متنوعة 🎲', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 22)),
                const SizedBox(height: 8),
                Text('$_rounds جولة • $_points نقطة', style: const TextStyle(color: Colors.white70)),
                const SizedBox(height: 8),
                const Text('اختاروا الفئة، اسحبوا بطاقة، وتناوبوا بالإجابة والتمثيل والتخمين.', style: TextStyle(color: Colors.white70, height: 1.5)),
              ]),
            ),
            const SizedBox(height: 14),
            Wrap(spacing: 7, runSpacing: 7, children: categories.map((c) => ChoiceChip(
              label: Text(c), selected: _category == c,
              onSelected: (_) => setState(() { _category = c; _card = null; }),
            )).toList()),
            const SizedBox(height: 16),
            Container(
              constraints: const BoxConstraints(minHeight: 190),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: cs.surfaceContainerHighest, borderRadius: BorderRadius.circular(22), border: Border.all(color: cs.outlineVariant)),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.style_rounded, size: 34),
                const SizedBox(height: 14),
                Text(_card ?? 'اضغط «اسحب بطاقة» حتى تبدأ الجولة', textAlign: TextAlign.center, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800, height: 1.5)),
              ]),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(onPressed: _next, icon: const Icon(Icons.shuffle_rounded), label: const Text('اسحب بطاقة جديدة')),
            OutlinedButton.icon(
              onPressed: _card == null ? null : () => setState(() => _points++),
              icon: const Icon(Icons.stars_rounded), label: const Text('احتساب نقطة للفريق'),
            ),
            TextButton.icon(onPressed: () => setState(() { _used.clear(); _card = null; _points = 0; _rounds = 0; }), icon: const Icon(Icons.restart_alt_rounded), label: const Text('بدء جلسة جديدة')),
            const SizedBox(height: 18),
            Card(child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('تحديات أونلاين برمز غرفة', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17)),
                const SizedBox(height: 5),
                const Text('للمسابقة المتزامنة بين جهازين استخدموا غرفة المسابقة الحالية؛ بطاقات هذه الصفحة تعمل بالتناوب على جهاز واحد.'),
                const SizedBox(height: 10),
                FilledButton.tonalIcon(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FriendsQuizPage())),
                  icon: const Icon(Icons.public_rounded), label: const Text('فتح مسابقة الأصدقاء أونلاين'),
                ),
              ]),
            )),
          ],
        ),
      ),
    );
  }
}
