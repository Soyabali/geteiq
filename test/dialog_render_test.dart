import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottie/lottie.dart';
import 'package:vms/widgets/success_dialog.dart';
import 'package:vms/widgets/failure_dialog.dart';

void main() {
  testWidgets('SuccessDialog renders the Lottie (not the icon fallback)', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Builder(builder: (context) {
        return Scaffold(body: Center(child: ElevatedButton(
          onPressed: () => SuccessDialog.show(context, 'Done'),
          child: const Text('go'),
        )));
      }),
    ));
    await tester.tap(find.text('go'));
    await tester.pump();               // open dialog
    await tester.pump(const Duration(milliseconds: 100)); // let asset load
    expect(find.text('Done'), findsOneWidget);
    expect(find.byType(LottieBuilder), findsOneWidget);   // Lottie present
    expect(find.byIcon(Icons.check_circle_rounded), findsNothing); // not fallback
    expect(tester.takeException(), isNull);
    await tester.pump(const Duration(seconds: 3));         // auto-dismiss
    await tester.pumpAndSettle();
    expect(find.text('Done'), findsNothing);
  });

  testWidgets('FailureDialog renders the Lottie (not the icon fallback)', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Builder(builder: (context) {
        return Scaffold(body: Center(child: ElevatedButton(
          onPressed: () => FailureDialog.show(context, 'Oops'),
          child: const Text('go'),
        )));
      }),
    ));
    await tester.tap(find.text('go'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Oops'), findsOneWidget);
    expect(find.byType(LottieBuilder), findsOneWidget);
    expect(find.byIcon(Icons.cancel_rounded), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    expect(find.text('Oops'), findsNothing);
  });
}
