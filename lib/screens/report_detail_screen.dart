import 'package:flutter/material.dart';

import '../models/month_report.dart';
import '../theme/tokens.dart';
import '../widgets/app_card.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/report_badge.dart';

/// Detail view for a single report card. Shows the headline metric, its badge,
/// and the [ReportRow.breakdown] facts. Data comes straight from the tapped
/// [ReportRow], so it's already API-ready.
class ReportDetailScreen extends StatelessWidget {
  const ReportDetailScreen({super.key, required this.row});

  final ReportRow row;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    return AppScaffold(
      title: row.title,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.sm),
          AppCard(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(row.subtitle, style: t.headlineSmall),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    ReportBadge(label: row.badgeLabel, tone: row.badgeTone),
                  ],
                ),
                if (row.detail.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(row.detail, style: t.bodyMedium),
                ],
                if (row.breakdown.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.lg),
                  const Divider(height: 1),
                  const SizedBox(height: AppSpacing.xs),
                  for (final fact in row.breakdown) _FactRow(fact: fact),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FactRow extends StatelessWidget {
  const _FactRow({required this.fact});

  final ReportFact fact;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              fact.label,
              style: t.bodyMedium?.copyWith(color: AppColors.muted),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Text(fact.value, style: t.titleSmall),
        ],
      ),
    );
  }
}
