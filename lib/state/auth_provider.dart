import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config.dart';
import '../models/order.dart';

/// Sitenin kullandığı Supabase Auth + "profiles" / "addresses" tabloları.
class AuthProvider extends ChangeNotifier {
  SupabaseClient get _client => Supabase.instance.client;
  StreamSubscription<AuthState>? _sub;

  Session? _session;
  Map<String, dynamic>? _profile;
  List<SavedAddress> _addresses = [];

  User? get user => _session?.user;
  bool get isLoggedIn => _session != null;
  String get email => user?.email ?? '';
  String get fullName => '${_profile?['full_name'] ?? user?.userMetadata?['full_name'] ?? ''}'.trim();
  String get phone => '${_profile?['phone'] ?? ''}'.trim();
  List<SavedAddress> get addresses => List.unmodifiable(_addresses);

  SavedAddress? get defaultAddress {
    if (_addresses.isEmpty) return null;
    return _addresses.firstWhere((a) => a.isDefault, orElse: () => _addresses.first);
  }

  void init() {
    _session = _client.auth.currentSession;
    if (_session != null) _loadUserData();
    _sub = _client.auth.onAuthStateChange.listen((state) {
      _session = state.session;
      if (_session == null) {
        _profile = null;
        _addresses = [];
      } else {
        _loadUserData();
      }
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    await Future.wait([_loadProfile(), loadAddresses()]);
  }

  Future<void> _loadProfile() async {
    final current = user;
    if (current == null) return;
    try {
      final row = await _client.from('profiles').select().eq('id', current.id).maybeSingle();
      if (row != null) {
        _profile = row;
      } else {
        final meta = current.userMetadata ?? {};
        _profile = await _client
            .from('profiles')
            .insert({
              'id': current.id,
              'email': current.email,
              'full_name': meta['full_name'] ?? meta['name'],
              'phone': current.phone,
            })
            .select()
            .maybeSingle();
      }
      notifyListeners();
    } catch (_) {
      // Profil okunamazsa oturum yine de çalışır.
    }
  }

  Future<void> loadAddresses() async {
    final current = user;
    if (current == null) return;
    try {
      final rows = await _client
          .from('addresses')
          .select()
          .eq('user_id', current.id)
          .order('is_default', ascending: false)
          .order('created_at', ascending: false);
      _addresses = (rows as List).map((e) => SavedAddress.fromJson(Map<String, dynamic>.from(e as Map))).toList();
      notifyListeners();
    } catch (_) {}
  }

  /// Hata varsa kullanıcıya gösterilecek mesajı döndürür, başarılıysa null.
  Future<String?> signIn(String email, String password) async {
    try {
      await _client.auth.signInWithPassword(email: email.trim(), password: password);
      return null;
    } on AuthException catch (e) {
      return _authMessage(e);
    } catch (_) {
      return 'Bağlantı hatası. Lütfen tekrar deneyin.';
    }
  }

  Future<String?> signUp({required String fullName, required String email, required String password}) async {
    try {
      final res = await _client.auth.signUp(
        email: email.trim(),
        password: password,
        data: {'full_name': fullName.trim()},
        emailRedirectTo: '${AppConfig.siteUrl}/auth/callback',
      );
      if (res.session == null) {
        return 'Kayıt alındı. E-posta adresinize gelen bağlantıyla hesabınızı doğrulayıp giriş yapabilirsiniz.';
      }
      return null;
    } on AuthException catch (e) {
      return _authMessage(e);
    } catch (_) {
      return 'Bağlantı hatası. Lütfen tekrar deneyin.';
    }
  }

  Future<String?> resetPassword(String email) async {
    try {
      await _client.auth.resetPasswordForEmail(email.trim(), redirectTo: '${AppConfig.siteUrl}/auth/callback');
      return null;
    } on AuthException catch (e) {
      return _authMessage(e);
    } catch (_) {
      return 'Bağlantı hatası. Lütfen tekrar deneyin.';
    }
  }

  Future<void> signOut() => _client.auth.signOut();

  Future<String?> updateProfile({required String fullName, required String phone}) async {
    final current = user;
    if (current == null) return 'Oturum bulunamadı.';
    try {
      final row = await _client
          .from('profiles')
          .update({'full_name': fullName.trim(), 'phone': phone.trim(), 'updated_at': DateTime.now().toIso8601String()})
          .eq('id', current.id)
          .select()
          .maybeSingle();
      if (row != null) _profile = row;
      notifyListeners();
      return null;
    } catch (_) {
      return 'Profil kaydedilemedi.';
    }
  }

  Future<String?> addAddress({
    required String title,
    required String fullName,
    required String phone,
    required String city,
    required String district,
    required String addressLine,
    bool makeDefault = false,
  }) async {
    final current = user;
    if (current == null) return 'Oturum bulunamadı.';
    try {
      final isDefault = makeDefault || _addresses.isEmpty;
      if (isDefault && _addresses.isNotEmpty) {
        await _client.from('addresses').update({'is_default': false}).eq('user_id', current.id);
      }
      await _client.from('addresses').insert({
        'user_id': current.id,
        'title': title.trim().isEmpty ? 'Adresim' : title.trim(),
        'full_name': fullName.trim(),
        'phone': phone.trim(),
        'city': city,
        'district': district.trim(),
        'address_line': addressLine.trim(),
        'is_default': isDefault,
      });
      await loadAddresses();
      return null;
    } catch (_) {
      return 'Adres kaydedilemedi.';
    }
  }

  Future<void> deleteAddress(String id) async {
    final current = user;
    if (current == null) return;
    try {
      await _client.from('addresses').delete().eq('id', id).eq('user_id', current.id);
      await loadAddresses();
    } catch (_) {}
  }

  String _authMessage(AuthException e) {
    final m = e.message.toLowerCase();
    if (m.contains('invalid login')) return 'E-posta veya şifre hatalı.';
    if (m.contains('email not confirmed')) return 'E-posta adresiniz henüz doğrulanmamış. Gelen kutunuzu kontrol edin.';
    if (m.contains('already registered') || m.contains('already been registered')) {
      return 'Bu e-posta ile kayıtlı bir hesap var. Giriş yapmayı deneyin.';
    }
    if (m.contains('password') && m.contains('6')) return 'Şifre en az 6 karakter olmalı.';
    if (m.contains('rate limit') || m.contains('too many')) return 'Çok fazla deneme yapıldı. Biraz sonra tekrar deneyin.';
    return e.message;
  }
}
