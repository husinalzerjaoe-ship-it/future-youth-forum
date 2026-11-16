import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'watch_party.dart';

const _cinemaAccent = Color(0xFFB68CFF);

class CinemaHubPage extends StatefulWidget {
  const CinemaHubPage({super.key});
  @override State<CinemaHubPage> createState() => _CinemaHubPageState();
}

class _CinemaHubPageState extends State<CinemaHubPage> {
  final _search = TextEditingController();
  String _category = 'الكل';
  late Future<List<_Film>> _catalog;
  final Set<String> _favorites = {};
  static const _categories = ['الكل','الأفلام','المسلسلات','مفضلاتي','رعب','غموض','كوميديا','دراما','خيال علمي','مغامرة','أفلام صامتة'];

  @override void initState() { super.initState(); _catalog = _load(); _loadFavorites(); }
  @override void dispose() { _search.dispose(); super.dispose(); }

  Future<void> _loadFavorites() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      final s = await FirebaseFirestore.instance.collection('users').doc(uid).collection('cinemaFavorites').get();
      if (mounted) setState(() => _favorites.addAll(s.docs.map((d) => d.id)));
    } catch (_) {}
  }

  Future<void> _favorite(_Film film) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final ref = FirebaseFirestore.instance.collection('users').doc(uid).collection('cinemaFavorites').doc(film.id);
    try {
      if (_favorites.contains(film.id)) { await ref.delete(); setState(() => _favorites.remove(film.id)); }
      else { await ref.set({'title': film.title, 'year': film.year, 'addedAt': FieldValue.serverTimestamp()}); setState(() => _favorites.add(film.id)); }
    } catch (_) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تعذر حفظ المفضلة.'))); }
  }

  Future<List<_Film>> _load({bool series = false}) async {
    final q = series
        ? 'collection:classic_tv AND mediatype:movies'
        : 'collection:opensource_movies AND mediatype:movies';
    // Load up to 900 catalogue records in pages; actual playback is checked per title.
    final pages = await Future.wait(List.generate(9, (index) async {
      final uri = Uri.https('archive.org', '/advancedsearch.php', {
        'q': q,
        'fl[]': 'identifier,title,year,description',
        'rows': '100',
        'page': '${index + 1}',
        'output': 'json',
        'sort[]': 'downloads desc',
      });
      final response = await http.get(uri).timeout(const Duration(seconds: 25));
      if (response.statusCode != 200) throw Exception('archive unavailable');
      final root = jsonDecode(response.body) as Map<String, dynamic>;
      final responseData = root['response'] as Map<String, dynamic>;
      return (responseData['docs'] as List<dynamic>? ?? const <dynamic>[]);
    }));
    final seen = <String>{};
    return pages.expand((page) => page).whereType<Map<String, dynamic>>().map((d) {
      final id = (d['identifier'] ?? '').toString();
      return _Film(id, (d['title'] ?? 'عمل سينمائي').toString(),
        (d['year'] ?? '').toString(), (d['description'] ?? '').toString(), isSeries: series);
    }).where((film) => film.id.isNotEmpty && seen.add(film.id)).toList();
  }

  List<_Film> _filter(List<_Film> films) {
    final q = _search.text.trim().toLowerCase();
    return films.where((f) {
      final t = '${f.title} ${f.year} ${f.description}'.toLowerCase();
      final searchOk = q.isEmpty || t.contains(q);
      final categoryOk = switch (_category) {
        'رعب' => RegExp(r'horror|monster|vampire|ghost|zombie').hasMatch(t),
        'غموض' => RegExp(r'mystery|detective|thriller|crime').hasMatch(t),
        'كوميديا' => t.contains('comedy'),
        'دراما' => t.contains('drama') || t.contains('romance'),
        'خيال علمي' => RegExp(r'science fiction|sci.fi|space|alien').hasMatch(t),
        'مغامرة' => RegExp(r'adventure|western|war').hasMatch(t),
        'أفلام صامتة' => (int.tryParse(f.year) ?? 9999) < 1930,
        'الأفلام' => !f.isSeries,
        'المسلسلات' => f.isSeries,
        'مفضلاتي' => _favorites.contains(f.id),
        'مسلسلات كلاسيكية' => true,
        _ => true,
      };
      return searchOk && categoryOk;
    }).toList();
  }

  void _details(_Film film) => showModalBottomSheet<void>(
    context: context, isScrollControlled: true, showDragHandle: true,
    builder: (_) => _FilmDetails(film: film, onFavorite: () => _favorite(film)));

  @override Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.rtl,
    child: Scaffold(
      appBar: AppBar(title: const Text('سينما الملتقى'), actions: [
        IconButton(tooltip: 'غرف السينما', icon: const Icon(Icons.groups_rounded),
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CinemaRoomsPage()))),
      ]),
      body: FutureBuilder<List<_Film>>(
        future: _catalog,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (snap.hasError) return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('تعذر تحميل المكتبة المفتوحة.'),
            TextButton(onPressed: () => setState(() => _catalog = _load()), child: const Text('إعادة المحاولة')),
          ]));
          final films = _filter(snap.data ?? []);
          return RefreshIndicator(onRefresh: () async => setState(() => _catalog = _load(series: _category == 'المسلسلات' || _category == 'مسلسلات كلاسيكية')),
            child: CustomScrollView(slivers: [
              SliverToBoxAdapter(child: Container(
                margin: const EdgeInsets.all(14), padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: const LinearGradient(colors: [Color(0xFF321B57), Color(0xFF15162E), Color(0xFF40225B)]),
                  border: Border.all(color: _cinemaAccent.withOpacity(.4))),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Row(children: [Icon(Icons.movie_filter_rounded, color: Color(0xFFFFD98A), size: 28), SizedBox(width: 9),
                    Text('ليلتكم… على شاشة وحدة', style: TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w900))]),
                  const SizedBox(height: 8),
                  const Text('مكتبة أعمال مفتوحة، وغرف خاصة بدردشة ومزامنة للمقاطع المباشرة المدعومة.',
                    style: TextStyle(color: Colors.white70, height: 1.6)),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: Colors.white54)),
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ArabicAnimeCatalogPage())),
                    icon: const Icon(Icons.auto_awesome), label: const Text('عالم الأنمي • نحو 1000 عنوان'),
                  ),
                  const SizedBox(height: 12),
                  Wrap(spacing: 8, runSpacing: 8, children: [
                    FilledButton.icon(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CinemaRoomsPage())),
                      icon: const Icon(Icons.meeting_room), label: const Text('غرف السينما')),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: Colors.white54)),
                      onPressed: () { setState(() { _category = 'مسلسلات كلاسيكية'; _catalog = _load(series: true); }); },
                      icon: const Icon(Icons.live_tv), label: const Text('المسلسلات')),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: Colors.white54)),
                      onPressed: () { setState(() { _category = 'الكل'; _catalog = _load(); }); },
                      icon: const Icon(Icons.local_movies), label: const Text('الأفلام')),
                  ]),
                ]))),
              SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                child: TextField(controller: _search, onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(hintText: 'ابحث عن فيلم أو مسلسل...', prefixIcon: const Icon(Icons.search),
                    suffixIcon: _search.text.isEmpty ? null : IconButton(icon: const Icon(Icons.close), onPressed: () { _search.clear(); setState(() {}); }),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)))))),
              SliverToBoxAdapter(child: SizedBox(height: 48, child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 14), scrollDirection: Axis.horizontal,
                itemCount: _categories.length, separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) => ChoiceChip(label: Text(_categories[i]), selected: _category == _categories[i],
                  onSelected: (_) => setState(() { _category = _categories[i]; _catalog = _load(series: _categories[i] == 'المسلسلات' || _categories[i] == 'مسلسلات كلاسيكية'); }))))),
              SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
                child: Row(children: [const Icon(Icons.local_movies, color: _cinemaAccent), const SizedBox(width: 8),
                  const Expanded(child: Text('مكتبة الأعمال المفتوحة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18))),
                  Text(_category == 'مفضلاتي' ? '${films.length} مفضلة' : '${films.length} عمل')]))),
              if (films.isEmpty) const SliverFillRemaining(hasScrollBody: false, child: Center(child: Text('ما لقينا نتائج بهذا البحث.')))
              else SliverPadding(padding: const EdgeInsets.all(14), sliver: SliverGrid(
                delegate: SliverChildBuilderDelegate((_, i) {
                  final film = films[i];
                  return _FilmCard(film: film, favorite: _favorites.contains(film.id),
                    onTap: () => _details(film), onFavorite: () => _favorite(film));
                }, childCount: films.length),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: .68, crossAxisSpacing: 12, mainAxisSpacing: 12))),
              const SliverToBoxAdapter(child: Padding(padding: EdgeInsets.all(16), child: Text(
                'المكتبة تجلب أعمالاً من مجموعة Open Source Movies في Internet Archive. التوفر والترخيص يختلفان حسب العمل؛ راجع صفحة المصدر قبل المشاركة.',
                style: TextStyle(color: Colors.grey, fontSize: 11, height: 1.6)))),
            ]));
        },
      ),
    ),
  );
}

