import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const _studioColors = <Color>[
  Color(0xFF241B52), Color(0xFF5636A8), Color(0xFF075B68),
  Color(0xFF8A315D), Color(0xFF34445E),
];

/// A lightweight, fully local creative studio: no extra backend permissions required.
class FutureStudioPage extends StatefulWidget {
  const FutureStudioPage({super.key});
  @override
  State<FutureStudioPage> createState() => _FutureStudioPageState();
}

class _FutureStudioPageState extends State<FutureStudioPage> {
  final _text = TextEditingController(text: 'أثرُك الجميل يبقى، حتى بعد أن تمضي الأيام ✨');
  final _author = TextEditingController(text: 'ملتقى شباب المستقبل');
  int _color = 0;
  String _kind = 'اقتباس';
  static const _ideas = [
    'اكتب رسالة امتنان لشخص صنع فرقاً في يومك.',
    'شارك هدفاً صغيراً تريد تحقيقه هذا الأسبوع.',
    'ما أجمل ذكرى صنعتها مع أصدقائك؟',
    'اختر كتاباً أو أنمي أو لعبة تنصح بها أعضاء الملتقى.',
    'اكتب كلمة تشجيع لشخص يمر بيوم صعب.',
  ];
  int _idea = DateTime.now().day % _ideas.length;

  @override
  void dispose() {
    _text.dispose();
    _author.dispose();
    super.dispose();
  }

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: '$_kind\n${_text.text.trim()}\n— ${_author.text.trim()}'));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم نسخ البطاقة النصية، تقدر تشاركها وين ما تريد')));
  }

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.rtl,
    child: Scaffold(
      appBar: AppBar(title: const Text('استوديو ملتقى المستقبل'), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF171936), Color(0xFF6554D9), Color(0xFF20A8B8)]),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('اصنع شيئاً يحمل بصمتك ✨', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
              SizedBox(height: 7),
              Text('جهّز اقتباساً أو تهنئة أو رسالة من تصميمك وشاركها مع الأصدقاء.', style: TextStyle(color: Colors.white70, height: 1.5)),
            ]),
          ),
          const SizedBox(height: 18),
          const Text('نوع البطاقة', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Wrap(spacing: 8, children: ['اقتباس', 'تهنئة', 'رسالة صداقة', 'تحفيز'].map((v) => ChoiceChip(
            label: Text(v), selected: _kind == v, onSelected: (_) => setState(() => _kind = v),
          )).toList()),
          const SizedBox(height: 14),
          TextField(
            controller: _text, maxLines: 4, maxLength: 220,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(labelText: 'اكتب محتوى بطاقتك', border: OutlineInputBorder(), alignLabelWithHint: true),
          ),
          TextField(controller: _author, onChanged: (_) => setState(() {}), decoration: const InputDecoration(labelText: 'التوقيع')),
          const SizedBox(height: 16),
          const Text('اختر ألوان التصميم', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 9),
          Wrap(spacing: 12, children: List.generate(_studioColors.length, (i) => InkWell(
            onTap: () => setState(() => _color = i),
            borderRadius: BorderRadius.circular(30),
            child: Container(width: 38, height: 38, decoration: BoxDecoration(
              color: _studioColors[i], shape: BoxShape.circle,
              border: Border.all(color: _color == i ? Colors.amber : Colors.white, width: _color == i ? 3 : 1),
            )),
          ))),
          const SizedBox(height: 16),
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            width: double.infinity, padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 30),
            decoration: BoxDecoration(
              gradient: LinearGradient(begin: Alignment.topRight, end: Alignment.bottomLeft,
                colors: [_studioColors[_color], Color.lerp(_studioColors[_color], Colors.black, .38)!]),
              borderRadius: BorderRadius.circular(24),
              boxShadow: const [BoxShadow(color: Color(0x26000000), blurRadius: 15, offset: Offset(0, 6))],
            ),
            child: Column(children: [
              const Icon(Icons.auto_awesome, color: Color(0xFFFFD166), size: 28),
              const SizedBox(height: 14),
              Text(_kind, style: const TextStyle(color: Color(0xFFFFD166), fontWeight: FontWeight.bold)),
              const SizedBox(height: 14),
              Text(_text.text.isEmpty ? 'ابدأ بكتابة فكرتك...' : _text.text,
                textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 21, height: 1.6, fontWeight: FontWeight.w800)),
              const SizedBox(height: 18),
              Text(_author.text.isEmpty ? 'ملتقى شباب المستقبل' : '— ${_author.text}',
                style: const TextStyle(color: Colors.white70, fontSize: 13)),
            ]),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(onPressed: _copy, icon: const Icon(Icons.copy_rounded), label: const Text('نسخ البطاقة ومشاركتها')),
          const SizedBox(height: 18),
          Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('🎯 فكرة تفاعلية لليوم', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(_ideas[_idea], style: const TextStyle(height: 1.5)),
            Align(alignment: Alignment.centerLeft, child: TextButton.icon(
              onPressed: () => setState(() => _idea = (_idea + 1) % _ideas.length),
              icon: const Icon(Icons.refresh), label: const Text('فكرة ثانية'),
            )),
          ]))),
        ],
      ),
    ),
  );
}
