import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/guard_visitor.dart';
import 'VMSGaurdVisitorRequestListMonth.dart';
import 'VmsVisitorDetailsByManagement.dart';

/// Role-aware visitor list for a date range.
///
/// The guard and management sides show the *same* screens (Today / Yesterday /
/// Monthly) over the *same* [GuardVisitor] rows, but read from two different
/// endpoints:
///
/// | `iUserType` | Endpoint | Body |
/// |---|---|---|
/// | `"1"` (guard) | `VMSGaurdVisitorRequestList` | `dFromDate`, `dToDate` |
/// | anything else (management) | `VmsVisitorDetailsByManagement` | `dFromDate`, `dToDate`, `iUserId` |
///
/// Screens should call this instead of a specific repo, so the guard/manager
/// split lives in exactly one place. Only the endpoint changes — the response
/// shape is identical, so nothing downstream has to care.
class VisitorListRepo {
  /// Both dates are inclusive and get formatted as `dd/MMM/yyyy` by the
  /// underlying repo.
  Future<List<GuardVisitor>> getVisitorList(
    BuildContext context, {
    required DateTime fromDate,
    required DateTime toDate,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final iUserType = (prefs.getString('iUserType') ?? '').trim();
    final isGuard = iUserType == "1";
    print('----VisitorList role----> iUserType=$iUserType guard=$isGuard');

    if (!context.mounted) return <GuardVisitor>[];

    if (isGuard) {
      // Despite the name, this repo takes any range — the guard endpoint's
      // body is just dFromDate/dToDate, so it serves today and yesterday too.
      return GuardVisitorMonthRepo().getVisitorList(
        context,
        fromDate: fromDate,
        toDate: toDate,
      );
    }

    // Management — same rows, but scoped to the logged-in user's iUserId,
    // which the repo reads from SharedPreferences itself.
    return VmsVisitorDetailsByManagementRepo().getVisitorDetails(
      context,
      fromDate: fromDate,
      toDate: toDate,
    );
  }

  /// Convenience ranges, so each screen doesn't re-derive its own dates.
  static DateTimeRange get today {
    final now = DateTime.now();
    final d = DateTime(now.year, now.month, now.day);
    return DateTimeRange(start: d, end: d);
  }

  static DateTimeRange get yesterday {
    final d = DateTime.now().subtract(const Duration(days: 1));
    final day = DateTime(d.year, d.month, d.day);
    return DateTimeRange(start: day, end: day);
  }

  /// 1st -> last day of the current month. Day 0 of next month normalises the
  /// overflow, so December works too.
  static DateTimeRange get thisMonth {
    final now = DateTime.now();
    return DateTimeRange(
      start: DateTime(now.year, now.month, 1),
      end: DateTime(now.year, now.month + 1, 0),
    );
  }
}
