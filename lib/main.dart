import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config.dart';
import 'screens/shell.dart';
import 'state/auth_provider.dart';
import 'state/cart_provider.dart';
import 'state/catalog_provider.dart';
import 'state/favorites_provider.dart';
import 'state/orders_provider.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await Supabase.initialize(url: AppConfig.supabaseUrl, anonKey: AppConfig.supabaseAnonKey);

  final catalog = CatalogProvider();
  final cart = CartProvider();
  final favorites = FavoritesProvider();
  final orders = OrdersProvider();
  final auth = AuthProvider()..init();
  await Future.wait([cart.init(), favorites.init(), orders.init()]);
  // Katalog önbellekten/gömülü kopyadan hemen açılır, siteden güncellemesi arka planda gelir.
  catalog.init();

  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider.value(value: catalog),
      ChangeNotifierProvider.value(value: cart),
      ChangeNotifierProvider.value(value: favorites),
      ChangeNotifierProvider.value(value: orders),
      ChangeNotifierProvider.value(value: auth),
    ],
    child: const BrothersApp(),
  ));
}

class BrothersApp extends StatelessWidget {
  const BrothersApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      home: const AppShell(),
    );
  }
}
