import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/catalog.dart';
import '../screens/product_detail_screen.dart';
import '../state/cart_provider.dart';
import '../state/favorites_provider.dart';
import '../theme.dart';
import 'common.dart';

void openProduct(BuildContext context, Product product) {
  Navigator.of(context).push(MaterialPageRoute(builder: (_) => ProductDetailScreen(productId: product.id)));
}

class ProductCard extends StatelessWidget {
  final Product product;
  const ProductCard({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final favorite = context.select<FavoritesProvider, bool>((f) => f.isFavorite(product.id));
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => openProduct(context, product),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(color: Colors.white, child: NetImage(product.image, fit: BoxFit.contain)),
                  if (product.hasDiscount)
                    Positioned(
                      left: 8,
                      top: 8,
                      child: _Badge(text: '%${product.discountPercent}', color: AppColors.danger),
                    ),
                  if (!product.inStock)
                    Positioned(
                      left: 8,
                      bottom: 8,
                      child: _Badge(text: 'Tükendi', color: AppColors.muted),
                    ),
                  Positioned(
                    right: 4,
                    top: 4,
                    child: IconButton(
                      visualDensity: VisualDensity.compact,
                      style: IconButton.styleFrom(backgroundColor: Colors.white.withValues(alpha: 0.9)),
                      icon: Icon(favorite ? Icons.favorite : Icons.favorite_border,
                          size: 20, color: favorite ? AppColors.danger : AppColors.muted),
                      onPressed: () => context.read<FavoritesProvider>().toggle(product.id),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(product.brand.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 10.5, fontWeight: FontWeight.w700, color: AppColors.blue, letterSpacing: 0.4)),
                    const SizedBox(height: 2),
                    Text(product.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13, height: 1.25, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 4),
                    RatingView(rating: product.rating, count: product.reviewCount, size: 11),
                    const Spacer(),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(child: PriceView(price: product.price, oldPrice: product.oldPrice, size: 15)),
                        if (product.inStock)
                          SizedBox(
                            width: 36,
                            height: 36,
                            child: IconButton.filled(
                              padding: EdgeInsets.zero,
                              style: IconButton.styleFrom(backgroundColor: AppColors.green),
                              icon: const Icon(Icons.add_shopping_cart, size: 18, color: Colors.white),
                              onPressed: () => _quickAdd(context),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _quickAdd(BuildContext context) {
    if (product.variants.isNotEmpty) {
      openProduct(context, product);
      return;
    }
    context.read<CartProvider>().add(product);
    showMessage(context, 'Sepete eklendi: ${product.name}');
  }
}

class _Badge extends StatelessWidget {
  final String text;
  final Color color;
  const _Badge({required this.text, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(6)),
        child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800)),
      );
}

/// İki sütunlu ürün ızgarası (kaydırılabilir alanların içinde sliver olarak).
class ProductSliverGrid extends StatelessWidget {
  final List<Product> products;
  const ProductSliverGrid({super.key, required this.products});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final columns = width >= 900 ? 4 : width >= 600 ? 3 : 2;
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
      sliver: SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 0.52,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, i) => ProductCard(product: products[i]),
          childCount: products.length,
        ),
      ),
    );
  }
}

/// Yatay kaydırılan ürün şeridi.
class ProductStrip extends StatelessWidget {
  final List<Product> products;
  const ProductStrip({super.key, required this.products});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 330,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: products.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, i) => SizedBox(width: 168, child: ProductCard(product: products[i])),
      ),
    );
  }
}
