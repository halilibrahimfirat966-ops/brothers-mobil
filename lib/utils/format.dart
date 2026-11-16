/// Türkçe fiyat biçimi: 12.345,67 ₺
String formatPrice(num value) {
  final negative = value < 0;
  final cents = (value.abs() * 100).round();
  final whole = cents ~/ 100;
  final fraction = (cents % 100).toString().padLeft(2, '0');
  final digits = whole.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write('.');
    buffer.write(digits[i]);
  }
  return '${negative ? '-' : ''}$buffer,$fraction ₺';
}

String formatDateTime(DateTime date) {
  String two(int v) => v.toString().padLeft(2, '0');
  final d = date.toLocal();
  return '${two(d.day)}.${two(d.month)}.${d.year} ${two(d.hour)}:${two(d.minute)}';
}

/// Arama için Türkçe karakterleri sadeleştirir (İ/ı/ş/ğ/ü/ö/ç).
String normalizeTr(String input) {
  final lower = input.replaceAll('İ', 'i').replaceAll('I', 'ı').toLowerCase();
  const map = {'ı': 'i', 'ş': 's', 'ğ': 'g', 'ü': 'u', 'ö': 'o', 'ç': 'c', 'â': 'a', 'î': 'i', 'û': 'u'};
  final buffer = StringBuffer();
  for (final rune in lower.runes) {
    final ch = String.fromCharCode(rune);
    buffer.write(map[ch] ?? ch);
  }
  return buffer.toString();
}

/// Türkçe alfabetik karşılaştırma için anahtar.
String trSortKey(String input) {
  const order = 'abcçdefgğhıijklmnoöprsştuüvyz';
  final lower = input.replaceAll('İ', 'i').replaceAll('I', 'ı').toLowerCase();
  final buffer = StringBuffer();
  for (final rune in lower.runes) {
    final ch = String.fromCharCode(rune);
    final index = order.indexOf(ch);
    buffer.write(index >= 0 ? String.fromCharCode(0x100 + index) : ch);
  }
  return buffer.toString();
}
