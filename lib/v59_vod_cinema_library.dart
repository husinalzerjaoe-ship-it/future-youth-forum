import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';
import 'watch_party.dart';

const _vodSecure = FlutterSecureStorage();
const _vodKey = 'v59_vod_sources';

class _Source {
  _Source(this.id,this.name,this.kind,this.url,{this.username='' });
  final String id,name,kind,url,username;
  Map<String,dynamic> json()=>{'id':id,'name':name,'kind':kind,'url':url,'username':username};
  factory _Source.from(Map<String,dynamic> j)=>_Source((j['id']??'').toString(),(j['name']??'مصدر').toString(),(j['kind']??'url').toString(),(j['url']??'').toString(),username:(j['username']??'').toString());
}
class _Entry {
  _Entry(this.id,this.title,this.kind,this.url,{this.poster='',this.plot='',this.seriesId='',this.category=''});
  final String id,title,kind,url,poster,plot,seriesId,category;
}

class VodCinemaLibraryPage extends StatefulWidget {
  const VodCinemaLibraryPage({super.key});
  @override State<VodCinemaLibraryPage> createState()=>_VodCinemaLibraryPageState();
}
class _VodCinemaLibraryPageState extends State<VodCinemaLibraryPage> {
  final _name=TextEditingController(),_host=TextEditingController(),_user=TextEditingController(),_pass=TextEditingController(),_url=TextEditingController(),_search=TextEditingController();
  final List<_Source> _sources=[];
  final List<_Entry> _entries=[];
  final Set<String> _favorites={};
  String _tab='الكل',_active='',_error='';
  bool _busy=false;

