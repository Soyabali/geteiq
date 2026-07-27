import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/loader_helper.dart';
import 'baseurl.dart';


class VmsUpdateVisitorgsmid {

  // this is a loginApi call functin

  Future vmsUpdateVisitorGsmid(BuildContext context, token) async {
    // sharedPreference
    SharedPreferences prefs = await SharedPreferences.getInstance();
    //String? sToken = prefs.getString('sToken');
    String? iUserId = prefs.getString('iUserType');// iUserType

    try {
      print("----firebase Token------22----------$token");
      print("----iUserId   --23-----$iUserId");

      var baseURL = BaseRepo().baseurl;
      var endPoint = "UdpateGSMId/UdpateGSMId";
      var registrationApi = "$baseURL$endPoint";
      print('------------17---gsmid---$registrationApi');

      showLoader();
      // var headers = {'Content-Type': 'application/json'};
      var headers = {
        //'token': '$sToken',
        'Content-Type': 'application/json'
      };

      var request = http.Request('POST', Uri.parse('$registrationApi'));
      request.body = json.encode(
          {
            "iUserId": iUserId,
           // "sGSMid":token,
          });
      request.headers.addAll(headers);
      http.StreamedResponse response = await request.send();
      var map;
      var data = await response.stream.bytesToString();
      map = json.decode(data);
      print('----------20---update fir4ebase token RESPONSE----$map');

      if (response.statusCode == 200) {
        // create an instance of auth class
        print('----44-${response.statusCode}');
        hideLoader();
        print('----------22-----$map');
        return map;
      } else {
        print('----------29---Gsmid RESPONSE----$map');
        hideLoader();
        print(response.reasonPhrase);
        return map;
      }
    } catch (e) {
      hideLoader();
      debugPrint("exception: $e");
      throw e;
    }
  }

}
