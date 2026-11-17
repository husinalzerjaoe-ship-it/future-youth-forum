import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

const _plusBrand = Color(0xFF6554D9);
final _plusDb = FirebaseFirestore.instance;
String get _plusUid => FirebaseAuth.instance.currentUser!.uid;
bool get _plusFounder => FirebaseAuth.instance.currentUser?.email?.toLowerCase() == 'husinalzerjaoe@gmail.com';

/// Search and threaded community discussions.
class CommunityPlusPage extends StatelessWidget {
  const CommunityPlusPage({super.key});
  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.rtl,
    child: Scaffold(
      appBar: AppBar(title: const Text('مجتمع الأوتاكو')),
      body: ListView(padding: const EdgeInsets.all(14), children: [
        const _CommunitySearch(),
        const SizedBox(height: 14),
        Row(children: [
          const Expanded(child: Text('نقاشات الأعضاء', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold))),
          FilledButton.icon(onPressed: () => _createTopic(context), icon: const Icon(Icons.add), label: const Text('موضوع جديد')),
        ]),
        const SizedBox(height: 8),
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _plusDb.collection('communityTopics').orderBy('createdAt', descending: true).limit(50).snapshots(),
          builder: (context, s) {
            if (s.hasError) return const Text('تعذر تحميل النقاشات. تأكد من نشر قواعد Firestore.');
            if (!s.hasData) return const Center(child: CircularProgressIndicator());
            if (s.data!.docs.isEmpty) return const Card(child: Padding(padding: EdgeInsets.all(18), child: Text('ماكو نقاشات بعد. افتح أول موضوع عن الأنمي!')));
            return Column(children: s.data!.docs.map((d) => _TopicCard(doc: d)).toList());
          },
        ),
      ]),
    ),
  );
}

class _CommunitySearch extends StatefulWidget {
  const _CommunitySearch();
  @override State<_CommunitySearch> createState() => _CommunitySearchState();
}
class _CommunitySearchState extends State<_CommunitySearch> {
  final _controller = TextEditingController();
  String _query = '';
  bool _busy = false;
  List<_SearchHit> _hits = [];
  String? _error;
  @override void dispose() { _controller.dispose(); super.dispose(); }

  Future<void> _search() async {
    final q = _query.trim();
    if (q.length < 2) { setState(() { _hits = []; _error = 'اكتب حرفين على الأقل.'; }); return; }
    setState(() { _busy = true; _error = null; _hits = []; });
    try {
      final end = '$q\uf8ff';
      final results = await Future.wait([
        _plusDb.collection('publicProfiles').orderBy('name').startAt([q]).endAt([end]).limit(12).get(),
        _plusDb.collection('communityTopics').orderBy('title').startAt([q]).endAt([end]).limit(12).get(),
        _plusDb.collection('posts').orderBy('text').startAt([q]).endAt([end]).limit(12).get(),
      ]);
      final hits = <_SearchHit>[];
      for (final d in results[0].docs) {
        if (d.id != _plusUid) hits.add(_SearchHit('عضو', d.data()['name'] as String? ?? 'عضو', d.data()['bio'] as String? ?? '', Icons.person, null));
      }
      for (final d in results[1].docs) {
        hits.add(_SearchHit('نقاش', d.data()['title'] as String? ?? 'موضوع', d.data()['body'] as String? ?? '', Icons.forum, d.id));
      }
      for (final d in results[2].docs) {
        hits.add(_SearchHit('منشور', d.data()['text'] as String? ?? 'منشور', d.data()['authorName'] as String? ?? '', Icons.article, null));
      }
      if (mounted) setState(() => _hits = hits);
    } catch (_) {
      if (mounted) setState(() => _error = 'تعذر البحث. قد تحتاج فهارس Firestore أو تحديث قواعده.');
    } finally { if (mounted) setState(() => _busy = false); }
  }

