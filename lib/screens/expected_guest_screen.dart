import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/expected_guest.dart';
import '../models/guard_visitor.dart';
import '../services/VMSGaurdUpdateStatus.dart';
import '../services/VMSGaurdVisitorRequestList.dart';
import '../theme/tokens.dart';
import '../widgets/app_card.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/pill_search_field.dart';
import 'scan_visitor_screen.dart';

/// Tablet breakpoint. Phones (< 600) always render the original, untouched
/// single-column mobile list. Same convention as gate_log_screen.dart,
/// invite_guest_list_screen.dart and month_guest_list_screen.dart.
bool _isTablet(BuildContext context) => MediaQuery.sizeOf(context).width >= 600;

/// Landscape / large tablets get a 3-column guest grid; portrait-ish
/// tablets get 2.
bool _isWideTablet(BuildContext context) => MediaQuery.sizeOf(context).width >= 900;

/// Guard-side "Expected Guests" screen.
///
/// Search + 4 stage filters (Expected / Check-in / Meeting / Check-out) + a
/// list of guest cards. Data comes from the VMSGaurdVisitorRequestList API.


class ExpectedGuestScreen extends StatefulWidget {
  const ExpectedGuestScreen({super.key});

  @override
  State<ExpectedGuestScreen> createState() => _ExpectedGuestScreenState();
}

class _ExpectedGuestScreenState extends State<ExpectedGuestScreen> {
  final _search = TextEditingController();

  // Loaded from the API; kept mutable so the action buttons can change a
  // guest's stage locally.
  List<ExpectedGuest> _all = [];
  bool _loading = true; // spinner while the API call runs
  bool _error = false; // network / server error

  // null = show all; otherwise only guests in this stage.
  GuestStage? _stageFilter;

  @override
  void initState() {
    super.initState();
    _load();
  }

  // Calls the API and maps the response into the UI model.
  //
  /// [silent] keeps the current list on screen instead of swapping it for the
  /// full-screen spinner — used when refreshing after the QR scanner checked
  /// a guest in, so the list updates in place without a visible flash.
  Future<void> _load({bool silent = false}) async {
    setState(() {
      _loading = !silent;
      _error = false;
    });
    try {
      final list = await GuardVisitorRepo().getVisitorList(context);
      if (!mounted) return;
      setState(() {
        _all = list.map(_mapToExpected).toList();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        // A silent refresh keeps whatever is already on screen. Blanking the
        // list for the full-screen error here would read as "the check-in
        // failed" when in fact it succeeded and only this re-fetch didn't.
        if (!silent) _error = true;
      });
    }
  }

  // Maps one API row -> the card's UI model.
  ExpectedGuest _mapToExpected(GuardVisitor v) {
    // sGuestNames may be a comma list -> the "+N" badge beside the name.
    final names = v.guestNames
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    final plus = names.length > 1 ? names.length - 1 : 0;

    return ExpectedGuest(
      qrCodeVal: v.qrCodeVal, // sQRCodeVal -> sent to the status-update api
      name: v.guestNames, // sGuestNames -> card name (top line)
      plus: plus,
      requestedBy: v.userName, // sUserName -> "RequestedBy :" line
      // phone: not returned by this API -> left empty. // TODO: change if added
      when: _formatWhen(v.date, v.time), // dDate + dTime
      duration: v.validHours.isEmpty ? '—' : v.validHours, // iValidHours
      note: v.note.isEmpty ? '—' : v.note, // sNote
      stage: _stageFromStatus(v.status), // sStatus -> stage
      statusText: v.status.isEmpty ? '—' : v.status, // sStatus -> shown as-is
      checkedIn: v.checkedIn, // dCheckedIn  ('' while null)
      checkedOut: v.checkedOut, // dCheckedOut ('' while null)
    );
  }

  // "2026-07-24" + "18:00:00" -> "24 Jul 2026 · 6:00 PM"
  String _formatWhen(String date, String time) {
    try {
      final dt = DateTime.parse('$date $time');
      return DateFormat('d MMM yyyy · h:mm a').format(dt);
    } catch (_) {
      return '$date $time'.trim();
    }
  }

