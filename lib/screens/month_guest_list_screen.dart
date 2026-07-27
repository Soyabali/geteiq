import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/guard_visitor.dart';
import '../services/VMSGaurdVisitorRequestListMonth.dart';
import '../theme/tokens.dart';
import '../widgets/app_card.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/pill_search_field.dart';

/// "Month guest list" — every guard visitor request from the current month.
///
/// Read-only history, same layout as [YesterdayGuestListScreen]: no approve
/// action and no note field. Data comes from [GuardVisitorMonthRepo].
class MonthGuestListScreen extends StatefulWidget {
  const MonthGuestListScreen({super.key});

  @override
  State<MonthGuestListScreen> createState() => _MonthGuestListScreenState();
}

class _MonthGuestListScreenState extends State<MonthGuestListScreen> {
  final _search = TextEditingController();

  List<GuardVisitor> _all = [];
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

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = false;
    });
    try {
      final list = await GuardVisitorMonthRepo().getVisitorList(context);
      if (!mounted) return;
      setState(() {
        _all = list;
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

  List<GuardVisitor> get _filtered {
    final q = _search.text.trim().toLowerCase();
    if (q.isEmpty) return _all;
    return _all.where((v) {
      return v.guestNames.toLowerCase().contains(q) ||
          v.userName.toLowerCase().contains(q);
    }).toList();
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
        title: const Text('Month guest list'),
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
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        gutter,
                        AppSpacing.xs,
                        gutter,
                        AppSpacing.md,
                      ),
                      child: PillSearchField(
                        controller: _search,
                        hint: "Search this month's guests",
                        onChanged: () => setState(() {}),
                      ),
                    ),
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
                              itemBuilder: (context, i) =>
                                  _MonthGuestCard(visitor: rows[i]),
                            ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _MonthGuestCard extends StatelessWidget {
  const _MonthGuestCard({required this.visitor});

  final GuardVisitor visitor;

  // sGuestNames may be a comma list -> "Ram +2" style, same convention as
  // the Expected Guests / Yesterday screens.
  String get _guestName {
    final names = visitor.guestNames
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    if (names.isEmpty) return '—';
    final extra = names.length - 1;
    return extra > 0 ? '${names.first} +$extra' : names.first;
  }

  // "2026-07-23" + "18:00:00" -> "23 Jul 2026 · 6:00 PM"
  String get _dateTime {
    try {
      final dt = DateTime.parse('${visitor.date} ${visitor.time}');
      return DateFormat('d MMM yyyy · h:mm a').format(dt);
    } catch (_) {
      return '${visitor.date} ${visitor.time}'.trim();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _LogRow(label: 'Guest Name :', value: _guestName),
          const _RowDivider(),
          _LogRow(label: 'Date / Time :', value: _dateTime),
          const _RowDivider(),
          _LogRow(
            label: 'Duration :',
            value: visitor.validHours.isEmpty ? '—' : visitor.validHours,
          ),
          const _RowDivider(),
          _LogRow(
            label: 'Meet with :',
            value: visitor.userName.isEmpty ? '—' : visitor.userName,
          ),
        ],
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
              "Couldn't load this month's guests.",
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
              Icons.people_outline_rounded,
              size: 44,
              color: AppColors.faint,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'No Data available',
              style: t.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
