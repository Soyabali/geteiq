import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vms/screens/month_guest_report_screen.dart';

void main() {
  testWidgets('Month report renders stat tiles and the report list', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: MonthGuestReportScreen()));

    // Let the (delayed) repository future resolve.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump();

    // Stat tiles.
    expect(find.text('142'), findsOneWidget);
    expect(find.text('Total'), findsOneWidget);
    expect(find.text('Checked in'), findsOneWidget);
    // 'Interviews' is both a stat-tile label and a report-row title.
    expect(find.text('Interviews'), findsNWidgets(2));

    // Report list rows — the part that was rendering blank before.
    expect(find.text('Total Guests'), findsOneWidget);
    expect(find.text('Checked In'), findsOneWidget);
    expect(find.text('Peak Day'), findsOneWidget);

    // No layout/other exception was swallowed during the build.
    expect(tester.takeException(), isNull);
  });

  testWidgets('Tapping a report row opens its detail screen', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: MonthGuestReportScreen()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump();

    await tester.tap(find.text('Total Guests'));
    await tester.pumpAndSettle();

    // Detail screen shows a breakdown fact.
    expect(find.text('Guard entries'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
