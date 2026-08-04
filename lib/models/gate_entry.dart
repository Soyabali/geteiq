import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../theme/tokens.dart';

// ============================================================================
//  APPROVE / REJECT STATE  (sAppRejStatus)
// ============================================================================

/// Management's call on a gate entry — mirrors the API's `sAppRejStatus`.
enum GateDecision {
  pending('Pending'),
  approved('Approved'),
  rejected('Rejected');

  const GateDecision(this.label);

  /// Chip text / button label.
  final String label;

  /// Maps `sAppRejStatus` ("Approved", "approved", "REJECTED", null, …) onto a
  /// [GateDecision]. Anything unknown falls back to [pending], so a new server
  /// value never crashes the list.
  static GateDecision fromApi(String? raw) {
    final key = (raw ?? '').toLowerCase().replaceAll(RegExp(r'[\s_-]'), '');
    return switch (key) {
      'approved' || 'approve' => GateDecision.approved,
      'rejected' || 'reject' || 'denied' => GateDecision.rejected,
      _ => GateDecision.pending,
    };
  }

  /// Chip text colour.
  Color get foreground => switch (this) {
    GateDecision.approved => AppColors.success,
    GateDecision.rejected => AppColors.danger,
    GateDecision.pending => const Color(0xFFB45309),
  };

  /// Chip background — a soft tint of [foreground].
  Color get background => switch (this) {
    GateDecision.approved => const Color(0xFFE3F2E7),
    GateDecision.rejected => const Color(0xFFF9DEDC),
    GateDecision.pending => const Color(0xFFFBE7CF),
  };
}

// ============================================================================
//  GATE ENTRY  —  one row of the "Data" array
// ============================================================================

/// One gate-log row, mapped 1:1 from either gate API.
///
/// Both endpoints return the identical shape, so one model serves both:
///   * `EntryByGaurd/EntryByGaurd`               (management, iUserType != "1")
///   * `VisitorEntryByGaurd/VisitorEntryByGaurd` (guard,      iUserType == "1")
///
/// ```json
/// {
///   "sQRCodeVal":    "678249",
///   "dDate":         "2026-07-29",
///   "dTime":         "09:37:00",
///   "iValidHours":   "8 Hour(s)",
///   "sNote":         "weCome",
///   "sUserName":     "Pramod",
///   "dRequiredAt":   "29/Jul/2026 09:37",
///   "sStatus":       "Pending",
///   "sGuestNames":   "Ali",
///   "sAppRejStatus": "Approved"
/// }
/// ```
@immutable
class GateEntry {
  const GateEntry({
    required this.qrCodeVal,
    required this.date,
    required this.time,
    required this.validHours,
    required this.note,
    required this.userName,
    required this.requiredAt,
    required this.status,
    required this.guestNames,
    required this.decision,
  });

  final String qrCodeVal; // sQRCodeVal    e.g. "678249"
  final String date; // dDate         e.g. "2026-07-29"
  final String time; // dTime         e.g. "09:37:00"
  final String validHours; // iValidHours   e.g. "8 Hour(s)"
  final String note; // sNote         e.g. "weCome"
  final String userName; // sUserName     the host / requester
  final String requiredAt; // dRequiredAt   e.g. "29/Jul/2026 09:37"
  final String status; // sStatus       e.g. "Pending"
  final String guestNames; // sGuestNames   e.g. "Ali, Rohan"

  /// sAppRejStatus — shown as a read-only chip on the guard side, and as the
  /// selected Approve/Reject button on the management side.
  final GateDecision decision;

  // --------------------------------------------------------------------------
  //  JSON
  // --------------------------------------------------------------------------

  /// Every value is string-coerced (`'${j[...] ?? ''}'`) so the list survives
  /// the backend sending a number where a string is expected.
  factory GateEntry.fromJson(Map<String, dynamic> j) => GateEntry(
    qrCodeVal: '${j['sQRCodeVal'] ?? ''}',
    date: '${j['dDate'] ?? ''}',
    time: '${j['dTime'] ?? ''}',
    validHours: '${j['iValidHours'] ?? ''}',
    note: '${j['sNote'] ?? ''}',
    userName: '${j['sUserName'] ?? ''}',
    requiredAt: '${j['dRequiredAt'] ?? ''}',
    status: '${j['sStatus'] ?? ''}',
    guestNames: '${j['sGuestNames'] ?? ''}',
    decision: GateDecision.fromApi(j['sAppRejStatus'] as String?),
  );

  /// Local-only change (management taps Approve / Reject). Does not hit the
  /// API — wire that up when the update endpoint exists.
  GateEntry copyWith({GateDecision? decision}) => GateEntry(
    qrCodeVal: qrCodeVal,
    date: date,
    time: time,
    validHours: validHours,
    note: note,
    userName: userName,
    requiredAt: requiredAt,
    status: status,
    guestNames: guestNames,
    decision: decision ?? this.decision,
  );

  // --------------------------------------------------------------------------
  //  DISPLAY HELPERS
  // --------------------------------------------------------------------------

  /// "Ali, Rohan" -> ["Ali", "Rohan"]
  List<String> get names => guestNames
      .split(',')
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toList();

  /// First guest name, or "—" when the field is empty.
  String get primaryName => names.isEmpty ? '—' : names.first;

  /// Extra guests beyond the first, for the "+N" badge.
  int get plus => names.length > 1 ? names.length - 1 : 0;

  /// `dDate` + `dTime` formatted for display — e.g. "2026-07-29" + "09:37:00"
  /// -> "29 Jul 2026 · 9:37 AM". Used by the Gate Log "Date :" row.
  ///
  /// Same absolute format the Month / Invite Guest List cards use — no
  /// relative "Today / Tomorrow" labels, so the actual date is always visible.
  /// Falls back to the raw API strings if the backend ever sends a date this
  /// can't parse.
  String get dateTime {
    try {
      final dt = DateTime.parse('$date $time');
      return DateFormat('d MMM yyyy · h:mm a').format(dt);
    } catch (_) {
      return '$date $time'.trim();
    }
  }

  /// Alias for [dateTime], kept so both names render the identical string.
  String get when => dateTime;

  /// Matched against the search box.
  String get searchText =>
      '$guestNames $userName $note $qrCodeVal $status'.toLowerCase();
}
