import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import 'media_upload_service.dart';
import 'advanced_features.dart';
import 'community_events.dart';
import 'community_pages.dart';
import 'community_polls.dart';
import 'community_plus.dart';
import 'future_arcade.dart';
import 'future_culture_hub.dart';
import 'future_planner.dart';
import 'future_studio.dart';
import 'friends_battle_arena.dart';
import 'friends_fun_world.dart';
import 'game_center.dart';
import 'iptv_center.dart';
import 'knowledge_corner.dart';
import 'premium_media_hub.dart';
import 'v52_community_reels.dart';
import 'v53_community_hub.dart';
import 'v54_world_community.dart';
import 'v56_future_world.dart';
import 'v59_vod_cinema_library.dart';
import 'ai_assistant.dart';
import 'v60_app_health_center.dart';
import 'v60_link_library.dart';

class V58ExperienceHubPage extends StatefulWidget {
  const V58ExperienceHubPage({super.key});
  @override
  State<V58ExperienceHubPage> createState() => _V58ExperienceHubPageState();
}

class _V58ExperienceHubPageState extends State<V58ExperienceHubPage> {
  static const _accent = Color(0xFF8B78FF);
  final _search = TextEditingController();
  String _category = 'الكل';

  late final List<_V58Feature> _features = [
    _V58Feature('مساعد المستقبل الذكي', 'مساعد للدراسة والأفكار والمعرفة', Icons.smart_toy_rounded, 'الإبداع والمعرفة', () => const AiAssistantPage()),
    _V58Feature('مركز صحة التطبيق', 'افحص اتصال Firebase وذاكرة الصور', Icons.health_and_safety_rounded, 'الأمان', () => const V60AppHealthPage()),
    _V58Feature('مكتبتي الشخصية للروابط', 'احفظ روابطك العامة وصنّفها وافتحها بسرعة', Icons.link_rounded, 'الإبداع والمعرفة', () => const V60LinkLibraryPage()),
    _V58Feature('قصص الملتقى', 'انشر صورة أو فيديو وتحكم بمدة بقائه', Icons.auto_stories_rounded, 'المجتمع', () => const V58StoriesPage()),
    _V58Feature('ريلز الملتقى', 'مقاطع عمودية، إعجابات وتعليقات', Icons.smart_display_rounded, 'المجتمع', () => const CommunityReelsPage()),
    _V58Feature('مركز المجتمع', 'الأندية والإنجازات ومحتوى الأعضاء', Icons.groups_rounded, 'المجتمع', () => const V53CommunityHubPage()),
    _V58Feature('عالم المجتمع', 'الإشعارات والفعاليات والتفاعل', Icons.public_rounded, 'المجتمع', () => const V54WorldCommunityPage()),
    _V58Feature('الفعاليات', 'تابع فعاليات الملتقى ومواعيدها', Icons.event_rounded, 'المجتمع', () => const CommunityEventsPage()),
    _V58Feature('التصويت والاستطلاعات', 'شارك برأيك في استطلاعات الأعضاء', Icons.poll_rounded, 'المجتمع', () => const CommunityPollsPage()),
    _V58Feature('الدردشة الخاصة', 'افتح محادثاتك الخاصة', Icons.forum_rounded, 'التواصل', () => const DirectMessagesPage()),
    _V58Feature('مركز الألعاب', 'ألعاب وتحديات متنوعة', Icons.sports_esports_rounded, 'الألعاب', () => const GameCenterPage()),
    _V58Feature('عالم وناسة الأصدقاء', 'نشاطات وألعاب اجتماعية', Icons.celebration_rounded, 'الألعاب', () => const FriendsFunWorldPage()),
    _V58Feature('مدينة ألعاب 2D', 'افتح تجارب الألعاب الموجودة', Icons.videogame_asset_rounded, 'الألعاب', () => const FutureArcadePage()),
    _V58Feature('منافسات الأصدقاء', 'تحديات ولوحة منافسة', Icons.emoji_events_rounded, 'الألعاب', () => const FriendsBattleArenaPage()),
    _V58Feature('مركز IPTV', 'القنوات المباشرة ودليل البرامج', Icons.live_tv_rounded, 'الترفيه', () => const IptvCenterPage()),
    _V58Feature('مكتبة الأفلام والمسلسلات المتزامنة', 'أفلام وأنمي وحلقات ومشاهدة جماعية', Icons.movie_filter_rounded, 'الترفيه', () => const VodCinemaLibraryPage()),
    _V58Feature('مكتبة الوسائط', 'مركز الصوت والفيديو', Icons.video_library_rounded, 'الترفيه', () => const PremiumMediaHubPage()),
    _V58Feature('عالم المستقبل V56', 'دفتر الأحلام والذكريات والقصص', Icons.auto_awesome_rounded, 'الإبداع والمعرفة', () => const V56FutureWorldPage()),
    _V58Feature('استوديو الإبداع', 'مساحة الكتابة وصناعة المحتوى', Icons.brush_rounded, 'الإبداع والمعرفة', () => const FutureStudioPage()),
    _V58Feature('ركن المعرفة', 'اكتشاف ومعلومات ومحتوى معرفي', Icons.lightbulb_rounded, 'الإبداع والمعرفة', () => const KnowledgeCornerPage()),
    _V58Feature('مخطط المستقبل', 'نظم مهامك وأهدافك', Icons.event_note_rounded, 'الإبداع والمعرفة', () => const FuturePlannerPage()),
    _V58Feature('الأمان والخصوصية', 'إرشادات وأدوات سلامة الحساب', Icons.shield_rounded, 'الأمان', () => const MemberSafetyPage()),
    _V58Feature('المجتمع الشامل', 'مساحة إضافية للأقسام الاجتماعية', Icons.hub_rounded, 'المجتمع', () => const CommunityPlusPage()),
    _V58Feature('مكتبة الثقافة', 'الشعر والاقتباسات والثقافة', Icons.menu_book_rounded, 'الإبداع والمعرفة', () => const FutureCultureHubPage()),
  ];

