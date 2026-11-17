import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';
import 'news_article_page.dart';

const _footballTabs = <String>['آخر الأخبار', 'الانتقالات', 'العراق', 'أوروبا', 'الدوريات العربية', 'المنتخبات'];
const _feedQueries = <List<String>>[
  ['أخبار كرة القدم -انتقالات -سوق الانتقالات', 'football soccer latest news'],
  ['انتقالات رسمية كرة القدم official confirmed transfer', 'official football transfers completed', 'مفاوضات انتقالات كرة القدم football transfer negotiations', 'شائعات انتقالات كرة القدم football transfer rumours'],
  ['أخبار كرة القدم العراقية', 'المنتخب العراقي كرة القدم'],
  ['الدوري الإنجليزي الدوري الإسباني دوري أبطال أوروبا', 'Premier League La Liga Champions League'],
  ['الدوري السعودي الدوري المصري الدوري العربي', 'Saudi Pro League Egyptian Premier League'],
  ['أخبار المنتخبات الوطنية كرة القدم', 'national football teams international football'],
];

class _FootballNewsItem {
  const _FootballNewsItem({required this.title, required this.url, required this.source, required this.published, required this.category, this.imageUrl = ''});
  final String title, url, source, published, category, imageUrl;
}

class FootballNewsPage extends StatefulWidget {
  const FootballNewsPage({super.key});
  @override
  State<FootballNewsPage> createState() => _FootballNewsPageState();
}

class _FootballNewsPageState extends State<FootballNewsPage> {
  int _selectedTab = 0;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  late Future<List<_FootballNewsItem>> _newsFuture;

