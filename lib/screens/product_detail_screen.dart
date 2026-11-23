import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/catalog.dart';
import '../state/cart_provider.dart';
import '../state/catalog_provider.dart';
import '../state/favorites_provider.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/product_card.dart';
import 'shell.dart';

class ProductDetailScreen extends StatefulWidget {
  final String productId;
  const ProductDetailScreen({super.key, required this.productId});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _quantity = 1;
  final Map<String, VariantOption> _selected = {};

  @override
  Widget build(BuildContext context) {
    final catalog = context.watch<CatalogProvider>();
    final favorite = context.select<FavoritesProvider, bool>((f) => f.isFavorite(widget.productId));
    final product = catalog.productById(widget.productId);
    if (product == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const EmptyState(
          icon: Icons.inventory_2_outlined,
          title: 'Ürün bulunamadı',
          message: 'Bu ürün artık satışta olmayabilir.',
        ),
      );
    }

    for (final group in product.variants) {
      if (!_selected.containsKey(group.id) && group.options.isNotEmpty) {
        _selected[group.id] = group.options.firstWhere((o) => o.stock > 0, orElse: () => group.options.first);
      }
    }

    final unitPrice = product.price + _selected.values.fold<double>(0, (sum, o) => sum + o.priceDelta);
    final oldUnit = product.oldPrice == null
        ? null
        : product.oldPrice! + _selected.values.fold<double>(0, (sum, o) => sum + o.priceDelta);
    final variantLabel = product.variants
        .map((g) => _selected[g.id]?.label)
        .whereType<String>()
        .join(' · ');
    final variantOutOfStock = _selected.values.any((o) => o.stock <= 0);
    final canBuy = product.inStock && !variantOutOfStock;
    final category = catalog.categoryById(product.category);
    final similar = catalog.similarTo(product);

