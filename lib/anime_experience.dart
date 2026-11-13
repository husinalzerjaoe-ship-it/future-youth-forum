import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const _violet = Color(0xFF6554D9);
const _ink = Color(0xFF171936);
final _db = FirebaseFirestore.instance;
String get _uid => FirebaseAuth.instance.currentUser!.uid;
bool get _founder => FirebaseAuth.instance.currentUser?.email?.toLowerCase() == 'husinalzerjaoe@gmail.com';

class AnimeExperiencePage extends StatelessWidget {
  const AnimeExperiencePage({super.key});
  @override Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.rtl,
    child: DefaultTabController(length: 3, child: Scaffold(
      appBar: AppBar(title: const Text('عالم الأنمي'), foregroundColor: Colors.white,
        flexibleSpace: Container(decoration: const BoxDecoration(gradient: LinearGradient(colors: [_ink, _violet, Color(0xFF168E9B)]))),
        bottom: const TabBar(isScrollable: true, tabs: [
          Tab(icon: Icon(Icons.wallpaper), text: 'الخلفيات'),
          Tab(icon: Icon(Icons.bookmarks), text: 'قائمتي'),
          Tab(icon: Icon(Icons.quiz), text: 'اختبر نفسك'),
        ])),
      body: const TabBarView(children: [AnimeWallpaperGallery(), AnimeWatchlistPage(), AnimeQuizPage()]),
    )),
  );
}

