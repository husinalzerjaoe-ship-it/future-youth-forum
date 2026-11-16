import 'dart:async';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

const _botColor = Color(0xFF6554D9);
const _assistantWebhookUrl =
    'https://cloud.activepieces.com/api/v1/webhooks/YQruwrsE0xEvTlbBdcNsy/sync';

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
      throw Exception('استجابة الخادم ${response.statusCode}');
    }

    final answer = _extractAnswer(response.body);
    if (answer == null) {
      throw const FormatException(
        'وصل رد فارغ. تأكد أن آخر خطوة في Flow هي Return Response وتعيد جواب ChatGPT.',
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
    _scrollToBottom();

    String reply;
    try {
      reply = await _askAssistant(value, history);
    } on TimeoutException {
      reply = 'تأخر رد المساعد أكثر من الوقت المسموح. جرّب مرة ثانية.';
    } on FormatException catch (error) {
      reply = 'وصل رد غير مفهوم من Flow. ${error.message}';
    } catch (_) {
      reply = 'تعذر الاتصال بمساعد الذكاء الاصطناعي حالياً. تأكد من الإنترنت وأن Flow منشور ويحتوي خطوة Return Response، ثم حاول مجدداً.';
    }

    if (!mounted) return;
    setState(() {
      messages.add({'from': 'bot', 'text': reply});
      thinking = false;
    });
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
              child: ListView.builder(
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
