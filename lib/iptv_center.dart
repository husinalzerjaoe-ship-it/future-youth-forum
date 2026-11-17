import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';
import 'watch_party.dart';
import 'iptv_epg.dart';

class IptvChannel {
  const IptvChannel({required this.name, required this.url, this.group='عام', this.logo='', this.tvgId='', this.source='', this.sourceUrl=''});
  final String name, url, group, logo, tvgId, source, sourceUrl;
  String get id => url;
  Map<String,dynamic> toJson() => {'name':name,'url':url,'group':group,'logo':logo,'tvgId':tvgId,'source':source,'sourceUrl':sourceUrl};
  factory IptvChannel.fromJson(Map<String,dynamic> j) => IptvChannel(name:j['name']?.toString()??'قناة',url:j['url']?.toString()??'',group:j['group']?.toString()??'عام',logo:j['logo']?.toString()??'',tvgId:j['tvgId']?.toString()??'',source:j['source']?.toString()??'',sourceUrl:j['sourceUrl']?.toString()??'');
}

class IptvPlaylistParser {
  static List<IptvChannel> parse(String text,{String source='',String sourceUrl='',Uri? baseUri}) {
    final result=<IptvChannel>[];
    String? name; var group='عام',logo='',tvgId='';
    final attr=RegExp(r'''([A-Za-z0-9_-]+)\s*=\s*["']([^"']*)["']''');
    for(final raw in const LineSplitter().convert(text)) {
      final line=raw.trim(); if(line.isEmpty) continue;
      if(line.startsWith('#EXTINF')) {
        final comma=line.indexOf(','), meta=comma<0?line:line.substring(0,comma);
        final values=<String,String>{};
        for(final m in attr.allMatches(meta)) { values[m.group(1)!.toLowerCase()]=m.group(2)!; }
        name=comma>=0&&comma+1<line.length?line.substring(comma+1).trim():(values['tvg-name']??'');
        group=(values['group-title']??'').trim(); if(group.isEmpty) group='عام';
        logo=values['tvg-logo']??''; tvgId=values['tvg-id']??'';
        if(name!.isEmpty) name=tvgId.isEmpty?'قناة':tvgId;
        continue;
      }
      if(line.startsWith('#')) continue;
      final parsed=Uri.tryParse(line); if(parsed==null) {name=null;continue;}
      final uri=parsed.hasScheme?parsed:(baseUri?.resolveUri(parsed)??parsed);
      if(!{'http','https'}.contains(uri.scheme)||uri.host.isEmpty) {name=null;continue;}
      result.add(IptvChannel(name:name==null||name!.isEmpty?uri.host:name!,url:uri.toString(),group:group,logo:logo,tvgId:tvgId,source:source,sourceUrl:sourceUrl));
      name=null; group='عام'; logo=''; tvgId='';
    }
    return result;
  }
}

