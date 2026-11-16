# Brothers Teknoloji Mobil Uygulaması (Android + iOS)

Flutter ile yazılmış, brothersteknoloji.com ile **aynı altyapıyı** kullanan yerel mobil uygulama:

| Özellik | Kaynak |
|---|---|
| Ürünler, kategoriler, vitrin | Sitenin katalog dosyaları → `https://brothersteknoloji.com/app-catalog.json` |
| Üyelik, giriş, şifre sıfırlama | Sitenin Supabase Auth'u (site hesaplarıyla aynı) |
| Profil ve kayıtlı adresler | Supabase `profiles` ve `addresses` tabloları |
| Ödeme | Sitenin `iyzico-init` / `iyzico-verify` fonksiyonları, iyzico'nun 3D Secure ödeme sayfası |
| İletişim bilgileri | Sitenin `site-settings` fonksiyonu (Footer & İletişim ayarları) |

Ekranlar: Ana sayfa (kampanya slaytı, kategoriler, öne çıkanlar, indirimliler, yeni gelenler), kategori ağacı,
ürün listesi (sıralama + marka/fiyat/stok filtresi), arama (Türkçe karakter duyarsız, geçmişli), ürün detayı
(özellikler, benzer ürünler, varyant desteği), sepet, ödeme, iyzico ödeme sayfası, sonuç ekranı, favoriler,
giriş/üye ol, siparişlerim, adreslerim, kullanıcı bilgilerim, iletişim (telefon/WhatsApp/e-posta).

---

## 1. Katalog dosyasını siteye ekleyin (bir kez + her ürün değişikliğinde)

Sitede ürünler kodun içindeki dosyalarda (`src/mocks/catalog*.ts`) duruyor; veritabanında değil.
Uygulamanın güncel ürünleri görebilmesi için bu listeyi siteyle birlikte JSON olarak yayınlamanız gerekir.

Site klasöründe (Node 22.6 veya üzeri gerekir):

```
node --import ./scripts/app-catalog/register.mjs --experimental-strip-types scripts/app-catalog/export.ts
```

Bu komut `public/app-catalog.json` dosyasını üretir (fiyat zam kuralı uygulanmış, sitedekiyle aynı fiyatlar).
Siteyi her zamanki gibi derleyip yayınladığınızda dosya `https://brothersteknoloji.com/app-catalog.json`
adresinde açılır. Tarayıcıda bu adresi açıp JSON göründüğünü kontrol edin.

Kalıcı çözüm için `package.json` içindeki build betiğini şöyle yapabilirsiniz:
`"build": "node --import ./scripts/app-catalog/register.mjs --experimental-strip-types scripts/app-catalog/export.ts && vite build"`

> Dosya yayınlanmamışsa uygulama çalışmaya devam eder: içine gömülü katalog kopyasını kullanır
> (bugünkü 331 ürün). Ama fiyat/stok güncellemeleri ancak bu dosya yayınlanınca uygulamaya yansır.

## 2. Uygulamayı kurun ve çalıştırın

Gerekenler: [Flutter SDK](https://docs.flutter.dev/get-started/install/windows) ve Android Studio (Android SDK + emülatör).

```
cd mobil-uygulama
powershell -ExecutionPolicy Bypass -File .\kurulum.ps1
flutter run
```

`kurulum.ps1`: Android/iOS proje dosyalarını oluşturur, internet izni + uygulama adını ayarlar,
paketleri indirir ve sitedeki logodan uygulama simgesini üretir.

## 3. Mağazaya yükleme

**Android (Google Play):**
1. İmza anahtarı oluşturun:
   `keytool -genkey -v -keystore android\app\upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload`
2. `android/key.properties` dosyası oluşturun ve `android/app/build.gradle(.kts)` içinde release imzasını tanımlayın
   (adımlar: https://docs.flutter.dev/deployment/android#sign-the-app).
3. `flutter build appbundle` → `build/app/outputs/bundle/release/app-release.aab` dosyasını Play Console'a yükleyin.
   Test için doğrudan APK: `flutter build apk --release`.

**iOS (App Store):** Mac bilgisayar + Xcode + Apple Developer hesabı (yıllık ücretli) gerekir.
Mac'te `flutter build ipa` ile paketleyip Transporter/Xcode ile yükleyin.

## 4. Yayından önce mutlaka test edin

- **Gerçek bir ödeme deneyin** (küçük tutarlı bir ürünle). iyzico ödeme sayfası uygulama içinde açılır; ödeme
  bitince iyzico'nun sitenin `/odeme-sonuc?order=...` adresine yönlendirmesi yakalanır ve sonuç doğrulanır.
  `iyzico-init` ve `iyzico-verify` fonksiyonları sitenin Supabase projesinde yayında olmalı
  (bilgisayarınızdaki `supabase/functions` klasöründe yoklar; site bunları kullandığı için yayında oldukları varsayılmıştır).
- Üye olma ve giriş: site ile aynı hesaplar. Supabase'de e-posta doğrulaması açıksa kullanıcı önce e-postasını onaylamalı.

## Bilinen sınırlar (sitenin yapısından gelen)

- **Yönetim panelinden yapılan ürün/fiyat/stok değişiklikleri** sitede yalnızca yöneticinin tarayıcısında saklanıyor
  (localStorage). Bu yüzden ne site ziyaretçilerine ne de uygulamaya ulaşır. Gerçek zamanlı yönetim için ürünlerin
  bir Supabase tablosuna taşınması önerilir; o zaman uygulama `catalog_service.dart` içinden doğrudan o tabloyu okuyabilir.
- **Siparişlerim** ekranı bu cihazdan verilen siparişleri gösterir (site de müşteri siparişlerini tarayıcıda tutuyor).
  Sipariş durumu (Kargoda vb.) için "Kargo takibi" sitedeki sayfayı açar.
- **Kupon kodları** uygulamada yok: sitedeki kampanyalar da yöneticinin tarayıcısında tutuluyor.
- Ödeme tek çekim olarak başlatılır.

## Dosya yapısı

```
lib/
  config.dart              Site adresi, Supabase adresi/anahtarı, kargo kuralları
  theme.dart               Renkler ve tema (sitedeki lacivert/yeşil/mavi)
  models/                  Ürün, kategori, sipariş, adres modelleri
  services/                Katalog indirme, iyzico ödeme, site ayarları
  state/                   Katalog, sepet, favoriler, oturum, siparişler (Provider)
  screens/                 Tüm ekranlar
  widgets/                 Ürün kartı, fiyat, ortak bileşenler
assets/catalog.json        Gömülü yedek katalog
```

`config.dart` içindeki Supabase anahtarı sitenin de tarayıcıya gönderdiği herkese açık "anon" anahtardır.
Gizli servis anahtarı uygulamada yoktur ve olmamalıdır.
