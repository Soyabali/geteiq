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
  Future<void> _load() async {
    setState(() {
      _loading = true;
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
        _error = true;
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
    if (s.contains('checkout') ||
        s.contains('check-out') ||
        s.contains('check out')) {
      return GuestStage.checkout;
    }
    if (s.contains('checkin') ||
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

  List<ExpectedGuest> get _filtered {
    final q = _search.text.trim().toLowerCase();
    return _all.where((g) {
      final matchesQuery = q.isEmpty || g.searchText.contains(q);
      final matchesStage = _stageFilter == null || g.stage == _stageFilter;
      return matchesQuery && matchesStage;
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
          if (i >= 0) setState(() => _all[i] = guest.copyWith(stage: stage));
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

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        titleSpacing: gutter,
        leadingWidth: gutter + 32,
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
                        expected: _countOf(GuestStage.expected),
                        checkin: _countOf(GuestStage.checkin),
                        meeting: _countOf(GuestStage.meeting),
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
                              itemBuilder: (context, i) {
                                final g = rows[i];
                                return _GuestCard(
                                  guest: g,
                                  // Not arrived -> 4, Check-in -> 2,
                                  // Check-out -> 3
                                  onNotArrived: () => _updateStatus(
                                    g,
                                    GuardStatus.notArrived,
                                    stage: GuestStage.expected,
                                  ),
                                  onCheckIn: () => _updateStatus(
                                    g,
                                    GuardStatus.checkIn,
                                    stage: GuestStage.checkin,
                                  ),
                                  onCheckOut: () => _updateStatus(
                                    g,
                                    GuardStatus.checkOut,
                                    stage: GuestStage.checkout,
                                  ),
                                );
                              },
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
  });

  final int expected;
  final int checkin;
  final int meeting;
  final int checkout;
  final GuestStage? selected;
  final ValueChanged<GuestStage> onTap;

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

/// A single guest card with the three flow-action buttons.
class _GuestCard extends StatelessWidget {
  const _GuestCard({
    required this.guest,
    required this.onNotArrived,
    required this.onCheckIn,
    required this.onCheckOut,
  });

  final ExpectedGuest guest;
  final VoidCallback onNotArrived; // iStatus 4
  final VoidCallback onCheckIn; // iStatus 2
  final VoidCallback onCheckOut; // iStatus 3

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
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Status: ${guest.stage.label}',
                      style: t.bodySmall?.copyWith(
                        color: AppColors.faint,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              // Right lane — scan icon, 5dp off the card edge.
              const _ScanIconButton(),
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
  const _ScanIconButton();

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
      onPressed: () => Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const ScanVisitorScreen()),
      ),
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
