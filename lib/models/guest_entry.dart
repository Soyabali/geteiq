import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../theme/tokens.dart';

/// Lifecycle state of a guest, rendered as a coloured chip on the list rows.
enum GuestStatus {
  expected('Expected'),
  checkedIn('Checked In'),
  pending('Pending'),
  checkedOut('Checked Out'),
  denied('Denied');

  const GuestStatus(this.label);

  /// Text shown on the chip.
  final String label;

  /// Maps a backend value ("checked_in", "checkedIn", "CHECKED_IN"…) onto a
  /// [GuestStatus]. Unknown / null values fall back to [expected], so a new
  /// server status never crashes the UI.
  static GuestStatus fromApi(String? raw) {
    final key = (raw ?? '').toLowerCase().replaceAll(RegExp(r'[\s_-]'), '');
    return switch (key) {
      'checkedin' => GuestStatus.checkedIn,
      'pending' => GuestStatus.pending,
      'checkedout' => GuestStatus.checkedOut,
      'denied' || 'rejected' => GuestStatus.denied,
      _ => GuestStatus.expected,
    };
  }

  /// Chip text colour.
  Color get foreground => switch (this) {
    GuestStatus.checkedIn => const Color(0xFF2563EB),
    GuestStatus.pending => const Color(0xFFB45309),
    GuestStatus.checkedOut => AppColors.muted,
    GuestStatus.denied => AppColors.danger,
    GuestStatus.expected => AppColors.brandDeep,
  };

  /// Chip background — a soft tint of [foreground].
  Color get background => switch (this) {
    GuestStatus.checkedIn => const Color(0xFFE7EEFF),
    GuestStatus.pending => const Color(0xFFFBE7CF),
    GuestStatus.checkedOut => AppColors.borderSoft,
    GuestStatus.denied => const Color(0xFFF9DEDC),
    GuestStatus.expected => AppColors.brandTint,
  };
}

/// One row in a guest list. Kept flat so it maps 1:1 onto a JSON object from
/// the API — see [GuestEntry.fromJson].
@immutable
class GuestEntry {
  const GuestEntry({
    required this.name,
    required this.phone,
    required this.scheduledAt,
    this.department,
    this.status = GuestStatus.expected,
  });

  final String name;
  final String phone;

  /// When the guest is expected / was seen.
  final DateTime scheduledAt;

  /// Host department or purpose (e.g. "HR"). Optional.
  final String? department;

  final GuestStatus status;

  /// "Today · 4:30 PM · HR" — the supporting line under the name.
  String get meta {
    final now = DateTime.now();
    final day = DateTime(scheduledAt.year, scheduledAt.month, scheduledAt.day);
    final today = DateTime(now.year, now.month, now.day);
    final label = switch (day.difference(today).inDays) {
      0 => 'Today',
      1 => 'Tomorrow',
      -1 => 'Yesterday',
      _ => DateFormat('d MMM').format(scheduledAt),
    };
    final base = '$label · ${DateFormat('h:mm a').format(scheduledAt)}';
    return (department == null || department!.isEmpty)
        ? base
        : '$base · $department';
  }

  /// Builds an entry from an API JSON object. Tolerant of missing/renamed keys
  /// so a partial response never throws.
  factory GuestEntry.fromJson(Map<String, dynamic> json) => GuestEntry(
    name: (json['name'] ?? json['guestName'] ?? '') as String,
    phone: (json['phone'] ?? json['mobile'] ?? '') as String,
    scheduledAt:
        DateTime.tryParse(
          (json['scheduledAt'] ?? json['dateTime'] ?? '') as String,
        ) ??
        DateTime.now(),
    department: json['department'] as String?,
    status: GuestStatus.fromApi(json['status'] as String?),
  );
}
