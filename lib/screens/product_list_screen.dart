import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/catalog.dart';
import '../state/catalog_provider.dart';
import '../theme.dart';
import '../utils/format.dart';
import '../widgets/common.dart';
import '../widgets/product_card.dart';

enum SortMode { recommended, priceAsc, priceDesc, rating, discount, name }

const _sortLabels = {
  SortMode.recommended: 'Önerilen',
  SortMode.priceAsc: 'En düşük fiyat',
  SortMode.priceDesc: 'En yüksek fiyat',
  SortMode.rating: 'En yüksek puan',
  SortMode.discount: 'En çok indirim',
  SortMode.name: 'İsme göre (A-Z)',
};

class ProductListScreen extends StatefulWidget {
  final String title;
  final List<Product>? products;
  final ShopCategory? category;

  const ProductListScreen({super.key, required this.title, required List<Product> this.products}) : category = null;

  const ProductListScreen.category({super.key, required ShopCategory this.category})
      : title = '',
        products = null;

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  SortMode _sort = SortMode.recommended;
  Set<String> _brands = {};
  bool _onlyInStock = false;
  double? _minPrice;
  double? _maxPrice;
  String? _subCategoryId;

  int get _activeFilters =>
      (_brands.isNotEmpty ? 1 : 0) + (_onlyInStock ? 1 : 0) + (_minPrice != null || _maxPrice != null ? 1 : 0);

  @override
  Widget build(BuildContext context) {
    final catalog = context.watch<CatalogProvider>();
    final category = widget.category;
    final subCategories = category == null ? const <ShopCategory>[] : catalog.childrenOf(category.id);
    final source = category == null
        ? widget.products!
        : catalog.productsInCategory(_subCategoryId ?? category.id);
    final brands = source.map((p) => p.brand).toSet().toList()..sort((a, b) => trSortKey(a).compareTo(trSortKey(b)));
    final items = _apply(source);

    return Scaffold(
      appBar: AppBar(title: Text(category?.name ?? widget.title)),
      body: CustomScrollView(
        slivers: [
          if (subCategories.isNotEmpty)
            SliverToBoxAdapter(
              child: SizedBox(
                height: 52,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
                  children: [
                    _chip('Tümü', _subCategoryId == null, () => setState(() => _subCategoryId = null)),
                    for (final sub in subCategories)
                      _chip(sub.name, _subCategoryId == sub.id, () => setState(() => _subCategoryId = sub.id)),
                  ],
                ),
              ),
            ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 8, 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text('${items.length} ürün',
                        style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w600)),
                  ),
                  TextButton.icon(
                    onPressed: () => _openSort(context),
                    icon: const Icon(Icons.swap_vert, size: 18),
                    label: Text(_sortLabels[_sort]!),
                  ),
                  TextButton.icon(
                    onPressed: () => _openFilters(context, brands),
                    icon: Badge(
                      isLabelVisible: _activeFilters > 0,
                      label: Text('$_activeFilters'),
                      child: const Icon(Icons.tune, size: 18),
                    ),
                    label: const Text('Filtrele'),
                  ),
                ],
              ),
            ),
          ),
          if (items.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: EmptyState(
                icon: Icons.search_off,
                title: 'Ürün bulunamadı',
                message: 'Seçtiğiniz filtrelere uygun ürün yok.',
                actionLabel: _activeFilters > 0 ? 'Filtreleri temizle' : null,
                onAction: _clearFilters,
              ),
            )
          else
            ProductSliverGrid(products: items),
        ],
      ),
    );
  }

  Widget _chip(String label, bool selected, VoidCallback onTap) => Padding(
        padding: const EdgeInsets.only(right: 8),
        child: ChoiceChip(
          label: Text(label),
          selected: selected,
          onSelected: (_) => onTap(),
          selectedColor: AppColors.navy,
          labelStyle: TextStyle(color: selected ? Colors.white : AppColors.navy, fontSize: 12.5),
          showCheckmark: false,
        ),
      );

  List<Product> _apply(List<Product> source) {
    final list = source.where((p) {
      if (_onlyInStock && !p.inStock) return false;
      if (_brands.isNotEmpty && !_brands.contains(p.brand)) return false;
      if (_minPrice != null && p.price < _minPrice!) return false;
      if (_maxPrice != null && p.price > _maxPrice!) return false;
      return true;
    }).toList();
    switch (_sort) {
      case SortMode.recommended:
        list.sort((a, b) => (b.inStock ? 1 : 0).compareTo(a.inStock ? 1 : 0));
      case SortMode.priceAsc:
        list.sort((a, b) => a.price.compareTo(b.price));
      case SortMode.priceDesc:
        list.sort((a, b) => b.price.compareTo(a.price));
      case SortMode.rating:
        list.sort((a, b) => b.rating.compareTo(a.rating));
      case SortMode.discount:
        list.sort((a, b) => b.discountPercent.compareTo(a.discountPercent));
      case SortMode.name:
        list.sort((a, b) => trSortKey(a.name).compareTo(trSortKey(b.name)));
    }
    return list;
  }

  void _clearFilters() => setState(() {
        _brands = {};
        _onlyInStock = false;
        _minPrice = null;
        _maxPrice = null;
      });

  void _openSort(BuildContext context) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final mode in SortMode.values)
              ListTile(
                title: Text(_sortLabels[mode]!),
                trailing: mode == _sort ? const Icon(Icons.check, color: AppColors.green) : null,
                onTap: () {
                  setState(() => _sort = mode);
                  Navigator.pop(context);
                },
              ),
          ],
        ),
      ),
    );
  }

  void _openFilters(BuildContext context, List<String> brands) {
    final minCtrl = TextEditingController(text: _minPrice?.toStringAsFixed(0) ?? '');
    final maxCtrl = TextEditingController(text: _maxPrice?.toStringAsFixed(0) ?? '');
    var brandSel = Set<String>.from(_brands);
    var stockOnly = _onlyInStock;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheet) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Text('Filtrele', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                ),
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    padding: const EdgeInsets.all(20),
                    children: [
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Yalnızca stoktakiler'),
                        value: stockOnly,
                        onChanged: (v) => setSheet(() => stockOnly = v),
                      ),
                      const SizedBox(height: 8),
                      const Text('Fiyat aralığı (₺)', style: TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      Row(children: [
                        Expanded(
                          child: TextField(
                            controller: minCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(hintText: 'En az'),
                          ),
                        ),
                        const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text('–')),
                        Expanded(
                          child: TextField(
                            controller: maxCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(hintText: 'En çok'),
                          ),
                        ),
                      ]),
                      const SizedBox(height: 16),
                      if (brands.length > 1) ...[
                        const Text('Marka', style: TextStyle(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final brand in brands)
                              FilterChip(
                                label: Text(brand),
                                selected: brandSel.contains(brand),
                                onSelected: (v) => setSheet(() {
                                  brandSel = {...brandSel};
                                  v ? brandSel.add(brand) : brandSel.remove(brand);
                                }),
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                    child: Row(children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            _clearFilters();
                          },
                          child: const Text('Temizle'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: () {
                            Navigator.pop(context);
                            setState(() {
                              _brands = brandSel;
                              _onlyInStock = stockOnly;
                              _minPrice = double.tryParse(minCtrl.text.replaceAll('.', '').replaceAll(',', '.'));
                              _maxPrice = double.tryParse(maxCtrl.text.replaceAll('.', '').replaceAll(',', '.'));
                            });
                          },
                          child: const Text('Uygula'),
                        ),
                      ),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
