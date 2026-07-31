import 'package:flutter/material.dart';

import '../models/app_notification.dart';
import '../services/NotificationList.dart';
import '../theme/tokens.dart';

/// Tablet breakpoint. Phones (< 600) always render the original, untouched
/// flat white list.
bool _isTablet(BuildContext context) => MediaQuery.sizeOf(context).width >= 600;

/// Notifications screen — professional white layout, grouped by day, with a
/// slow open transition (see [route]) and an iOS-style back button.
///
/// Rows come from `NotificationList/NotificationList` via
/// [NotificationListRepo], which sends the login `iUserId`. Same load /
/// error / empty pattern as `gate_log_screen.dart`.
class NotificationScreen extends StatefulWidget {
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
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  List<AppNotification> _all = [];
  bool _loading = true;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  // ==========================================================================
  //  DATA
  // ==========================================================================

  /// [silent] keeps the current list on screen (pull-to-refresh) instead of
  /// swapping it for the full-screen spinner.
  Future<void> _load({bool silent = false}) async {
    setState(() {
      _loading = !silent;
      _error = false;
    });
    try {
      final rows = await NotificationListRepo().getNotifications(context);
      if (!mounted) return;
      setState(() {
        _all = rows;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = true;
      });
    }
  }

  /// Rows in the order the API sent them (newest first), split into
  /// "Today" / "Yesterday" / date sections.
  List<_Section> get _sections {
    final sections = <_Section>[];
    for (final n in _all) {
      final label = n.dayLabel;
      if (sections.isEmpty || sections.last.label != label) {
        sections.add(_Section(label: label, items: [n]));
      } else {
        sections.last.items.add(n);
      }
    }
    return sections;
  }

  // ==========================================================================
  //  UI
  // ==========================================================================

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final isTablet = _isTablet(context);

    return Scaffold(
      backgroundColor: isTablet ? AppColors.canvas : Colors.white,
      appBar: AppBar(
        backgroundColor: isTablet ? AppColors.canvas : Colors.white,
        surfaceTintColor: isTablet ? AppColors.canvas : Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        toolbarHeight: isTablet ? 72 : kToolbarHeight,
        titleSpacing: 0,
        centerTitle: true,
        // iOS-style back chevron.
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          color: AppColors.ink,
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          'Notifications',
          style: t.titleLarge?.copyWith(fontSize: isTablet ? 24 : 20),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, size: 22),
            color: AppColors.brand,
            tooltip: 'Refresh',
            onPressed: _loading ? null : _load,
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      body: _body(),
    );
  }

  Widget _body() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.brand),
      );
    }
    if (_error) {
      return _ListMessage(
        icon: Icons.wifi_off_rounded,
        message: "Couldn't load your notifications.",
        onRetry: _load,
      );
    }
    if (_all.isEmpty) {
      return const _ListMessage(
        icon: Icons.notifications_none_rounded,
        message: 'No Data',
      );
    }

    final sections = _sections;

    return Builder(
      builder: (context) {
        final isTablet = _isTablet(context);

        // Notifications are chronological, so — unlike the guest-list
        // screens — a grid would scramble the reading order. Instead: cap
        // the reading width and centre it, like a real notification centre,
        // with each row promoted to its own card. RefreshIndicator + ListView
        // stay the single scrollable either way, so pull-to-refresh behaves
        // identically; only the padding and item widget change for tablet.
        double horizontalInset = 0;
        if (isTablet) {
          final width = MediaQuery.sizeOf(context).width;
          const maxContentWidth = 720.0;
          final gutter = AppSpacing.gutter(context);
          horizontalInset = width > maxContentWidth + gutter * 2
              ? (width - maxContentWidth) / 2
              : gutter;
        }

        return RefreshIndicator(
          color: AppColors.brand,
          onRefresh: () => _load(silent: true),
          child: ListView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            padding: EdgeInsets.fromLTRB(
              horizontalInset,
              isTablet ? AppSpacing.lg : 0,
              horizontalInset,
              AppSpacing.xxl,
            ),
            children: [
              for (final s in sections) ...[
                _SectionHeader(label: s.label),
                if (isTablet)
                  ...s.items.map((n) => _TabletNotifTile(item: n))
                else
                  ...s.items.map((n) => _NotifTile(item: n)),
              ],
            ],
          ),
        );
      },
    );
  }
}

/// One day's worth of rows, in API order.
class _Section {
  _Section({required this.label, required this.items});

  final String label;
  final List<AppNotification> items;
}

/// Small muted section label ("Today" / "Yesterday" / "29 Jul 2026").
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

/// Tablet notification row — same data as [_NotifTile], promoted to its own
/// bordered/shadowed card with a gap below it (instead of a flush row flat
/// against the page), a bigger icon badge, and roomier type. Purely visual —
/// no new fields, no new behaviour.
class _TabletNotifTile extends StatelessWidget {
  const _TabletNotifTile({required this.item});

  final AppNotification item;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: AppColors.borderSoft),
        boxShadow: AppShadows.card,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: item.color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            clipBehavior: Clip.antiAlias,
            child: item.hasImage
                ? Image.network(
                    item.imageUrl,
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        Icon(item.icon, color: item.color, size: 24),
                  )
                : Icon(item.icon, color: item.color, size: 24),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  item.title.isEmpty ? 'Notification' : item.title,
                  style: t.titleSmall?.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  item.message,
                  style: t.bodyMedium?.copyWith(
                    color: AppColors.muted,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Text(
            item.timeLabel,
            style: t.labelSmall?.copyWith(color: AppColors.faint),
          ),
        ],
      ),
    );
  }
}

/// One notification row.
class _NotifTile extends StatelessWidget {
  const _NotifTile({required this.item});

  final AppNotification item;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // sImageUrl when the API sent one, otherwise the derived type icon
          // in a tinted circle.
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: item.color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            clipBehavior: Clip.antiAlias,
            child: item.hasImage
                ? Image.network(
                    item.imageUrl,
                    width: 42,
                    height: 42,
                    fit: BoxFit.cover,
                    // A dead image URL must not blank out the row.
                    errorBuilder: (_, __, ___) =>
                        Icon(item.icon, color: item.color, size: 21),
                  )
                : Icon(item.icon, color: item.color, size: 21),
          ),
          const SizedBox(width: AppSpacing.md),

          // sTitle + sNotification.
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  item.title.isEmpty ? 'Notification' : item.title,
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

          // dReceivedAt — time of day, the day itself is in the section header.
          Text(
            item.timeLabel,
            style: t.labelSmall?.copyWith(color: AppColors.faint),
          ),
        ],
      ),
    );
  }
}

/// Full-height placeholder for the error / empty states.
class _ListMessage extends StatelessWidget {
  const _ListMessage({required this.icon, required this.message, this.onRetry});

  final IconData icon;
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: AppColors.faint),
            const SizedBox(height: AppSpacing.md),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.muted),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: AppSpacing.md),
              TextButton(
                onPressed: onRetry,
                style: TextButton.styleFrom(foregroundColor: AppColors.brand),
                child: const Text('Try again'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
