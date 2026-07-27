import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../services/connectivity_service.dart';
import '../theme/tokens.dart';

/// Full-screen, non-dismissible "you're offline" gate — same idea as the
/// Amazon app's offline screen: an animated mascot while there's no
/// internet, checked in the background, swapping to a brief "back online"
/// message the moment the connection returns.
///
/// Usage: `await NoInternetScreen.waitForConnection(context);` before a flow
/// that needs the network. Returns immediately if already online; otherwise
/// blocks until the connection comes back, then returns so the caller's
/// existing flow can continue unchanged.
class NoInternetScreen extends StatefulWidget {
  const NoInternetScreen({super.key});

  static Future<void> waitForConnection(BuildContext context) async {
    if (await ConnectivityService.instance.hasInternet()) return;
    if (!context.mounted) return;
    await Navigator.of(context).push<void>(
      PageRouteBuilder<void>(
        opaque: true,
        fullscreenDialog: true,
        transitionDuration: const Duration(milliseconds: 260),
        pageBuilder: (_, __, ___) => const NoInternetScreen(),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  State<NoInternetScreen> createState() => _NoInternetScreenState();
}

class _NoInternetScreenState extends State<NoInternetScreen> {
  static const _pollEvery = Duration(seconds: 3);
  Timer? _poll;
  bool _reconnected = false;

  @override
  void initState() {
    super.initState();
    _poll = Timer.periodic(_pollEvery, (_) => _check());
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  Future<void> _check() async {
    if (_reconnected) return;
    final online = await ConnectivityService.instance.hasInternet();
    if (!online || !mounted || _reconnected) return;

    _poll?.cancel();
    setState(() => _reconnected = true);
    // Let the "back online" beat register before handing control back.
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // Offline is a hard gate — the back gesture can't skip past it.
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.canvas,
        body: Center(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 320),
            child: _reconnected
                ? const _StatusMessage(
                    key: ValueKey('online'),
                    art: SizedBox(
                      width: 140,
                      height: 140,
                      child: _SuccessArt(),
                    ),
                    title: "You're back online",
                    subtitle: 'Continuing…',
                  )
                : const _StatusMessage(
                    key: ValueKey('offline'),
                    art: _AnimatedDog(),
                    title: 'No internet connection',
                    subtitle:
                        "Check your Wi-Fi or mobile data — we'll reconnect "
                        'automatically.',
                  ),
          ),
        ),
      ),
    );
  }
}

class _StatusMessage extends StatelessWidget {
  const _StatusMessage({
    super.key,
    required this.art,
    required this.title,
    required this.subtitle,
  });

  final Widget art;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          art,
          const SizedBox(height: AppSpacing.xl),
          Text(title, style: t.titleLarge, textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.sm),
          Text(
            subtitle,
            style: t.bodyMedium?.copyWith(color: AppColors.muted),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// Reuses the app's existing "success" Lottie for the reconnect beat — no
/// new asset needed.
class _SuccessArt extends StatelessWidget {
  const _SuccessArt();

  @override
  Widget build(BuildContext context) {
    return Lottie.asset(
      'assets/lottie/success.json',
      fit: BoxFit.contain,
      // If the asset ever fails to load, a checkmark still reads as "back
      // online" rather than showing a broken box.
      errorBuilder: (_, __, ___) => const Icon(
        Icons.check_circle_rounded,
        size: 96,
        color: AppColors.success,
      ),
    );
  }
}

/// A small idle "head tilt + bounce" loop on a dog emoji — a lightweight,
/// dependency-free mascot for the offline state. Pure Flutter animation, so
/// it always renders even with zero connectivity (nothing here is fetched
/// over the network).
class _AnimatedDog extends StatefulWidget {
  const _AnimatedDog();

  @override
  State<_AnimatedDog> createState() => _AnimatedDogState();
}

class _AnimatedDogState extends State<_AnimatedDog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = Curves.easeInOut.transform(_controller.value);
        final tilt = (t - 0.5) * 0.24; // gentle head tilt, ~±0.12 rad
        final lift = -8 * t; // small bounce upward
        return Transform.translate(
          offset: Offset(0, lift),
          child: Transform.rotate(angle: tilt, child: child),
        );
      },
      child: const Text('🐶', style: TextStyle(fontSize: 96)),
    );
  }
}
