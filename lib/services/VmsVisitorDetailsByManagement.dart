import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/guard_visitor.dart';
import '../widgets/loader_helper.dart';
import 'baseurl.dart';

/// Fetches the visitor details raised by the logged-in management user.
///
/// Endpoint: VmsVisitorDetailsByManagement/VmsVisitorDetailsByManagement
/// Body (both dates = today, "28/Jul/2026" format; iUserId from login):
///   { "dFromDate": "28/Jul/2026", "dToDate": "28/Jul/2026", "iUserId": "5" }
///
/// The "Data" rows are the same 9 fields as the guard list, so they reuse the
/// [GuardVisitor] model. Same style as [GuardVisitorRepo] in
/// VMSGaurdVisitorRequestList.dart.
class VmsVisitorDetailsByManagementRepo {
  /// [fromDate] / [toDate] default to today when not supplied, so a caller
  /// that only wants "today" can just call `getVisitorDetails(context)`.
  Future<List<GuardVisitor>> getVisitorDetails(
    BuildContext context, {
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    try {
      // iUserId -> saved at login time by login_screen.dart.
      final prefs = await SharedPreferences.getInstance();
      final iUserId = prefs.getString('iUserId') ?? '0';
      print('----VisitorDetailsByMgmt iUserId (SharedPreferences)--> $iUserId');

      final fmt = DateFormat('dd/MMM/yyyy');
      final now = DateTime.now();
      final body = {
        "dFromDate": fmt.format(fromDate ?? now),
        "dToDate": fmt.format(toDate ?? now),
        "iUserId": iUserId,
      };
      print('----VisitorDetailsByMgmt BODY----> $body');

      var baseURL = BaseRepo().baseurl;
      var endPoint =
          "VmsVisitorDetailsByManagement/VmsVisitorDetailsByManagement";
      var apiUrl = "$baseURL$endPoint";
      print('----VisitorDetailsByMgmt URL----> $apiUrl');

      showLoader();
      var headers = {'Content-Type': 'application/json'};
      var request = http.Request('POST', Uri.parse(apiUrl));
      request.body = json.encode(body);
      request.headers.addAll(headers);

      http.StreamedResponse response = await request.send();
      var data = await response.stream.bytesToString();
      var map = json.decode(data);
      hideLoader();
      print('----VisitorDetailsByMgmt RESPONSE----> $map');

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
      debugPrint("VisitorDetailsByMgmt exception: $e");
      rethrow;
    }
  }
}
