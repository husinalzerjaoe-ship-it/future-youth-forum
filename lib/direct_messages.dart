import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

const _dmBrand = Color(0xFF6554D9);
const _dmFounderEmail = 'husinalzerjaoe@gmail.com';
final _dmDb = FirebaseFirestore.instance;

class DirectMessagesPage extends StatelessWidget {
  const DirectMessagesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('سجّل الدخول لعرض رسائلك الخاصة')));
    }
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('الرسائل الخاصة'),
          backgroundColor: const Color(0xFF171936),
          foregroundColor: Colors.white,
        ),
        backgroundColor: const Color(0xFF111321),
        body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          // Keep the query aligned with the Firestore members-array rule.
          stream: _dmDb.collection('conversations')
              .where('members', arrayContains: user.uid).snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return _InboxState(
                icon: Icons.mark_email_unread_outlined,
                title: 'تعذر تحميل الرسائل الخاصة',
                detail: 'رمز الخطأ: ${snapshot.error is FirebaseException ? (snapshot.error as FirebaseException).code : 'unknown'}',
                retry: () {},
              );
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator(color: _dmBrand));
            }
            final docs = snapshot.data!.docs.toList()
              ..sort((a, b) {
                final at = a.data()['updatedAt'];
                final bt = b.data()['updatedAt'];
                final ad = at is Timestamp ? at : Timestamp(0, 0);
                final bd = bt is Timestamp ? bt : Timestamp(0, 0);
                return bd.compareTo(ad);
              });
            if (docs.isEmpty) {
              return const _InboxState(
                icon: Icons.mark_email_unread_outlined,
                title: 'ما عندك محادثات بعد',
                detail: 'افتح ملف أي عضو واضغط «مراسلة خاصة» حتى تبدأ محادثتك الأولى.',
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(14),
              itemCount: docs.length,
              separatorBuilder: (_, __) => const SizedBox(height: 9),
              itemBuilder: (context, index) {
                final doc = docs[index];
                final data = doc.data();
                final members = (data['members'] as List?)?.whereType<String>().toList() ?? <String>[];
                final otherUid = members.firstWhere((id) => id != user.uid, orElse: () => '');
                if (otherUid.isEmpty) return const SizedBox.shrink();
                final names = data['memberNames'] is Map ? Map<String, dynamic>.from(data['memberNames']) : <String, dynamic>{};
                final name = names[otherUid]?.toString() ?? 'عضو';
                final last = data['lastMessage']?.toString() ?? 'ابدأ المحادثة الآن';
                return Material(
                  color: const Color(0xFF1B1D32),
                  borderRadius: BorderRadius.circular(18),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 7),
                    leading: CircleAvatar(
                      backgroundColor: _dmBrand.withValues(alpha: .22),
                      child: const Icon(Icons.person, color: Color(0xFFC9C1FF)),
                    ),
                    title: Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                    subtitle: Text(last, maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white60)),
                    trailing: const Icon(Icons.chevron_left, color: Colors.white54),
                    onTap: () => Navigator.push(context, MaterialPageRoute(
                      builder: (_) => DirectChatPage(conversationId: doc.id, otherUid: otherUid, otherName: name),
                    )),
                  ),
                );
              },
            );
          },
        ),
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: _dmBrand,
          foregroundColor: Colors.white,
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const _StartDirectMessagePage())),
          icon: const Icon(Icons.edit),
          label: const Text('محادثة جديدة'),
        ),
      ),
    );
  }
}

class _StartDirectMessagePage extends StatefulWidget {
  const _StartDirectMessagePage();

  @override
  State<_StartDirectMessagePage> createState() => _StartDirectMessagePageState();
}

