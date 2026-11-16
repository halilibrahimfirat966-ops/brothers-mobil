import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/order.dart';
import '../services/settings_service.dart';
import '../state/auth_provider.dart';
import '../state/orders_provider.dart';
import '../theme.dart';
import '../utils/format.dart';
import '../utils/tr_cities.dart';
import '../widgets/common.dart';

// ---------------------------------------------------------------- Siparişlerim
class OrdersPage extends StatelessWidget {
  const OrdersPage({super.key});

  @override
  Widget build(BuildContext context) {
    final orders = context.watch<OrdersProvider>().orders;
    return Scaffold(
      appBar: AppBar(title: const Text('Siparişlerim')),
      body: orders.isEmpty
          ? const EmptyState(
              icon: Icons.receipt_long_outlined,
              title: 'Henüz siparişiniz yok',
              message: 'Bu cihazdan verdiğiniz siparişler burada listelenir.',
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: orders.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) => _OrderCard(order: orders[i]),
            ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final PlacedOrder order;
  const _OrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ExpansionTile(
        shape: const Border(),
        tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        title: Text('#${order.orderNo.toUpperCase()}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
        subtitle: Text('${formatDateTime(order.createdAt)} · ${formatPrice(order.amount)}'),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(color: AppColors.greenSoft, borderRadius: BorderRadius.circular(8)),
          child: Text(order.status,
              style: const TextStyle(color: AppColors.green, fontWeight: FontWeight.w700, fontSize: 12)),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
        children: [
          for (final item in order.items)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(children: [
                SizedBox(width: 48, height: 48, child: NetImage(item.image, fit: BoxFit.contain)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text('${item.quantity} × ${item.name}',
                      maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13)),
                ),
                Text(formatPrice(item.price * item.quantity), style: const TextStyle(fontWeight: FontWeight.w600)),
              ]),
            ),
          if (order.address.isNotEmpty)
            Align(
              alignment: Alignment.centerLeft,
              child: Text('Teslimat: ${order.address}', style: const TextStyle(color: AppColors.muted, fontSize: 12.5)),
            ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => openExternal(context, '/kargo-takip'),
              icon: const Icon(Icons.local_shipping_outlined),
              label: const Text('Kargo takibi'),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------- Adreslerim
class AddressesPage extends StatelessWidget {
  const AddressesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Adreslerim')),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.green,
        foregroundColor: Colors.white,
        onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AddressFormPage())),
        icon: const Icon(Icons.add),
        label: const Text('Yeni adres'),
      ),
      body: RefreshIndicator(
        onRefresh: auth.loadAddresses,
        child: auth.addresses.isEmpty
            ? ListView(children: const [
                SizedBox(height: 80),
                EmptyState(
                  icon: Icons.location_on_outlined,
                  title: 'Kayıtlı adresiniz yok',
                  message: 'Adres ekleyerek ödeme adımını hızlandırabilirsiniz.',
                ),
              ])
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                itemCount: auth.addresses.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, i) {
                  final a = auth.addresses[i];
                  return Card(
                    child: ListTile(
                      contentPadding: const EdgeInsets.fromLTRB(14, 8, 4, 8),
                      title: Row(children: [
                        Flexible(child: Text(a.title, style: const TextStyle(fontWeight: FontWeight.w800))),
                        if (a.isDefault) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration:
                                BoxDecoration(color: AppColors.greenSoft, borderRadius: BorderRadius.circular(6)),
                            child: const Text('Varsayılan',
                                style: TextStyle(fontSize: 11, color: AppColors.green, fontWeight: FontWeight.w700)),
                          ),
                        ],
                      ]),
                      subtitle: Text('${a.fullName} · ${a.phone}\n${a.addressLine}\n${a.district} / ${a.city}',
                          style: const TextStyle(height: 1.4)),
                      isThreeLine: true,
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline, color: AppColors.danger),
                        onPressed: () async {
                          final ok = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Adresi sil'),
                              content: Text('"${a.title}" silinsin mi?'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Vazgeç')),
                                TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Sil')),
                              ],
                            ),
                          );
                          if (ok == true && context.mounted) await context.read<AuthProvider>().deleteAddress(a.id);
                        },
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}

