import 'package:flutter/material.dart';

import '../models/gate_log.dart';
import '../theme/tokens.dart';
import '../widgets/app_card.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/pill_search_field.dart';

/// "Gate Log" — guests invited by the guard. Search, then approve or reject.
///
/// Static data for now ([kGateLogDemo]); swap for an API list later.
class GateLogScreen extends StatefulWidget {
  const GateLogScreen({super.key});

  @override
  State<GateLogScreen> createState() => _GateLogScreenState();
}

class _GateLogScreenState extends State<GateLogScreen> {
  final _search = TextEditingController();

  // Mutable copy so the approve / reject decisions stick.
  late final List<GateLogEntry> _all = List.of(kGateLogDemo);

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<GateLogEntry> get _filtered {
    final q = _search.text.trim().toLowerCase();
    if (q.isEmpty) return _all;
    return _all.where((g) => g.searchText.contains(q)).toList();
  }

  /// Tapping the button of the decision already set clears it back to
  /// pending, so a mis-tap can be undone without leaving the screen.
  void _setDecision(int i, GateLogDecision decision) {
    setState(() {
      final next = _all[i].decision == decision
          ? GateLogDecision.pending
          : decision;
      _all[i] = _all[i].copyWith(decision: next);
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final gutter = AppSpacing.gutter(context);
    final rows = _filtered;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        titleSpacing: gutter,
        leadingWidth: gutter + 32,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text('Gate Log'),
      ),
      body: SafeArea(
        bottom: false,
        child: CenteredFill(
          child: Column(
            children: [
              // Search + subtitle.
              Padding(
                padding: EdgeInsets.fromLTRB(
                  gutter,
                  AppSpacing.xs,
                  gutter,
                  AppSpacing.sm,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    PillSearchField(
                      controller: _search,
                      hint: 'Search guard guests',
                      onChanged: () => setState(() {}),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Guests invited by guard · approve or reject',
                      style: t.bodySmall?.copyWith(
                        color: AppColors.muted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              // List.
              Expanded(
                child: rows.isEmpty
                    ? const _Empty()
                    : ListView.separated(
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
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: AppSpacing.md),
                        itemBuilder: (context, i) {
                          final g = rows[i];
                          final realIdx = _all.indexOf(g);
                          return _GateLogCard(
                            entry: g,
                            onApprove: () => _setDecision(
                              realIdx,
                              GateLogDecision.approved,
                            ),
                            onReject: () => _setDecision(
                              realIdx,
                              GateLogDecision.rejected,
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

class _GateLogCard extends StatelessWidget {
  const _GateLogCard({
    required this.entry,
    required this.onApprove,
    required this.onReject,
  });

  final GateLogEntry entry;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    final hasNote = entry.note.isNotEmpty;

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _LogRow(
            label: 'Guest Name :',
            value: entry.plus > 0 ? '${entry.name}  +${entry.plus}' : entry.name,
          ),
          const _RowDivider(),
          _LogRow(label: 'Date / Time :', value: entry.when),
          const _RowDivider(),
          _LogRow(label: 'Duration :', value: entry.duration),
          const _RowDivider(),
          _LogRow(label: 'RequestedBy :', value: entry.meetWith),

          // Saved note — same "Label : value" alignment as the rows above.
          if (hasNote) ...[
            const _RowDivider(),
            _LogRow(label: 'Note :', value: entry.note),
          ],

          const SizedBox(height: AppSpacing.md),

          // Approve / Reject — equal halves so neither dominates the card.
          Row(
            children: [
              Expanded(
                child: _DecisionButton(
                  label: entry.approved ? 'Approved' : 'Approve',
                  color: AppColors.success,
                  active: entry.approved,
                  onTap: onApprove,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _DecisionButton(
                  label: entry.rejected ? 'Rejected' : 'Reject',
                  color: AppColors.danger,
                  active: entry.rejected,
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

/// One half of the Approve / Reject pair. Filled in its own colour once
/// chosen, otherwise a soft outlined pill — same convention as the guard
/// flow buttons on the Expected Guests card.
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

/// A "Label : value" row inside a card.
class _LogRow extends StatelessWidget {
  const _LogRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 104,
            child: Text(
              label,
              style: t.bodyMedium?.copyWith(color: AppColors.muted),
            ),
          ),
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

class _Empty extends StatelessWidget {
  const _Empty();

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
              Icons.shield_outlined,
              size: 44,
              color: AppColors.faint,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'No guard guests yet',
              style: t.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
