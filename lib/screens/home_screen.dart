import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/catalog.dart';
import '../state/catalog_provider.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/product_card.dart';
import 'product_list_screen.dart';
import 'search_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final catalog = context.watch<CatalogProvider>();
    final featured = catalog.featured;
    final discounted = catalog.discounted.take(12).toList();
    final fresh = catalog.newProducts;

    return Scaffold(
      appBar: AppBar(
        title: const BrandLogo(),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SearchScreen())),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: catalog.refresh,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _SearchBox()),
            if (catalog.heroSlides.isNotEmpty) SliverToBoxAdapter(child: _HeroSlider(slides: catalog.heroSlides)),
            const SliverToBoxAdapter(child: _TrustStrip()),
            SliverToBoxAdapter(
              child: SectionHeader(
                title: 'Kategoriler',
                action: 'Tümü',
                onAction: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => ProductListScreen(title: 'Tüm Ürünler', products: catalog.products)),
                ),
              ),
            ),
            SliverToBoxAdapter(child: _CategoryStrip(categories: catalog.homeCategories)),
            if (featured.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: SectionHeader(
                  title: 'Öne Çıkanlar',
                  action: 'Tümü',
                  onAction: () => _openList(context, 'Öne Çıkanlar', featured),
                ),
              ),
              SliverToBoxAdapter(child: ProductStrip(products: featured)),
            ],
            if (discounted.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: SectionHeader(
                  title: 'İndirimli Ürünler',
                  action: 'Tümü',
                  onAction: () => _openList(context, 'İndirimli Ürünler', catalog.discounted),
                ),
              ),
              SliverToBoxAdapter(child: ProductStrip(products: discounted)),
            ],
            if (fresh.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: SectionHeader(
                  title: 'Yeni Gelenler',
                  action: 'Tümü',
                  onAction: () => _openList(context, 'Yeni Gelenler', fresh),
                ),
              ),
              SliverToBoxAdapter(child: ProductStrip(products: fresh)),
            ],
            const SliverToBoxAdapter(child: SectionHeader(title: 'Sizin İçin Seçtiklerimiz')),
            ProductSliverGrid(products: catalog.products.where((p) => p.inStock).take(20).toList()),
          ],
        ),
      ),
    );
  }

  void _openList(BuildContext context, String title, List<Product> items) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => ProductListScreen(title: title, products: items)));
  }
}

class _SearchBox extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SearchScreen())),
        child: Container(
          height: 46,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: const Row(children: [
            Icon(Icons.search, color: AppColors.muted),
            SizedBox(width: 10),
            Expanded(
              child: Text('Ürün, marka veya kategori ara',
                  style: TextStyle(color: AppColors.muted), overflow: TextOverflow.ellipsis),
            ),
          ]),
        ),
      ),
    );
  }
}

class _HeroSlider extends StatefulWidget {
  final List<HeroSlide> slides;
  const _HeroSlider({required this.slides});

  @override
  State<_HeroSlider> createState() => _HeroSliderState();
}

class _HeroSliderState extends State<_HeroSlider> {
  final _controller = PageController();
  Timer? _timer;
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!_controller.hasClients || widget.slides.length < 2) return;
      final next = (_page + 1) % widget.slides.length;
      _controller.animateToPage(next, duration: const Duration(milliseconds: 450), curve: Curves.easeOut);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final catalog = context.read<CatalogProvider>();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Column(
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: PageView.builder(
                controller: _controller,
                itemCount: widget.slides.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (context, i) {
                  final slide = widget.slides[i];
                  final category = slide.categoryId == null ? null : catalog.categoryById(slide.categoryId!);
                  return GestureDetector(
                    onTap: category == null
                        ? null
                        : () => Navigator.of(context).push(MaterialPageRoute(
                              builder: (_) => ProductListScreen.category(category: category),
                            )),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        NetImage(slide.image),
                        const DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [Color(0xE6161B23), Color(0x33161B23)],
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(slide.title,
                                  maxLines: 2,
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800, height: 1.15)),
                              const SizedBox(height: 6),
                              Text(slide.subtitle,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(color: Color(0xFFDCE3EC), fontSize: 12.5, height: 1.3)),
                              const SizedBox(height: 10),
                              if (slide.cta.isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                                  decoration: BoxDecoration(
                                      color: AppColors.green, borderRadius: BorderRadius.circular(8)),
                                  child: Text(slide.cta,
                                      style: const TextStyle(
                                          color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12.5)),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < widget.slides.length; i++)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: i == _page ? 18 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: i == _page ? AppColors.navy : AppColors.border,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TrustStrip extends StatelessWidget {
  const _TrustStrip();

  @override
  Widget build(BuildContext context) {
    const items = [
      (Icons.local_shipping_outlined, 'Hızlı Kargo'),
      (Icons.verified_user_outlined, 'Güvenli Ödeme'),
      (Icons.workspace_premium_outlined, 'Distribütör Garantisi'),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Row(
        children: [
          for (final item in items)
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 3),
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(children: [
                  Icon(item.$1, color: AppColors.green, size: 22),
                  const SizedBox(height: 4),
                  Text(item.$2,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.navy)),
                ]),
              ),
            ),
        ],
      ),
    );
  }
}

class _CategoryStrip extends StatelessWidget {
  final List<ShopCategory> categories;
  const _CategoryStrip({required this.categories});

  @override
  Widget build(BuildContext context) {
    final catalog = context.read<CatalogProvider>();
    return SizedBox(
      height: 112,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, i) {
          final category = categories[i];
          return InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => ProductListScreen.category(category: category))),
            child: SizedBox(
              width: 78,
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: NetImage(catalog.categoryImage(category), width: 72, height: 72),
                  ),
                  const SizedBox(height: 6),
                  Text(category.name,
                      maxLines: 2,
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, height: 1.2)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
