import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class V22CinemaDiscoveryPage extends StatefulWidget {
  const V22CinemaDiscoveryPage({super.key});
  @override
  State<V22CinemaDiscoveryPage> createState() => _V22CinemaDiscoveryPageState();
}
class _V22CinemaDiscoveryPageState extends State<V22CinemaDiscoveryPage> {
  final _search = TextEditingController();
  String _year = '2026', _kind = 'movie', _genre = 'الكل', _apiKey = '';
  bool _loading = false, _hasMore = true;
  String? _error;
  int _page = 1;
  List<_V22Title> _items = [];
  final Set<int> _favorites = {}, _watched = {};
  static const _genres = <String, int>{'الكل':0,'أكشن':28,'مغامرة':12,'كوميديا':35,'دراما':18,'خيال علمي':878,'رعب':27,'غموض':9648,'رسوم متحركة':16,'وثائقي':99,'عائلي':10751};

  @override
  void initState() { super.initState(); _restore(); }
  @override
  void dispose() { _search.dispose(); super.dispose(); }
  Future<void> _restore() async {
    final p = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _apiKey = p.getString('v22_tmdb_api_key') ?? '';
      _favorites.addAll((p.getStringList('v22_favorites') ?? []).map((e) => int.tryParse(e) ?? -1).where((e) => e >= 0));
      _watched.addAll((p.getStringList('v22_watched') ?? []).map((e) => int.tryParse(e) ?? -1).where((e) => e >= 0));
    });
    if (_apiKey.isEmpty) setState(() => _error = 'أضف مفتاح TMDB API من زر الإعدادات لتفعيل فهرس 2025 و2026.');
    else _load(reset: true);
  }
  Future<void> _saveSet(String key, Set<int> values) async {
    final p = await SharedPreferences.getInstance();
    await p.setStringList(key, values.map((e) => e.toString()).toList());
  }
  Future<void> _configureKey() async {
    final controller = TextEditingController(text: _apiKey);
    final value = await showDialog<String>(context: context, builder: (c) => Directionality(textDirection: TextDirection.rtl, child: AlertDialog(
      title: const Text('إعداد فهرس الأفلام'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text('أدخل مفتاح TMDB API للاستخدام غير التجاري. يُحفظ على هذا الجهاز فقط ويُرسل إلى TMDB.'),
        const SizedBox(height: 10),
        TextField(controller: controller, obscureText: true, decoration: const InputDecoration(labelText: 'TMDB API Key', border: OutlineInputBorder())),
      ]),
      actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text('إلغاء')), FilledButton(onPressed: () => Navigator.pop(c, controller.text.trim()), child: const Text('حفظ'))],
    )));
    controller.dispose();
    if (value == null) return;
    final p = await SharedPreferences.getInstance();
    await p.setString('v22_tmdb_api_key', value);
    if (!mounted) return;
    setState(() { _apiKey = value; _error = null; });
    if (_apiKey.isEmpty) { setState(() => _items = []); return; }
    _load(reset: true);
  }
  Future<void> _load({bool reset = false}) async {
    if (_apiKey.isEmpty) { setState(() => _error = 'أضف مفتاح TMDB API من زر الإعدادات.'); return; }
    if (_loading || (!_hasMore && !reset)) return;
    if (reset) { _page = 1; _hasMore = true; }
    setState(() { _loading = true; _error = null; });
    try {
      final q = _search.text.trim(), isMovie = _kind == 'movie';
      final endpoint = q.isNotEmpty ? (isMovie ? 'search/movie' : 'search/tv') : (isMovie ? 'discover/movie' : 'discover/tv');
      final params = <String, String>{'api_key':_apiKey,'language':'ar-IQ','page':_page.toString(),'include_adult':'false','sort_by':'popularity.desc'};
      if (q.isNotEmpty) { params['query'] = q; params['year'] = _year; }
      else if (isMovie) { params['primary_release_date.gte'] = _year + '-01-01'; params['primary_release_date.lte'] = _year + '-12-31'; }
      else { params['first_air_date.gte'] = _year + '-01-01'; params['first_air_date.lte'] = _year + '-12-31'; }
      final gid = _genres[_genre] ?? 0;
      if (gid != 0) params['with_genres'] = gid.toString();
      final uri = Uri.https('api.themoviedb.org', '/3/' + endpoint, params);
      final response = await http.get(uri, headers: {'Accept':'application/json'}).timeout(const Duration(seconds:20));
      if (response.statusCode != 200) throw Exception(response.statusCode == 401 ? 'مفتاح TMDB غير صحيح.' : 'تعذر جلب الفهرس (' + response.statusCode.toString() + ').');
      final root = jsonDecode(response.body) as Map<String, dynamic>;
      final raw = root['results'] as List<dynamic>? ?? const [];
      final fresh = raw.whereType<Map<String, dynamic>>().map((m) => _V22Title.fromJson(m, isMovie)).where((m) => m.id > 0).toList();
      if (!mounted) return;
      setState(() {
        if (reset) _items = fresh; else _items.addAll(fresh);
        _hasMore = _page < ((root['total_pages'] as num?)?.toInt() ?? 1) && fresh.isNotEmpty;
        _page++;
      });
    } catch (e) {
      if (mounted) setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally { if (mounted) setState(() => _loading = false); }
  }
  Future<void> _toggle(Set<int> set, int id, String key) async {
    setState(() { if (!set.add(id)) set.remove(id); });
    await _saveSet(key, set);
  }
  Future<void> _details(_V22Title item) async {
    List<Map<String, dynamic>> providers = [];
    String? providerLink;
    try {
      final path = '/3/' + (item.isMovie ? 'movie/' : 'tv/') + item.id.toString() + '/watch/providers';
      final r = await http.get(Uri.https('api.themoviedb.org', path, {'api_key':_apiKey}), headers: {'Accept':'application/json'}).timeout(const Duration(seconds:12));
      if (r.statusCode == 200) {
        final data = jsonDecode(r.body) as Map<String, dynamic>;
        final iq = (data['results'] as Map<String, dynamic>?)?['IQ'] as Map<String, dynamic>?;
        providerLink = iq?['link']?.toString();
        providers = (iq?['flatrate'] as List<dynamic>? ?? const []).whereType<Map<String, dynamic>>().toList();
      }
    } catch (_) {}
    if (!mounted) return;
    final safeProviderLink = providerLink;
    showModalBottomSheet<void>(context: context, isScrollControlled: true, showDragHandle: true, builder: (c) => Directionality(textDirection: TextDirection.rtl, child: Padding(
      padding: const EdgeInsets.fromLTRB(18,8,18,24),
      child: SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        Text(item.title, style: const TextStyle(fontSize:21,fontWeight:FontWeight.w900)),
        const SizedBox(height:6),
        Text(item.year + ' • ' + (item.isMovie ? 'فيلم' : 'مسلسل') + ' • ⭐ ' + item.rating.toStringAsFixed(1)),
        const SizedBox(height:12),
        Text(item.overview.isEmpty ? 'لا يتوفر ملخص عربي لهذا العنوان حالياً.' : item.overview, style: const TextStyle(height:1.6)),
        const SizedBox(height:12),
        const Text('المشاهدة والترجمة', style: TextStyle(fontWeight:FontWeight.w900)),
        const Text('تختلف الترجمة العربية حسب البلد والمنصة. هذه معلومات توفر رسمية عند إتاحتها من TMDB وليست ضماناً لوجود ترجمة.'),
        if (providers.isNotEmpty) Wrap(spacing:8,runSpacing:8,children:providers.map((p)=>Chip(label:Text((p['provider_name']??'').toString()))).toList())
        else const Text('لا تتوفر حالياً بيانات مزودي مشاهدة لهذا العنوان في العراق.'),
        const SizedBox(height:12),
        Wrap(spacing:8,children:[
          OutlinedButton.icon(onPressed:() async { await launchUrl(Uri.parse('https://www.themoviedb.org/' + (item.isMovie?'movie/':'tv/') + item.id.toString()),mode:LaunchMode.externalApplication); },icon:const Icon(Icons.info_outline),label:const Text('تفاصيل TMDB')),
          if (safeProviderLink != null && safeProviderLink.startsWith('https://')) FilledButton.icon(onPressed:() async { await launchUrl(Uri.parse(safeProviderLink),mode:LaunchMode.externalApplication); },icon:const Icon(Icons.ondemand_video),label:const Text('خيارات المشاهدة')),
          TextButton(onPressed:()=>Navigator.pop(c),child:const Text('إغلاق')),
        ]),
      ])),
    )));
  }
  @override
  Widget build(BuildContext context) => Directionality(textDirection:TextDirection.rtl,child:Scaffold(
    appBar:AppBar(title:const Text('مكتبة 2025 • 2026'),actions:[IconButton(tooltip:'إعداد مفتاح الفهرس',onPressed:_configureKey,icon:const Icon(Icons.key_rounded))]),
    body:Column(children:[
      Padding(padding:const EdgeInsets.fromLTRB(12,12,12,6),child:TextField(controller:_search,textInputAction:TextInputAction.search,onSubmitted:(_)=>_load(reset:true),decoration:InputDecoration(hintText:'ابحث عن فيلم أو مسلسل…',prefixIcon:const Icon(Icons.search),suffixIcon:IconButton(onPressed:(){_search.clear();_load(reset:true);},icon:const Icon(Icons.close)),border:OutlineInputBorder(borderRadius:BorderRadius.circular(14))))),
      SingleChildScrollView(scrollDirection:Axis.horizontal,padding:const EdgeInsets.symmetric(horizontal:12,vertical:6),child:Row(children:[
        ChoiceChip(label:const Text('2026'),selected:_year=='2026',onSelected:(_){setState(()=>_year='2026');_load(reset:true);}),
        const SizedBox(width:8),ChoiceChip(label:const Text('2025'),selected:_year=='2025',onSelected:(_){setState(()=>_year='2025');_load(reset:true);}),
        const SizedBox(width:12),ChoiceChip(label:const Text('أفلام'),selected:_kind=='movie',onSelected:(_){setState(()=>_kind='movie');_load(reset:true);}),
        const SizedBox(width:8),ChoiceChip(label:const Text('مسلسلات'),selected:_kind=='tv',onSelected:(_){setState(()=>_kind='tv');_load(reset:true);}),
      ])),
      SizedBox(height:46,child:ListView(scrollDirection:Axis.horizontal,padding:const EdgeInsets.symmetric(horizontal:12),children:_genres.keys.map((g)=>Padding(padding:const EdgeInsetsDirectional.only(end:7),child:ChoiceChip(label:Text(g),selected:_genre==g,onSelected:(_){setState(()=>_genre=g);_load(reset:true);}))).toList())),
      if (_error != null) Padding(padding:const EdgeInsets.all(12),child:Column(children:[Text(_error!,textAlign:TextAlign.center),if(_apiKey.isEmpty)TextButton.icon(onPressed:_configureKey,icon:const Icon(Icons.key),label:const Text('إعداد مفتاح TMDB')),if(_apiKey.isNotEmpty)TextButton(onPressed:()=>_load(reset:true),child:const Text('إعادة المحاولة'))])),
      Expanded(child:_items.isEmpty && _loading ? const Center(child:CircularProgressIndicator()) : _items.isEmpty ? const Center(child:Text('لا توجد نتائج بعد. أضف مفتاح الفهرس أو غيّر البحث.')) : NotificationListener<ScrollNotification>(
        onNotification:(n){if(n.metrics.pixels>=n.metrics.maxScrollExtent-240&&!_loading&&_hasMore)_load();return false;},
        child:GridView.builder(padding:const EdgeInsets.all(12),itemCount:_items.length+(_loading?1:0),gridDelegate:const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount:2,childAspectRatio:.59,crossAxisSpacing:10,mainAxisSpacing:10),itemBuilder:(context,i){
          if(i>=_items.length)return const Center(child:CircularProgressIndicator());
          final item=_items[i], poster=item.poster.isEmpty?null:'https://image.tmdb.org/t/p/w500'+item.poster;
          return Card(clipBehavior:Clip.antiAlias,child:InkWell(onTap:()=>_details(item),child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
            Expanded(child:poster==null?const ColoredBox(color:Color(0xFF28243A),child:Icon(Icons.movie,size:54,color:Colors.white54)):Image.network(poster,fit:BoxFit.cover,errorBuilder:(_,__,___)=>const ColoredBox(color:Color(0xFF28243A),child:Icon(Icons.broken_image,color:Colors.white54)))),
            Padding(padding:const EdgeInsets.fromLTRB(8,8,8,2),child:Text(item.title,maxLines:2,overflow:TextOverflow.ellipsis,style:const TextStyle(fontWeight:FontWeight.w900))),
            Padding(padding:const EdgeInsets.symmetric(horizontal:8),child:Text(item.year+' • ⭐ '+item.rating.toStringAsFixed(1),style:const TextStyle(fontSize:11,color:Colors.grey))),
            Row(mainAxisAlignment:MainAxisAlignment.spaceBetween,children:[
              IconButton(visualDensity:VisualDensity.compact,tooltip:'مفضلة',onPressed:()=>_toggle(_favorites,item.id,'v22_favorites'),icon:Icon(_favorites.contains(item.id)?Icons.favorite:Icons.favorite_border,color:Colors.pinkAccent)),
              IconButton(visualDensity:VisualDensity.compact,tooltip:'تمت المشاهدة',onPressed:()=>_toggle(_watched,item.id,'v22_watched'),icon:Icon(_watched.contains(item.id)?Icons.check_circle:Icons.check_circle_outline,color:Colors.green)),
            ]),
          ])));
        }),
      )),
      const Padding(padding:EdgeInsets.fromLTRB(12,4,12,10),child:Text('بيانات وصور TMDB مع الإسناد المطلوب. توفر المنصات والترجمة قد يختلف حسب البلد. لا نستضيف الأفلام أو نوفر روابط بث غير مرخصة.',textAlign:TextAlign.center,style:TextStyle(fontSize:10,color:Colors.grey))),
    ]),
  ));
}

class _V22Title {
  const _V22Title({required this.id,required this.title,required this.year,required this.overview,required this.poster,required this.rating,required this.isMovie});
  final int id;
  final String title,year,overview,poster;
  final double rating;
  final bool isMovie;
  factory _V22Title.fromJson(Map<String,dynamic> json,bool isMovie) {
    final date=(json[isMovie?'release_date':'first_air_date']??'').toString();
    return _V22Title(id:(json['id'] as num?)?.toInt()??0,title:(json[isMovie?'title':'name']??'بدون عنوان').toString(),year:date.length>=4?date.substring(0,4):'—',overview:(json['overview']??'').toString(),poster:(json['poster_path']??'').toString(),rating:(json['vote_average'] as num?)?.toDouble()??0,isMovie:isMovie);
  }
}
