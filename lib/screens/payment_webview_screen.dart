import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../models/order.dart';
import '../theme.dart';
import 'payment_result_screen.dart';

/// iyzico'nun barındırdığı ödeme sayfasını uygulama içinde açar.
/// Ödeme bitince iyzico, sitenin /odeme-sonuc?order=... adresine yönlendirir;
/// bu adres yakalanır ve sonuç uygulama içinde doğrulanır.
class PaymentWebViewScreen extends StatefulWidget {
  final String paymentUrl;
  final String orderNo;
  final List<OrderItem> items;
  final String buyerName;
  final String address;

  const PaymentWebViewScreen({
    super.key,
    required this.paymentUrl,
    required this.orderNo,
    required this.items,
    required this.buyerName,
    required this.address,
  });

  @override
  State<PaymentWebViewScreen> createState() => _PaymentWebViewScreenState();
}

class _PaymentWebViewScreenState extends State<PaymentWebViewScreen> {
  late final WebViewController _controller;
  int _progress = 0;
  bool _handled = false;

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
        onNavigationRequest: (request) {
          if (_isResultUrl(request.url)) {
            _finish(request.url);
            return NavigationDecision.prevent;
          }
          return NavigationDecision.navigate;
        },
        onPageStarted: (url) {
          if (_isResultUrl(url)) _finish(url);
        },
        onUrlChange: (change) {
          final url = change.url;
          if (url != null && _isResultUrl(url)) _finish(url);
        },
      ))
      ..loadRequest(Uri.parse(widget.paymentUrl));
  }

  bool _isResultUrl(String url) => url.contains('/odeme-sonuc');

  void _finish(String url) {
    if (_handled || !mounted) return;
    _handled = true;
    final uri = Uri.tryParse(url);
    final order = uri?.queryParameters['order'];
    Navigator.of(context).pushReplacement(MaterialPageRoute(
      builder: (_) => PaymentResultScreen(
        orderNo: (order != null && order.isNotEmpty) ? order : widget.orderNo,
        items: widget.items,
        buyerName: widget.buyerName,
        address: widget.address,
      ),
    ));
  }

  Future<bool> _confirmLeave() async {
    final leave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ödemeden çık'),
        content: const Text('Ödeme işlemi henüz tamamlanmadı. Çıkmak istediğinize emin misiniz?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Devam et')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Çık')),
        ],
      ),
    );
    return leave == true;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (await _controller.canGoBack()) {
          await _controller.goBack();
          return;
        }
        if (await _confirmLeave() && context.mounted) Navigator.of(context).pop();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Row(children: [
            Icon(Icons.lock, size: 18, color: AppColors.green),
            SizedBox(width: 6),
            Text('Güvenli Ödeme'),
          ]),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () async {
              if (await _confirmLeave() && context.mounted) Navigator.of(context).pop();
            },
          ),
          bottom: _progress < 100
              ? PreferredSize(
                  preferredSize: const Size.fromHeight(3),
                  child: LinearProgressIndicator(value: _progress / 100, minHeight: 3),
                )
              : null,
        ),
        body: WebViewWidget(controller: _controller),
      ),
    );
  }
}
