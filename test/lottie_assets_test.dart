import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottie/lottie.dart';

/// Verifies the hand-authored Lottie files actually parse into a valid
/// composition (so they animate, instead of falling back to the icon).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final asset in const [
    'assets/lottie/success.json',
    'assets/lottie/error.json',
  ]) {
    test('$asset parses into a Lottie composition', () async {
      final data = await rootBundle.load(asset);
      final bytes = data.buffer.asUint8List();
      final composition = await LottieComposition.fromBytes(bytes);

      // A real animation: non-zero duration and at least one layer.
      expect(composition.duration.inMilliseconds, greaterThan(0));
      expect(jsonDecode(utf8.decode(bytes))['layers'], isNotEmpty);
    });
  }
}
