import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/order.dart';
import '../services/payment_service.dart';
import '../state/cart_provider.dart';
import '../state/orders_provider.dart';
import '../theme.dart';
import '../utils/format.dart';

class PaymentResultScreen extends StatefulWidget {
  final String orderNo;
  final List<OrderItem> items;
  final String buyerName;
  final String address;

  const PaymentResultScreen({
    super.key,
    required this.orderNo,
    required this.items,
    required this.buyerName,
    required this.address,
  });

  @override
  State<PaymentResultScreen> createState() => _PaymentResultScreenState();
}

class _PaymentResultScreenState extends State<PaymentResultScreen> {
  PaymentResult? _result;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _verify();
  }

  Future<void> _verify() async {
    setState(() => _loading = true);
    PaymentResult? result;
    // iyzico sonucu birkaç saniye gecikmeli işleyebilir; kısa aralıklarla tekrar sorulur.
    for (var attempt = 0; attempt < 4; attempt++) {
      result = await PaymentService().verify(widget.orderNo);
      if (result != null && result.status != 'pending') break;
      await Future<void>.delayed(const Duration(seconds: 2));
    }
    if (!mounted) return;

    if (result != null && result.isSuccess) {
      final orders = context.read<OrdersProvider>();
      if (!orders.contains(result.orderNo)) {
        await orders.add(PlacedOrder(
          orderNo: result.orderNo,
          createdAt: DateTime.now(),
          amount: result.amount > 0
              ? result.amount
              : widget.items.fold<double>(0, (sum, i) => sum + i.price * i.quantity),
          status: 'Hazırlanıyor',
          cardMask: result.cardMask,
          buyerName: result.buyerName.isNotEmpty ? result.buyerName : widget.buyerName,
          address: widget.address,
          items: widget.items,
        ));
      }
      if (mounted) context.read<CartProvider>().clear();
    }
    if (!mounted) return;
    setState(() {
      _result = result;
      _loading = false;
    });
  }

  void _close() => Navigator.of(context).popUntil((route) => route.isFirst);

  @override
  Widget build(BuildContext context) {
    final success = _result?.isSuccess == true;
    return PopScope(
      canPop: !_loading,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Ödeme Sonucu'), automaticallyImplyLeading: false),
        body: _loading
            ? const Center(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Ödemeniz doğrulanıyor…'),
                ]),
              )
            : ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  const SizedBox(height: 24),
                  Center(
                    child: Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        color: success ? AppColors.greenSoft : const Color(0xFFFDECEC),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(success ? Icons.check_rounded : Icons.close_rounded,
                          size: 56, color: success ? AppColors.green : AppColors.danger),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    success ? 'Siparişiniz alındı!' : 'Ödeme tamamlanamadı',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.navy),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    success
                        ? 'Teşekkür ederiz. Siparişiniz hazırlanmaya başladı; kargoya verildiğinde bilgilendirileceksiniz.'
                        : (_result?.errorMessage.isNotEmpty == true
                            ? _result!.errorMessage
                            : 'Kartınızdan çekim yapılmadı. Bilgilerinizi kontrol ederek tekrar deneyebilirsiniz.'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.muted, height: 1.45),
                  ),
                  const SizedBox(height: 24),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(children: [
                        _row('Sipariş no', widget.orderNo),
                        if (success) ...[
                          _row('Tutar', formatPrice(_result!.amount)),
                          if (_result!.cardMask.isNotEmpty) _row('Kart', _result!.cardMask),
                          _row('Ödeme', _result!.installment > 1 ? '${_result!.installment} taksit' : 'Tek çekim'),
                        ],
                      ]),
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (!success) ...[
                    FilledButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Tekrar Dene')),
                    const SizedBox(height: 10),
                    OutlinedButton(onPressed: _verify, child: const Text('Durumu yeniden kontrol et')),
                    const SizedBox(height: 10),
                  ],
                  OutlinedButton(onPressed: _close, child: const Text('Alışverişe Dön')),
                ],
              ),
      ),
    );
  }

  Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(children: [
          Expanded(child: Text(label, style: const TextStyle(color: AppColors.muted))),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
        ]),
      );
}
