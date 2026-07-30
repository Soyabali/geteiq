import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../theme/tokens.dart';

/// One row of the `NotificationList` "Data" array.
///
/// ```json
/// {
///   "sTitle":        "Approval Status",
///   "sNotification": "Request has been rejected. Reference No.:697586.",
///   "dReceivedAt":   "30/Jul/2026 09:39",
///   "sImageUrl":     "NA"
/// }
/// ```
///
/// The API carries no read/unread flag, so the screen renders every row the
/// same way — add the tint back here if the backend ever sends one.
@immutable
class AppNotification {
  const AppNotification({
    required this.title,
    required this.message,
    required this.receivedAtRaw,
    required this.imageUrl,
    required this.receivedAt,
  });

  final String title; // sTitle         e.g. "Approval Status"
  final String message; // sNotification  the body line
  final String receivedAtRaw; // dReceivedAt    e.g. "30/Jul/2026 09:39"
  final String imageUrl; // sImageUrl      "NA" when there is no image

  /// [receivedAtRaw] parsed, or null when the backend sends something this
  /// can't read — the UI then falls back to the raw string.
  final DateTime? receivedAt;

  // --------------------------------------------------------------------------
  //  JSON
  // --------------------------------------------------------------------------

  /// Every value is string-coerced (`'${j[...] ?? ''}'`) so the list survives
  /// the backend sending a number where a string is expected.
  factory AppNotification.fromJson(Map<String, dynamic> j) {
    final raw = '${j['dReceivedAt'] ?? ''}'.trim();
    return AppNotification(
      title: '${j['sTitle'] ?? ''}',
      message: '${j['sNotification'] ?? ''}',
      receivedAtRaw: raw,
      imageUrl: '${j['sImageUrl'] ?? ''}',
      receivedAt: _parseReceivedAt(raw),
    );
  }

  /// "30/Jul/2026 09:39" -> DateTime. Null when it doesn't match.
  static DateTime? _parseReceivedAt(String raw) {
    if (raw.isEmpty) return null;
    try {
      return DateFormat('dd/MMM/yyyy HH:mm').parseStrict(raw);
    } catch (_) {
      return null;
    }
  }

  // --------------------------------------------------------------------------
  //  DISPLAY HELPERS
  // --------------------------------------------------------------------------

  /// True when `sImageUrl` is a real URL and not the API's "NA" placeholder.
  bool get hasImage {
    final v = imageUrl.trim();
    return v.isNotEmpty && v.toUpperCase() != 'NA';
  }

  /// Section header this row belongs under — "Today", "Yesterday" or
  /// "29 Jul 2026". Rows with an unparsable date land under "Earlier".
  String get dayLabel {
    final dt = receivedAt;
    if (dt == null) return 'Earlier';
    final day = DateTime(dt.year, dt.month, dt.day);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return switch (day.difference(today).inDays) {
      0 => 'Today',
      -1 => 'Yesterday',
      _ => DateFormat('d MMM yyyy').format(dt),
    };
  }

  /// Trailing time on the row — "9:39 AM". Falls back to the raw string.
  String get timeLabel {
    final dt = receivedAt;
    if (dt == null) return receivedAtRaw;
    return DateFormat('h:mm a').format(dt);
  }

  /// The API only sends free text, so the icon / colour are derived from what
  /// the message says. Anything unrecognised gets the neutral brand bell.
  _NotifKind get _kind {
    final text = '$title $message'.toLowerCase();
    if (text.contains('reject') || text.contains('denied')) {
      return _NotifKind.rejected;
    }
    if (text.contains('approve')) return _NotifKind.approved;
    if (text.contains('checked out') || text.contains('check out')) {
      return _NotifKind.checkedOut;
    }
    if (text.contains('checked in') ||
        text.contains('check in') ||
        text.contains('entry')) {
      return _NotifKind.checkedIn;
    }
    return _NotifKind.general;
  }

  IconData get icon => _kind.icon;

  Color get color => _kind.color;
}

/// The handful of looks a notification row can take.
enum _NotifKind {
  approved(Icons.check_circle_rounded, AppColors.success),
  rejected(Icons.cancel_rounded, AppColors.danger),
  checkedIn(Icons.login_rounded, Color(0xFF2563EB)),
  checkedOut(Icons.logout_rounded, Color(0xFFEA580C)),
  general(Icons.notifications_rounded, AppColors.brand);

  const _NotifKind(this.icon, this.color);

  final IconData icon;
  final Color color;
}