class _Film {
  const _Film(this.id, this.title, this.year, this.description, {this.isSeries = false});
  final String id, title, year, description;
  final bool isSeries;
}

class _FilmCard extends StatelessWidget {
  const _FilmCard({required this.film, required this.favorite, required this.onTap, required this.onFavorite});
  final _Film film; final bool favorite; final VoidCallback onTap, onFavorite;
  @override Widget build(BuildContext context) => InkWell(
    borderRadius: BorderRadius.circular(18), onTap: onTap,
    child: Ink(decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(18), border: Border.all(color: _cinemaAccent.withOpacity(.2))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Expanded(child: Stack(fit: StackFit.expand, children: [
          ClipRRect(borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
            child: Image.network('https://archive.org/services/img/${film.id}', fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(color: const Color(0xFF24203B), child: const Icon(Icons.movie, color: _cinemaAccent, size: 50)))),
          Positioned(top: 3, left: 3, child: IconButton.filledTonal(onPressed: onFavorite,
            icon: Icon(favorite ? Icons.favorite : Icons.favorite_border, color: favorite ? Colors.pinkAccent : Colors.white))),
          const Positioned(bottom: 8, right: 8, child: Icon(Icons.play_circle_fill, color: Colors.white, size: 34)),
        ])),
        Padding(padding: const EdgeInsets.all(10), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(film.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(film.year.isEmpty ? 'عمل مفتوح' : film.year, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey)),
        ])),
      ])),
  );
}

