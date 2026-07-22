import 'package:flutter/material.dart';

import '../models/month_report.dart';
import '../theme/tokens.dart';

/// Small pill badge used on the report cards ("July", "90%", "HR", "Busy").
/// Colours come from the [ReportTone] so they stay consistent everywhere.
class ReportBadge extends StatelessWidget {
  const ReportBadge({super.key, required this.label, required this.tone});

  final String label;
  final ReportTone tone;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: tone.background,
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          fontSize: 12.5,
          color: tone.foreground,
          letterSpacing: 0,
        ),
      ),
    );
  }
}
