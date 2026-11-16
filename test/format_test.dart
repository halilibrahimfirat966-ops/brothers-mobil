import 'package:brothers_teknoloji/utils/format.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Türkçe fiyat biçimi', () {
    expect(formatPrice(6823), '6.823,00 ₺');
    expect(formatPrice(1234567.5), '1.234.567,50 ₺');
    expect(formatPrice(49.9), '49,90 ₺');
  });

  test('Türkçe arama sadeleştirme', () {
    expect(normalizeTr('İŞLEMCİ Güç Kaynağı'), 'islemci guc kaynagi');
  });
}
