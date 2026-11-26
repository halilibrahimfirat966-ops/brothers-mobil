import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/catalog.dart';
import '../services/catalog_service.dart';
import '../utils/format.dart';

class CatalogProvider extends ChangeNotifier with WidgetsBindingObserver {
  final CatalogService _service = CatalogService();
  CatalogData? _base;
  RealtimeChannel? _channel;
  Timer? _debounce;
  Timer? _periodic;
  bool _live = false;

  /// Ürünler Supabase'den canlı geliyorsa true.
  bool get isLive => _live;

  CatalogData? _data;
  bool _loading = true;
  bool _refreshing = false;
  Map<String, Product> _byId = {};
  Map<String, ShopCategory> _categoryById = {};
  Map<String, List<ShopCategory>> _children = {};
  Map<String, String> _searchIndex = {};

  bool get loading => _loading;
  bool get refreshing => _refreshing;
  bool get ready => _data != null;
  List<Product> get products => _data?.products ?? const [];
  List<HeroSlide> get heroSlides => _data?.heroSlides ?? const [];
  List<ShopCategory> get categories => _data?.categories ?? const [];

  Future<void> init() async {
    final cached = await _service.loadCached();
    _base = cached ?? await _service.loadBundled();
    _apply(_base!);
    _loading = false;
    notifyListeners();
    WidgetsBinding.instance.addObserver(this);
    await refresh();
    _subscribe();
    // Realtime bağlantısı koparsa ya da gizlenen ürün olayı gelmezse diye düzenli kontrol.
    _periodic = Timer.periodic(const Duration(minutes: 2), (_) => _reloadLive());
  }

  Future<void> refresh() async {
    _refreshing = true;
    notifyListeners();
    final live = await _service.fetchLive(_base ?? _data!);
    if (live != null) {
      _live = true;
      _apply(live);
    } else {
      _live = false;
      final remote = await _service.fetchRemote();
      if (remote != null) {
        _base = remote;
        _apply(remote);
      }
    }
    _refreshing = false;
    notifyListeners();
  }

  Future<void> _reloadLive() async {
    final live = await _service.fetchLive(_base ?? _data!);
    if (live == null) return;
    _live = true;
    _apply(live);
    notifyListeners();
  }

  /// Sitede ürün eklenince / silinince / değişince Supabase anında haber verir.
  void _subscribe() {
    void schedule(PostgresChangePayload _) {
      _debounce?.cancel();
      _debounce = Timer(const Duration(milliseconds: 800), _reloadLive);
    }

    _channel = Supabase.instance.client
        .channel('bt-catalog-live')
        .onPostgresChanges(event: PostgresChangeEvent.all, schema: 'public', table: 'products', callback: schedule)
        .onPostgresChanges(event: PostgresChangeEvent.all, schema: 'public', table: 'categories', callback: schedule)
        .subscribe();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _reloadLive();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _debounce?.cancel();
    _periodic?.cancel();
    final channel = _channel;
    if (channel != null) Supabase.instance.client.removeChannel(channel);
    super.dispose();
  }

  void _apply(CatalogData data) {
    _data = data;
    _byId = {for (final p in data.products) p.id: p};
    _categoryById = {for (final c in data.categories) c.id: c};
    _children = {};
    for (final c in data.categories) {
      if (c.parent != null) _children.putIfAbsent(c.parent!, () => []).add(c);
    }
    for (final list in _children.values) {
      list.sort((a, b) => a.order.compareTo(b.order));
    }
    _searchIndex = {
      for (final p in data.products)
        p.id: normalizeTr([
          p.name,
          p.brand,
          _categoryById[p.category]?.name ?? '',
          ...p.specs.map((s) => s.value),
        ].join(' ')),
    };
  }

  Product? productById(String id) => _byId[id];
  ShopCategory? categoryById(String id) => _categoryById[id];

  List<ShopCategory> get rootCategories =>
      categories.where((c) => c.parent == null).toList()..sort((a, b) => a.order.compareTo(b.order));

  List<ShopCategory> childrenOf(String id) => _children[id] ?? const [];

  List<ShopCategory> get homeCategories {
    final roots = rootCategories.where((c) => c.showOnHome).toList();
    final kids = rootCategories.expand((r) => childrenOf(r.id)).where((c) => c.showOnHome);
    return [...roots, ...kids];
  }

  /// Kategori ve tüm alt kategorilerindeki ürünler.
  List<Product> productsInCategory(String id) {
    final ids = <String>{id};
    void walk(String parent) {
      for (final child in childrenOf(parent)) {
        ids.add(child.id);
        walk(child.id);
      }
    }

    walk(id);
    return products.where((p) => ids.contains(p.category)).toList();
  }

  int productCount(String categoryId) => productsInCategory(categoryId).length;

  /// Alt kategorilerde görsel yoksa üst kategorinin ya da ilk ürünün görseli kullanılır.
  String categoryImage(ShopCategory category) {
    if (category.image != null && category.image!.isNotEmpty) return category.image!;
    final parent = category.parent == null ? null : _categoryById[category.parent!];
    final items = productsInCategory(category.id);
    if (items.isNotEmpty) return items.first.image;
    if (parent?.image != null) return parent!.image!;
    return '';
  }

  List<Product> _resolve(List<String> ids) =>
      ids.map((id) => _byId[id]).whereType<Product>().toList();

  List<Product> get featured {
    final list = _resolve(_data?.featuredIds ?? const []);
    return list.isNotEmpty ? list : products.take(10).toList();
  }

  List<Product> get newProducts => _resolve(_data?.newIds ?? const []);

  List<Product> get discounted {
    final list = products.where((p) => p.hasDiscount && p.inStock).toList()
      ..sort((a, b) => b.discountPercent.compareTo(a.discountPercent));
    return list;
  }

  List<Product> similarTo(Product product, {int limit = 10}) =>
      products.where((p) => p.category == product.category && p.id != product.id).take(limit).toList();

  List<Product> search(String query) {
    final terms = normalizeTr(query).split(RegExp(r'\s+')).where((t) => t.isNotEmpty).toList();
    if (terms.isEmpty) return const [];
    final results = products.where((p) {
      final text = _searchIndex[p.id] ?? '';
      return terms.every(text.contains);
    }).toList();
    final first = normalizeTr(query.trim());
    results.sort((a, b) {
      final an = normalizeTr(a.name).startsWith(first) || normalizeTr(a.brand).startsWith(first) ? 0 : 1;
      final bn = normalizeTr(b.name).startsWith(first) || normalizeTr(b.brand).startsWith(first) ? 0 : 1;
      return an.compareTo(bn);
    });
    return results;
  }

  List<ShopCategory> searchCategories(String query) {
    final q = normalizeTr(query.trim());
    if (q.length < 2) return const [];
    return categories.where((c) => normalizeTr(c.name).contains(q)).take(6).toList();
  }
}