class AnimeWallpaperGallery extends StatefulWidget {
  const AnimeWallpaperGallery({super.key});
  @override State<AnimeWallpaperGallery> createState() => _AnimeWallpaperGalleryState();
}
class _AnimeWallpaperGalleryState extends State<AnimeWallpaperGallery> {
  bool busy = false;
  String filter = 'الكل';
  Future<void> addWallpaper() async {
    final file = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 90, maxWidth: 2560);
    if (file == null || !mounted) return;
    final title = TextEditingController(), anime = TextEditingController(), artist = TextEditingController(), source = TextEditingController();
    String rights = 'أنا صاحب العمل وأسمح بنشره';
    final ok = await showDialog<bool>(context: context, builder: (c) => Directionality(textDirection: TextDirection.rtl, child: AlertDialog(
      title: const Text('إضافة خلفية مع حفظ الحقوق'),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: title, decoration: const InputDecoration(labelText: 'عنوان الخلفية')),
        TextField(controller: anime, decoration: const InputDecoration(labelText: 'اسم الأنمي')),
        TextField(controller: artist, decoration: const InputDecoration(labelText: 'اسم الفنان أو صاحب العمل')),
        TextField(controller: source, decoration: const InputDecoration(labelText: 'رابط المصدر أو الترخيص'), keyboardType: TextInputType.url),
        DropdownButtonFormField<String>(value: rights, isExpanded: true, decoration: const InputDecoration(labelText: 'أساس حق النشر'),
          items: const [
            DropdownMenuItem(value: 'أنا صاحب العمل وأسمح بنشره', child: Text('أنا صاحب العمل')),
            DropdownMenuItem(value: 'ترخيص Creative Commons يسمح بإعادة الاستخدام', child: Text('ترخيص Creative Commons')),
            DropdownMenuItem(value: 'إذن مكتوب من صاحب الحقوق', child: Text('إذن مكتوب')),
            DropdownMenuItem(value: 'مصدر رسمي يسمح صراحة بإعادة الاستخدام', child: Text('مصدر رسمي يسمح بإعادة الاستخدام')),
          ], onChanged: (v) { if (v != null) rights = v; }),
        const Text('لن تظهر الصورة للكل قبل مراجعة المشرف. لا ترفع صوراً محمية دون إذن.', style: TextStyle(fontSize: 12, color: Colors.grey)),
      ])),
      actions: [TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('إلغاء')),
        FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('إرسال للمراجعة'))],
    )));
    if (ok != true) { title.dispose(); anime.dispose(); artist.dispose(); source.dispose(); return; }
    if ([title.text, anime.text, artist.text].any((v) => v.trim().isEmpty) || !source.text.trim().startsWith('https://')) {
      _snack('أكمل العنوان والفنان ورابط مصدر صحيح يبدأ بـ https://');
      title.dispose(); anime.dispose(); artist.dispose(); source.dispose(); return;
    }
    setState(() => busy = true);
    try {
      final ext = file.name.toLowerCase().split('.').last;
      final safe = ['jpg','jpeg','png','webp'].contains(ext) ? ext : 'jpg';
      final mime = safe == 'jpg' || safe == 'jpeg' ? 'image/jpeg' : 'image/$safe';
      final path = 'anime-wallpapers/' + _uid + '/' + DateTime.now().microsecondsSinceEpoch.toString() + '.' + safe;
      await Supabase.instance.client.storage.from('forum-media').uploadBinary(path, await file.readAsBytes(),
        fileOptions: FileOptions(contentType: mime, upsert: false));
      final url = Supabase.instance.client.storage.from('forum-media').getPublicUrl(path);
      await _db.collection('animeWallpapers').add({
        'title': title.text.trim(), 'anime': anime.text.trim(), 'artist': artist.text.trim(),
        'sourceUrl': source.text.trim(), 'rights': rights, 'imageUrl': url, 'uploaderId': _uid,
        'status': 'pending', 'createdAt': FieldValue.serverTimestamp(),
      });
      _snack('وصلتنا الخلفية، وتظهر بعد موافقة المشرف والتحقق من الحقوق.');
    } catch (_) { _snack('تعذر الرفع. تحقق من نشر سياسة مجلد anime-wallpapers في Supabase.'); }
    finally {
      title.dispose(); anime.dispose(); artist.dispose(); source.dispose();
      if (mounted) setState(() => busy = false);
    }
  }
  void _snack(String s) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s))); }
  Future<void> review(DocumentSnapshot<Map<String,dynamic>> doc, bool approve) async {
    await doc.reference.update({'status': approve ? 'approved' : 'rejected', 'reviewedBy': _uid, 'reviewedAt': FieldValue.serverTimestamp()});
    _snack(approve ? 'تمت الموافقة' : 'تم الرفض');
  }
  Future<void> pending() async {
    await showModalBottomSheet<void>(context: context, isScrollControlled: true, showDragHandle: true,
      builder: (c) => Directionality(textDirection: TextDirection.rtl, child: SizedBox(height: MediaQuery.of(c).size.height * .7,
        child: StreamBuilder<QuerySnapshot<Map<String,dynamic>>>(
          stream: _db.collection('animeWallpapers').where('status', isEqualTo: 'pending').limit(60).snapshots(),
          builder: (context, s) {
            if (s.hasError) return const Center(child: Text('تعذر تحميل الطلبات'));
            if (!s.hasData) return const Center(child: CircularProgressIndicator());
            if (s.data!.docs.isEmpty) return const Center(child: Text('ماكو خلفيات معلقة'));
            return ListView(children: s.data!.docs.map((doc) {
              final d = doc.data();
              return ListTile(title: Text(d['title'] ?? 'خلفية'), subtitle: Text('\${d['artist'] ?? ''} • \${d['rights'] ?? ''}'),
                trailing: Wrap(children: [
                  IconButton(icon: const Icon(Icons.check_circle, color: Colors.green), onPressed: () => review(doc, true)),
                  IconButton(icon: const Icon(Icons.cancel, color: Colors.red), onPressed: () => review(doc, false)),
                ]));
            }).toList());
          },
        ))));
  }
  @override Widget build(BuildContext context) {
    const filters = ['الكل', 'ناروتو', 'ون بيس', 'هجوم العمالقة', 'مناظر', 'شخصيات'];
    return Column(children: [
      Container(margin: const EdgeInsets.all(12), padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(18), gradient: const LinearGradient(colors: [_ink, _violet, Color(0xFF168E9B)])),
        child: Row(children: [
          const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('خلفيتك… عالمك ✨', style: TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.bold)),
            Text('مكتبة فنية بمصادر وحقوق واضحة', style: TextStyle(color: Colors.white70)),
          ])),
          IconButton(onPressed: busy ? null : addWallpaper, icon: busy ? const CircularProgressIndicator(color: Colors.white) : const Icon(Icons.add_photo_alternate, color: Colors.white)),
        ])),
      SizedBox(height: 46, child: ListView(scrollDirection: Axis.horizontal, children: filters.map((f) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4), child: ChoiceChip(label: Text(f), selected: filter == f, onSelected: (_) => setState(() => filter = f)),
      )).toList())),
      Expanded(child: StreamBuilder<QuerySnapshot<Map<String,dynamic>>>(
        stream: _db.collection('animeWallpapers').where('status', isEqualTo: 'approved').limit(100).snapshots(),
        builder: (context, s) {
          if (s.hasError) return const Center(child: Text('تعذر تحميل الخلفيات'));
          if (!s.hasData) return const Center(child: CircularProgressIndicator());
          final docs = s.data!.docs.where((doc) {
            if (filter == 'الكل') return true;
            final d = doc.data(); return '\${d['anime'] ?? ''} \${d['title'] ?? ''}'.toLowerCase().contains(filter.toLowerCase());
          }).toList();
          if (docs.isEmpty) return const Center(child: Padding(padding: EdgeInsets.all(24), child: Text('المكتبة بانتظار أول الأعمال المرخّصة. شارك عملاً تملك حق نشره!')));
          return GridView.builder(padding: const EdgeInsets.all(12), itemCount: docs.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: .68, crossAxisSpacing: 10, mainAxisSpacing: 10),
            itemBuilder: (context, i) {
              final d = docs[i].data();
              return Card(clipBehavior: Clip.antiAlias, child: InkWell(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => WallpaperDetailPage(data: d))),
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Expanded(child: Image.network(d['imageUrl'] ?? '', fit: BoxFit.cover, errorBuilder: (_,__,___) => const Icon(Icons.broken_image))),
                  Padding(padding: const EdgeInsets.all(8), child: Text(d['title'] ?? 'خلفية', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold))),
                  Padding(padding: const EdgeInsets.fromLTRB(8,0,8,8), child: Text('\${d['anime'] ?? ''} • \${d['artist'] ?? ''}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11))),
                ]),
              ));
            });
        },
      )),
      if (_founder) TextButton.icon(onPressed: pending, icon: const Icon(Icons.fact_check), label: const Text('مراجعة الخلفيات المعلقة')),
    ]);
  }
}