class AddressFormPage extends StatefulWidget {
  const AddressFormPage({super.key});

  @override
  State<AddressFormPage> createState() => _AddressFormPageState();
}

class _AddressFormPageState extends State<AddressFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController(text: 'Ev');
  late final _name = TextEditingController(text: context.read<AuthProvider>().fullName);
  late final _phone = TextEditingController(text: context.read<AuthProvider>().phone);
  final _district = TextEditingController();
  final _address = TextEditingController();
  String? _city;
  bool _default = false;
  bool _busy = false;

  @override
  void dispose() {
    for (final c in [_title, _name, _phone, _district, _address]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    final error = await context.read<AuthProvider>().addAddress(
          title: _title.text,
          fullName: _name.text,
          phone: _phone.text,
          city: _city!,
          district: _district.text,
          addressLine: _address.text,
          makeDefault: _default,
        );
    if (!mounted) return;
    setState(() => _busy = false);
    if (error != null) {
      showMessage(context, error, error: true);
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Yeni Adres')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(controller: _title, decoration: const InputDecoration(labelText: 'Adres başlığı (Ev, İş…)')),
            const SizedBox(height: 10),
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Ad Soyad'),
              validator: (v) => (v ?? '').trim().length < 3 ? 'Ad soyad girin.' : null,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Telefon'),
              validator: (v) => (v ?? '').replaceAll(RegExp(r'\D'), '').length < 10 ? 'Geçerli telefon girin.' : null,
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: _city,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'İl'),
              items: [for (final c in trCities) DropdownMenuItem(value: c, child: Text(c))],
              onChanged: (v) => setState(() => _city = v),
              validator: (v) => v == null ? 'İl seçin.' : null,
            ),
            const SizedBox(height: 10),
            TextFormField(controller: _district, decoration: const InputDecoration(labelText: 'İlçe')),
            const SizedBox(height: 10),
            TextFormField(
              controller: _address,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(labelText: 'Açık adres', alignLabelWithHint: true),
              validator: (v) => (v ?? '').trim().length < 10 ? 'Açık adres girin.' : null,
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Varsayılan adres yap'),
              value: _default,
              onChanged: (v) => setState(() => _default = v),
            ),
            const SizedBox(height: 12),
            FilledButton(onPressed: _busy ? null : _save, child: Text(_busy ? 'Kaydediliyor…' : 'Kaydet')),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------- Profil
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late final _name = TextEditingController(text: context.read<AuthProvider>().fullName);
  late final _phone = TextEditingController(text: context.read<AuthProvider>().phone);
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Kullanıcı Bilgilerim')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextFormField(
            enabled: false,
            initialValue: auth.email,
            decoration: const InputDecoration(labelText: 'E-posta'),
          ),
          const SizedBox(height: 10),
          TextField(controller: _name, decoration: const InputDecoration(labelText: 'Ad Soyad')),
          const SizedBox(height: 10),
          TextField(
            controller: _phone,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(labelText: 'Telefon'),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _busy
                ? null
                : () async {
                    setState(() => _busy = true);
                    final error = await auth.updateProfile(fullName: _name.text, phone: _phone.text);
                    if (!context.mounted) return;
                    setState(() => _busy = false);
                    showMessage(context, error ?? 'Bilgileriniz güncellendi.', error: error != null);
                  },
            child: Text(_busy ? 'Kaydediliyor…' : 'Kaydet'),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () async {
              final error = await auth.resetPassword(auth.email);
              if (context.mounted) {
                showMessage(context, error ?? 'Şifre değiştirme bağlantısı e-postanıza gönderildi.', error: error != null);
              }
            },
            child: const Text('Şifremi değiştir'),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------- İletişim
class ContactPage extends StatefulWidget {
  const ContactPage({super.key});

  @override
  State<ContactPage> createState() => _ContactPageState();
}

class _ContactPageState extends State<ContactPage> {
  ContactInfo? _info;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    SettingsService().fetchContact().then((info) {
      if (mounted) {
        setState(() {
          _info = info;
          _loading = false;
        });
      }
    });
  }

  String _whatsAppUrl(String phone) {
    var digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('0')) digits = '9$digits';
    if (digits.length == 10) digits = '90$digits';
    return 'https://wa.me/$digits';
  }

  @override
  Widget build(BuildContext context) {
    final info = _info;
    return Scaffold(
      appBar: AppBar(title: const Text('İletişim & Destek')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (info != null && !info.isEmpty)
                  Card(
                    clipBehavior: Clip.antiAlias,
                    child: Column(children: [
                      if (info.phone.isNotEmpty) ...[
                        ListTile(
                          leading: const Icon(Icons.phone_outlined, color: AppColors.navy),
                          title: const Text('Telefon'),
                          subtitle: Text(info.phone),
                          onTap: () => openExternal(context, 'tel:${info.phone.replaceAll(RegExp(r'[^\d+]'), '')}'),
                        ),
                        ListTile(
                          leading: const Icon(Icons.chat_outlined, color: AppColors.green),
                          title: const Text('WhatsApp'),
                          subtitle: const Text('Hızlı destek için yazın'),
                          onTap: () => openExternal(context, _whatsAppUrl(info.phone)),
                        ),
                      ],
                      if (info.email.isNotEmpty)
                        ListTile(
                          leading: const Icon(Icons.mail_outline, color: AppColors.navy),
                          title: const Text('E-posta'),
                          subtitle: Text(info.email),
                          onTap: () => openExternal(context, 'mailto:${info.email}'),
                        ),
                      if (info.address.isNotEmpty)
                        ListTile(
                          leading: const Icon(Icons.place_outlined, color: AppColors.navy),
                          title: const Text('Adres'),
                          subtitle: Text(info.address),
                          onTap: () => openExternal(
                              context, 'https://maps.google.com/?q=${Uri.encodeComponent(info.address)}'),
                        ),
                    ]),
                  ),
                if (info != null && info.socials.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Text('Sosyal medya', style: TextStyle(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  Wrap(spacing: 8, runSpacing: 8, children: [
                    for (final s in info.socials)
                      ActionChip(label: Text(_platformName(s.platform)), onPressed: () => openExternal(context, s.url)),
                  ]),
                ],
                const SizedBox(height: 16),
                Card(
                  clipBehavior: Clip.antiAlias,
                  child: Column(children: [
                    ListTile(
                      leading: const Icon(Icons.confirmation_number_outlined, color: AppColors.navy),
                      title: const Text('Destek talebi oluştur'),
                      trailing: const Icon(Icons.open_in_new, size: 18),
                      onTap: () => openExternal(context, '/destek'),
                    ),
                    ListTile(
                      leading: const Icon(Icons.contact_mail_outlined, color: AppColors.navy),
                      title: const Text('İletişim formu'),
                      trailing: const Icon(Icons.open_in_new, size: 18),
                      onTap: () => openExternal(context, '/iletisim'),
                    ),
                  ]),
                ),
              ],
            ),
    );
  }

  String _platformName(String id) {
    const names = {
      'instagram': 'Instagram',
      'facebook': 'Facebook',
      'x': 'X (Twitter)',
      'twitter': 'X (Twitter)',
      'linkedin': 'LinkedIn',
      'youtube': 'YouTube',
      'tiktok': 'TikTok',
      'whatsapp': 'WhatsApp',
    };
    return names[id] ?? id;
  }
}
