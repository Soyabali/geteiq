import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import '../models/guard_visitor.dart';
import '../widgets/loader_helper.dart';
import 'baseurl.dart';

/// Fetches the guard's visitor request list.
///
/// Endpoint: VMSGaurdVisitorRequestList/VMSGaurdVisitorRequestList
/// Body (both dates = today, "24/Jul/2026" format):
///   { "dFromDate": "24/Jul/2026", "dToDate": "24/Jul/2026" }
///
/// Same style as [ValidateOtpRepo] in validateOtp.dart.
class GuardVisitorRepo {
  Future<List<GuardVisitor>> getVisitorList(BuildContext context) async {
    try {
      // Both dates = today's date, formatted like "24/Jul/2026".
      final today = DateFormat('dd/MMM/yyyy').format(DateTime.now());
      final body = {"dFromDate": today, "dToDate": today};
      print('----GuardVisitorList BODY----> $body');

      var baseURL = BaseRepo().baseurl;
      var endPoint = "VMSGaurdVisitorRequestList/VMSGaurdVisitorRequestList";
      var apiUrl = "$baseURL$endPoint";
      print('----GuardVisitorList URL----> $apiUrl');

      showLoader();
      var headers = {'Content-Type': 'application/json'};
      var request = http.Request('POST', Uri.parse(apiUrl));
      request.body = json.encode(body);
      request.headers.addAll(headers);

      http.StreamedResponse response = await request.send();
      var data = await response.stream.bytesToString();
      var map = json.decode(data);
      hideLoader();
      print('----GuardVisitorList RESPONSE----> $map');

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
      debugPrint("GuardVisitorList exception: $e");
      rethrow;
    }
  }
}
