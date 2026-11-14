import 'package:flutter/material.dart';

const _violet = Color(0xFF6554D9);
const _ink = Color(0xFF171936);

class ZodiacAgePage extends StatefulWidget {
  const ZodiacAgePage({super.key});

  @override
  State<ZodiacAgePage> createState() => _ZodiacAgePageState();
}

class _ZodiacAgePageState extends State<ZodiacAgePage> {
  DateTime? _birthDate;

  DateTime _addMonthsClamped(DateTime date, int months) {
    final total = date.year * 12 + date.month - 1 + months;
    final year = total ~/ 12;
    final month = total % 12 + 1;
    final lastDay = DateTime(year, month + 1, 0).day;
    return DateTime(year, month, date.day > lastDay ? lastDay : date.day);
  }

  ({int years, int months, int days}) _age(DateTime birth, DateTime today) {
    var cursor = DateTime(birth.year, birth.month, birth.day);
    var years = 0;
    while (true) {
      final next = DateTime(cursor.year + 1, cursor.month,
          cursor.day > DateTime(cursor.year + 1, cursor.month + 1, 0).day
              ? DateTime(cursor.year + 1, cursor.month + 1, 0).day
              : cursor.day);
      if (next.isAfter(today)) break;
      cursor = next;
      years++;
    }
    var months = 0;
    while (true) {
      final next = _addMonthsClamped(cursor, 1);
      if (next.isAfter(today)) break;
      cursor = next;
      months++;
    }
    return (years: years, months: months, days: today.difference(cursor).inDays);
  }

