# Brothers Teknoloji mobil uygulaması - ilk kurulum (Windows PowerShell)
# Kullanım: bu klasörde sağ tık > "PowerShell'de çalıştır" ya da:
#   powershell -ExecutionPolicy Bypass -File .\kurulum.ps1
$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot

if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
  Write-Host "Flutter bulunamadı. https://docs.flutter.dev/get-started/install/windows adresinden kurun ve tekrar deneyin." -ForegroundColor Red
  exit 1
}

Write-Host "1/5 Android ve iOS proje dosyaları oluşturuluyor..." -ForegroundColor Cyan
flutter create . --org com.brothersteknoloji --project-name brothers_teknoloji --platforms android,ios
if (Test-Path "test\widget_test.dart") { Remove-Item "test\widget_test.dart" }

# Mağaza paket adı (Google Play'deki kayıtla aynı olmalı)
$appId = "com.brothersteknoloji.app"
foreach ($gradleFile in @("android\app\build.gradle.kts", "android\app\build.gradle")) {
  if (Test-Path $gradleFile) {
    $gt = Get-Content $gradleFile -Raw -Encoding UTF8
    $gt = [regex]::Replace($gt, 'applicationId\s*=?\s*"[^"]+"', "applicationId = `"$appId`"")
    if ($gradleFile.EndsWith(".gradle")) { $gt = $gt.Replace("applicationId = `"$appId`"", "applicationId `"$appId`"") }
    [System.IO.File]::WriteAllText((Resolve-Path $gradleFile), $gt, (New-Object System.Text.UTF8Encoding $false))
    if ($gt -notmatch [regex]::Escape($appId)) { throw "Paket adı ayarlanamadı: $gradleFile" }
  }
}
$pbx = "ios\Runner.xcodeproj\project.pbxproj"
if (Test-Path $pbx) {
  $pt = (Get-Content $pbx -Raw -Encoding UTF8).Replace("com.brothersteknoloji.brothersTeknoloji", $appId)
  [System.IO.File]::WriteAllText((Resolve-Path $pbx), $pt, (New-Object System.Text.UTF8Encoding $false))
}
Write-Host "Paket adı: $appId" -ForegroundColor Green

Write-Host "2/5 Android izinleri ve uygulama adı ayarlanıyor..." -ForegroundColor Cyan
$manifestPath = "android\app\src\main\AndroidManifest.xml"
$manifest = Get-Content $manifestPath -Raw -Encoding UTF8
if ($manifest -notmatch "android.permission.INTERNET") {
  $manifest = $manifest -replace '(<manifest[^>]*>)', "`$1`r`n    <uses-permission android:name=`"android.permission.INTERNET`" />"
}
$manifest = $manifest -replace 'android:label="[^"]*"', 'android:label="Brothers Teknoloji"'
if ($manifest -notmatch 'android:scheme="tel"') {
  $queries = @"
    <queries>
        <intent><action android:name="android.intent.action.VIEW" /><data android:scheme="https" /></intent>
        <intent><action android:name="android.intent.action.DIAL" /><data android:scheme="tel" /></intent>
        <intent><action android:name="android.intent.action.SENDTO" /><data android:scheme="mailto" /></intent>
"@
  if ($manifest -match '<queries>') {
    $manifest = $manifest -replace '<queries>', $queries
  } else {
    $manifest = $manifest -replace '</manifest>', "$queries`r`n    </queries>`r`n</manifest>"
  }
}
[System.IO.File]::WriteAllText((Resolve-Path $manifestPath), $manifest, (New-Object System.Text.UTF8Encoding $false))

Write-Host "3/5 iOS ayarları yapılıyor..." -ForegroundColor Cyan
$plistPath = "ios\Runner\Info.plist"
if (Test-Path $plistPath) {
  $plist = Get-Content $plistPath -Raw -Encoding UTF8
  $plist = $plist -replace '(<key>CFBundleDisplayName</key>\s*<string>)[^<]*(</string>)', '$1Brothers Teknoloji$2'
  if ($plist -notmatch 'LSApplicationQueriesSchemes') {
    $extra = "`t<key>LSApplicationQueriesSchemes</key>`n`t<array>`n`t`t<string>https</string>`n`t`t<string>tel</string>`n`t`t<string>mailto</string>`n`t</array>`n"
    $index = $plist.LastIndexOf("</dict>")
    $plist = $plist.Insert($index, $extra)
  }
  [System.IO.File]::WriteAllText((Resolve-Path $plistPath), $plist, (New-Object System.Text.UTF8Encoding $false))
}

Write-Host "Logo indiriliyor (açılış ekranı için)..." -ForegroundColor Cyan
try {
  Invoke-WebRequest -Uri "https://public.readdy.ai/ai/img_res/edited_02064cb7465cc4c3d736643c25eca29b_1ffb1d29.jpg" -OutFile "assets\logo.jpg"
} catch {
  Write-Host "Logo indirilemedi; açılış ekranı logoyu internetten yükleyecek." -ForegroundColor Yellow
}

Write-Host "4/5 Paketler indiriliyor..." -ForegroundColor Cyan
flutter pub get

Write-Host "5/5 Uygulama simgesi logodan üretiliyor..." -ForegroundColor Cyan
try {
  Invoke-WebRequest -Uri "https://public.readdy.ai/ai/img_res/edited_02064cb7465cc4c3d736643c25eca29b_1ffb1d29.jpg" -OutFile "assets\icon_source.jpg"
  Add-Type -AssemblyName System.Drawing
  $img = [System.Drawing.Image]::FromFile((Resolve-Path "assets\icon_source.jpg"))
  $size = 1024
  $bmp = New-Object System.Drawing.Bitmap $size, $size
  $g = [System.Drawing.Graphics]::FromImage($bmp)
  $g.Clear([System.Drawing.Color]::White)
  $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
  $side = [Math]::Min($img.Width, $img.Height)
  $src = New-Object System.Drawing.Rectangle ([int](($img.Width - $side) / 2)), ([int](($img.Height - $side) / 2)), $side, $side
  $pad = 120
  $dst = New-Object System.Drawing.Rectangle $pad, $pad, ($size - 2 * $pad), ($size - 2 * $pad)
  $g.DrawImage($img, $dst, $src, [System.Drawing.GraphicsUnit]::Pixel)
  $bmp.Save((Join-Path $PWD "assets\icon.png"), [System.Drawing.Imaging.ImageFormat]::Png)
  $g.Dispose(); $bmp.Dispose(); $img.Dispose()
  Remove-Item "assets\icon_source.jpg"
  dart run flutter_launcher_icons
} catch {
  Write-Host "Simge üretilemedi (isteğe bağlı adım): $_" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Kurulum tamam. Telefonu USB ile bağlayıp (ya da emülatör açıp) şunu çalıştırın:" -ForegroundColor Green
Write-Host "  flutter run" -ForegroundColor Green