  static const _categories = ['الكل', 'المجتمع', 'التواصل', 'الألعاب', 'الترفيه', 'الإبداع والمعرفة', 'الأمان'];

  @override
  void dispose() { _search.dispose(); super.dispose(); }

  void _open(_V58Feature feature) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => feature.page()));
  }

  @override
  Widget build(BuildContext context) {
    final query = _search.text.trim().toLowerCase();
    final visible = _features.where((feature) {
      final matchesCategory = _category == 'الكل' || feature.category == _category;
      final haystack = '${feature.title} ${feature.subtitle} ${feature.category}'.toLowerCase();
      return matchesCategory && (query.isEmpty || haystack.contains(query));
    }).toList();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('مركز تجربة الملتقى V60'),
          actions: [IconButton(tooltip: 'مسح البحث', onPressed: () { _search.clear(); setState(() {}); }, icon: const Icon(Icons.refresh_rounded))],
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 28),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: const LinearGradient(begin: Alignment.topRight, end: Alignment.bottomLeft, colors: [Color(0xFF30256A), Color(0xFF171936), Color(0xFF124B60)]),
              ),
              child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [Icon(Icons.auto_awesome_rounded, color: Color(0xFFE5DFFF), size: 30), SizedBox(width: 10), Expanded(child: Text('كل الملتقى بمكان واحد', style: TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.w900)))]),
                SizedBox(height: 10),
                Text('بوابة موحدة للوصول السريع إلى المجتمع والألعاب والترفيه والإبداع والأمان، مع إبقاء الأقسام الأصلية كما هي.', style: TextStyle(color: Colors.white70, height: 1.6)),
              ]),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _search,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(hintText: 'ابحث عن قسم أو ميزة...', prefixIcon: const Icon(Icons.search_rounded), suffixIcon: _search.text.isEmpty ? null : IconButton(onPressed: () { _search.clear(); setState(() {}); }, icon: const Icon(Icons.close_rounded)), filled: true, border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none)),
            ),
            const SizedBox(height: 12),
            SizedBox(height: 42, child: ListView(scrollDirection: Axis.horizontal, children: _categories.map((category) => Padding(
              padding: const EdgeInsetsDirectional.only(end: 8),
              child: ChoiceChip(label: Text(category), selected: _category == category, onSelected: (_) => setState(() => _category = category), selectedColor: _accent.withValues(alpha: .25)),
            )).toList())),
            const SizedBox(height: 12),
            Row(children: [const Icon(Icons.apps_rounded, color: _accent), const SizedBox(width: 8), Text('الأقسام والميزات (${visible.length})', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold))]),
            const SizedBox(height: 10),
            if (visible.isEmpty)
              const Card(child: Padding(padding: EdgeInsets.all(22), child: Center(child: Text('ما لقينا قسم بهذا الاسم. جرّب كلمة ثانية.'))))
            else
              LayoutBuilder(builder: (context, constraints) {
                final columns = constraints.maxWidth >= 700 ? 3 : 2;
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: visible.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: columns, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 1.12),
                  itemBuilder: (context, index) {
                    final feature = visible[index];
                    return Card(clipBehavior: Clip.antiAlias, child: InkWell(
                      onTap: () => _open(feature),
                      child: Padding(padding: const EdgeInsets.all(13), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Container(width: 42, height: 42, decoration: BoxDecoration(color: _accent.withValues(alpha: .16), borderRadius: BorderRadius.circular(13)), child: Icon(feature.icon, color: _accent)),
                        const Spacer(),
                        Text(feature.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 5),
                        Text(feature.subtitle, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, color: Theme.of(context).hintColor)),
                        const SizedBox(height: 5),
                        Row(children: [Text(feature.category, style: const TextStyle(fontSize: 10, color: _accent)), const Spacer(), const Icon(Icons.arrow_back_ios_new_rounded, size: 12)]),
                      ])),
                    ));
                  },
                );
              }),
            const SizedBox(height: 16),
            Card(child: ListTile(leading: const Icon(Icons.verified_user_outlined, color: _accent), title: const Text('ملاحظة حول الخصوصية'), subtitle: const Text('استخدم أدوات الإبلاغ والحظر، ولا تشارك كلمات المرور أو روابطاً تحتوي رموز دخول.'), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MemberSafetyPage())))),
          ],
        ),
      ),
    );
  }
}

