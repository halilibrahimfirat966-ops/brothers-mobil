import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config.dart';
import '../state/auth_provider.dart';
import '../state/orders_provider.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'account_pages.dart';
import 'auth_screen.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final orderCount = context.select<OrdersProvider, int>((o) => o.orders.length);

    void push(Widget page) => Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
    void needLogin(Widget page) {
      if (auth.isLoggedIn) {
        push(page);
      } else {
        Navigator.of(context, rootNavigator: true).push(MaterialPageRoute(builder: (_) => const AuthScreen()));
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Hesabım')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: auth.isLoggedIn
                  ? Row(children: [
                      CircleAvatar(
                        radius: 26,
                        backgroundColor: AppColors.navy,
                        child: Text(
                          _initials(auth.fullName.isNotEmpty ? auth.fullName : auth.email),
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(auth.fullName.isNotEmpty ? auth.fullName : 'Hoş geldiniz',
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                          Text(auth.email, style: const TextStyle(color: AppColors.muted)),
                        ]),
                      ),
                    ])
                  : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                      const Text('Hesabınıza giriş yapın',
                          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: AppColors.navy)),
                      const SizedBox(height: 4),
                      const Text('Adreslerinizi kaydedin, ödemeyi hızlandırın.', style: TextStyle(color: AppColors.muted)),
                      const SizedBox(height: 14),
                      Row(children: [
                        Expanded(
                          child: FilledButton(
                            onPressed: () => Navigator.of(context, rootNavigator: true)
                                .push(MaterialPageRoute(builder: (_) => const AuthScreen())),
                            child: const Text('Giriş Yap'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(context, rootNavigator: true).push(
                                MaterialPageRoute(builder: (_) => const AuthScreen(startWithRegister: true))),
                            child: const Text('Üye Ol'),
                          ),
                        ),
                      ]),
                    ]),
            ),
          ),
          const SizedBox(height: 16),
          _group([
            _tile(Icons.receipt_long_outlined, 'Siparişlerim', () => push(const OrdersPage()),
                trailing: orderCount > 0 ? '$orderCount' : null),
            _tile(Icons.local_shipping_outlined, 'Kargo Takibi', () => openExternal(context, '/kargo-takip', title: 'Kargo Takibi')),
            _tile(Icons.location_on_outlined, 'Adreslerim', () => needLogin(const AddressesPage())),
            _tile(Icons.person_outline, 'Kullanıcı Bilgilerim', () => needLogin(const ProfilePage())),
          ]),
          const SizedBox(height: 16),
          _group([
            _tile(Icons.support_agent_outlined, 'İletişim & Destek', () => push(const ContactPage())),
            _tile(Icons.help_outline, 'Sıkça Sorulan Sorular', () => openExternal(context, '/sikca-sorulan-sorular', title: 'Sıkça Sorulan Sorular')),
            _tile(Icons.account_balance_outlined, 'Havale / EFT Bilgileri',
                () => openExternal(context, '/havale-banka-bilgileri', title: 'Havale / EFT Bilgileri')),
            _tile(Icons.privacy_tip_outlined, 'Gizlilik Politikası', () => openExternal(context, '/gizlilik-politikasi', title: 'Gizlilik Politikası')),
            _tile(Icons.cookie_outlined, 'Çerez Politikası', () => openExternal(context, '/cerez-politikasi', title: 'Çerez Politikası')),
          ]),
          if (auth.isLoggedIn) ...[
            const SizedBox(height: 16),
            _group([
              ListTile(
                leading: const Icon(Icons.logout, color: AppColors.danger),
                title: const Text('Çıkış Yap', style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.w600)),
                onTap: () async {
                  await context.read<AuthProvider>().signOut();
                  if (context.mounted) showMessage(context, 'Çıkış yapıldı.');
                },
              ),
            ]),
          ],
          const SizedBox(height: 24),
          const Center(
            child: Text('${AppConfig.appName} · v1.0.0', style: TextStyle(color: AppColors.muted, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  static String _initials(String text) {
    final parts = text.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.characters.first.toUpperCase();
    return (parts.first.characters.first + parts.last.characters.first).toUpperCase();
  }

  Widget _group(List<Widget> tiles) => Card(
        clipBehavior: Clip.antiAlias,
        child: Column(children: [
          for (var i = 0; i < tiles.length; i++) ...[
            if (i > 0) const Divider(indent: 56),
            tiles[i],
          ],
        ]),
      );

  Widget _tile(IconData icon, String title, VoidCallback onTap, {String? trailing}) => ListTile(
        leading: Icon(icon, color: AppColors.navy),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
          if (trailing != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: AppColors.greenSoft, borderRadius: BorderRadius.circular(10)),
              child: Text(trailing, style: const TextStyle(color: AppColors.green, fontWeight: FontWeight.w800)),
            ),
          const Icon(Icons.chevron_right, color: AppColors.muted),
        ]),
        onTap: onTap,
      );
}
