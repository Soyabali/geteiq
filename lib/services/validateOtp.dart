import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../widgets/loader_helper.dart';
import 'baseurl.dart';

class ValidateOtpRepo {
  // this is a loginApi call functin
  ///GeneralFunction generalFunction = GeneralFunction();

  Future validateOtp(BuildContext context, String otpNumber, String phoneNumber) async {
    // sharedPreference
    // SharedPreferences prefs = await SharedPreferences.getInstance();
    // String? sToken = prefs.getString('sToken');
    // String? mobileNo = prefs.getString('mobileNo');
    //String? mobileNo = prefs.getString('mobileNo');

    try {
       print('----otp-----17--$otpNumber');
       print('----mobileNo------18-$phoneNumber');
      // print('----sToken------18-$sToken');
      //print('----phoneNumber------18-$phoneNumber');

      var baseURL = BaseRepo().baseurl;
      var endPoint = "VmsApiManagementValidateOtp/VmsApiManagementValidateOtp";
      var validateOtpApi = "$baseURL$endPoint";
      print('------------17---validateOtpApi---$validateOtpApi');

      showLoader();
      var headers = {'Content-Type': 'application/json'};
      // var headers = {
      //   'token': '$sToken',
      //   'Content-Type': 'application/json'
      // };

      var request = http.Request('POST', Uri.parse('$validateOtpApi'));
      request.body = json.encode(
          {
            "sContactNo": phoneNumber,
            // ============ CHANGE HERE (OTP sent to backend) ============
            // Now it sends the OTP the user typed (comes from login_screen).
            // Backend test OTP = "1982", so typing 1982 works while testing.
            // If you want to hard-code it here instead, use:  "sOtp": "1982",
            "sOtp": otpNumber,
            // ===========================================================
          });
      request.headers.addAll(headers);
      http.StreamedResponse response = await request.send();
      var map;
      var data = await response.stream.bytesToString();
      map = json.decode(data);
      print('----------20---LOGINaPI RESPONSE----$map');

      if (response.statusCode == 200) {
        // create an instance of auth class
        print('----44-${response.statusCode}');
        hideLoader();
        print('----------22-----$map');
        return map;
      } else {
        print('----------29---Otp response----$map');
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
