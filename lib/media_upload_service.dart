import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
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
    case 'posts':
    case 'voice-messages':
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

  // Existing accounts may predate the onUserCreated trigger. This callable
  // safely adds role=authenticated to the current user's custom claims.
  try {
    await FirebaseFunctions.instance
        .httpsCallable('ensureSupabaseAuthenticatedRole')
        .call();
  } on FirebaseFunctionsException catch (e) {
    throw StateError('تعذر تجهيز صلاحية رفع الوسائط (' + e.code + '). شغّل نشر Cloud Functions ثم أعد تسجيل الدخول.');
  }

  final token = await user.getIdToken(true);
  if (token == null || token.split('.').length != 3) {
    throw StateError('تعذر تحديث رمز تسجيل الدخول. سجّل خروج وادخل من جديد.');
  }
  Map<String, dynamic> claims;
  try {
    final payload = token.split('.')[1];
    claims = jsonDecode(
      utf8.decode(base64Url.decode(base64Url.normalize(payload))),
    ) as Map<String, dynamic>;
  } catch (_) {
    throw StateError('رمز Firebase غير صالح. سجّل خروج وادخل من جديد.');
  }
  if (claims['sub'] != user.uid || claims['aud'] != 'futureyouth-69f8a'
      || claims['iss'] != 'https://securetoken.google.com/futureyouth-69f8a') {
    throw StateError('هوية Firebase لا تطابق مشروع التطبيق. راجع إعداد Firebase Third-party Auth في Supabase.');
  }
  if (claims['role'] != 'authenticated') {
    throw StateError('Firebase لم يضف صلاحية authenticated بعد. انشر Cloud Functions ثم سجّل خروج وادخل من جديد.');
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
  try {
    await storage.uploadBinary(
      path,
      bytes,
      fileOptions: FileOptions(contentType: contentType, upsert: false),
    );
  } on StorageException catch (e) {
    final detail = e.message.toLowerCase();
    if (detail.contains('firebase') || detail.contains('third-party')
        || detail.contains('jwt') || detail.contains('unauthorized')) {
      throw StateError('Supabase لم يتعرف على رمز Firebase. فعّل Firebase من Authentication → Third-Party Auth في مشروع Supabase ثم أعد تسجيل الدخول. (' + (e.statusCode ?? 'Auth').toString() + ')');
    }
    rethrow;
  }
  return storage.getPublicUrl(path);
}
