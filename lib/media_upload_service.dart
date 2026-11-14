import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Uploads media to a user's own folder after obtaining the Supabase-compatible
/// Firebase custom claim on the trusted server.
Future<String> uploadForumMedia(
  XFile file, {
  required String folder,
  String? roomId,
}) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) throw StateError('سجّل الدخول أولاً.');

  String prefix;
  switch (folder) {
    case 'anime-wallpapers':
    case 'public-chat':
    case 'stories':
    case 'private-chat':
    case 'chat-backgrounds':
    case 'profiles':
    case 'shared-files':
      prefix = '$folder/${user.uid}/';
      break;
    case 'regional-chat':
      if (roomId == null || roomId.isEmpty) {
        throw ArgumentError('معرّف غرفة الدردشة مطلوب.');
      }
      prefix = 'regional-chat/$roomId/${user.uid}/';
      break;
    default:
      throw ArgumentError('مجلد رفع غير مسموح.');
  }

  // Supabase trusts Firebase as a Third-Party Auth provider. Firebase ID
  // tokens do not need a custom "role" claim: Supabase assigns the anon role
  // when role is absent, and the bucket RLS policies below validate the signed
  // Firebase issuer, audience, subject, and sign-in provider before allowing
  // uploads into this user's own folder.
  final token = await user.getIdToken(true);
  if (token == null || token.split('.').length != 3) {
    throw StateError('تعذر قراءة رمز تسجيل الدخول. سجّل خروج وادخل من جديد.');
  }
  final payload = token.split('.')[1];
  final claims = jsonDecode(
    utf8.decode(base64Url.decode(base64Url.normalize(payload))),
  ) as Map<String, dynamic>;
  final firebase = claims['firebase'];
  if (claims['iss'] != 'https://securetoken.google.com/futureyouth-69f8a' ||
      claims['aud'] != 'futureyouth-69f8a' ||
      claims['sub'] != user.uid ||
      firebase is! Map ||
      firebase['sign_in_provider'] == null) {
    throw StateError(
      'تعذر التحقق من هوية Firebase. تأكد من ربط Firebase كمزوّد مصادقة '
      'خارجي في إعدادات Supabase ثم سجّل الخروج والدخول.',
    );
  }

  final name = file.name.toLowerCase();
  final ext = name.contains('.') ? name.split('.').last : 'jpg';
  const mimeTypes = {
    'jpg': 'image/jpeg',
    'jpeg': 'image/jpeg',
    'png': 'image/png',
    'webp': 'image/webp',
    'gif': 'image/gif',
    'mp4': 'video/mp4',
    'mov': 'video/quicktime',
    'apk': 'application/vnd.android.package-archive',
    'xapk': 'application/octet-stream',
    'zip': 'application/zip',
    'pdf': 'application/pdf',
    'mp3': 'audio/mpeg',
    'm4a': 'audio/mp4',
    'aac': 'audio/aac',
    'wav': 'audio/wav',
    'ogg': 'audio/ogg',
    'flac': 'audio/flac',
  };
  final contentType = mimeTypes[ext];
  if (contentType == null) {
    throw ArgumentError('صيغة الملف غير مدعومة. استخدم صور JPG/PNG/WEBP/GIF أو فيديو MP4/MOV أو صوت MP3/M4A/AAC/WAV/OGG/FLAC أو APK/ZIP/PDF/XAPK.');
  }

  final bytes = await file.readAsBytes();
  if (bytes.isEmpty) throw StateError('الملف فارغ ولا يمكن رفعه.');
  final maxBytes = folder == 'shared-files' ? 100 * 1024 * 1024 : 50 * 1024 * 1024;
  if (bytes.length > maxBytes) {
    throw StateError('حجم الملف أكبر من الحد المسموح (' + (folder == 'shared-files' ? '100' : '50') + ' ميغابايت).');
  }

  final path = '$prefix${DateTime.now().microsecondsSinceEpoch}.$ext';
  final storage = Supabase.instance.client.storage.from('forum-media');
  await storage.uploadBinary(
    path,
    bytes,
    fileOptions: FileOptions(contentType: contentType, upsert: false),
  );
  return storage.getPublicUrl(path);
}
