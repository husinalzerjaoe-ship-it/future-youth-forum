import 'dart:convert';
import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';

import 'local_audio_handler.dart';
import 'media_upload_service.dart';
import 'watch_party.dart';

class PremiumMediaHubPage extends StatefulWidget {
  const PremiumMediaHubPage({super.key});
  @override
  State<PremiumMediaHubPage> createState() => _PremiumMediaHubPageState();
}

class _PremiumMediaHubPageState extends State<PremiumMediaHubPage> {
  static const _key = 'future_youth_media_library_v1';
  final List<_MediaEntry> _items = [];
  bool _loading = true;
  bool _audioReady = false;
  bool _busy = false;
  double? _progress;
  String? _busyLabel;

  bool _audio(String path) => RegExp(r'\.(mp3|m4a|aac|ogg|wav|flac|opus)$', caseSensitive: false).hasMatch(path);
  bool _video(String path) => RegExp(r'\.(mp4|m4v|mov|webm|mkv)$', caseSensitive: false).hasMatch(path);

  @override
  void initState() {
    super.initState();
    _load();
    _prepareAudio();
  }

  Future<void> _prepareAudio() async {
    try {
      await initializeLocalAudioService();
      if (mounted) setState(() => _audioReady = true);
    } catch (error) {
      debugPrint('Media hub audio initialization failed: $error');
    }
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw != null) {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          _items.addAll(decoded.whereType<Map>().map((e) => _MediaEntry.fromJson(Map<String, dynamic>.from(e))));
        }
      }
      _items.removeWhere((e) => !File(e.path).existsSync());
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
    try { await _save(); } catch (error) { debugPrint('Media library save failed: $error'); }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(_items.map((e) => e.toJson()).toList()));
  }

  void _toast(String value) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value)));
  }

  Future<void> _pick() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['mp3','m4a','aac','ogg','wav','flac','opus','mp4','m4v','mov','webm','mkv'],
        allowMultiple: true,
      );
      if (result == null) return;
      var count = 0;
      final documents = await getApplicationDocumentsDirectory();
      for (final f in result.files) {
        final sourcePath = f.path;
        if (sourcePath == null || (!_audio(sourcePath) && !_video(sourcePath))) continue;
        if (_items.any((e) => e.title == f.name && File(e.path).existsSync())) continue;

        // File-picker paths may point to temporary cache/URI-backed files.
        // Copy selected media into app-owned storage so it remains available
        // after Android cleans the picker cache or the app is restarted.
        final source = File(sourcePath);
        if (!await source.exists()) continue;
        final safeName = f.name.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
        final destination = File(
          '${documents.path}/import_${DateTime.now().microsecondsSinceEpoch}_${safeName.isEmpty ? 'media' : safeName}',
        );
        try {
          final saved = await source.copy(destination.path);
          _items.insert(0, _MediaEntry(
            path: saved.path,
            title: f.name,
            kind: _audio(sourcePath) ? 'audio' : 'video',
            downloaded: true,
          ));
          count++;
        } catch (error) {
          debugPrint('Could not persist imported media ${f.name}: $error');
        }
      }
      await _save();
      if (mounted) setState(() {});
      _toast(count == 0 ? 'ما تمت إضافة ملفات جديدة.' : 'أُضيف $count ملف إلى مكتبتك.');
    } catch (e) { _toast('تعذر اختيار الملفات: $e'); }
  }

  Future<void> _download() async {
    final url = TextEditingController();
    final title = TextEditingController();
    final accepted = await showDialog<bool>(
      context: context,
      builder: (c) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('تنزيل ملف إلى مكتبتي'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: url, keyboardType: TextInputType.url,
              decoration: const InputDecoration(labelText: 'رابط مباشر HTTPS', hintText: 'https://example.com/file.mp4')),
            const SizedBox(height: 10),
            TextField(controller: title, decoration: const InputDecoration(labelText: 'اسم الملف (اختياري)')),
            const SizedBox(height: 8),
            const Text('استخدم روابط مباشرة لملفات تملكها أو لديك إذن بتنزيلها.', style: TextStyle(fontSize: 12, color: Colors.grey)),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('إلغاء')),
            FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('تنزيل')),
          ],
        ),
      ),
    );
    if (accepted != true) { url.dispose(); title.dispose(); return; }
    final uri = Uri.tryParse(url.text.trim());
    final name = title.text.trim();
    url.dispose(); title.dispose();
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) { _toast('الرابط غير صالح؛ استخدم HTTPS.'); return; }
    final isAudio = _audio(uri.path);
    final isVideo = _video(uri.path);
    if (!isAudio && !isVideo) { _toast('امتداد غير مدعوم. استخدم mp3 أو mp4 أو أحد التنسيقات المدعومة.'); return; }

    setState(() { _busy = true; _progress = null; _busyLabel = 'جاري التنزيل...'; });
    HttpClient? client;
    File? output;
    try {
      final dir = await getApplicationDocumentsDirectory();
      final ext = uri.path.substring(uri.path.lastIndexOf('.'));
      final original = uri.pathSegments.isEmpty ? 'media' : uri.pathSegments.last.replaceAll(RegExp(r'\.[^.]+$'), '');
      final safe = (name.isEmpty ? original : name).replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
      output = File(dir.path + '/' + DateTime.now().millisecondsSinceEpoch.toString() + '_' + (safe.isEmpty ? 'media' : safe) + ext);
      client = HttpClient()..connectionTimeout = const Duration(seconds: 25);
      final request = await client.getUrl(uri);
      request.headers.set(HttpHeaders.userAgentHeader, 'FutureYouthForum/7.0');
      final response = await request.close();
      if (response.statusCode < 200 || response.statusCode >= 300) throw HttpException('HTTP ' + response.statusCode.toString());
      final total = response.contentLength;
      var received = 0;
      final sink = output.openWrite();
      try {
        await for (final chunk in response) {
          sink.add(chunk);
          received += chunk.length;
          if (mounted && total > 0) setState(() => _progress = (received / total).clamp(0.0, 1.0).toDouble());
        }
      } finally { await sink.flush(); await sink.close(); }
      if (received == 0) throw const HttpException('الملف فارغ');
      _items.insert(0, _MediaEntry(path: output.path, title: name.isEmpty ? original : name, kind: isAudio ? 'audio' : 'video', downloaded: true));
      await _save();
      if (mounted) setState(() {});
      _toast('اكتمل التنزيل وأُضيف الملف إلى مكتبتك.');
    } catch (e) {
      if (output != null && await output.exists()) await output.delete();
      _toast('فشل التنزيل: $e');
    } finally {
      client?.close(force: true);
      if (mounted) setState(() { _busy = false; _progress = null; _busyLabel = null; });
    }
  }

  Future<void> _pickGalleryVideo() async {
    try {
      final picked = await ImagePicker().pickVideo(source: ImageSource.gallery);
      if (picked == null) return;
      final ext = picked.name.contains('.') ? picked.name.split('.').last.toLowerCase() : picked.path.split('.').last.toLowerCase();
      if (!['mp4', 'mov'].contains(ext)) {
        _toast('حالياً رفع الغرف يدعم MP4 وMOV. حوّل الفيديو إلى إحدى هاتين الصيغتين ثم جرّب.');
        return;
      }
      final source = File(picked.path);
      final bytes = await source.length();
      if (bytes == 0) { _toast('ملف الفيديو فارغ.'); return; }
      if (bytes > 4 * 1024 * 1024 * 1024) {
        _toast('الحد الأعلى لفيديو غرفة المشاهدة 4GB.');
        return;
      }
      final dir = await getApplicationDocumentsDirectory();
      final fileName = 'gallery_${DateTime.now().millisecondsSinceEpoch}.$ext';
      final saved = await source.copy('${dir.path}/$fileName');
      final entry = _MediaEntry(path: saved.path, title: picked.name, kind: 'video', downloaded: true);
      _items.insert(0, entry);
      await _save();
      if (mounted) setState(() {});
      await _uploadVideoAndOpenRoom(entry);
    } catch (e) {
      _toast('تعذر اختيار الفيديو من الاستديو: $e');
    }
  }

  Future<void> _uploadVideoAndOpenRoom(_MediaEntry entry) async {
    if (entry.kind != 'video') return;
    final ext = entry.path.split('.').last.toLowerCase();
    if (!['mp4', 'mov'].contains(ext)) {
      _toast('رفع الغرف يدعم حالياً فيديو MP4 وMOV.');
      return;
    }
    final file = File(entry.path);
    if (!await file.exists()) { _toast('ملف الفيديو لم يعد موجوداً على الجهاز.'); return; }
    final size = await file.length();
    if (size == 0 || size > 4 * 1024 * 1024 * 1024) {
      _toast(size == 0 ? 'ملف الفيديو فارغ.' : 'الحد الأعلى لرفع فيديو الغرفة 4GB.');
      return;
    }
    setState(() { _busy = true; _progress = null; _busyLabel = 'جاري رفع الفيديو لغرفة المشاهدة...'; });
    try {
      final remoteUrl = await uploadForumMedia(
        XFile(entry.path, name: entry.path.split(Platform.pathSeparator).last),
        folder: 'watch-rooms',
        onProgress: (progress) {
          if (mounted) setState(() => _progress = progress);
        },
      );
      if (!mounted) return;
      setState(() { _busy = false; _busyLabel = null; });
      await Navigator.push(context, MaterialPageRoute(
        builder: (_) => WatchPartyLobbyPage(initialUrl: remoteUrl, initialName: entry.title),
      ));
    } catch (e) {
      _toast('تعذر رفع الفيديو: $e');
    } finally {
      if (mounted) setState(() { _busy = false; _progress = null; _busyLabel = null; });
    }
  }

  Future<void> _uploadCommunityMusic() async {
    if (_busy) return;
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['mp3', 'm4a', 'aac', 'wav', 'ogg', 'flac'],
      allowMultiple: false,
      withData: false,
    );
    final file = picked?.files.single;
    final path = file?.path;
    if (file == null || path == null) return;
    if (file.size <= 0 || file.size > 50 * 1024 * 1024) {
      _toast('حجم الأغنية يجب ألا يتجاوز 50 ميغابايت.');
      return;
    }
    final dot = file.name.lastIndexOf('.');
    final defaultTitle = dot > 0 ? file.name.substring(0, dot) : file.name;
    final titleController = TextEditingController(text: defaultTitle);
    final artistController = TextEditingController(text: FirebaseAuth.instance.currentUser?.displayName ?? 'عضو الملتقى');
    final rights = await showDialog<String>(
      context: context,
      builder: (dialogContext) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('رفع أغنية للمجتمع'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: titleController, decoration: const InputDecoration(labelText: 'اسم الأغنية')),
            const SizedBox(height: 8),
            TextField(controller: artistController, decoration: const InputDecoration(labelText: 'الفنان / صاحب الملف')),
            const SizedBox(height: 10),
            const Text('ارفع فقط ملفاً تملك حقوق نشره أو لديك إذن بمشاركته.', style: TextStyle(fontSize: 12)),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('إلغاء')),
            FilledButton(onPressed: () => Navigator.pop(dialogContext, 'أنا صاحب العمل وأسمح بنشره'), child: const Text('أؤكد وأرفع')),
          ],
        ),
      ),
    );
    final title = titleController.text.trim();
    final artist = artistController.text.trim();
    titleController.dispose();
    artistController.dispose();
    if (rights == null) return;
    if (title.isEmpty || title.length > 100 || artist.isEmpty || artist.length > 100) {
      _toast('اكتب اسم أغنية وفناناً صالحين (حتى 100 حرف).');
      return;
    }
    setState(() { _busy = true; _progress = null; _busyLabel = 'جاري رفع الأغنية للمجتمع...'; });
    try {
      final url = await uploadForumMedia(
        XFile(path, name: file.name),
        folder: 'music',
        onProgress: (value) { if (mounted) setState(() => _progress = value); },
      );
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final extension = dot >= 0 ? file.name.substring(dot + 1).toLowerCase() : '';
      await FirebaseFirestore.instance.collection('animeWallpapers').add({
        'category': 'music',
        'title': title,
        'anime': 'موسيقى مجتمع ملتقى شباب المستقبل',
        'artist': artist,
        'uploaderId': uid,
        'status': 'approved',
        'extension': extension,
        'sourceUrl': url,
        'imageUrl': 'https://images.unsplash.com/photo-1511379938547-c1f69419868d?w=640',
        'rights': rights,
        'createdAt': FieldValue.serverTimestamp(),
      });
      _toast('تم رفع الأغنية وإضافتها إلى مكتبة المجتمع.');
    } catch (error) {
      _toast('تعذر رفع الأغنية: ' + error.toString());
    } finally {
      if (mounted) setState(() { _busy = false; _progress = null; _busyLabel = null; });
    }
  }

  Future<void> _playCommunityMusic(String url, String title) async {
    try {
      await initializeLocalAudioService();
      if (mounted && !_audioReady) setState(() => _audioReady = true);
      await appAudioHandler.loadRemoteTrack(url, title);
    } catch (error) {
      _toast('تعذر تشغيل الأغنية المشتركة: ' + error.toString());
    }
  }

  Widget _communityMusicSection() {
    final query = FirebaseFirestore.instance.collection('animeWallpapers')
        .where('category', isEqualTo: 'music')
        .where('status', isEqualTo: 'approved')
        .limit(60);
    return SliverToBoxAdapter(
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 6),
          child: Row(children: [
            const Expanded(child: Text('موسيقى المجتمع', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900))),
            TextButton.icon(onPressed: _busy ? null : _uploadCommunityMusic, icon: const Icon(Icons.upload_rounded), label: const Text('رفع أغنية')),
          ]),
        ),
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: query.snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) return const Padding(padding: EdgeInsets.all(14), child: Text('تعذر تحميل مكتبة المجتمع. تحقق من صلاحيات Firestore والتخزين.'));
            if (!snapshot.hasData) return const LinearProgressIndicator();
            final docs = snapshot.data!.docs.toList()
              ..sort((a, b) {
                final at = a.data()['createdAt'];
                final bt = b.data()['createdAt'];
                final av = at is Timestamp ? at.millisecondsSinceEpoch : 0;
                final bv = bt is Timestamp ? bt.millisecondsSinceEpoch : 0;
                return bv.compareTo(av);
              });
            if (docs.isEmpty) return const Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8), child: Text('ماكو أغاني مشتركة بعد. ارفع أول أغنية تملك حق مشاركتها.', style: TextStyle(color: Colors.grey)));
            return Column(children: docs.map((doc) {
              final data = doc.data();
              final url = (data['sourceUrl'] ?? '').toString();
              final title = (data['title'] ?? 'أغنية').toString();
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                child: ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.music_note_rounded)),
                  title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Text((data['artist'] ?? 'فنان غير معروف').toString()),
                  trailing: IconButton(
                    tooltip: 'تشغيل',
                    onPressed: url.startsWith('https://') ? () => _playCommunityMusic(url, title) : null,
                    icon: const Icon(Icons.play_circle_fill_rounded, size: 32),
                  ),
                ),
              );
            }).toList());
          },
        ),
      ]),
    );
  }

  Future<void> _play(_MediaEntry entry) async {
    final tracks = _items.where((e) => e.kind == 'audio' && File(e.path).existsSync()).toList();
    final index = tracks.indexWhere((e) => e.path == entry.path);
    if (index < 0) return;
    try {
      await initializeLocalAudioService();
      if (mounted && !_audioReady) setState(() => _audioReady = true);
      await appAudioHandler.loadLocalQueue([
        for (final e in tracks) MediaItem(id: e.path, title: e.title, album: 'مكتبة ملتقى شباب المستقبل')
      ], initialIndex: index);
      await appAudioHandler.play();
    } catch (e) { _toast('تعذر تشغيل الصوت: $e'); }
  }

  Future<void> _favorite(_MediaEntry entry) async {
    setState(() => entry.favorite = !entry.favorite);
    await _save();
  }

  Future<void> _remove(_MediaEntry entry) async {
    final ok = await showDialog<bool>(context: context, builder: (c) => AlertDialog(
      title: const Text('حذف من المكتبة؟'),
      content: Text(entry.downloaded ? 'سيُحذف الملف المنزّل من الجهاز.' : 'سيُحذف من القائمة فقط ولن يُحذف الملف الأصلي.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('إلغاء')),
        FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('حذف')),
      ],
    ));
    if (ok != true) return;
    if (entry.downloaded) { final f = File(entry.path); if (await f.exists()) await f.delete(); }
    _items.remove(entry);
    await _save();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final audio = _items.where((e) => e.kind == 'audio').toList();
    final videos = _items.where((e) => e.kind == 'video').toList();
    final favorites = _items.where((e) => e.favorite).toList();
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('مكتبة ومشغّل المستقبل'),
          actions: [IconButton(tooltip: 'استيراد ملفات', onPressed: _busy ? null : _pick, icon: const Icon(Icons.add_to_photos_outlined))]),
        body: _loading ? const Center(child: CircularProgressIndicator()) : CustomScrollView(slivers: [
          SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.all(14), child: _hero(audio.length, videos.length, favorites.length))),
          if (_busy) SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(_busyLabel ?? 'جاري العمل'), const SizedBox(height: 8), LinearProgressIndicator(value: _progress)
          ]))),
          SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 14), child: Row(children: [
            Expanded(child: _action(Icons.folder_open, 'استيراد ملفات', 'من جهازك', _busy ? null : _pick)),
            const SizedBox(width: 10),
            Expanded(child: _action(Icons.download_for_offline, 'تنزيل مباشر', 'صوت وفيديو', _busy ? null : _download)),
          ]))),
          SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            child: _action(Icons.video_call_rounded, 'ارفع فيديو من الاستديو', 'غرفة مشاهدة متزامنة مع دردشة وفويس', _busy ? null : _pickGalleryVideo))),
          SliverToBoxAdapter(child: _heading('الصوتيات', audio.length)),
          _list(audio, Icons.headphones_rounded),
          SliverToBoxAdapter(child: _heading('الفيديوهات', videos.length)),
          _list(videos, Icons.video_library_rounded),
          SliverToBoxAdapter(child: _heading('المفضلة', favorites.length)),
          _list(favorites, Icons.favorite_rounded),
          if (_items.isEmpty) const SliverFillRemaining(hasScrollBody: false, child: Center(child: Padding(
            padding: EdgeInsets.all(28), child: Text('مكتبتك جاهزة!\\nاستورد ملفاتك أو أضف رابطاً مباشراً لملف تملك حق تنزيله.', textAlign: TextAlign.center)
          ))),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ]),
        bottomNavigationBar: _nowPlaying(),
      ),
    );
  }

  Widget _hero(int audio, int video, int favorites) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(24),
      gradient: const LinearGradient(begin: Alignment.topRight, end: Alignment.bottomLeft, colors: [Color(0xFF28205C), Color(0xFF171936), Color(0xFF123B4B)]),
      border: Border.all(color: Colors.white.withOpacity(.12)),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Icon(Icons.auto_awesome_rounded, color: Color(0xFFBDAEFF), size: 30),
      const SizedBox(height: 8),
      const Text('كل وسائطك بمكان واحد', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900, color: Colors.white)),
      const SizedBox(height: 6),
      const Text('مكتبة محلية، تنزيلاتك، ومشغّل صوت يعمل بالخلفية.', style: TextStyle(color: Colors.white70)),
      const SizedBox(height: 14),
      Wrap(spacing: 8, children: [_pill('$audio صوت'), _pill('$video فيديو'), _pill('$favorites مفضلة')]),
    ]),
  );

  Widget _pill(String text) => Container(padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
    decoration: BoxDecoration(color: Colors.white.withOpacity(.10), borderRadius: BorderRadius.circular(30)),
    child: Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)));

  Widget _action(IconData icon, String title, String subtitle, VoidCallback? onTap) => Card(
    child: InkWell(borderRadius: BorderRadius.circular(16), onTap: onTap, child: Padding(padding: const EdgeInsets.all(13), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, color: const Color(0xFF9F8BFF), size: 27), const SizedBox(height: 8),
      Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
    ]))),
  );

  Widget _heading(String title, int count) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
    child: Row(children: [Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)), const SizedBox(width: 8), Text(count.toString(), style: const TextStyle(color: Colors.grey))]),
  );

  Widget _list(List<_MediaEntry> entries, IconData icon) {
    if (entries.isEmpty) return const SliverToBoxAdapter(child: Padding(padding: EdgeInsets.symmetric(horizontal: 18, vertical: 6), child: Text('لا توجد ملفات هنا بعد.', style: TextStyle(color: Colors.grey, fontSize: 12))));
    return SliverList(delegate: SliverChildBuilderDelegate((context, index) {
      final entry = entries[index];
      return Card(margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 4), child: ListTile(
        leading: CircleAvatar(backgroundColor: const Color(0xFF30265D), child: Icon(icon, color: const Color(0xFFCCBEFF))),
        title: Text(entry.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text((entry.downloaded ? 'محفوظ داخل التطبيق' : 'ملف محلي') + ' • ' + (entry.kind == 'audio' ? 'صوت' : 'فيديو'), style: const TextStyle(fontSize: 11)),
        onTap: () => entry.kind == 'audio' ? _play(entry) : Navigator.push(context, MaterialPageRoute(builder: (_) => _LocalVideoPage(entry: entry))),
        trailing: PopupMenuButton<String>(
          onSelected: (v) {
            if (v == 'favorite') _favorite(entry);
            if (v == 'remove') _remove(entry);
            if (v == 'watch') _uploadVideoAndOpenRoom(entry);
          },
          itemBuilder: (_) => [
            PopupMenuItem(value: 'favorite', child: Text(entry.favorite ? 'إزالة من المفضلة' : 'إضافة للمفضلة')),
            if (entry.kind == 'video') const PopupMenuItem(value: 'watch', child: Text('رفع وفتح غرفة مشاهدة')),
            const PopupMenuItem(value: 'remove', child: Text('حذف')),
          ],
        ),
      ));
    }, childCount: entries.length));
  }

  Widget _nowPlaying() {
    // AudioService is initialized asynchronously after the home screen appears.
    // Never dereference the late handler until initialization has completed.
    if (!_audioReady || !isAudioServiceInitialized) return const SizedBox.shrink();
    return StreamBuilder<MediaItem?>(
    stream: appAudioHandler.mediaItem,
    builder: (context, media) {
      final item = media.data;
      if (item == null) return const SizedBox.shrink();
      return StreamBuilder<PlaybackState>(
        stream: appAudioHandler.playbackState,
        builder: (context, state) {
          final playing = state.data?.playing ?? false;
          return SafeArea(top: false, child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: const Color(0xFF211B48), border: Border(top: BorderSide(color: Colors.white.withOpacity(.12)))),
            child: Row(children: [
              const Icon(Icons.graphic_eq, color: Color(0xFFBDAEFF)),
              const SizedBox(width: 8),
              Expanded(child: Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis)),
              IconButton(tooltip: 'السابق', onPressed: appAudioHandler.skipToPrevious, icon: const Icon(Icons.skip_previous_rounded)),
              IconButton(onPressed: () => playing ? appAudioHandler.pause() : appAudioHandler.play(), icon: Icon(playing ? Icons.pause : Icons.play_arrow)),
              IconButton(tooltip: 'التالي', onPressed: appAudioHandler.skipToNext, icon: const Icon(Icons.skip_next_rounded)),
              IconButton(onPressed: appAudioHandler.stop, icon: const Icon(Icons.stop)),
            ]),
          ));
        },
      );
    },
  );
  }
}

