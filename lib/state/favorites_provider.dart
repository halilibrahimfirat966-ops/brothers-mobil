import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FavoritesProvider extends ChangeNotifier {
  static const _key = 'favorites_v1';
  List<String> _ids = [];

  List<String> get ids => List.unmodifiable(_ids);
  int get count => _ids.length;
  bool isFavorite(String id) => _ids.contains(id);

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _ids = prefs.getStringList(_key) ?? [];
    notifyListeners();
  }

  Future<void> toggle(String id) async {
    if (_ids.contains(id)) {
      _ids.remove(id);
    } else {
      _ids.insert(0, id);
    }
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, _ids);
  }
}
