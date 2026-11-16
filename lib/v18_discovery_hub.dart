import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

const _v18Purple = Color(0xFF8B72FF);

class V18DiscoveryHubPage extends StatefulWidget {
  const V18DiscoveryHubPage({super.key});
  @override State<V18DiscoveryHubPage> createState() => _V18DiscoveryHubPageState();
}

class _V18DiscoveryHubPageState extends State<V18DiscoveryHubPage> {
  final _search = TextEditingController();
  final Set<String> _favorites = {};
  bool _favoritesOnly = false;
  static const _sections = <_V18Section>[
    _V18Section('ديوان الملتقى', 'شعر عراقي وفصيح وخليجي وخواطر وأمثال', Icons.auto_stories_rounded,
      [Color(0xFF8E44AD), Color(0xFF283593)], [
        _V18Entry('شعر عراقي', 'مساحة للشعر الشعبي العراقي والقصائد الوجدانية والنصوص التي يضيفها الأعضاء.'),
        _V18Entry('الشعر الفصيح', 'مختارات أدبية ومعلومات عن العصور الشعرية والمدارس والأساليب.'),
        _V18Entry('الشعر النبطي والخليجي', 'قصائد نبطية وأمثال وحكايات من التراث الخليجي.'),
        _V18Entry('خواطر من كتابتنا', 'اكتب خاطرتك الأصلية وشاركها مع مجتمع الملتقى.'),
        _V18Entry('أمثال عراقية وعربية', 'أمثال شعبية مع شرح معناها وسياق استخدامها.'),
        _V18Entry('قصص قصيرة', 'ركن للقصص القصيرة الأصلية ومراجعات الكتب.'),
      ]),
    _V18Section('ركن الذكر والدعاء', 'أذكار مختصرة وأدعية مأثورة ومراجع موثوقة', Icons.mosque_rounded,
      [Color(0xFF087E8B), Color(0xFF164B55)], [
        _V18Entry('أذكار قصيرة', 'سبحان الله، والحمد لله، ولا إله إلا الله، والله أكبر.'),
        _V18Entry('الاستغفار', 'أستغفر الله وأتوب إليه.'),
        _V18Entry('دعاء جامع', 'ربنا آتنا في الدنيا حسنة وفي الآخرة حسنة وقنا عذاب النار.'),
        _V18Entry('الصلاة على النبي', 'اللهم صلِّ وسلم على نبينا محمد.'),
        _V18Entry('مراجعة النصوص', 'للتوسع في الآيات والأحاديث والأذكار المطوّلة، افتح مصدراً موثوقاً وتحقق من النص والتخريج.'),
      ]),
    _V18Section('أكاديمية الملتقى', 'تعلم التقنية واللغات والمهارات والدراسة', Icons.school_rounded,
      [Color(0xFF1565C0), Color(0xFF4527A0)], [
        _V18Entry('أساسيات البرمجة', 'مفاهيم الخوارزميات والمتغيرات والشروط والحلقات ومشاريع تدريبية.'),
        _V18Entry('الذكاء الاصطناعي', 'مقدمة في النماذج والبيانات والاستخدام المسؤول والتحقق من النتائج.'),
        _V18Entry('اللغة الإنجليزية', 'مفردات يومية وقواعد بسيطة وتمارين قراءة ومحادثة.'),
        _V18Entry('مهارات الدراسة', 'تنظيم الوقت، تدوين الملاحظات، والاستعداد للاختبارات.'),
        _V18Entry('التصميم والإبداع', 'مبادئ الألوان والتكوين وتجربة المستخدم وصناعة المحتوى.'),
      ]),
    _V18Section('مختبر العلوم والفضاء', 'الكون والطبيعة والاختراعات والتجارب الآمنة', Icons.rocket_launch_rounded,
      [Color(0xFF283593), Color(0xFF00838F)], [
        _V18Entry('الفضاء والكواكب', 'تعرف على المجموعة الشمسية والنجوم والمجرات والاستكشاف الفضائي.'),
        _V18Entry('علوم الطبيعة', 'الأحياء والبيئة والطقس والأنظمة الطبيعية.'),
        _V18Entry('اختراعات غيّرت العالم', 'قصص مبسطة عن الكهرباء والاتصالات والطب والحوسبة.'),
        _V18Entry('ألغاز علمية', 'أسئلة تفكير ومعلومات علمية مع تفسير مبسط للإجابة.'),
      ]),
    _V18Section('مطبخ الملتقى', 'وصفات منزلية وثقافة الأكلات العراقية والعربية', Icons.restaurant_rounded,
      [Color(0xFFEF6C00), Color(0xFFAD1457)], [
        _V18Entry('المطبخ العراقي', 'تعرف على أطباق عراقية معروفة ومكوناتها وتاريخها الشعبي.'),
        _V18Entry('حلويات ومخبوزات', 'أفكار حلويات منزلية ومخبوزات مع تنبيهات الحساسية الغذائية.'),
        _V18Entry('وصفات سهلة', 'وصفات بسيطة بخطوات واضحة ومكونات متاحة.'),
        _V18Entry('ثقافة الطعام', 'حكايات الأكلات والمواسم والعادات حول المائدة.'),
      ]),
    _V18Section('دليل العراق والعالم', 'مدن ومعالم وثقافات وجغرافيا', Icons.public_rounded,
      [Color(0xFF2E7D32), Color(0xFF00695C)], [
        _V18Entry('مدن العراق', 'بغداد والبصرة والموصل وأربيل والنجف وكربلاء ومدن العراق الأخرى.'),
        _V18Entry('حضارات بلاد الرافدين', 'السومريون والأكديون والبابليون والآشوريون وآثارهم.'),
        _V18Entry('حول العالم', 'دول وعواصم ومعالم وثقافات وجغرافيا.'),
        _V18Entry('رحلات افتراضية', 'خطط لزيارة المعالم والمتاحف والمواقع الثقافية عبر مصادرها الرسمية.'),
      ]),
    _V18Section('استوديو البودكاست', 'أفكار حلقات ومراجعات وملخصات صوتية', Icons.mic_rounded,
      [Color(0xFF6A1B9A), Color(0xFF283593)], [
        _V18Entry('حكايات من العراق', 'أفكار حلقات عن المدن والتراث والشخصيات التاريخية.'),
        _V18Entry('دقيقة معرفة', 'ملخصات قصيرة لمعلومة علمية أو ثقافية مع ذكر المصدر.'),
        _V18Entry('نادي الكتب', 'مراجعات كتب ونقاشات أدبية من إعداد الأعضاء.'),
        _V18Entry('مساحة الأعضاء', 'اقترح موضوعاً لحلقة أو شارك نصاً صوتياً تملك حق نشره.'),
      ]),
  ];

