import 'package:supabase_flutter/supabase_flutter.dart';

import '../config.dart';

class PaymentItem {
  final String id;
  final String name;
  final double price;
  final int quantity;
  const PaymentItem({required this.id, required this.name, required this.price, required this.quantity});
  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'price': price, 'quantity': quantity};
}

class PaymentBuyer {
  final String fullName;
  final String email;
  final String phone;
  final String address;
  final String city;
  const PaymentBuyer({
    required this.fullName,
    required this.email,
    required this.phone,
    required this.address,
    required this.city,
  });
  Map<String, dynamic> toJson() =>
      {'fullName': fullName, 'email': email, 'phone': phone, 'address': address, 'city': city};
}

class PaymentStart {
  final bool ok;
  final String orderNo;
  final String paymentPageUrl;
  final double amount;
  final String message;
  const PaymentStart({
    required this.ok,
    this.orderNo = '',
    this.paymentPageUrl = '',
    this.amount = 0,
    this.message = '',
  });
}

class PaymentResult {
  final String orderNo;
  final String status;
  final double amount;
  final int installment;
  final String buyerName;
  final String cardMask;
  final String errorMessage;
  const PaymentResult({
    required this.orderNo,
    required this.status,
    required this.amount,
    required this.installment,
    required this.buyerName,
    required this.cardMask,
    required this.errorMessage,
  });
  bool get isSuccess => status == 'success';
}

/// Sitenin kullandığı iyzico Supabase fonksiyonlarını (iyzico-init / iyzico-verify) çağırır.
/// Kart bilgisi uygulamada toplanmaz; ödeme iyzico'nun kendi sayfasında yapılır.
class PaymentService {
  SupabaseClient get _client => Supabase.instance.client;

  Future<PaymentStart> start({
    required List<PaymentItem> items,
    required PaymentBuyer buyer,
    int installment = 1,
  }) async {
    try {
      final response = await _client.functions.invoke('iyzico-init', body: {
        'items': items.map((e) => e.toJson()).toList(),
        'buyer': buyer.toJson(),
        'installment': installment,
        'siteUrl': AppConfig.siteUrl,
      });
      final data = response.data;
      if (data is Map && data['ok'] == true) {
        return PaymentStart(
          ok: true,
          orderNo: '${data['orderNo']}',
          paymentPageUrl: '${data['paymentPageUrl']}',
          amount: (data['amount'] as num?)?.toDouble() ?? 0,
        );
      }
      return PaymentStart(
        ok: false,
        message: data is Map && data['message'] != null ? '${data['message']}' : 'Ödeme başlatılamadı.',
      );
    } on FunctionException catch (e) {
      final details = e.details;
      final message = details is Map && details['message'] != null
          ? '${details['message']}'
          : 'Ödeme servisine ulaşılamadı. Lütfen tekrar deneyin.';
      return PaymentStart(ok: false, message: message);
    } catch (_) {
      return const PaymentStart(ok: false, message: 'Ödeme servisine ulaşılamadı. İnternet bağlantınızı kontrol edin.');
    }
  }

  Future<PaymentResult?> verify(String orderNo) async {
    if (orderNo.isEmpty) return null;
    try {
      final response = await _client.functions.invoke('iyzico-verify', body: {'order': orderNo});
      final data = response.data;
      if (data is! Map || data['ok'] != true) return null;
      return PaymentResult(
        orderNo: '${data['orderNo'] ?? orderNo}',
        status: '${data['status'] ?? 'pending'}',
        amount: (data['amount'] as num?)?.toDouble() ?? 0,
        installment: (data['installment'] as num?)?.toInt() ?? 1,
        buyerName: '${data['buyerName'] ?? ''}',
        cardMask: '${data['cardMask'] ?? ''}',
        errorMessage: '${data['errorMessage'] ?? ''}',
      );
    } catch (_) {
      return null;
    }
  }
}