  @override void initState(){super.initState();_restore();}
  @override void dispose(){_name.dispose();_host.dispose();_user.dispose();_pass.dispose();_url.dispose();_search.dispose();super.dispose();}
  void _msg(String s){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(s)));}
  Future<void> _restore()async{
    final p=await SharedPreferences.getInstance();
    try{final raw=jsonDecode(p.getString(_vodKey)??'[]');if(raw is List)_sources.addAll(raw.whereType<Map>().map((x)=>_Source.from(Map<String,dynamic>.from(x))));_favorites.addAll(p.getStringList(_vodKey+'_fav')??const []);}catch(_){}
    if(mounted)setState((){});
    if(_sources.isNotEmpty)_load(_sources.first);
  }
  Future<void> _save()async{final p=await SharedPreferences.getInstance();await p.setString(_vodKey,jsonEncode(_sources.map((s)=>s.json()).toList()));await p.setStringList(_vodKey+'_fav',_favorites.toList());}
  Uri _api(_Source s,String pw,String action,{String? series})=>Uri.parse(s.url.replaceFirst(RegExp(r'/+$'),'')+'/player_api.php').replace(queryParameters:{'username':s.username,'password':pw,'action':action,if(series!=null)'series_id':series});
  Future<dynamic> _get(Uri u)async{final r=await http.get(u).timeout(const Duration(seconds:30));if(r.statusCode!=200)throw Exception('HTTP '+r.statusCode.toString());return jsonDecode(utf8.decode(r.bodyBytes,allowMalformed:true));}
  Future<List<_Entry>> _xtream(_Source s,String pw)async{
    final out=<_Entry>[];
    final movies=await _get(_api(s,pw,'get_vod_streams'));
    if(movies is List)for(final x in movies.whereType<Map>()){
      final id=(x['stream_id']??'').toString(),ext=(x['container_extension']??'mp4').toString();if(id.isEmpty)continue;
      out.add(_Entry(s.id+'|'+id,(x['name']??'فيلم').toString(),'movie',s.url.replaceFirst(RegExp(r'/+$'),'')+'/movie/'+s.username+'/'+pw+'/'+id+'.'+ext,poster:(x['stream_icon']??'').toString(),plot:(x['plot']??'').toString(),category:(x['category_name']??'').toString()));
    }
    final shows=await _get(_api(s,pw,'get_series'));
    if(shows is List)for(final x in shows.whereType<Map>()){
      final id=(x['series_id']??'').toString();if(id.isEmpty)continue;final cat=(x['category_name']??'').toString();
      out.add(_Entry(s.id+'|series|'+id,(x['name']??'مسلسل').toString(),RegExp(r'anime|انمي',caseSensitive:false).hasMatch(cat)?'anime':'series','',poster:(x['cover']??'').toString(),plot:(x['plot']??'').toString(),seriesId:id,category:cat));
    }
    return out;
  }
  Future<List<_Entry>> _episodes(_Source s,String pw,String id)async{
    final data=await _get(_api(s,pw,'get_series_info',series:id));
    if(data is! Map||data['episodes'] is! Map)throw Exception('المصدر لا يعرض حلقات لهذا المسلسل');
    final out=<_Entry>[];
    (data['episodes'] as Map).forEach((season,rows){if(rows is List)for(final e in rows.whereType<Map>()){
      final eid=(e['id']??e['episode_id']??'').toString(),ext=(e['container_extension']??'mp4').toString();if(eid.isEmpty)continue;
      out.add(_Entry(eid,'موسم '+season.toString()+' • '+(e['title']??'حلقة').toString(),'episode',s.url.replaceFirst(RegExp(r'/+$'),'')+'/series/'+s.username+'/'+pw+'/'+eid+'.'+ext,category:'الموسم '+season.toString()));
    }});
    return out;
  }
  Future<List<_Entry>> _urlCatalog(String url)async{
    final u=Uri.tryParse(url);if(u==null||!{'http','https'}.contains(u.scheme)||u.host.isEmpty)throw Exception('الرابط غير صالح');
    final r=await http.get(u,headers:const {'Accept':'application/json, text/plain, application/x-mpegURL, */*'}).timeout(const Duration(seconds:30));
    if(r.statusCode!=200)throw Exception('HTTP '+r.statusCode.toString());
    final body=utf8.decode(r.bodyBytes,allowMalformed:true);
    if(body.trimLeft().startsWith('{')||body.trimLeft().startsWith('[')){
      final j=jsonDecode(body),rows=j is List?j:(j is Map?(j['items']??j['results']??j['data']??[]):[]);
      if(rows is! List)throw Exception('JSON غير مدعوم');
      return rows.whereType<Map>().map((x){final link=(x['url']??x['stream_url']??x['link']??'').toString(),type=(x['type']??'movie').toString().toLowerCase();return _Entry(link,(x['title']??x['name']??'عمل').toString(),type.contains('anime')?'anime':type.contains('series')?'series':'movie',link,poster:(x['poster']??x['image']??x['cover']??'').toString(),plot:(x['description']??x['plot']??'').toString(),category:(x['category']??'').toString());}).where((e)=>e.url.startsWith('http')).toList();
    }
    if(body.contains('#EXTM3U')){
      final out=<_Entry>[];var title='فيديو',group='',poster='';
      for(final raw in const LineSplitter().convert(body)){final line=raw.trim();if(line.startsWith('#EXTINF')){final i=line.lastIndexOf(',');title=i<0?'فيديو':line.substring(i+1).trim();poster=RegExp('tvg-logo=["'+"'"+']([^"'+"'"+']+)').firstMatch(line)?.group(1)??'';group=RegExp('group-title=["'+"'"+']([^"'+"'"+']+)').firstMatch(line)?.group(1)??'';}else if(line.startsWith('http')){final t=(group+' '+title).toLowerCase();out.add(_Entry(line,title,RegExp(r'anime|انمي').hasMatch(t)?'anime':RegExp(r'series|مسلسل|حلقة').hasMatch(t)?'series':'movie',line,poster:poster,category:group));}}
      return out;
    }
    if(RegExp(r'\.(mp4|m3u8|m4v|webm)(\?|$)',caseSensitive:false).hasMatch(u.path))return [_Entry(url,u.pathSegments.isEmpty?'فيديو':u.pathSegments.last,'movie',url)];
    throw Exception('الرابط ليس JSON أو M3U أو فيديو مباشراً مدعوماً');
  }
  Future<void> _load(_Source s)async{
    if(_busy)return;setState(()=>_busy=true);_active=s.id;_error='';
    try{List<_Entry> data;if(s.kind=='xtream'){final pw=await _vodSecure.read(key:'v59_pw_'+s.id);if(pw==null||pw.isEmpty)throw Exception('أعد إضافة كلمة مرور المصدر');data=await _xtream(s,pw);}else{data=await _urlCatalog(s.url);}
      if(mounted)setState(()=>_entries..removeWhere((e)=>e.id.startsWith(s.id+'|'))..addAll(data));
    }catch(e){if(mounted)setState(()=>_error=e.toString().replaceFirst('Exception: ',''));}finally{if(mounted)setState(()=>_busy=false);}
  }
  Future<void> _addXtream()async{
    _name.clear();_host.clear();_user.clear();_pass.clear();
    final ok=await showDialog<bool>(context:context,builder:(c)=>Directionality(textDirection:TextDirection.rtl,child:AlertDialog(title:const Text('إضافة Xtream Codes'),content:SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min,children:[
      TextField(controller:_name,decoration:const InputDecoration(labelText:'اسم المصدر')),
      TextField(controller:_host,decoration:const InputDecoration(labelText:'رابط الخادم')),
      TextField(controller:_user,decoration:const InputDecoration(labelText:'اسم المستخدم')),
      TextField(controller:_pass,obscureText:true,decoration:const InputDecoration(labelText:'كلمة المرور')),
      const Text('استخدم بيانات مصدر مصرح لك به. كلمة المرور تحفظ محلياً بتخزين آمن.',style:TextStyle(fontSize:12))])),
      actions:[TextButton(onPressed:()=>Navigator.pop(c,false),child:const Text('إلغاء')),FilledButton(onPressed:()=>Navigator.pop(c,true),child:const Text('إضافة'))])));
    if(ok!=true)return;final u=Uri.tryParse(_host.text.trim());if(u==null||!{'http','https'}.contains(u.scheme)||u.host.isEmpty||_user.text.trim().isEmpty||_pass.text.isEmpty){_msg('أكمل بيانات المصدر');return;}
    final id=DateTime.now().microsecondsSinceEpoch.toString(),s=_Source(id,_name.text.trim().isEmpty?'Xtream':_name.text.trim(),'xtream',_host.text.trim(),username:_user.text.trim());
    await _vodSecure.write(key:'v59_pw_'+id,value:_pass.text);_sources.add(s);await _save();if(mounted)setState((){});await _load(s);
  }
  Future<void> _addUrl()async{
    _name.clear();_url.clear();final ok=await showDialog<bool>(context:context,builder:(c)=>Directionality(textDirection:TextDirection.rtl,child:AlertDialog(title:const Text('إضافة رابط كتالوج'),content:Column(mainAxisSize:MainAxisSize.min,children:[TextField(controller:_name,decoration:const InputDecoration(labelText:'اسم المصدر')),TextField(controller:_url,decoration:const InputDecoration(labelText:'رابط M3U / JSON / فيديو'))]),actions:[TextButton(onPressed:()=>Navigator.pop(c,false),child:const Text('إلغاء')),FilledButton(onPressed:()=>Navigator.pop(c,true),child:const Text('استيراد'))])));
    if(ok!=true)return;final u=Uri.tryParse(_url.text.trim());if(u==null||!{'http','https'}.contains(u.scheme)||u.host.isEmpty){_msg('رابط غير صالح');return;}
    final id=DateTime.now().microsecondsSinceEpoch.toString(),s=_Source(id,_name.text.trim().isEmpty?u.host:_name.text.trim(),'url',_url.text.trim());_sources.add(s);await _save();if(mounted)setState((){});await _load(s);
  }
  Future<void> _episodesFor(_Entry e)async{
    final sid=e.id.split('|').first,source=_sources.where((x)=>x.id==sid).firstOrNull;if(source==null||source.kind!='xtream'){_msg('هذا المصدر لا يوفر معلومات الحلقات');return;}
    final pw=await _vodSecure.read(key:'v59_pw_'+sid);if(pw==null)return;setState(()=>_busy=true);
    try{final list=await _episodes(source,pw,e.seriesId);if(!mounted)return;await showModalBottomSheet<void>(context:context,isScrollControlled:true,builder:(c)=>Directionality(textDirection:TextDirection.rtl,child:SizedBox(height:MediaQuery.of(c).size.height*.75,child:ListView(children:[Padding(padding:const EdgeInsets.all(15),child:Text('حلقات '+e.title,style:const TextStyle(fontWeight:FontWeight.bold))),...list.map((x)=>ListTile(title:Text(x.title),onTap:(){Navigator.pop(c);_play(x,e.title+' — '+x.title);} ))]))));}catch(x){_msg(x.toString());}finally{if(mounted)setState(()=>_busy=false);}
  }
  Future<void> _play(_Entry e,[String? title])async{if(e.kind=='series'||e.kind=='anime'||e.url.isEmpty){await _episodesFor(e);return;}await Navigator.push(context,MaterialPageRoute(builder:(_)=>_VodPlayer(url:e.url,title:title??e.title)));}
  List<_Entry> get _visible{final q=_search.text.toLowerCase().trim();return _entries.where((e){final match=_tab=='الأفلام'?e.kind=='movie':_tab=='المسلسلات'?e.kind=='series':_tab=='الأنمي'?e.kind=='anime':_tab=='المفضلة'?_favorites.contains(e.id):true;return match&&(q.isEmpty|| (e.title+' '+e.category).toLowerCase().contains(q));}).toList();}
  @override Widget build(BuildContext context){final list=_visible;return Directionality(textDirection:TextDirection.rtl,child:Scaffold(
    appBar:AppBar(title:const Text('مكتبة الأفلام والمسلسلات المتزامنة'),actions:[PopupMenuButton<String>(onSelected:(v){if(v=='x')_addXtream();if(v=='u')_addUrl();if(v=='m')_manage();},itemBuilder:(_)=>const [PopupMenuItem(value:'x',child:Text('إضافة Xtream')),PopupMenuItem(value:'u',child:Text('إضافة رابط')),PopupMenuItem(value:'m',child:Text('إدارة المصادر'))])]),
    body:ListView(padding:const EdgeInsets.all(14),children:[
      Container(padding:const EdgeInsets.all(18),decoration:BoxDecoration(borderRadius:BorderRadius.circular(20),gradient:const LinearGradient(colors:[Color(0xFF32245F),Color(0xFF171936),Color(0xFF12495C)])),child:const Text('أفلام • مسلسلات • أنمي • مواسم وحلقات • مشاهدة جماعية',style:TextStyle(color:Colors.white,fontSize:18,fontWeight:FontWeight.bold))),
      Row(children:[Expanded(child:OutlinedButton(onPressed:_addXtream,child:const Text('Xtream Codes'))),const SizedBox(width:8),Expanded(child:FilledButton(onPressed:_addUrl,child:const Text('إضافة رابط')))]),
      if(_sources.isNotEmpty)SizedBox(height:45,child:ListView(scrollDirection:Axis.horizontal,children:_sources.map((s)=>Padding(padding:const EdgeInsetsDirectional.only(end:6),child:ChoiceChip(label:Text(s.name),selected:_active==s.id,onSelected:(_)=>_load(s)))).toList())),
      TextField(controller:_search,onChanged:(_)=>setState((){}),decoration:const InputDecoration(prefixIcon:Icon(Icons.search),hintText:'ابحث عن عمل')),
      Wrap(spacing:5,children:['الكل','الأفلام','المسلسلات','الأنمي','المفضلة'].map((t)=>ChoiceChip(label:Text(t),selected:_tab==t,onSelected:(_)=>setState(()=>_tab=t))).toList()),
      if(_busy)const Center(child:CircularProgressIndicator()),if(_error.isNotEmpty)Text(_error,style:const TextStyle(color:Colors.orange)),
      if(list.isEmpty&&!_busy)const Padding(padding:EdgeInsets.all(25),child:Text('أضف مصدراً حتى تظهر الأعمال هنا.')),
      if(list.isNotEmpty)GridView.builder(shrinkWrap:true,physics:const NeverScrollableScrollPhysics(),itemCount:list.length,gridDelegate:const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount:2,childAspectRatio:.7,crossAxisSpacing:8,mainAxisSpacing:8),itemBuilder:(_,i){final e=list[i];return Card(clipBehavior:Clip.antiAlias,child:InkWell(onTap:()=>_play(e),child:Column(children:[Expanded(child:e.poster.startsWith('http')?Image.network(e.poster,fit:BoxFit.cover,errorBuilder:(_,__,___)=>const Icon(Icons.movie)):const Icon(Icons.movie,size:42)),Padding(padding:const EdgeInsets.all(8),child:Text(e.title,maxLines:2,overflow:TextOverflow.ellipsis)),IconButton(onPressed:(){setState(()=>_favorites.contains(e.id)?_favorites.remove(e.id):_favorites.add(e.id));_save();},icon:Icon(_favorites.contains(e.id)?Icons.favorite:Icons.favorite_border))])));})
    ])));
  }
  Future<void> _manage()async{await showModalBottomSheet<void>(context:context,builder:(c)=>Directionality(textDirection:TextDirection.rtl,child:ListView(shrinkWrap:true,children:[const ListTile(title:Text('مصادر المكتبة')),..._sources.map((s)=>ListTile(title:Text(s.name),trailing:IconButton(icon:const Icon(Icons.delete_outline),onPressed:()async{_sources.remove(s);_entries.removeWhere((e)=>e.id.startsWith(s.id+'|'));await _vodSecure.delete(key:'v59_pw_'+s.id);await _save();if(c.mounted)Navigator.pop(c);if(mounted)setState((){});}))) ])));}
}

