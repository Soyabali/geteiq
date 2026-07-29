import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../models/vms_user.dart';
import '../widgets/loader_helper.dart';
import 'baseurl.dart';

/// Fetches the Department dropdown options for the guard's "Add Guest" form.
///
/// Endpoint: VMSUsers/VMSUsers  (GET, no request body / query params)
/// Response:
///   { "Result": "1", "Msg": "Success", "Data": [ { "iUserId": 8, "sUserName": "..." }, ... ] }
///
/// Same style as [GuardVisitorRepo] in VMSGaurdVisitorRequestList.dart, but a
/// plain GET since this endpoint takes no body.
class VmsUsersRepo {
  Future<List<VmsUser>> getUsers(BuildContext context) async {
    try {
      var baseURL = BaseRepo().baseurl;
      var endPoint = "VMSUsers/VMSUsers";
      var apiUrl = "$baseURL$endPoint";
      print('----VMSUsers URL----> $apiUrl');

      showLoader();
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
      );
      final map = json.decode(response.body);
      hideLoader();
      print('----VMSUsers RESPONSE----> $map');

      // Success -> parse the "Data" array into VmsUser models.
      if (response.statusCode == 200 && "${map['Result']}" == "1") {
        final rawList = (map['Data'] as List?) ?? const [];
        return rawList
            .map((e) => VmsUser.fromJson(e as Map<String, dynamic>))
            .toList();
      }

      // Result != 1 (or bad status) -> no options.
      return <VmsUser>[];
    } catch (e) {
      hideLoader();
      debugPrint("VMSUsers exception: $e");
      rethrow;
    }
  }
}
