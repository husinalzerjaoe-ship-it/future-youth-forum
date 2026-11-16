import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tus_client_dart/tus_client_dart.dart';

/// Uploads media to the signed-in Firebase user's own Supabase Storage folder.
/// Storage RLS verifies the Firebase JWT issuer, audience and UID.
Future<String> uploadForumMedia(
  XFile file, {
  required String folder,
  String? roomId,
  void Function(double progress)? onProgress,
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
    case 'watch-rooms':
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

  // Refresh the Firebase ID token before sending it to Supabase Third-party Auth.
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
  // Firebase ID tokens do not contain Supabase's role claim by default.
  // Storage RLS accepts the verified Firebase JWT under the anon DB role,
  // but still checks the Firebase issuer, audience and owner UID in SQL.

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

  final path = prefix + DateTime.now().microsecondsSinceEpoch.toString() + '.$ext';
  final supabase = Supabase.instance.client;
  final storage = supabase.storage.from('forum-media');

  if (folder == 'watch-rooms') {
    final localFile = File(file.path);
    if (!await localFile.exists()) throw StateError('ملف الفيديو غير موجود على الجهاز.');
    final fileSize = await localFile.length();
    const maxVideoBytes = 4 * 1024 * 1024 * 1024;
    if (fileSize <= 0) throw StateError('ملف الفيديو فارغ ولا يمكن رفعه.');
    if (fileSize > maxVideoBytes) {
      throw StateError('الحد الأعلى لفيديو غرفة المشاهدة 4GB.');
    }

    // Stream large files in TUS chunks rather than loading the whole video
    // into memory. Persist the upload fingerprint for interruption recovery.
    // Keep the public project endpoint aligned with Supabase.initialize in main.dart.
    // This is a publishable client key, not a service-role secret.
    const projectRef = 'xwfzdiftlzrjsprnbwpf';
    const publishableKey = 'sb_publishable_kra9SFgnuh5CtvV2-2n4mQ_7q_iJzbY';
    final tusEndpoint = Uri.parse(
      'https://$projectRef.storage.supabase.co/storage/v1/upload/resumable',
    );
    final supportDir = await getApplicationSupportDirectory();
    final tusStoreDir = Directory('${supportDir.path}/forum_tus_uploads');
    await tusStoreDir.create(recursive: true);
    final tusClient = TusClient(
      file,
      store: TusFileStore(tusStoreDir),
      maxChunkSize: 6 * 1024 * 1024,
    );
    try {
      await tusClient.upload(
        uri: tusEndpoint,
        headers: {
          'apikey': publishableKey,
          'Authorization': 'Bearer $token',
          'x-upsert': 'false',
        },
        metadata: {
          'bucketName': 'forum-media',
          'objectName': path,
          'contentType': contentType,
          'cacheControl': '3600',
        },
        onProgress: (progress, estimate) {
          onProgress?.call(progress.clamp(0.0, 1.0).toDouble());
        },
      );
      onProgress?.call(1.0);
      return storage.getPublicUrl(path);
    } catch (e) {
      throw StateError('تعذر رفع الفيديو الكبير. تحقق من حد الرفع العام في Supabase وخطة التخزين والاتصال. ($e)');
    }
  }

  final bytes = await file.readAsBytes();
  if (bytes.isEmpty) throw StateError('الملف فارغ ولا يمكن رفعه.');
  final maxBytes = folder == 'shared-files' ? 100 * 1024 * 1024 : 50 * 1024 * 1024;
  if (bytes.length > maxBytes) {
    throw StateError('حجم الملف أكبر من الحد المسموح (' + (folder == 'shared-files' ? '100' : '50') + ' ميغابايت).');
  }

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


Future<void> deleteForumMedia(String publicUrl) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) throw StateError('سجّل الدخول أولاً.');
  final uri = Uri.tryParse(publicUrl);
  if (uri == null || uri.host.isEmpty) throw ArgumentError('رابط الملف غير صالح.');
  final segments = uri.pathSegments;
  final marker = segments.indexOf('forum-media');
  if (marker < 0 || marker + 2 >= segments.length) throw ArgumentError('رابط الملف غير صالح.');
  final objectPath = segments.skip(marker + 1).join('/');
  final parts = objectPath.split('/');
  final owner = parts.length >= 3 && parts.first == 'regional-chat' ? parts[2] : parts.length >= 2 ? parts[1] : '';
  if (owner != user.uid) throw StateError('يمكنك حذف ملفاتك أنت فقط.');
  await Supabase.instance.client.storage.from('forum-media').remove([objectPath]);
}
