import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_notification.dart';
import '../widgets/loader_helper.dart';
import 'baseurl.dart';

/// Notification rows for the logged-in user (the app-bar bell on the
/// dashboard).
///
/// Endpoint: NotificationList/NotificationList  (POST)
/// Body:     `{ "iUserId": "<from SharedPreferences, saved at login>" }`
/// Response: { "Result": "1", "Msg": "Success", "Data": [ { sTitle,
///             sNotification, dReceivedAt, sImageUrl }, ... ] }
///
/// Same style as [VmsVisitorDetailsByManagementRepo] in
/// VmsVisitorDetailsByManagement.dart — the only input is the login `iUserId`.
class NotificationListRepo {
  Future<List<AppNotification>> getNotifications(BuildContext context) async {
    try {
      // iUserId -> saved at login time by login_screen.dart.
      final prefs = await SharedPreferences.getInstance();
      final iUserId = prefs.getString('iUserId') ?? '0';
      print('----NotificationList iUserId (SharedPreferences)----> $iUserId');

      final body = {"iUserId": iUserId};
      print('----NotificationList BODY----> $body');

      var baseURL = BaseRepo().baseurl;
      var endPoint = "NotificationList/NotificationList";
      var apiUrl = "$baseURL$endPoint";
      print('----NotificationList URL----> $apiUrl');

      showLoader();
      var headers = {'Content-Type': 'application/json'};
      var request = http.Request('POST', Uri.parse(apiUrl));
      request.body = json.encode(body);
      request.headers.addAll(headers);

      http.StreamedResponse response = await request.send();
      var data = await response.stream.bytesToString();
      var map = json.decode(data);
      hideLoader();
      print('----NotificationList RESPONSE----> $map');

      // Success -> parse the "Data" array into AppNotification models.
      if (response.statusCode == 200 && "${map['Result']}" == "1") {
        final rawList = (map['Data'] as List?) ?? const [];
        final rows = rawList
            .map((e) => AppNotification.fromJson(e as Map<String, dynamic>))
            .toList();
        print('----NotificationList PARSED ROWS----> ${rows.length}');
        return rows;
      }

      // Result != 1 (or bad status) -> no rows.
      print('----NotificationList Result != 1 -> empty list----');
      return <AppNotification>[];
    } catch (e) {
      hideLoader();
      debugPrint("NotificationList exception: $e");
      rethrow;
    }
  }
}