class _StartDirectMessagePageState extends State<_StartDirectMessagePage> {
  final _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final me = FirebaseAuth.instance.currentUser;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('محادثة جديدة'), backgroundColor: const Color(0xFF171936), foregroundColor: Colors.white),
        backgroundColor: const Color(0xFF111321),
        body: Column(children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: TextField(
              controller: _search,
              onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'ابحث عن عضو بالاسم',
                hintStyle: const TextStyle(color: Colors.white54),
                prefixIcon: const Icon(Icons.search, color: Colors.white70),
                filled: true, fillColor: const Color(0xFF1B1D32),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _dmDb.collection('publicProfiles').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) return const Center(child: Text('تعذر تحميل الأعضاء', style: TextStyle(color: Colors.white70)));
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: _dmBrand));
                final docs = snapshot.data!.docs.where((d) =>
                  d.id != me?.uid && (d.data()['name']?.toString().toLowerCase().contains(_query) ?? false)).toList();
                if (docs.isEmpty) return const Center(child: Text('ما لقينا أعضاء بهذا الاسم', style: TextStyle(color: Colors.white60)));
                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, i) {
                    final d = docs[i];
                    final name = d.data()['name']?.toString() ?? 'عضو';
                    return ListTile(
                      leading: CircleAvatar(backgroundColor: _dmBrand.withValues(alpha: .22), child: const Icon(Icons.person, color: Colors.white)),
                      title: Text(name, style: const TextStyle(color: Colors.white)),
                      trailing: const Icon(Icons.chat_bubble_outline, color: Color(0xFFB9AEFF)),
                      onTap: () async {
                        final uid = me?.uid;
                        if (uid == null) return;
                        final ids = [uid, d.id]..sort();
                        final id = '${ids[0]}_${ids[1]}';
                        final ref = _dmDb.collection('conversations').doc(id);
                        final existing = await ref.get();
                        if (!existing.exists) {
                          final mine = await _dmDb.collection('publicProfiles').doc(uid).get();
                          await ref.set({
                            'members': ids,
                            'memberNames': {
                              uid: mine.data()?['name'] ?? me?.displayName ?? 'عضو',
                              d.id: name,
                            },
                            'updatedAt': FieldValue.serverTimestamp(),
                          });
                        }
                        if (!mounted) return;
                        Navigator.pushReplacement(context, MaterialPageRoute(
                          builder: (_) => DirectChatPage(conversationId: id, otherUid: d.id, otherName: name),
                        ));
                      },
                    );
                  },
                );
              },
            ),
          ),
        ]),
      ),
    );
  }
}

class DirectChatPage extends StatefulWidget {
  final String conversationId;
  final String otherUid;
  final String otherName;

  const DirectChatPage({super.key, required this.conversationId, required this.otherUid, required this.otherName});

  @override
  State<DirectChatPage> createState() => _DirectChatPageState();
}

