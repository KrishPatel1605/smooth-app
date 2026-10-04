import 'package:flutter_test/flutter_test.dart';
import 'package:scanner_shared/scanner_shared.dart';

void main() {
  group('GtinValidator', () {
    test('accepts real GTINs', () {
      for (final String code in <String>[
        '3017620425035', // EAN-13 (Nutella)
        '5449000000996', // EAN-13 (Coca-Cola)
        '3175680011480', // EAN-13
        '96385074', // EAN-8
        '036000291452', // UPC-A
        '10012345678902', // GTIN-14
      ]) {
        expect(GtinValidator.hasValidGtinChecksum(code), true, reason: code);
      }
    });

    test('rejects wrong check digits', () {
      expect(GtinValidator.hasValidGtinChecksum('3017620425036'), false);
      expect(GtinValidator.hasValidGtinChecksum('96385075'), false);
      expect(GtinValidator.hasValidGtinChecksum('036000291453'), false);
    });

    test('rejects wrong shape', () {
      expect(GtinValidator.looksLikeGtin('12345'), false);
      expect(GtinValidator.looksLikeGtin('30176204250AB'), false);
      expect(GtinValidator.hasValidGtinChecksum('12345'), false);
    });
  });

  group('BarcodeConfirmer', () {
    test('needs two sightings within the window', () {
      DateTime now = DateTime(2026);
      final BarcodeConfirmer c = BarcodeConfirmer(clock: () => now);
      expect(c.confirm('12345'), false);
      now = now.add(const Duration(milliseconds: 500));
      expect(c.confirm('12345'), true);
    });

    test('forgets sightings that are too old', () {
      DateTime now = DateTime(2026);
      final BarcodeConfirmer c = BarcodeConfirmer(clock: () => now);
      expect(c.confirm('12345'), false);
      now = now.add(const Duration(seconds: 5));
      expect(c.confirm('12345'), false);
    });
  });
}
