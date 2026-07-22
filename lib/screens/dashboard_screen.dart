import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../data/demo_data.dart';
import '../models/invite.dart';
import '../theme/tokens.dart';
import '../widgets/app_button.dart';
import '../widgets/app_card.dart';
import '../widgets/app_scaffold.dart';
import 'invite_setup_sheet.dart';

/// Screen 4 — home. Sponsored slot, four entry points, and the primary
/// "Add Guest" action that starts the invite flow.
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final gutter = AppSpacing.gutter(context);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        bottom: false,
        child: CenteredFill(
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  gutter,
                  AppSpacing.sm,
                  gutter,
                  AppSpacing.lg,
                ),
                sliver: const SliverToBoxAdapter(child: _DashboardHeader()),
              ),
              SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: gutter),
                sliver: const SliverToBoxAdapter(child: _SponsoredBanner()),
              ),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  gutter,
                  AppSpacing.xxl,
                  gutter,
                  AppSpacing.xxl,
                ),
                sliver: const _ActionGrid(),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _AddGuestBar(gutter: gutter),
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader();

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      DemoData.flat,
                      style: t.titleLarge?.copyWith(fontSize: 21),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 20,
                    color: AppColors.ink,
                  ),
                ],
              ),
              Text(
                DemoData.society,
                style: t.bodySmall,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const _IconAction(icon: Icons.search_rounded, tooltip: 'Search'),
        const SizedBox(width: AppSpacing.xs),
        const _IconAction(
          icon: Icons.notifications_none_rounded,
          tooltip: 'Notifications',
        ),
        const SizedBox(width: AppSpacing.sm),
        // Profile avatar.
        Container(
          width: 38,
          height: 38,
          decoration: const BoxDecoration(
            gradient: AppColors.brandGradientDeep,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            'JW',
            style: t.titleSmall?.copyWith(color: Colors.white, fontSize: 13.5),
          ),
        ),
      ],
    );
  }
}

class _IconAction extends StatelessWidget {
  const _IconAction({required this.icon, required this.tooltip});

  final IconData icon;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon, color: AppColors.ink, size: 23),
      tooltip: tooltip,
      visualDensity: VisualDensity.compact,
      onPressed: () {},
    );
  }
}

/// Gradient promo card with an Unsplash photo underlay.
class _SponsoredBanner extends StatelessWidget {
  const _SponsoredBanner();

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadii.xl),
      child: Stack(
        fit: StackFit.passthrough,
        children: [
          // Photo layer — a failure here simply reveals the gradient below.
          Positioned.fill(
            child: CachedNetworkImage(
              imageUrl: DemoData.bannerImage,
              fit: BoxFit.cover,
              fadeInDuration: const Duration(milliseconds: 350),
              placeholder: (_, __) => const ColoredBox(color: AppColors.brand),
              errorWidget: (_, __, ___) =>
                  const ColoredBox(color: AppColors.brand),
            ),
          ),
          // Gradient scrim keeps the copy legible over any photo.
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    AppColors.brand.withValues(alpha: 0.97),
                    AppColors.brand.withValues(alpha: 0.72),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const TagChip(label: 'SPONSORED'),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Festive move-in offers\nat ${DemoData.society}',
                  style: t.titleLarge?.copyWith(
                    color: Colors.white,
                    fontSize: 20,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Learn more',
                      style: t.titleSmall?.copyWith(color: Colors.white),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      color: Colors.white,
                      size: 17,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Four entry tiles. Switches to a single column on very narrow phones so
/// the labels never clip.
class _ActionGrid extends StatelessWidget {
  const _ActionGrid();

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final narrow = width < 340;

    // Size tiles from their actual contents rather than a guessed aspect
    // ratio: card padding + icon chip + gap are fixed, while the two text
    // lines grow with the OS text scale. A fixed ratio overflows on small
    // phones and at large accessibility sizes.
    final textScale = MediaQuery.textScalerOf(context).scale(1.0);
    const fixed =
        AppSpacing.lg * 2 + 42 + AppSpacing.lg; // padding + icon + gap
    final textBlock = (20 * 2 + 2 + 19) * textScale; // 2 title lines + subtitle
    final extent = fixed + textBlock;

    const tiles = [
      (
        Icons.person_add_alt_1_outlined,
        'Invite guest list',
        'People you invited',
      ),
      (Icons.verified_user_outlined, 'Invited by Guard', 'Guard entries'),
      (Icons.access_time_rounded, 'Yesterday guest list', 'Past 24 hours'),
      (Icons.calendar_month_outlined, 'Month guest Report', 'This month'),
    ];

    return SliverGrid(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: narrow ? 1 : 2,
        mainAxisSpacing: AppSpacing.lg,
        crossAxisSpacing: AppSpacing.lg,
        mainAxisExtent: extent,
      ),
      delegate: SliverChildBuilderDelegate((context, i) {
        final (icon, title, sub) = tiles[i];
        return ActionTile(
          icon: icon,
          title: title,
          subtitle: sub,
          onTap: () => ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text('$title — coming soon'))),
        );
      }, childCount: tiles.length),
    );
  }
}

class _AddGuestBar extends StatelessWidget {
  const _AddGuestBar({required this.gutter});

  final double gutter;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.canvas,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            gutter,
            AppSpacing.sm,
            gutter,
            AppSpacing.md,
          ),
          child: CenteredBar(
            child: PrimaryButton(
              label: 'Add Guest',
              trailing: Icons.arrow_forward_rounded,
              onPressed: () => showInviteSetupSheet(context, Invite()),
            ),
          ),
        ),
      ),
    );
  }
}