  // sStatus text -> GuestStage (drives the highlighted action button + counts).
  GuestStage _stageFromStatus(String status) {
    final s = status.toLowerCase();
    // Matches "Checked Out", "Check-out", "Check out", "Checkout", etc.
    if (s.contains('checked out') ||
        s.contains('checkout') ||
        s.contains('check-out') ||
        s.contains('check out')) {
      return GuestStage.checkout;
    }
    // Matches "Checked In", "Check-in", "Check in", "Checkin", etc.
    if (s.contains('checked in') ||
        s.contains('checkin') ||
        s.contains('check-in') ||
        s.contains('check in')) {
      return GuestStage.checkin;
    }
    if (s.contains('meeting')) return GuestStage.meeting;
    // "Pending" / anything else -> expected.
    return GuestStage.expected;
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  int _countOf(GuestStage stage) => _all.where((g) => g.stage == stage).length;

  // Guests currently on the premises: checked in and not yet checked out.
  // There is no separate "start meeting" action in the guard flow, so
  // Check-in and Meeting always show — and filter to — this same set; a
  // Check-out immediately removes the guest from both.
  int get _onPremisesCount => _all
      .where(
        (g) => g.stage == GuestStage.checkin || g.stage == GuestStage.meeting,
      )
      .length;

  // Still-to-arrive guests: total roster minus everyone who has already
  // checked in (on premises) or checked out. A guest only re-enters this
  // count via the "Not arrived" button, which resets their stage back to
  // expected.
  int get _expectedCount => _countOf(GuestStage.expected);

  bool _matchesStageFilter(ExpectedGuest g) {
    final f = _stageFilter;
    if (f == null) return true;
    if (f == GuestStage.checkin || f == GuestStage.meeting) {
      return g.stage == GuestStage.checkin || g.stage == GuestStage.meeting;
    }
    return g.stage == f; // expected / checkout
  }

  List<ExpectedGuest> get _filtered {
    final q = _search.text.trim().toLowerCase();
    return _all.where((g) {
      final matchesQuery = q.isEmpty || g.searchText.contains(q);
      return matchesQuery && _matchesStageFilter(g);
    }).toList();
  }

  void _toggleFilter(GuestStage stage) {
    setState(() => _stageFilter = _stageFilter == stage ? null : stage);
  }

  /// Pushes a new status to the backend, then reflects it on the card.
  ///
  /// [stage] is the local UI stage to move the card into once the API says
  /// OK; it is null for "Approved", which is a badge action and does not
  /// change which flow button is highlighted.
  Future<void> _updateStatus(
    ExpectedGuest guest,
    GuardStatus status, {
    GuestStage? stage,
  }) async {
    // No pass id -> nothing the backend can match on.
    if (guest.qrCodeVal.isEmpty) {
      _toast('No QR code on this pass.', ok: false);
      return;
    }

    try {
      final res = await GuardUpdateStatusRepo().updateStatus(
        context,
        guest.qrCodeVal,
        status,
      );
      if (!mounted) return;

      final result = "${res['Result']}";
      final msg = "${res['Msg']}";

      if (result == "1") {
        // Success -> move the card into its new stage locally so the guard
        // sees the change without a full reload.
        if (stage != null) {
          final i = _all.indexOf(guest);
          if (i >= 0) {
            setState(
              () => _all[i] = guest.copyWith(
                stage: stage,
                statusText: status.label,
              ),
            );
          }
        }
        _toast(msg.isEmpty ? '${status.label} updated' : msg, ok: true);
      } else {
        _toast(msg.isEmpty ? 'Could not update the status.' : msg, ok: false);
      }
    } catch (e) {
      if (!mounted) return;
      _toast('Something went wrong. Please try again.', ok: false);
    }
  }

  /// Floating, rounded toast in the app's brand colours.
  void _toast(String message, {required bool ok}) {
    final gutter = AppSpacing.gutter(context);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: ok ? AppColors.success : AppColors.danger,
          elevation: 6,
          duration: const Duration(seconds: 2),
          margin: EdgeInsets.fromLTRB(
            gutter,
            0,
            gutter,
            AppSpacing.lg,
          ),
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
                ok
                    ? Icons.check_circle_rounded
                    : Icons.error_outline_rounded,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  message,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final gutter = AppSpacing.gutter(context);
    final rows = _filtered;
    final isTablet = _isTablet(context);

    // The scanner checked a guest in on the server, so pull the list again
    // to pick up their new stage / status / checked-in time. Silent, so the
    // list updates in place instead of flashing the full-screen spinner.
    void onScanCheckedIn() => _load(silent: true);

    // Not arrived -> 4, Check-in -> 2, Check-out -> 3 — same handlers for
    // every layout, just wired up once here.
    Widget guestCard(ExpectedGuest g) => _GuestCard(
      guest: g,
      onNotArrived: () => _updateStatus(
        g,
        GuardStatus.notArrived,
        stage: GuestStage.expected,
      ),
      onCheckIn: () =>
          _updateStatus(g, GuardStatus.checkIn, stage: GuestStage.checkin),
      onCheckOut: () =>
          _updateStatus(g, GuardStatus.checkOut, stage: GuestStage.checkout),
      onScanCheckedIn: onScanCheckedIn,
    );

    // Tablet-only card: same data and the exact same three handlers, just a
    // single polished card instead of mobile's two-card stack.
    Widget tabletGuestCard(ExpectedGuest g) => _TabletGuestCard(
      guest: g,
      onNotArrived: () => _updateStatus(
        g,
        GuardStatus.notArrived,
        stage: GuestStage.expected,
      ),
      onCheckIn: () =>
          _updateStatus(g, GuardStatus.checkIn, stage: GuestStage.checkin),
      onCheckOut: () =>
          _updateStatus(g, GuardStatus.checkOut, stage: GuestStage.checkout),
      onScanCheckedIn: onScanCheckedIn,
    );

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        titleSpacing: gutter,
        leadingWidth: gutter + 32,
        centerTitle: true,
        leading: Navigator.of(context).canPop()
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                onPressed: () => Navigator.of(context).maybePop(),
              )
            : null,
        title: const Text('Expected Guests'),
      ),
      body: SafeArea(
        bottom: false,
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.brand),
              )
            : _error
            ? _ErrorState(onRetry: _load)
            : isTablet
            ? Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1120),
                  child: Column(
                    children: [
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                          gutter,
                          AppSpacing.md,
                          gutter,
                          AppSpacing.lg,
                        ),
                        child: PillSearchField(
                          controller: _search,
                          hint: 'Search',
                          onChanged: () => setState(() {}),
                        ),
                      ),

                      // One row of 4 stage filter tiles — there's room for it
                      // on a tablet, instead of a 2x2 square.
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: gutter),
                        child: _StatGrid(
                          expected: _expectedCount,
                          checkin: _onPremisesCount,
                          meeting: _onPremisesCount,
                          checkout: _countOf(GuestStage.checkout),
                          selected: _stageFilter,
                          onTap: _toggleFilter,
                          singleRow: true,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      Expanded(
                        child: rows.isEmpty
                            ? const _Empty()
                            : _ExpectedGuestGrid(
                                rows: rows,
                                gutter: gutter,
                                cardBuilder: tabletGuestCard,
                              ),
                      ),
                    ],
                  ),
                ),
              )
            : CenteredFill(
                child: Column(
                  children: [
                    // Search
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        gutter,
                        AppSpacing.xs,
                        gutter,
                        AppSpacing.md,
                      ),
                      child: PillSearchField(
                        controller: _search,
                        hint: 'Search',
                        onChanged: () => setState(() {}),
                      ),
                    ),

                    // 2 x 2 stage filter tiles
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: gutter),
                      child: _StatGrid(
                        expected: _expectedCount,
                        checkin: _onPremisesCount,
                        meeting: _onPremisesCount,
                        checkout: _countOf(GuestStage.checkout),
                        selected: _stageFilter,
                        onTap: _toggleFilter,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Guest list
                    Expanded(
                      child: rows.isEmpty
                          ? const _Empty()
                          : ListView.separated(
                              physics: const BouncingScrollPhysics(
                                parent: AlwaysScrollableScrollPhysics(),
                              ),
                              padding: EdgeInsets.fromLTRB(
                                gutter,
                                AppSpacing.xs,
                                gutter,
                                AppSpacing.xxl,
                              ),
                              itemCount: rows.length,
                              // Wider than the gap inside a guest's own two
                              // cards, so each pair still reads as one entry.
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: AppSpacing.xl),
                              itemBuilder: (context, i) => guestCard(rows[i]),
                            ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

/// The 2×2 grid of tappable stat / filter tiles.
class _StatGrid extends StatelessWidget {
  const _StatGrid({
    required this.expected,
    required this.checkin,
    required this.meeting,
    required this.checkout,
    required this.selected,
    required this.onTap,
    this.singleRow = false,
  });

  final int expected;
  final int checkin;
  final int meeting;
  final int checkout;
  final GuestStage? selected;
  final ValueChanged<GuestStage> onTap;

  /// Tablet-only: lay all 4 tiles out in one row instead of a 2x2 square,
  /// since there's width to spare. Mobile always passes false (the default),
  /// so its layout is untouched.
  final bool singleRow;

  @override
  Widget build(BuildContext context) {
    Widget cell(GuestStage stage, int count) => Expanded(
      child: _StatBox(
        count: count,
        label: stage.label,
        active: selected == stage,
        onTap: () => onTap(stage),
      ),
    );

    if (singleRow) {
      return Row(
        children: [
          cell(GuestStage.expected, expected),
          const SizedBox(width: AppSpacing.md),
          cell(GuestStage.checkin, checkin),
          const SizedBox(width: AppSpacing.md),
          cell(GuestStage.meeting, meeting),
          const SizedBox(width: AppSpacing.md),
          cell(GuestStage.checkout, checkout),
        ],
      );
    }

    return Column(
      children: [
        Row(
          children: [
            cell(GuestStage.expected, expected),
            const SizedBox(width: AppSpacing.md),
            cell(GuestStage.checkin, checkin),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            cell(GuestStage.meeting, meeting),
            const SizedBox(width: AppSpacing.md),
            cell(GuestStage.checkout, checkout),
          ],
        ),
      ],
    );
  }
}

class _StatBox extends StatelessWidget {
  const _StatBox({
    required this.count,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final int count;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      decoration: BoxDecoration(
        color: active ? AppColors.brandTint : AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(
          color: active ? AppColors.brand : AppColors.borderSoft,
          width: active ? 1.4 : 1,
        ),
        boxShadow: active ? null : AppShadows.card,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadii.lg),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$count',
                  style: t.titleLarge?.copyWith(
                    fontSize: 22,
                    color: active ? AppColors.brandDeep : AppColors.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: t.bodySmall?.copyWith(
                    color: active ? AppColors.brandDeep : AppColors.muted,
                    fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Tablet grid — 2 columns on portrait/medium tablets, 3 on wide landscape,
/// so the list actually uses the extra width instead of floating a single
/// phone-width column in the middle of the screen. A Wrap of fixed-width
/// items (not a fixed-extent GridView), since each [_GuestCard] is itself a
/// two-card stack whose total height varies with content — same approach as
/// the Gate Log / Invite Guest List / Month Guest List tablet grids.
class _ExpectedGuestGrid extends StatelessWidget {
  const _ExpectedGuestGrid({
    required this.rows,
    required this.gutter,
    required this.cardBuilder,
  });

  final List<ExpectedGuest> rows;
  final double gutter;
  final Widget Function(ExpectedGuest) cardBuilder;

  @override
  Widget build(BuildContext context) {
    final crossAxisCount = _isWideTablet(context) ? 3 : 2;
    const spacing = AppSpacing.xl;

    return LayoutBuilder(
      builder: (context, constraints) {
        final available = constraints.maxWidth - gutter * 2;
        final cardWidth =
            (available - spacing * (crossAxisCount - 1)) / crossAxisCount;

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          padding: EdgeInsets.fromLTRB(
            gutter,
            AppSpacing.xs,
            gutter,
            AppSpacing.xxl,
          ),
          child: Wrap(
            spacing: spacing,
            runSpacing: spacing,
            children: [
              for (final g in rows)
                SizedBox(width: cardWidth, child: cardBuilder(g)),
            ],
          ),
        );
      },
    );
  }
}

/// Tablet-only guest card — the same data and three flow actions as
/// [_GuestCard], reassembled as one polished card (avatar, aligned meta
/// rows, actions built in) instead of mobile's two stacked cards. No new
/// fields, no new logic — [_updateStatus] and the API calls behind it are
/// untouched; this only changes how the same data is presented on tablet.
class _TabletGuestCard extends StatelessWidget {
  const _TabletGuestCard({
    required this.guest,
    required this.onNotArrived,
    required this.onCheckIn,
    required this.onCheckOut,
    required this.onScanCheckedIn,
  });

  final ExpectedGuest guest;
  final VoidCallback onNotArrived;
  final VoidCallback onCheckIn;
  final VoidCallback onCheckOut;

  /// Fired after the QR scanner's "Done" status API succeeded, so the list
  /// can be refreshed.
  final VoidCallback onScanCheckedIn;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ---- Header: avatar, name (+N), scan icon ----
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _InitialsAvatar(name: guest.name),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            guest.name,
                            style: t.titleMedium?.copyWith(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (guest.plus > 0) ...[
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            '+${guest.plus}',
                            style: t.titleSmall?.copyWith(
                              color: AppColors.brand,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      guest.when,
                      style: t.bodySmall?.copyWith(color: AppColors.muted),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              _ScanIconButton(onCheckedIn: onScanCheckedIn),
            ],
          ),

          const SizedBox(height: AppSpacing.lg),
          const Divider(height: 1, color: AppColors.borderSoft),
          const SizedBox(height: AppSpacing.md),

          // ---- Aligned meta rows — same 7 fields as the mobile card ----
          _TabletMetaLine(
            label: 'Requested By',
            value: guest.requestedBy.isEmpty ? '—' : guest.requestedBy,
          ),
          _TabletMetaLine(label: 'Date / Time', value: guest.when),
          _TabletMetaLine(label: 'Duration', value: guest.duration),
          _TabletMetaLine(label: 'Note', value: guest.note),
          _TabletMetaLine(label: 'Status', value: guest.statusText),
          _TabletMetaLine(
            label: 'Checked In',
            value: guest.checkedIn.isEmpty ? '—' : guest.checkedIn,
          ),
          _TabletMetaLine(
            label: 'Checked Out',
            value: guest.checkedOut.isEmpty ? '—' : guest.checkedOut,
          ),

          const SizedBox(height: AppSpacing.lg),

          // ---- The three flow actions, built into the same card ----
          Row(
            children: [
              Expanded(
                child: _ActBtn(
                  label: 'Not arrived',
                  active: guest.stage == GuestStage.expected,
                  onTap: onNotArrived,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _ActBtn(
                  label: 'Check-in',
                  active:
                      guest.stage == GuestStage.checkin ||
                      guest.stage == GuestStage.meeting,
                  onTap: onCheckIn,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _ActBtn(
                  label: 'Check-out',
                  active: guest.stage == GuestStage.checkout,
                  onTap: onCheckOut,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Brand-tinted initials circle, matching the avatar language already used
/// on the dashboard and Select Guests screens.
class _InitialsAvatar extends StatelessWidget {
  const _InitialsAvatar({required this.name});

  final String name;

  String get _initials {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 46,
      decoration: const BoxDecoration(
        color: AppColors.brandTint,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        _initials,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: AppColors.brand,
          fontSize: 15,
        ),
      ),
    );
  }
}

/// Aligned "Label : value" row for the tablet guest card — same idea as the
/// _LogRow used on the Gate Log / Month / Yesterday tablet cards, so every
/// colon lines up regardless of label length.
class _TabletMetaLine extends StatelessWidget {
  const _TabletMetaLine({required this.label, required this.value});

  final String label;
  final String value;

  static const double _labelWidth = 104;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final labelStyle = t.bodySmall?.copyWith(color: AppColors.faint);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: _labelWidth, child: Text(label, style: labelStyle)),
          Text(':', style: labelStyle),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              value,
              style: t.bodySmall?.copyWith(
                color: AppColors.inkSoft,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

/// A single guest card with the three flow-action buttons.
class _GuestCard extends StatelessWidget {
  const _GuestCard({
    required this.guest,
    required this.onNotArrived,
    required this.onCheckIn,
    required this.onCheckOut,
    required this.onScanCheckedIn,
  });

  final ExpectedGuest guest;
  final VoidCallback onNotArrived; // iStatus 4
  final VoidCallback onCheckIn; // iStatus 2
  final VoidCallback onCheckOut; // iStatus 3

  /// Fired after the QR scanner's "Done" status API succeeded, so the list
  /// can be refreshed.
  final VoidCallback onScanCheckedIn;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ---- Card 1: details. Two lanes — text on the left, badge + scan
        // icon on the right, so the icon no longer adds height of its own
        // (that was the empty gap under the name).
        AppCard(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            5,
            AppSpacing.sm,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left lane — takes almost the full width.
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            guest.name,
                            style: t.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (guest.plus > 0) ...[
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            '+${guest.plus}',
                            style: t.titleSmall?.copyWith(
                              color: AppColors.brand,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _MetaLine(
                      label: 'RequestedBy :',
                      value: guest.requestedBy.isEmpty
                          ? '—'
                          : guest.requestedBy,
                    ),
                    _MetaLine(label: 'Date / Time:', value: guest.when),
                    _MetaLine(
                      label: 'Meeting duration:',
                      value: guest.duration,
                    ),
                    _MetaLine(label: 'Note:', value: guest.note),
                    _MetaLine(label: 'Status:', value: guest.statusText),
                    // dCheckedIn / dCheckedOut — null until the guard acts on
                    // the pass, which the model maps to '' (blank value).
                    _MetaLine(label: 'Checked In:', value: guest.checkedIn),
                    _MetaLine(label: 'Checked Out:', value: guest.checkedOut),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              // Right lane — scan icon, 5dp off the card edge.
              _ScanIconButton(onCheckedIn: onScanCheckedIn),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xs),

        // ---- Card 2: the three flow actions (same handlers as before).
        AppCard(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Expanded(
                child: _ActBtn(
                  label: 'Not arrived',
                  active: guest.stage == GuestStage.expected,
                  onTap: onNotArrived,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _ActBtn(
                  label: 'Check-in',
                  active:
                      guest.stage == GuestStage.checkin ||
                      guest.stage == GuestStage.meeting,
                  onTap: onCheckIn,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _ActBtn(
                  label: 'Check-out',
                  active: guest.stage == GuestStage.checkout,
                  onTap: onCheckOut,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// One "Label: value" row inside a guest card.
class _MetaLine extends StatelessWidget {
  const _MetaLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Text.rich(
        TextSpan(
          style: t.bodySmall?.copyWith(color: AppColors.inkSoft),
          children: [
            TextSpan(
              text: '$label ',
              style: t.bodySmall?.copyWith(color: AppColors.faint),
            ),
            TextSpan(text: value),
          ],
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

/// Same icon + same action as the AppBar scan button on the dashboard
/// ([DashboardScreen]'s guard-only "Scan Visitor QR Pass" icon) — opens the
/// camera to scan a visitor's QR/barcode pass, just placed on the card here
/// instead of the AppBar.
class _ScanIconButton extends StatelessWidget {
  const _ScanIconButton({required this.onCheckedIn});

  /// Called when the scanner popped after its "Done" status API succeeded,
  /// so this screen can pull the list again and show the new stage/status.
  final VoidCallback onCheckedIn;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(
        Icons.qr_code_scanner_rounded,
        color: AppColors.ink,
        size: 28,
      ),
      tooltip: 'Scan Visitor QR Pass',
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      // Keeps the glyph at least 25dp on every side without the default
      // 48dp IconButton box pushing the card wider.
      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
      onPressed: () async {
        // ScanVisitorScreen pops `true` only after its check-in API replied
        // Result == "1"; anything else (plain back, failed call) leaves the
        // list alone.
        final checkedIn = await Navigator.of(context).push<bool>(
          MaterialPageRoute<bool>(builder: (_) => const ScanVisitorScreen()),
        );
        if (checkedIn == true && context.mounted) onCheckedIn();
      },
    );
  }
}

/// One of the three flow-action buttons. Filled (brand) when it is the
/// guest's current stage, otherwise a soft outlined pill.
class _ActBtn extends StatelessWidget {
  const _ActBtn({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    return Material(
      color: active ? AppColors.brand : AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadii.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.md),
        child: Container(
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.md),
            border: Border.all(
              color: active ? AppColors.brand : AppColors.border,
            ),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              maxLines: 1,
              style: t.titleSmall?.copyWith(
                fontSize: 13,
                color: active ? Colors.white : AppColors.inkSoft,
                fontWeight: active ? FontWeight.w700 : FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Network / server error state with a retry button.
class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.wifi_off_rounded,
              size: 44,
              color: AppColors.faint,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              "Couldn't load the visitor list.",
              style: t.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            TextButton(
              onPressed: onRetry,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.brand,
                textStyle: t.titleSmall,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Empty state when search / filter yields nothing.
class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xxxl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.people_outline_rounded,
            size: 44,
            color: AppColors.faint,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'No guests found',
            style: t.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