class _MediaEntry {
  _MediaEntry({required this.path, required this.title, required this.kind, required this.downloaded, this.favorite = false});
  final String path;
  final String title;
  final String kind;
  final bool downloaded;
  bool favorite;
  Map<String, dynamic> toJson() => {'path': path, 'title': title, 'kind': kind, 'downloaded': downloaded, 'favorite': favorite};
  factory _MediaEntry.fromJson(Map<String, dynamic> json) => _MediaEntry(
    path: json['path'] as String? ?? '',
    title: json['title'] as String? ?? 'وسائط',
    kind: json['kind'] as String? ?? 'audio',
    downloaded: json['downloaded'] as bool? ?? false,
    favorite: json['favorite'] as bool? ?? false,
  );
}

class _LocalVideoPage extends StatefulWidget {
  const _LocalVideoPage({required this.entry});
  final _MediaEntry entry;
  @override
  State<_LocalVideoPage> createState() => _LocalVideoPageState();
}

class _LocalVideoPageState extends State<_LocalVideoPage> {
  VideoPlayerController? _controller;
  bool _failed = false;
  @override
  void initState() { super.initState(); _init(); }
  Future<void> _init() async {
    try {
      final c = VideoPlayerController.file(File(widget.entry.path));
      _controller = c;
      await c.initialize();
      if (!mounted) return;
      setState(() {});
      await c.play();
    } catch (_) { if (mounted) setState(() => _failed = true); }
  }
  @override
  void dispose() { _controller?.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(widget.entry.title, maxLines: 1, overflow: TextOverflow.ellipsis)),
    backgroundColor: Colors.black,
    body: Center(
      child: _failed
        ? const Text('تعذر تشغيل هذا التنسيق على جهازك.', style: TextStyle(color: Colors.white))
        : _controller?.value.isInitialized == true
          ? AspectRatio(aspectRatio: _controller!.value.aspectRatio, child: Stack(alignment: Alignment.center, children: [
              VideoPlayer(_controller!),
              IconButton.filled(
                onPressed: () { final c = _controller!; setState(() { c.value.isPlaying ? c.pause() : c.play(); }); },
                icon: Icon(_controller!.value.isPlaying ? Icons.pause : Icons.play_arrow), iconSize: 38,
              ),
              Align(alignment: Alignment.bottomCenter, child: VideoProgressIndicator(_controller!, allowScrubbing: true)),
            ]))
          : const CircularProgressIndicator(color: Colors.white),
    ),
  );
}
