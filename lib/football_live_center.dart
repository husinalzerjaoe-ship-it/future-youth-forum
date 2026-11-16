import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'watch_party.dart';

const _green = Color(0xFF16834A);
const _gold = Color(0xFFFFD66B);

class FootballLiveCenterPage extends StatefulWidget {
  const FootballLiveCenterPage({super.key});
  @override
  State<FootballLiveCenterPage> createState() => _FootballLiveCenterPageState();
}

class _FootballLiveCenterPageState extends State<FootballLiveCenterPage> {
  static const leagues = <String, String>{
    'الدوري العراقي': 'irq.1',
    'الدوري الإنجليزي': 'eng.1',
    'الدوري الإسباني': 'esp.1',
    'الدوري الإيطالي': 'ita.1',
    'الدوري الألماني': 'ger.1',
    'الدوري الفرنسي': 'fra.1',
    'دوري أبطال أوروبا': 'uefa.champions',
    'الدوري الأوروبي': 'uefa.europa',
    'الدوري السعودي': 'ksa.1',
  };
  static const channels = <_Channel>[
    _Channel('beIN SPORTS', 'https://www.beinsports.com/ar-mena', 'الموقع الرسمي • تحقق من اشتراك وحقوق العراق'),
    _Channel('SSC الرياضية', 'https://ssc.tv', 'الموقع الرسمي للقنوات الرياضية'),
    _Channel('أبوظبي الرياضية', 'https://www.adsports.ae', 'الموقع الرسمي للقناة'),
    _Channel('دبي الرياضية', 'https://www.dubaisports.ae', 'الموقع الرسمي للقناة'),
    _Channel('العراقية الرياضية', 'https://imn.iq', 'شبكة الإعلام العراقي'),
  ];
  static const familyChannels = <_Channel>[
    _Channel('MBC3', 'https://shahid.mbc.net/ar/livestream/mbc3/livechannel-816771', 'بث MBC3 الرسمي عبر شاهد • قد يتطلب اشتراكاً'),
    _Channel('MBC شاهد • البث المباشر', 'https://shahid.mbc.net/ar/livestream', 'قنوات MBC والقنوات المتاحة رسمياً على شاهد'),
    _Channel('Spacetoon • سبيستون', 'https://www.youtube.com/@Spacetoonyoutube', 'القناة الرسمية على YouTube • حلقات ومقاطع عربية'),
  ];

  String league = 'eng.1';
  String leagueName = 'الدوري الإنجليزي';
  String query = '';
  final search = TextEditingController();
  late Future<List<Map<String, dynamic>>> future;

  @override
  void initState() {
    super.initState();
    future = load(league);
  }

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  Future<List<Map<String, dynamic>>> load(String code) async {
    final uri = Uri.https('site.api.espn.com', '/apis/site/v2/sports/soccer/' + code + '/scoreboard');
    final response = await http.get(uri, headers: {'User-Agent': 'FutureYouthForum/1.0', 'Accept': 'application/json'}).timeout(const Duration(seconds: 16));
    if (response.statusCode != 200) throw Exception('تعذر جلب النتائج');
    final data = jsonDecode(response.body);
    final events = data is Map ? data['events'] : null;
    if (events is! List) return const [];
    return events.whereType<Map<String, dynamic>>().toList();
  }

  Future<void> refresh() async {
    final next = load(league);
    setState(() => future = next);
    await next;
  }

  List<Map<String, dynamic>> teams(Map<String, dynamic> event) {
    final comps = event['competitions'];
    if (comps is! List || comps.isEmpty || comps.first is! Map) return [];
    final raw = comps.first['competitors'];
    if (raw is! List) return [];
    return raw.whereType<Map<String, dynamic>>().toList();
  }

  Map<String, dynamic> side(List<Map<String, dynamic>> list, String which, int fallback) {
    for (final team in list) {
      if (team['homeAway'] == which) return team;
    }
    return list.length > fallback ? list[fallback] : <String, dynamic>{};
  }

  String teamName(Map<String, dynamic> team) {
    final t = team['team'];
    if (t is Map) return (t['displayName'] ?? t['name'] ?? 'فريق').toString();
    return 'فريق';
  }

  String logo(Map<String, dynamic> team) {
    final t = team['team'];
    return t is Map ? (t['logo'] ?? '').toString() : '';
  }

  String score(Map<String, dynamic> team) => (team['score'] ?? '—').toString();

  String status(Map<String, dynamic> event) {
    final s = event['status'];
    if (s is Map && s['type'] is Map) {
      final t = s['type'] as Map;
      return (t['shortDetail'] ?? t['description'] ?? 'لم تبدأ').toString();
    }
    return 'لم تبدأ';
  }

  bool live(Map<String, dynamic> event) {
    final s = event['status'];
    return s is Map && s['type'] is Map && s['type']['state'] == 'in';
  }

