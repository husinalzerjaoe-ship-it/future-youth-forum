import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Set FUTURE_AI_WEBHOOK_URL after deploying the shared n8n workflow.
/// Gemini and Telegram credentials must stay in n8n, not in this app.
const String futureAiWebhookUrl = String.fromEnvironment('FUTURE_AI_WEBHOOK_URL');

class _AiMessage {
  const _AiMessage(this.text, this.fromUser, this.createdAt);
  final String text;
  final bool fromUser;
  final DateTime createdAt;
  Map<String, dynamic> toJson() => {
    'text': text, 'fromUser': fromUser, 'createdAt': createdAt.toIso8601String(),
  };
  factory _AiMessage.fromJson(Map<String, dynamic> json) => _AiMessage(
    json['text'] as String? ?? '',
    json['fromUser'] as bool? ?? false,
    DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
  );
}

class AiAssistantPage extends StatefulWidget {
  const AiAssistantPage({super.key});
  @override
  State<AiAssistantPage> createState() => _AiAssistantPageState();
}

class _AiAssistantPageState extends State<AiAssistantPage> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final List<_AiMessage> _messages = [];
  bool _sending = false;
  String? _notice;
  String? _sessionId;

  static const _prompts = [
    'اقترح لي فكرة جديدة', 'ساعدني بالدراسة',
    'اشرح لي Flutter ببساطة', 'خل نلعب لعبة أسئلة',
  ];

  String get _storageKey {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? 'guest';
    return 'future_ai_history_$uid';
  }

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (!mounted) return;
    setState(() {
      _sessionId = prefs.getString(_storageKey + '_session');
      if (raw != null) {
        try {
          final items = jsonDecode(raw) as List<dynamic>;
          _messages.addAll(items.whereType<Map<String, dynamic>>().map(_AiMessage.fromJson));
        } catch (_) {
          _messages.clear();
        }
      }
      if (_messages.isEmpty) {
        _messages.add(_AiMessage(
          'أهلاً بيك! أنا مساعد المستقبل 🤖\nأكدر أساعدك بالأفكار والدراسة والبرمجة وأسئلة المعرفة.',
          false, DateTime.now(),
        ));
      }
    });
  }

  Future<void> _saveHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, jsonEncode(_messages.take(80).map((m) => m.toJson()).toList()));
    if (_sessionId != null) await prefs.setString(_storageKey + '_session', _sessionId!);
  }

  Future<void> _send([String? preset]) async {
    final text = (preset ?? _input.text).trim();
    if (text.isEmpty || _sending) return;
    _input.clear();
    FocusScope.of(context).unfocus();
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _notice = 'سجّل دخولك حتى تستخدم مساعد المستقبل.');
      return;
    }

    final current = _AiMessage(text, true, DateTime.now());
    setState(() { _notice = null; _messages.add(current); _sending = true; });
    await _saveHistory();
    _scrollToBottom();

    if (futureAiWebhookUrl.trim().isEmpty) {
      setState(() {
        _sending = false;
        _notice = 'واجهة المساعد جاهزة؛ يتبقى ربط رابط n8n بعد إعداد الـ Workflow.';
      });
      return;
    }

    try {
      final token = await user.getIdToken();
      final history = _messages
          .where((m) => m.createdAt != current.createdAt)
          .toList()
          .reversed.take(12).toList().reversed
          .map((m) => {'role': m.fromUser ? 'user' : 'assistant', 'content': m.text})
          .toList();

      final result = await http.post(
        Uri.parse(futureAiWebhookUrl),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'source': 'future_youth_forum_app',
          'message': text,
          'history': history,
          'sessionId': _sessionId ??= user.uid + '_future_assistant',
        }),
      ).timeout(const Duration(seconds: 45));

      if (result.statusCode < 200 || result.statusCode >= 300) {
        throw Exception('HTTP ' + result.statusCode.toString());
      }
      final decoded = jsonDecode(result.body);
      final reply = decoded is Map<String, dynamic>
          ? (decoded['reply'] ?? decoded['output'] ?? decoded['text'])?.toString()
          : decoded.toString();
      if (reply == null || reply.trim().isEmpty) throw const FormatException('Empty response');
      if (!mounted) return;
      setState(() {
        _messages.add(_AiMessage(reply.trim(), false, DateTime.now()));
        _sending = false;
      });
      await _saveHistory();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _sending = false;
        _notice = 'ما وصلني رد. تأكد من الإنترنت وإعداد Webhook في n8n.';
      });
    }
    _scrollToBottom();
  }

  Future<void> _newChat() async {
    setState(() {
      _messages
        ..clear()
        ..add(_AiMessage('بدأنا محادثة جديدة! شنو تحب نسوي اليوم؟', false, DateTime.now()));
      _notice = null;
    });
    await _saveHistory();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 260), curve: Curves.easeOut);
      }
    });
  }

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.rtl,
    child: Scaffold(
      appBar: AppBar(
        title: const Row(children: [
          CircleAvatar(radius: 17, backgroundColor: Color(0xFF6252D5),
            child: Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 19)),
          SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('مساعد المستقبل', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
            Text('ذكاء اصطناعي للملتقى', style: TextStyle(fontSize: 10, color: Colors.white70)),
          ]),
        ]),
        actions: [IconButton(tooltip: 'محادثة جديدة', onPressed: _sending ? null : _newChat,
          icon: const Icon(Icons.add_comment_outlined))],
      ),
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: LinearGradient(
          begin: Alignment.topRight, end: Alignment.bottomLeft,
          colors: [Color(0xFF11152B), Color(0xFF171936), Color(0xFF211B45)],
        )),
        child: Column(children: [
          Expanded(child: ListView.builder(
            controller: _scroll,
            padding: const EdgeInsets.fromLTRB(14, 18, 14, 12),
            itemCount: _messages.length + (_sending ? 1 : 0),
            itemBuilder: (context, index) {
              if (_sending && index == _messages.length) {
                return const Align(alignment: AlignmentDirectional.centerStart,
                  child: Padding(padding: EdgeInsets.all(8), child: _TypingIndicator()));
              }
              return _MessageBubble(message: _messages[index]);
            },
          )),
          if (_messages.length <= 1)
            SizedBox(height: 48, child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              scrollDirection: Axis.horizontal,
              children: _prompts.map((p) => Padding(
                padding: const EdgeInsetsDirectional.only(end: 7),
                child: ActionChip(
                  label: Text(p), onPressed: _sending ? null : () => _send(p),
                  backgroundColor: const Color(0xFF292653),
                  side: BorderSide(color: Colors.white.withOpacity(.12)),
                  labelStyle: const TextStyle(color: Colors.white, fontSize: 11),
                ),
              )).toList(),
            )),
          if (_notice != null)
            Padding(padding: const EdgeInsets.fromLTRB(14, 5, 14, 8),
              child: Text(_notice!, textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFFFFD28A), fontSize: 11))),
          SafeArea(top: false, child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Expanded(child: TextField(
                controller: _input, minLines: 1, maxLines: 5,
                textInputAction: TextInputAction.send, onSubmitted: (_) => _send(),
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'اكتب رسالتك لمساعد المستقبل...',
                  hintStyle: TextStyle(color: Colors.white.withOpacity(.48), fontSize: 13),
                  filled: true, fillColor: const Color(0xFF292653),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(color: Colors.white.withOpacity(.12))),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(color: Colors.white.withOpacity(.12))),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(color: Color(0xFF9A8BFF))),
                ),
              )),
              const SizedBox(width: 8),
              Material(color: const Color(0xFF7666E8), shape: const CircleBorder(),
                child: IconButton(
                  tooltip: 'إرسال', onPressed: _sending ? null : () => _send(),
                  icon: _sending
                    ? const SizedBox(width: 19, height: 19,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.send_rounded, color: Colors.white),
                )),
            ]),
          )),
        ]),
      ),
    ),
  );
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});
  final _AiMessage message;
  @override
  Widget build(BuildContext context) {
    final mine = message.fromUser;
    return Align(
      alignment: mine ? AlignmentDirectional.centerEnd : AlignmentDirectional.centerStart,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 330),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
        decoration: BoxDecoration(
          color: mine ? const Color(0xFF6656D6) : const Color(0xFF292653),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(19), topRight: const Radius.circular(19),
            bottomLeft: Radius.circular(mine ? 19 : 5),
            bottomRight: Radius.circular(mine ? 5 : 19),
          ),
          border: Border.all(color: Colors.white.withOpacity(.08)),
        ),
        child: SelectableText(message.text,
          style: const TextStyle(color: Colors.white, height: 1.45, fontSize: 14)),
      ),
    );
  }
}

class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    decoration: BoxDecoration(color: const Color(0xFF292653), borderRadius: BorderRadius.circular(18)),
    child: const Row(mainAxisSize: MainAxisSize.min, children: [
      SizedBox(width: 7, height: 7, child: DecoratedBox(
        decoration: BoxDecoration(color: Colors.white70, shape: BoxShape.circle))),
      SizedBox(width: 5),
      SizedBox(width: 7, height: 7, child: DecoratedBox(
        decoration: BoxDecoration(color: Colors.white70, shape: BoxShape.circle))),
      SizedBox(width: 5),
      SizedBox(width: 7, height: 7, child: DecoratedBox(
        decoration: BoxDecoration(color: Colors.white70, shape: BoxShape.circle))),
    ]),
  );
}
