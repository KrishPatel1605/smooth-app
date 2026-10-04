import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_zxing/flutter_zxing.dart';
import 'package:scanner_shared/scanner_shared.dart';
import 'package:visibility_detector/visibility_detector.dart';

/// Scanner implementation using ZXing
class ScannerZXing extends Scanner {
  const ScannerZXing();

  @override
  String getType() => 'ZXing';

  @override
  Widget getScanner({
    required Future<bool> Function(String) onScan,
    required Future<void> Function() hapticFeedback,
    required Function(BuildContext)? onCameraFlashError,
    required Function(
      String msg,
      String category, {
      int? eventValue,
      String? barcode,
    })
    trackCustomEvent,
    required bool hasMoreThanOneCamera,
    required Widget barcodeScannerIcon,
    required Widget torchOnIcon,
    required Widget torchOffIcon,
    String? toggleCameraModeTooltip,
    String? toggleFlashModeTooltip,
    EdgeInsetsGeometry? contentPadding,
  }) {
    return _SmoothBarcodeScannerZXing(
      onScan: onScan,
      hapticFeedback: hapticFeedback,
      onCameraFlashError: onCameraFlashError,
      hasMoreThanOneCamera: hasMoreThanOneCamera,
      toggleCameraModeTooltip: toggleCameraModeTooltip,
      toggleFlashModeTooltip: toggleFlashModeTooltip,
      barcodeScannerIcon: barcodeScannerIcon,
      torchOnIcon: torchOnIcon,
      torchOffIcon: torchOffIcon,
      contentPadding: contentPadding,
    );
  }
}

/// Barcode scanner based on ZXing.
class _SmoothBarcodeScannerZXing extends StatefulWidget {
  const _SmoothBarcodeScannerZXing({
    required this.onScan,
    required this.hapticFeedback,
    required this.onCameraFlashError,
    required this.hasMoreThanOneCamera,
    required this.barcodeScannerIcon,
    required this.torchOnIcon,
    required this.torchOffIcon,
    this.toggleCameraModeTooltip,
    this.toggleFlashModeTooltip,
    this.contentPadding,
  });

  final Future<bool> Function(String) onScan;
  final Future<void> Function() hapticFeedback;
  final Function(BuildContext)? onCameraFlashError;
  final bool hasMoreThanOneCamera;

  final Widget barcodeScannerIcon;
  final Widget torchOnIcon;
  final Widget torchOffIcon;

  final EdgeInsetsGeometry? contentPadding;
  final String? toggleCameraModeTooltip;
  final String? toggleFlashModeTooltip;

  @override
  State<StatefulWidget> createState() => _SmoothBarcodeScannerZXingState();
}

class _SmoothBarcodeScannerZXingState
    extends State<_SmoothBarcodeScannerZXing> {
  @override
  Widget build(BuildContext context) => VisibilityDetector(
    key: const ValueKey<String>('VisibilityDetector'),
    onVisibilityChanged: (final VisibilityInfo info) {},
    child: Stack(
      children: <Widget>[
        Positioned.fill(
          child: ReaderWidget(
            onScan: _onScan,
            // We draw our own visor
            showScannerOverlay: false,
            showGallery: false,
            showToggleCamera: widget.hasMoreThanOneCamera,
            showFlashlight: true,
            // Barcodes can be in any direction (eg: standing vertically):
            // [tryRotate] makes ZXing test the 4 orientations and
            // [tryHarder] enables a slower but more accurate algorithm.
            tryRotate: true,
            tryHarder: true,
            // Some labels are printed white on black
            tryInverted: true,
            // The default delay (1s) is far too long to catch a barcode
            // while the phone is moving.
            scanDelay: const Duration(milliseconds: 150),
            scanDelaySuccess: const Duration(milliseconds: 1000),
            // Analyze a larger area than the default (0.5), so that a
            // barcode standing vertically is not cropped.
            cropPercent: 0.8,
          ),
        ),
        Center(
          child: SmoothBarcodeScannerVisor(
            icon: widget.barcodeScannerIcon,
            contentPadding: widget.contentPadding,
          ),
        ),
      ],
    ),
  );

  Future<void> _onScan(final Code code) async {
    final String? text = code.text;
    // Ignore partial / invalid decodings
    if (!code.isValid || text == null || text.isEmpty) {
      return;
    }
    // The upper layer validates the check digit (see GtinValidator)
    await widget.onScan(text);
  }
}
