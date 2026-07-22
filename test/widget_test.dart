import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:vms/models/invite.dart';
import 'package:vms/screens/dashboard_screen.dart';
import 'package:vms/screens/login_screen.dart';
import 'package:vms/screens/role_select_screen.dart';
import 'package:vms/theme/app_theme.dart';

Widget _wrap(Widget child) => MaterialApp(theme: AppTheme.light(), home: child);

void main() {
  group('Guest', () {
    test('derives initials from one- and two-part names', () {
      expect(const Guest(name: 'Ravi Yadav', phone: '1').initials, 'RY');
      expect(const Guest(name: 'InstaHelp', phone: '1').initials, 'I');
      expect(const Guest(name: '  ', phone: '1').initials, '?');
    });
  });

  group('Invite', () {
    test('end time is start plus the validity window', () {
      final invite = Invite(
        date: DateTime(2026, 7, 21),
        startTime: const TimeOfDayValue(hour: 16, minute: 56),
        validForHours: 8,
      );
      expect(invite.startsAt, DateTime(2026, 7, 21, 16, 56));
      expect(invite.endsAt, DateTime(2026, 7, 22, 0, 56));
    });

    test('generates a 6-digit gate code', () {
      expect(Invite().code, matches(RegExp(r'^\d{6}$')));
    });
  });

  testWidgets('role select offers both sign-in paths', (tester) async {
    await tester.pumpWidget(_wrap(const RoleSelectScreen()));

    expect(find.text('Management Login'), findsOneWidget);
    expect(find.text('Login as Guard'), findsOneWidget);
  });

  testWidgets('login reveals OTP only after a valid number is sent', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(const LoginScreen(role: UserRole.management)),
    );

    // OTP block stays hidden until a code has been requested.
    expect(find.text('Enter 4-digit code'), findsNothing);

    await tester.enterText(find.byType(TextField).first, '9876543210');
    await tester.pump();
    await tester.tap(find.text('Send OTP'));

    // Fixed pumps rather than pumpAndSettle: the resend countdown ticks for
    // 30s, so the tree never reaches a settled state.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Enter 4-digit code'), findsOneWidget);

    // Let the countdown finish so no timer outlives the test.
    await tester.pump(const Duration(seconds: 31));
  });

  testWidgets('dashboard renders its four action tiles', (tester) async {
    await tester.pumpWidget(_wrap(const DashboardScreen()));
    await tester.pump();

    expect(find.text('Invite guest list'), findsOneWidget);
    expect(find.text('Invited by Guard'), findsOneWidget);
    expect(find.text('Yesterday guest list'), findsOneWidget);
    expect(find.text('Month guest Report'), findsOneWidget);
    expect(find.text('Add Guest'), findsOneWidget);
  });
}
