import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

const _botColor = Color(0xFF6554D9);
const _assistantWebhookUrl = String.fromEnvironment('ACTIVEPIECES_WEBHOOK_URL');

class LocalHelperBotPage extends StatefulWidget {
  const LocalHelperBotPage({super.key});

  @override
  State<LocalHelperBotPage> createState() => _LocalHelperBotPageState();
}

class _LocalHelperBotPageState extends State<LocalHelperBotPage> {
  final input = TextEditingController();
  final scroll = ScrollController();
  final List<Map<String, String>> messages = [
    {
      'from': 'bot',
      'text': 'هلا بيك! أنا مساعد ملتقى شباب المستقبل 🤖💜\nاكتب سؤالك وراح أحاول أجيبك بمساعدة الذكاء الاصطناعي.',
    },
  ];
  bool thinking = false;
  bool _historyReady = false;

  String get _historyKey =>
      'future_helper_bot_history_${FirebaseAuth.instance.currentUser?.uid ?? 'guest'}';

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_historyKey);
    if (!mounted) return;
    if (raw != null) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          final restored = decoded
              .whereType<Map>()
              .map((item) => Map<String, String>.from(item.map(
                    (key, value) => MapEntry(key.toString(), value.toString()),
                  )))
              .where((item) => item['from'] == 'user' || item['from'] == 'bot')
              .where((item) => (item['text'] ?? '').isNotEmpty)
              .take(80)
              .toList();
          if (restored.isNotEmpty) {
            messages
              ..clear()
              ..addAll(restored);
          }
        }
      } catch (_) {
        await prefs.remove(_historyKey);
      }
    }
    if (mounted) setState(() => _historyReady = true);
    _scrollToBottom();
  }

  Future<void> _saveHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final recent = messages.length > 80
        ? messages.sublist(messages.length - 80)
        : messages;
    await prefs.setString(_historyKey, jsonEncode(recent));
  }

  Future<void> _clearHistory() async {
    if (thinking) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('مسح المحادثة؟'),
          content: const Text('راح تنمسح المحادثة المحفوظة على هذا الجهاز فقط.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('مسح')),
          ],
        ),
      ),
    );
    if (confirmed != true) return;
    messages
      ..clear()
      ..add({
        'from': 'bot',
        'text': 'بدأنا محادثة جديدة! شنو تحب تسأل اليوم؟',
      });
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_historyKey);
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    input.dispose();
    scroll.dispose();
    super.dispose();
  }

  String? _extractAnswer(dynamic value) {
    if (value == null) return null;
    if (value is String) {
      final text = value.trim();
      if (text.isEmpty) return null;
      try {
        final decoded = jsonDecode(text);
        final nested = _extractAnswer(decoded);
        if (nested != null) return nested;
      } catch (_) {
        // Plain-text responses are valid too.
      }
      return text;
    }
    if (value is List) {
      for (final item in value) {
        final answer = _extractAnswer(item);
        if (answer != null) return answer;
      }
      return null;
    }
    if (value is Map) {
      for (final key in [
        'answer', 'output', 'response', 'text', 'message',
        'content', 'result', 'data', 'body', 'choices',
      ]) {
        if (value.containsKey(key)) {
          final answer = _extractAnswer(value[key]);
          if (answer != null) return answer;
        }
      }
    }
    return null;
  }

  Future<String> _askAssistant(
    String question,
    List<Map<String, String>> history,
  ) async {
    if (_assistantWebhookUrl.isEmpty) {
      throw StateError('رابط المساعد غير مضبوط في إعدادات البناء.');
    }
    final user = FirebaseAuth.instance.currentUser;
    final response = await http
        .post(
          Uri.parse(_assistantWebhookUrl),
          headers: const {
            'Content-Type': 'application/json; charset=utf-8',
            'Accept': 'application/json, text/plain',
          },
          body: jsonEncode({
            'message': question,
            'text': question,
            'prompt': question,
            'input': question,
            'history': history,
            'user': {'uid': user?.uid, 'name': user?.displayName},
          }),
        )
        .timeout(const Duration(seconds: 27));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final detail = response.body.trim();
      final shortDetail = detail.length > 220 ? '${detail.substring(0, 220)}…' : detail;
      throw HttpException(
        'خادم المساعد رجّع ${response.statusCode}${shortDetail.isEmpty ? '' : ': $shortDetail'}',
      );
    }

    final answer = _extractAnswer(response.body);
    if (answer == null) {
      final detail = response.body.trim();
      final shortDetail = detail.length > 220 ? '${detail.substring(0, 220)}…' : detail;
      throw FormatException(
        'وصل رد بدون نص جواب. راجع Return Response في Flow. الرد المستلم: $shortDetail',
      );
    }
    return answer;
  }

  Future<void> send([String? suggestion]) async {
    final value = (suggestion ?? input.text).trim();
    if (value.isEmpty || thinking) return;

    final history = messages
        .map((item) => {
              'role': item['from'] == 'user' ? 'user' : 'assistant',
              'content': item['text'] ?? '',
            })
        .toList(growable: false);

    setState(() {
      messages.add({'from': 'user', 'text': value});
      input.clear();
      thinking = true;
    });
    await _saveHistory();
    _scrollToBottom();

    String reply;
    try {
      reply = await _askAssistant(value, history);
    } on TimeoutException {
      reply = 'تأخر رد المساعد أكثر من الوقت المسموح. جرّب مرة ثانية.';
    } on FormatException catch (error) {
      reply = 'وصل رد غير مفهوم من Flow. ${error.message}';
    } on HttpException catch (error) {
      reply = 'تعذر إكمال طلب المساعد: ${error.message}';
    } catch (error) {
      final detail = error.toString();
      reply = 'تعذر الاتصال بمساعد الذكاء الاصطناعي: ${detail.length > 220 ? detail.substring(0, 220) : detail}';
    }

    if (!mounted) return;
    setState(() {
      messages.add({'from': 'bot', 'text': reply});
      thinking = false;
    });
    await _saveHistory();
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scroll.hasClients) {
        scroll.animateTo(
          scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) => Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          appBar: AppBar(
            actions: [
              IconButton(
                tooltip: 'مسح المحادثة المحفوظة',
                onPressed: thinking ? null : _clearHistory,
                icon: const Icon(Icons.delete_sweep_outlined),
              ),
            ],
            title: const Row(children: [
              CircleAvatar(
                backgroundColor: Color(0xFFEAE6FF),
                child: Icon(Icons.smart_toy, color: _botColor),
              ),
              SizedBox(width: 10),
              Text('مساعد الملتقى'),
            ]),
          ),
          body: Column(children: [
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(12, 10, 12, 2),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF6554D9).withOpacity(.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'تُرسل رسالتك إلى خدمة المساعد للرد عليها، ويُحفظ سجل المحادثة على هذا الجهاز. لا ترسل كلمات مرور أو معلومات خاصة.',
                style: TextStyle(fontSize: 11, height: 1.4),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  'شلون أدخل الرومات؟',
                  'شلون أنشر ستوري؟',
                  'شلون أحمي حسابي؟',
                  'اشرح لي الذكاء الاصطناعي',
                  'اقترح لي أفكار جديدة',
                ]
                    .map((q) => ActionChip(
                          label: Text(q),
                          onPressed: thinking ? null : () => send(q),
                        ))
                    .toList(),
              ),
            ),
            Expanded(
              child: !_historyReady
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                controller: scroll,
                padding: const EdgeInsets.all(12),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final item = messages[index];
                  final isBot = item['from'] == 'bot';
                  return Align(
                    alignment:
                        isBot ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * .84,
                      ),
                      margin: const EdgeInsets.symmetric(vertical: 5),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isBot
                            ? const Color(0xFFEDEAFF)
                            : const Color(0xFFE7F3FF),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: SelectableText(
                        item['text'] ?? '',
                        style: const TextStyle(height: 1.5),
                      ),
                    ),
                  );
                },
              ),
            ),
            if (thinking)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    SizedBox(
                      width: 15,
                      height: 15,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 9),
                    Text('المساعد يفكر ويكتب...'),
                  ]),
                ),
              ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Row(children: [
                  Expanded(
                    child: TextField(
                      controller: input,
                      minLines: 1,
                      maxLines: 4,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => send(),
                      decoration: const InputDecoration(
                        hintText: 'اكتب سؤالك...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: thinking ? null : send,
                    icon: const Icon(Icons.send),
                    style: IconButton.styleFrom(
                      backgroundColor: _botColor,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ]),
              ),
            ),
          ]),
        ),
      );
}