class IptvCenterPage extends StatefulWidget {
  const IptvCenterPage({super.key});
  @override State<IptvCenterPage> createState()=>_IptvCenterPageState();
}
class _IptvCenterPageState extends State<IptvCenterPage> {
  static const _key='future_youth_iptv_channels_v1';
  static const _epgKey='future_youth_iptv_epg_v1';
  final _url=TextEditingController(),_name=TextEditingController(),_search=TextEditingController();
  final List<IptvChannel> _channels=[]; final Set<String> _favorites={};
  final List<IptvProgram> _programs=[];
  bool _loading=true,_busy=false; String _category='الكل',_query='';
  @override void initState(){super.initState();_load();}
  @override void dispose(){_url.dispose();_name.dispose();_search.dispose();super.dispose();}
  Future<void> _load() async {
    try { final p=await SharedPreferences.getInstance(),raw=p.getString(_key);
      if(raw!=null){final data=jsonDecode(raw);if(data is List)_channels.addAll(data.whereType<Map>().map((e)=>IptvChannel.fromJson(Map<String,dynamic>.from(e))));}
      _favorites.addAll(p.getStringList(_key+'_favorites')??const []);
      final epgRaw=p.getString(_epgKey);
      if(epgRaw!=null){final epgData=jsonDecode(epgRaw);if(epgData is List)_programs.addAll(epgData.whereType<Map>().map((e)=>IptvProgram.fromJson(Map<String,dynamic>.from(e))));}
    } catch(_){}
    if(mounted)setState(()=>_loading=false);
  }
  Future<void> _save() async {final p=await SharedPreferences.getInstance();await p.setString(_key,jsonEncode(_channels.map((e)=>e.toJson()).toList()));await p.setStringList(_key+'_favorites',_favorites.toList());await p.setString(_epgKey,jsonEncode(_programs.map((e)=>e.toJson()).toList()));}
  void _toast(String s){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(s)));}
  void _replace(String source,List<IptvChannel> items){_channels.removeWhere((e)=>e.source==source);_channels.addAll(items);_channels.sort((a,b)=>a.name.toLowerCase().compareTo(b.name.toLowerCase()));}
  Future<void> _addUrl() async {
    final uri=Uri.tryParse(_url.text.trim());
    if(uri==null||!{'http','https'}.contains(uri.scheme)||uri.host.isEmpty){_toast('أدخل رابط M3U صحيح يبدأ بـ http أو https.');return;}
    setState(()=>_busy=true);
    try{
      final response=await http.get(uri,headers:const {'Accept':'application/x-mpegURL, text/plain, */*'}).timeout(const Duration(seconds:25));
      if(response.statusCode!=200)throw Exception('استجابة المصدر '+response.statusCode.toString());
      if(response.bodyBytes.length>8*1024*1024)throw Exception('القائمة أكبر من 8 ميغابايت.');
      final source=_name.text.trim().isEmpty?uri.host:_name.text.trim();
      final items=IptvPlaylistParser.parse(utf8.decode(response.bodyBytes,allowMalformed:true),source:source,sourceUrl:uri.toString(),baseUri:uri);
      if(items.isEmpty)throw Exception('لم نعثر على قنوات صالحة.');
      _replace(source,items);await _save();_url.clear();_name.clear();_toast('تم استيراد '+items.length.toString()+' قناة.');
    }catch(e){_toast('تعذر استيراد القائمة: '+e.toString());}
    finally{if(mounted)setState(()=>_busy=false);}
  }
  Future<void> _importFile() async {
    try{
      final picked=await FilePicker.platform.pickFiles(type:FileType.custom,allowedExtensions:['m3u','m3u8','txt'],withData:true);
      if(picked==null||picked.files.isEmpty)return;
      final file=picked.files.first,bytes=picked.files.first.bytes;
      if(bytes==null){_toast('تعذر قراءة الملف.');return;}
      if(bytes.length>8*1024*1024){_toast('الملف أكبر من 8 ميغابايت.');return;}
      final items=IptvPlaylistParser.parse(utf8.decode(bytes,allowMalformed:true),source:file.name);
      if(items.isEmpty){_toast('الملف لا يحتوي قنوات M3U صالحة.');return;}
      _replace(file.name,items);await _save();_toast('تم استيراد '+items.length.toString()+' قناة من الملف.');
    }catch(e){_toast('تعذر استيراد الملف: '+e.toString());}
  }
  Future<void> _importEpg() async {
    try {
      final picked=await FilePicker.platform.pickFiles(type:FileType.custom,allowedExtensions:['xml','xmltv','txt'],withData:true);
      if(picked==null||picked.files.isEmpty)return;
      final bytes=picked.files.first.bytes;
      if(bytes==null){_toast('تعذر قراءة ملف دليل البرامج.');return;}
      if(bytes.length>8*1024*1024){_toast('ملف الدليل أكبر من 8 ميغابايت.');return;}
      final parsed=IptvEpgParser.parse(utf8.decode(bytes,allowMalformed:true));
      if(parsed.isEmpty){_toast('لم نعثر على برامج XMLTV صالحة.');return;}
      setState((){_programs..clear()..addAll(parsed);});
      await _save();
      _toast('تم استيراد دليل البرامج: '+parsed.length.toString()+' برنامج.');
    } catch(e){_toast('تعذر استيراد دليل البرامج: '+e.toString());}
  }
  Future<void> _showEpgGuide() async {
    final now=DateTime.now();
    await showModalBottomSheet<void>(context:context,isScrollControlled:true,showDragHandle:true,builder:(ctx)=>Directionality(textDirection:TextDirection.rtl,child:SafeArea(child:SizedBox(height:MediaQuery.of(ctx).size.height*.78,child:Column(children:[
      Padding(padding:const EdgeInsets.all(14),child:Row(children:[const Expanded(child:Text('دليل البرامج EPG',style:TextStyle(fontSize:20,fontWeight:FontWeight.w900))),TextButton.icon(onPressed:(){Navigator.pop(ctx);_importEpg();},icon:const Icon(Icons.file_upload_outlined),label:const Text('استيراد XMLTV'))])),
      Expanded(child:_programs.isEmpty?const Center(child:Text('استورد ملف XMLTV لعرض البرامج الحالية والقادمة.')):ListView.builder(itemCount:_channels.length,itemBuilder:(_,i){final c=_channels[i];final current=c.tvgId.isEmpty?null:IptvEpgParser.current(_programs,c.tvgId,now);final next=c.tvgId.isEmpty?null:IptvEpgParser.next(_programs,c.tvgId,now);return ListTile(leading:const Icon(Icons.live_tv),title:Text(c.name),subtitle:Text(current==null?'لا يوجد برنامج حالي':('الآن: '+current.title+' • '+TimeOfDay.fromDateTime(current.start.toLocal()).format(context)+' - '+TimeOfDay.fromDateTime(current.stop.toLocal()).format(context))+'\\n'+(next==null?'لا يوجد برنامج قادم':'التالي: '+next.title)),isThreeLine:true,onTap:(){Navigator.pop(ctx);Navigator.push(context,MaterialPageRoute(builder:(_)=>IptvPlayerPage(channel:c)));});})),
    ])))));
  }
  Future<void> _favorite(IptvChannel c) async {setState(()=>_favorites.contains(c.id)?_favorites.remove(c.id):_favorites.add(c.id));await _save();}
  Future<void> _removeSource(String source) async {
    final ids=_channels.where((e)=>e.source==source).map((e)=>e.id).toSet();
    setState((){_channels.removeWhere((e)=>e.source==source);_favorites.removeAll(ids);});await _save();_toast('تم حذف المصدر.');
  }
  List<String> get _categories=>['الكل','المفضلة',...(_channels.map((e)=>e.group).toSet().toList()..sort())];
  List<IptvChannel> get _visible=>_channels.where((c){
    final cat=_category=='الكل'||(_category=='المفضلة'?_favorites.contains(c.id):c.group==_category),q=_query.trim().toLowerCase();
    return cat&&(q.isEmpty||c.name.toLowerCase().contains(q)||c.group.toLowerCase().contains(q)||c.source.toLowerCase().contains(q));
  }).toList();

  @override Widget build(BuildContext context){
    final visible=_visible;
    return Directionality(textDirection:TextDirection.rtl,child:Scaffold(
      appBar:AppBar(title:const Text('مركز التلفزيون وIPTV'),actions:[
        IconButton(tooltip:'تحديث المصادر',onPressed:_busy?null:_refreshAllSources,icon:const Icon(Icons.refresh_rounded)),
        IconButton(tooltip:'دليل البرامج',onPressed:_showEpgGuide,icon:const Icon(Icons.calendar_month_rounded)),
        IconButton(tooltip:'استيراد دليل XMLTV',onPressed:_importEpg,icon:const Icon(Icons.event_available_rounded)),
        IconButton(tooltip:'إدارة المصادر',onPressed:_manageSources,icon:const Icon(Icons.playlist_add_check)),
        IconButton(tooltip:'استيراد ملف',onPressed:_busy?null:_importFile,icon:const Icon(Icons.file_open)),
      ]),
      body:_loading?const Center(child:CircularProgressIndicator()):ListView(padding:const EdgeInsets.all(14),children:[
        _hero(),const SizedBox(height:12),
        Card(child:Padding(padding:const EdgeInsets.all(14),child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
          const Text('إضافة قائمة من رابط',style:TextStyle(fontWeight:FontWeight.w900)),const SizedBox(height:8),
          TextField(controller:_name,decoration:const InputDecoration(labelText:'اسم القائمة (اختياري)',border:OutlineInputBorder())),
          const SizedBox(height:8),
          TextField(controller:_url,keyboardType:TextInputType.url,decoration:const InputDecoration(labelText:'رابط M3U / M3U8',hintText:'https://example.com/list.m3u',border:OutlineInputBorder())),
          const SizedBox(height:9),
          FilledButton.icon(onPressed:_busy?null:_addUrl,icon:_busy?const SizedBox(width:18,height:18,child:CircularProgressIndicator(strokeWidth:2)):const Icon(Icons.playlist_add),label:Text(_busy?'جاري الاستيراد...':'استيراد القنوات')),
          TextButton.icon(onPressed:_busy?null:_importFile,icon:const Icon(Icons.folder_open),label:const Text('اختيار ملف M3U من الجهاز')),
        ]))),
        const SizedBox(height:10),
        TextField(controller:_search,onChanged:(v)=>setState(()=>_query=v),decoration:InputDecoration(hintText:'ابحث عن قناة أو تصنيف...',prefixIcon:const Icon(Icons.search),suffixIcon:_query.isEmpty?null:IconButton(onPressed:(){_search.clear();setState(()=>_query='');},icon:const Icon(Icons.close)),border:OutlineInputBorder(borderRadius:BorderRadius.circular(14)))),
        const SizedBox(height:9),
        SizedBox(height:42,child:ListView.separated(scrollDirection:Axis.horizontal,itemCount:_categories.length,separatorBuilder:(_,__)=>const SizedBox(width:7),itemBuilder:(_,i)=>ChoiceChip(label:Text(_categories[i]),selected:_category==_categories[i],onSelected:(_)=>setState(()=>_category=_categories[i])))),
        const SizedBox(height:12),
        Row(children:[Expanded(child:Text('القنوات ('+visible.length.toString()+')',style:const TextStyle(fontSize:18,fontWeight:FontWeight.w900))),TextButton(onPressed:_manageSources,child:const Text('المصادر'))]),
        if(visible.isEmpty)const Card(child:Padding(padding:EdgeInsets.all(24),child:Column(children:[Icon(Icons.live_tv_outlined,size:44,color:Colors.grey),SizedBox(height:8),Text('ماكو قنوات مضافة حالياً',style:TextStyle(fontWeight:FontWeight.bold)),Text('أضف قائمة تملك حق استخدامها أو استورد ملف M3U.',textAlign:TextAlign.center,style:TextStyle(color:Colors.grey))]))) else ...visible.take(250).map(_channelTile),
        if(visible.length>250)const Text('نعرض أول 250 قناة للمحافظة على سرعة الصفحة. استخدم البحث للتصفية.'),
      ]),
    ));
  }
  Future<void> _openWatchParty([IptvChannel? channel]) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => WatchPartyLobbyPage(
      initialUrl: channel?.url,
      initialName: channel == null ? 'غرفة IPTV جماعية' : 'مشاهدة ${channel.name}',
      forceDirect: channel != null,
    )));
  }

  Widget _hero()=>Container(padding:const EdgeInsets.all(17),decoration:BoxDecoration(borderRadius:BorderRadius.circular(21),gradient:const LinearGradient(begin:Alignment.topRight,end:Alignment.bottomLeft,colors:[Color(0xFF4B3D9B),Color(0xFF1B2945),Color(0xFF123A46)])),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
    const Icon(Icons.live_tv,color:Color(0xFFE4DEFF),size:32),const SizedBox(height:8),
    const Text('شاهد قنواتك بمكان واحد',style:TextStyle(color:Colors.white,fontSize:20,fontWeight:FontWeight.w900)),
    const SizedBox(height:5),const Text('استيراد M3U وM3U8، تصنيفات، بحث ومفضلة.',style:TextStyle(color:Colors.white70)),
    const SizedBox(height:10),Text(_channels.length.toString()+' قناة • '+_channels.map((e)=>e.source).toSet().length.toString()+' مصدر • '+_favorites.length.toString()+' مفضلة',style:const TextStyle(color:Colors.white)),
    const SizedBox(height:12),Wrap(spacing:8,runSpacing:8,children:[FilledButton.icon(onPressed:()=>_openWatchParty(),icon:const Icon(Icons.groups_rounded),label:const Text('غرف مشاهدة IPTV مع الأصدقاء')),OutlinedButton.icon(onPressed:_showEpgGuide,icon:const Icon(Icons.calendar_month),label:Text('دليل البرامج ('+_programs.length.toString()+')'))]), 
  ]));
  Widget _channelTile(IptvChannel c)=>Card(margin:const EdgeInsets.only(bottom:7),child:ListTile(
    leading:ClipRRect(borderRadius:BorderRadius.circular(9),child:Container(width:46,height:46,color:Theme.of(context).colorScheme.surfaceContainerHighest,padding:const EdgeInsets.all(5),child:c.logo.startsWith('https://')?Image.network(c.logo,fit:BoxFit.contain,errorBuilder:(_,__,___)=>const Icon(Icons.tv)):const Icon(Icons.tv))),
    title:Text(c.name,maxLines:1,overflow:TextOverflow.ellipsis,style:const TextStyle(fontWeight:FontWeight.w800)),
    subtitle:Text(c.group+' • '+c.source,maxLines:1,overflow:TextOverflow.ellipsis),
    trailing:Wrap(children:[
      IconButton(tooltip:'شاهد مع الأصدقاء',onPressed:()=>_openWatchParty(c),icon:const Icon(Icons.groups_rounded)),
      IconButton(tooltip:'المفضلة',onPressed:()=>_favorite(c),icon:Icon(_favorites.contains(c.id)?Icons.favorite:Icons.favorite_border,color:_favorites.contains(c.id)?Colors.redAccent:null)),
    ]),
    onTap:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>IptvPlayerPage(channel:c))),
  ));
  Future<void> _refreshSource(String source) async {
    final old = _channels.where((e) => e.source == source).toList();
    if (old.isEmpty || old.first.sourceUrl.isEmpty) { _toast('هذا المصدر ملف محلي ولا يملك رابط تحديث.'); return; }
    final uri = Uri.tryParse(old.first.sourceUrl);
    if (uri == null || !{'http','https'}.contains(uri.scheme)) { _toast('رابط تحديث المصدر غير صالح.'); return; }
    setState(() => _busy = true);
    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 25));
      if (response.statusCode != 200) throw Exception('HTTP '+response.statusCode.toString());
      if (response.bodyBytes.length > 8*1024*1024) throw Exception('القائمة أكبر من 8 ميغابايت.');
      final items = IptvPlaylistParser.parse(utf8.decode(response.bodyBytes,allowMalformed:true),source:source,sourceUrl:uri.toString(),baseUri:uri);
      if (items.isEmpty) throw Exception('القائمة لا تحتوي قنوات صالحة.');
      _replace(source,items); await _save(); _toast('تم تحديث '+items.length.toString()+' قناة.');
    } catch(e) { _toast('فشل تحديث المصدر: '+e.toString()); }
    finally { if(mounted) setState(() => _busy = false); }
  }
  Future<void> _refreshAllSources() async {
    final sources = _channels.where((e)=>e.sourceUrl.isNotEmpty).map((e)=>e.source).toSet().toList();
    if(sources.isEmpty){_toast('لا توجد قوائم روابط لتحديثها.');return;}
    for(final source in sources){if(!mounted)return;await _refreshSource(source);}
  }
  Future<void> _manageSources() async {
    final sources=_channels.map((e)=>e.source).toSet().toList()..sort();
    if(sources.isEmpty){_toast('ماكو مصادر محفوظة بعد.');return;}
    await showModalBottomSheet<void>(context:context,isScrollControlled:true,builder:(ctx)=>Directionality(textDirection:TextDirection.rtl,child:SafeArea(child:ListView(shrinkWrap:true,padding:const EdgeInsets.all(14),children:[
      const Text('مصادرك المحفوظة',style:TextStyle(fontSize:19,fontWeight:FontWeight.w900)),
      ...sources.map((s)=>ListTile(leading:const Icon(Icons.playlist_play),title:Text(s),subtitle:Text(_channels.where((e)=>e.source==s).length.toString()+' قناة'),trailing:Wrap(spacing:0,children:[if(_channels.any((e)=>e.source==s&&e.sourceUrl.isNotEmpty))IconButton(tooltip:'تحديث القائمة',icon:const Icon(Icons.refresh),onPressed:(){Navigator.pop(ctx);_refreshSource(s);}),IconButton(icon:const Icon(Icons.delete_outline),onPressed:(){Navigator.pop(ctx);_removeSource(s);})]))),
    ]))));
  }
}