  _Zodiac? _sign(DateTime date) {
    final value = date.month * 100 + date.day;
    for (final sign in _zodiacs) {
      if (sign.start <= sign.end) {
        if (value >= sign.start && value <= sign.end) return sign;
      } else if (value >= sign.start || value <= sign.end) {
        return sign;
      }
    }
    return null;
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime(2000, 1, 1),
      firstDate: DateTime(1900),
      lastDate: now,
      helpText: 'اختَر تاريخ ميلادك',
      cancelText: 'إلغاء',
      confirmText: 'تأكيد',
    );
    if (selected != null) setState(() => _birthDate = selected);
  }

  @override
  Widget build(BuildContext context) {
    final sign = _birthDate == null ? null : _sign(_birthDate!);
    final age = _birthDate == null ? null : _age(_birthDate!, DateTime.now());
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('الأبراج وحاسبة العمر')),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [_ink, _violet, Color(0xFF8C65D9)],
                ),
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('اعرف عمرك وبرجك ✨',
                      style: TextStyle(color: Colors.white, fontSize: 22,
                          fontWeight: FontWeight.bold)),
                  SizedBox(height: 7),
                  Text('أداة ترفيهية ومعلومات عامة، وليست تنبؤاً بالمستقبل.',
                      style: TextStyle(color: Colors.white70, height: 1.5)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('حاسبة العمر',
                        style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(_birthDate == null
                        ? 'اختَر تاريخ ميلادك لحساب عمرك بدقة.'
                        : 'تاريخ الميلاد: ${_birthDate!.year}/${_birthDate!.month}/${_birthDate!.day}'),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: _pickDate,
                      icon: const Icon(Icons.calendar_month),
                      label: const Text('اختيار تاريخ الميلاد'),
                    ),
                    if (age != null) ...[
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          _AgePart(value: age.years, label: 'سنة'),
                          _AgePart(value: age.months, label: 'شهر'),
                          _AgePart(value: age.days, label: 'يوم'),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (sign != null) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text('برجك حسب تاريخ الميلاد',
                          style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Text(sign.symbol, style: const TextStyle(fontSize: 42)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(sign.name, style: const TextStyle(
                                    fontSize: 22, fontWeight: FontWeight.bold,
                                    color: _violet)),
                                Text(sign.dates, style: const TextStyle(color: Colors.grey)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(sign.description, style: const TextStyle(height: 1.7)),
                      const Divider(height: 24),
                      const Text('رسالة اليوم',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                      const SizedBox(height: 6),
                      Text(sign.daily[DateTime.now().day % sign.daily.length],
                          style: const TextStyle(height: 1.7)),
                      const SizedBox(height: 8),
                      const Text('هذه رسالة تحفيزية عامة للتسلية والتأمل، وليست توقعاً أو حقيقة علمية.',
                          style: TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('توافق الأبراج (للتسلية فقط)',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text(sign.compatibility, style: const TextStyle(height: 1.7)),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            Card(
              child: ExpansionTile(
                leading: const Icon(Icons.mosque, color: _violet),
                title: const Text('دليل صلاة الاستخارة'),
                subtitle: const Text('الدعاء والخطوات باختصار'),
                childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                children: const [
                  Text(
                    'إذا هممت بأمر مباح وترددت فيه، صلِّ ركعتين من غير الفريضة، ثم ادعُ بدعاء الاستخارة، وامضِ فيما يتيسر لك بعد الاستشارة والتفكير.',
                    style: TextStyle(height: 1.7),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'دعاء الاستخارة: «اللهم إني أستخيرك بعلمك، وأستقدرك بقدرتك، وأسألك من فضلك العظيم، فإنك تقدر ولا أقدر، وتعلم ولا أعلم، وأنت علام الغيوب. اللهم إن كنت تعلم أن هذا الأمر خير لي في ديني ومعاشي وعاقبة أمري، فاقدره لي ويسره لي ثم بارك لي فيه، وإن كنت تعلم أن هذا الأمر شر لي في ديني ومعاشي وعاقبة أمري، فاصرفه عني واصرفني عنه، واقدر لي الخير حيث كان ثم أرضني به».',
                    style: TextStyle(height: 1.8),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'لا تعتمد على الأبراج أو الأحلام أو نتيجة عشوائية لاتخاذ القرار؛ الاستخارة دعاء وتفويض لله مع الأخذ بالأسباب.',
                    style: TextStyle(color: Colors.grey, fontSize: 12, height: 1.6),
                  ),
                ],
              ),
            ),
            Card(
              child: ExpansionTile(
                title: const Text('دليل الأبراج الاثني عشر'),
                subtitle: const Text('الفترات والأسماء'),
                children: _zodiacs.map((z) => ListTile(
                  leading: Text(z.symbol, style: const TextStyle(fontSize: 28)),
                  title: Text(z.name),
                  subtitle: Text(z.dates),
                )).toList(),
              ),
            ),
            if (_birthDate != null)
              TextButton.icon(
                onPressed: () => setState(() => _birthDate = null),
                icon: const Icon(Icons.refresh),
                label: const Text('مسح تاريخ الميلاد'),
              ),
          ],
        ),
      ),
    );
  }
}

class _AgePart extends StatelessWidget {
  final int value;
  final String label;
  const _AgePart({required this.value, required this.label});

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
      decoration: BoxDecoration(
        color: _violet.withValues(alpha: .09),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text('$value', style: const TextStyle(
              color: _violet, fontWeight: FontWeight.bold, fontSize: 25)),
          Text(label),
        ],
      ),
    ),
  );
}

class _Zodiac {
  final String name, symbol, dates, description, compatibility;
  final int start, end;
  final List<String> daily;
  const _Zodiac(this.name, this.symbol, this.dates, this.start, this.end,
      this.description, this.compatibility, this.daily);
}

const _daily = [
  'خذ خطوة صغيرة اليوم نحو هدف تؤمن به، ولا تستعجل النتائج.',
  'امنح نفسك وقتاً للراحة، فالتوازن يساعدك على الاستمرار.',
  'الكلمة الطيبة قد تصنع فرقاً كبيراً؛ اختر كلماتك بمحبة.',
  'رتّب أولوياتك وابدأ بالأهم، فالتقدم يأتي بالتدرج.',
  'استمع للآخرين، واحتفظ بحقك في التفكير واتخاذ قرارك.',
  'تذكّر إنجازاتك السابقة عندما تشعر بالتعب، أنت قادر على التعلم.',
];

