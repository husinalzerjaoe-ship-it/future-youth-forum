import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

const _v39FounderEmail = 'husinalzerjaoe@gmail.com';
final _v39LinksDb = FirebaseFirestore.instance;

class V39CreatorLinksPage extends StatelessWidget {
  const V39CreatorLinksPage({super.key});

  bool get _isFounder =>
      FirebaseAuth.instance.currentUser?.email?.toLowerCase() == _v39FounderEmail;

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.rtl,
    child: Scaffold(
      appBar: AppBar(
        title: const Text('حسابات المطوّر'),
        actions: [
          if (_isFounder)
            IconButton(
              tooltip: 'إدارة الروابط وإعدادات الدردشة',
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => _edit(context),
            ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: _v39LinksDb.collection('developerLinks').doc('main').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('تعذر تحميل روابط المطوّر حالياً'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snapshot.data!.data() ?? {};
          const entries = <({String key, String title, IconData icon})>[
            (key: 'telegram', title: 'تيليگرام', icon: Icons.send_rounded),
            (key: 'instagram', title: 'إنستغرام', icon: Icons.camera_alt_outlined),
            (key: 'tiktok', title: 'تيك توك', icon: Icons.music_note_rounded),
            (key: 'youtube', title: 'يوتيوب', icon: Icons.play_circle_outline_rounded),
            (key: 'website', title: 'الموقع الإلكتروني', icon: Icons.language_rounded),
          ];
          final active = entries.where((entry) {
            final value = (data[entry.key] ?? '').toString().trim();
            return value.startsWith('https://') || value.startsWith('http://');
          }).toList();
          return ListView(
            padding: const EdgeInsets.all(18),
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF171936), Color(0xFF6554D9), Color(0xFF16A6B8)],
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                  ),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.verified_rounded, color: Color(0xFFFFD36A), size: 34),
                    SizedBox(height: 12),
                    Text('مجتمع ملتقى شباب المستقبل',
                      style: TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.w900)),
                    SizedBox(height: 6),
                    Text('تابع حسابات المطوّر الرسمية وروابط التواصل.',
                      style: TextStyle(color: Colors.white70, height: 1.5)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (active.isEmpty)
                Card(child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(children: [
                    const Icon(Icons.link_off_rounded, size: 36),
                    const SizedBox(height: 8),
                    const Text('لم تُضف روابط بعد'),
                    if (_isFounder)
                      const Text('اضغط زر التعديل بالأعلى لإضافة حساباتك وروابط قنواتك.',
                        textAlign: TextAlign.center),
                  ]),
                )),
              ...active.map((entry) {
                final url = data[entry.key].toString().trim();
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(child: Icon(entry.icon)),
                    title: Text(entry.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(url, maxLines: 1, overflow: TextOverflow.ellipsis),
                    trailing: const Icon(Icons.open_in_new_rounded),
                    onTap: () => _open(context, url),
                  ),
                );
              }),
              const SizedBox(height: 14),
              if (_isFounder)
                const Text('أنت تدخل بصلاحية المؤسس. الروابط وإعدادات التحكم محفوظة في Firestore ويشاهدها الأعضاء.',
                  style: TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          );
        },
      ),
    ),
  );

  Future<void> _open(BuildContext context, String value) async {
    final uri = Uri.tryParse(value);
    if (uri == null || !['https', 'http'].contains(uri.scheme) || uri.host.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرابط غير صالح')),
      );
      return;
    }
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication) && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر فتح الرابط')),
      );
    }
  }

  Future<void> _edit(BuildContext context) async {
    final linksRef = _v39LinksDb.collection('developerLinks').doc('main');
    final controlsRef = _v39LinksDb.collection('chatControls').doc('main');
    final links = (await linksRef.get()).data() ?? {};
    final controls = (await controlsRef.get()).data() ?? {};
    final fields = <String, TextEditingController>{
      'telegram': TextEditingController(text: (links['telegram'] ?? '').toString()),
      'instagram': TextEditingController(text: (links['instagram'] ?? '').toString()),
      'tiktok': TextEditingController(text: (links['tiktok'] ?? '').toString()),
      'youtube': TextEditingController(text: (links['youtube'] ?? '').toString()),
      'website': TextEditingController(text: (links['website'] ?? '').toString()),
    };
    bool allowLinks = controls['allowLinks'] != false;
    bool allowMedia = controls['allowMedia'] != false;
    bool directMessagesEnabled = controls['directMessagesEnabled'] != false;
    bool publicChatEnabled = controls['publicChatEnabled'] != false;
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Text('إدارة حسابات المطوّر والدردشة'),
            content: SizedBox(
              width: 440,
              child: SingleChildScrollView(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  for (final entry in fields.entries)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 9),
                      child: TextField(
                        controller: entry.value,
                        keyboardType: TextInputType.url,
                        decoration: InputDecoration(
                          labelText: switch (entry.key) {
                            'telegram' => 'رابط تيليگرام',
                            'instagram' => 'رابط إنستغرام',
                            'tiktok' => 'رابط تيك توك',
                            'youtube' => 'رابط يوتيوب',
                            _ => 'رابط الموقع',
                          },
                          prefixIcon: const Icon(Icons.link_rounded),
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ),
                  const Divider(height: 24),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('السماح بروابط المواقع داخل الدردشة'),
                    value: allowLinks,
                    onChanged: (v) => setDialogState(() => allowLinks = v),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('السماح بإرسال الصور والفيديو والصوت'),
                    value: allowMedia,
                    onChanged: (v) => setDialogState(() => allowMedia = v),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('تشغيل المحادثات الخاصة'),
                    value: directMessagesEnabled,
                    onChanged: (v) => setDialogState(() => directMessagesEnabled = v),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('تشغيل الدردشة العامة'),
                    value: publicChatEnabled,
                    onChanged: (v) => setDialogState(() => publicChatEnabled = v),
                  ),
                  const Text('هذه الإعدادات عامة لكل الأعضاء. لا تغيّر صلاحيات المكالمات أو غرف المشاهدة.',
                    style: TextStyle(fontSize: 11, color: Colors.grey)),
                ]),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('إلغاء')),
              FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('حفظ')),
            ],
          ),
        ),
      ),
    );
    if (saved == true) {
      try {
        final values = <String, String>{};
        for (final entry in fields.entries) {
          final value = entry.value.text.trim();
          if (value.isNotEmpty) {
            final uri = Uri.tryParse(value);
            if (uri == null || uri.host.isEmpty || !['https', 'http'].contains(uri.scheme)) {
              throw const FormatException('استخدم رابطاً يبدأ بـ https://');
            }
          }
          values[entry.key] = value;
        }
        await linksRef.set({...values, 'updatedAt': FieldValue.serverTimestamp()});
        await controlsRef.set({
          'allowLinks': allowLinks,
          'allowMedia': allowMedia,
          'directMessagesEnabled': directMessagesEnabled,
          'publicChatEnabled': publicChatEnabled,
          'updatedAt': FieldValue.serverTimestamp(),
          'updatedBy': FirebaseAuth.instance.currentUser!.uid,
        });
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حفظ الروابط وإعدادات الدردشة')));
        }
      } catch (error) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تعذر الحفظ: $error')));
        }
      }
    }
    for (final controller in fields.values) {
      controller.dispose();
    }
  }
}
