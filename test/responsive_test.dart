import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:vms/models/invite.dart';
import 'package:vms/screens/dashboard_screen.dart';
import 'package:vms/screens/invite_details_screen.dart';
import 'package:vms/screens/login_screen.dart';
import 'package:vms/screens/role_select_screen.dart';
import 'package:vms/screens/select_guests_screen.dart';
import 'package:vms/screens/ticket_screen.dart';
import 'package:vms/theme/app_theme.dart';

/// Real device logical sizes, smallest to largest.
const devices = <String, Size>{
  'iPhone SE': Size(320, 568),
  'iPhone 13 mini': Size(375, 812),
  'iPhone 15 Pro Max': Size(430, 932),
  'Pixel 7': Size(412, 915),
  'iPad Pro 11': Size(834, 1194),
};

Invite _invite() => Invite(
  guests: const [
    Guest(name: 'Amit Sharma', phone: '+91 97111 07824'),
    Guest(name: 'Priya Nair', phone: '+91 81784 06887'),
  ],
  note: 'Inko Andar aane dena',
);

void main() {
  for (final entry in devices.entries) {
    for (final scale in [1.0, 1.35]) {
      testWidgets('${entry.key} @${scale}x has no overflow', (tester) async {
        tester.view.physicalSize = entry.value;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        final screens = <String, Widget>{
          'role': const RoleSelectScreen(),
          'login': const LoginScreen(),
          'dashboard': const DashboardScreen(),
          'selectGuests': SelectGuestsScreen(invite: _invite()),
          'inviteDetails': InviteDetailsScreen(invite: _invite()),
          'ticket': TicketScreen(invite: _invite()),
        };

        for (final s in screens.entries) {
          await tester.pumpWidget(
            MaterialApp(
              theme: AppTheme.light(),
              home: MediaQuery(
                data: MediaQueryData(
                  size: entry.value,
                  textScaler: TextScaler.linear(scale),
                ),
                child: s.value,
              ),
            ),
          );
          await tester.pump();
          expect(
            tester.takeException(),
            isNull,
            reason: '${s.key} on ${entry.key} @${scale}x',
          );
        }
      });
    }
  }
}
