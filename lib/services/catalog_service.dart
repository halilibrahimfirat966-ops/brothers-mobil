import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config.dart';
import '../models/catalog.dart';

/// Katalog üç kaynaktan okunur: (1) sitedeki app-catalog.json, (2) son indirilen
/// kopya (çevrimdışı açılış için), (3) uygulamaya gömülü yedek kopya.
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
}