    return Scaffold(
      appBar: AppBar(
        title: Text(category?.name ?? 'Ürün Detayı', style: const TextStyle(fontSize: 16)),
        actions: [
          IconButton(
            icon: Icon(favorite ? Icons.favorite : Icons.favorite_border, color: favorite ? AppColors.danger : null),
            onPressed: () => context.read<FavoritesProvider>().toggle(product.id),
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          GestureDetector(
            onTap: () => _openImage(context, product),
            child: Container(
              color: Colors.white,
              height: 320,
              padding: const EdgeInsets.all(16),
              child: Hero(tag: 'img-${product.id}', child: NetImage(product.image, fit: BoxFit.contain)),
            ),
          ),
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product.brand.toUpperCase(),
                    style: const TextStyle(color: AppColors.blue, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                const SizedBox(height: 4),
                Text(product.name,
                    style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700, height: 1.3, color: AppColors.navy)),
                const SizedBox(height: 8),
                RatingView(rating: product.rating, count: product.reviewCount, size: 13),
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    PriceView(price: unitPrice, oldPrice: oldUnit, size: 24),
                    const SizedBox(width: 10),
                    if (product.hasDiscount)
                      Container(
                        margin: const EdgeInsets.only(bottom: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: AppColors.danger, borderRadius: BorderRadius.circular(6)),
                        child: Text('%${product.discountPercent} indirim',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12)),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(children: [
                  Icon(canBuy ? Icons.check_circle : Icons.cancel,
                      size: 18, color: canBuy ? AppColors.green : AppColors.muted),
                  const SizedBox(width: 6),
                  Text(
                    canBuy
                        ? (product.stock != null && product.stock! > 0 && product.stock! <= 5
                            ? 'Stokta son ${product.stock} ürün'
                            : 'Stokta · Hızlı kargo')
                        : 'Stokta yok',
                    style: TextStyle(fontWeight: FontWeight.w700, color: canBuy ? AppColors.green : AppColors.muted),
                  ),
                ]),
                if (product.tags.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final tag in product.tags.where((t) => t.tone != 'discount'))
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.greenSoft,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(tag.label,
                              style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.green)),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          for (final group in product.variants) _variantGroup(group),
          if (product.description.isNotEmpty)
            _section('Ürün Açıklaması', Text(product.description, style: const TextStyle(height: 1.5))),
          if (product.specs.isNotEmpty)
            _section(
              'Teknik Özellikler',
              Column(
                children: [
                  for (var i = 0; i < product.specs.length; i++)
                    Container(
                      color: i.isEven ? AppColors.background : Colors.transparent,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 2,
                            child: Text(product.specs[i].label,
                                style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w600)),
                          ),
                          Expanded(flex: 3, child: Text(product.specs[i].value)),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          _section(
            'Teslimat ve Ödeme',
            const Column(children: [
              _InfoRow(Icons.local_shipping_outlined, 'Stoktaki ürünler aynı gün kargoya verilir.'),
              _InfoRow(Icons.lock_outline, 'Ödemeler iyzico güvencesiyle 3D Secure olarak alınır.'),
              _InfoRow(Icons.receipt_long_outlined, 'Tüm ürünler faturalı ve distribütör garantilidir.'),
            ]),
          ),
          if (similar.isNotEmpty) ...[
            const SectionHeader(title: 'Benzer Ürünler'),
            ProductStrip(products: similar),
          ],
          const SizedBox(height: 24),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(top: BorderSide(color: AppColors.border)),
          ),
          child: Row(
            children: [
              if (canBuy) ...[
                QuantityStepper(
                  value: _quantity,
                  max: product.stock != null && product.stock! > 0 ? product.stock! : 99,
                  onChanged: (v) => setState(() => _quantity = v < 1 ? 1 : v),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: FilledButton.icon(
                  onPressed: canBuy
                      ? () {
                          context.read<CartProvider>().add(
                                product,
                                quantity: _quantity,
                                variantLabel: variantLabel,
                                unitPrice: product.variants.isEmpty ? null : unitPrice,
                              );
                          ScaffoldMessenger.of(context)
                            ..hideCurrentSnackBar()
                            ..showSnackBar(SnackBar(
                              behavior: SnackBarBehavior.floating,
                              content: const Text('Ürün sepete eklendi'),
                              action: SnackBarAction(
                                label: 'SEPETE GİT',
                                onPressed: () => AppShell.goToTab(context, 2),
                              ),
                            ));
                        }
                      : null,
                  icon: const Icon(Icons.add_shopping_cart),
                  label: Text(canBuy ? 'Sepete Ekle' : 'Stokta Yok'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _variantGroup(VariantGroup group) {
    return _section(
      group.name,
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final option in group.options)
            ChoiceChip(
              avatar: option.hex == null
                  ? null
                  : CircleAvatar(backgroundColor: _hex(option.hex!), radius: 8),
              label: Text(option.priceDelta > 0 ? '${option.label} (+${option.priceDelta.toStringAsFixed(0)} ₺)' : option.label),
              selected: _selected[group.id]?.id == option.id,
              onSelected: option.stock > 0 ? (_) => setState(() => _selected[group.id] = option) : null,
            ),
        ],
      ),
    );
  }

  Color _hex(String hex) {
    final value = int.tryParse(hex.replaceFirst('#', ''), radix: 16) ?? 0xCCCCCC;
    return Color(0xFF000000 | value);
  }

  Widget _section(String title, Widget child) => Container(
        margin: const EdgeInsets.only(top: 8),
        color: AppColors.surface,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.navy)),
            const SizedBox(height: 10),
            child,
          ],
        ),
      );

  void _openImage(BuildContext context, Product product) {
    Navigator.of(context, rootNavigator: true).push(MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(),
        body: Center(
          child: InteractiveViewer(
            maxScale: 4,
            child: Hero(tag: 'img-${product.id}', child: NetImage(product.image, fit: BoxFit.contain)),
          ),
        ),
      ),
    ));
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoRow(this.icon, this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, size: 20, color: AppColors.green),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: const TextStyle(height: 1.35))),
        ]),
      );
}
