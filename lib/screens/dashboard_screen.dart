import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/invite.dart';
import '../services/vmsUpdateVisitorGsmid.dart';
import '../theme/tokens.dart';
import '../widgets/app_button.dart';
import '../widgets/app_card.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/company_carousel.dart';
import '../widgets/logout_dialog.dart';
import 'expected_guest_screen.dart';
import 'gate_log_screen.dart';
import 'invite_setup_sheet.dart';
import 'invite_guest_list_screen.dart';
import 'login_screen.dart';
import 'month_guest_list_screen.dart';
import 'notification_screen.dart';
import 'scan_visitor_screen.dart';
import 'yesterday_guest_list_screen.dart';

/// Screen 4 — home. Sponsored slot, four entry points, and the primary
/// "Add Guest" action that starts the invite flow.
///

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
                sliver: const SliverToBoxAdapter(child: CompanyCarousel()),
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

class _DashboardHeader extends StatefulWidget {
  const _DashboardHeader();

  @override
  State<_DashboardHeader> createState() => _DashboardHeaderState();
}

class _DashboardHeaderState extends State<_DashboardHeader> {
  String _name = ''; // sUserName from login
  String _contactNo = ''; // sContactNo from login
  bool _isGuard = false; // iUserType == "1"

  @override
  void initState() {
    super.initState();
    _setupPushNotifications();
    _load();
  }

  // firebase related code
  void _setupPushNotifications() async {
    final fcm = FirebaseMessaging.instance;
    final token = await fcm.getToken();
    print("-------69--------firebase token------$token");
    print("Token : $token");
    //updateGsmid(token);
    if(token!=null){
      updateGsmid(token);
    }
  }
  // FirebaseTokenApi
  updateGsmid(token) async {
    if (token != null) {
      print("--------106----xxx----$token");
      var UpdateGsmid = await VmsUpdateVisitorgsmid().vmsUpdateVisitorGsmid(
        context,
        token,
      );
      print("-------Update Gsmid Visitor-------70-----$UpdateGsmid");
    } else {}
  }


  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _name = (prefs.getString('sUserName') ?? '').trim();
      _contactNo = (prefs.getString('sContactNo') ?? '').trim();
      _isGuard = (prefs.getString('iUserType') ?? '').trim() == "1";
    });
  }

  // Logout icon tapped -> confirm, then clear prefs and go to login.
  Future<void> _onLogoutTap(BuildContext context) async {
    final confirmed = await showLogoutDialog(context);
    if (confirmed != true || !context.mounted) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    return Row(
      children: [
        // Left: login name + Guard/Mgmt group.
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _name.isEmpty ? 'Welcome' : _name,
                style: t.titleLarge?.copyWith(fontSize: 21),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                _contactNo,
                style: t.bodySmall?.copyWith(color: AppColors.muted),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        // Bell -> opens the Notifications screen with a slow transition.
        _IconAction(
          icon: Icons.notifications_none_rounded,
          tooltip: 'Notifications',
          onTap: () => Navigator.of(context).push(NotificationScreen.route()),
        ),
        // Guard-only: scan the visitor QR pass (opens the camera scanner).
        if (_isGuard)
          _IconAction(
            icon: Icons.qr_code_scanner_rounded,
            tooltip: 'Scan Visitor QR Pass',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const ScanVisitorScreen(),
              ),
            ),
          ),
        const SizedBox(width: AppSpacing.sm),
        // Logout icon — iOS-style tinted circle. Tap -> confirm dialog.
        _LogoutIconButton(onTap: () => _onLogoutTap(context)),
      ],
    );
  }
}

/// A soft, tinted circular logout button with comfortable iOS-style padding.
class _LogoutIconButton extends StatelessWidget {
  const _LogoutIconButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.brandTint,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        splashColor: AppColors.brand.withValues(alpha: 0.18),
        highlightColor: AppColors.brand.withValues(alpha: 0.08),
        child: const Padding(
          padding: EdgeInsets.all(10),
          child: Icon(Icons.logout_rounded, color: AppColors.brand, size: 21),
        ),
      ),
    );
  }
}

class _IconAction extends StatelessWidget {
  const _IconAction({required this.icon, required this.tooltip, this.onTap});

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
        1 => const GateLogScreen(),
        2 => const YesterdayGuestListScreen(),
        3 => const MonthGuestListScreen(),
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

  /// "Add Guest" opens the same invite bottom sheet for BOTH roles —
  /// guard (iUserType == "1") and management (iUserType == "2").
  void _onAddGuest(BuildContext context) {
    showInviteSetupSheet(context, Invite());
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
