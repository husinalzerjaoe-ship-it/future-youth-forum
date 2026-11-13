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
  await FirebaseFunctions.instance
      .httpsCallable('ensureSupabaseAuthenticatedRole')
      .call();

  final token = await user.getIdToken(true);
  if (token == null || token.split('.').length != 3) {
    throw StateError('تعذر تحديث رمز تسجيل الدخول. سجّل خروج وادخل من جديد.');
  }
  final payload = token.split('.')[1];
  final claims = jsonDecode(
    utf8.decode(base64Url.decode(base64Url.normalize(payload))),
  ) as Map<String, dynamic>;
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
  };
  final contentType = mimeTypes[ext];
  if (contentType == null) {
    throw ArgumentError('صيغة الملف غير مدعومة. استخدم JPG أو PNG أو WEBP أو GIF أو MP4 أو MOV.');
  }

  final bytes = await file.readAsBytes();
  if (bytes.isEmpty) throw StateError('ملف الصورة فارغ.');
  if (bytes.length > 50 * 1024 * 1024) {
    throw StateError('حجم الملف أكبر من الحد المسموح (50 ميغابايت).');
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