  @override Widget build(BuildContext context) => Card(child: Padding(
    padding: const EdgeInsets.all(14),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('بحث شامل', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
      const SizedBox(height: 8),
      TextField(controller: _controller, textInputAction: TextInputAction.search,
        onChanged: (v) => _query = v,
        onSubmitted: (_) => _search(),
        decoration: InputDecoration(
          hintText: 'ابحث عن عضو أو موضوع أو منشور',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: IconButton(onPressed: _busy ? null : _search, icon: const Icon(Icons.arrow_forward)),
          border: const OutlineInputBorder(),
        )),
      if (_busy) const LinearProgressIndicator(),
      if (_error != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(_error!, style: const TextStyle(color: Colors.red))),
      ..._hits.map((h) => ListTile(
        dense: true, contentPadding: EdgeInsets.zero, leading: Icon(h.icon, color: _plusBrand),
        title: Text(h.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text('${h.kind} • ${h.subtitle}', maxLines: 1, overflow: TextOverflow.ellipsis),
        trailing: h.topicId == null ? null : const Icon(Icons.chevron_left),
        onTap: h.topicId == null ? null : () => Navigator.push(context, MaterialPageRoute(builder: (_) => TopicDetailPage(topicId: h.topicId!, title: h.title))),
      )),
      if (_hits.isEmpty && !_busy && _query.trim().length >= 2 && _error == null)
        const Padding(padding: EdgeInsets.only(top: 8), child: Text('ما لقينا نتائج مطابقة. البحث حالياً يبدأ من أول الكلمة.')),
    ]),
  ));
}

class _SearchHit {
  final String kind, title, subtitle;
  final IconData icon;
  final String? topicId;
  const _SearchHit(this.kind, this.title, this.subtitle, this.icon, this.topicId);
}

class _TopicCard extends StatelessWidget {
  final QueryDocumentSnapshot<Map<String, dynamic>> doc;
  const _TopicCard({required this.doc});
  @override Widget build(BuildContext context) {
    final d = doc.data();
    return Card(child: ListTile(
      leading: const CircleAvatar(backgroundColor: Color(0xFFEDE8FF), child: Icon(Icons.forum, color: _plusBrand)),
      title: Text(d['title'] as String? ?? 'موضوع', style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text('${d['authorName'] ?? 'عضو'} • ${d['category'] ?? 'عام'}'),
      trailing: const Icon(Icons.chevron_left),
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TopicDetailPage(topicId: doc.id, title: d['title'] as String? ?? 'نقاش'))),
    ));
  }
}

Future<void> _createTopic(BuildContext context) async {
  final title = TextEditingController(), body = TextEditingController();
  String category = 'أنمي';
  final ok = await showDialog<bool>(context: context, builder: (c) => StatefulBuilder(builder: (c, setD) => Directionality(
    textDirection: TextDirection.rtl,
    child: AlertDialog(
      title: const Text('فتح نقاش جديد'),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: title, maxLength: 100, decoration: const InputDecoration(labelText: 'عنوان النقاش')),
        TextField(controller: body, minLines: 3, maxLines: 6, maxLength: 2000, decoration: const InputDecoration(labelText: 'اكتب فكرتك أو سؤالك')),
        DropdownButtonFormField<String>(value: category, decoration: const InputDecoration(labelText: 'القسم'),
          items: const ['أنمي','مانغا','ألعاب','نقاش عام','نظريات وتحليلات'].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
          onChanged: (v) { if (v != null) setD(() => category = v); }),
      ])),
      actions: [
        TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('إلغاء')),
        FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('نشر النقاش')),
      ],
    ),
  )));
  if (ok == true && title.text.trim().length >= 3 && body.text.trim().isNotEmpty) {
    try {
      final profile = await _plusDb.collection('publicProfiles').doc(_plusUid).get();
      await _plusDb.collection('communityTopics').add({
        'title': title.text.trim(), 'body': body.text.trim(), 'category': category,
        'authorId': _plusUid, 'authorName': profile.data()?['name'] ?? 'عضو',
        'createdAt': FieldValue.serverTimestamp(), 'replyCount': 0, 'isLocked': false,
      });
    } catch (_) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تعذر نشر النقاش. تحقق من قواعد Firestore.')));
    }
  }
  title.dispose(); body.dispose();
}

class TopicDetailPage extends StatefulWidget {
  final String topicId, title;
  const TopicDetailPage({super.key, required this.topicId, required this.title});
  @override State<TopicDetailPage> createState() => _TopicDetailPageState();
}
class _TopicDetailPageState extends State<TopicDetailPage> {
  final _reply = TextEditingController();
  bool _sending = false;
  @override void dispose() { _reply.dispose(); super.dispose(); }