  @override void initState() { super.initState(); _loadFavorites(); }
  @override void dispose() { _search.dispose(); super.dispose(); }

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() => _favorites.addAll(prefs.getStringList('v18_discovery_favorites') ?? const []));
  }

  Future<void> _toggleFavorite(String key) async {
    setState(() { if (!_favorites.add(key)) _favorites.remove(key); });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('v18_discovery_favorites', _favorites.toList());
  }

  void _openSection(_V18Section section) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => _V18SectionPage(
      section: section, favorites: _favorites, onFavorite: _toggleFavorite)));
  }

  @override Widget build(BuildContext context) {
    final q = _search.text.trim().toLowerCase();
    final sections = _sections.where((s) {
      final matches = ('${s.title} ${s.subtitle} ${s.entries.map((e) => '${e.title} ${e.body}').join(' ')}').toLowerCase().contains(q);
      return matches && (!_favoritesOnly || _favorites.contains(s.title) || s.entries.any((e) => _favorites.contains('${s.title}|${e.title}')));
    }).toList();
    return Directionality(textDirection: TextDirection.rtl, child: Scaffold(
      appBar: AppBar(title: const Text('مكتبة V18 الشاملة'), actions: [
        IconButton(tooltip: 'المفضلة', onPressed: () => setState(() => _favoritesOnly = !_favoritesOnly),
          icon: Icon(_favoritesOnly ? Icons.favorite : Icons.favorite_border, color: _favoritesOnly ? Colors.pinkAccent : null)),
      ]),
      body: ListView(padding: const EdgeInsets.all(14), children: [
        Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(begin: Alignment.topRight, end: Alignment.bottomLeft,
            colors: [Color(0xFF5030A8), Color(0xFF171B3C), Color(0xFF087E8B)])),
          child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('مساحة معرفة وإبداع لكل يوم', style: TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.w900)),
            SizedBox(height: 7),
            Text('أدب وذكر وعلوم وتعلم ومطبخ وثقافة وبودكاست، بأقسام مستقلة قابلة للبحث والحفظ.', style: TextStyle(color: Colors.white70, height: 1.6)),
          ])),
        const SizedBox(height: 14),
        TextField(controller: _search, onChanged: (_) => setState(() {}),
          decoration: InputDecoration(hintText: 'ابحث داخل المكتبة...', prefixIcon: const Icon(Icons.search),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)))),
        const SizedBox(height: 14),
        if (sections.isEmpty) const Padding(padding: EdgeInsets.all(30), child: Center(child: Text('ماكو أقسام مطابقة.')))
        else ...sections.map((s) => _V18SectionCard(section: s, favorite: _favorites.contains(s.title), onTap: () => _openSection(s),
          onFavorite: () => _toggleFavorite(s.title))),
        const SizedBox(height: 8),
        const Text('ملاحظة: المحتوى التعريفي داخل هذه الأقسام نقطة بداية قابلة للتوسعة. لا تُعرض النصوص الدينية المطوّلة أو الأحاديث دون توثيق ومراجعة مصدرها.', style: TextStyle(color: Colors.grey, fontSize: 11, height: 1.5)),
      ]),
    ));
  }
}