class IptvPlayerPage extends StatefulWidget {
  const IptvPlayerPage({super.key,required this.channel});
  final IptvChannel channel;
  @override State<IptvPlayerPage> createState()=>_IptvPlayerPageState();
}
class _IptvPlayerPageState extends State<IptvPlayerPage> {
  VideoPlayerController? _player; bool _loading=true; String? _error;
  @override void initState(){super.initState();_initialize();}
  Future<void> _initialize() async {
    final old=_player;_player=null;await old?.dispose();if(!mounted)return;
    setState(() { _loading = true; _error = null; });
    try{
      final uri=Uri.parse(widget.channel.url);
      if(!{'http','https'}.contains(uri.scheme)||uri.host.isEmpty)throw const FormatException();
      final p=VideoPlayerController.networkUrl(uri,httpHeaders:const {'User-Agent':'FutureYouthForum/1.0'});
      _player=p;await p.initialize().timeout(const Duration(seconds:30));if(!mounted)return;await p.play();setState(()=>_loading=false);
    }catch(_){if(mounted)setState(() { _loading = false; _error = 'تعذر تشغيل القناة. قد يكون الرابط متوقفاً أو يحتاج صلاحية أو صيغة غير مدعومة.'; });}
  }
  @override void dispose(){_player?.dispose();super.dispose();}
  String _time(Duration d)=>d.inMinutes.toString().padLeft(2,'0')+':'+(d.inSeconds%60).toString().padLeft(2,'0');
  @override Widget build(BuildContext context){
    final p=_player;
    return Directionality(textDirection:TextDirection.rtl,child:Scaffold(backgroundColor:Colors.black,appBar:AppBar(backgroundColor:Colors.black,title:Text(widget.channel.name,maxLines:1,overflow:TextOverflow.ellipsis),actions:[IconButton(tooltip:'شاهد مع الأصدقاء',onPressed:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>WatchPartyLobbyPage(initialUrl:widget.channel.url,initialName:'مشاهدة ${widget.channel.name}',forceDirect:true))),icon:const Icon(Icons.groups_rounded))]),body:Column(children:[
      Expanded(child:Center(child:_loading?const CircularProgressIndicator(color:Colors.white):_error!=null||p==null||!p.value.isInitialized
        ?Padding(padding:const EdgeInsets.all(24),child:Column(mainAxisSize:MainAxisSize.min,children:[const Icon(Icons.live_tv,color:Colors.white70,size:48),const SizedBox(height:10),Text(_error??'تعذر تشغيل القناة.',textAlign:TextAlign.center,style:const TextStyle(color:Colors.white)),const SizedBox(height:12),FilledButton.icon(onPressed:_initialize,icon:const Icon(Icons.refresh),label:const Text('إعادة المحاولة'))]))
        :AspectRatio(aspectRatio:p.value.aspectRatio>0?p.value.aspectRatio:16/9,child:Stack(fit:StackFit.expand,children:[
          VideoPlayer(p),
          Center(child:ValueListenableBuilder<VideoPlayerValue>(valueListenable:p,builder:(_,v,__)=>IconButton.filledTonal(iconSize:48,onPressed:()async{v.isPlaying?await p.pause():await p.play();if(mounted)setState((){});},icon:Icon(v.isPlaying?Icons.pause_rounded:Icons.play_arrow_rounded)))),
          Align(alignment:Alignment.bottomCenter,child:Padding(padding:const EdgeInsets.all(8),child:VideoProgressIndicator(p,allowScrubbing:true))),
        ])))),
      if(p!=null&&p.value.isInitialized)Padding(padding:const EdgeInsets.fromLTRB(12,5,12,14),child:Row(children:[
        const Icon(Icons.live_tv,color:Colors.white70),const SizedBox(width:7),Expanded(child:Text(widget.channel.group,style:const TextStyle(color:Colors.white70))),
        ValueListenableBuilder<VideoPlayerValue>(valueListenable:p,builder:(_,v,__)=>Text(v.duration==Duration.zero?'بث مباشر':_time(v.position)+' / '+_time(v.duration),style:const TextStyle(color:Colors.white70,fontSize:12))),
        IconButton(tooltip:'إعادة الاتصال',onPressed:_initialize,icon:const Icon(Icons.refresh,color:Colors.white)),
      ])),
    ])));
  }
}
