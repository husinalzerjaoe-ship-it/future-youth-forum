import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

const _eventBrand = Color(0xFF6554D9);
final _eventDb = FirebaseFirestore.instance;
String get _eventUid => FirebaseAuth.instance.currentUser!.uid;
bool get _eventFounder => FirebaseAuth.instance.currentUser?.email?.toLowerCase() == 'husinalzerjaoe@gmail.com';

class CommunityEventsPage extends StatelessWidget {
  const CommunityEventsPage({super.key});

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.rtl,
    child: Scaffold(
      appBar: AppBar(title: const Text('فعاليات الملتقى')),
      floatingActionButton: _eventFounder ? FloatingActionButton.extended(
        onPressed: () => _create(context),
        icon: const Icon(Icons.event_available),
        label: const Text('إضافة فعالية'),
      ) : null,
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _eventDb.collection('communityEvents').orderBy('startsAt').limit(50).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return const Center(child: Text('تعذر تحميل الفعاليات. تحقق من قواعد Firestore.'));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final now = Timestamp.now();
          final events = snapshot.data!.docs.where((e) {
            final start = e.data()['startsAt'];
            return start is Timestamp && start.toDate().isAfter(now.toDate());
          }).toList();
          if (events.isEmpty) return const _NoEvents();
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 90),
            itemCount: events.length,
            itemBuilder: (context, index) => _EventCard(doc: events[index]),
          );
        },
      ),
    ),
  );

  Future<void> _create(BuildContext context) async {
    final title = TextEditingController();
    final description = TextEditingController();
    DateTime selected = DateTime.now().add(const Duration(days: 1));
    TimeOfDay time = const TimeOfDay(hour: 19, minute: 0);
    bool busy = false;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(builder: (dialogContext, setDialog) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('فعالية جديدة'),
          content: SizedBox(width: 420, child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: title, maxLength: 100, decoration: const InputDecoration(labelText: 'عنوان الفعالية')),
            TextField(controller: description, maxLength: 700, minLines: 2, maxLines: 5, decoration: const InputDecoration(labelText: 'التفاصيل')),
            const SizedBox(height: 10),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_month),
              title: const Text('التاريخ'),
              subtitle: Text('${selected.year}/${selected.month}/${selected.day}'),
              onTap: () async {
                final value = await showDatePicker(context: dialogContext, initialDate: selected, firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)));
                if (value != null) setDialog(() => selected = DateTime(value.year, value.month, value.day));
              },
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.access_time),
              title: const Text('الوقت'),
              subtitle: Text(time.format(dialogContext)),
              onTap: () async {
                final value = await showTimePicker(context: dialogContext, initialTime: time);
                if (value != null) setDialog(() => time = value);
              },
            ),
          ]))),
          actions: [
            TextButton(onPressed: busy ? null : () => Navigator.pop(dialogContext), child: const Text('إلغاء')),
            FilledButton(
              onPressed: busy ? null : () async {
                if (title.text.trim().length < 3 || description.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('اكتب عنواناً وتفاصيل للفعالية.')));
                  return;
                }
                final startsAt = DateTime(selected.year, selected.month, selected.day, time.hour, time.minute);
                if (!startsAt.isAfter(DateTime.now())) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('اختَر موعداً في المستقبل.')));
                  return;
                }
                setDialog(() => busy = true);
                try {
                  await _eventDb.collection('communityEvents').add({
                    'title': title.text.trim(),
                    'description': description.text.trim(),
                    'startsAt': Timestamp.fromDate(startsAt),
                    'createdBy': _eventUid,
                    'createdAt': FieldValue.serverTimestamp(),
                  });
                  if (dialogContext.mounted) Navigator.pop(dialogContext);
                } catch (_) {
                  setDialog(() => busy = false);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تعذر نشر الفعالية.')));
                }
              },
              child: busy ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('نشر'),
            ),
          ],
        ),
      )),
    );
    title.dispose();
    description.dispose();
  }
}