class _FilmDetails extends StatefulWidget {
  const _FilmDetails({required this.film, required this.onFavorite});
  final _Film film; final VoidCallback onFavorite;
  @override State<_FilmDetails> createState() => _FilmDetailsState();
}

class _FilmDetailsState extends State<_FilmDetails> {
  bool _busy = false; String? _directUrl; String? _message;
  Future<void> _checkVideo() async {
    setState(() { _busy = true; _message = null; });
    try {
      final r = await http.get(Uri.https('archive.org', '/metadata/${widget.film.id}')).timeout(const Duration(seconds: 20));
      if (r.statusCode != 200) throw Exception();
      final data = jsonDecode(r.body) as Map<String, dynamic>;
      final files = (data['files'] as List<dynamic>? ?? []).whereType<Map<String, dynamic>>().where((f) {
        final n = (f['name'] ?? '').toString().toLowerCase();
        return n.endsWith('.mp4') || n.endsWith('.m4v') || n.endsWith('.webm');
      }).toList();
      files.sort((a,b) => (int.tryParse((b['size'] ?? '0').toString()) ?? 0).compareTo(int.tryParse((a['size'] ?? '0').toString()) ?? 0));
      if (files.isEmpty) { setState(() => _message = 'ما لقينا ملف فيديو مباشر. تگدر تفتح المصدر، لكن المزامنة غير مضمونة.'); }
      else {
        final name = (files.first['name'] ?? '').toString();
        setState(() => _directUrl = 'https://archive.org/download/${widget.film.id}/${Uri.encodeComponent(name)}');
      }
    } catch (_) { setState(() => _message = 'تعذر فحص ملف التشغيل. افتح صفحة المصدر.'); }
    finally { if (mounted) setState(() => _busy = false); }
  }
  void _start() {
    final url = _directUrl; if (url == null) return;
    final navigator = Navigator.of(context);
    navigator.pop();
    navigator.push(MaterialPageRoute(builder: (_) => WatchPartyLobbyPage(
      initialUrl: url, initialName: widget.film.title, cinemaMode: true)));
  }
  @override Widget build(BuildContext context) => Directionality(textDirection: TextDirection.rtl,
    child: SafeArea(child: SingleChildScrollView(child: Padding(padding: const EdgeInsets.all(18), child: Column(mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        ClipRRect(borderRadius: BorderRadius.circular(16), child: AspectRatio(aspectRatio: 16/8,
          child: Image.network('https://archive.org/services/img/${widget.film.id}', fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(color: const Color(0xFF24203B), child: const Icon(Icons.movie, size: 50))))),
        const SizedBox(height: 12),
        Text(widget.film.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        Text(widget.film.year, style: const TextStyle(color: Colors.grey)),
        const SizedBox(height: 8),
        Text(widget.film.description.isEmpty ? 'عمل من مكتبة Internet Archive المفتوحة.' : widget.film.description,
          maxLines: 4, overflow: TextOverflow.ellipsis),
        if (_message != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(_message!, style: const TextStyle(color: Colors.orangeAccent))),
        if (_directUrl != null) const Text('تم العثور على فيديو مباشر يدعم مزامنة المشاهدة داخل الغرفة.',
          style: TextStyle(color: Colors.greenAccent, fontSize: 12)),
        const SizedBox(height: 10),
        FilledButton.icon(onPressed: _busy ? null : (_directUrl == null ? _checkVideo : _start),
          icon: _busy ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
            : Icon(_directUrl == null ? Icons.search : Icons.groups),
          label: Text(_busy ? 'جارٍ فحص الفيديو...' : _directUrl == null ? 'فحص التشغيل وإنشاء غرفة' : 'شاهد مع الأصدقاء')),
        TextButton.icon(onPressed: () => launchUrl(Uri.https('archive.org', '/details/${widget.film.id}'), mode: LaunchMode.externalApplication),
          icon: const Icon(Icons.open_in_new), label: const Text('صفحة المصدر')),
        TextButton.icon(
          onPressed: () {
            final title = widget.film.title;
            final uri = Uri.https('www.google.com', '/search', {'q': '$title ترجمة عربية مدبلج منصة رسمية'});
            launchUrl(uri, mode: LaunchMode.externalApplication);
          },
          icon: const Icon(Icons.translate),
          label: const Text('ابحث عن النسخة العربية على المنصات الرسمية'),
        ),
        TextButton.icon(onPressed: widget.onFavorite, icon: const Icon(Icons.favorite_border), label: const Text('إضافة / إزالة من المفضلة')),
      ])))));
}

