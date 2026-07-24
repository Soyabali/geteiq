import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../theme/tokens.dart';

/// Shows a polished logout confirmation dialog with a fade + scale entrance.
///
/// Returns `true` if the user tapped **Logout**, otherwise `false`/`null`.
Future<bool?> showLogoutDialog(BuildContext context) {
  return showGeneralDialog<bool>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Logout',
    barrierColor: Colors.black.withValues(alpha: 0.5),
    transitionDuration: const Duration(milliseconds: 340),
    pageBuilder: (context, _, __) => const _LogoutDialogCard(),
    transitionBuilder: (context, anim, _, child) {
      final scale = CurvedAnimation(
        parent: anim,
        curve: Curves.easeOutBack,
        reverseCurve: Curves.easeInCubic,
      );
      return FadeTransition(
        opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.86, end: 1).animate(scale),
          child: child,
        ),
      );
    },
  );
}

class _LogoutDialogCard extends StatelessWidget {
  const _LogoutDialogCard();

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Material(
            color: Colors.transparent,
            child: Container(
              decoration: BoxDecoration(
                // Soft top-down gradient on the card for a premium feel.
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFFFFFFF), Color(0xFFFDF6F1)],
                ),
                borderRadius: BorderRadius.circular(AppRadii.xxl),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x33101820),
                    blurRadius: 40,
                    offset: Offset(0, 18),
                    spreadRadius: -6,
                  ),
                ],
              ),
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.xxl,
                AppSpacing.xl,
                AppSpacing.lg,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Animated logout mark inside a gradient circle.
                  Container(
                    width: 104,
                    height: 104,
                    decoration: const BoxDecoration(
                      gradient: AppColors.brandGradientDeep,
                      shape: BoxShape.circle,
                      boxShadow: AppShadows.brandGlow,
                    ),
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Lottie.asset(
                      // Drop a real logout animation at this path to use it;
                      // until then the animated fallback icon below is shown.
                      'assets/lottie/logout.json',
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const _PulseLogoutIcon(),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  Text(
                    'Do you want to Logout?',
                    textAlign: TextAlign.center,
                    style: t.titleLarge?.copyWith(fontSize: 20),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    "You'll need to sign in again to continue.",
                    textAlign: TextAlign.center,
                    style: t.bodyMedium?.copyWith(color: AppColors.muted),
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // Buttons — bottom-right aligned.
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      CupertinoButton(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                          vertical: 10,
                        ),
                        minSize: 0,
                        onPressed: () => Navigator.of(context).pop(false),
                        child: Text(
                          'Cancel',
                          style: t.titleSmall?.copyWith(
                            color: AppColors.muted,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      // Gradient logout button.
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: AppColors.brandGradientDeep,
                          borderRadius: BorderRadius.circular(AppRadii.pill),
                          boxShadow: AppShadows.brandGlow,
                        ),
                        child: CupertinoButton(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.xl,
                            vertical: 11,
                          ),
                          minSize: 0,
                          borderRadius: BorderRadius.circular(AppRadii.pill),
                          onPressed: () => Navigator.of(context).pop(true),
                          child: Text(
                            'Logout',
                            style: t.titleSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Animated fallback shown when no Lottie asset is present — a gently pulsing
/// logout glyph, so the dialog still "feels" alive.
class _PulseLogoutIcon extends StatefulWidget {
  const _PulseLogoutIcon();

  @override
  State<_PulseLogoutIcon> createState() => _PulseLogoutIconState();
}

class _PulseLogoutIconState extends State<_PulseLogoutIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1300),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        final v = Curves.easeInOut.transform(_c.value);
        return Transform.scale(
          scale: 0.92 + (0.12 * v),
          child: Transform.translate(
            offset: Offset(2 * v, 0), // arrow nudges "out"
            child: child,
          ),
        );
      },
      child: const Icon(
        Icons.logout_rounded,
        color: Colors.white,
        size: 44,
      ),
    );
  }
}
