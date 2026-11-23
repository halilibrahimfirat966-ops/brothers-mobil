import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config.dart';
import '../models/order.dart';
import '../services/payment_service.dart';
import '../state/auth_provider.dart';
import '../state/cart_provider.dart';
import '../state/catalog_provider.dart';
import '../theme.dart';
import '../utils/format.dart';
import '../utils/tr_cities.dart';
import '../widgets/common.dart';
import 'auth_screen.dart';
import 'payment_webview_screen.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _district = TextEditingController();
  final _address = TextEditingController();
  String? _city;
  String? _addressId;
  bool _accepted = false;
  bool _saveAddress = true;
  bool _processing = false;
  bool _prefilled = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _prefill();
  }

  void _prefill() {
    final auth = context.read<AuthProvider>();
    if (_prefilled || !auth.isLoggedIn) return;
    _prefilled = true;
    _email.text = auth.email;
    final address = auth.defaultAddress;
    if (address != null) {
      _applyAddress(address);
    } else {
      _name.text = auth.fullName;
      _phone.text = auth.phone;
    }
  }

  void _applyAddress(SavedAddress address) {
    _addressId = address.id;
    _name.text = address.fullName;
    _phone.text = address.phone;
    _city = trCities.contains(address.city) ? address.city : null;
    _district.text = address.district;
    _address.text = address.addressLine;
  }

  void _useAddress(SavedAddress address) => setState(() => _applyAddress(address));

  @override
  void dispose() {
    for (final c in [_name, _phone, _email, _district, _address]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit(CartSummary summary) async {
    if (!_formKey.currentState!.validate()) return;
    if (_city == null) {
      showMessage(context, 'Lütfen il seçin.', error: true);
      return;
    }
    if (!_accepted) {
      showMessage(context, 'Devam etmek için satış sözleşmesini onaylayın.', error: true);
      return;
    }
    final auth = context.read<AuthProvider>();

    final items = summary.entries
        .map((e) => PaymentItem(
              id: e.product.id,
              name: e.line.variantLabel.isEmpty ? e.product.name : '${e.product.name} (${e.line.variantLabel})',
              price: e.unitPrice,
              quantity: e.line.quantity,
            ))
        .toList();
    if (summary.shipping > 0) {
      items.add(PaymentItem(id: 'SHIPPING', name: 'Kargo ücreti', price: summary.shipping, quantity: 1));
    }

    final email = auth.isLoggedIn
        ? auth.email
        : (_email.text.trim().isNotEmpty ? _email.text.trim() : AppConfig.guestEmail);
    final fullAddress = '${_address.text.trim()}${_district.text.trim().isEmpty ? '' : ' / ${_district.text.trim()}'}';

    setState(() => _processing = true);

    if (auth.isLoggedIn && _saveAddress && _addressId == null) {
      // Adres kaydı ödemeyi engellemez; başarısız olursa sessizce geçilir.
      await auth.addAddress(
        title: 'Teslimat adresim',
        fullName: _name.text,
        phone: _phone.text,
        city: _city!,
        district: _district.text,
        addressLine: _address.text,
      );
    }

    final result = await PaymentService().start(
      items: items,
      buyer: PaymentBuyer(
        fullName: _name.text.trim(),
        email: email,
        phone: _phone.text.trim(),
        address: fullAddress,
        city: _city!,
      ),
    );
    if (!mounted) return;
    setState(() => _processing = false);

    if (!result.ok) {
      showMessage(context, result.message, error: true);
      return;
    }

    final snapshot = summary.entries
        .map((e) => OrderItem(
              productId: e.product.id,
              name: e.line.variantLabel.isEmpty ? e.product.name : '${e.product.name} (${e.line.variantLabel})',
              image: e.product.image,
              quantity: e.line.quantity,
              price: e.unitPrice,
            ))
        .toList();

    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => PaymentWebViewScreen(
        paymentUrl: result.paymentPageUrl,
        orderNo: result.orderNo,
        items: snapshot,
        buyerName: _name.text.trim(),
        address: '$fullAddress, $_city',
      ),
    ));
    // Sepet, ödeme başarıyla doğrulandığında sonuç ekranında temizlenir.
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final summary = context.watch<CartProvider>().summary(context.watch<CatalogProvider>());
    if (auth.isLoggedIn && !_prefilled) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(_prefill);
      });
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Ödeme')),
      body: summary.isEmpty
          ? const EmptyState(icon: Icons.shopping_cart_outlined, title: 'Sepetiniz boş', message: 'Ödeme için sepete ürün ekleyin.')
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (!auth.isLoggedIn)
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.person_outline, color: AppColors.blue),
                        title: const Text('Üye girişi yapın', style: TextStyle(fontWeight: FontWeight.w700)),
                        subtitle: const Text('Adreslerinizi kaydedin, siparişlerinizi kolayca takip edin. '
                            'Dilerseniz üye olmadan da devam edebilirsiniz.'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AuthScreen())),
                      ),
                    ),
                  if (auth.addresses.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    const Text('Kayıtlı adreslerim', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 92,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: auth.addresses.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (context, i) {
                          final a = auth.addresses[i];
                          final selected = a.id == _addressId;
                          return InkWell(
                            onTap: () => _useAddress(a),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              width: 210,
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: selected ? AppColors.green : AppColors.border, width: selected ? 2 : 1),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(a.title, style: const TextStyle(fontWeight: FontWeight.w800)),
                                  const SizedBox(height: 2),
                                  Text('${a.addressLine} ${a.district}/${a.city}',
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  const Text('Teslimat bilgileri', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _name,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(labelText: 'Ad Soyad'),
                    onChanged: (_) => _addressId = null,
                    validator: (v) => (v ?? '').trim().length < 3 ? 'Ad soyad girin.' : null,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _phone,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(labelText: 'Cep telefonu', hintText: '05xx xxx xx xx'),
                    onChanged: (_) => _addressId = null,
                    validator: (v) =>
                        (v ?? '').replaceAll(RegExp(r'\D'), '').length < 10 ? 'Geçerli bir telefon numarası girin.' : null,
                  ),
                  if (!auth.isLoggedIn) ...[
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(labelText: 'E-posta (sipariş bilgilendirmesi için)'),
                      validator: (v) {
                        final value = (v ?? '').trim();
                        if (value.isEmpty) return null;
                        return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value) ? null : 'Geçerli bir e-posta girin.';
                      },
                    ),
                  ],
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    key: ValueKey(_city),
                    value: _city,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'İl'),
                    items: [for (final c in trCities) DropdownMenuItem(value: c, child: Text(c))],
                    onChanged: (v) => setState(() {
                      _city = v;
                      _addressId = null;
                    }),
                    validator: (v) => v == null ? 'İl seçin.' : null,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _district,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(labelText: 'İlçe'),
                    onChanged: (_) => _addressId = null,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _address,
                    minLines: 2,
                    maxLines: 4,
                    decoration: const InputDecoration(labelText: 'Açık adres', alignLabelWithHint: true),
                    onChanged: (_) => _addressId = null,
                    validator: (v) => (v ?? '').trim().length < 10 ? 'Açık adres girin (en az 10 karakter).' : null,
                  ),
                  if (auth.isLoggedIn && _addressId == null)
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      value: _saveAddress,
                      onChanged: (v) => setState(() => _saveAddress = v ?? false),
                      title: const Text('Bu adresi hesabıma kaydet'),
                    ),
                  const SizedBox(height: 16),
                  const Text('Sipariş özeti', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                  const SizedBox(height: 10),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        children: [
                          for (final e in summary.entries)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Text('${e.line.quantity} × ${e.product.name}',
                                        maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13)),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(formatPrice(e.lineTotal), style: const TextStyle(fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                          const Divider(),
                          const SizedBox(height: 8),
                          _line('Ara toplam', formatPrice(summary.subtotal)),
                          _line('Kargo', summary.shipping == 0 ? 'Ücretsiz' : formatPrice(summary.shipping)),
                          const SizedBox(height: 4),
                          _line('Ödenecek tutar', formatPrice(summary.total), bold: true),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    value: _accepted,
                    onChanged: (v) => setState(() => _accepted = v ?? false),
                    title: Wrap(children: [
                      const Text('Ön bilgilendirme formunu ve mesafeli satış sözleşmesini okudum, onaylıyorum. '),
                      GestureDetector(
                        onTap: () => openExternal(context, '/gizlilik-politikasi', title: 'Gizlilik Politikası'),
                        child: const Text('Gizlilik politikası',
                            style: TextStyle(color: AppColors.blue, decoration: TextDecoration.underline)),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 8),
                  const Row(children: [
                    Icon(Icons.lock_outline, size: 18, color: AppColors.green),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Kart bilgileriniz uygulamada saklanmaz. Ödeme, iyzico\'nun 3D Secure korumalı sayfasında yapılır.',
                        style: TextStyle(fontSize: 12.5, color: AppColors.muted),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 90),
                ],
              ),
            ),
      bottomNavigationBar: summary.isEmpty
          ? null
          : SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
                child: FilledButton.icon(
                  onPressed: _processing ? null : () => _submit(summary),
                  icon: _processing
                      ? const SizedBox(
                          width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.lock),
                  label: Text(_processing ? 'Ödeme hazırlanıyor…' : 'Güvenli Ödeme · ${formatPrice(summary.total)}'),
                ),
              ),
            ),
    );
  }

  Widget _line(String label, String value, {bool bold = false}) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(children: [
          Expanded(
              child: Text(label,
                  style: TextStyle(color: bold ? AppColors.navy : AppColors.muted, fontWeight: bold ? FontWeight.w800 : FontWeight.w500))),
          Text(value, style: TextStyle(fontWeight: FontWeight.w800, fontSize: bold ? 17 : 14, color: AppColors.navy)),
        ]),
      );
}
