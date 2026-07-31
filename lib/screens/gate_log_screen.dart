import 'package:flutter/material.dart';

import '../models/gate_entry.dart';
import '../services/GateEntryRepo.dart';
import '../services/VMSVisitorAppStatus.dart';
import '../theme/tokens.dart';
import '../widgets/app_card.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/pill_search_field.dart';

/// Tablet breakpoint. Phones (< 600) always render the original, untouched
/// single-column mobile list. Mirrors the same helper in
/// invite_guest_list_screen.dart so both list screens share one convention.
bool _isTablet(BuildContext context) => MediaQuery.sizeOf(context).width >= 600;

/// Landscape / large tablets get a 3-column grid; portrait-ish tablets get 2.
bool _isWideTablet(BuildContext context) => MediaQuery.sizeOf(context).width >= 900;

/// "Gate Log" — guests the guard logged at the gate.
///
/// Role-driven, from [GateEntryRepo]:
///
/// | `iUserType` | API | Card actions |
/// |---|---|---|
/// | `"1"` guard | `VisitorEntryByGaurd` | read-only `sAppRejStatus` chip |
/// | else, management | `EntryByGaurd` | Approve / Reject buttons |
class GateLogScreen extends StatefulWidget {
  const GateLogScreen({super.key});

  @override
  State<GateLogScreen> createState() => _GateLogScreenState();
}

class _GateLogScreenState extends State<GateLogScreen> {
  final _search = TextEditingController();

  List<GateEntry> _all = [];
  bool _isGuard = false; // iUserType == "1" -> hide the action buttons
  bool _loading = true;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  // ==========================================================================
  //  DATA
  // ==========================================================================

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = false;
    });
    try {
      final repo = GateEntryRepo();
      // Fetch first, so `context` is used before any await. The repo picks the
      // guard / management endpoint itself; we only re-read the same flag to
      // decide what the card renders.
      final rows = await repo.getGateEntries(context);
      if (!mounted) return;
      final isGuard = await repo.isGuard();
      if (!mounted) return;
      setState(() {
        _all = rows;
        _isGuard = isGuard;
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

  List<GateEntry> get _filtered {
    final q = _search.text.trim().toLowerCase();
    if (q.isEmpty) return _all;
    return _all.where((g) => g.searchText.contains(q)).toList();
  }

  /// Management only. Approve / Reject -> VMSVisitorAppStatus API.
  ///
  /// Sends the tapped entry's `sQRCodeVal` plus `iStatus` (Approved -> "1",
  /// Rejected -> "2"), then toasts whatever "Msg" the API replied with. The
  /// card only flips to the new decision once the API confirms it
  /// ("Result" == "1") — a failed call leaves the card as it was.
  Future<void> _onDecision(GateEntry entry, GateDecision decision) async {
    final i = _all.indexOf(entry);
    if (i < 0) return;

    final status = decision == GateDecision.approved
        ? VisitorAppStatus.approved
        : VisitorAppStatus.rejected;

    try {
      final map = await VmsVisitorAppStatusRepo().updateStatus(
        context,
        entry.qrCodeVal, // sQRCodeVal
        status,
      );
      if (!mounted) return;

      // Toast — just the API's own message, whatever it says.
      final msg = '${map['Msg'] ?? ''}';
      if (msg.isNotEmpty) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(msg)));
      }

      // "Result": "1" -> accepted, update the card. Anything else -> leave it.
      if ("${map['Result']}" == "1") {
        setState(() => _all[i] = _all[i].copyWith(decision: decision));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('Something went wrong')));
    }
  }

  // ==========================================================================
  //  UI
  // ==========================================================================

  @override
  Widget build(BuildContext context) {
    final gutter = AppSpacing.gutter(context);
    final rows = _filtered;
    final isTablet = _isTablet(context);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        titleSpacing: gutter,
        leadingWidth: gutter + 32,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text('Gate Log'),
      ),
      body: SafeArea(
        bottom: false,
        child: isTablet
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
                          hint: 'Search guard guests',
                          onChanged: () => setState(() {}),
                        ),
                      ),
                      Expanded(child: _body(rows, gutter)),
                    ],
                  ),
                ),
              )
            : CenteredFill(
                child: Column(
                  children: [
                    // ---- Search ----
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        gutter,
                        AppSpacing.xs,
                        gutter,
                        AppSpacing.sm,
                      ),
                      child: PillSearchField(
                        controller: _search,
                        hint: 'Search guard guests',
                        onChanged: () => setState(() {}),
                      ),
                    ),

                    // ---- List ----
                    Expanded(child: _body(rows, gutter)),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _body(List<GateEntry> rows, double gutter) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.brand),
      );
    }
    if (_error) {
      return _ListMessage(
        icon: Icons.wifi_off_rounded,
        message: "Couldn't load the gate log.",
        onRetry: _load,
      );
    }
    if (rows.isEmpty) {
      return _ListMessage(
        icon: Icons.shield_outlined,
        message: _search.text.trim().isEmpty
            ? 'No Data'
            : 'No guests match "${_search.text.trim()}"',
      );
    }

    if (_isTablet(context)) {
      return _GateLogGrid(
        rows: rows,
        gutter: gutter,
        isGuard: _isGuard,
        onApprove: (g) => _onDecision(g, GateDecision.approved),
        onReject: (g) => _onDecision(g, GateDecision.rejected),
      );
    }

    return ListView.separated(
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      padding: EdgeInsets.fromLTRB(
        gutter,
        AppSpacing.sm,
        gutter,
        AppSpacing.xxl,
      ),
      itemCount: rows.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (context, i) {
        final g = rows[i];
        return _GateLogCard(
          entry: g,
          isGuard: _isGuard,
          onApprove: () => _onDecision(g, GateDecision.approved),
          onReject: () => _onDecision(g, GateDecision.rejected),
        );
      },
    );
  }
}