class WallpaperDetailPage extends StatelessWidget {
  final Map<String,dynamic> data;
  const WallpaperDetailPage({super.key, required this.data});
  Future<void> download(BuildContext context) async {
    HttpClient? client;
    try {
      client = HttpClient();
      final request = await client.getUrl(Uri.parse(data['imageUrl'] as String));
      final response = await request.close();
      if (response.statusCode != 200) throw Exception('download');
      final bytes = await response.fold<List<int>>(<int>[], (all, chunk) => all..addAll(chunk));
      if (!await Gal.hasAccess() && !await Gal.requestAccess()) throw Exception('permission');
      await Gal.putImageBytes(bytes, album: 'ملتقى الأنمي');
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حفظ الخلفية بالمعرض')));
    } catch (_) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تعذر تنزيل الخلفية')));
    } finally { client?.close(force: true); }
  }
  @override Widget build(BuildContext context) => Directionality(textDirection: TextDirection.rtl, child: Scaffold(
    appBar: AppBar(title: Text(data['title'] ?? 'خلفية')),
    body: ListView(padding: const EdgeInsets.all(16), children: [
      ClipRRect(borderRadius: BorderRadius.circular(18), child: AspectRatio(aspectRatio: 9/16,
        child: Image.network(data['imageUrl'] ?? '', fit: BoxFit.cover, errorBuilder: (_,__,___) => const Icon(Icons.broken_image)))),
      const SizedBox(height: 12),
      Text(data['title'] ?? 'خلفية', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
      ListTile(leading: const Icon(Icons.movie), title: const Text('الأنمي'), subtitle: Text(data['anime'] ?? '')),
      ListTile(leading: const Icon(Icons.brush), title: const Text('الفنان'), subtitle: Text(data['artist'] ?? '')),
      ListTile(leading: const Icon(Icons.copyright), title: const Text('الحقوق'), subtitle: Text(data['rights'] ?? '')),
      ListTile(leading: const Icon(Icons.link), title: const Text('المصدر'), subtitle: SelectableText(data['sourceUrl'] ?? '')),
      FilledButton.icon(onPressed: () => download(context), icon: const Icon(Icons.download), label: const Text('تنزيل الخلفية')),
    ]),
  ));
}

