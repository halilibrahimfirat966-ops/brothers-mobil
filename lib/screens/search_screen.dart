import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/catalog.dart';
import '../state/catalog_provider.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/product_card.dart';
import 'product_list_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  static const _historyKey = 'search_history_v1';
  final _controller = TextEditingController();
  Timer? _debounce;
  String _query = '';
  List<String> _history = [];

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((p) {
      if (mounted) setState(() => _history = p.getStringList(_historyKey) ?? []);
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () => setState(() => _query = value.trim()));
  }

  Future<void> _remember(String value) async {
    final q = value.trim();
    if (q.length < 2) return;
    final next = [q, ..._history.where((h) => h.toLowerCase() != q.toLowerCase())].take(8).toList();
    setState(() => _history = next);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_historyKey, next);
  }

  Future<void> _clearHistory() async {
    setState(() => _history = []);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_historyKey);
  }

  void _useTerm(String term) {
    _controller.text = term;
    _controller.selection = TextSelection.collapsed(offset: term.length);
    setState(() => _query = term);
  }

  @override
  Widget build(BuildContext context) {
    final catalog = context.watch<CatalogProvider>();
    final List<Product> results = _query.length >= 2 ? catalog.search(_query) : const [];
    final categories = catalog.searchCategories(_query);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: TextField(
          controller: _controller,
          autofocus: true,
          textInputAction: TextInputAction.search,
          onChanged: _onChanged,
          onSubmitted: (v) {
            _remember(v);
            setState(() => _query = v.trim());
          },
          decoration: InputDecoration(
            hintText: 'Ürün, marka veya kategori ara',
            isDense: true,
            suffixIcon: _controller.text.isEmpty
                ? null
                : IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      _controller.clear();
                      setState(() => _query = '');
                    },
                  ),
          ),
        ),
        actions: const [SizedBox(width: 12)],
      ),
      body: _query.length < 2
          ? ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (_history.isNotEmpty) ...[
                  Row(children: [
                    const Expanded(
                        child: Text('Son aramalar', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16))),
                    TextButton(onPressed: _clearHistory, child: const Text('Temizle')),
                  ]),
                  Wrap(spacing: 8, runSpacing: 8, children: [
                    for (final h in _history) ActionChip(label: Text(h), onPressed: () => _useTerm(h)),
                  ]),
                  const SizedBox(height: 20),
                ],
                const Text('Popüler aramalar', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                const SizedBox(height: 10),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  for (final t in const ['Router', 'Switch', 'SSD', 'Monitör', 'IP Kamera', 'UPS', 'Yazıcı', 'Laptop'])
                    ActionChip(label: Text(t), onPressed: () => _useTerm(t)),
                ]),
              ],
            )
          : CustomScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              slivers: [
                if (categories.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                      child: Wrap(spacing: 8, runSpacing: 8, children: [
                        for (final c in categories)
                          ActionChip(
                            avatar: const Icon(Icons.category_outlined, size: 16),
                            label: Text(c.name),
                            onPressed: () => Navigator.of(context)
                                .push(MaterialPageRoute(builder: (_) => ProductListScreen.category(category: c))),
                          ),
                      ]),
                    ),
                  ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                    child: Text('"$_query" için ${results.length} sonuç',
                        style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w600)),
                  ),
                ),
                if (results.isEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: EmptyState(
                      icon: Icons.search_off,
                      title: 'Sonuç bulunamadı',
                      message: 'Farklı bir kelime ya da marka adıyla tekrar deneyin.',
                    ),
                  )
                else
                  ProductSliverGrid(products: results),
              ],
            ),
    );
  }
}
