import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../services/VMSGaurdUpdateStatus.dart';
import '../services/VMSGaurdVisitorRequestList.dart';
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
  bool _submitting = false; // "Done" -> status api in progress

  // The barcode only carries the pass code, so the guest's name is looked up
  // from today's guard list by matching sQRCodeVal — see [_lookupGuestName].
  String? _guestName; // null until the lookup resolves
  bool _lookingUpName = false; // shows "Looking up…" on the card

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// "Done" -> mark this pass checked-in (iStatus = 2) using the scanned code
  /// as sQRCodeVal, then toast the server's reply.
  Future<void> _done() async {
    final code = _extractCode(_raw ?? '');
    if (code.isEmpty || _submitting) return;

    // Grabbed before awaiting so the toast still shows after this route pops.
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    setState(() => _submitting = true);

    try {
      final res = await GuardUpdateStatusRepo().updateStatus(
        context,
        code,
        GuardStatus.checkIn, // iStatus = "2"
      );
      if (!mounted) return;

      final result = "${res['Result']}";
      final msg = "${res['Msg']}";
      final ok = result == "1";

      _toast(
        messenger,
        msg.isEmpty
            ? (ok ? 'Check-in updated' : 'Could not update the status.')
            : msg,
        ok: ok,
      );

      // Success -> close the scanner. Failure -> stay put so the guard can
      // re-scan instead of losing the camera.
      if (ok) {
        navigator.pop();
      } else {
        setState(() => _submitting = false);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      _toast(messenger, 'Something went wrong. Please try again.', ok: false);
    }
  }

  /// Floating toast. Takes the messenger rather than reading it off `context`
  /// so it survives this screen being popped.
  void _toast(
    ScaffoldMessengerState messenger,
    String message, {
    required bool ok,
  }) {
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: ok ? AppColors.success : AppColors.danger,
          elevation: 6,
          duration: const Duration(seconds: 3),
          margin: const EdgeInsets.all(AppSpacing.lg),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.md),
          ),
          content: Row(
            children: [
              Icon(
                ok ? Icons.check_circle_rounded : Icons.error_outline_rounded,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
  }

  void _onDetect(BarcodeCapture capture) {
    if (_raw != null) return; // already captured one
    final code = capture.barcodes.isNotEmpty
        ? capture.barcodes.first.rawValue
        : null;
    if (code == null || code.trim().isEmpty) return;
    // If the card ever shows fewer/different fields than expected, check this
    // line — it's the exact, unparsed text the scanner read off the barcode.
    debugPrint('🔎 Scanned raw: ${code.trim()}');
    setState(() => _raw = code.trim());
    _controller.stop(); // freeze the camera while showing the result
    _lookupGuestName(); // resolve the name behind the scanned code
  }

  void _scanAgain() {
    setState(() {
      _raw = null;
      _guestName = null;
      _lookingUpName = false;
    });
    _controller.start();
  }

  /// The pass code (sQRCodeVal) carried by the scanned text.
  ///
  /// Most passes encode the bare code, but the in-app ticket encodes a
  /// `gateiq://invite?code=…` URI, so the code is pulled out of the known
  /// key when one is present and the whole trimmed text is used otherwise.
  String _extractCode(String raw) {
    final trimmed = raw.trim();
    const keys = ['sQRCodeVal', 'qrCodeVal', 'code', 'sCode'];

    // JSON object, e.g. {"sQRCodeVal":"911309", ...}
    try {
      final decoded = json.decode(trimmed);
      if (decoded is Map) {
        for (final k in keys) {
          final v = '${decoded[k] ?? ''}'.trim();
          if (v.isNotEmpty) return v;
        }
      }
    } catch (_) {
      // not JSON — fall through
    }

    // URI query, e.g. gateiq://invite?code=911309&flat=T%201%20304
    final uri = Uri.tryParse(trimmed);
    if (uri != null && uri.hasScheme && uri.queryParameters.isNotEmpty) {
      for (final k in keys) {
        final v = (uri.queryParameters[k] ?? '').trim();
        if (v.isNotEmpty) return v;
      }
    }

    return trimmed; // bare code — the common case
  }

  /// Looks the scanned code up in today's guard list to get the guest's name.
  ///
  /// The barcode itself carries no name, so this matches the scanned code
  /// against `sQRCodeVal` and reads `sGuestNames` off that row. Failure is
  /// silent — the card just falls back to showing the code alone, and the
  /// guard can still tap Done.
  Future<void> _lookupGuestName() async {
    final code = _extractCode(_raw ?? '');
    if (code.isEmpty) return;

    setState(() => _lookingUpName = true);
    try {
      final list = await GuardVisitorRepo().getVisitorList(context);
      if (!mounted) return;

      final match = list.where((v) => v.qrCodeVal.trim() == code).firstOrNull;
      setState(() {
        _guestName = match?.guestNames.trim();
        _lookingUpName = false;
      });
    } catch (e) {
      if (!mounted) return;
      debugPrint('Guest name lookup failed: $e');
      setState(() => _lookingUpName = false);
    }
  }

  /// Turns the raw scanned text into label/value pairs for the details card.
  ///
  /// The number and shape of fields packed into a barcode isn't fixed here,
  /// so this tries several common encodings, in order, and — unlike a plain
  /// "show the raw text" fallback — always returns at least one entry. That
  /// way a barcode holding one code and a barcode holding many fields are
  /// both rendered the same "label: value" way on the card.
  List<MapEntry<String, String>> _details(String raw) {
    final trimmed = raw.trim();

    // 1) JSON object, e.g. {"sQRCodeVal":"911309","sGuestNames":"Ram"}
    // 2) JSON array, e.g. ["911309","Ram","T1304"]
    try {
      final decoded = json.decode(trimmed);
      if (decoded is Map) {
        return decoded.entries
            .map((e) => MapEntry(_prettyLabel('${e.key}'), '${e.value}'))
            .toList();
      }
      if (decoded is List) {
        return [
          for (var i = 0; i < decoded.length; i++)
            MapEntry('Field ${i + 1}', '${decoded[i]}'),
        ];
      }
    } catch (_) {
      // not JSON — fall through
    }

    // 3) URI with a scheme and query params,
    //    e.g. gateiq://invite?code=911309&flat=T%201%20304
    final uri = Uri.tryParse(trimmed);
    if (uri != null && uri.hasScheme && uri.queryParameters.isNotEmpty) {
      return uri.queryParameters.entries
          .map((e) => MapEntry(_prettyLabel(e.key), e.value))
          .toList();
    }

    // 4) key=value / key:value pairs joined by &, ;, |, a newline or a tab,
    //    e.g. "code=911309&flat=T1304&guest=Ram" — same idea as #3 but with
    //    no URI scheme, which Uri.tryParse won't split into query params.
    final groups = trimmed
        .split(RegExp(r'[&;|\n\t]'))
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toList();

    if (groups.isNotEmpty) {
      final pairs = <MapEntry<String, String>>[];
      var allHaveSeparator = true;
      for (final g in groups) {
        final i = g.indexOf(RegExp(r'[=:]'));
        if (i <= 0) {
          allHaveSeparator = false;
          break;
        }
        pairs.add(
          MapEntry(_prettyLabel(g.substring(0, i)), g.substring(i + 1).trim()),
        );
      }
      if (allHaveSeparator) return pairs;

      // 5) Same split, but no keys — just a delimited list of plain values,
      //    e.g. "911309|Ram|T1304".
      if (groups.length > 1) {
        return [
          for (var i = 0; i < groups.length; i++)
            MapEntry('Field ${i + 1}', groups[i]),
        ];
      }
    }

    // 6) One atomic value (e.g. a bare numeric code) — still shown as
    //    "label: value", the same fashion as everything above.
    return [MapEntry('Code', trimmed)];
  }

  /// "sGuestNames" -> "Guest Names", "flat_no" -> "Flat No", "code" -> "Code".
  /// Strips this backend's Hungarian `s`-string prefix (sQRCodeVal, sNote,
  /// sGuestNames, ...) then title-cases camelCase / snake_case / kebab-case.
  String _prettyLabel(String key) {
    var k = key.trim();
    if (k.length > 1 && k[0] == 's' && k[1] == k[1].toUpperCase()) {
      k = k.substring(1);
    }
    final words = k
        .replaceAllMapped(
          RegExp(r'([a-z0-9])([A-Z])'),
          (m) => '${m[1]} ${m[2]}',
        )
        .split(RegExp(r'[_\-\s]+'))
        .where((w) => w.isNotEmpty);
    return words.map((w) => w[0].toUpperCase() + w.substring(1)).join(' ');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
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
                guestName: _guestName,
                lookingUpName: _lookingUpName,
                details: _details(_raw!),
                submitting: _submitting,
                onScanAgain: _scanAgain,
                onDone: _done,
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
    required this.guestName,
    required this.lookingUpName,
    required this.details,
    required this.submitting,
    required this.onScanAgain,
    required this.onDone,
  });

  /// sGuestNames for the scanned pass. Null until the lookup finishes, or when
  /// the code matched no row in today's list.
  final String? guestName;
  final bool lookingUpName;
  final List<MapEntry<String, String>> details;
  final bool submitting;
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

            // Guest name — not in the barcode, so it comes from the list API
            // keyed on the scanned code. Sits above the code, in the same
            // "label: value" fashion as the rows below.
            // Padding(
            //   padding: const EdgeInsets.only(bottom: 6),
            //   child: Text.rich(
            //     TextSpan(
            //       style: t.bodyMedium?.copyWith(color: AppColors.inkSoft),
            //       children: [
            //         TextSpan(
            //           text: 'Name: ',
            //           style: t.bodyMedium?.copyWith(color: AppColors.faint),
            //         ),
            //         TextSpan(
            //           text: lookingUpName
            //               ? 'Looking up…'
            //               : (guestName == null || guestName!.isEmpty
            //                     ? '—'
            //                     : guestName!),
            //           style: t.bodyMedium?.copyWith(
            //             fontWeight: FontWeight.w700,
            //             color: AppColors.ink,
            //           ),
            //         ),
            //       ],
            //     ),
            //   ),
            // ),

            // Every field the barcode carried — one entry or many, all shown
            // the same "label: value" way.
            ...details.map(
              (e) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text.rich(
                  TextSpan(
                    style: t.bodyMedium?.copyWith(color: AppColors.inkSoft),
                    children: [
                      TextSpan(
                        text: '${e.key}: ',
                        style: t.bodyMedium?.copyWith(color: AppColors.faint),
                      ),
                      TextSpan(text: e.value),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: submitting ? null : onScanAgain,
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
                    onPressed: submitting ? null : onDone,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.brand,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadii.md),
                      ),
                    ),
                    child: submitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Done'),
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
