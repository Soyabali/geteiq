import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/invite.dart';
import '../theme/tokens.dart';
import '../widgets/app_button.dart';
import '../widgets/app_card.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/company_carousel.dart';
import 'expected_guest_screen.dart';
import 'guard_invite_screen.dart';
import 'invite_setup_sheet.dart';
import 'invite_guest_list_screen.dart';
import 'invited_by_guard_screen.dart';
import 'login_screen.dart';
import 'month_guest_report_screen.dart';
import 'notification_screen.dart';
import 'scan_visitor_screen.dart';
import 'yesterday_guest_list_screen.dart';

/// Screen 4 — home. Sponsored slot, four entry points, and the primary
/// "Add Guest" action that starts the invite flow.
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final gutter = AppSpacing.gutter(context);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      // Right-side drawer opened by tapping the profile avatar.
      endDrawer: const _AppDrawer(),
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
                sliver: const SliverToBoxAdapter(child: CompanyCarousel()),
              ),
              // Guard-only "Scan Visitor QR Pass" button (hidden for managers).
              const SliverToBoxAdapter(child: _ScanPassBar()),
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

/// Guard-only "Scan Visitor QR Pass" bar. Reads iUserType from prefs and only
/// renders when the user is a guard (iUserType == "1"); managers see nothing.
class _ScanPassBar extends StatefulWidget {
  const _ScanPassBar();

  @override
  State<_ScanPassBar> createState() => _ScanPassBarState();
}

