import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config.dart';
import '../models/catalog.dart';

/// Katalog kaynakları (öncelik sırasıyla):
/// 1) Supabase "products" / "categories" tabloları — canlı, anlık senkron
/// 2) Sitedeki app-catalog.json
/// 3) Son indirilen kopya (çevrimdışı açılış) ve uygulamaya gömülü yedek kopya
class CatalogService {
  static const _cacheKey = 'catalog_cache_v1';

  Future<CatalogData> loadBundled() async {
    final raw = await rootBundle.loadString('assets/catalog.json');
    return CatalogData.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<CatalogData?> loadCached() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_cacheKey);
      if (raw == null) return null;
      return CatalogData.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<CatalogData?> fetchRemote() async {
    try {
      final uri = Uri.parse('${AppConfig.catalogUrl}?t=${DateTime.now().millisecondsSinceEpoch ~/ 60000}');
      final response = await http.get(uri, headers: {'Accept': 'application/json'}).timeout(const Duration(seconds: 20));
      if (response.statusCode != 200) return null;
      final body = utf8.decode(response.bodyBytes);
      // Dosya henüz yayınlanmadıysa site index.html döndürür; JSON değilse yok say.
      if (!body.trimLeft().startsWith('{')) return null;
      final data = CatalogData.fromJson(jsonDecode(body) as Map<String, dynamic>);
      if (data.products.isEmpty) return null;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cacheKey, body);
      return data;
    } catch (_) {
      return null;
    }
  }

  /// Supabase tablolarından canlı katalog. Tablolar yoksa ya da boşsa null döner.
  /// Kampanya slaytları tabloda olmadığı için [base] katalogdan alınır.
  Future<CatalogData?> fetchLive(CatalogData base) async {
    try {
      final client = Supabase.instance.client;
      final results = await Future.wait([
        client.from('products').select().eq('active', true).order('sort_order').limit(5000),
        client.from('categories').select().eq('active', true).order('sort_order').limit(1000),
      ]).timeout(const Duration(seconds: 20));
      final productRows = (results[0] as List).cast<Map<String, dynamic>>();
      final categoryRows = (results[1] as List).cast<Map<String, dynamic>>();
      if (productRows.isEmpty) return null;

      final products = productRows.map((r) => Product.fromJson({
            'id': r['id'],
            'slug': r['slug'] ?? r['id'],
            'name': r['name'],
            'brand': r['brand'],
            'category': r['category'],
            'price': r['price'],
            'oldPrice': r['old_price'],
            'rating': r['rating'],
            'reviewCount': r['review_count'],
            'inStock': r['in_stock'],
            'image': r['image'],
            'tags': r['tags'],
            'description': r['description'],
            'specs': r['specs'],
            'stock': r['stock'],
            'variants': r['variants'],
          })).toList();

      final categories = categoryRows.isEmpty
          ? base.categories
          : categoryRows
              .map((r) => ShopCategory.fromJson({
                    'id': r['id'],
                    'name': r['name'],
                    'slug': r['slug'],
                    'parent': r['parent'],
                    'description': r['description'],
                    'order': r['sort_order'],
                    'showOnHome': r['show_on_home'],
                    'image': r['image'],
                  }))
              .toList();

      return CatalogData(
        version: 'live-${DateTime.now().toIso8601String()}',
        heroSlides: base.heroSlides,
        featuredIds: [for (final r in productRows) if (r['featured'] == true) '${r['id']}'],
        newIds: [for (final r in productRows) if (r['is_new'] == true) '${r['id']}'],
        categories: categories,
        products: products,
      );
    } catch (_) {
      return null;
    }
  }
}
