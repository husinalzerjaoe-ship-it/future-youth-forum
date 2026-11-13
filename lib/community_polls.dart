import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

const _pollBrand = Color(0xFF6554D9);
final _pollDb = FirebaseFirestore.instance;
String get _pollUid => FirebaseAuth.instance.currentUser!.uid;

class CommunityPollsPage extends StatelessWidget {
  const CommunityPollsPage({super.key});

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.rtl,
    child: Scaffold(
      appBar: AppBar(title: const Text('تصويتات الملتقى')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _createPoll(context),
        icon: const Icon(Icons.add_chart),
        label: const Text('تصويت جديد'),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _pollDb.collection('communityPolls')
          .orderBy('createdAt', descending: true).limit(60).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return const Center(child: Text('تعذر تحميل التصويتات. تحقق من نشر قواعد Firestore.'));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) return const _PollEmpty();
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 90),
            itemCount: docs.length,
            itemBuilder: (context, index) => _PollCard(doc: docs[index]),
          );
        },
      ),
    ),
  );

  Future<void> _createPoll(BuildContext context) async {
    final question = TextEditingController();
    final options = [TextEditingController(), TextEditingController()];
    final formKey = GlobalKey<FormState>();
    bool busy = false;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialog) => Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Text('إنشاء تصويت'),
            content: SizedBox(
              width: 420,
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    TextFormField(
                      controller: question, maxLength: 160,
                      decoration: const InputDecoration(labelText: 'السؤال', border: OutlineInputBorder()),
                      validator: (v) => v == null || v.trim().length < 5 ? 'اكتب سؤالاً واضحاً' : null,
                    ),
                    const SizedBox(height: 12),
                    ...List.generate(options.length, (i) => Padding(
                      padding: const EdgeInsets.only(bottom: 9),
                      child: TextFormField(
                        controller: options[i], maxLength: 80,
                        decoration: InputDecoration(labelText: 'الخيار ${i + 1}', border: const OutlineInputBorder()),
                        validator: (v) => v == null || v.trim().isEmpty ? 'اكتب الخيار' : null,
                      ),
                    )),
                    if (options.length < 5)
                      Align(alignment: Alignment.centerRight, child: TextButton.icon(
                        onPressed: () => setDialog(() => options.add(TextEditingController())),
                        icon: const Icon(Icons.add), label: const Text('إضافة خيار'),
                      )),
                    const Text('كل عضو يقدر يصوّت مرة واحدة، والتصويت ما يكشف اختيارك للآخرين.', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ]),
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: busy ? null : () => Navigator.pop(dialogContext), child: const Text('إلغاء')),
              FilledButton(
                onPressed: busy ? null : () async {
                  if (!formKey.currentState!.validate()) return;
                  setDialog(() => busy = true);
                  try {
                    await _pollDb.collection('communityPolls').add({
                      'question': question.text.trim(),
                      'options': options.map((e) => e.text.trim()).toList(),
                      'createdBy': _pollUid,
                      'createdAt': FieldValue.serverTimestamp(),
                      'active': true,
                    });
                    if (dialogContext.mounted) Navigator.pop(dialogContext);
                  } catch (_) {
                    setDialog(() => busy = false);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تعذر إنشاء التصويت. تحقق من قواعد Firestore.')));
                  }
                },
                child: busy ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('نشر التصويت'),
              ),
            ],
          ),
        ),
      ),
    );
    question.dispose();
    for (final option in options) { option.dispose(); }
  }
}

class _PollCard extends StatelessWidget {
  final QueryDocumentSnapshot<Map<String, dynamic>> doc;
  const _PollCard({required this.doc});

