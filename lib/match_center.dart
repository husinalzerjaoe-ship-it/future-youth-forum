import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class MatchCenterPage extends StatefulWidget {
  const MatchCenterPage({super.key});
  @override
  State<MatchCenterPage> createState() => _MatchCenterPageState();
}

class _MatchCenterPageState extends State<MatchCenterPage> {
  Widget _teamCrest(Map<String, dynamic>? team, {double size = 56}) {
    final logos = team?['logos'];
    final firstLogo = logos is List && logos.isNotEmpty ? logos.first : null;
    final url = (team?['logo'] ?? (firstLogo is Map ? firstLogo['href'] : null) ?? '').toString();
    return Container(
      width: size, height: size,
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: url.startsWith('http')
          ? Image.network(url, fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Icon(Icons.shield_rounded, size: 34))
          : const Icon(Icons.shield_rounded, size: 34),
    );
  }
  static const leagues = <String, String>{
    'الدوري الإنجليزي': 'eng.1',
    'الدوري الإسباني': 'esp.1',
    'الدوري الإيطالي': 'ita.1',
    'الدوري الألماني': 'ger.1',
    'الدوري الفرنسي': 'fra.1',
    'دوري أبطال أوروبا': 'uefa.champions',
    'الدوري الأوروبي': 'uefa.europa',
    'الدوري العراقي': 'irq.1',
  };
  String selected = 'eng.1';
  late Future<List<Map<String, dynamic>>> matches;

  @override
  void initState() {
    super.initState();
    matches = loadMatches(selected);
  }

  Future<List<Map<String, dynamic>>> loadMatches(String league) async {
    final uri = Uri.https('site.api.espn.com', '/apis/site/v2/sports/soccer/$league/scoreboard');
    final response = await http.get(uri, headers: {'User-Agent': 'FutureYouthForum/1.0'})
        .timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) throw Exception('HTTP ' + response.statusCode.toString());
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final events = body['events'] as List? ?? const [];
    return events.whereType<Map<String, dynamic>>().toList();
  }

  String eventDate(dynamic raw) {
    final date = DateTime.tryParse(raw?.toString() ?? '')?.toLocal();
    if (date == null) return 'موعد غير محدد';
    return date.day.toString().padLeft(2, '0') + '/' +
        date.month.toString().padLeft(2, '0') + ' • ' +
        date.hour.toString().padLeft(2, '0') + ':' +
        date.minute.toString().padLeft(2, '0');
  }

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.rtl,
    child: Scaffold(
      appBar: AppBar(title: const Text('مركز المباريات والنتائج')),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
          child: DropdownButtonFormField<String>(
            value: selected,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'اختر البطولة', border: OutlineInputBorder()),
            items: leagues.entries.map((e) => DropdownMenuItem(value: e.value, child: Text(e.key))).toList(),
            onChanged: (value) {
              if (value == null) return;
              setState(() { selected = value; matches = loadMatches(value); });
            },
          ),
        ),
        Expanded(
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: matches,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
              if (snapshot.hasError) return Center(child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.cloud_off, size: 44, color: Colors.grey),
                  const SizedBox(height: 10),
                  const Text('تعذر جلب بيانات هذه البطولة حالياً. قد لا تكون متاحة لدى مزوّد النتائج.'),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(onPressed: () => setState(() => matches = loadMatches(selected)), icon: const Icon(Icons.refresh), label: const Text('إعادة المحاولة')),
                ]),
              ));
              final events = snapshot.data ?? const [];
              if (events.isEmpty) return const Center(child: Text('لا توجد مباريات ضمن نافذة البيانات الحالية.'));
              return RefreshIndicator(
                onRefresh: () async => setState(() => matches = loadMatches(selected)),
                child: ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(12),
                  itemCount: events.length,
                  itemBuilder: (context, index) {
                    final event = events[index];
                    final competition = (event['competitions'] as List?)?.firstOrNull as Map<String, dynamic>?;
                    final competitors = competition?['competitors'] as List? ?? const [];
                    Map<String, dynamic>? home, away;
                    for (final raw in competitors) {
                      if (raw is! Map<String, dynamic>) continue;
                      if (raw['homeAway'] == 'home') home = raw;
                      if (raw['homeAway'] == 'away') away = raw;
                    }
                    final status = (competition?['status'] as Map?)?['type'] as Map?;
                    final statusText = status?['shortDetail']?.toString() ?? status?['detail']?.toString() ?? 'المباراة';
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(children: [
                          Row(children: [
                            Expanded(child: Text(event['name']?.toString() ?? 'مباراة', style: const TextStyle(fontWeight: FontWeight.bold))),
                            Text(statusText, style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.primary)),
                          ]),
                          const SizedBox(height: 14),
                          Row(children: [
                            Expanded(child: Column(children: [
                              _teamCrest(home?['team'] as Map<String, dynamic>?, size: 58),
                              const SizedBox(height: 7),
                              Text(home?['team']?['displayName']?.toString() ?? 'الفريق الأول', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w700)),
                            ])),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: Text(
                                (home?['score']?.toString() ?? '-') + '  -  ' + (away?['score']?.toString() ?? '-'),
                                style: const TextStyle(fontSize: 23, fontWeight: FontWeight.bold),
                              ),
                            ),
                            Expanded(child: Column(children: [
                              _teamCrest(away?['team'] as Map<String, dynamic>?, size: 58),
                              const SizedBox(height: 7),
                              Text(away?['team']?['displayName']?.toString() ?? 'الفريق الثاني', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w700)),
                            ])),
                          ]),
                          const SizedBox(height: 10),
                          Text(eventDate(event['date']), style: const TextStyle(color: Colors.grey, fontSize: 12)),
                        ]),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(12, 0, 12, 8),
          child: Text('النتائج والمواعيد من مزوّد بيانات خارجي، وقد يختلف التوفر حسب البطولة والمنطقة.', textAlign: TextAlign.center, style: TextStyle(fontSize: 10, color: Colors.grey)),
        ),
      ]),
    ),
  );
}
