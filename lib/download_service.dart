import 'dart:io';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

class ForumDownloadService {
  static const MethodChannel _channel = MethodChannel('com.futureyouth.forum/downloads');

  static Future<void> download(String url, String fileName) async {
    final uri = Uri.tryParse(url.trim());
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) {
      throw ArgumentError('رابط التنزيل غير صالح أو غير آمن');
    }
    final safeName = fileName.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
    if (Platform.isAndroid) {
      await _channel.invokeMethod<int>('downloadFile', {
        'url': uri.toString(),
        'fileName': safeName.isEmpty ? 'forum-download' : safeName,
      });
      return;
    }
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened) throw Exception('تعذر فتح رابط التنزيل في المتصفح');
  }
}