  @override
  void initState() {
    super.initState();
    _newsFuture = _loadNews(0);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<List<_FootballNewsItem>> _loadNews(int tab) async {
    final transferLabels = ['بحث: صفقات رسمية', 'بحث: صفقات مكتملة', 'بحث: مفاوضات', 'بحث: شائعات'];
    final results = await Future.wait(List.generate(_feedQueries[tab].length, (index) {
      final label = tab == 1 ? transferLabels[index] : _footballTabs[tab];
      return _readFeed(_feedQueries[tab][index], label);
    }));
    final seen = <String>{};
    final news = <_FootballNewsItem>[];
    for (final batch in results) {
      for (final item in batch) {
        final key = item.title.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();
        if (key.isNotEmpty && seen.add(key)) news.add(item);
      }
    }
    news.sort((a, b) => _publishedMillis(b.published).compareTo(_publishedMillis(a.published)));
    return news.take(45).toList();
  }

  int _publishedMillis(String value) {
    try {
      return HttpDate.parse(value).millisecondsSinceEpoch;
    } catch (_) {
      return 0;
    }
  }

  Future<List<_FootballNewsItem>> _readFeed(String query, String category) async {
    final uri = Uri.https('news.google.com', '/rss/search', {'q': query, 'hl': 'ar', 'gl': 'IQ', 'ceid': 'IQ:ar'});
    try {
      final response = await http.get(uri, headers: {
        'User-Agent': 'FutureYouthForum/1.0 (Android)',
        'Accept': 'application/rss+xml, application/xml, text/xml',
      }).timeout(const Duration(seconds: 18));
      if (response.statusCode != 200) return const [];
      final document = XmlDocument.parse(response.body);
      return document.findAllElements('item').map((item) {
        String value(String tag) {
          final elements = item.findElements(tag);
          return elements.isEmpty ? '' : elements.first.innerText.trim();
        }
        final title = value('title');
        final link = value('link');
        if (title.isEmpty || !link.startsWith('http')) return null;
        final source = value('source');
        var imageUrl = '';
        for (final node in item.descendants.whereType<XmlElement>()) {
          final tag = node.name.qualified.toLowerCase();
          if (tag.endsWith('thumbnail') || tag.endsWith('content') || tag == 'enclosure') {
            final candidate = node.getAttribute('url') ?? node.getAttribute('href') ?? '';
            if (candidate.startsWith('https://')) { imageUrl = candidate; break; }
          }
        }
        return _FootballNewsItem(title: title, url: link, source: source.isEmpty ? 'Google News' : source, published: value('pubDate'), category: category, imageUrl: imageUrl);
      }).whereType<_FootballNewsItem>().toList();
    } on TimeoutException {
      return const [];
    } catch (_) {
      return const [];
    }
  }

  Future<void> _refresh() async {
    final next = _loadNews(_selectedTab);
    setState(() => _newsFuture = next);
    await next;
  }

  void _openArticle(_FootballNewsItem item) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => NewsArticlePage(
      title: item.title,
      url: item.url,
      source: item.source,
      published: item.published,
      imageUrl: item.imageUrl,
    )));
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF111321) : const Color(0xFFF4F5FA),
        body: Column(children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [Color(0xFF171936), Color(0xFF392B78), Color(0xFF6554D9)], begin: Alignment.topRight, end: Alignment.bottomLeft),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(22)),
            ),
            child: const SafeArea(
              bottom: false,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Icon(Icons.sports_soccer_rounded, color: Color(0xFFFFD66B), size: 30),
                  SizedBox(width: 10),
                  Text('عالم كرة القدم', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                ]),
                SizedBox(height: 7),
                Text('آخر الأخبار والصفقات من مصادرها الأصلية', style: TextStyle(color: Color(0xFFE2DFFF), fontSize: 13)),
              ]),
            ),
          ),
          SizedBox(
            height: 58,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              scrollDirection: Axis.horizontal,
              itemCount: _footballTabs.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) => ChoiceChip(
                label: Text(_footballTabs[index]), selected: _selectedTab == index,
                onSelected: (_) => setState(() { _selectedTab = index; _newsFuture = _loadNews(index); }),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 2, 12, 8),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: 'ابحث عن فريق أو لاعب أو خبر...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isEmpty ? null : IconButton(
                  tooltip: 'مسح البحث',
                  onPressed: () { _searchController.clear(); setState(() => _searchQuery = ''); },
                  icon: const Icon(Icons.close),
                ),
                filled: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(vertical: 4),
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<_FootballNewsItem>>(
              future: _newsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) return const Center(child: CircularProgressIndicator());
                if (snapshot.hasError) return _NewsMessage(icon: Icons.wifi_off_rounded, message: 'تعذر تحميل الأخبار حالياً. اسحب للأسفل للمحاولة مجدداً.', onRetry: _refresh);
                final allItems = snapshot.data ?? const <_FootballNewsItem>[];
                final query = _searchQuery.trim().toLowerCase();
                final items = allItems.where((item) => query.isEmpty || item.title.toLowerCase().contains(query) || item.source.toLowerCase().contains(query)).toList();
                if (items.isEmpty) return _NewsMessage(icon: Icons.search_off_rounded, message: query.isEmpty ? 'ما وصلتنا أخبار حالياً. تأكد من الإنترنت وحاول مرة ثانية.' : 'ما لقينا أخبار تطابق بحثك.', onRetry: _refresh);
                return RefreshIndicator(
                  onRefresh: _refresh,
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(12, 4, 12, 22),
                    itemCount: items.length + 1,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return Padding(
                          padding: const EdgeInsets.fromLTRB(4, 6, 4, 12),
                          child: Row(children: [
                            const Icon(Icons.bolt_rounded, color: Color(0xFF6554D9)),
                            const SizedBox(width: 6),
                            Text(_selectedTab == 1 ? 'مستجدات سوق الانتقالات' : 'أحدث المستجدات', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            const Spacer(),
                            Text(items.length.toString() + ' خبر', style: TextStyle(color: Theme.of(context).colorScheme.secondary, fontSize: 12)),
                          ]),
                        );
                      }
                      final item = items[index - 1];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 10), elevation: 1,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Theme.of(context).dividerColor.withValues(alpha: .35))),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16), onTap: () => _openArticle(item),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              if (item.imageUrl.isNotEmpty) ...[
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.network(
                                    item.imageUrl,
                                    width: double.infinity,
                                    height: 165,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                                  ),
                                ),
                                const SizedBox(height: 11),
                              ],
                              Row(children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(color: const Color(0xFF6554D9).withValues(alpha: .12), borderRadius: BorderRadius.circular(20)),
                                  child: Text(item.category, style: const TextStyle(color: Color(0xFF8A78F0), fontSize: 11, fontWeight: FontWeight.bold)),
                                ),
                                const Spacer(),
                                const Icon(Icons.open_in_new_rounded, size: 16, color: Colors.grey),
                              ]),
                              const SizedBox(height: 10),
                              Text(item.title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, height: 1.55)),
                              const SizedBox(height: 12),
                              Row(children: [
                                const Icon(Icons.public_rounded, size: 15, color: Colors.grey),
                                const SizedBox(width: 5),
                                Expanded(child: Text(item.source, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.grey, fontSize: 12))),
                                if (item.published.isNotEmpty) ...[
                                  const SizedBox(width: 8),
                                  const Icon(Icons.schedule_rounded, size: 14, color: Colors.grey),
                                  const SizedBox(width: 4),
                                  Flexible(child: Text(item.published, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.grey, fontSize: 10))),
                                ],
                              ]),
                            ]),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
            child: Text('الأخبار تُعرض من مصادرها الأصلية؛ اضغط على الخبر لقراءة التفاصيل.', textAlign: TextAlign.center, style: TextStyle(color: Theme.of(context).hintColor, fontSize: 10)),
          ),
        ]),
      ),
    );
  }
}

class _NewsMessage extends StatelessWidget {
  const _NewsMessage({required this.icon, required this.message, required this.onRetry});
  final IconData icon;
  final String message;
  final Future<void> Function() onRetry;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 46, color: Colors.grey),
        const SizedBox(height: 12),
        Text(message, textAlign: TextAlign.center),
        const SizedBox(height: 12),
        OutlinedButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh_rounded), label: const Text('إعادة المحاولة')),
      ]),
    ),
  );
}
