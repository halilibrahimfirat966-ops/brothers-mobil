import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config.dart';
import '../models/catalog.dart';
import 'catalog_provider.dart';

class CartLine {
  final String productId;
  final int quantity;
  final String variantLabel;
  final double? unitPrice;

  const CartLine({required this.productId, required this.quantity, this.variantLabel = '', this.unitPrice});

  String get key => '$productId::$variantLabel';

  CartLine copyWith({int? quantity}) =>
      CartLine(productId: productId, quantity: quantity ?? this.quantity, variantLabel: variantLabel, unitPrice: unitPrice);

  Map<String, dynamic> toJson() =>
      {'productId': productId, 'quantity': quantity, 'variantLabel': variantLabel, 'unitPrice': unitPrice};

  factory CartLine.fromJson(Map<String, dynamic> j) => CartLine(
        productId: '${j['productId']}',
        quantity: (j['quantity'] as num?)?.toInt() ?? 1,
        variantLabel: '${j['variantLabel'] ?? ''}',
        unitPrice: (j['unitPrice'] as num?)?.toDouble(),
      );
}

class CartEntry {
  final CartLine line;
  final Product product;
  final double unitPrice;
  const CartEntry(this.line, this.product, this.unitPrice);
  double get lineTotal => unitPrice * line.quantity;
}

class CartSummary {
  final List<CartEntry> entries;
  final double subtotal;
  final double shipping;
  const CartSummary(this.entries, this.subtotal, this.shipping);
  double get total => subtotal + shipping;
  int get count => entries.fold(0, (sum, e) => sum + e.line.quantity);
  bool get isEmpty => entries.isEmpty;
}

class CartProvider extends ChangeNotifier {
  static const _key = 'cart_lines_v1';
  List<CartLine> _lines = [];

  List<CartLine> get lines => List.unmodifiable(_lines);
  int get count => _lines.fold(0, (sum, l) => sum + l.quantity);

  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw != null) {
        _lines = (jsonDecode(raw) as List)
            .whereType<Map>()
            .map((e) => CartLine.fromJson(Map<String, dynamic>.from(e)))
            .where((l) => l.quantity > 0)
            .toList();
      }
    } catch (_) {
      _lines = [];
    }
    notifyListeners();
  }

  Future<void> _save() async {
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, jsonEncode(_lines.map((e) => e.toJson()).toList()));
    } catch (_) {}
  }

  void add(Product product, {int quantity = 1, String variantLabel = '', double? unitPrice}) {
    final line = CartLine(
      productId: product.id,
      quantity: quantity,
      variantLabel: variantLabel,
      unitPrice: unitPrice,
    );
    final index = _lines.indexWhere((l) => l.key == line.key);
    if (index >= 0) {
      _lines[index] = _lines[index].copyWith(quantity: _lines[index].quantity + quantity);
    } else {
      _lines.add(line);
    }
    _save();
  }

  void setQuantity(String key, int quantity) {
    if (quantity <= 0) {
      _lines.removeWhere((l) => l.key == key);
    } else {
      _lines = _lines.map((l) => l.key == key ? l.copyWith(quantity: quantity) : l).toList();
    }
    _save();
  }

  void remove(String key) {
    _lines.removeWhere((l) => l.key == key);
    _save();
  }

  void clear() {
    _lines = [];
    _save();
  }

  int quantityOf(String productId) =>
      _lines.where((l) => l.productId == productId).fold(0, (sum, l) => sum + l.quantity);

  CartSummary summary(CatalogProvider catalog) {
    final entries = <CartEntry>[];
    for (final line in _lines) {
      final product = catalog.productById(line.productId);
      if (product == null) continue;
      // Sitedeki gibi: eklendiği andaki fiyat güncel fiyatın altına düşmüşse güncel fiyat kullanılır.
      final price = line.unitPrice != null && line.unitPrice! >= product.price ? line.unitPrice! : product.price;
      entries.add(CartEntry(line, product, price));
    }
    final subtotal = entries.fold<double>(0, (sum, e) => sum + e.lineTotal);
    final freeShipping = AppConfig.freeShippingEnabled || subtotal >= AppConfig.freeShippingThreshold;
    final shipping = entries.isEmpty || freeShipping ? 0.0 : AppConfig.shippingFee;
    return CartSummary(entries, subtotal, shipping);
  }
}
