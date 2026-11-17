import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

/// DNS diagnostics and Android Private DNS setup helper.
/// This page does not claim to alter app-wide DNS or bypass network controls.
class DnsHelperPage extends StatefulWidget {
  const DnsHelperPage({super.key});
  @override
  State<DnsHelperPage> createState() => _DnsHelperPageState();
}
class _DnsProvider {
  const _DnsProvider(this.name, this.host, this.endpoint);
  final String name, host, endpoint;
}
class _DnsHelperPageState extends State<DnsHelperPage> {
  static const _providers = <_DnsProvider>[
    _DnsProvider('Cloudflare', 'one.one.one.one', 'https://cloudflare-dns.com/dns-query'),
    _DnsProvider('Google DNS', 'dns.google', 'https://dns.google/resolve'),
    _DnsProvider('Quad9', 'dns.quad9.net', 'https://dns.quad9.net/dns-query'),
  ];
  final _domain = TextEditingController(text: 'example.com');
  _DnsProvider _provider = _providers.first;
  bool _checking = false;
  String? _result;
  bool? _success;

  @override
  void dispose() { _domain.dispose(); super.dispose(); }

  Future<void> _copyHost() async {
    await Clipboard.setData(ClipboardData(text: _provider.host));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('تم نسخ عنوان ${_provider.name}')),
    );
  }

  Future<void> _testDns() async {
    final domain = _domain.text.trim().toLowerCase();
    final valid = RegExp(r'^(?=.{1,253}$)([a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?\\.)+[a-z]{2,63}$');
    if (!valid.hasMatch(domain)) {
      setState(() { _success = false; _result = 'اكتب اسم نطاق صحيح مثل example.com'; });
      return;
    }
    setState(() { _checking = true; _result = null; _success = null; });
    try {
      final uri = Uri.parse(_provider.endpoint).replace(queryParameters: {'name': domain, 'type': 'A'});
      final response = await http.get(uri, headers: const {
        'accept': 'application/dns-json, application/dns-message, */*',
      }).timeout(const Duration(seconds: 12));
      if (response.statusCode != 200) throw Exception('استجابة الخادم: ${response.statusCode}');
      final data = jsonDecode(response.body);
      final status = data is Map ? data['Status'] : null;
      final answers = data is Map && data['Answer'] is List
          ? (data['Answer'] as List).whereType<Map>()
              .map((item) => item['data']?.toString() ?? '')
              .where((value) => value.isNotEmpty).toList()
          : <String>[];
      if (status == 0 && answers.isNotEmpty) {
        setState(() { _success = true; _result = 'نجح اختبار DNS للنطاق $domain\\nالعناوين: ${answers.take(4).join('، ')}'; });
      } else if (status == 0) {
        setState(() { _success = true; _result = 'استجاب خادم DNS، لكن لم يُرجع عنوان IPv4 لهذا النطاق.'; });
      } else {
        setState(() { _success = false; _result = 'خادم DNS لم يتمكن من حل النطاق (رمز الحالة: ${status ?? 'غير معروف'}).'; });
      }
    } catch (error) {
      setState(() { _success = false; _result = 'تعذر إكمال الاختبار: $error'; });
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.rtl,
    child: Scaffold(
      appBar: AppBar(title: const Text('DNS الذكي والاتصال'), backgroundColor: const Color(0xFF171936)),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Row(children: [
              Icon(Icons.public_rounded, color: Color(0xFF8D80FF), size: 28),
              SizedBox(width: 10),
              Expanded(child: Text('اختيار مزوّد DNS', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
            ]),
            const SizedBox(height: 12),
            DropdownButtonFormField<_DnsProvider>(
              value: _provider, isExpanded: true, decoration: const InputDecoration(labelText: 'المزوّد'),
              items: _providers.map((p) => DropdownMenuItem(value: p, child: Text(p.name))).toList(),
              onChanged: (value) { if (value != null) setState(() { _provider = value; _result = null; _success = null; }); },
            ),
            const SizedBox(height: 12),
            SelectableText(_provider.host, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
            Align(alignment: Alignment.centerLeft, child: OutlinedButton.icon(
              onPressed: _copyHost, icon: const Icon(Icons.copy_rounded), label: const Text('نسخ عنوان DNS'),
            )),
          ],
        ))),
        const SizedBox(height: 12),
        Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('فحص استجابة DNS عبر HTTPS', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('هذا الفحص يختبر قدرة المزوّد على حل اسم النطاق، ولا يغيّر إعداد DNS المستخدم لبقية اتصالات التطبيق.'),
            const SizedBox(height: 12),
            TextField(controller: _domain, keyboardType: TextInputType.url, textDirection: TextDirection.ltr,
              decoration: const InputDecoration(labelText: 'اسم الموقع', hintText: 'example.com', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            SizedBox(width: double.infinity, child: FilledButton.icon(
              onPressed: _checking ? null : _testDns,
              icon: _checking ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.network_check_rounded),
              label: Text(_checking ? 'جاري الفحص...' : 'اختبار DNS'),
            )),
            if (_result != null) ...[
              const SizedBox(height: 12),
              Container(width: double.infinity, padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: (_success == true ? Colors.green : Colors.orange).withOpacity(.12), borderRadius: BorderRadius.circular(12)),
                child: Text(_result!, style: TextStyle(color: _success == true ? Colors.greenAccent : Colors.orangeAccent))),
            ],
          ],
        ))),
        const SizedBox(height: 12),
        Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: const [
            Text('تفعيل Private DNS على أندرويد', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('حتى يستخدم الهاتف هذا المزوّد في اتصالاته، افتح إعدادات أندرويد وابحث عن: الشبكة والإنترنت ← DNS خاص (Private DNS) ← اسم مضيف مزوّد DNS.'),
            SizedBox(height: 8),
            Text('انسخ اسم المضيف أعلاه والصقه في إعدادات الهاتف، ثم احفظ. قد تختلف أسماء القوائم حسب نوع الجهاز وإصدار أندرويد.'),
          ],
        ))),
        const SizedBox(height: 12),
        const Text('تنبيه: DNS قد يساعد إذا كان العطل بسبب حجب أسماء النطاقات فقط. لا يفتح كل المواقع أو القوائم، ولا يتجاوز حجب عنوان IP أو جدار الحماية أو قيود الخدمة. استخدمه للمواقع والخدمات المسموح لك بالوصول إليها.',
          style: TextStyle(color: Colors.white70, height: 1.5)),
      ]),
    ),
  );
}
