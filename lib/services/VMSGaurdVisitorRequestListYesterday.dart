import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import '../models/guard_visitor.dart';
import '../widgets/loader_helper.dart';
import 'baseurl.dart';

/// Fetches the guard's visitor request list **for yesterday**.
///
/// Endpoint: VMSGaurdVisitorRequestList/VMSGaurdVisitorRequestList
/// Body (both dates = yesterday, "24/Jul/2026" format):
///   { "dFromDate": "23/Jul/2026", "dToDate": "23/Jul/2026" }
///
/// Same style as [ValidateOtpRepo] in validateOtp.dart. This is the same
/// endpoint as [GuardVisitorRepo] (VMSGaurdVisitorRequestList.dart) — only
/// the date in the request body differs.
class GuardVisitorYesterdayRepo {
  Future<List<GuardVisitor>> getVisitorList(BuildContext context) async {
    try {
      final yesterday = DateFormat(
        'dd/MMM/yyyy',
      ).format(DateTime.now().subtract(const Duration(days: 1)));
      final body = {"dFromDate": yesterday, "dToDate": yesterday};
      print('----GuardVisitorYesterdayList BODY----> $body');

      var baseURL = BaseRepo().baseurl;
      var endPoint = "VMSGaurdVisitorRequestList/VMSGaurdVisitorRequestList";
      var apiUrl = "$baseURL$endPoint";
      print('----GuardVisitorYesterdayList URL----> $apiUrl');

      showLoader();
      var headers = {'Content-Type': 'application/json'};
      var request = http.Request('POST', Uri.parse(apiUrl));
      request.body = json.encode(body);
      request.headers.addAll(headers);

      http.StreamedResponse response = await request.send();
      var data = await response.stream.bytesToString();
      var map = json.decode(data);
      hideLoader();
      print('----GuardVisitorYesterdayList RESPONSE----> $map');

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
      debugPrint("GuardVisitorYesterdayList exception: $e");
      rethrow;
    }
  }
}