class _V18SectionCard extends StatelessWidget {
  const _V18SectionCard({required this.section, required this.favorite, required this.onTap, required this.onFavorite});
  final _V18Section section; final bool favorite; final VoidCallback onTap, onFavorite;
  @override Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 12), clipBehavior: Clip.antiAlias,
    child: InkWell(onTap: onTap, child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Container(height: 108, padding: const EdgeInsets.all(16), decoration: BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topRight, end: Alignment.bottomLeft, colors: section.colors)),
        child: Row(children: [
          Container(width: 62, height: 62, decoration: BoxDecoration(color: Colors.white.withValues(alpha: .16), borderRadius: BorderRadius.circular(18)),
            child: Icon(section.icon, size: 34, color: Colors.white)),
          const SizedBox(width: 14),
          Expanded(child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(section.title, style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w900)),
            Text(section.subtitle, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ])),
          IconButton(onPressed: onFavorite, icon: Icon(favorite ? Icons.favorite : Icons.favorite_border, color: Colors.white)),
        ])),
      Padding(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10), child: Row(children: [
        Text('${section.entries.length} أركان', style: const TextStyle(color: _v18Purple, fontWeight: FontWeight.bold)),
        const Spacer(), const Text('افتح المكتبة', style: TextStyle(fontSize: 12)), const Icon(Icons.chevron_left),
      ])),
    ])),
  );
}

class _V18SectionPage extends StatefulWidget {
  const _V18SectionPage({required this.section, required this.favorites, required this.onFavorite});
  final _V18Section section; final Set<String> favorites; final Future<void> Function(String) onFavorite;
  @override State<_V18SectionPage> createState() => _V18SectionPageState();
}
class _V18SectionPageState extends State<_V18SectionPage> {
  @override Widget build(BuildContext context) => Directionality(textDirection: TextDirection.rtl,
    child: Scaffold(appBar: AppBar(title: Text(widget.section.title)),
      body: ListView(padding: const EdgeInsets.all(14), children: [
        Container(padding: const EdgeInsets.all(18), decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20), gradient: LinearGradient(colors: widget.section.colors)),
          child: Text(widget.section.subtitle, style: const TextStyle(color: Colors.white, fontSize: 16, height: 1.5))),
        const SizedBox(height: 12),
        ...widget.section.entries.map((entry) {
          final key = '${widget.section.title}|${entry.title}';
          final saved = widget.favorites.contains(key);
          return Card(child: ListTile(
            contentPadding: const EdgeInsets.all(14),
            leading: const CircleAvatar(child: Icon(Icons.menu_book_rounded)),
            title: Text(entry.title, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Padding(padding: const EdgeInsets.only(top: 6), child: Text(entry.body)),
            trailing: IconButton(onPressed: () async { await widget.onFavorite(key); if (mounted) setState(() {}); },
              icon: Icon(saved ? Icons.favorite : Icons.favorite_border, color: saved ? Colors.pinkAccent : null)),
          ));
        }),
        if (widget.section.title == 'ركن الذكر والدعاء')
          OutlinedButton.icon(onPressed: () => launchUrl(Uri.https('quran.com'), mode: LaunchMode.externalApplication),
            icon: const Icon(Icons.open_in_new), label: const Text('فتح القرآن الكريم على مصدره')),
      ]),
    ));
}

class _V18Section {
  const _V18Section(this.title, this.subtitle, this.icon, this.colors, this.entries);
  final String title, subtitle; final IconData icon; final List<Color> colors; final List<_V18Entry> entries;
}
class _V18Entry {
  const _V18Entry(this.title, this.body);
  final String title, body;
}
