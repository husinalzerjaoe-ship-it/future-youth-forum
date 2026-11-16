import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

const _titleFounderEmail = 'husinalzerjaoe@gmail.com';

class MemberTitleBadge extends StatelessWidget {
  final String title;
  final int? colorValue, endColorValue;
  final String fontStyle, icon;
  final bool compact, gradient, glow;
  final Timestamp? expiresAt;
  const MemberTitleBadge({super.key, required this.title, this.colorValue, this.endColorValue,
    this.fontStyle = 'default', this.icon = '', this.gradient = false, this.glow = false,
    this.expiresAt, this.compact = false});

  factory MemberTitleBadge.fromProfile({required String title, required Map<String, dynamic> profile, bool compact = false}) {
    return MemberTitleBadge(
      title: title,
      colorValue: profile['customTitleColor'] is int ? profile['customTitleColor'] as int : null,
      endColorValue: profile['customTitleEndColor'] is int ? profile['customTitleEndColor'] as int : null,
      fontStyle: (profile['customTitleFont'] ?? 'default').toString(),
      icon: (profile['customTitleIcon'] ?? '').toString(),
      gradient: profile['customTitleGradient'] == true,
      glow: profile['customTitleGlow'] == true,
      expiresAt: profile['customTitleExpiresAt'] is Timestamp ? profile['customTitleExpiresAt'] as Timestamp : null,
      compact: compact,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (expiresAt != null && expiresAt!.toDate().isBefore(DateTime.now())) return const SizedBox.shrink();
    final color = Color(colorValue ?? 0xFF6554D9);
    final end = Color(endColorValue ?? 0xFF13A89E);
    final family = switch (fontStyle) { 'serif' => 'serif', 'mono' => 'monospace', _ => null };
    return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 7 : 10, vertical: compact ? 3 : 5),
      decoration: BoxDecoration(
        color: gradient ? null : color.withValues(alpha: .12),
        gradient: gradient ? LinearGradient(colors: [color.withValues(alpha: .24), end.withValues(alpha: .24)]) : null,
        border: Border.all(color: color.withValues(alpha: .75)),
        borderRadius: BorderRadius.circular(30),
        boxShadow: glow ? [BoxShadow(color: color.withValues(alpha: .35), blurRadius: compact ? 7 : 13)] : const [],
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (icon.isNotEmpty) ...[Text(icon, style: TextStyle(fontSize: compact ? 10 : 13)), const SizedBox(width: 4)],
        Text(title, maxLines: 1, overflow: TextOverflow.ellipsis,
          style: TextStyle(color: color, fontFamily: family, fontSize: compact ? 9 : 11, fontWeight: FontWeight.w900, letterSpacing: fontStyle == 'mono' ? .5 : 0)),
      ]),
    );
  }
}

class FounderMemberTitlesPage extends StatefulWidget {
  const FounderMemberTitlesPage({super.key});
  @override State<FounderMemberTitlesPage> createState() => _FounderMemberTitlesPageState();
}
class _FounderMemberTitlesPageState extends State<FounderMemberTitlesPage> {
  final _search = TextEditingController();
  static const _colors = <int>[0xFF6554D9,0xFF168E9B,0xFFD18A16,0xFFB33B72,0xFF2E7D52,0xFF2875B8,0xFF8A55B5,0xFF455A64];
  bool get _isFounder => FirebaseAuth.instance.currentUser?.email?.toLowerCase() == _titleFounderEmail;
  @override void dispose() { _search.dispose(); super.dispose(); }