// ============================================================================
//  TABLET GRID
// ============================================================================

/// Tablet grid — 2 columns on portrait/medium tablets, 3 on wide landscape,
/// so the list actually uses the extra width instead of floating a single
/// phone-width column in the middle of the screen. Same approach as the
/// Invite Guest List tablet grid: a Wrap of fixed-width cards rather than a
/// fixed-extent GridView, since card height varies (the "Note" row only
/// shows up sometimes), so each card keeps its own natural height.
class _GateLogGrid extends StatelessWidget {
  const _GateLogGrid({
    required this.rows,
    required this.gutter,
    required this.isGuard,
    required this.onApprove,
    required this.onReject,
  });

  final List<GateEntry> rows;
  final double gutter;
  final bool isGuard;
  final ValueChanged<GateEntry> onApprove;
  final ValueChanged<GateEntry> onReject;

  @override
  Widget build(BuildContext context) {
    final crossAxisCount = _isWideTablet(context) ? 3 : 2;
    const spacing = AppSpacing.md;

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
            AppSpacing.sm,
            gutter,
            AppSpacing.xxl,
          ),
          child: Wrap(
            spacing: spacing,
            runSpacing: spacing,
            children: [
              for (final g in rows)
                SizedBox(
                  width: cardWidth,
                  child: _GateLogCard(
                    entry: g,
                    isGuard: isGuard,
                    onApprove: () => onApprove(g),
                    onReject: () => onReject(g),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

// ============================================================================
//  CARD
// ============================================================================

class _GateLogCard extends StatelessWidget {
  const _GateLogCard({
    required this.entry,
    required this.isGuard,
    required this.onApprove,
    required this.onReject,
  });

  final GateEntry entry;

  /// Guard -> read-only chip. Management -> Approve / Reject buttons.
  final bool isGuard;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    final name = entry.plus > 0
        ? '${entry.primaryName}  +${entry.plus}'
        : entry.primaryName;

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ---- Detail rows ----
          // Labels are passed WITHOUT the ":" — _LogRow draws it in its own
          // fixed column so every colon lines up vertically down the card.
          _LogRow(label: 'Guest Name', value: name),
          const _RowDivider(),
          _LogRow(label: 'Date', value: entry.dateTime),
          const _RowDivider(),
          _LogRow(
            label: 'Duration',
            value: entry.validHours.isEmpty ? '—' : entry.validHours,
          ),
          const _RowDivider(),
          _LogRow(
            label: 'Meet With',
            value: entry.userName.isEmpty ? '—' : entry.userName,
          ),
          if (entry.note.isNotEmpty) ...[
            const _RowDivider(),
            _LogRow(label: 'Note', value: entry.note),
          ],

          const SizedBox(height: AppSpacing.md),

          // ---- Footer: chip (guard) OR the two buttons (management) ----
          if (isGuard)
            Align(
              alignment: Alignment.centerLeft,
              child: _StatusChip(decision: entry.decision),
            )
          else
            Row(
              children: [
                Expanded(
                  child: _DecisionButton(
                    label: entry.decision == GateDecision.approved
                        ? 'Approved'
                        : 'Approve',
                    color: AppColors.success,
                    active: entry.decision == GateDecision.approved,
                    onTap: onApprove,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _DecisionButton(
                    label: entry.decision == GateDecision.rejected
                        ? 'Rejected'
                        : 'Reject',
                    color: AppColors.danger,
                    active: entry.decision == GateDecision.rejected,
                    onTap: onReject,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

/// Read-only `sAppRejStatus` pill — the guard's view of the decision.
class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.decision});

  final GateDecision decision;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: decision.background,
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Text(
        decision.label,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          fontSize: 13,
          color: decision.foreground,
          fontWeight: FontWeight.w700,
          letterSpacing: 0,
        ),
      ),
    );
  }
}

/// One half of the management Approve / Reject pair. Filled in its own colour
/// once chosen, otherwise a soft outlined pill.
class _DecisionButton extends StatelessWidget {
  const _DecisionButton({
    required this.label,
    required this.color,
    required this.active,
    required this.onTap,
  });

  final String label;
  final Color color;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    return Material(
      color: active ? color : AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadii.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.md),
        child: Container(
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.md),
            border: Border.all(color: active ? color : AppColors.border),
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

// ============================================================================
//  SMALL PIECES
// ============================================================================

/// A "Label : value" row inside a card.
///
/// [label] is passed WITHOUT its colon. The label sits in a fixed-width box
/// and the ":" is drawn as its own widget right after it, so the colons of
/// every row land on the same vertical line no matter how long the label is.
class _LogRow extends StatelessWidget {
  const _LogRow({required this.label, required this.value});

  final String label;
  final String value;

  /// Width of the label column — sized for the longest label on this card
  /// ("Duration"), which is what fixes the colon's x position.
  static const double _labelWidth = 96;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final labelStyle = t.bodyMedium?.copyWith(color: AppColors.muted);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: _labelWidth,
            child: Text(label, style: labelStyle),
          ),
          // The shared colon column.
          Text(':', style: labelStyle),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              value,
              style: t.bodyMedium?.copyWith(
                color: AppColors.ink,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RowDivider extends StatelessWidget {
  const _RowDivider();

  @override
  Widget build(BuildContext context) =>
      const Divider(height: 1, color: AppColors.borderSoft);
}

/// Full-height centred message for the empty / error states.
class _ListMessage extends StatelessWidget {
  const _ListMessage({
    required this.icon,
    required this.message,
    this.onRetry,
  });

  final IconData icon;
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 44, color: AppColors.faint),
            const SizedBox(height: AppSpacing.md),
            Text(message, textAlign: TextAlign.center, style: t.bodyMedium),
            if (onRetry != null) ...[
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
          ],
        ),
      ),
    );
  }
}
