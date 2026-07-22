import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// Colour tone for a small report badge ("July", "90%", "HR", "Busy"…).
enum ReportTone {
  info,
  success,
  warning,
  brand,
  neutral;

  /// Maps a backend value onto a tone. Unknown / null falls back to [info].
  static ReportTone fromApi(String? raw) =>
      switch ((raw ?? '').toLowerCase()) {
        'success' || 'good' || 'positive' => ReportTone.success,
        'warning' || 'warn' => ReportTone.warning,
        'brand' || 'busy' => ReportTone.brand,
        'neutral' || 'muted' => ReportTone.neutral,
        _ => ReportTone.info,
      };

  Color get foreground => switch (this) {
    ReportTone.info => const Color(0xFF2563EB),
    ReportTone.success => AppColors.success,
    ReportTone.warning => const Color(0xFFB45309),
    ReportTone.brand => AppColors.brandDeep,
    ReportTone.neutral => AppColors.muted,
  };

  Color get background => switch (this) {
    ReportTone.info => const Color(0xFFE7EEFF),
    ReportTone.success => const Color(0xFFDCFCE7),
    ReportTone.warning => const Color(0xFFFBE7CF),
    ReportTone.brand => AppColors.brandTint,
    ReportTone.neutral => AppColors.borderSoft,
  };
}

/// One of the summary tiles at the top (e.g. "142 / Total").
@immutable
class ReportStat {
  const ReportStat({required this.value, required this.label});

  final String value;
  final String label;

  factory ReportStat.fromJson(Map<String, dynamic> json) => ReportStat(
    value: '${json['value'] ?? ''}',
    label: (json['label'] ?? '') as String,
  );
}

/// A label/value pair shown on the report detail screen.
@immutable
class ReportFact {
  const ReportFact({required this.label, required this.value});

  final String label;
  final String value;

  factory ReportFact.fromJson(Map<String, dynamic> json) => ReportFact(
    label: (json['label'] ?? '') as String,
    value: '${json['value'] ?? ''}',
  );
}

/// A tappable report card (e.g. "Total Guests", "Peak Day").
@immutable
class ReportRow {
  const ReportRow({
    required this.title,
    required this.subtitle,
    required this.detail,
    required this.badgeLabel,
    this.badgeTone = ReportTone.info,
    this.breakdown = const [],
  });

  final String title;
  final String subtitle;
  final String detail;
  final String badgeLabel;
  final ReportTone badgeTone;

  /// Extra facts shown when the card is opened.
  final List<ReportFact> breakdown;

  /// Lower-cased haystack for the search box.
  String get searchText =>
      '$title $subtitle $detail $badgeLabel'.toLowerCase();

  factory ReportRow.fromJson(Map<String, dynamic> json) => ReportRow(
    title: (json['title'] ?? '') as String,
    subtitle: (json['subtitle'] ?? '') as String,
    detail: (json['detail'] ?? '') as String,
    badgeLabel: (json['badge'] ?? '') as String,
    badgeTone: ReportTone.fromApi(json['tone'] as String?),
    breakdown: ((json['breakdown'] ?? const []) as List)
        .map((e) => ReportFact.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}

/// The whole "Month guest Report" payload: summary tiles + report cards.
@immutable
class MonthReport {
  const MonthReport({required this.stats, required this.rows});

  final List<ReportStat> stats;
  final List<ReportRow> rows;

  factory MonthReport.fromJson(Map<String, dynamic> json) => MonthReport(
    stats: ((json['stats'] ?? const []) as List)
        .map((e) => ReportStat.fromJson(e as Map<String, dynamic>))
        .toList(),
    rows: ((json['rows'] ?? const []) as List)
        .map((e) => ReportRow.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}
