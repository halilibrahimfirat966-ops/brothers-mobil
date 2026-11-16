double _toDouble(dynamic v, [double fallback = 0]) => v is num ? v.toDouble() : double.tryParse('$v') ?? fallback;
int _toInt(dynamic v, [int fallback = 0]) => v is num ? v.toInt() : int.tryParse('$v') ?? fallback;
String _str(dynamic v) => v == null ? '' : '$v';
List<Map<String, dynamic>> _maps(dynamic v) =>
    v is List ? v.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList() : const [];

class ProductTag {
  final String label;
  final String tone;
  const ProductTag(this.label, this.tone);
  factory ProductTag.fromJson(Map<String, dynamic> j) => ProductTag(_str(j['label']), _str(j['tone']));
}

class ProductSpec {
  final String label;
  final String value;
  const ProductSpec(this.label, this.value);
  factory ProductSpec.fromJson(Map<String, dynamic> j) => ProductSpec(_str(j['label']), _str(j['value']));
}

class VariantOption {
  final String id;
  final String label;
  final String? hex;
  final double priceDelta;
  final int stock;
  const VariantOption({required this.id, required this.label, this.hex, required this.priceDelta, required this.stock});
  factory VariantOption.fromJson(Map<String, dynamic> j) => VariantOption(
        id: _str(j['id']),
        label: _str(j['label']),
        hex: j['hex'] as String?,
        priceDelta: _toDouble(j['priceDelta']),
        stock: _toInt(j['stock']),
      );
}

class VariantGroup {
  final String id;
  final String name;
  final String type;
  final List<VariantOption> options;
  const VariantGroup({required this.id, required this.name, required this.type, required this.options});
  factory VariantGroup.fromJson(Map<String, dynamic> j) => VariantGroup(
        id: _str(j['id']),
        name: _str(j['name']),
        type: _str(j['type']),
        options: _maps(j['options']).map(VariantOption.fromJson).toList(),
      );
}

class Product {
  final String id;
  final String slug;
  final String name;
  final String brand;
  final String category;
  final double price;
  final double? oldPrice;
  final double rating;
  final int reviewCount;
  final bool inStock;
  final String image;
  final List<ProductTag> tags;
  final String description;
  final List<ProductSpec> specs;
  final int? stock;
  final List<VariantGroup> variants;

  const Product({
    required this.id,
    required this.slug,
    required this.name,
    required this.brand,
    required this.category,
    required this.price,
    required this.oldPrice,
    required this.rating,
    required this.reviewCount,
    required this.inStock,
    required this.image,
    required this.tags,
    required this.description,
    required this.specs,
    required this.stock,
    required this.variants,
  });

  factory Product.fromJson(Map<String, dynamic> j) {
    final old = j['oldPrice'];
    return Product(
      id: _str(j['id']),
      slug: _str(j['slug']),
      name: _str(j['name']),
      brand: _str(j['brand']),
      category: _str(j['category']),
      price: _toDouble(j['price']),
      oldPrice: old == null ? null : _toDouble(old),
      rating: _toDouble(j['rating']),
      reviewCount: _toInt(j['reviewCount']),
      inStock: j['inStock'] != false,
      image: _str(j['image']),
      tags: _maps(j['tags']).map(ProductTag.fromJson).toList(),
      description: _str(j['description']),
      specs: _maps(j['specs']).map(ProductSpec.fromJson).toList(),
      stock: j['stock'] == null ? null : _toInt(j['stock']),
      variants: _maps(j['variants']).map(VariantGroup.fromJson).toList(),
    );
  }

  bool get hasDiscount => oldPrice != null && oldPrice! > price;

  int get discountPercent => hasDiscount ? (((oldPrice! - price) / oldPrice!) * 100).round() : 0;

  String get webUrl => '/urunler/$slug';
}

class ShopCategory {
  final String id;
  final String name;
  final String slug;
  final String? parent;
  final String description;
  final int order;
  final bool showOnHome;
  final String? image;

  const ShopCategory({
    required this.id,
    required this.name,
    required this.slug,
    required this.parent,
    required this.description,
    required this.order,
    required this.showOnHome,
    required this.image,
  });

  factory ShopCategory.fromJson(Map<String, dynamic> j) => ShopCategory(
        id: _str(j['id']),
        name: _str(j['name']),
        slug: _str(j['slug']),
        parent: (j['parent'] as String?)?.isEmpty == true ? null : j['parent'] as String?,
        description: _str(j['description']),
        order: _toInt(j['order']),
        showOnHome: j['showOnHome'] == true,
        image: (j['image'] as String?)?.isEmpty == true ? null : j['image'] as String?,
      );
}

class HeroSlide {
  final String id;
  final String title;
  final String subtitle;
  final String cta;
  final String image;
  final String? categoryId;

  const HeroSlide({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.cta,
    required this.image,
    required this.categoryId,
  });

  factory HeroSlide.fromJson(Map<String, dynamic> j) => HeroSlide(
        id: _str(j['id']),
        title: _str(j['title']),
        subtitle: _str(j['subtitle']),
        cta: _str(j['cta']),
        image: _str(j['image']),
        categoryId: j['categoryId'] as String?,
      );
}

class CatalogData {
  final String version;
  final List<HeroSlide> heroSlides;
  final List<String> featuredIds;
  final List<String> newIds;
  final List<ShopCategory> categories;
  final List<Product> products;

  const CatalogData({
    required this.version,
    required this.heroSlides,
    required this.featuredIds,
    required this.newIds,
    required this.categories,
    required this.products,
  });

  factory CatalogData.fromJson(Map<String, dynamic> j) => CatalogData(
        version: _str(j['version']),
        heroSlides: _maps(j['heroSlides']).map(HeroSlide.fromJson).toList(),
        featuredIds: (j['featuredProductIds'] as List? ?? const []).map((e) => '$e').toList(),
        newIds: (j['newProductIds'] as List? ?? const []).map((e) => '$e').toList(),
        categories: _maps(j['categories']).map(ShopCategory.fromJson).toList(),
        products: _maps(j['products']).map(Product.fromJson).toList(),
      );
}
