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

  // Date range filter — defaults to the current calendar month (1st -> last
  // day), same default the api used before this filter existed.
  late DateTime _fromDate;
  late DateTime _toDate;

  static final _dateFmt = DateFormat('d MMM yyyy');
  static final _pickerFirstDate = DateTime(2020, 1, 1);
  static final _pickerLastDate = DateTime.now().add(const Duration(days: 365));

  List<GuardVisitor> _all = [];
  bool _loading = true;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _fromDate = DateTime(now.year, now.month, 1);
    _toDate = DateTime(now.year, now.month + 1, 0);
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
      final list = await GuardVisitorMonthRepo().getVisitorList(
        context,
        fromDate: _fromDate,
        toDate: _toDate,
      );
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

  // FromDate can never sit after ToDate -> cap its picker at ToDate.
  Future<void> _pickFromDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fromDate,
      firstDate: _pickerFirstDate,
      lastDate: _toDate,
      builder: _brandedDatePicker,
    );
    if (picked == null) return;
    setState(() => _fromDate = picked);
    _load();
  }

  // ToDate can never sit before FromDate -> floor its picker at FromDate.
  Future<void> _pickToDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _toDate,
      firstDate: _fromDate,
      lastDate: _pickerLastDate,
      builder: _brandedDatePicker,
    );
    if (picked == null) return;
    setState(() => _toDate = picked);
    _load();
  }

  // Re-skins the default Material calendar in gateIQ's brand colours instead
  // of stock Material blue: orange header/selection, ink body text, the
  // app's rounded-card shape.
  static Widget _brandedDatePicker(BuildContext context, Widget? child) {
    final base = Theme.of(context);
    return Theme(
      data: base.copyWith(
        colorScheme: base.colorScheme.copyWith(
          primary: AppColors.brand,
          onPrimary: Colors.white,
          surface: AppColors.surface,
          onSurface: AppColors.ink,
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(foregroundColor: AppColors.brand),
        ),
        datePickerTheme: DatePickerThemeData(
          backgroundColor: AppColors.surface,
          headerBackgroundColor: AppColors.brand,
          headerForegroundColor: Colors.white,
          todayForegroundColor: const WidgetStatePropertyAll(AppColors.brand),
          todayBorder: const BorderSide(color: AppColors.brand, width: 1.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.xl),
          ),
        ),
      ),
      child: child!,
    );
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
                      child: _DateRangeCard(
                        fromLabel: _dateFmt.format(_fromDate),
                        toLabel: _dateFmt.format(_toDate),
                        onTapFrom: _pickFromDate,
                        onTapTo: _pickToDate,
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        gutter,
                        0,
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

/// Unified "From — To" date-range control: one bordered card, split by a
/// hairline divider, matching the app's card/border look instead of two
/// separate floating pills.
class _DateRangeCard extends StatelessWidget {
  const _DateRangeCard({
    required this.fromLabel,
    required this.toLabel,
    required this.onTapFrom,
    required this.onTapTo,
  });

  final String fromLabel;
  final String toLabel;
  final VoidCallback onTapFrom;
  final VoidCallback onTapTo;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: AppColors.border, width: 1.2),
        boxShadow: AppShadows.card,
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Expanded(
              child: _DateCell(
                label: 'From Date',
                value: fromLabel,
                onTap: onTapFrom,
                radius: const BorderRadius.horizontal(
                  left: Radius.circular(AppRadii.lg),
                ),
              ),
            ),
            const VerticalDivider(
              width: 1,
              thickness: 1,
              color: AppColors.borderSoft,
            ),
            Expanded(
              child: _DateCell(
                label: 'To Date',
                value: toLabel,
                onTap: onTapTo,
                radius: const BorderRadius.horizontal(
                  right: Radius.circular(AppRadii.lg),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One half of [_DateRangeCard]: brand-tinted icon badge + label + value.
class _DateCell extends StatelessWidget {
  const _DateCell({
    required this.label,
    required this.value,
    required this.onTap,
    required this.radius,
  });

  final String label;
  final String value;
  final VoidCallback onTap;
  final BorderRadius radius;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Material(
      color: Colors.transparent,
      borderRadius: radius,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            children: [
              Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.brandTint,
                  borderRadius: BorderRadius.circular(AppRadii.sm),
                ),
                child: const Icon(
                  Icons.calendar_today_rounded,
                  size: 14,
                  color: AppColors.brand,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label.toUpperCase(),
                      style: t.labelSmall?.copyWith(
                        color: AppColors.faint,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      value,
                      style: t.bodyMedium?.copyWith(
                        color: AppColors.ink,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
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
            label: 'RequestedBy :',
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