class CinemaRoomsPage extends StatelessWidget {
  const CinemaRoomsPage({super.key});
  @override Widget build(BuildContext context) => Directionality(textDirection: TextDirection.rtl,
    child: Scaffold(appBar: AppBar(title: const Text('غرف سينما الملتقى')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('watchRooms').where('roomType', isEqualTo: 'cinema').where('active', isEqualTo: true).where('visibility', isEqualTo: 'public').limit(50).snapshots(),
        builder: (context, snap) {
          if (snap.hasError) return const Center(child: Text('تعذر تحميل غرف السينما.'));
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snap.data!.docs;
          if (docs.isEmpty) return const Center(child: Text('ماكو غرف سينما مفتوحة حالياً. اختار فيلماً وأنشئ غرفة.'));
          return ListView(children: docs.map((d) => Card(child: ListTile(
            leading: const CircleAvatar(child: Icon(Icons.movie_filter)),
            title: Text((d.data()['name'] ?? 'غرفة سينما').toString()),
            subtitle: Text((d.data()['contentTitle'] ?? 'مشاهدة جماعية').toString()),
            trailing: const Icon(Icons.chevron_left),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => WatchPartyRoomPage(roomId: d.id))),
          ))).toList());
        },
      )));
}


class ArabicAnimeCatalogPage extends StatefulWidget {
  const ArabicAnimeCatalogPage({super.key});
  @override State<ArabicAnimeCatalogPage> createState() => _ArabicAnimeCatalogPageState();
}

class _ArabicAnimeCatalogPageState extends State<ArabicAnimeCatalogPage> {
  final _search = TextEditingController();
  final List<Map<String, dynamic>> _items = [];
  int _page = 1;
  bool _loading = false;
  bool _hasNext = true;
  String? _error;

  @override void initState() { super.initState(); _load(); }
  @override void dispose() { _search.dispose(); super.dispose(); }