class AnimeWatchlistPage extends StatefulWidget {
  const AnimeWatchlistPage({super.key});
  @override State<AnimeWatchlistPage> createState() => _AnimeWatchlistPageState();
}
class _AnimeWatchlistPageState extends State<AnimeWatchlistPage> {
  static const suggestions = [
    ('هجوم العمالقة','أكشن • غموض','attack-on-titan'),('ون بيس','مغامرة • خيال','one-piece'),
    ('ناروتو','نينجا • مغامرة','naruto'),('قاتل الشياطين','أكشن • فانتازيا','demon-slayer'),
    ('جوجوتسو كايسن','خوارق • أكشن','jujutsu-kaisen'),('ديث نوت','غموض • نفسي','death-note'),
    ('بلو لوك','رياضة • منافسة','blue-lock'),('هايكيو','رياضة • مدرسي','haikyuu'),
  ];
  Future<void> add() async {
    final title = TextEditingController(), genre = TextEditingController();
    final ok = await showDialog<bool>(context: context, builder: (c) => Directionality(textDirection: TextDirection.rtl, child: AlertDialog(
      title: const Text('أضف أنمي لقائمتك'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: title, decoration: const InputDecoration(labelText: 'اسم الأنمي')),
        TextField(controller: genre, decoration: const InputDecoration(labelText: 'التصنيف')),
      ]),
      actions: [TextButton(onPressed: () => Navigator.pop(c,false), child: const Text('إلغاء')), FilledButton(onPressed: () => Navigator.pop(c,true), child: const Text('إضافة'))],
    )));
    if (ok == true && title.text.trim().isNotEmpty) {
      await _db.collection('users').doc(_uid).collection('animeWatchlist').add({
        'title': title.text.trim(), 'genre': genre.text.trim(), 'status': 'planned', 'createdAt': FieldValue.serverTimestamp(),
      });
    }
    title.dispose(); genre.dispose();
  }
  @override Widget build(BuildContext context) => Column(children: [
    Padding(padding: const EdgeInsets.all(12), child: Row(children: [
      const Expanded(child: Text('أنميات شاهدتها أو تريد مشاهدتها')),
      FilledButton.tonalIcon(onPressed: add, icon: const Icon(Icons.add), label: const Text('إضافة')),
    ])),
    Expanded(child: StreamBuilder<QuerySnapshot<Map<String,dynamic>>>(
      stream: _db.collection('users').doc(_uid).collection('animeWatchlist').orderBy('createdAt', descending: true).snapshots(),
      builder: (context, s) {
        if (s.hasError) return const Center(child: Text('تعذر تحميل قائمتك'));
        if (!s.hasData) return const Center(child: CircularProgressIndicator());
        final docs = s.data!.docs;
        return ListView(children: [
          if (docs.isEmpty) const Padding(padding: EdgeInsets.all(18), child: Text('قائمتك فارغة، أضف أنمياتك المفضلة.', textAlign: TextAlign.center)),
          ...docs.map((doc) {
            final d = doc.data(); final status = d['status'] ?? 'planned';
            return Card(child: ListTile(
              leading: CircleAvatar(child: Icon(status == 'watched' ? Icons.check : Icons.play_arrow)),
              title: Text(d['title'] ?? 'أنمي'), subtitle: Text('\${d['genre'] ?? ''} • \${status == 'watched' ? 'تمت المشاهدة' : status == 'watching' ? 'أشاهده حالياً' : 'أريد مشاهدته'}'),
              trailing: PopupMenuButton<String>(onSelected: (v) async {
                if (v == 'delete') { await doc.reference.delete(); } else { await doc.reference.update({'status': v}); }
              }, itemBuilder: (_) => const [
                PopupMenuItem(value: 'planned', child: Text('أريد مشاهدته')),
                PopupMenuItem(value: 'watching', child: Text('أشاهده حالياً')),
                PopupMenuItem(value: 'watched', child: Text('تمت المشاهدة')),
                PopupMenuItem(value: 'delete', child: Text('حذف')),
              ]),
            ));
          }),
          const Padding(padding: EdgeInsets.all(12), child: Text('اقتراحات', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17))),
          ...suggestions.where((item) => !docs.any((d) => d.id == item.$3 || d.data()['title'] == item.$1)).map((item) => ListTile(
            leading: const Icon(Icons.movie_creation_outlined), title: Text(item.$1), subtitle: Text(item.$2),
            trailing: IconButton(icon: const Icon(Icons.add_circle_outline), onPressed: () => _db.collection('users').doc(_uid).collection('animeWatchlist').doc(item.$3).set({
              'title': item.$1, 'genre': item.$2, 'status': 'planned', 'createdAt': FieldValue.serverTimestamp(),
            })),
          )),
        ]);
      },
    )),
  ]);
}

