import 'dart:convert';
import 'dart:async';
import 'package:crypto/crypto.dart' as crypto;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
  // Allow larger M3U/M3U8 playlists while keeping memory use bounded.
  static const int _maxPlaylistBytes = 64 * 1024 * 1024;
  static const _key='future_youth_iptv_channels_v1';
  static const _epgKey='future_youth_iptv_epg_v1';
  static const _hiddenSharedKey='future_youth_iptv_hidden_shared_channels_v1';
  final _url=TextEditingController(),_name=TextEditingController(),_search=TextEditingController(),_epgUrl=TextEditingController();
  final List<IptvChannel> _channels=[]; final List<IptvChannel> _sharedChannels=[]; final Set<String> _favorites={};
  final Set<String> _hiddenSharedChannels={};
  bool _publishToMembers=false;
  bool get _isFounder => FirebaseAuth.instance.currentUser?.email?.toLowerCase() == 'husinalzerjaoe@gmail.com';
  StreamSubscription<QuerySnapshot<Map<String,dynamic>>>? _sharedSub;
  final List<IptvProgram> _programs=[];
  bool _loading=true,_busy=false; String _category='الكل',_query='',_lastPublishError='';
  @override void initState(){super.initState();_load();_listenShared();}
  @override void dispose(){_sharedSub?.cancel();_url.dispose();_name.dispose();_search.dispose();_epgUrl.dispose();super.dispose();}
  void _listenShared() {
    _sharedSub = FirebaseFirestore.instance.collection('iptvSharedPlaylists')
      .orderBy('updatedAt', descending:true).snapshots().listen((snapshot) async {
        try {
          final groups = await Future.wait(snapshot.docs.map((doc) async {
            final channels = await doc.reference.collection('channels').orderBy('index').get();
            return channels.docs.map((item) {
              final data = item.data();
              return IptvChannel(name:data['name']?.toString() ?? 'قناة',url:data['url']?.toString() ?? '',group:data['group']?.toString() ?? 'عام',logo:data['logo']?.toString() ?? '',tvgId:data['tvgId']?.toString() ?? '',source:data['source']?.toString() ?? doc.data()['name']?.toString() ?? 'مكتبة مشتركة',sourceUrl:data['sourceUrl']?.toString() ?? '');
            }).where((channel) => channel.url.isNotEmpty).toList();
          }));
          if (!mounted) return;
          setState(() { _sharedChannels..clear()..addAll(groups.expand((items) => items)); });
        } catch (_) { /* Local IPTV remains available if cloud sync is offline. */ }
      }, onError: (_) { /* Cloud sync must not block local playback. */ });
  }

  String _sharedId(String source, String sourceUrl, List<IptvChannel> items) {
    final identity = sourceUrl.isNotEmpty ? sourceUrl : '$source|${items.isEmpty ? '' : items.first.url}';
    return crypto.sha256.convert(utf8.encode(identity)).toString();
  }

  Future<bool> _publishSharedPlaylist(String source, List<IptvChannel> items, {String sourceUrl = ''}) async {
    final user = FirebaseAuth.instance.currentUser;
    _lastPublishError = '';
    if (user == null) {
      _lastPublishError = 'لا يوجد حساب Firebase مسجل الدخول.';
      return false;
    }
    if (items.isEmpty || items.length > 10000 || sourceUrl.length > 2048) {
      _lastPublishError = 'بيانات القائمة خارج الحدود المسموحة.';
      return false;
    }
    try {
      // Refresh the Firebase ID token before Firestore evaluates the founder claim.
      // This avoids using a stale email claim after account/provider changes.
      await user.getIdToken(true);
      final token = await user.getIdTokenResult();
      final tokenEmail = (token.claims?['email'] ?? '').toString().trim().toLowerCase();
      if (tokenEmail != 'husinalzerjaoe@gmail.com') {
        _lastPublishError = 'حساب Firebase الحالي ليس حساب المؤسس المعتمد. سجّل الدخول بحساب المؤسس ثم أعد المحاولة.';
        return false;
      }
      final sharedName = source.trim().isEmpty ? 'قائمة IPTV' : (source.length > 100 ? source.substring(0,100) : source);
      final parent = FirebaseFirestore.instance.collection('iptvSharedPlaylists').doc(_sharedId(sharedName, sourceUrl, items));
      await parent.set({'name':sharedName,'sourceUrl':sourceUrl,'ownerUid':user.uid,'channelCount':items.length,'updatedBy':user.uid,'updatedAt':FieldValue.serverTimestamp()}, SetOptions(merge:true));
      final old = await parent.collection('channels').get();
      for (var start=0; start<old.docs.length; start+=400) {
        final batch=FirebaseFirestore.instance.batch();
        for (final doc in old.docs.skip(start).take(400)) { batch.delete(doc.reference); }
        await batch.commit();
      }
      for (var start=0; start<items.length; start+=400) {
        final batch=FirebaseFirestore.instance.batch();
        final chunk=items.skip(start).take(400).toList();
        for (var i=0; i<chunk.length; i++) {
          final c=chunk[i];
          batch.set(parent.collection('channels').doc((start+i).toString().padLeft(6,'0')), {'index':start+i,'name':c.name.length > 160 ? c.name.substring(0,160) : c.name,'url':c.url,'group':c.group.length > 100 ? c.group.substring(0,100) : c.group,'logo':c.logo.length > 2048 ? c.logo.substring(0,2048) : c.logo,'tvgId':c.tvgId.length > 160 ? c.tvgId.substring(0,160) : c.tvgId,'source':sharedName,'sourceUrl':sourceUrl});
        }
        await batch.commit();
      }
      await parent.update({'channelCount':items.length,'updatedAt':FieldValue.serverTimestamp(),'updatedBy':user.uid});
      return true;
    } catch (e, stack) {
      _lastPublishError = e.toString();
      debugPrint('IPTV shared publish failed: $e\\n$stack');
      return false;
    }
  }
  Future<void> _load() async {
    try { final p=await SharedPreferences.getInstance(),raw=p.getString(_key);
      if(raw!=null){final data=jsonDecode(raw);if(data is List)_channels.addAll(data.whereType<Map>().map((e)=>IptvChannel.fromJson(Map<String,dynamic>.from(e))));}
      _favorites.addAll(p.getStringList(_key+'_favorites')??const []);
      _hiddenSharedChannels.addAll(p.getStringList(_hiddenSharedKey)??const []);
      final epgRaw=p.getString(_epgKey);
      if(epgRaw!=null){final epgData=jsonDecode(epgRaw);if(epgData is List)_programs.addAll(epgData.whereType<Map>().map((e)=>IptvProgram.fromJson(Map<String,dynamic>.from(e))));}
    } catch(_){}
    if(mounted)setState(()=>_loading=false);
  }
  Future<void> _save() async {final p=await SharedPreferences.getInstance();await p.setString(_key,jsonEncode(_channels.map((e)=>e.toJson()).toList()));await p.setStringList(_key+'_favorites',_favorites.toList());await p.setStringList(_hiddenSharedKey,_hiddenSharedChannels.toList());await p.setString(_epgKey,jsonEncode(_programs.map((e)=>e.toJson()).toList()));}
  void _toast(String s){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(s)));}
  void _replace(String source,List<IptvChannel> items){_channels.removeWhere((e)=>e.source==source);_channels.addAll(items);_channels.sort((a,b)=>a.name.toLowerCase().compareTo(b.name.toLowerCase()));}
  Future<void> _addUrl() async {
    final uri=Uri.tryParse(_url.text.trim());
    if(uri==null||!{'http','https'}.contains(uri.scheme)||uri.host.isEmpty){_toast('أدخل رابط M3U صحيح يبدأ بـ http أو https.');return;}
    setState(()=>_busy=true);
    try{
      final response=await http.get(uri,headers:const {'Accept':'application/x-mpegURL, text/plain, */*'}).timeout(const Duration(seconds:25));
      if(response.statusCode!=200)throw Exception('استجابة المصدر '+response.statusCode.toString());
      if(response.bodyBytes.length>_maxPlaylistBytes)throw Exception('القائمة أكبر من الحد الأقصى (64 ميغابايت).');
      final source=_name.text.trim().isEmpty?uri.host:_name.text.trim();
      final items=IptvPlaylistParser.parse(utf8.decode(response.bodyBytes,allowMalformed:true),source:source,sourceUrl:uri.toString(),baseUri:uri);
      if(items.isEmpty)throw Exception('لم نعثر على قنوات صالحة.');
      _replace(source,items);await _save();_url.clear();_name.clear();
      if (_publishToMembers) {
        final shared=await _publishSharedPlaylist(source,items,sourceUrl:uri.toString());
        _toast(shared?'تم استيراد ونشر '+items.length.toString()+' قناة لكل الأعضاء.':'تم حفظها عندك، وتعذر النشر العام: '+(_lastPublishError.isEmpty?'تحقق من صلاحية حساب المؤسس.':_lastPublishError));
      } else { _toast('تم استيراد '+items.length.toString()+' قناة وحفظها عندك فقط.'); }
    }catch(e){_toast('تعذر استيراد القائمة: '+e.toString());}
    finally{if(mounted)setState(()=>_busy=false);}
  }
  Future<void> _importFile() async {
    try{
      final picked=await FilePicker.platform.pickFiles(type:FileType.custom,allowedExtensions:['m3u','m3u8','txt'],withData:true);
      if(picked==null||picked.files.isEmpty)return;
      final file=picked.files.first,bytes=picked.files.first.bytes;
      if(bytes==null){_toast('تعذر قراءة الملف.');return;}
      if(bytes.length>_maxPlaylistBytes){_toast('الملف أكبر من الحد الأقصى (64 ميغابايت).');return;}
      final items=IptvPlaylistParser.parse(utf8.decode(bytes,allowMalformed:true),source:file.name);
      if(items.isEmpty){_toast('الملف لا يحتوي قنوات M3U صالحة.');return;}
      _replace(file.name,items);await _save();
      if (_publishToMembers) {
        final shared=await _publishSharedPlaylist(file.name,items);
        _toast(shared?'تم استيراد ونشر '+items.length.toString()+' قناة لكل الأعضاء.':'تم حفظها عندك، وتعذر النشر العام: '+(_lastPublishError.isEmpty?'تحقق من صلاحية حساب المؤسس.':_lastPublishError));
      } else { _toast('تم استيراد '+items.length.toString()+' قناة وحفظها عندك فقط.'); }
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
  Future<void> _importEpgFromUrl() async {
    final controller = TextEditingController(text: _epgUrl.text);
    final url = await showDialog<String>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('استيراد دليل XMLTV من رابط'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                keyboardType: TextInputType.url,
                decoration: const InputDecoration(
                  labelText: 'رابط XMLTV',
                  hintText: 'https://example.com/epg.xml',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'استخدم رابط دليل برامج مسموح لك باستخدامه. لا تضع كلمات مرور أو رموز دخول خاصة في الرابط.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
            FilledButton(onPressed: () => Navigator.pop(ctx, controller.text.trim()), child: const Text('استيراد')),
          ],
        ),
      ),
    );
    controller.dispose();
    if (url == null || url.isEmpty) return;
    final uri = Uri.tryParse(url);
    if (uri == null || !{'http', 'https'}.contains(uri.scheme) || uri.host.isEmpty) {
      _toast('أدخل رابط XMLTV صحيح يبدأ بـ http أو https.');
      return;
    }
    setState(() => _busy = true);
    try {
      final response = await http.get(
        uri,
        headers: const {'Accept': 'application/xml, text/xml, */*'},
      ).timeout(const Duration(seconds: 25));
      if (response.statusCode != 200) {
        throw Exception('استجابة المصدر ' + response.statusCode.toString());
      }
      if (response.bodyBytes.length > _maxPlaylistBytes) {
        throw Exception('ملف الدليل أكبر من 8 ميغابايت.');
      }
      final parsed = IptvEpgParser.parse(
        utf8.decode(response.bodyBytes, allowMalformed: true),
      );
      if (parsed.isEmpty) throw Exception('لم نعثر على برامج XMLTV صالحة.');
      if (!mounted) return;
      setState(() {
        _programs
          ..clear()
          ..addAll(parsed);
        _epgUrl.text = uri.toString();
      });
      await _save();
      _toast('تم استيراد دليل البرامج من الرابط: ' + parsed.length.toString() + ' برنامج.');
    } catch (e) {
      _toast('تعذر استيراد دليل البرامج: ' + e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _showEpgGuide() async {
    final now=DateTime.now();
    await showModalBottomSheet<void>(context:context,isScrollControlled:true,showDragHandle:true,builder:(ctx)=>Directionality(textDirection:TextDirection.rtl,child:SafeArea(child:SizedBox(height:MediaQuery.of(ctx).size.height*.78,child:Column(children:[
      Padding(padding:const EdgeInsets.all(14),child:Row(children:[const Expanded(child:Text('دليل البرامج EPG',style:TextStyle(fontSize:20,fontWeight:FontWeight.w900))),Wrap(spacing:4,children:[TextButton.icon(onPressed:(){Navigator.pop(ctx);_importEpg();},icon:const Icon(Icons.file_upload_outlined),label:const Text('ملف')),TextButton.icon(onPressed:(){Navigator.pop(ctx);_importEpgFromUrl();},icon:const Icon(Icons.link_rounded),label:const Text('رابط'))])])),
      Expanded(child:_programs.isEmpty?const Center(child:Text('استورد ملف XMLTV لعرض البرامج الحالية والقادمة.')):ListView.builder(itemCount:_allChannels.length,itemBuilder:(_,i){final c=_allChannels[i];final current=c.tvgId.isEmpty?null:IptvEpgParser.current(_programs,c.tvgId,now);final next=c.tvgId.isEmpty?null:IptvEpgParser.next(_programs,c.tvgId,now);return ListTile(leading:const Icon(Icons.live_tv),title:Text(c.name),subtitle:Text(current==null?'لا يوجد برنامج حالي':('الآن: '+current.title+' • '+TimeOfDay.fromDateTime(current.start.toLocal()).format(context)+' - '+TimeOfDay.fromDateTime(current.stop.toLocal()).format(context))+'\\n'+(next==null?'لا يوجد برنامج قادم':'التالي: '+next.title)),isThreeLine:true,onTap:(){Navigator.pop(ctx);Navigator.push(context,MaterialPageRoute(builder:(_)=>IptvPlayerPage(channel:c)));});})),
    ])))));
  }
  Future<void> _favorite(IptvChannel c) async {setState(()=>_favorites.contains(c.id)?_favorites.remove(c.id):_favorites.add(c.id));await _save();}
  Future<void> _removeChannel(IptvChannel channel) async {
    final confirmed = await showDialog<bool>(context:context,builder:(ctx)=>AlertDialog(
      title:const Text('حذف القناة؟'),
      content:Text('راح تختفي قناة «${channel.name}» من قائمتك فقط. إذا كانت مشتركة، ما راح تنحذف من مكتبة بقية الأعضاء.'),
      actions:[TextButton(onPressed:()=>Navigator.pop(ctx,false),child:const Text('إلغاء')),FilledButton(onPressed:()=>Navigator.pop(ctx,true),child:const Text('حذف'))],
    ));
    if (confirmed != true) return;
    setState(() {
      if (channel.source.startsWith('مشتركة • ')) {
        _hiddenSharedChannels.add(channel.id);
      } else {
        _channels.removeWhere((item)=>item.id==channel.id && item.source==channel.source);
      }
      _favorites.remove(channel.id);
    });
    await _save();
    _toast('تم حذف القناة من قائمتك.');
  }
  Future<void> _removeSource(String source) async {
    final ids=_channels.where((e)=>e.source==source).map((e)=>e.id).toSet();
    setState((){_channels.removeWhere((e)=>e.source==source);_favorites.removeAll(ids);});await _save();_toast('تم حذف المصدر.');
  }
  List<IptvChannel> get _allChannels { final localUrls=_channels.map((c)=>c.url).toSet(); return [..._channels,..._sharedChannels.where((c)=>!localUrls.contains(c.url) && !_hiddenSharedChannels.contains(c.url)).map((c)=>IptvChannel(name:c.name,url:c.url,group:c.group,logo:c.logo,tvgId:c.tvgId,source:'مشتركة • '+c.source,sourceUrl:c.sourceUrl))]; }
  List<String> get _categories=>['الكل','المفضلة',...(_allChannels.map((e)=>e.group).toSet().toList()..sort())];
  List<IptvChannel> get _visible=>_allChannels.where((c){
    final cat=_category=='الكل'||(_category=='المفضلة'?_favorites.contains(c.id):c.group==_category),q=_query.trim().toLowerCase();
    return cat&&(q.isEmpty||c.name.toLowerCase().contains(q)||c.group.toLowerCase().contains(q)||c.source.toLowerCase().contains(q));
  }).toList();

  @override Widget build(BuildContext context){
    final visible=_visible;
    return Directionality(textDirection:TextDirection.rtl,child:Scaffold(
      appBar:AppBar(title:const Text('مركز التلفزيون وIPTV'),actions:[
        IconButton(tooltip:'تحديث المصادر',onPressed:_busy?null:_refreshAllSources,icon:const Icon(Icons.refresh_rounded)),
        IconButton(tooltip:'دليل البرامج',onPressed:_showEpgGuide,icon:const Icon(Icons.calendar_month_rounded)),
        IconButton(tooltip:'استيراد ملف XMLTV',onPressed:_importEpg,icon:const Icon(Icons.event_available_rounded)),
        IconButton(tooltip:'استيراد XMLTV من رابط',onPressed:_busy?null:_importEpgFromUrl,icon:const Icon(Icons.link_rounded)),
        IconButton(tooltip:'إدارة المصادر',onPressed:_manageSources,icon:const Icon(Icons.playlist_add_check)),
        IconButton(tooltip:'استيراد ملف',onPressed:_busy?null:_importFile,icon:const Icon(Icons.file_open)),
      ]),
      body:_loading?const Center(child:CircularProgressIndicator()):ListView(padding:const EdgeInsets.all(14),children:[
        _hero(),const SizedBox(height:12),
        Card(child:Padding(padding:const EdgeInsets.all(14),child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
          const Text('إضافة قائمة من رابط',style:TextStyle(fontWeight:FontWeight.w900)),const SizedBox(height:8),
          SwitchListTile.adaptive(
            contentPadding:EdgeInsets.zero,
            value:_publishToMembers && _isFounder,
            onChanged:_isFounder?(value)=>setState(()=>_publishToMembers=value):null,
            title:const Text('نشر القائمة لكل الأعضاء'),
            subtitle:Text(_isFounder
              ? (_publishToMembers?'سيشاهد الأعضاء القنوات بعد النشر.':'مطفأ: القائمة خاصة بك فقط.')
              : 'النشر العام متاح لحساب المؤسس فقط؛ يمكنك الاستيراد لنفسك.'),
          ),
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
        Row(children:[Expanded(child:Text('القنوات والمكتبة المشتركة ('+visible.length.toString()+')',style:const TextStyle(fontSize:18,fontWeight:FontWeight.w900))),TextButton(onPressed:_manageSources,child:const Text('المصادر'))]),
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
    const SizedBox(height:5),const Text('استيراد M3U وM3U8، ومشاركة مكتبتك مع أعضاء الملتقى.',style:TextStyle(color:Colors.white70)),
    const SizedBox(height:10),Text(_allChannels.length.toString()+' قناة • '+_channels.map((e)=>e.source).toSet().length.toString()+' مصدر محلي • '+_sharedChannels.length.toString()+' قناة مشتركة',style:const TextStyle(color:Colors.white)),
    const SizedBox(height:12),Wrap(spacing:8,runSpacing:8,children:[FilledButton.icon(onPressed:()=>_openWatchParty(),icon:const Icon(Icons.groups_rounded),label:const Text('غرف مشاهدة IPTV مع الأصدقاء')),OutlinedButton.icon(onPressed:_showEpgGuide,icon:const Icon(Icons.calendar_month),label:Text('دليل البرامج ('+_programs.length.toString()+')'))]), 
  ]));
  Widget _channelTile(IptvChannel c)=>Card(margin:const EdgeInsets.only(bottom:7),child:ListTile(
    leading:ClipRRect(borderRadius:BorderRadius.circular(9),child:Container(width:46,height:46,color:Theme.of(context).colorScheme.surfaceContainerHighest,padding:const EdgeInsets.all(5),child:c.logo.startsWith('https://')?Image.network(c.logo,fit:BoxFit.contain,errorBuilder:(_,__,___)=>const Icon(Icons.tv)):const Icon(Icons.tv))),
    title:Text(c.name,maxLines:1,overflow:TextOverflow.ellipsis,style:const TextStyle(fontWeight:FontWeight.w800)),
    subtitle:Text(c.group+' • '+c.source,maxLines:1,overflow:TextOverflow.ellipsis),
    trailing:Wrap(children:[
      IconButton(tooltip:'شاهد مع الأصدقاء',onPressed:()=>_openWatchParty(c),icon:const Icon(Icons.groups_rounded)),
      IconButton(tooltip:'المفضلة',onPressed:()=>_favorite(c),icon:Icon(_favorites.contains(c.id)?Icons.favorite:Icons.favorite_border,color:_favorites.contains(c.id)?Colors.redAccent:null)),
      IconButton(tooltip:'حذف من قائمتي',onPressed:()=>_removeChannel(c),icon:const Icon(Icons.delete_outline_rounded,color:Colors.redAccent)),
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
      if (response.bodyBytes.length > _maxPlaylistBytes) throw Exception('القائمة أكبر من الحد الأقصى (64 ميغابايت).');
      final items = IptvPlaylistParser.parse(utf8.decode(response.bodyBytes,allowMalformed:true),source:source,sourceUrl:uri.toString(),baseUri:uri);
      if (items.isEmpty) throw Exception('القائمة لا تحتوي قنوات صالحة.');
      _replace(source,items); await _save(); _toast('تم تحديث '+items.length.toString()+' قناة.');
    } catch(e) { _toast('فشل تحديث المصدر: '+e.toString()); }
    finally { if(mounted) setState(() => _busy = false); }
  }
  Future<void> _refreshSharedSources() async {
    final email = FirebaseAuth.instance.currentUser?.email?.toLowerCase();
    if (email != 'husinalzerjaoe@gmail.com') return;
    setState(() => _busy = true);
    var updated = 0;
    var skipped = 0;
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('iptvSharedPlaylists')
          .get()
          .timeout(const Duration(seconds: 20));
      for (final doc in snapshot.docs) {
        if (!mounted) return;
        final data = doc.data();
        final sourceUrl = data['sourceUrl']?.toString() ?? '';
        final sourceName = data['name']?.toString() ?? 'قائمة IPTV';
        final uri = Uri.tryParse(sourceUrl);
        if (uri == null || !{'http', 'https'}.contains(uri.scheme) || uri.host.isEmpty) {
          skipped++;
          continue;
        }
        try {
          final response = await http.get(uri).timeout(const Duration(seconds: 25));
          if (response.statusCode != 200 || response.bodyBytes.length > 8 * 1024 * 1024) {
            skipped++;
            continue;
          }
          final items = IptvPlaylistParser.parse(
            utf8.decode(response.bodyBytes, allowMalformed: true),
            source: sourceName,
            sourceUrl: uri.toString(),
            baseUri: uri,
          );
          if (items.isEmpty || !await _publishSharedPlaylist(sourceName, items, sourceUrl: uri.toString())) {
            skipped++;
            continue;
          }
          updated++;
        } catch (_) {
          skipped++;
        }
      }
      _toast('تحديث المكتبة المشتركة: تم تحديث $updated قائمة، وتعذر تحديث $skipped.');
    } catch (e) {
      _toast('تعذر تحديث المكتبة المشتركة: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _refreshAllSources() async {
    final sources = _channels.where((e)=>e.sourceUrl.isNotEmpty).map((e)=>e.source).toSet().toList();
    final isFounder = FirebaseAuth.instance.currentUser?.email?.toLowerCase() == 'husinalzerjaoe@gmail.com';
    if (sources.isEmpty && !isFounder) {
      _toast('لا توجد قوائم روابط محلية لتحديثها.');
      return;
    }
    for (final source in sources) {
      if (!mounted) return;
      await _refreshSource(source);
    }
    if (isFounder) await _refreshSharedSources();
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
