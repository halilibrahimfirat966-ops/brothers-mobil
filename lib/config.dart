/// Uygulama genel ayarları.
/// Supabase anahtarı sitenin .env dosyasındaki herkese açık (anon) istemci anahtarıdır;
/// web sitesi de aynı anahtarı tarayıcıya gönderir. Gizli servis anahtarı burada YOKTUR.
class AppConfig {
  AppConfig._();

  static const String appName = 'Brothers Teknoloji';
  static const String siteUrl = 'https://brothersteknoloji.com';

  /// Sitenin public/ klasöründen yayınlanan katalog dosyası.
  static const String catalogUrl = '$siteUrl/app-catalog.json';

  static const String supabaseUrl = 'https://rnadorzfjhqjtbiepvfo.supabase.co';
  static const String supabaseAnonKey = 'sb_publishable_MtzWxNVzxsrkKlbL0cnt4g_WSxrEOOw';

  static const String logoUrl =
      'https://public.readdy.ai/ai/img_res/edited_02064cb7465cc4c3d736643c25eca29b_1ffb1d29.jpg';

  /// Kargo kuralları (sitedeki varsayılan ayarlarla aynı).
  static const double shippingFee = 49.90;
  static const bool freeShippingEnabled = true;
  static const double freeShippingThreshold = 500;

  /// Giriş yapmadan alışveriş yapan müşteriler için sitenin kullandığı e-posta.
  static const String guestEmail = 'misafir.musteri@brothersteknoloji.com';
}