class _ScanPassBarState extends State<_ScanPassBar> {
  bool _isGuard = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final iUserType = (prefs.getString('iUserType') ?? '').trim();
    if (!mounted) return;
    setState(() => _isGuard = iUserType == "1");
  }

  void _openScanner(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const ScanVisitorScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Managers (or before prefs load) -> nothing, no extra space.
    if (!_isGuard) return const SizedBox.shrink();

    final gutter = AppSpacing.gutter(context);

    return Padding(
      padding: EdgeInsets.fromLTRB(gutter, AppSpacing.lg, gutter, 0),
      child: Material(
        color: const Color(0xFF1F3A8A), // deep blue, like the mock
        borderRadius: BorderRadius.circular(AppRadii.xl),
        child: InkWell(
          onTap: () => _openScanner(context),
          borderRadius: BorderRadius.circular(AppRadii.xl),
          child: Container(
            height: 56,
            alignment: Alignment.center,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.qr_code_scanner_rounded,
                  color: Colors.white,
                  size: 22,
                ),
                const SizedBox(width: AppSpacing.md),
                Text(
                  'SCAN VISITOR QR PASS',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Right-side drawer with the logged-in user's name and a single Logout action.
class _AppDrawer extends StatefulWidget {
  const _AppDrawer();

  @override
  State<_AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<_AppDrawer> {
  String _name = '';
  String _contact = '';

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _name = prefs.getString('sUserName') ?? '';
      _contact = prefs.getString('sContactNo') ?? '';
    });
  }

  Future<void> _logout(BuildContext context) async {
    // Clear every stored value (login state, user info, etc.).
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (!context.mounted) return;

    // Go to the login screen and drop the whole back stack.
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    return Drawer(
      backgroundColor: AppColors.surface,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: avatar + name + contact.
            Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(
                      gradient: AppColors.brandGradientDeep,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.person_rounded,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _name.isEmpty ? 'Account' : _name,
                          style: t.titleMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (_contact.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            _contact,
                            style: t.bodySmall?.copyWith(color: AppColors.muted),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Logout — the only option.
            ListTile(
              leading: const Icon(Icons.logout_rounded, color: AppColors.brand),
              title: Text(
                'Logout',
                style: t.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              onTap: () => _logout(context),
            ),
          ],
        ),
      ),
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
        const Spacer(),
        // Bell -> opens the Notifications screen with a slow transition.
        _IconAction(
          icon: Icons.notifications_none_rounded,
          tooltip: 'Notifications',
          onTap: () => Navigator.of(context).push(NotificationScreen.route()),
        ),
        const SizedBox(width: AppSpacing.sm),
        // Profile avatar — tap to open the right-side drawer (Logout).
        // Builder gives a context under the Scaffold so openEndDrawer works.
        Builder(
          builder: (context) => GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => Scaffold.of(context).openEndDrawer(),
            child: Container(
              width: 38,
              height: 38,
              decoration: const BoxDecoration(
                gradient: AppColors.brandGradientDeep,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                'JW',
                style: t.titleSmall?.copyWith(
                  color: Colors.white,
                  fontSize: 13.5,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _IconAction extends StatelessWidget {
  const _IconAction({
    required this.icon,
    required this.tooltip,
    this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon, color: AppColors.ink, size: 23),
      tooltip: tooltip,
      visualDensity: VisualDensity.compact,
      onPressed: onTap ?? () {},
    );
  }
}

/// Four entry tiles. Switches to a single column on very narrow phones so
/// the labels never clip.
class _ActionGrid extends StatefulWidget {
  const _ActionGrid();

  @override
  State<_ActionGrid> createState() => _ActionGridState();
}

class _ActionGridState extends State<_ActionGrid> {
  // User type saved at login time ('iUserType'). Decides the first card.
  String _iUserType = '';

  // Single source of truth so the LABEL and the SCREEN always match:
  //   Guard    (iUserType == "1") -> "Today's List" + ExpectedGuestScreen
  //   Manager  (otherwise, "2")   -> "My Invites"   + InviteGuestListScreen (no change)
  bool get _isGuard => _iUserType == "1";

  @override
  void initState() {
    super.initState();
    _loadUserType();
  }

  Future<void> _loadUserType() async {
    final prefs = await SharedPreferences.getInstance();
    final value = (prefs.getString('iUserType') ?? '').trim();
    if (!mounted) return;
    setState(() => _iUserType = value);
  }

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
    // Small safety margin: the line-height assumptions above are exact only
    // for one specific font metrics table, so a hairline buffer keeps this
    // from clipping under slightly different font rendering.
    final extent = fixed + textBlock + 8;

    // First card title depends on the logged-in user type:
    //   Guard   (iUserType == "1") -> "Today's List"
    //   Manager (otherwise)        -> "My Invites"
    final firstTitle = _isGuard ? "Today's List" : 'My Invites';

    final tiles = [
      (Icons.person_add_alt_1_outlined, firstTitle, 'People you invited'),
      (Icons.verified_user_outlined, 'Gate Log', 'Guard entries'),
      (Icons.access_time_rounded, 'Yesterday', 'Past 24 hours'),
      (Icons.calendar_month_outlined, 'Monthly', 'This month'),
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
          onTap: () => _openTile(context, i, title),
        );
      }, childCount: tiles.length),
    );
  }

  /// Each entry tile opens its own list screen. They share one UI
  /// ([GuestListScreen]) but keep separate widgets + data sources, so each can
  /// be wired to a different REST endpoint independently.
  Future<void> _openTile(BuildContext context, int index, String title) async {
    Widget? screen;

    if (index == 0) {
      // Read the FRESH user type from SharedPreferences at tap time (not the
      // cached value), so the first card always routes by the real login value.
      final prefs = await SharedPreferences.getInstance();
      final iUserType = (prefs.getString('iUserType') ?? '').trim();
      if (!context.mounted) return;

      // Guard (iUserType == "1") -> Expected Guests screen
      // Manager (otherwise, "2") -> existing Invite guest list (no change)
      screen = iUserType == "1"
          ? const ExpectedGuestScreen()
          : const InviteGuestListScreen();
    } else {
      screen = switch (index) {
        1 => const InvitedByGuardScreen(),
        2 => const YesterdayGuestListScreen(),
        3 => const MonthGuestReportScreen(),
        _ => null,
      };
    }

    final next = screen;
    if (next == null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('$title — coming soon')));
      return;
    }

    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => next));
  }
}

class _AddGuestBar extends StatelessWidget {
  const _AddGuestBar({required this.gutter});

  final double gutter;

  /// Decides which flow the "Add Guest" button opens, based on the logged-in
  /// user's type saved at login time (SharedPreferences key 'iUserType').
  ///   iUserType == "1"  → Guard  → full-screen GuardInviteScreen
  ///   otherwise (e.g. "2" management) → the Invite() bottom sheet
  Future<void> _onAddGuest(BuildContext context) async {
    // Read the user type stored during login.
    final prefs = await SharedPreferences.getInstance();
    final iUserType = prefs.getString('iUserType') ?? '';
    if (!context.mounted) return;

    if (iUserType == "1") {
      // Guard → full-screen "Invite Setup" for a walk-in guest at the gate.
      Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const GuardInviteScreen()),
      );
    } else {
      // Management → the existing Invite bottom sheet.
      showInviteSetupSheet(context, Invite());
    }
  }

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
              onPressed: () => _onAddGuest(context),
            ),
          ),
        ),
      ),
    );
  }
}
