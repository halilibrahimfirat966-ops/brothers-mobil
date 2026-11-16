import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/auth_provider.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// Giriş / Üye ol / Şifremi unuttum. Site ile aynı hesaplar kullanılır.
class AuthScreen extends StatefulWidget {
  final bool startWithRegister;
  const AuthScreen({super.key, this.startWithRegister = false});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  late bool _register = widget.startWithRegister;
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  bool _obscure = true;
  bool _accepted = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_register && !_accepted) {
      showMessage(context, 'Üyelik için gizlilik politikasını onaylayın.', error: true);
      return;
    }
    setState(() => _busy = true);
    final auth = context.read<AuthProvider>();
    final message = _register
        ? await auth.signUp(fullName: _name.text, email: _email.text, password: _password.text)
        : await auth.signIn(_email.text, _password.text);
    if (!mounted) return;
    setState(() => _busy = false);
    if (auth.isLoggedIn) {
      showMessage(context, _register ? 'Hoş geldiniz! Hesabınız oluşturuldu.' : 'Giriş yapıldı.');
      Navigator.of(context).pop();
      return;
    }
    if (message != null) showMessage(context, message, error: !message.startsWith('Kayıt alındı'));
  }

  Future<void> _forgot() async {
    final email = _email.text.trim();
    if (!email.contains('@')) {
      showMessage(context, 'Önce e-posta adresinizi yazın.', error: true);
      return;
    }
    setState(() => _busy = true);
    final error = await context.read<AuthProvider>().resetPassword(email);
    if (!mounted) return;
    setState(() => _busy = false);
    showMessage(context, error ?? 'Şifre yenileme bağlantısı $email adresine gönderildi.', error: error != null);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_register ? 'Üye Ol' : 'Giriş Yap')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const Center(child: BrandLogo(size: 56, showText: false)),
            const SizedBox(height: 14),
            Text(
              _register ? 'Brothers Teknoloji\'ye üye olun' : 'Hesabınıza giriş yapın',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.navy),
            ),
            const SizedBox(height: 6),
            const Text(
              'brothersteknoloji.com hesabınızla aynıdır.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.muted),
            ),
            const SizedBox(height: 24),
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: false, label: Text('Giriş Yap')),
                ButtonSegment(value: true, label: Text('Üye Ol')),
              ],
              selected: {_register},
              onSelectionChanged: (s) => setState(() => _register = s.first),
            ),
            const SizedBox(height: 20),
            if (_register) ...[
              TextFormField(
                controller: _name,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Ad Soyad', prefixIcon: Icon(Icons.person_outline)),
                validator: (v) => (v ?? '').trim().length < 3 ? 'Ad soyad girin.' : null,
              ),
              const SizedBox(height: 12),
            ],
            TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              decoration: const InputDecoration(labelText: 'E-posta', prefixIcon: Icon(Icons.mail_outline)),
              validator: (v) =>
                  RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch((v ?? '').trim()) ? null : 'Geçerli bir e-posta girin.',
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _password,
              obscureText: _obscure,
              autofillHints: [_register ? AutofillHints.newPassword : AutofillHints.password],
              decoration: InputDecoration(
                labelText: 'Şifre',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
              validator: (v) {
                final value = v ?? '';
                if (_register && value.length < 8) return 'Şifre en az 8 karakter olmalı.';
                if (value.isEmpty) return 'Şifrenizi girin.';
                return null;
              },
              onFieldSubmitted: (_) => _submit(),
            ),
            if (!_register)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(onPressed: _busy ? null : _forgot, child: const Text('Şifremi unuttum')),
              ),
            if (_register)
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                value: _accepted,
                onChanged: (v) => setState(() => _accepted = v ?? false),
                title: GestureDetector(
                  onTap: () => openExternal(context, '/gizlilik-politikasi'),
                  child: const Text.rich(TextSpan(children: [
                    TextSpan(
                        text: 'Gizlilik politikasını',
                        style: TextStyle(color: AppColors.blue, decoration: TextDecoration.underline)),
                    TextSpan(text: ' okudum ve kabul ediyorum.'),
                  ])),
                ),
              ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _busy ? null : _submit,
              child: _busy
                  ? const SizedBox(
                      width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(_register ? 'Üye Ol' : 'Giriş Yap'),
            ),
          ],
        ),
      ),
    );
  }
}
