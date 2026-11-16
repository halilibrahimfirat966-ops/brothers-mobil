import 'package:supabase_flutter/supabase_flutter.dart';

class SocialLink {
  final String platform;
  final String url;
  const SocialLink(this.platform, this.url);
}

class ContactInfo {
  final String phone;
  final String email;
  final String address;
  final List<SocialLink> socials;
  const ContactInfo({this.phone = '', this.email = '', this.address = '', this.socials = const []});
  bool get isEmpty => phone.isEmpty && email.isEmpty && address.isEmpty;
}

/// Sitenin "Footer & İletişim" ayarlarını (site-settings fonksiyonu) okur.
class SettingsService {
  Future<ContactInfo?> fetchContact() async {
    try {
      final response =
          await Supabase.instance.client.functions.invoke('site-settings', body: {'action': 'read'});
      final data = response.data;
      if (data is! Map || data['ok'] != true || data['settings'] is! Map) return null;
      final s = Map<String, dynamic>.from(data['settings'] as Map);
      final socials = (s['socials'] as List? ?? const [])
          .whereType<Map>()
          .map((e) => SocialLink('${e['platform'] ?? ''}', '${e['url'] ?? ''}'))
          .where((e) => e.url.trim().isNotEmpty)
          .toList();
      return ContactInfo(
        phone: '${s['phone'] ?? ''}',
        email: '${s['email'] ?? ''}',
        address: '${s['address'] ?? ''}',
        socials: socials,
      );
    } catch (_) {
      return null;
    }
  }
}
