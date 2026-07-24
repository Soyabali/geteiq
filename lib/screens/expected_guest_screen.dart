import 'package:flutter/material.dart';
import '../models/expected_guest.dart';
import '../theme/tokens.dart';
import '../widgets/app_card.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/pill_search_field.dart';

/// Guard-side "Expected Guests" screen.
///
/// Search + 4 stage filters (Expected / Check-in / Meeting / Check-out) + a
/// list of guest cards the guard can move through the flow with the three
/// action buttons. Data is static for now (see [kExpectedGuestsDemo]).
class ExpectedGuestScreen extends StatefulWidget {
  const ExpectedGuestScreen({super.key});

  @override
  State<ExpectedGuestScreen> createState() => _ExpectedGuestScreenState();
}

class _ExpectedGuestScreenState extends State<ExpectedGuestScreen> {
  final _search = TextEditingController();

  // Own mutable copy so tapping an action can change a guest's stage.
  late final List<ExpectedGuest> _all = List.of(kExpectedGuestsDemo);

  // null = show all; otherwise only guests in this stage.
  GuestStage? _stageFilter;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  int _countOf(GuestStage stage) =>
      _all.where((g) => g.stage == stage).length;

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

  void _setStage(ExpectedGuest guest, GuestStage stage) {
    final i = _all.indexOf(guest);
    if (i < 0) return;
    setState(() => _all[i] = guest.copyWith(stage: stage));
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
        child: CenteredFill(
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
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: AppSpacing.md),
                        itemBuilder: (context, i) {
                          final g = rows[i];
                          return _GuestCard(
                            guest: g,
                            onStage: (stage) => _setStage(g, stage),
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
  const _GuestCard({required this.guest, required this.onStage});

  final ExpectedGuest guest;
  final ValueChanged<GuestStage> onStage;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Name (+plus)  ...........................  APPROVED
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
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
                    const SizedBox(height: 2),
                    Text(
                      guest.people.isNotEmpty
                          ? '(${guest.people})'
                          : guest.phone,
                      style: t.bodySmall?.copyWith(color: AppColors.faint),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              _ApprovedBadge(label: guest.approval),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Meta lines
          _MetaLine(label: 'Date, Time:', value: guest.when),
          _MetaLine(label: 'Meeting duration:', value: guest.duration),
          _MetaLine(label: 'Note:', value: guest.note),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Status: ${guest.stage.label}',
            style: t.bodySmall?.copyWith(color: AppColors.faint, fontSize: 11),
          ),
          const SizedBox(height: AppSpacing.md),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: _ActBtn(
                  label: 'Not arrived',
                  active: guest.stage == GuestStage.expected,
                  onTap: () => onStage(GuestStage.expected),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _ActBtn(
                  label: 'Check-in',
                  active: guest.stage == GuestStage.checkin ||
                      guest.stage == GuestStage.meeting,
                  onTap: () => onStage(GuestStage.checkin),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _ActBtn(
                  label: 'Check-out',
                  active: guest.stage == GuestStage.checkout,
                  onTap: () => onStage(GuestStage.checkout),
                ),
              ),
            ],
          ),
        ],
      ),
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

/// Green "APPROVED" pill.
class _ApprovedBadge extends StatelessWidget {
  const _ApprovedBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Text(
        label.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: AppColors.success,
          fontWeight: FontWeight.w700,
          fontSize: 10.5,
          letterSpacing: 0.4,
        ),
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
