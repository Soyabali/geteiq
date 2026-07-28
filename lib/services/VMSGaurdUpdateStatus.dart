import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../widgets/loader_helper.dart';
import 'baseurl.dart';

/// The four gate-flow states the guard can push for one visitor pass.
///
/// The number is what the backend expects in the `iStatus` field — do NOT
/// renumber these, they are the API's contract, not a UI order.
enum GuardStatus {
  approved('1', 'Approved'),
  checkIn('2', 'Check-in'),
  checkOut('3', 'Check-out'),
  notArrived('4', 'Not arrived');

  const GuardStatus(this.code, this.label);

  /// Value sent as "iStatus".
  final String code;

  /// Human label, used in the toast message.
  final String label;
}

/// Updates one visitor pass's status.
///
/// Endpoint: VMSGaurdUpdateStatus/VMSGaurdUpdateStatus
/// Body: { "sQRCodeVal": "430377", "iStatus": "1" }
/// Response: { "Result": "1", "Msg": "Reply Sent" }
///
/// Same style as [ValidateOtpRepo] in validateOtp.dart.
class GuardUpdateStatusRepo {
  Future updateStatus(
    BuildContext context,
    String qrCodeVal,
    GuardStatus status,
  ) async {
    try {
      final body = {"sQRCodeVal": qrCodeVal, "iStatus": status.code};
      print('----GuardUpdateStatus BODY----> $body');

      var baseURL = BaseRepo().baseurl;
      var endPoint = "VMSGaurdUpdateStatus/VMSGaurdUpdateStatus";
      var apiUrl = "$baseURL$endPoint";
      print('----GuardUpdateStatus URL----> $apiUrl');

      showLoader();
      var headers = {'Content-Type': 'application/json'};
      var request = http.Request('POST', Uri.parse(apiUrl));
      request.body = json.encode(body);
      request.headers.addAll(headers);

      http.StreamedResponse response = await request.send();
      var data = await response.stream.bytesToString();
      var map = json.decode(data);
      hideLoader();

      if (response.statusCode == 200) {
        print('----GuardUpdateStatus RESPONSE 200----> $map');
        return map;
      } else {
        print('----GuardUpdateStatus ERROR ${response.statusCode}----> $map');
        print(response.reasonPhrase);
        return map;
      }
    } catch (e) {
      hideLoader();
      debugPrint("GuardUpdateStatus exception: $e");
      rethrow;
    }
  }
}
