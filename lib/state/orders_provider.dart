import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/order.dart';

/// Bu cihazdan tamamlanan siparişler (site de müşteri siparişlerini tarayıcıda tutar).
class OrdersProvider extends ChangeNotifier {
  static const _key = 'placed_orders_v1';
  List<PlacedOrder> _orders = [];

  List<PlacedOrder> get orders => List.unmodifiable(_orders);

  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw != null) {
        _orders = (jsonDecode(raw) as List)
            .whereType<Map>()
            .map((e) => PlacedOrder.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }
    } catch (_) {
      _orders = [];
    }
    notifyListeners();
  }

  bool contains(String orderNo) => _orders.any((o) => o.orderNo == orderNo);

  Future<void> add(PlacedOrder order) async {
    if (contains(order.orderNo)) return;
    _orders.insert(0, order);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(_orders.map((e) => e.toJson()).toList()));
  }
}
