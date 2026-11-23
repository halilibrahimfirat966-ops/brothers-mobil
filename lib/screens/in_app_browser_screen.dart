import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../theme.dart';

/// Site sayfalarını (kargo takibi, SSS, sözleşmeler, destek…) uygulamanın içinde açar.
/// Telefon, e-posta ve WhatsApp bağlantıları ilgili uygulamada açılır.
class InAppBrowserScreen extends StatefulWidget {
  final String url;
  final String? title;
  const InAppBrowserScreen({super.key, required this.url, this.title});

  /// Uygulama dışında (telefon, e-posta, WhatsApp, harita, mağaza) açılması gereken bağlantılar.
  static bool isAppLinkUri(Uri uri) {
    const appSchemes = {'tel', 'mailto', 'sms', 'whatsapp', 'intent', 'market', 'geo'};
    if (appSchemes.contains(uri.scheme)) return true;
    const appHosts = {'wa.me', 'api.whatsapp.com', 'maps.google.com', 'play.google.com', 'apps.apple.com'};
    return appHosts.contains(uri.host);
  }

  @override
  State<InAppBrowserScreen> createState() => _InAppBrowserScreenState();
}

class _InAppBrowserScreenState extends State<InAppBrowserScreen> {
  late final WebViewController _controller;
  int _progress = 0;
  String _pageTitle = '';
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(NavigationDelegate(
        onProgress: (p) {
          if (mounted) setState(() => _progress = p);
        },
        onPageStarted: (_) {
          if (mounted) setState(() => _failed = false);
        },
        onPageFinished: (_) async {
          final title = await _controller.getTitle();
          if (mounted && title != null) setState(() => _pageTitle = title);
        },
        onWebResourceError: (error) {
          if (error.isForMainFrame == true && mounted) setState(() => _failed = true);
        },
        onNavigationRequest: (request) {
          final uri = Uri.tryParse(request.url);
          if (uri != null && InAppBrowserScreen.isAppLinkUri(uri)) {
            launchUrl(uri, mode: LaunchMode.externalApplication);
            return NavigationDecision.prevent;
          }
          return NavigationDecision.navigate;
        },
      ))
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.title ?? (_pageTitle.isNotEmpty ? _pageTitle : 'Brothers Teknoloji');
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (await _controller.canGoBack()) {
          await _controller.goBack();
        } else if (context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.of(context).pop()),
          title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 16)),
          actions: [
            IconButton(icon: const Icon(Icons.refresh), onPressed: () => _controller.reload()),
          ],
          bottom: _progress < 100
              ? PreferredSize(
                  preferredSize: const Size.fromHeight(3),
                  child: LinearProgressIndicator(value: _progress / 100, minHeight: 3),
                )
              : null,
        ),
        body: _failed
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.wifi_off, size: 48, color: AppColors.muted),
                    const SizedBox(height: 12),
                    const Text('Sayfa yüklenemedi', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
                    const SizedBox(height: 6),
                    const Text('İnternet bağlantınızı kontrol edip tekrar deneyin.',
                        textAlign: TextAlign.center, style: TextStyle(color: AppColors.muted)),
                    const SizedBox(height: 16),
                    FilledButton(onPressed: () => _controller.reload(), child: const Text('Tekrar dene')),
                  ]),
                ),
              )
            : WebViewWidget(controller: _controller),
      ),
    );
  }
}
