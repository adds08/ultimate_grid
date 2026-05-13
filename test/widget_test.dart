import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_grid/main.dart';
import 'package:flutter_grid/widgets/timesheet_grid.dart';

void main() {
  testWidgets('Unified app launches with sidebar visible (desktop layout)',
      (tester) async {
    // Force a wide viewport so the side-nav layout is selected.
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(const UltimateTableApp());
    await tester.pumpAndSettle();

    expect(find.text('Ultimate Table'), findsOneWidget);
    // Every example label appears in the sidebar. Some labels (like
    // "Budget") also appear as a column header inside the active
    // example, so we assert "at least one" rather than "exactly one".
    expect(find.text('Budget'), findsAtLeast(1));
    expect(find.text('Timesheet'), findsOneWidget);
    expect(find.text('Inventory'), findsOneWidget);
    expect(find.text('Datagrid'), findsOneWidget);
    expect(find.text('Spreadsheet'), findsOneWidget);
    expect(find.text('Stress test'), findsOneWidget);
  });

  testWidgets(
    'Timesheet example (mounted directly) renders the headline columns',
    (tester) async {
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(home: TimesheetGrid()),
      );
      await tester.pumpAndSettle();
      expect(find.text('CREW'), findsOneWidget);
      expect(find.text('HOURS'), findsOneWidget);
      expect(find.text('OT'), findsOneWidget);
      expect(find.text('PER DIEM'), findsOneWidget);
      expect(find.text('Martinez, Carlos'), findsOneWidget);
      expect(find.text('02-200'), findsOneWidget);
    },
  );
}
