import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config.dart';
import '../state/cart_provider.dart';
import '../state/catalog_provider.dart';
import '../theme.dart';
import '../utils/format.dart';
import '../widgets/common.dart';
import '../widgets/product_card.dart';
import 'checkout_screen.dart';
import 'shell.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final catalog = context.watch<CatalogProvider>();
    final summary = cart.summary(catalog);

    return Scaffold(
      appBar: AppBar(
        title: Text(summary.isEmpty ? 'Sepetim' : 'Sepetim (${summary.count})'),
        actions: [
          if (!summary.isEmpty)
            TextButton(
              onPressed: () async {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Sepeti boşalt'),
                    content: const Text('Sepetteki tüm ürünler kaldırılsın mı?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Vazgeç')),
                      TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Boşalt')),
                    ],
                  ),
                );
                if (ok == true) cart.clear();
              },
              child: const Text('Boşalt', style: TextStyle(color: AppColors.danger)),
            ),
        ],
      ),
      body: summary.isEmpty
          ? EmptyState(
              icon: Icons.shopping_cart_outlined,
              title: 'Sepetiniz boş',
              message: 'Beğendiğiniz ürünleri sepete ekleyerek alışverişe başlayın.',
              actionLabel: 'Alışverişe Başla',
              onAction: () => AppShell.goToTab(context, 0),
            )
          : ListView(
              padding: const EdgeInsets.all(12),
              children: [
                if (!AppConfig.freeShippingEnabled && summary.subtotal < AppConfig.freeShippingThreshold)
                  Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: AppColors.greenSoft, borderRadius: BorderRadius.circular(12)),
                    child: Text(
                      '${formatPrice(AppConfig.freeShippingThreshold - summary.subtotal)} daha ekleyin, kargo bedava olsun!',
                      style: const TextStyle(color: AppColors.green, fontWeight: FontWeight.w700),
                    ),
                  ),
                for (final entry in summary.entries)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Dismissible(
                      key: ValueKey(entry.line.key),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        decoration: BoxDecoration(color: AppColors.danger, borderRadius: BorderRadius.circular(14)),
                        child: const Icon(Icons.delete_outline, color: Colors.white),
                      ),
                      onDismissed: (_) => cart.remove(entry.line.key),
                      child: Card(
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () => openProduct(context, entry.product),
                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 84,
                                  height: 84,
                                  color: Colors.white,
                                  child: NetImage(entry.product.image, fit: BoxFit.contain),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(entry.product.name,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(fontWeight: FontWeight.w600, height: 1.25)),
                                      if (entry.line.variantLabel.isNotEmpty)
                                        Text(entry.line.variantLabel,
                                            style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          QuantityStepper(
                                            value: entry.line.quantity,
                                            onChanged: (v) => cart.setQuantity(entry.line.key, v),
                                          ),
                                          const Spacer(),
                                          Text(formatPrice(entry.lineTotal),
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.w800, color: AppColors.navy, fontSize: 15)),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 4),
                _SummaryCard(summary: summary),
              ],
            ),
      bottomNavigationBar: summary.isEmpty
          ? null
          : SafeArea(
              top: false,
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  border: Border(top: BorderSide(color: AppColors.border)),
                ),
                child: Row(
                  children: [
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Toplam', style: TextStyle(color: AppColors.muted, fontSize: 12)),
                        Text(formatPrice(summary.total),
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.navy)),
                      ],
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: FilledButton(
                        onPressed: () => Navigator.of(context, rootNavigator: true)
                            .push(MaterialPageRoute(builder: (_) => const CheckoutScreen())),
                        child: const Text('Siparişi Tamamla'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final CartSummary summary;
  const _SummaryCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            _row('Ara toplam', formatPrice(summary.subtotal)),
            const SizedBox(height: 6),
            _row('Kargo', summary.shipping == 0 ? 'Ücretsiz' : formatPrice(summary.shipping),
                highlight: summary.shipping == 0),
            const Padding(padding: EdgeInsets.symmetric(vertical: 10), child: Divider()),
            _row('Ödenecek tutar', formatPrice(summary.total), bold: true),
            const SizedBox(height: 6),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('Fiyatlara KDV dahildir.', style: TextStyle(color: AppColors.muted, fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value, {bool bold = false, bool highlight = false}) => Row(
        children: [
          Expanded(
            child: Text(label,
                style: TextStyle(
                    fontWeight: bold ? FontWeight.w800 : FontWeight.w500, color: bold ? AppColors.navy : AppColors.muted)),
          ),
          Text(value,
              style: TextStyle(
                fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
                fontSize: bold ? 17 : 14,
                color: highlight ? AppColors.green : AppColors.navy,
              )),
        ],
      );
}
