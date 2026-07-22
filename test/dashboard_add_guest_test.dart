import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vms/models/user_role.dart';
import 'package:vms/screens/dashboard_screen.dart';

void main() {
  // The "Add Guest" button branches on the hard-coded [kLoggedInRole] on the
  // dashboard page. This test follows whatever that value is set to, so it
  // stays correct whether you're building the guard or the management flow.
  testWidgets('Add Guest opens the flow matching kLoggedInRole', (
    tester,
  ) async {
    // Render at an iPhone-sized viewport (the app is laid out phone-first);
    // the default test surface is a wide desktop canvas that doesn't match
    // any real device.
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: DashboardScreen()));
    await tester.pump();

    await tester.tap(find.text('Add Guest'));
    await tester.pumpAndSettle();

    if (kLoggedInRole == UserRole.guard) {
      // Guard → full-screen "Invite Setup" (GuardInviteScreen).
      expect(find.text('Invite Setup'), findsOneWidget);
      expect(
        find.text('Manually add a walk-in guest at the gate'),
        findsOneWidget,
      );
    } else {
      // Management → the existing Invite bottom sheet.
      expect(find.text('Select Guest(s)'), findsOneWidget);
    }

    expect(tester.takeException(), isNull);
  });
}