const _zodiacs = <_Zodiac>[
  _Zodiac('الحمل','♈','21 مارس – 19 أبريل',321,419,
    'يوصف الحمل في الثقافة الفلكية الشعبية بالحماس والمبادرة وحب التجربة.',
    'تُذكر عادةً معه الأبراج النارية والهوائية كتوافق ترفيهي، ولا يحدد البرج نجاح العلاقات.',
    _daily),
  _Zodiac('الثور','♉','20 أبريل – 20 مايو',420,520,
    'يرتبط الثور في الأوصاف الشعبية بالصبر والعملية وحب الاستقرار.',
    'تُذكر معه عادةً الأبراج الترابية والمائية في قوائم التوافق الترفيهية.',
    _daily),
  _Zodiac('الجوزاء','♊','21 مايو – 20 يونيو',521,620,
    'يوصف الجوزاء شعبياً بالفضول وسرعة التواصل وتنوع الاهتمامات.',
    'تُذكر معه عادةً الأبراج الهوائية والنارية في التوافق الشعبي.',
    _daily),
  _Zodiac('السرطان','♋','21 يونيو – 22 يوليو',621,722,
    'يرتبط السرطان في الأوصاف الشعبية بالعاطفة والاهتمام بالعائلة.',
    'تُذكر معه عادةً الأبراج المائية والترابية في قوائم التوافق الترفيهية.',
    _daily),
  _Zodiac('الأسد','♌','23 يوليو – 22 أغسطس',723,822,
    'يوصف الأسد شعبياً بالثقة والإبداع وحب التعبير عن النفس.',
    'تُذكر معه عادةً الأبراج النارية والهوائية في التوافق الشعبي.',
    _daily),
  _Zodiac('العذراء','♍','23 أغسطس – 22 سبتمبر',823,922,
    'يرتبط العذراء في الأوصاف الشعبية بالدقة والتنظيم والانتباه للتفاصيل.',
    'تُذكر معه عادةً الأبراج الترابية والمائية في قوائم التوافق الترفيهية.',
    _daily),
  _Zodiac('الميزان','♎','23 سبتمبر – 22 أكتوبر',923,1022,
    'يوصف الميزان شعبياً بحب التوازن والذوق والتفاهم.',
    'تُذكر معه عادةً الأبراج الهوائية والنارية في التوافق الشعبي.',
    _daily),
  _Zodiac('العقرب','♏','23 أكتوبر – 21 نوفمبر',1023,1121,
    'يرتبط العقرب في الأوصاف الشعبية بالتركيز والخصوصية وقوة الإرادة.',
    'تُذكر معه عادةً الأبراج المائية والترابية في قوائم التوافق الترفيهية.',
    _daily),
  _Zodiac('القوس','♐','22 نوفمبر – 21 ديسمبر',1122,1221,
    'يوصف القوس شعبياً بحب الاستكشاف والتعلم والتفاؤل.',
    'تُذكر معه عادةً الأبراج النارية والهوائية في التوافق الشعبي.',
    _daily),
  _Zodiac('الجدي','♑','22 ديسمبر – 19 يناير',1222,119,
    'يرتبط الجدي في الأوصاف الشعبية بالطموح والانضباط وتحمل المسؤولية.',
    'تُذكر معه عادةً الأبراج الترابية والمائية في قوائم التوافق الترفيهية.',
    _daily),
  _Zodiac('الدلو','♒','20 يناير – 18 فبراير',120,218,
    'يوصف الدلو شعبياً بالاستقلالية والأفكار المبتكرة والاهتمام بالمجتمع.',
    'تُذكر معه عادةً الأبراج الهوائية والنارية في التوافق الشعبي.',
    _daily),
  _Zodiac('الحوت','♓','19 فبراير – 20 مارس',219,320,
    'يرتبط الحوت في الأوصاف الشعبية بالخيال والتعاطف والحس الفني.',
    'تُذكر معه عادةً الأبراج المائية والترابية في قوائم التوافق الترفيهية.',
    _daily),
];
