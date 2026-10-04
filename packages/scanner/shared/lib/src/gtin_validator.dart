/// Helpers to filter out "ghost" scans, i.e. barcodes that were wrongly
/// decoded (typically when the phone moves quickly or the barcode is
/// partially visible).
abstract final class GtinValidator {
  /// GTIN lengths that carry a GS1 check digit (EAN-8, UPC-A, EAN-13, ITF-14).
  static const Set<int> GTIN_LENGTHS = <int>{8, 12, 13, 14};

  static final RegExp _digitsOnly = RegExp(r'^\d+$');

  /// Whether [code] has the shape of a GTIN (only digits, a known length).
  static bool looksLikeGtin(String code) =>
      GTIN_LENGTHS.contains(code.length) && _digitsOnly.hasMatch(code);

  /// Whether [code] is a GTIN with a correct GS1 check digit.
  ///
  /// Algorithm: starting from the right (excluding the check digit), digits
  /// are weighted 3, 1, 3, 1… The check digit completes the sum to a
  /// multiple of 10.
  static bool hasValidGtinChecksum(String code) {
    if (!looksLikeGtin(code)) {
      return false;
    }

    int sum = 0;
    for (int i = code.length - 2, weight = 3; i >= 0; i--) {
      sum += int.parse(code[i]) * weight;
      weight = weight == 3 ? 1 : 3;
    }
    final int expected = (10 - sum % 10) % 10;
    return expected == int.parse(code[code.length - 1]);
  }
}

/// Requires a barcode to be seen several times in a short period before it is
/// accepted. Used for non-GTIN codes (short, alphanumeric…) where no checksum
/// can reject a misread.
class BarcodeConfirmer {
  BarcodeConfirmer({
    this.requiredSightings = 2,
    this.window = const Duration(seconds: 2),
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final int requiredSightings;
  final Duration window;
  final DateTime Function() _clock;

  final Map<String, List<DateTime>> _sightings = <String, List<DateTime>>{};

  /// Registers a sighting and returns true once [code] has been seen
  /// [requiredSightings] times within [window].
  bool confirm(String code) {
    final DateTime now = _clock();
    // Forget everything outdated, so the map never grows
    _sightings.removeWhere(
      (_, List<DateTime> v) => now.difference(v.last) > window,
    );

    final List<DateTime> list = _sightings.putIfAbsent(code, () => <DateTime>[])
      ..add(now)
      ..removeWhere((DateTime d) => now.difference(d) > window);

    if (list.length >= requiredSightings) {
      _sightings.remove(code);
      return true;
    }
    return false;
  }
}