  String dateLabel(dynamic value) {
    final d = DateTime.tryParse((value ?? '').toString())?.toLocal();
    if (d == null) return 'موعد غير محدد';
    return d.day.toString().padLeft(2, '0') + '/' + d.month.toString().padLeft(2, '0') +
      ' • ' + d.hour.toString().padLeft(2, '0') + ':' + d.minute.toString().padLeft(2, '0');
  }

  String venue(Map<String, dynamic> event) {
    final comps = event['competitions'];
    if (comps is List && comps.isNotEmpty && comps.first is Map) {
      final v = comps.first['venue'];
      if (v is Map) return (v['fullName'] ?? '').toString();
    }
    return '';
  }

  Future<void> openUrl(String value) async {
    final uri = Uri.tryParse(value);
    if (uri == null) return;
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تعذر فتح الرابط.')));
    }
  }

  Future<void> searchWeb(String value) async {
    await openUrl(Uri.https('www.google.com', '/search', {'q': value}).toString());
  }

  Widget teamBadge(Map<String, dynamic> team, {bool compact = false}) {
    final image = logo(team);
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: compact ? 34 : 62,
        height: compact ? 34 : 62,
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(14)),
        child: image.startsWith('http')
          ? Image.network(image, fit: BoxFit.contain, errorBuilder: (_, __, ___) => const Icon(Icons.shield))
          : const Icon(Icons.shield),
      ),
      const SizedBox(height: 5),
      SizedBox(width: compact ? 100 : 115, child: Text(teamName(team), maxLines: 2, overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: compact ? 11 : 13))),
    ]);
  }

  Widget matchCard(Map<String, dynamic> event) {
    final list = teams(event);
    final home = side(list, 'home', 0);
    final away = side(list, 'away', 1);
    final isLive = live(event);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => showMatch(event),
        child: Padding(
          padding: const EdgeInsets.all(13),
          child: Column(children: [
            Row(children: [
              Expanded(child: Text(leagueName, style: const TextStyle(color: Colors.grey, fontSize: 11))),
              if (isLive) const Text('● مباشر الآن', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 11))
              else Text(dateLabel(event['date']), style: const TextStyle(color: Colors.grey, fontSize: 11)),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: teamBadge(home, compact: true)),
              Column(children: [
                Text(score(home) + ' - ' + score(away), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
                Text(status(event), style: const TextStyle(color: _green, fontSize: 10, fontWeight: FontWeight.bold)),
              ]),
              Expanded(child: teamBadge(away, compact: true)),
            ]),
            const SizedBox(height: 9),
            const Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              Text('التفاصيل والقنوات والمعلّق', style: TextStyle(color: _green, fontSize: 11, fontWeight: FontWeight.bold)),
              Icon(Icons.chevron_left, color: _green, size: 17),
            ]),
          ]),
        ),
      ),
    );
  }

  Widget channelCard(_Channel channel) => Card(
    child: ListTile(
      leading: const CircleAvatar(backgroundColor: Color(0xFFE9F5ED), child: Icon(Icons.live_tv, color: _green)),
      title: Text(channel.name, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(channel.description),
      trailing: const Icon(Icons.open_in_new, size: 18),
      onTap: () => openUrl(channel.url),
    ),
  );

  void showChannels() {
    showModalBottomSheet<void>(
      context: context, showDragHandle: true,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: SafeArea(child: ListView(shrinkWrap: true, padding: const EdgeInsets.all(16), children: [
          const Text('دليل القنوات الرياضية الرسمية', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
          const SizedBox(height: 7),
          const Text('افتح موقع القناة وتحقق من جدول البث وحقوق العراق. هذه روابط رسمية وليست تأكيداً أن كل مباراة منقولة أو مجانية.',
            style: TextStyle(color: Colors.grey, fontSize: 12, height: 1.5)),
          const SizedBox(height: 10),
          const Text('قنوات ترفيهية وعائلية', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
          ...familyChannels.map(channelCard),
          const SizedBox(height: 8),
          ...channels.map(channelCard),
        ])),
      ),
    );
  }

  void quickPlayer() {
    showModalBottomSheet<void>(
      context: context, isScrollControlled: true, showDragHandle: true,
      builder: (ctx) {
        final controller = TextEditingController();
        return Directionality(
          textDirection: TextDirection.rtl,
          child: SafeArea(child: Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, MediaQuery.of(ctx).viewInsets.bottom + 18),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              const Text('المشغل السريع', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900)),
              const SizedBox(height: 7),
              const Text('ألصق رابط YouTube أو رابط بث مباشر تملكه أو لديك إذن باستخدامه. مواقع القنوات العادية تفتح من موقعها الرسمي.',
                style: TextStyle(color: Colors.grey, fontSize: 12, height: 1.5)),
              const SizedBox(height: 12),
              TextField(controller: controller, keyboardType: TextInputType.url,
                decoration: const InputDecoration(labelText: 'رابط البث أو الفيديو', hintText: 'https://', border: OutlineInputBorder(), prefixIcon: Icon(Icons.link))),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: () {
                  final value = controller.text.trim();
                  final uri = Uri.tryParse(value);
                  if (uri == null || !uri.hasScheme || !['http', 'https'].contains(uri.scheme)) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('أدخل رابطاً صحيحاً يبدأ بـ https://')));
                    return;
                  }
                  Navigator.pop(ctx);
                  Navigator.push(context, MaterialPageRoute(builder: (_) =>
                    WatchPartyLobbyPage(initialUrl: value, initialName: 'مشغل الكرة السريع')));
                },
                icon: const Icon(Icons.play_arrow), label: const Text('فتح المشغل'),
              ),
            ]),
          )),
        );
      },
    );
  }

  void showMatch(Map<String, dynamic> event) {
    final list = teams(event);
    final home = side(list, 'home', 0);
    final away = side(list, 'away', 1);
    final name = (event['name'] ?? 'مباراة كرة قدم').toString();
    showModalBottomSheet<void>(
      context: context, isScrollControlled: true, showDragHandle: true,
      builder: (sheet) => Directionality(
        textDirection: TextDirection.rtl,
        child: SafeArea(child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 20),
          child: SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(children: [
              const Icon(Icons.sports_soccer, color: _green),
              const SizedBox(width: 7),
              Expanded(child: Text(leagueName, style: const TextStyle(fontWeight: FontWeight.bold))),
              if (live(event)) const Chip(label: Text('مباشر')),
            ]),
            const SizedBox(height: 14),
            Row(children: [
              Expanded(child: teamBadge(home)),
              Column(children: [
                Text(score(home) + ' - ' + score(away), style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w900)),
                Text(status(event), style: const TextStyle(color: _green, fontWeight: FontWeight.bold)),
              ]),
              Expanded(child: teamBadge(away)),
            ]),
            const SizedBox(height: 16),
            detail(Icons.event, 'الموعد', dateLabel(event['date'])),
            if (venue(event).isNotEmpty) detail(Icons.stadium, 'الملعب', venue(event)),
            detail(Icons.record_voice_over, 'المعلّق', 'غير معلن في مصدر النتائج؛ لا نعرض اسماً غير مؤكد'),
            const SizedBox(height: 10),
            const Text('القنوات الناقلة', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17)),
            const Text('تختلف الحقوق حسب البطولة وبلد المشاهدة. افتح القناة الرسمية وتحقق من جدولها قبل المباراة.',
              style: TextStyle(color: Colors.grey, fontSize: 12, height: 1.5)),
            const SizedBox(height: 8),
            ...channels.map(channelCard),
            OutlinedButton.icon(
              onPressed: () => searchWeb('اسم معلق مباراة ' + name + ' اليوم'),
              icon: const Icon(Icons.record_voice_over), label: const Text('ابحث عن اسم المعلّق'),
            ),
            OutlinedButton.icon(
              onPressed: () => searchWeb('القنوات الناقلة مباراة ' + name + ' العراق اليوم'),
              icon: const Icon(Icons.search), label: const Text('تحقق من القناة الناقلة'),
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: () {
                Navigator.pop(sheet);
                Navigator.push(context, MaterialPageRoute(builder: (_) =>
                  WatchPartyLobbyPage(initialName: 'مشاهدة جماعية: ' + name)));
              },
              icon: const Icon(Icons.groups), label: const Text('غرفة مشاهدة متزامنة مع الأصدقاء'),
            ),
          ])),
        )),
      ),
    );
  }

  Widget detail(IconData icon, String title, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, size: 18, color: _green), const SizedBox(width: 8),
      Text(title + ': ', style: const TextStyle(fontWeight: FontWeight.bold)),
      Expanded(child: Text(value, style: const TextStyle(height: 1.4))),
    ]),
  );

  Widget heroButton(IconData icon, String text, VoidCallback action) => FilledButton.tonalIcon(
    style: FilledButton.styleFrom(backgroundColor: Colors.white.withValues(alpha: .13), foregroundColor: Colors.white),
    onPressed: action, icon: Icon(icon, size: 18), label: Text(text),
  );

  Widget hero() => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(23),
      gradient: const LinearGradient(colors: [Color(0xFF102B24), Color(0xFF176B4A), Color(0xFF171936)], begin: Alignment.topRight, end: Alignment.bottomLeft),
      boxShadow: const [BoxShadow(color: Color(0x3316834A), blurRadius: 18, offset: Offset(0, 7))],
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const Icon(Icons.sports_soccer, color: _gold, size: 32), const SizedBox(width: 9),
        const Expanded(child: Text('مركز الكرة المباشر', style: TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.w900))),
        const Text('LIVE', style: TextStyle(color: _gold, fontWeight: FontWeight.w900)),
      ]),
      const SizedBox(height: 8),
      const Text('مباريات ونتائج وتفاصيل المواجهات ودليل القنوات ومشاهدة الأصدقاء',
        style: TextStyle(color: Colors.white70, height: 1.5)),
      const SizedBox(height: 13),
      Wrap(spacing: 7, runSpacing: 7, children: [
        heroButton(Icons.live_tv, 'القنوات', showChannels),
        heroButton(Icons.play_circle_fill, 'مشغل سريع', quickPlayer),
        heroButton(Icons.groups, 'مشاهدة جماعية', () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => const WatchPartyLobbyPage()))),
      ]),
    ]),
  );

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.rtl,
    child: Scaffold(
      appBar: AppBar(title: const Text('كرة القدم والمشاهدة'), actions: [
        IconButton(onPressed: refresh, icon: const Icon(Icons.refresh), tooltip: 'تحديث'),
      ]),
      body: RefreshIndicator(
        onRefresh: refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 26),
          children: [
            hero(),
            const SizedBox(height: 18),
            const Text('المباريات والنتائج', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900)),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: league, isExpanded: true,
              decoration: const InputDecoration(labelText: 'اختر الدوري أو البطولة', border: OutlineInputBorder(), prefixIcon: Icon(Icons.emoji_events)),
              items: leagues.entries.map((e) => DropdownMenuItem(value: e.value, child: Text(e.key))).toList(),
              onChanged: (value) {
                if (value == null) return;
                setState(() {
                  league = value;
                  leagueName = leagues.entries.firstWhere((e) => e.value == value).key;
                  future = load(value);
                });
              },
            ),
            const SizedBox(height: 9),
            TextField(
              controller: search,
              onChanged: (value) => setState(() => query = value.trim().toLowerCase()),
              decoration: InputDecoration(
                hintText: 'ابحث عن فريق...', prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                suffixIcon: query.isEmpty ? null : IconButton(onPressed: () {
                  search.clear(); setState(() => query = '');
                }, icon: const Icon(Icons.close)),
              ),
            ),
            const SizedBox(height: 10),
            FutureBuilder<List<Map<String, dynamic>>>(
              future: future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                  return const Padding(padding: EdgeInsets.all(35), child: Center(child: CircularProgressIndicator()));
                }
                if (snapshot.hasError) return Card(child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(children: [
                    const Icon(Icons.cloud_off, size: 38, color: Colors.grey),
                    const SizedBox(height: 8),
                    const Text('تعذر جلب المباريات حالياً. جرّب التحديث أو بطولة ثانية.', textAlign: TextAlign.center),
                    TextButton.icon(onPressed: refresh, icon: const Icon(Icons.refresh), label: const Text('إعادة المحاولة')),
                  ]),
                ));
                final all = snapshot.data ?? const <Map<String, dynamic>>[];
                final filtered = all.where((event) {
                  if (query.isEmpty) return true;
                  final names = teams(event).map(teamName).join(' ').toLowerCase();
                  return names.contains(query) || (event['name'] ?? '').toString().toLowerCase().contains(query);
                }).toList();
                if (filtered.isEmpty) return Card(child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Text(all.isEmpty ? 'لا توجد مباريات معروضة حالياً لهذه البطولة.' : 'ما لقينا فريق بهذا الاسم.', textAlign: TextAlign.center),
                ));
                return Column(children: filtered.map(matchCard).toList());
              },
            ),
            const SizedBox(height: 17),
            const Text('القنوات الرياضية', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900)),
            const SizedBox(height: 5),
            const Text('روابط رسمية للتحقق من البث والحقوق المتاحة في العراق.', style: TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 8),
            ...channels.map(channelCard),
            const SizedBox(height: 14),
            const Text('قنوات الأطفال والترفيه', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900)),
            const SizedBox(height: 5),
            const Text('روابط رسمية للقنوات والمحتوى العربي. بعض البثوث تحتاج حساباً أو اشتراكاً حسب بلدك.', style: TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 8),
            ...familyChannels.map(channelCard),
            Card(child: ListTile(
              leading: const CircleAvatar(child: Icon(Icons.groups)),
              title: const Text('غرفة مشاهدة متزامنة'),
              subtitle: const Text('شغّل رابطاً مسموحاً وشارك أصدقاءك بالمزامنة والدردشة'),
              trailing: const Icon(Icons.chevron_left),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WatchPartyLobbyPage())),
            )),
          ],
        ),
      ),
    ),
  );
}

class _Channel {
  const _Channel(this.name, this.url, this.description);
  final String name;
  final String url;
  final String description;
}