  Future<void> _sendReply() async {
    final text = _reply.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      final topic = _plusDb.collection('communityTopics').doc(widget.topicId);
      final profile = await _plusDb.collection('publicProfiles').doc(_plusUid).get();
      await _plusDb.runTransaction((tx) async {
        final snap = await tx.get(topic);
        if (!snap.exists || snap.data()?['isLocked'] == true) throw StateError('locked');
        final replyRef = topic.collection('replies').doc();
        tx.set(replyRef, {'uid': _plusUid, 'name': profile.data()?['name'] ?? 'عضو', 'text': text, 'createdAt': FieldValue.serverTimestamp()});
        tx.update(topic, {'replyCount': FieldValue.increment(1)});
      });
      _reply.clear();
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تعذر إرسال الرد؛ قد يكون النقاش مغلقاً أو تحتاج تحديث القواعد.')));
    } finally { if (mounted) setState(() => _sending = false); }
  }

  Future<void> _toggleLock(bool locked) async {
    if (!_plusFounder) return;
    await _plusDb.collection('communityTopics').doc(widget.topicId).update({'isLocked': !locked});
  }

  @override Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.rtl,
    child: Scaffold(
      appBar: AppBar(title: Text(widget.title), actions: [
        if (_plusFounder) StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: _plusDb.collection('communityTopics').doc(widget.topicId).snapshots(),
          builder: (c, s) {
            final locked = s.data?.data()?['isLocked'] == true;
            return IconButton(tooltip: locked ? 'فتح النقاش' : 'إغلاق النقاش', onPressed: () => _toggleLock(locked), icon: Icon(locked ? Icons.lock_open : Icons.lock_outline));
          }),
      ]),
      body: Column(children: [
        Expanded(child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: _plusDb.collection('communityTopics').doc(widget.topicId).snapshots(),
          builder: (c, s) {
            if (!s.hasData) return const Center(child: CircularProgressIndicator());
            if (!s.data!.exists) return const Center(child: Text('هذا النقاش لم يعد موجوداً.'));
            final d = s.data!.data()!;
            return ListView(padding: const EdgeInsets.all(14), children: [
              Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(d['category'] as String? ?? 'عام', style: const TextStyle(color: _plusBrand, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(d['body'] as String? ?? '', style: const TextStyle(fontSize: 16, height: 1.6)),
                const SizedBox(height: 8),
                Text('بواسطة ${d['authorName'] ?? 'عضو'} • ${d['replyCount'] ?? 0} رد'),
              ]))),
              const SizedBox(height: 8),
              const Text('الردود', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: _plusDb.collection('communityTopics').doc(widget.topicId).collection('replies').orderBy('createdAt').limit(100).snapshots(),
                builder: (c, r) {
                  if (r.hasError) return const Text('تعذر تحميل الردود.');
                  if (!r.hasData) return const LinearProgressIndicator();
                  if (r.data!.docs.isEmpty) return const Text('كن أول من يرد على الموضوع.');
                  return Column(children: r.data!.docs.map((x) => Card(child: ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.person_outline)),
                    title: Text(x.data()['name'] as String? ?? 'عضو'),
                    subtitle: Text(x.data()['text'] as String? ?? ''),
                  ))).toList());
                },
              ),
            ]);
          },
        )),
        StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: _plusDb.collection('communityTopics').doc(widget.topicId).snapshots(),
          builder: (c, s) {
            final locked = s.data?.data()?['isLocked'] == true;
            if (locked) return const Padding(padding: EdgeInsets.all(14), child: Text('تم إغلاق النقاش من الإدارة.'));
            return SafeArea(child: Padding(padding: const EdgeInsets.all(8), child: Row(children: [
              Expanded(child: TextField(controller: _reply, maxLength: 1000, minLines: 1, maxLines: 3, decoration: const InputDecoration(hintText: 'اكتب ردك...', border: OutlineInputBorder(), counterText: ''))),
              IconButton(onPressed: _sending ? null : _sendReply, icon: _sending ? const CircularProgressIndicator() : const Icon(Icons.send, color: _plusBrand)),
            ])));
          },
        ),
      ]),
    ),
  );
}