  @override
  Widget build(BuildContext context) {
    final data = doc.data();
    final options = (data['options'] as List<dynamic>? ?? []).whereType<String>().toList();
    if (options.length < 2 || options.length > 5) return const SizedBox.shrink();
    final votes = doc.reference.collection('votes');
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: votes.snapshots(),
      builder: (context, voteSnapshot) {
        final voteDocs = voteSnapshot.data?.docs ?? [];
        final counts = List<int>.filled(options.length, 0);
        for (final vote in voteDocs) {
          final choice = vote.data()['option'];
          if (choice is int && choice >= 0 && choice < counts.length) counts[choice]++;
        }
        return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: votes.doc(_pollUid).snapshots(),
          builder: (context, myVoteSnapshot) {
            final myChoice = myVoteSnapshot.data?.data()?['option'];
            final hasVoted = myChoice is int && myChoice >= 0 && myChoice < options.length;
            final total = counts.fold<int>(0, (sum, value) => sum + value);
            final mine = data['createdBy'] == _pollUid;
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(15),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    const Icon(Icons.poll_rounded, color: _pollBrand),
                    const SizedBox(width: 8),
                    Expanded(child: Text(data['question'] as String? ?? 'تصويت', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold))),
                    if (mine || FirebaseAuth.instance.currentUser?.email?.toLowerCase() == 'husinalzerjaoe@gmail.com')
                      IconButton(tooltip: 'حذف التصويت', onPressed: () => _confirmDelete(context), icon: const Icon(Icons.delete_outline)),
                  ]),
                  const SizedBox(height: 8),
                  ...List.generate(options.length, (i) {
                    final percent = total == 0 ? 0.0 : counts[i] / total;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 9),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: hasVoted || data['active'] == false ? null : () => _vote(context, i),
                        child: Container(
                          padding: const EdgeInsets.all(11),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: myChoice == i ? _pollBrand : Colors.transparent, width: 1.5),
                          ),
                          child: Column(children: [
                            Row(children: [
                              Expanded(child: Text(options[i], style: const TextStyle(fontWeight: FontWeight.w600))),
                              if (hasVoted || data['active'] == false)
                                Text('${(percent * 100).round()}%  •  ${counts[i]}'),
                              if (myChoice == i) const Padding(padding: EdgeInsets.only(right: 6), child: Icon(Icons.check_circle, color: _pollBrand, size: 18)),
                            ]),
                            if (hasVoted || data['active'] == false) ...[
                              const SizedBox(height: 7),
                              ClipRRect(borderRadius: BorderRadius.circular(20), child: LinearProgressIndicator(value: percent, minHeight: 7)),
                            ],
                          ]),
                        ),
                      ),
                    );
                  }),
                  Row(children: [
                    Text('$total'.replaceFirst('$', '') + ' صوت', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    const Spacer(),
                    Text(hasVoted ? 'صوّتت بالفعل' : (data['active'] == false ? 'منتهي' : 'اختر إجابتك'), style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  ]),
                ]),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _vote(BuildContext context, int option) async {
    try {
      await doc.reference.collection('votes').doc(_pollUid).set({
        'uid': _pollUid, 'option': option, 'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ما قدرنا نسجل صوتك. يمكن سبق وصوّت أو تحتاج تحديث القواعد.')));
    }
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final yes = await showDialog<bool>(context: context, builder: (c) => Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        title: const Text('حذف التصويت؟'),
        content: const Text('سيختفي التصويت وأصواته من القائمة.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('إلغاء')),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('حذف')),
        ],
      ),
    ));
    if (yes != true) return;
    try {
      final votes = await doc.reference.collection('votes').get();
      final batch = _pollDb.batch();
      for (final vote in votes.docs) { batch.delete(vote.reference); }
      batch.delete(doc.reference);
      await batch.commit();
    } catch (_) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تعذر حذف التصويت.')));
    }
  }
}

class _PollEmpty extends StatelessWidget {
  const _PollEmpty();
  @override
  Widget build(BuildContext context) => Center(child: Padding(
    padding: const EdgeInsets.all(28),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.how_to_vote_outlined, size: 64, color: _pollBrand),
      const SizedBox(height: 12),
      const Text('ماكو تصويتات حالياً', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      const Text('ابدأ أول تصويت وخلي أعضاء الملتقى يشاركون برأيهم.'),
    ]),
  ));
}