  Future<void> _editTitle(String uid, String name, Map<String, dynamic> profile) async {
    final controller = TextEditingController(text: (profile['customTitle'] ?? '').toString());
    final iconController = TextEditingController(text: (profile['customTitleIcon'] ?? '').toString());
    var selectedColor = profile['customTitleColor'] is int ? profile['customTitleColor'] as int : _colors.first;
    var endColor = profile['customTitleEndColor'] is int ? profile['customTitleEndColor'] as int : 0xFF13A89E;
    var fontStyle = (profile['customTitleFont'] ?? 'default').toString();
    var gradient = profile['customTitleGradient'] == true;
    var glow = profile['customTitleGlow'] == true;
    var duration = 'permanent';
    final saved = await showDialog<bool>(context: context,
      builder: (dialogContext) => StatefulBuilder(builder: (context, setDialogState) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: Text(oldTitle.isEmpty ? 'منح لقب لـ $name' : 'تعديل لقب $name'),
          content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            TextField(controller: controller, autofocus: true, maxLength: 32,
              decoration: const InputDecoration(labelText: 'اللقب المخصص', hintText: 'مثلاً: نجم الملتقى', border: OutlineInputBorder())),
            const SizedBox(height: 12), const Text('لون اللقب', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(spacing: 10, runSpacing: 10, children: _colors.map((value) => InkWell(
              onTap: () => setDialogState(() => selectedColor = value), borderRadius: BorderRadius.circular(30),
              child: Container(width: 34, height: 34, decoration: BoxDecoration(color: Color(value), shape: BoxShape.circle,
                border: Border.all(color: selectedColor == value ? Colors.black : Colors.transparent, width: 3)),
                child: selectedColor == value ? const Icon(Icons.check, color: Colors.white, size: 18) : null),
            )).toList()),
            const SizedBox(height: 12),
            TextField(controller: iconController, maxLength: 4, decoration: const InputDecoration(labelText: 'رمز أو إيموجي اختياري', hintText: '⭐')),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: fontStyle,
              decoration: const InputDecoration(labelText: 'نوع الخط'),
              items: const [
                DropdownMenuItem(value: 'default', child: Text('عريض حديث')),
                DropdownMenuItem(value: 'serif', child: Text('كلاسيكي')),
                DropdownMenuItem(value: 'mono', child: Text('تقني')),
              ],
              onChanged: (v) { if (v != null) setDialogState(() => fontStyle = v); },
            ),
            const SizedBox(height: 8),
            CheckboxListTile(contentPadding: EdgeInsets.zero, value: gradient, onChanged: (v) => setDialogState(() => gradient = v ?? false), title: const Text('تدرج بلونين')),
            if (gradient) Wrap(spacing: 10, runSpacing: 10, children: _colors.map((value) => InkWell(
              onTap: () => setDialogState(() => endColor = value), borderRadius: BorderRadius.circular(30),
              child: Container(width: 30, height: 30, decoration: BoxDecoration(color: Color(value), shape: BoxShape.circle,
                border: Border.all(color: endColor == value ? Colors.white : Colors.transparent, width: 3)),
                child: endColor == value ? const Icon(Icons.check, color: Colors.white, size: 16) : null),
            )).toList()),
            CheckboxListTile(contentPadding: EdgeInsets.zero, value: glow, onChanged: (v) => setDialogState(() => glow = v ?? false), title: const Text('تأثير توهج')),
            DropdownButtonFormField<String>(
              value: duration,
              decoration: const InputDecoration(labelText: 'مدة اللقب'),
              items: const [
                DropdownMenuItem(value: 'permanent', child: Text('دائم')),
                DropdownMenuItem(value: '7', child: Text('7 أيام')),
                DropdownMenuItem(value: '30', child: Text('30 يوماً')),
                DropdownMenuItem(value: '90', child: Text('90 يوماً')),
              ],
              onChanged: (v) { if (v != null) setDialogState(() => duration = v); },
            ),
            const SizedBox(height: 8), const Text('اترك خانة اللقب فارغة لإزالة اللقب من العضو.', style: TextStyle(fontSize: 12, color: Colors.grey)),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('إلغاء')),
            FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('حفظ اللقب')),
          ],
        ),
      )),
    );
    if (saved == true && mounted) {
      final value = controller.text.trim();
      try {
        await FirebaseFirestore.instance.collection('publicProfiles').doc(uid).update({
          'customTitle': value,
          'customTitleColor': selectedColor,
          'customTitleEndColor': endColor,
          'customTitleFont': fontStyle,
          'customTitleGradient': gradient,
          'customTitleGlow': glow,
          'customTitleIcon': iconController.text.trim(),
          'customTitleExpiresAt': duration == 'permanent'
              ? null
              : Timestamp.fromDate(DateTime.now().add(Duration(days: int.parse(duration)))),
          'customTitleUpdatedAt': FieldValue.serverTimestamp(),
        });
        await FirebaseFirestore.instance.collection('adminLogs').add({
          'actorId': FirebaseAuth.instance.currentUser!.uid, 'targetId': uid, 'targetName': name,
          'action': value.isEmpty ? 'remove_custom_title' : 'set_custom_title', 'createdAt': FieldValue.serverTimestamp(),
        });
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value.isEmpty ? 'تمت إزالة لقب $name' : 'تم منح $name لقب «$value»')));
      } catch (_) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تعذر حفظ اللقب. تأكد من نشر قواعد Firestore المحدثة.')));
      }
    }
    controller.dispose();
    iconController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isFounder) return const Scaffold(body: Center(child: Text('هذه الصفحة للمؤسس فقط.')));
    return Directionality(textDirection: TextDirection.rtl, child: Scaffold(
      appBar: AppBar(title: const Text('إدارة ألقاب الأعضاء')),
      body: Column(children: [
        Padding(padding: const EdgeInsets.all(12), child: TextField(controller: _search, onChanged: (_) => setState(() {}),
          decoration: InputDecoration(prefixIcon: const Icon(Icons.search), hintText: 'ابحث باسم العضو...',
            suffixIcon: _search.text.isEmpty ? null : IconButton(onPressed: () { _search.clear(); setState(() {}); }, icon: const Icon(Icons.close)),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16))))),
        const Padding(padding: EdgeInsets.fromLTRB(14,0,14,10), child: Text(
          'الألقاب التي تمنحها هنا تظهر في الملف الشخصي والدردشة والغرف الإقليمية. يمكنك تغييرها أو حذفها بأي وقت.',
          style: TextStyle(fontSize: 12, color: Colors.grey))),
        Expanded(child: StreamBuilder<QuerySnapshot<Map<String,dynamic>>>(
          stream: FirebaseFirestore.instance.collection('publicProfiles').orderBy('name').limit(300).snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) return const Center(child: Text('تعذر تحميل الأعضاء.'));
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
            final q = _search.text.trim().toLowerCase();
            final members = snapshot.data!.docs.where((doc) {
              final name = (doc.data()['name'] ?? '').toString().toLowerCase();
              return q.isEmpty || name.contains(q) || doc.id.toLowerCase().contains(q);
            }).toList();
            if (members.isEmpty) return const Center(child: Text('ماكو أعضاء مطابقين للبحث.'));
            return ListView.builder(itemCount: members.length, itemBuilder: (context,index) {
              final doc = members[index]; final data = doc.data();
              final name = (data['name'] ?? 'عضو').toString();
              final title = (data['customTitle'] ?? '').toString().trim();
              final color = data['customTitleColor'] is int ? data['customTitleColor'] as int : null;
              return Card(margin: const EdgeInsets.symmetric(horizontal:12,vertical:5), child: ListTile(
                leading: CircleAvatar(child: Text(name.isEmpty ? '؟' : name.characters.first)),
                title: Text(name,maxLines:1,overflow:TextOverflow.ellipsis),
                subtitle: title.isEmpty ? const Text('بدون لقب مخصص') : Padding(padding: const EdgeInsets.only(top:5),
                  child: Align(alignment:Alignment.centerRight,child:MemberTitleBadge(title:title,colorValue:color))),
                trailing: const Icon(Icons.edit_outlined),
                onTap: () => _editTitle(doc.id, name, data),
              ));
            });
          },
        )),
      ]),
    ));
  }
}
