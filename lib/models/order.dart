class OrderItem {
  final String productId;
  final String name;
  final String image;
  final int quantity;
  final double price;

  const OrderItem({
    required this.productId,
    required this.name,
    required this.image,
    required this.quantity,
    required this.price,
  });

  Map<String, dynamic> toJson() =>
      {'productId': productId, 'name': name, 'image': image, 'quantity': quantity, 'price': price};

  factory OrderItem.fromJson(Map<String, dynamic> j) => OrderItem(
        productId: '${j['productId'] ?? ''}',
        name: '${j['name'] ?? ''}',
        image: '${j['image'] ?? ''}',
        quantity: (j['quantity'] as num?)?.toInt() ?? 1,
        price: (j['price'] as num?)?.toDouble() ?? 0,
      );
}

/// Bu cihazdan verilen sipariş kaydı.
class PlacedOrder {
  final String orderNo;
  final DateTime createdAt;
  final double amount;
  final String status;
  final String cardMask;
  final String buyerName;
  final String address;
  final List<OrderItem> items;

  const PlacedOrder({
    required this.orderNo,
    required this.createdAt,
    required this.amount,
    required this.status,
    required this.cardMask,
    required this.buyerName,
    required this.address,
    required this.items,
  });

  Map<String, dynamic> toJson() => {
        'orderNo': orderNo,
        'createdAt': createdAt.toIso8601String(),
        'amount': amount,
        'status': status,
        'cardMask': cardMask,
        'buyerName': buyerName,
        'address': address,
        'items': items.map((e) => e.toJson()).toList(),
      };

  factory PlacedOrder.fromJson(Map<String, dynamic> j) => PlacedOrder(
        orderNo: '${j['orderNo'] ?? ''}',
        createdAt: DateTime.tryParse('${j['createdAt']}') ?? DateTime.now(),
        amount: (j['amount'] as num?)?.toDouble() ?? 0,
        status: '${j['status'] ?? 'Hazırlanıyor'}',
        cardMask: '${j['cardMask'] ?? ''}',
        buyerName: '${j['buyerName'] ?? ''}',
        address: '${j['address'] ?? ''}',
        items: (j['items'] as List? ?? const [])
            .whereType<Map>()
            .map((e) => OrderItem.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
      );
}

/// Teslimat bilgileri (ödeme formu).
class DeliveryInfo {
  String fullName;
  String phone;
  String email;
  String city;
  String district;
  String address;

  DeliveryInfo({
    this.fullName = '',
    this.phone = '',
    this.email = '',
    this.city = '',
    this.district = '',
    this.address = '',
  });
}

/// Supabase "addresses" tablosundaki kayıt.
class SavedAddress {
  final String id;
  final String title;
  final String fullName;
  final String phone;
  final String city;
  final String district;
  final String addressLine;
  final bool isDefault;

  const SavedAddress({
    required this.id,
    required this.title,
    required this.fullName,
    required this.phone,
    required this.city,
    required this.district,
    required this.addressLine,
    required this.isDefault,
  });

  factory SavedAddress.fromJson(Map<String, dynamic> j) => SavedAddress(
        id: '${j['id']}',
        title: '${j['title'] ?? 'Adres'}',
        fullName: '${j['full_name'] ?? ''}',
        phone: '${j['phone'] ?? ''}',
        city: '${j['city'] ?? ''}',
        district: '${j['district'] ?? ''}',
        addressLine: '${j['address_line'] ?? ''}',
        isDefault: j['is_default'] == true,
      );
}
