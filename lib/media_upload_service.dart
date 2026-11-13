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

  // First inspect the existing Firebase token. Most users already have the
  // Supabase authenticated claim from account creation, so do not make every
  // upload depend on a separately deployed callable function.
  Future<Map<String, dynamic>> readClaims({required bool forceRefresh}) async {
    final token = await user.getIdToken(forceRefresh);
    if (token == null || token.split('.').length != 3) {
      throw StateError('تعذر قراءة رمز تسجيل الدخول. سجّل خروج وادخل من جديد.');
    }
    final payload = token.split('.')[1];
    return jsonDecode(
      utf8.decode(base64Url.decode(base64Url.normalize(payload))),
    ) as Map<String, dynamic>;
  }

  var claims = await readClaims(forceRefresh: false);
  if (claims['role'] != 'authenticated') {
    // Backward compatibility for older accounts. If the callable is absent,
    // surface a clear setup error instead of the raw NOT_FOUND stack trace.
    try {
      await FirebaseFunctions.instance
          .httpsCallable('ensureSupabaseAuthenticatedRole')
          .call();
      claims = await readClaims(forceRefresh: true);
    } on FirebaseFunctionsException catch (e) {
      if (e.code == 'not-found') {
        throw StateError(
          'رفع الصور غير مهيأ لهذا الحساب: صلاحية التخزين غير موجودة '
          'وخدمة التهيئة على Firebase غير منشورة. يلزم إعداد الصلاحية '
          'من جهة الخادم قبل الرفع؛ لن نفتح التخزين للعامة.',
        );
      }
      rethrow;
    }
  }
  if (claims['role'] != 'authenticated') {
    throw StateError('صلاحية التخزين لم تتحدث بعد. أعد المحاولة بعد لحظات.');
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
