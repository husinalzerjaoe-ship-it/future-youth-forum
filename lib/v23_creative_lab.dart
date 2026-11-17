import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _labAccent = Color(0xFF8B72FF);

class V23CreativeLabPage extends StatefulWidget {
  const V23CreativeLabPage({super.key});
  @override
  State<V23CreativeLabPage> createState() => _V23CreativeLabPageState();
}

class _V23CreativeLabPageState extends State<V23CreativeLabPage> {
  static const _challenges = <_LabChallenge>[
    _LabChallenge('اكتب نهاية مختلفة', 'كتابة', 'اختر حكاية تعرفها، واكتب لها نهاية جديدة من ثلاثة أسطر.'),
    _LabChallenge('مدينة من المستقبل', 'خيال', 'تخيّل مدينة عراقية بعد خمسين سنة، واكتب ثلاث ميزات تجعل الحياة فيها أفضل.'),
    _LabChallenge('رسالة إلى نفسي', 'كتابة', 'اكتب رسالة قصيرة لنفسك تتضمن شيئاً تعلمته وهدفاً صغيراً تريد تجربته.'),
    _LabChallenge('صمّم شعاراً بالكلمات', 'تصميم', 'ابتكر اسماً وشعاراً نصياً لنادٍ يهتم بالقراءة أو العلوم أو الألعاب.'),
    _LabChallenge('لغز من ابتكارك', 'تفكير', 'اختر شيئاً يومياً واكتب لغزاً لطيفاً عنه مع إجابته.'),
    _LabChallenge('اختراع مفيد', 'خيال', 'اقترح أداة بسيطة تساعد الطلاب على تنظيم وقت الدراسة والراحة.'),
    _LabChallenge('ثلاث زوايا', 'تفكير', 'اختر موضوعاً عاماً واكتب ثلاث وجهات نظر مختلفة حوله باحترام.'),
    _LabChallenge('قصيدة من أربع صور', 'شعر', 'اكتب أربعة أسطر، واجعل في كل سطر صورة من الطبيعة أو المدينة.'),
    _LabChallenge('حكاية بلا أسماء', 'كتابة', 'اكتب مشهداً قصيراً من دون ذكر أسماء أشخاص أو أماكن.'),
    _LabChallenge('معلومة تحققت منها', 'معرفة', 'ابحث عن معلومة علمية من مصدر موثوق، ثم لخّصها بكلماتك مع ذكر المصدر.'),
    _LabChallenge('حل مشكلة صغيرة', 'تفكير', 'اختر مشكلة يومية غير خطرة واقترح لها حلّين عمليين.'),
    _LabChallenge('وصف مكان عراقي', 'أدب', 'صف مكاناً عراقياً تحبه مستخدماً الحواس الخمس.'),
    _LabChallenge('حوار من ست جمل', 'كتابة', 'اكتب حواراً قصيراً بين شخصيتين تختلفان بالرأي ثم تصلان إلى تفاهم.'),
    _LabChallenge('فكرة لنادٍ جديد', 'مجتمع', 'اقترح نادياً داخل الملتقى وحدد نشاطاً أسبوعياً مناسباً له.'),
    _LabChallenge('رتّب فكرة معقدة', 'معرفة', 'اختر موضوعاً تعرفه واشرحه في خمس نقاط سهلة للمبتدئين.'),
    _LabChallenge('عنوان يجذب الانتباه', 'إبداع', 'اكتب خمسة عناوين مختلفة لمقال عن اكتشاف علمي أو كتاب أعجبك.'),
  ];

  String _category = 'الكل';
  final Set<String> _favorites = {};
  bool _loaded = false;
  late _LabChallenge _daily;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final day = now.year * 366 + now.month * 31 + now.day;
    _daily = _challenges[day % _challenges.length];
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _favorites.addAll(prefs.getStringList('v23_creative_lab_favorites') ?? const []);
      _loaded = true;
    });
  }

  Future<void> _toggleFavorite(_LabChallenge item) async {
    setState(() {
      if (!_favorites.add(item.title)) _favorites.remove(item.title);
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('v23_creative_lab_favorites', _favorites.toList());
  }

  Future<void> _copy(_LabChallenge item) async {
    await Clipboard.setData(ClipboardData(text: '${item.title}\n${item.prompt}'));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم نسخ التحدي')));
  }

  @override
  Widget build(BuildContext context) {
    final categories = ['الكل', 'كتابة', 'تفكير', 'خيال', 'شعر', 'تصميم', 'معرفة', 'المفضلة'];
    final visible = _challenges.where((item) {
      if (_category == 'الكل') return true;
      if (_category == 'المفضلة') return _favorites.contains(item.title);
      return item.category == _category;
    }).toList();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('مختبر الإبداع اليومي')),
        body: !_loaded
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(14),
                children: [
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22),
                      gradient: const LinearGradient(
                        begin: Alignment.topRight,
                        end: Alignment.bottomLeft,
                        colors: [Color(0xFF211A48), Color(0xFF6047B8), Color(0xFF087E91)],
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(children: [
                          Icon(Icons.auto_awesome_rounded, color: Color(0xFFFFD98A), size: 27),
                          SizedBox(width: 8),
                          Text('تحدي اليوم', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 19)),
                        ]),
                        const SizedBox(height: 12),
                        Text(_daily.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17)),
                        const SizedBox(height: 6),
                        Text(_daily.prompt, style: const TextStyle(color: Colors.white70, height: 1.6)),
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: OutlinedButton.icon(
                            onPressed: () => _copy(_daily),
                            icon: const Icon(Icons.copy_rounded, color: Colors.white),
                            label: const Text('نسخ التحدي', style: TextStyle(color: Colors.white)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('تحديات متنوعة • ${visible.length} تحدي', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 7,
                    runSpacing: 7,
                    children: categories.map((category) => ChoiceChip(
                      label: Text(category),
                      selected: _category == category,
                      onSelected: (_) => setState(() => _category = category),
                    )).toList(),
                  ),
                  const SizedBox(height: 10),
                  if (visible.isEmpty)
                    const Padding(padding: EdgeInsets.all(28), child: Center(child: Text('ما عندك تحديات محفوظة بعد.')))
                  else
                    ...visible.map((item) => Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(children: [
                            Expanded(child: Text(item.title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15))),
                            IconButton(
                              tooltip: 'حفظ بالمفضلة',
                              onPressed: () => _toggleFavorite(item),
                              icon: Icon(_favorites.contains(item.title) ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                                color: _favorites.contains(item.title) ? _labAccent : null),
                            ),
                            IconButton(tooltip: 'نسخ', onPressed: () => _copy(item), icon: const Icon(Icons.copy_rounded)),
                          ]),
                          Align(
                            alignment: Alignment.centerRight,
                            child: Chip(label: Text(item.category), visualDensity: VisualDensity.compact),
                          ),
                          Text(item.prompt, style: const TextStyle(height: 1.55)),
                        ]),
                      ),
                    )),
                  const SizedBox(height: 8),
                  const Text('التحديات محفوظة على جهازك، وتقدر تنسخ أي فكرة وتكملها باستوديو الإبداع.', style: TextStyle(color: Colors.grey, fontSize: 11)),
                ],
              ),
      ),
    );
  }
}

class _LabChallenge {
  const _LabChallenge(this.title, this.category, this.prompt);
  final String title;
  final String category;
  final String prompt;
}
