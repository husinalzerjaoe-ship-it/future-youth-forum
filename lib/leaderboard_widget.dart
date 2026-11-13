import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Live ranking. Weekly points are written by trusted Cloud Functions.
class _Leaderboard extends StatelessWidget {
  const _Leaderboard();

  @override
  Widget build(BuildContext context) {
    final db = FirebaseFirestore.instance;
    final week = _weekKey(DateTime.now());
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('🏆 متصدرون هذا الأسبوع', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: db.collection('publicProfiles').orderBy('points', descending: true).limit(50).snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) return const Text('الترتيب غير متاح حالياً.');
              if (!snapshot.hasData) return const LinearProgressIndicator();
              final docs = snapshot.data!.docs;
              docs.sort((a, b) {
                final av = (a.data()['weeklyPoints'] as Map<String, dynamic>?)?[week] as num? ?? 0;
                final bv = (b.data()['weeklyPoints'] as Map<String, dynamic>?)?[week] as num? ?? 0;
                return bv.compareTo(av);
              });
              final ranked = docs.where((d) => ((d.data()['weeklyPoints'] as Map<String, dynamic>?)?[week] as num? ?? 0) > 0).take(10).toList();
              if (ranked.isEmpty) return const Text('ابدأ بالتفاعل حتى يظهر ترتيب الأسبوع هنا.');
              return Column(children: List.generate(ranked.length, (i) {
                final data = ranked[i].data();
                final points = ((data['weeklyPoints'] as Map<String, dynamic>?)?[week] as num? ?? 0).toInt();
                final messages = (data['messageCount'] as num? ?? 0).toInt();
                return ListTile(
                  dense: true,
                  leading: CircleAvatar(
                    backgroundColor: i == 0 ? const Color(0xFFFFD56A) : const Color(0xFFEDE8FF),
                    child: Text('${i + 1}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  title: Text(data['name'] as String? ?? 'عضو', maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Text('رسائل: $messages'),
                  trailing: Text('$points نقطة', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF6554D9))),
                );
              }));
            },
          ),
          const SizedBox(height: 4),
          const Text('النقاط تُحتسب تلقائياً: الرسالة +2، المنشور +5، والإعجاب الذي يصلك +1.', style: TextStyle(fontSize: 11, color: Colors.grey)),
        ]),
      ),
    );
  }

  static String _weekKey(DateTime date) {
    final d = DateTime.utc(date.year, date.month, date.day);
    final monday = d.subtract(Duration(days: d.weekday - 1));
    return monday.toIso8601String().substring(0, 10);
  }
}
