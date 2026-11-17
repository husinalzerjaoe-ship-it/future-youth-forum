import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

class NewsArticlePage extends StatefulWidget {
  const NewsArticlePage({
    super.key,
    required this.title,
    required this.url,
    required this.source,
    required this.published,
    this.imageUrl = '',
  });

  final String title;
  final String url;
  final String source;
  final String published;
  final String imageUrl;

  @override
  State<NewsArticlePage> createState() => _NewsArticlePageState();
}

class _NewsArticlePageState extends State<NewsArticlePage> {
  late final WebViewController _controller;
  int _progress = 0;
  bool _loading = true;
  String? _error;

  Uri? get _articleUri {
    final uri = Uri.tryParse(widget.url);
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) return null;
    return uri;
  }

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onProgress: (progress) {
          if (mounted) setState(() => _progress = progress);
        },
        onPageStarted: (_) {
          if (mounted) setState(() {
            _loading = true;
            _error = null;
          });
        },
        onPageFinished: (_) {
          if (mounted) setState(() {
            _loading = false;
            _progress = 100;
          });
        },
        onWebResourceError: (error) {
          if (error.isForMainFrame == true && mounted) {
            setState(() {
              _loading = false;
              _error = 'تعذر تحميل الخبر من المصدر. تحقق من الإنترنت أو افتحه عبر المتصفح.';
            });
          }
        },
        onNavigationRequest: (request) {
          final uri = Uri.tryParse(request.url);
          if (uri == null || !['https', 'http'].contains(uri.scheme)) {
            return NavigationDecision.prevent;
          }
          return NavigationDecision.navigate;
        },
      ));

    final uri = _articleUri;
    if (uri == null) {
      _loading = false;
      _error = 'رابط الخبر غير صالح أو غير آمن.';
    } else {
      _controller.loadRequest(uri).catchError((Object error) {
        if (mounted) setState(() {
          _loading = false;
          _error = 'تعذر فتح الخبر داخل التطبيق.';
        });
      });
    }
  }

  Future<void> _openExternal() async {
    final uri = _articleUri;
    if (uri == null) return;
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذر فتح رابط الخبر.')),
        );
      }
    }
  }

  Future<void> _copyLink() async {
    await Clipboard.setData(ClipboardData(text: widget.url));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم نسخ رابط الخبر')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final image = Uri.tryParse(widget.imageUrl);
    final hasImage = image != null && image.scheme == 'https' && image.host.isNotEmpty;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('تفاصيل الخبر'),
          actions: [
            IconButton(
              tooltip: 'نسخ الرابط',
              onPressed: _copyLink,
              icon: const Icon(Icons.copy_rounded),
            ),
            IconButton(
              tooltip: 'فتح بالمستعرض',
              onPressed: _openExternal,
              icon: const Icon(Icons.open_in_browser_rounded),
            ),
          ],
        ),
        body: Column(
          children: [
            if (hasImage)
              Image.network(
                widget.imageUrl,
                width: double.infinity,
                height: 190,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      height: 1.55,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.public_rounded, size: 15, color: Colors.grey),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          widget.source,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                      if (widget.published.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        const Icon(Icons.schedule_rounded, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            widget.published,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            if (_loading)
              LinearProgressIndicator(value: _progress == 0 ? null : _progress / 100),
            Expanded(
              child: _error != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.wifi_off_rounded, size: 42),
                            const SizedBox(height: 12),
                            Text(_error!, textAlign: TextAlign.center),
                            const SizedBox(height: 12),
                            FilledButton.icon(
                              onPressed: () {
                                final uri = _articleUri;
                                if (uri == null) return;
                                setState(() {
                                  _loading = true;
                                  _error = null;
                                  _progress = 0;
                                });
                                _controller.loadRequest(uri);
                              },
                              icon: const Icon(Icons.refresh_rounded),
                              label: const Text('إعادة المحاولة'),
                            ),
                          ],
                        ),
                      ),
                    )
                  : WebViewWidget(controller: _controller),
            ),
          ],
        ),
      ),
    );
  }
}
