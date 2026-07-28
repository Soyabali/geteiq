import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import '../models/guard_visitor.dart';
import '../widgets/loader_helper.dart';
import 'baseurl.dart';

/// Fetches the guard's visitor request list **for the current month**.
///
/// Endpoint: VMSGaurdVisitorRequestList/VMSGaurdVisitorRequestList
/// Body (from = month's 1st, to = month's last day, "24/Jul/2026" format):
///   { "dFromDate": "01/Jul/2026", "dToDate": "31/Jul/2026" }
///
/// Same endpoint + model as [GuardVisitorRepo] (VMSGaurdVisitorRequestList.dart)
/// and [GuardVisitorYesterdayRepo] (VMSGaurdVisitorRequestListYesterday.dart)
/// — only the date range in the request body differs.
class GuardVisitorMonthRepo {
  /// [fromDate] / [toDate] default to the current calendar month (1st ->
  /// last day) when not supplied, so existing callers keep working unchanged.
  Future<List<GuardVisitor>> getVisitorList(
    BuildContext context, {
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    try {
      final now = DateTime.now();
      final firstDay = fromDate ?? DateTime(now.year, now.month, 1);
      // Day 0 of next month == the last day of this month (Dart normalises
      // the month overflow, so this also works correctly for December).
      final lastDay = toDate ?? DateTime(now.year, now.month + 1, 0);

      final fmt = DateFormat('dd/MMM/yyyy');
      final body = {
        "dFromDate": fmt.format(firstDay),
        "dToDate": fmt.format(lastDay),
      };
      print('----GuardVisitorMonthList BODY----> $body');

      var baseURL = BaseRepo().baseurl;
      var endPoint = "VMSGaurdVisitorRequestList/VMSGaurdVisitorRequestList";
      var apiUrl = "$baseURL$endPoint";
      print('----GuardVisitorMonthList URL----> $apiUrl');

      showLoader();
      var headers = {'Content-Type': 'application/json'};
      var request = http.Request('POST', Uri.parse(apiUrl));
      request.body = json.encode(body);
      request.headers.addAll(headers);

      http.StreamedResponse response = await request.send();
      var data = await response.stream.bytesToString();
      var map = json.decode(data);
      hideLoader();
      print('----GuardVisitorMonthList RESPONSE----> $map');

      // Success -> parse the "Data" array into GuardVisitor models.
      if (response.statusCode == 200 && "${map['Result']}" == "1") {
        final rawList = (map['Data'] as List?) ?? const [];
        return rawList
            .map((e) => GuardVisitor.fromJson(e as Map<String, dynamic>))
            .toList();
      }

      // Result != 1 (or bad status) -> no rows.
      return <GuardVisitor>[];
    } catch (e) {
      hideLoader();
      debugPrint("GuardVisitorMonthList exception: $e");
      rethrow;
    }
  }
}