class _VodPlayer extends StatefulWidget{const _VodPlayer({required this.url,required this.title});final String url,title;@override State<_VodPlayer> createState()=>_VodPlayerState();}
class _VodPlayerState extends State<_VodPlayer>{
  VideoPlayerController? _c;String? _error;
  @override void initState(){super.initState();_init();}
  Future<void> _init()async{try{final c=VideoPlayerController.networkUrl(Uri.parse(widget.url));_c=c;await c.initialize().timeout(const Duration(seconds:35));await c.play();if(mounted)setState((){});}catch(e){if(mounted)setState(()=>_error=e.toString());}}
  @override void dispose(){_c?.dispose();super.dispose();}
  @override Widget build(BuildContext context)=>Directionality(textDirection:TextDirection.rtl,child:Scaffold(appBar:AppBar(title:Text(widget.title)),body:ListView(padding:const EdgeInsets.all(14),children:[
    AspectRatio(aspectRatio:16/9,child:ColoredBox(color:Colors.black,child:Center(child:_c?.value.isInitialized==true?AspectRatio(aspectRatio:_c!.value.aspectRatio,child:VideoPlayer(_c!)):Text(_error??'جاري التحميل',style:const TextStyle(color:Colors.white))))),
    if(_c?.value.isInitialized==true)VideoProgressIndicator(_c!,allowScrubbing:true),
    if(_c?.value.isInitialized==true)IconButton(onPressed:()=>setState(()=>_c!.value.isPlaying?_c!.pause():_c!.play()),icon:Icon(_c!.value.isPlaying?Icons.pause:Icons.play_arrow)),
    FilledButton.icon(onPressed:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>WatchPartyLobbyPage(initialUrl:widget.url,initialName:widget.title,cinemaMode:true,forceDirect:true))),icon:const Icon(Icons.groups),label:const Text('شاهد مع أصدقائك بمزامنة')),
    const Text('قد تختلف قابلية التشغيل والمزامنة حسب صيغة المصدر والحماية المستخدمة.',style:TextStyle(fontSize:12,color:Colors.grey))
  ])));
}