class _EventCard extends StatelessWidget {
  final QueryDocumentSnapshot<Map<String, dynamic>> doc;
  const _EventCard({required this.doc});

  @override
  Widget build(BuildContext context) {
    final data = doc.data();
    final startsAt = (data['startsAt'] as Timestamp).toDate();
    final attendeeRef = doc.reference.collection('attendees');
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: attendeeRef.snapshots(),
      builder: (context, attendees) {
        final count = attendees.data?.docs.length ?? 0;
        return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: attendeeRef.doc(_eventUid).snapshots(),
          builder: (context, mine) {
            final joined = mine.data?.exists == true;
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              clipBehavior: Clip.antiAlias,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                  width: double.infinity, padding: const EdgeInsets.all(14),
                  decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF171936), _eventBrand, Color(0xFF168E9B)])),
                  child: Row(children: [
                    const Icon(Icons.event, color: Colors.white, size: 32),
                    const SizedBox(width: 10),
                    Expanded(child: Text(data['title'] as String? ?? 'فعالية الملتقى', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18))),
                  ]),
                ),
                Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(data['description'] as String? ?? '', style: const TextStyle(height: 1.5)),
                  const SizedBox(height: 10),
                  Row(children: [
                    const Icon(Icons.calendar_month, size: 18, color: _eventBrand),
                    const SizedBox(width: 6),
                    Text('${startsAt.year}/${startsAt.month}/${startsAt.day}  •  ${TimeOfDay.fromDateTime(startsAt).format(context)}'),
                    const Spacer(),
                    const Icon(Icons.people_alt_outlined, size: 18),
                    const SizedBox(width: 4),
                    Text('$count'),
                  ]),
                  const SizedBox(height: 10),
                  SizedBox(width: double.infinity, child: FilledButton.tonal(
                    onPressed: () => _toggle(context, joined),
                    child: Text(joined ? 'إلغاء مشاركتي' : 'سجّل مشاركتك'),
                  )),
                  if (_eventFounder) Align(alignment: Alignment.centerLeft, child: TextButton.icon(
                    onPressed: () => _delete(context), icon: const Icon(Icons.delete_outline), label: const Text('حذف الفعالية'),
                  )),
                ])),
              ]),
            );
          },
        );
      },
    );
  }

  Future<void> _toggle(BuildContext context, bool joined) async {
    try {
      final ref = doc.reference.collection('attendees').doc(_eventUid);
      if (joined) {
        await ref.delete();
      } else {
        await ref.set({
          'uid': _eventUid,
          'name': (FirebaseAuth.instance.currentUser?.displayName ?? 'عضو').substring(0, (FirebaseAuth.instance.currentUser?.displayName ?? 'عضو').length > 60 ? 60 : (FirebaseAuth.instance.currentUser?.displayName ?? 'عضو').length),
          'joinedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (_) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تعذر تحديث تسجيلك.')));
    }
  }

  Future<void> _delete(BuildContext context) async {
    final yes = await showDialog<bool>(context: context, builder: (c) => Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        title: const Text('حذف الفعالية؟'),
        content: const Text('لن تظهر الفعالية بعد الحذف.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('إلغاء')),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('حذف')),
        ],
      ),
    ));
    if (yes != true) return;
    try {
      await doc.reference.delete();
    } catch (_) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تعذر حذف الفعالية.')));
    }
  }
}

class _NoEvents extends StatelessWidget {
  const _NoEvents();
  @override
  Widget build(BuildContext context) => const Center(child: Padding(
    padding: EdgeInsets.all(28),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.event_busy, size: 64, color: _eventBrand),
      SizedBox(height: 12),
      Text('ماكو فعاليات قادمة حالياً', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      Text('تابع الصفحة حتى تشوف المسابقات واللقاءات القادمة.'),
    ]),
  ));
}