class _DirectChatPageState extends State<DirectChatPage> {
  final _text = TextEditingController();
  bool _sending = false;
  String? _error;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final user = FirebaseAuth.instance.currentUser;
    final text = _text.text.trim();
    if (user == null || text.isEmpty || _sending) return;
    setState(() { _sending = true; _error = null; });
    try {
      final conversation = _dmDb.collection('conversations').doc(widget.conversationId);
      // The client can read only its own block records; the Firestore rule
      // independently checks both directions before accepting a message.
      final blockedA = await _dmDb.collection('userBlocks').doc('${user.uid}_${widget.otherUid}').get();
      if (blockedA.exists) {
        setState(() => _error = 'لا يمكن المراسلة بسبب وجود حظر بين الحسابين.');
        return;
      }
      final sanction = await _dmDb.collection('userSanctions').doc(user.uid).get();
      final data = sanction.data() ?? <String, dynamic>{};
      final now = Timestamp.now();
      final muted = data['permanentMute'] == true ||
        (data['muteUntil'] is Timestamp && (data['muteUntil'] as Timestamp).compareTo(now) > 0);
      final banned = data['permanentBan'] == true ||
        (data['banUntil'] is Timestamp && (data['banUntil'] as Timestamp).compareTo(now) > 0);
      if (muted || banned) {
        setState(() => _error = banned ? 'حسابك موقوف عن استخدام المراسلة.' : 'حسابك مكتوم حالياً.');
        return;
      }
      final value = text;
      await conversation.collection('messages').add({
        'senderId': user.uid,
        'senderRole': user.email?.toLowerCase() == _dmFounderEmail ? 'founder' : 'member',
        'text': value,
        'type': 'text',
        'createdAt': FieldValue.serverTimestamp(),
      });
      await conversation.update({
        'lastMessage': value,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      _text.clear();
    } on FirebaseException catch (e) {
      setState(() => _error = 'تعذر الإرسال: ${e.code}');
    } catch (_) {
      setState(() => _error = 'تعذر إرسال الرسالة. حاول مرة ثانية.');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFF111321),
        appBar: AppBar(
          title: Text(widget.otherName),
          backgroundColor: const Color(0xFF171936),
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              tooltip: 'تحديث المحادثة',
              onPressed: () => setState(() => _error = null),
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        body: Column(children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _dmDb.collection('conversations').doc(widget.conversationId)
                .collection('messages').orderBy('createdAt', descending: true).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) return _InboxState(
                  icon: Icons.lock_outline,
                  title: 'تعذر تحميل الرسائل',
                  detail: 'رمز الخطأ: ${snapshot.error is FirebaseException ? (snapshot.error as FirebaseException).code : 'unknown'}',
                  retry: () => setState(() {}),
                );
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: _dmBrand));
                if (snapshot.data!.docs.isEmpty) return const Center(
                  child: Text('ابدأوا الحديث 👋', style: TextStyle(color: Colors.white60, fontSize: 17)),
                );
                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.all(14),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final msg = snapshot.data!.docs[index].data();
                    final mine = msg['senderId'] == user?.uid;
                    final time = msg['createdAt'] is Timestamp
                      ? TimeOfDay.fromDateTime((msg['createdAt'] as Timestamp).toDate()).format(context)
                      : '';
                    return Align(
                      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * .78),
                        margin: const EdgeInsets.symmetric(vertical: 5),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: mine ? const [Color(0xFF6554D9), Color(0xFF4939A8)] : const [Color(0xFF292C43), Color(0xFF202338)],
                          ),
                          borderRadius: BorderRadius.circular(17),
                          border: Border.all(color: Colors.white.withValues(alpha: .09)),
                        ),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(msg['text']?.toString() ?? '', style: const TextStyle(color: Colors.white, fontSize: 15)),
                          if (time.isNotEmpty) Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(time, style: const TextStyle(color: Colors.white60, fontSize: 10)),
                          ),
                        ]),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          if (_error != null) Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            child: Text(_error!, style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Row(children: [
                Expanded(child: TextField(
                  controller: _text,
                  minLines: 1,
                  maxLines: 5,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'اكتب رسالتك...',
                    hintStyle: const TextStyle(color: Colors.white54),
                    filled: true, fillColor: const Color(0xFF202338),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                  ),
                  onSubmitted: (_) => _send(),
                )),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: _sending ? null : _send,
                  style: IconButton.styleFrom(backgroundColor: _dmBrand, foregroundColor: Colors.white),
                  icon: _sending
                    ? const SizedBox(width: 19, height: 19, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.send_rounded),
                ),
              ]),
            ),
          ),
        ]),
      ),
    );
  }
}

class _InboxState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String detail;
  final VoidCallback retry;

  const _InboxState({required this.icon, required this.title, required this.detail, this.retry = _noop});
  static void _noop() {}

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 54, color: Colors.white),
        const SizedBox(height: 18),
        Text(title, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        Text(detail, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70)),
        if (retry != _noop) ...[
          const SizedBox(height: 18),
          OutlinedButton.icon(onPressed: retry, icon: const Icon(Icons.refresh), label: const Text('إعادة المحاولة')),
        ],
      ]),
    ),
  );
}
