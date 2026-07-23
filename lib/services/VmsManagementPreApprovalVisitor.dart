import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import '../models/invite.dart';
import '../widgets/loader_helper.dart';
import 'baseurl.dart';

/// Creates a guest pre-approval (invite).
///
/// API endpoint:
///   VmsManagementPreApprovalVisitor/VmsManagementPreApprovalVisitor
///
/// Same style as [GetOtpRepo] in getOtp.dart.
class PreApprovalVisitorRepo {
  Future createPreApproval(BuildContext context, Invite invite) async {
    try {
      // ---------- 1) build the body in the EXACT format the backend wants ----------

      // dDate -> "24/Jul/2026"  (day / short-month / year)
      final dDate = DateFormat('dd/MMM/yyyy').format(invite.date);

      // dTime -> "18:00"  (24-hour, NO am/pm)
      final st =
          invite.startTime ?? TimeOfDayValue.fromDateTime(DateTime.now());
      final dTime =
          '${st.hour.toString().padLeft(2, '0')}:${st.minute.toString().padLeft(2, '0')}';

      // iValidHours -> only the number, e.g. "1"  (no "Hour" / "Hours")
      final iValidHours = invite.validForHours.toString();

      // GuestList -> "[{sGuestName:Amit,sContactNo:9711107824},{...}]"
      // One {..} block per selected guest:
      //   1 guest  -> one block
      //   many     -> many blocks joined by comma
      final guestBlocks = invite.guests.map((g) {
        final digits = g.phone.replaceAll(RegExp(r'\D'), ''); // keep only 0-9
        // take the last 10 digits so "+91 97111 07824" -> "9711107824"
        final contactNo = digits.length > 10
            ? digits.substring(digits.length - 10)
            : digits;
        return '{sGuestName:${g.name},sContactNo:$contactNo}';
      }).join(',');
      final guestList = '[$guestBlocks]';

      var body = {
        "dDate": dDate,
        "dTime": dTime,
        "iValidHours": iValidHours,
        "sNote": invite.note,
        "iRequestedBy": "0", // TODO: put the logged-in user id here later
        "GuestList": guestList,
      };
      print('----PreApproval BODY----> $body');

      // ---------- 2) hit the api ----------
      var baseURL = BaseRepo().baseurl;
      var endPoint =
          "VmsManagementPreApprovalVisitor/VmsManagementPreApprovalVisitor";
      var apiUrl = "$baseURL$endPoint";
      print('----PreApproval URL----> $apiUrl');

      showLoader();
      var headers = {'Content-Type': 'application/json'};
      var request = http.Request('POST', Uri.parse(apiUrl));
      request.body = json.encode(body);
      request.headers.addAll(headers);

      http.StreamedResponse response = await request.send();
      var data = await response.stream.bytesToString();
      var map = json.decode(data);

      // ---------- 3) return the response ----------
      if (response.statusCode == 200) {
        hideLoader();
        // Example success response:
        // { "Result": "1", "Msg": "Record Saved Successfully.",
        //   "QRCode": "https://.../QRCodes/xxxx.png" }
        print('----PreApproval RESPONSE 200----> $map');
        return map;
      } else {
        hideLoader();
        print('----PreApproval ERROR ${response.statusCode}----> $map');
        print(response.reasonPhrase);
        return map;
      }
    } catch (e) {
      hideLoader();
      debugPrint("PreApproval exception: $e");
      rethrow;
    }
  }
}
