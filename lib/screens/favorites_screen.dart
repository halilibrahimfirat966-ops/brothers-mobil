import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/catalog.dart';
import '../state/catalog_provider.dart';
import '../state/favorites_provider.dart';
import '../widgets/common.dart';
import '../widgets/product_card.dart';
import 'shell.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final favorites = context.watch<FavoritesProvider>();
    final catalog = context.watch<CatalogProvider>();
    final items = favorites.ids.map(catalog.productById).whereType<Product>().toList();

    return Scaffold(
      appBar: AppBar(title: Text(items.isEmpty ? 'Favorilerim' : 'Favorilerim (${items.length})')),
      body: items.isEmpty
          ? EmptyState(
              icon: Icons.favorite_border,
              title: 'Favori ürününüz yok',
              message: 'Ürünlerdeki kalp simgesine dokunarak favorilerinize ekleyebilirsiniz.',
              actionLabel: 'Ürünleri Keşfet',
              onAction: () => AppShell.goToTab(context, 1),
            )
          : CustomScrollView(slivers: [
              const SliverToBoxAdapter(child: SizedBox(height: 8)),
              ProductSliverGrid(products: items),
            ]),
    );
  }
}
