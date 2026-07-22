import 'package:flutter/material.dart';

import '../data/month_report_repository.dart';
import '../models/month_report.dart';
import '../theme/tokens.dart';
import '../widgets/app_card.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/pill_search_field.dart';
import '../widgets/report_badge.dart';
import 'report_detail_screen.dart';

/// "Month guest Report" screen (see the mock): a search box, three summary
/// tiles, and a list of tappable report cards. Loading / empty / error are
/// handled here; all data comes from [MonthReportRepository].
class MonthGuestReportScreen extends StatefulWidget {
  const MonthGuestReportScreen({
    super.key,
    this.repository = const StaticMonthReportRepository(),
  });

  final MonthReportRepository repository;

  @override
  State<MonthGuestReportScreen> createState() => _MonthGuestReportScreenState();
}

class _MonthGuestReportScreenState extends State<MonthGuestReportScreen> {
  final _search = TextEditingController();
  late Future<MonthReport> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.repository.fetchReport();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _reload() => setState(() => _future = widget.repository.fetchReport());

  List<ReportRow> _filter(List<ReportRow> rows) {
    final q = _search.text.trim().toLowerCase();
    if (q.isEmpty) return rows;
    return rows.where((r) => r.searchText.contains(q)).toList();
  }

  void _open(ReportRow row) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => ReportDetailScreen(row: row)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final gutter = AppSpacing.gutter(context);

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
        title: const Text('Month guest Report'),
      ),
      body: SafeArea(
        bottom: false,
        child: CenteredFill(
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
                  hint: 'Search report',
                  onChanged: () => setState(() {}),
                ),
              ),
              Expanded(
                child: FutureBuilder<MonthReport>(
                  future: _future,
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.brand,
                        ),
                      );
                    }
                    if (snap.hasError || !snap.hasData) {
                      return _Message(
                        icon: Icons.wifi_off_rounded,
                        text: "Couldn't load the report.",
                        onRetry: _reload,
                      );
                    }
                    return _ReportBody(
                      report: snap.data!,
                      rows: _filter(snap.data!.rows),
                      gutter: gutter,
                      searching: _search.text.trim().isNotEmpty,
                      onOpen: _open,
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

class _ReportBody extends StatelessWidget {
  const _ReportBody({
    required this.report,
    required this.rows,
    required this.gutter,
    required this.searching,
    required this.onOpen,
  });

  final MonthReport report;
  final List<ReportRow> rows;
  final double gutter;
  final bool searching;
  final ValueChanged<ReportRow> onOpen;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
      children: [
        if (report.stats.isNotEmpty)
          Padding(
            padding: EdgeInsets.fromLTRB(
              gutter,
              AppSpacing.xs,
              gutter,
              AppSpacing.lg,
            ),
            child: _StatRow(stats: report.stats),
          ),
        if (rows.isEmpty)
          _Message(
            icon: Icons.query_stats_rounded,
            text: searching ? 'No report items match your search' : 'No report data',
          )
        else
          ColoredBox(
            color: AppColors.surface,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < rows.length; i++) ...[
                  if (i > 0)
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: gutter),
                      child: const Divider(height: 1),
                    ),
                  _ReportTile(
                    row: rows[i],
                    gutter: gutter,
                    onTap: () => onOpen(rows[i]),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

/// The three summary tiles.
class _StatRow extends StatelessWidget {
  const _StatRow({required this.stats});

  final List<ReportStat> stats;

  @override
  Widget build(BuildContext context) {
    // IntrinsicHeight lets the tiles match the tallest one *and* keeps the Row
    // height bounded — plain CrossAxisAlignment.stretch here would force an
    // infinite height because the Row sits inside a scrolling ListView.
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < stats.length; i++) ...[
            if (i > 0) const SizedBox(width: AppSpacing.sm),
            Expanded(child: _StatTile(stat: stats[i])),
          ],
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.stat});

  final ReportStat stat;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    return AppCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            stat.value,
            style: t.titleLarge?.copyWith(fontSize: 22),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            stat.label,
            style: t.bodySmall,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

/// A single tappable report card row (grouped inside the white surface).
class _ReportTile extends StatelessWidget {
  const _ReportTile({
    required this.row,
    required this.gutter,
    required this.onTap,
  });

  final ReportRow row;
  final double gutter;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: gutter,
            vertical: AppSpacing.lg,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      row.title,
                      style: t.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      row.subtitle,
                      style: t.bodySmall?.copyWith(color: AppColors.faint),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      row.detail,
                      style: t.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              ReportBadge(label: row.badgeLabel, tone: row.badgeTone),
            ],
          ),
        ),
      ),
    );
  }
}

/// Centred empty / error state.
class _Message extends StatelessWidget {
  const _Message({required this.icon, required this.text, this.onRetry});

  final IconData icon;
  final String text;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xxxl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 44, color: AppColors.faint),
          const SizedBox(height: AppSpacing.md),
          Text(text, textAlign: TextAlign.center, style: t.bodyMedium),
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
    );
  }
}
