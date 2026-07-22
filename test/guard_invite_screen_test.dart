import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vms/screens/guard_invite_screen.dart';

void main() {
  testWidgets('Department picker opens without overflow on a small screen', (
    tester,
  ) async {
    // iPhone SE — the shortest phone we support. This is where the picker
    // sheet used to overflow because its list wasn't scrollable.
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MaterialApp(home: GuardInviteScreen()));
    await tester.pump();

    await tester.tap(find.text('Select department'));
    await tester.pumpAndSettle();

    // The sheet is open (a department row only exists in the picker) and no
    // RenderFlex overflowed while laying it out.
    expect(find.text('Facility'), findsOneWidget);
    expect(tester.takeException(), isNull);

    // Picking a department fills the field.
    await tester.tap(find.text('IT').last);
    await tester.pumpAndSettle();
    expect(find.text('IT'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