class _V58Feature {
  const _V58Feature(this.title, this.subtitle, this.icon, this.category, this.page);
  final String title;
  final String subtitle;
  final IconData icon;
  final String category;
  final Widget Function() page;
}


/// Stories can expire after 24 hours or remain until their owner deletes them.
class V58StoriesPage extends StatefulWidget {
  const V58StoriesPage({super.key});
  @override
  State<V58StoriesPage> createState() => _V58StoriesPageState();
}

class _V58StoriesPageState extends State<V58StoriesPage> {
  final _picker = ImagePicker();
  bool _uploading = false;
  double _progress = 0;
  bool _expireAfterDay = true;
  String? _error;

  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? '';

  void _toast(String message) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _publish() async {
    if (_uid.isEmpty || _uploading) return;
    final kind = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(child: Directionality(
        textDirection: TextDirection.rtl,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(leading: const Icon(Icons.image_rounded), title: const Text('قصة بصورة'), onTap: () => Navigator.pop(ctx, 'image')),
          ListTile(leading: const Icon(Icons.video_library_rounded), title: const Text('قصة بفيديو'), onTap: () => Navigator.pop(ctx, 'video')),
        ]),
      )),
    );
    if (kind == null) return;
    XFile? file;
    try {
      file = kind == 'image'
          ? await _picker.pickImage(source: ImageSource.gallery, imageQuality: 88)
          : await _picker.pickVideo(source: ImageSource.gallery, maxDuration: const Duration(minutes: 2));
      if (file == null) return;
      setState(() { _uploading = true; _progress = 0; _error = null; });
      final url = await uploadForumMedia(file, folder: 'stories', onProgress: (v) {
        if (mounted) setState(() => _progress = v);
      });
      final user = FirebaseAuth.instance.currentUser!;
      final expiresAt = _expireAfterDay
          ? Timestamp.fromDate(DateTime.now().add(const Duration(hours: 24)))
          : null;
      await FirebaseFirestore.instance.collection('stories').add({
        'authorId': user.uid,
        'authorName': (user.displayName?.trim().isNotEmpty == true)
            ? user.displayName!.trim()
            : (user.email?.split('@').first ?? 'عضو'),
        'mediaUrl': url,
        'mediaType': kind,
        'createdAt': FieldValue.serverTimestamp(),
        'expiresAt': expiresAt,
      });
      _toast(_expireAfterDay ? 'نُشرت القصة وستنتهي بعد 24 ساعة.' : 'نُشرت القصة وستبقى حتى تحذفها.');
    } catch (error) {
      _toast('تعذر نشر القصة: $error');
    } finally {
      if (mounted) setState(() { _uploading = false; _progress = 0; });
    }
  }

  Future<void> _delete(DocumentSnapshot<Map<String, dynamic>> doc) async {
    final data = doc.data() ?? {};
    if (data['authorId'] != _uid) return;
    final ok = await showDialog<bool>(context: context, builder: (ctx) => Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        title: const Text('حذف القصة؟'),
        content: const Text('سيتم حذف القصة من الملتقى.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('حذف')),
        ],
      ),
    ));
    if (ok != true) return;
    try {
      await doc.reference.delete();
      final url = (data['mediaUrl'] ?? '').toString();
      if (url.isNotEmpty) {
        try { await deleteForumMedia(url); } catch (error) { debugPrint('Story media cleanup failed: $error'); }
      }
      _toast('تم حذف قصتك.');
    } catch (error) {
      _toast('تعذر حذف القصة: $error');
    }
  }

  String _remaining(dynamic value) {
    if (value is! Timestamp) return 'تبقى حتى تحذفها';
    final diff = value.toDate().difference(DateTime.now());
    if (diff.isNegative) return 'انتهت';
    if (diff.inHours > 0) return 'تنتهي بعد ${diff.inHours} ساعة';
    return 'تنتهي بعد ${diff.inMinutes.clamp(1, 59)} دقيقة';
  }

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.rtl,
    child: Scaffold(
      appBar: AppBar(title: const Text('قصص الملتقى')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _uploading ? null : _publish,
        icon: const Icon(Icons.add_rounded),
        label: const Text('إضافة قصة'),
      ),
      body: Column(children: [
        Card(
          margin: const EdgeInsets.fromLTRB(12, 10, 12, 8),
          child: Padding(padding: const EdgeInsets.all(12), child: Column(children: [
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _expireAfterDay,
              onChanged: _uploading ? null : (v) => setState(() => _expireAfterDay = v),
              title: const Text('حذف تلقائي بعد 24 ساعة'),
              subtitle: Text(_expireAfterDay ? 'القصة تنتهي بعد يوم' : 'القصة تبقى إلى أن تحذفها بنفسك'),
            ),
            if (_uploading) ...[
              LinearProgressIndicator(value: _progress > 0 ? _progress : null),
              const SizedBox(height: 6),
              Text('جاري رفع القصة ${(_progress * 100).round()}%'),
            ],
          ])),
        ),
        Expanded(child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance.collection('stories').orderBy('createdAt', descending: true).limit(100).snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) return Center(child: Padding(padding: const EdgeInsets.all(24), child: Text('تعذر تحميل القصص: ${snapshot.error}')));
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
            final docs = snapshot.data!.docs.where((doc) {
              final expires = doc.data()['expiresAt'];
              return expires is! Timestamp || expires.toDate().isAfter(DateTime.now());
            }).toList();
            if (docs.isEmpty) return const Center(child: Text('ماكو قصص حالياً. انشر أول قصة للملتقى!'));
            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 92),
              itemCount: docs.length,
              itemBuilder: (context, index) {
                final doc = docs[index];
                final data = doc.data();
                final mine = data['authorId'] == _uid;
                final image = data['mediaType'] == 'image';
                final url = (data['mediaUrl'] ?? '').toString();
                return Card(
                  clipBehavior: Clip.antiAlias,
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    ListTile(
                      leading: CircleAvatar(child: Icon(image ? Icons.image_outlined : Icons.play_arrow_rounded)),
                      title: Text((data['authorName'] ?? 'عضو').toString()),
                      subtitle: Text(_remaining(data['expiresAt'])),
                      trailing: mine ? IconButton(tooltip: 'حذف قصتي', onPressed: () => _delete(doc), icon: const Icon(Icons.delete_outline_rounded)) : null,
                    ),
                    if (image && url.isNotEmpty)
                      Image.network(url, height: 220, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const SizedBox(height: 120, child: Center(child: Text('تعذر عرض الصورة'))))
                    else
                      _V58StoryVideo(url: url),
                  ]),
                );
              },
            );
          },
        )),
      ]),
    ),
  );
}