  Future<void> _load({bool reset = false}) async {
    if (_loading) return;
    if (reset) { _page = 1; _hasNext = true; _items.clear(); }
    if (!_hasNext) return;
    setState(() { _loading = true; _error = null; });
    try {
      final rawQuery = _search.text.trim();
      const arabicAliases = <String, String>{
        'ون بيس': 'One Piece', 'لوفي': 'One Piece', 'ناروتو': 'Naruto',
        'بليتش': 'Bleach', 'دراغون بول': 'Dragon Ball', 'المحقق كونان': 'Detective Conan',
        'هجوم العمالقة': 'Attack on Titan', 'قاتل الشياطين': 'Demon Slayer',
        'جوجوتسو كايسن': 'Jujutsu Kaisen', 'مذكرة الموت': 'Death Note',
        'هنتر': 'Hunter x Hunter', 'هنتر x هنتر': 'Hunter x Hunter',
        'أكاديمية بطلي': 'My Hero Academia', 'هايكيو': 'Haikyu',
      };
      final query = arabicAliases[rawQuery] ?? rawQuery;
      final uri = query.isEmpty
        ? Uri.https('api.jikan.moe', '/v4/top/anime', {'page': '$_page', 'limit': '25', 'sfw': 'true'})
        : Uri.https('api.jikan.moe', '/v4/anime', {'page': '$_page', 'limit': '25', 'q': query, 'sfw': 'true'});
      final response = await http.get(uri, headers: {'Accept': 'application/json'}).timeout(const Duration(seconds: 25));
      if (response.statusCode == 429) throw Exception('الخدمة طلبت انتظاراً قصيراً؛ حاول بعد دقيقة.');
      if (response.statusCode != 200) throw Exception('تعذر جلب قائمة الأنمي حالياً.');
      final root = jsonDecode(response.body) as Map<String, dynamic>;
      final rows = (root['data'] as List<dynamic>? ?? []).whereType<Map<String, dynamic>>().toList();
      final pagination = root['pagination'] as Map<String, dynamic>? ?? {};
      if (mounted) setState(() {
        _items.addAll(rows);
        _hasNext = (pagination['has_next_page'] == true) && rows.isNotEmpty && _page < 40;
        _page++;
      });
    } catch (e) {
      if (mounted) setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally { if (mounted) setState(() => _loading = false); }
  }

  void _showAnimeDetails(Map<String, dynamic> anime) {
    final title = (anime['title_english'] ?? anime['title'] ?? 'Anime').toString();
    final synopsis = (anime['synopsis'] ?? 'لا يوجد ملخص متاح حالياً.').toString();
    final episodes = anime['episodes']?.toString() ?? 'غير محدد';
    final score = anime['score']?.toString() ?? '—';
    final image = ((anime['images'] as Map?)?['jpg'] as Map?)?['large_image_url']?.toString();
    showModalBottomSheet<void>(
      context: context, isScrollControlled: true, showDragHandle: true,
      builder: (sheetContext) => Directionality(
        textDirection: TextDirection.rtl,
        child: SafeArea(child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            if (image != null) ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(image, height: 190, fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox(height: 90, child: Icon(Icons.animation))),
            ),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
            const SizedBox(height: 6),
            Wrap(spacing: 8, children: [
              Chip(avatar: const Icon(Icons.video_library, size: 16), label: Text('$episodes حلقة')),
              Chip(avatar: const Icon(Icons.star, size: 16), label: Text('التقييم $score')),
              Chip(label: Text((anime['status'] ?? 'الحالة غير محددة').toString())),
            ]),
            const SizedBox(height: 8),
            Text(synopsis, style: const TextStyle(height: 1.6)),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: () { Navigator.pop(sheetContext); _checkArabic(anime); },
              icon: const Icon(Icons.translate), label: const Text('خيارات الترجمة العربية والمشاهدة'),
            ),
          ]),
        )),
      ),
    );
  }

  Future<void> _checkArabic(Map<String, dynamic> anime) async {
    final title = (anime['title_english'] ?? anime['title'] ?? '').toString();
    if (!mounted) return;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => Directionality(
        textDirection: TextDirection.rtl,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text('خيارات مشاهدة $title', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('اختر منصة وافحص صفحة العنوان. الترجمة والدبلجة تختلف حسب الموسم والحلقة وبلدك؛ هذه روابط بحث رسمية وليست تأكيداً بأن العنوان متاح أو مترجم.'),
            const SizedBox(height: 14),
            FilledButton.icon(
              icon: const Icon(Icons.subtitles),
              label: const Text('Crunchyroll • كرانشي رول'),
              onPressed: () => launchUrl(Uri.https('www.crunchyroll.com', '/search', {'q': title}), mode: LaunchMode.externalApplication),
            ),
            OutlinedButton.icon(
              icon: const Icon(Icons.movie_outlined),
              label: const Text('Netflix • نتفلكس'),
              onPressed: () => launchUrl(Uri.https('www.netflix.com', '/iq-en/search', {'q': title}), mode: LaunchMode.externalApplication),
            ),
            OutlinedButton.icon(
              icon: const Icon(Icons.play_circle_outline),
              label: const Text('Prime Video • برايم فيديو'),
              onPressed: () => launchUrl(Uri.https('www.primevideo.com', '/search/ref=atv_nb_sr?phrase=$title'), mode: LaunchMode.externalApplication),
            ),
          ]),
        ),
      ),
    );
  }

  @override Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.rtl,
    child: Scaffold(
      appBar: AppBar(title: const Text('دليل الأنمي')),
      body: Column(children: [
        Container(width: double.infinity, margin: const EdgeInsets.all(12), padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(18), gradient: const LinearGradient(colors: [Color(0xFF34205B), Color(0xFF17182E)])),
          child: const Text('تصفّح نحو 1000 عنوان أنمي، وابحث عن الترجمة أو الدبلجة العربية عبر منصات العرض الرسمية. توفر العربية يختلف حسب البلد والمنصة والعنوان، لذلك لا نضع علامة مترجم إلا بعد التحقق.',
            style: TextStyle(color: Colors.white, height: 1.6))),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 2, 12, 8),
          child: Wrap(spacing: 7, runSpacing: 6, children: [
            for (final title in ['One Piece', 'Naruto', 'Bleach', 'Dragon Ball', 'Detective Conan', 'Attack on Titan', 'Jujutsu Kaisen', 'Demon Slayer', 'My Hero Academia', 'Death Note', 'Hunter x Hunter', 'Haikyu!!'])
              ActionChip(
                label: Text(title),
                onPressed: () { _search.text = title; _load(reset: true); },
              ),
          ]),
        ),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: TextField(
          controller: _search,
          onSubmitted: (_) => _load(reset: true),
          decoration: InputDecoration(
            hintText: 'ابحث باسم الأنمي...',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: IconButton(icon: const Icon(Icons.search), onPressed: () => _load(reset: true)),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          ))),
        if (_error != null) Padding(padding: const EdgeInsets.all(8), child: Text(_error!, style: const TextStyle(color: Colors.orange))),
        Expanded(child: _items.isEmpty && _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _items.length + (_hasNext || _loading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index >= _items.length) return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Center(child: _loading ? const CircularProgressIndicator() : OutlinedButton.icon(
                    onPressed: _load, icon: const Icon(Icons.expand_more), label: const Text('تحميل 25 أنمي إضافياً'))));
                final item = _items[index];
                final title = (item['title_english'] ?? item['title'] ?? 'Anime').toString();
                final image = ((item['images'] as Map?)?['jpg'] as Map?)?['large_image_url']?.toString();
                final genres = (item['genres'] as List<dynamic>? ?? []).whereType<Map>().map((g) => g['name'].toString()).take(3).join(' • ');
                final year = item['year']?.toString() ?? item['aired']?['prop']?['from']?['year']?.toString() ?? '—';
                return Card(margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), child: ListTile(
                  isThreeLine: true,
                  leading: ClipRRect(borderRadius: BorderRadius.circular(8), child: image != null
                    ? Image.network(image, width: 58, height: 82, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.animation))
                    : const SizedBox(width: 58, height: 82, child: Icon(Icons.animation))),
                  title: Text(title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('$year • ${item['type'] ?? 'Anime'} • $genres\nتوفر الترجمة العربية: تحقّق من المنصة الرسمية', maxLines: 3, overflow: TextOverflow.ellipsis),
                  trailing: IconButton(tooltip: 'البحث عن ترجمة عربية', icon: const Icon(Icons.translate, color: _cinemaAccent), onPressed: () => _checkArabic(item)),
                  onTap: () => _showAnimeDetails(item),
                ));
              })),
      ]),
    ),
  );
}
