import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ultimate_grid/ultimate_grid.dart';

void main() {
  testWidgets('UltimateResizableHeader drag widens a column', (tester) async {
    final schema = GridSchema(
      columns: const [
        ColumnSpec(id: 'a', header: 'A', defaultWidth: 100),
        ColumnSpec(id: 'b', header: 'B', defaultWidth: 100),
      ],
      rows: const [RowSpec(id: 'r1')],
    );
    final src = MapGridDataSource(rowIds: ['r1'], colIds: ['a', 'b']);
    final controller = GridController(schema: schema, source: src);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 400,
            child: UltimateResizableHeader(controller: controller),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(controller.widthOf('a'), 100);

    // Drag the right edge of column "a" (at x ~100) by +50 pixels.
    const handleX = 100.0 - 4; // inside the 8-px-wide handle
    await tester.dragFrom(const Offset(handleX, 10), const Offset(50, 0));
    await tester.pump();

    expect(controller.widthOf('a'), 150);
  });

  testWidgets('UltimateResizableHeader tap fires onTapColumn', (tester) async {
    final schema = GridSchema(
      columns: const [
        ColumnSpec(id: 'a', header: 'A', defaultWidth: 100),
      ],
      rows: const [RowSpec(id: 'r1')],
    );
    final src = MapGridDataSource(rowIds: ['r1'], colIds: ['a']);
    final controller = GridController(schema: schema, source: src);
    ColId? tapped;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 400,
            child: UltimateResizableHeader(
              controller: controller,
              onTapColumn: (_, id) => tapped = id,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Tap on the header body (away from the right edge).
    await tester.tapAt(const Offset(20, 10));
    await tester.pump();

    expect(tapped, 'a');
  });
}
