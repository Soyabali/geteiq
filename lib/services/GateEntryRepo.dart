import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/gate_entry.dart';
import '../widgets/loader_helper.dart';
import 'baseurl.dart';

/// Gate Log rows, from **two different endpoints** depending on who is logged
/// in. Both take the same body and return the same shape, so one model
/// ([GateEntry]) and one screen serve both roles.
///
/// | `iUserType` | Role | Endpoint |
/// |---|---|---|
/// | `"1"` | Guard | `VisitorEntryByGaurd/VisitorEntryByGaurd` |
/// | anything else (`"2"`, …) | Management | `EntryByGaurd/EntryByGaurd` |
///
/// Body for both: `{ "iUserId": "<from SharedPreferences>" }`
///
/// Same style as the other repos in this folder — see
/// VMSGaurdVisitorRequestList.dart.
class GateEntryRepo {
  Future<List<GateEntry>> getGateEntries(BuildContext context) async {
    try {
      // ================= 1) who is asking? =================
      final prefs = await SharedPreferences.getInstance();
      final iUserType = (prefs.getString('iUserType') ?? '').trim();
      final iUserId = prefs.getString('iUserId') ?? '0';
      final isGuard = iUserType == "1";

      // Guard -> VisitorEntryByGaurd | Management -> EntryByGaurd
      final endPoint = isGuard
          ? "VisitorEntryByGaurd/VisitorEntryByGaurd"
          : "EntryByGaurd/EntryByGaurd";
      final role = isGuard ? 'GUARD' : 'MANAGEMENT';

      // ================= 2) build the request =================
      final body = {"iUserId": iUserId};
      final apiUrl = "${BaseRepo().baseurl}$endPoint";

      print('==================== GATE LOG [$role] ====================');
      print('---- iUserType (SharedPreferences) ----> $iUserType');
      print('---- iUserId   (SharedPreferences) ----> $iUserId');
      print('---- URL  ----> $apiUrl');
      print('---- BODY ----> $body');

      // ================= 3) hit the api =================
      showLoader();
      var headers = {'Content-Type': 'application/json'};
      var request = http.Request('POST', Uri.parse(apiUrl));
      request.body = json.encode(body);
      request.headers.addAll(headers);

      http.StreamedResponse response = await request.send();
      var data = await response.stream.bytesToString();
      var map = json.decode(data);
      hideLoader();

      print('---- STATUS ----> ${response.statusCode}');
      print('---- RESPONSE ----> $map');

      // ================= 4) parse "Data" -> models =================
      if (response.statusCode == 200 && "${map['Result']}" == "1") {
        final rawList = (map['Data'] as List?) ?? const [];
        final rows = rawList
            .map((e) => GateEntry.fromJson(e as Map<String, dynamic>))
            .toList();
        print('---- PARSED ROWS ----> ${rows.length}');
        print('=========================================================');
        return rows;
      }

      // Result != 1 (or bad status) -> no rows.
      print('---- Result != 1 -> returning an empty list ----');
      print('=========================================================');
      return <GateEntry>[];
    } catch (e) {
      hideLoader();
      debugPrint("GateLog exception: $e");
      rethrow;
    }
  }

  /// True when the logged-in user is a guard (`iUserType == "1"`).
  ///
  /// The screen uses this to decide whether to show the Approve / Reject
  /// buttons (management) or the read-only status chip (guard).
  Future<bool> isGuard() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getString('iUserType') ?? '').trim() == "1";
  }
}
