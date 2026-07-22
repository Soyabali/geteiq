import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../theme/tokens.dart';

/// A reusable SUCCESS popup used across the whole app.
///
/// Shows a small success Lottie on top, a message below, and closes itself
/// automatically after 4 seconds (tapping outside also closes it).
///
/// Call it in one line from anywhere — e.g. after an API returns result == 1:
///
/// ```dart
/// SuccessDialog.show(context, 'Invite created successfully');
/// ```
class SuccessDialog extends StatefulWidget {
  const SuccessDialog({super.key, required this.message});

  /// The text shown under the animation (usually the `msg` from the API).
  final String message;

  /// How long before the dialog closes on its own.
  static const Duration _autoCloseAfter = Duration(seconds: 3);

  /// One-line opener. `await` it if you want to run code after it closes.
  static Future<void> show(BuildContext context, String message) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true, // tapping outside also closes it
      builder: (_) => SuccessDialog(message: message),
    );
  }

  @override
  State<SuccessDialog> createState() => _SuccessDialogState();
}

class _SuccessDialogState extends State<SuccessDialog> {
  Timer? _autoCloseTimer;

  @override
  void initState() {
    super.initState();
    // Start the 4-second auto-dismiss countdown.
    _autoCloseTimer = Timer(SuccessDialog._autoCloseAfter, _close);
  }

  void _close() {
    if (mounted) Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _autoCloseTimer?.cancel(); // stop the timer if it closed early
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.xxl),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxxl),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.xxl,
          AppSpacing.xl,
          AppSpacing.xxl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Animated success tick. Swap the .json for any Lottie you like —
            // if the file is ever missing it falls back to a green tick so
            // nothing looks broken.
            SizedBox(
              width: 120,
              height: 120,
              child: Lottie.asset(
                'assets/lottie/success.json',
                repeat: false, // play once
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.success,
                  size: 84,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            // The message (from the API).
            Text(
              widget.message,
              textAlign: TextAlign.center,
              style: t.titleMedium,
            ),
          ],
        ),
      ),
    );
  }
}
