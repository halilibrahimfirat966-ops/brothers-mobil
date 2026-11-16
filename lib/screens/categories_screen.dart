import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/catalog.dart';
import '../state/catalog_provider.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'product_list_screen.dart';
import 'search_screen.dart';

/// Solda ana kategoriler, sağda seçili kategorinin alt kırılımları.
class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  String? _selectedId;

  @override
  Widget build(BuildContext context) {
    final catalog = context.watch<CatalogProvider>();
    final roots = catalog.rootCategories;
    if (roots.isEmpty) {
      return const Scaffold(body: Center(child: Text('Kategori bulunamadı.')));
    }
    final selected = roots.firstWhere((c) => c.id == _selectedId, orElse: () => roots.first);
    final children = catalog.childrenOf(selected.id);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kategoriler'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SearchScreen())),
          ),
        ],
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            width: 112,
            color: AppColors.surface,
            child: ListView.builder(
              itemCount: roots.length,
              itemBuilder: (context, i) {
                final category = roots[i];
                final active = category.id == selected.id;
                return InkWell(
                  onTap: () => setState(() => _selectedId = category.id),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
                    decoration: BoxDecoration(
                      color: active ? AppColors.background : AppColors.surface,
                      border: Border(
                        left: BorderSide(color: active ? AppColors.green : Colors.transparent, width: 3),
                      ),
                    ),
                    child: Text(
                      category.name,
                      style: TextStyle(
                        fontSize: 12.5,
                        height: 1.25,
                        fontWeight: active ? FontWeight.w800 : FontWeight.w500,
                        color: active ? AppColors.navy : AppColors.muted,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: [
                _CategoryBanner(category: selected),
                const SizedBox(height: 12),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: children.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 0.82,
                  ),
                  itemBuilder: (context, i) => _SubCategoryTile(category: children[i]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryBanner extends StatelessWidget {
  final ShopCategory category;
  const _CategoryBanner({required this.category});

  @override
  Widget build(BuildContext context) {
    final catalog = context.read<CatalogProvider>();
    final count = catalog.productCount(category.id);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => ProductListScreen.category(category: category))),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: NetImage(catalog.categoryImage(category), width: 56, height: 56),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(category.name,
                        style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.navy, fontSize: 15)),
                    const SizedBox(height: 2),
                    Text('Tümünü gör · $count ürün', style: const TextStyle(color: AppColors.blue, fontSize: 12.5)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.muted),
            ],
          ),
        ),
      ),
    );
  }
}

class _SubCategoryTile extends StatelessWidget {
  final ShopCategory category;
  const _SubCategoryTile({required this.category});

  @override
  Widget build(BuildContext context) {
    final catalog = context.read<CatalogProvider>();
    final count = catalog.productCount(category.id);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => ProductListScreen.category(category: category))),
        child: Column(
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                color: Colors.white,
                padding: const EdgeInsets.all(8),
                child: NetImage(catalog.categoryImage(category), fit: BoxFit.contain),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
              child: Column(children: [
                Text(category.name,
                    maxLines: 2,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, height: 1.2)),
                Text('$count ürün', style: const TextStyle(fontSize: 11, color: AppColors.muted)),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}
