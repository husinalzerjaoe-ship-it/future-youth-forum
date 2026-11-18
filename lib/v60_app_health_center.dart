import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'local_audio_handler.dart';

const _assistantWebhookUrl = String.fromEnvironment('ACTIVEPIECES_WEBHOOK_URL');
bool get _assistantWebhookConfigured => _assistantWebhookUrl.isNotEmpty;

/// Local diagnostics and an authenticated Firestore connectivity probe.
/// This page never displays tokens, passwords, or provider URLs.
class V60AppHealthPage extends StatefulWidget {
  const V60AppHealthPage({super.key});

  @override
  State<V60AppHealthPage> createState() => _V60AppHealthPageState();
}

class _V60AppHealthPageState extends State<V60AppHealthPage> {
  bool _checking = false;
  String _connection = 'لم يتم الفحص بعد';
  String _detail = 'اضغط فحص الاتصال للتحقق من وصول التطبيق إلى Firestore.';
  DateTime? _checkedAt;
  int _imageCount = 0;
  int _imageBytes = 0;

  Future<void> _checkConnection() async {
    if (_checking) return;
    setState(() => _checking = true);
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _connection = 'غير مسجل الدخول';
        _detail = 'سجّل الدخول أولاً حتى يمكن فحص الاتصال الموثّق.';
        _checkedAt = DateTime.now();
        _checking = false;
      });
      return;
    }

    try {
      // Reading the signed-in user's own document tests both network access
      // and the current Firestore rules without changing any user data.
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get(const GetOptions(source: Source.server))
          .timeout(const Duration(seconds: 12));
      if (!mounted) return;
      setState(() {
        _connection = 'الاتصال يعمل';
        _detail = 'تم الوصول إلى Firestore بحسابك الحالي بنجاح.';
        _checkedAt = DateTime.now();
      });
    } on FirebaseException catch (error) {
      if (!mounted) return;
      final permission = error.code == 'permission-denied';
      setState(() {
        _connection = permission ? 'مشكلة صلاحيات' : 'تعذر الاتصال';
        _detail = permission
            ? 'وصل التطبيق إلى الخدمة، لكن قواعد Firestore رفضت قراءة ملف الحساب. راجع صلاحيات users.'
            : 'رمز الخطأ: ${error.code}. تحقق من الإنترنت وحالة Firebase.';
        _checkedAt = DateTime.now();
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _connection = 'تعذر إكمال الفحص';
        _detail = 'انتهت مهلة الفحص أو حدث خطأ غير متوقع. جرّب مرة ثانية.';
        _checkedAt = DateTime.now();
      });
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  void _readCache() {
    final cache = PaintingBinding.instance.imageCache;
    setState(() {
      _imageCount = cache.currentSize;
      _imageBytes = cache.currentSizeBytes;
    });
  }

  void _clearImageCache() {
    PaintingBinding.instance.imageCache
      ..clear()
      ..clearLiveImages();
    _readCache();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم تفريغ ذاكرة الصور المؤقتة. قد تحتاج الصور للتحميل مجدداً.')),
    );
  }

  String _bytes(int value) {
    if (value < 1024) return '$value بايت';
    if (value < 1024 * 1024) return '${(value / 1024).toStringAsFixed(1)} كيلوبايت';
    return '${(value / (1024 * 1024)).toStringAsFixed(1)} ميغابايت';
  }

  @override
  void initState() {
    super.initState();
    _readCache();
  }

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.rtl,
    child: Scaffold(
      appBar: AppBar(title: const Text('مركز صحة التطبيق V60')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Row(children: [
                  Icon(Icons.health_and_safety_rounded, color: Colors.teal, size: 30),
                  SizedBox(width: 10),
                  Expanded(child: Text('فحص خدمات الملتقى', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold))),
                ]),
                const SizedBox(height: 10),
                Text(_connection, style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text(_detail),
                if (_checkedAt != null) ...[
                  const SizedBox(height: 8),
                  Text('آخر فحص: ${_checkedAt!.toLocal()}', style: Theme.of(context).textTheme.bodySmall),
                ],
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: _checking ? null : _checkConnection,
                  icon: _checking
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.wifi_find_rounded),
                  label: Text(_checking ? 'جاري الفحص...' : 'فحص اتصال Firestore'),
                ),
              ]),
            ),
          ),
          const SizedBox(height: 10),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('حالة الخدمات الإضافية', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(isAudioServiceInitialized ? Icons.graphic_eq_rounded : Icons.music_off_rounded,
                    color: isAudioServiceInitialized ? Colors.teal : Colors.orange),
                  title: const Text('مشغّل الصوت بالخلفية'),
                  subtitle: Text(isAudioServiceInitialized
                    ? 'تم تهيئة AudioService داخل هذه الجلسة.'
                    : 'لم تتم تهيئة المشغّل بعد؛ افتح قسم موسيقاي أو أعد تشغيل التطبيق.'),
                ),
                const Divider(height: 1),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(_assistantWebhookConfigured ? Icons.smart_toy_rounded : Icons.smart_toy_outlined,
                    color: _assistantWebhookConfigured ? Colors.teal : Colors.orange),
                  title: const Text('مساعد الذكاء الاصطناعي'),
                  subtitle: Text(_assistantWebhookConfigured
                    ? 'رابط الخدمة مضمّن في هذا البناء؛ يلزم اختبار الاستجابة من صفحة المساعد.'
                    : 'رابط الخدمة غير مضمّن في هذا البناء؛ المساعد لن يتصل بالـFlow.'),
                ),
                const Text('هذا فحص إعداد محلي، ولا يثبت أن الخادم الخارجي متاح أو أن كل ميزة تعمل.', style: TextStyle(fontSize: 12)),
              ]),
            ),
          ),
          const SizedBox(height: 10),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('ذاكرة الصور المؤقتة', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.photo_library_outlined),
                  title: Text('عدد الصور المحفوظة: $_imageCount'),
                  subtitle: Text('الحجم التقريبي: ${_bytes(_imageBytes)}'),
                ),
                Wrap(spacing: 8, children: [
                  OutlinedButton.icon(onPressed: _readCache, icon: const Icon(Icons.refresh), label: const Text('تحديث القياس')),
                  TextButton.icon(onPressed: _clearImageCache, icon: const Icon(Icons.cleaning_services_outlined), label: const Text('تفريغ الذاكرة')),
                ]),
              ]),
            ),
          ),
          const SizedBox(height: 10),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('ملاحظات مهمة', style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Text('• فحص Firestore يختبر حسابك الحالي ولا يغيّر بياناته.'),
                Text('• نجاح الفحص لا يعني أن كل الأقسام أو رفع الوسائط تعمل؛ لكل خدمة اختبارها.'),
                Text('• تفريغ ذاكرة الصور لا يحذف الصور من حسابك أو من الخادم.'),
                Text('• لا تعرض هذه الصفحة كلمات المرور أو رموز تسجيل الدخول.'),
              ]),
            ),
          ),
        ],
      ),
    ),
  );
}
