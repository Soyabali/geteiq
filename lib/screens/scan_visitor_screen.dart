import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../theme/tokens.dart';

/// Guard-only screen: opens the camera, reads a visitor QR/barcode pass, and
/// shows the decoded details on a card. Cross-platform (Android + iOS).
class ScanVisitorScreen extends StatefulWidget {
  const ScanVisitorScreen({super.key});

  @override
  State<ScanVisitorScreen> createState() => _ScanVisitorScreenState();
}

class _ScanVisitorScreenState extends State<ScanVisitorScreen> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );

  String? _raw; // the scanned text (null while still scanning)
  bool _torchOn = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_raw != null) return; // already captured one
    final code = capture.barcodes.isNotEmpty
        ? capture.barcodes.first.rawValue
        : null;
    if (code == null || code.trim().isEmpty) return;
    setState(() => _raw = code.trim());
    _controller.stop(); // freeze the camera while showing the result
  }

  void _scanAgain() {
    setState(() => _raw = null);
    _controller.start();
  }

  /// Turns the raw QR text into label/value pairs for the details card.
  /// Handles JSON objects and URIs with query params; else shows nothing here
  /// (the raw text is still displayed on the card).
  List<MapEntry<String, String>> _details(String raw) {
    // 1) JSON object? e.g. {"sGuestName":"Ram","sContactNo":"98..."}
    try {
      final decoded = json.decode(raw);
      if (decoded is Map) {
        return decoded.entries
            .map((e) => MapEntry(e.key.toString(), '${e.value}'))
            .toList();
      }
    } catch (_) {
      // not JSON — fall through
    }
    // 2) URI with query params? e.g. gateiq://invite?code=123&flat=T%201%20304
    final uri = Uri.tryParse(raw);
    if (uri != null && uri.queryParameters.isNotEmpty) {
      return uri.queryParameters.entries.toList();
    }
    // 3) plain text
    return const [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
        actionsIconTheme: const IconThemeData(color: Colors.white),
        // Clear close button to exit the camera.
        leading: IconButton(
          tooltip: 'Close',
          icon: const Icon(Icons.close_rounded, color: Colors.white),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text(
          'Scan Visitor QR Pass',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Torch',
            icon: Icon(
              _torchOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
              color: Colors.white,
            ),
            onPressed: () {
              _controller.toggleTorch();
              setState(() => _torchOn = !_torchOn);
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // Camera preview + decoding.
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
            errorBuilder: (context, error) => _ScannerError(error: error),
          ),

          // Aiming frame while scanning.
          if (_raw == null) const _ScanFrame(),

          // Result card once something is scanned.
          if (_raw != null)
            Align(
              alignment: Alignment.bottomCenter,
              child: _ResultCard(
                raw: _raw!,
                details: _details(_raw!),
                onScanAgain: _scanAgain,
                onDone: () => Navigator.of(context).maybePop(),
              ),
            ),
        ],
      ),
    );
  }
}

/// Centered square aiming guide with a hint.
class _ScanFrame extends StatelessWidget {
  const _ScanFrame();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadii.xl),
              border: Border.all(color: Colors.white, width: 3),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const Text(
            'Align the visitor QR inside the box',
            style: TextStyle(color: Colors.white, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

/// Bottom card showing the decoded pass details.
class _ResultCard extends StatelessWidget {
  const _ResultCard({
    required this.raw,
    required this.details,
    required this.onScanAgain,
    required this.onDone,
  });

  final String raw;
  final List<MapEntry<String, String>> details;
  final VoidCallback onScanAgain;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(AppSpacing.lg),
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadii.xl),
          boxShadow: AppShadows.card,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.verified_rounded,
                  color: AppColors.success,
                  size: 22,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text('Visitor Pass', style: t.titleMedium),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            const Divider(height: 1),
            const SizedBox(height: AppSpacing.md),

            // Parsed fields, or the raw text if we couldn't parse it.
            if (details.isNotEmpty)
              ...details.map(
                (e) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text.rich(
                    TextSpan(
                      style: t.bodyMedium?.copyWith(color: AppColors.inkSoft),
                      children: [
                        TextSpan(
                          text: '${e.key}: ',
                          style: t.bodyMedium?.copyWith(
                            color: AppColors.faint,
                          ),
                        ),
                        TextSpan(text: e.value),
                      ],
                    ),
                  ),
                ),
              )
            else
              Text(raw, style: t.bodyMedium),

            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onScanAgain,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.brand,
                      side: const BorderSide(color: AppColors.brand),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadii.md),
                      ),
                    ),
                    child: const Text('Scan again'),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: FilledButton(
                    onPressed: onDone,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.brand,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadii.md),
                      ),
                    ),
                    child: const Text('Done'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Shown when the camera can't start (e.g. permission denied).
class _ScannerError extends StatelessWidget {
  const _ScannerError({required this.error});

  final MobileScannerException error;

  @override
  Widget build(BuildContext context) {
    final message = switch (error.errorCode) {
      MobileScannerErrorCode.permissionDenied =>
        'Camera permission denied.\nEnable it in Settings to scan.',
      MobileScannerErrorCode.unsupported =>
        'Scanning is not supported on this device.',
      _ => 'Unable to start the camera.',
    };

    return ColoredBox(
      color: Colors.black,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.no_photography_rounded,
                color: Colors.white70,
                size: 48,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