class AnimeQuizPage extends StatefulWidget {
  const AnimeQuizPage({super.key});
  @override State<AnimeQuizPage> createState() => _AnimeQuizPageState();
}
class _AnimeQuizPageState extends State<AnimeQuizPage> {
  static const questions = [
    ('ما اسم قرية ناروتو؟',['كونوها','سونا','كيري','إيوا'],0),
    ('من طباخ طاقم قبعة القش؟',['زورو','سانجي','أوسوب','فرانكي'],1),
    ('ما اسم دفتر لايت؟',['دفتر الظلال','دفتر الموت','دفتر الأرواح','دفتر الليل'],1),
    ('من بطل هجوم العمالقة؟',['إيرين','ليفاي','أرمين','إروين'],0),
    ('ما اسم أخت تانجيرو؟',['زينيتسو','إينوسكي','نيزوكو','غيو'],2),
    ('أي رياضة في هايكيو؟',['كرة القدم','كرة السلة','الكرة الطائرة','التنس'],2),
    ('من بطل ون بنش مان؟',['غارو','سايتاما','جينوس','كينغ'],1),
    ('ما لقب لوفي؟',['النينجا','قبعة القش','الصياد','البرق'],1),
  ];
  int index = 0, score = 0; int? selected; bool finished = false;
  void answer(int value) { if (selected != null) return; setState(() { selected = value; if (value == questions[index].$3) score++; }); }
  void next() { if (index == questions.length - 1) { setState(() => finished = true); } else { setState(() { index++; selected = null; }); } }
  void restart() => setState(() { index = 0; score = 0; selected = null; finished = false; });
  @override Widget build(BuildContext context) {
    if (finished) return Center(child: Card(margin: const EdgeInsets.all(24), child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.emoji_events, size: 64, color: Colors.amber),
      const Text('خلص التحدي!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
      Text('\$score من \${questions.length}', style: const TextStyle(fontSize: 30, color: _violet, fontWeight: FontWeight.bold)),
      FilledButton.icon(onPressed: restart, icon: const Icon(Icons.replay), label: const Text('إعادة اللعب')),
    ]))));
    final q = questions[index];
    return ListView(padding: const EdgeInsets.all(18), children: [
      LinearProgressIndicator(value: (index + 1) / questions.length, minHeight: 8),
      const SizedBox(height: 12),
      Text('السؤال \${index + 1} من \${questions.length} • نقاطك \$score', style: const TextStyle(color: _violet, fontWeight: FontWeight.bold)),
      Card(child: Padding(padding: const EdgeInsets.all(20), child: Text(q.$1, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.bold)))),
      ...List.generate(q.$2.length, (i) {
        final correct = q.$3 == i, chosen = selected == i;
        return Card(color: selected == null ? null : correct ? Colors.green.withValues(alpha: .14) : chosen ? Colors.red.withValues(alpha: .12) : null,
          child: ListTile(title: Text(q.$2[i]), trailing: selected == null ? null : correct ? const Icon(Icons.check_circle, color: Colors.green) : chosen ? const Icon(Icons.cancel, color: Colors.red) : null, onTap: () => answer(i)));
      }),
      if (selected != null) FilledButton(onPressed: next, child: Text(index == questions.length - 1 ? 'عرض النتيجة' : 'السؤال التالي')),
    ]);
  }
}
