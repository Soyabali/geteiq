import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vms/screens/guard_invite_screen.dart';

void main() {
  testWidgets('Create Invite shows the success dialog, then auto-dismisses', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    // Push the screen from a base route so its success-pop returns cleanly.
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const GuardInviteScreen(),
                  ),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    // Fill the form.
    await tester.enterText(find.byType(TextFormField).at(0), 'Shivangi');
    await tester.enterText(find.byType(TextFormField).at(1), '9876643210');
    await tester.tap(find.text('Select department'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('HR').last);
    await tester.pumpAndSettle();

    // Tap Create Invite → spinner → success dialog.
    await tester.tap(find.text('Create Invite'));
    await tester.pump(); // start submitting
    await tester.pump(const Duration(milliseconds: 700)); // fake network wait
    await tester.pump(); // build dialog

    expect(find.text('Invite created successfully'), findsOneWidget);
    expect(tester.takeException(), isNull);

    // After 4s it auto-closes and the screen pops back to the base route.
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();

    expect(find.text('Invite created successfully'), findsNothing);
    expect(find.text('open'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
