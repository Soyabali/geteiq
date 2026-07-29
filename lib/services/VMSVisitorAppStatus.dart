import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../widgets/loader_helper.dart';
import 'baseurl.dart';

/// The two decisions management can push for one guard-raised visitor pass.
///
/// The number is what the backend expects in the `iStatus` field — do NOT
/// renumber these, they are the API's contract, not a UI order.
enum VisitorAppStatus {
  approved('1'),
  rejected('2');

  const VisitorAppStatus(this.code);

  /// Value sent as "iStatus".
  final String code;
}

/// Approves / rejects one guard-raised visitor pass from the Gate Log.
///
/// Endpoint: VMSVisitorAppStatus/VMSVisitorAppStatus  (POST)
/// Body:     { "sQRCodeVal": "678249", "iStatus": "1" }
/// Response: { "Result": "1", "Msg": "..." }
///        or { "Result": "0", "Msg": "Something went wrong" }
///
/// Same style as [GuardUpdateStatusRepo] in VMSGaurdUpdateStatus.dart — kept
/// as its own repo/file since it's a different endpoint with a different
/// status contract (only Approve/Reject here, not the 4 guard states).
class VmsVisitorAppStatusRepo {
  Future<Map<String, dynamic>> updateStatus(
    BuildContext context,
    String qrCodeVal, // sQRCodeVal — picked from the tapped GateEntry
    VisitorAppStatus status, // Approved -> "1", Rejected -> "2"
  ) async {
    try {
      final body = {"sQRCodeVal": qrCodeVal, "iStatus": status.code};
      print('----VMSVisitorAppStatus BODY----> $body');

      var baseURL = BaseRepo().baseurl;
      var endPoint = "VMSVisitorAppStatus/VMSVisitorAppStatus";
      var apiUrl = "$baseURL$endPoint";
      print('----VMSVisitorAppStatus URL----> $apiUrl');

      showLoader();
      var headers = {'Content-Type': 'application/json'};
      var request = http.Request('POST', Uri.parse(apiUrl));
      request.body = json.encode(body);
      request.headers.addAll(headers);

      http.StreamedResponse response = await request.send();
      var data = await response.stream.bytesToString();
      var map = json.decode(data);
      hideLoader();
      print('----VMSVisitorAppStatus RESPONSE----> $map');

      // Always hand the decoded map back — the caller reads "Msg" for the
      // toast and "Result" to decide whether the tap actually took effect.
      return map as Map<String, dynamic>;
    } catch (e) {
      hideLoader();
      debugPrint("VMSVisitorAppStatus exception: $e");
      rethrow;
    }
  }
}