class _V58StoryVideo extends StatefulWidget {
  const _V58StoryVideo({required this.url});
  final String url;
  @override
  State<_V58StoryVideo> createState() => _V58StoryVideoState();
}

class _V58StoryVideoState extends State<_V58StoryVideo> {
  VideoPlayerController? _controller;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      final controller = VideoPlayerController.networkUrl(Uri.parse(widget.url));
      _controller = controller;
      await controller.initialize();
      await controller.setLooping(true);
      if (mounted) setState(() {});
    } catch (error) {
      debugPrint('Story video initialization failed: $error');
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (_failed) return const SizedBox(height: 130, child: Center(child: Text('تعذر تشغيل الفيديو')));
    if (controller == null || !controller.value.isInitialized) {
      return const SizedBox(height: 150, child: Center(child: CircularProgressIndicator()));
    }
    return GestureDetector(
      onTap: () {
        if (controller.value.isPlaying) {
          controller.pause();
        } else {
          controller.play();
        }
        setState(() {});
      },
      child: AspectRatio(
        aspectRatio: controller.value.aspectRatio > 0 ? controller.value.aspectRatio : 16 / 9,
        child: Stack(
          alignment: Alignment.center,
          children: [
            VideoPlayer(controller),
            if (!controller.value.isPlaying)
              const Icon(Icons.play_circle_fill_rounded, color: Colors.white, size: 58),
          ],
        ),
      ),
    );
  }
}
