import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';

/// Whether the device currently has **working** internet.
///
/// connectivity_plus only reports the network *interface* (Wi-Fi, mobile
/// data, none, ...) — a phone can be joined to a Wi-Fi router with no
/// upstream internet (a captive portal, a router that's down) and still
/// report `wifi`. So every check here first rules out "no interface at
/// all", then confirms with a real DNS lookup, the same two-step check most
/// apps (Amazon included) use for their offline banner.
class ConnectivityService {
  ConnectivityService._();
  static final ConnectivityService instance = ConnectivityService._();

  final _connectivity = Connectivity();

  /// True only if there's a network interface (Wi-Fi or mobile data) AND it
  /// can actually reach the internet right now.
  Future<bool> hasInternet() async {
    final results = await _connectivity.checkConnectivity();
    // Per connectivity_plus docs, ConnectivityResult.none is only ever
    // present on its own — no interface at all, so no point probing further.
    if (results.contains(ConnectivityResult.none)) return false;
    return _canReachInternet();
  }

  Future<bool> _canReachInternet() async {
    try {
      final result = await InternetAddress.lookup(
        'google.com',
      ).timeout(const Duration(seconds: 4));
      return result.isNotEmpty && result.first.rawAddress.isNotEmpty;
    } on Exception {
      return false;
    }
  }
}
