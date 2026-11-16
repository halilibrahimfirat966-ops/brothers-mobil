import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../state/cart_provider.dart';
import '../state/catalog_provider.dart';
import '../state/favorites_provider.dart';
import 'account_screen.dart';
import 'cart_screen.dart';
import 'categories_screen.dart';
import 'favorites_screen.dart';
import 'home_screen.dart';

/// Alt menülü ana iskelet. Sekmeler arasında geçişte sayfa durumları korunur.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  static void goToTab(BuildContext context, int index) {
    context.findAncestorStateOfType<_AppShellState>()?.select(index);
  }

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;
  final _navigatorKeys = List.generate(5, (_) => GlobalKey<NavigatorState>());

  void select(int index) {
    if (index == _index) {
      _navigatorKeys[index].currentState?.popUntil((r) => r.isFirst);
    }
    setState(() => _index = index);
  }

  @override
  Widget build(BuildContext context) {
    final loading = context.select<CatalogProvider, bool>((c) => c.loading);
    final cartCount = context.select<CartProvider, int>((c) => c.count);
    final favCount = context.select<FavoritesProvider, int>((f) => f.count);

    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final pages = const [HomeScreen(), CategoriesScreen(), CartScreen(), FavoritesScreen(), AccountScreen()];

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        final nav = _navigatorKeys[_index].currentState;
        if (nav != null && nav.canPop()) {
          nav.pop();
        } else if (_index != 0) {
          setState(() => _index = 0);
        } else {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        body: IndexedStack(
          index: _index,
          children: [
            for (var i = 0; i < pages.length; i++)
              Navigator(
                key: _navigatorKeys[i],
                onGenerateRoute: (_) => MaterialPageRoute(builder: (_) => pages[i]),
              ),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: select,
          destinations: [
            const NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Ana Sayfa'),
            const NavigationDestination(
                icon: Icon(Icons.grid_view_outlined), selectedIcon: Icon(Icons.grid_view_rounded), label: 'Kategoriler'),
            NavigationDestination(
              icon: Badge(isLabelVisible: cartCount > 0, label: Text('$cartCount'), child: const Icon(Icons.shopping_cart_outlined)),
              selectedIcon: Badge(isLabelVisible: cartCount > 0, label: Text('$cartCount'), child: const Icon(Icons.shopping_cart)),
              label: 'Sepetim',
            ),
            NavigationDestination(
              icon: Badge(isLabelVisible: favCount > 0, label: Text('$favCount'), child: const Icon(Icons.favorite_border)),
              selectedIcon: Badge(isLabelVisible: favCount > 0, label: Text('$favCount'), child: const Icon(Icons.favorite)),
              label: 'Favoriler',
            ),
            const NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Hesabım'),
          ],
        ),
      ),
    );
  }
}
