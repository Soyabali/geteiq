import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// Notifications screen — professional white layout, grouped by day, with a
/// slow open transition (see [route]) and an iOS-style back button.
///
/// Static data for now; swap [_today] / [_earlier] for an API call later.
class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  /// A slow, smooth fade + gentle upward slide when opening this screen.
  static Route<void> route() {
    return PageRouteBuilder<void>(
      transitionDuration: const Duration(milliseconds: 600),
      reverseTransitionDuration: const Duration(milliseconds: 420),
      pageBuilder: (_, __, ___) => const NotificationScreen(),
      transitionsBuilder: (context, animation, secondary, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.06),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        titleSpacing: 0,
        // iOS-style back chevron.
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          color: AppColors.ink,
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          'Notifications',
          style: t.titleLarge?.copyWith(fontSize: 20),
        ),
        actions: [
          TextButton(
            onPressed: () {},
            style: TextButton.styleFrom(foregroundColor: AppColors.brand),
            child: const Text('Mark all read'),
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
        children: [
          _SectionHeader(label: 'Today'),
          ..._today.map((n) => _NotifTile(item: n)),
          _SectionHeader(label: 'Earlier'),
          ..._earlier.map((n) => _NotifTile(item: n)),
        ],
      ),
    );
  }
}

/// Small muted section label ("Today" / "Earlier").
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: Text(
        label.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: AppColors.faint,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

/// One notification row.
class _NotifTile extends StatelessWidget {
  const _NotifTile({required this.item});

  final _Notif item;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    return Container(
      // Unread rows get a very faint brand tint.
      color: item.unread ? AppColors.brandTint.withValues(alpha: 0.35) : Colors.white,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Type icon in a tinted circle.
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: item.color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(item.icon, color: item.color, size: 21),
          ),
          const SizedBox(width: AppSpacing.md),

          // Title + message.
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  item.title,
                  style: t.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.message,
                  style: t.bodySmall?.copyWith(
                    color: AppColors.muted,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),

          // Time + unread dot.
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                item.time,
                style: t.labelSmall?.copyWith(color: AppColors.faint),
              ),
              const SizedBox(height: 6),
              if (item.unread)
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.brand,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Static notification model.
class _Notif {
  const _Notif({
    required this.icon,
    required this.color,
    required this.title,
    required this.message,
    required this.time,
    this.unread = false,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String message;
  final String time;
  final bool unread;
}

const _today = <_Notif>[
  _Notif(
    icon: Icons.check_circle_rounded,
    color: AppColors.success,
    title: 'Guest approved',
    message: 'Ram Kumar has been approved for entry at Gate 1.',
    time: '2m',
    unread: true,
  ),
  _Notif(
    icon: Icons.login_rounded,
    color: Color(0xFF2563EB),
    title: 'Checked in',
    message: 'Priya Mehta checked in at the main gate.',
    time: '18m',
    unread: true,
  ),
  _Notif(
    icon: Icons.qr_code_2_rounded,
    color: AppColors.brand,
    title: 'Invite created',
    message: 'Your invite pass for Amit Verma is ready to share.',
    time: '1h',
  ),
];

const _earlier = <_Notif>[
  _Notif(
    icon: Icons.logout_rounded,
    color: Color(0xFFEA580C),
    title: 'Checked out',
    message: 'Neha Gupta checked out at 9:30 AM.',
    time: 'Yesterday',
  ),
  _Notif(
    icon: Icons.warning_amber_rounded,
    color: AppColors.danger,
    title: 'Security alert',
    message: 'An unrecognised visitor was flagged at Gate 2.',
    time: 'Yesterday',
  ),
  _Notif(
    icon: Icons.campaign_rounded,
    color: Color(0xFF7C3AED),
    title: 'Society notice',
    message: 'Water supply maintenance scheduled for Sunday 8–10 AM.',
    time: '2d',
  ),
];
