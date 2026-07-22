import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../theme/tokens.dart';
import '../widgets/brand_mark.dart';
import 'login_screen.dart';
import 'role_select_screen.dart';

/// Screen 1 — brand moment.
///
/// Plays the handshake Lottie, then hands off to role selection. Tapping
/// anywhere skips ahead so the animation never blocks a returning user.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  /// How long the splash holds before advancing on its own.
  /// Tuned so the handshake reads as a complete gesture; lower it freely.
  static const _hold = Duration(milliseconds: 1800);

  late final AnimationController _lottie = AnimationController(vsync: this);
  late final Timer _timer;
  bool _leaving = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer(_hold, _advance);
  }

  @override
  void dispose() {
    _timer.cancel();
    _lottie.dispose();
    super.dispose();
  }

  void _advance() {
    if (_leaving || !mounted) return;
    _leaving = true;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 420),
        pageBuilder: (_, __, ___) => LoginScreen(),
        transitionsBuilder: (_, animation, __, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          );
          return FadeTransition(
            opacity: curved,
            child: ScaleTransition(
              scale: Tween<double>(begin: 1.04, end: 1).animate(curved),
              child: child,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    // Keep the animation proportional but never oversized on tablets.
    final side = MediaQuery.sizeOf(context).width;
    final artSize = (side * 0.52).clamp(160.0, 260.0);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _advance,
        child: SafeArea(
          child: Column(
            children: [
              const Spacer(flex: 3),
              _FadeIn(
                delay: Duration.zero,
                child: SizedBox(
                  width: artSize,
                  height: artSize,
                  child: Lottie.asset(
                    'assets/lottie/handshake.json',
                    controller: _lottie,
                    fit: BoxFit.contain,
                    onLoaded: (composition) {
                      _lottie
                        ..duration = composition.duration
                        ..forward();
                    },
                    // If the asset ever fails, fall back to the brand glyph
                    // rather than showing a broken box.
                    errorBuilder: (_, __, ___) =>
                        const Center(child: BrandMark(size: 96)),
                  ),
                ),
              ),
              const Spacer(flex: 2),
              _FadeIn(
                delay: const Duration(milliseconds: 260),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const BrandMark(size: 40),
                        const SizedBox(width: AppSpacing.md),
                        const BrandWordmark(fontSize: 30),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Visitor Management',
                      style: t.bodyLarge?.copyWith(color: AppColors.muted),
                    ),
                  ],
                ),
              ),
              const Spacer(flex: 3),
              _FadeIn(
                delay: const Duration(milliseconds: 700),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
                  child: Text(
                    'Tap to continue',
                    style: t.bodySmall?.copyWith(color: AppColors.faint),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Small staggered fade+rise used to sequence the splash elements.
class _FadeIn extends StatefulWidget {
  const _FadeIn({required this.child, required this.delay});

  final Widget child;
  final Duration delay;

  @override
  State<_FadeIn> createState() => _FadeInState();
}

class _FadeInState extends State<_FadeIn> {
  bool _shown = false;

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(widget.delay, () {
      if (mounted) setState(() => _shown = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSlide(
      offset: _shown ? Offset.zero : const Offset(0, 0.12),
      duration: const Duration(milliseconds: 520),
      curve: Curves.easeOutCubic,
      child: AnimatedOpacity(
        opacity: _shown ? 1 : 0,
        duration: const Duration(milliseconds: 520),
        child: widget.child,
      ),
    );
  }
}
