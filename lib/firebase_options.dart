import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) throw UnsupportedError('هذا الإصدار مخصص حالياً لأجهزة أندرويد.');
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError('منصة التشغيل هذه غير مهيأة حالياً.');
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDYE7t2lD0HLrGS2191tN3LsuVoQvAw-eI',
    appId: '1:609448232328:android:e88c61f0d02550e025a63d',
    messagingSenderId: '609448232328',
    projectId: 'futureyouth-69f8a',
    storageBucket: 'futureyouth-69f8a.firebasestorage.app',
  );
}
