import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ultimate_grid/ultimate_grid.dart';

void main() {
  testWidgets(
    'UltimateTable.headerBuilder renders without overflow even when total '
    'column width exceeds the viewport',
    (tester) async {
      final schema = GridSchema(
        columns: [
          const ColumnSpec(
            id: 'a',
            header: 'A',
            defaultFrozen: FrozenSide.start,
          ),
          for (var i = 0; i < 10; i++)
            ColumnSpec(id: 'c$i', header: 'C$i', defaultWidth: 130),
          const ColumnSpec(id: 'z', header: 'Z', defaultFrozen: FrozenSide.end),
        ],
        rows: const [
          RowSpec(id: 'r0'),
          RowSpec(id: 'r1'),
        ],
      );
      final src = MapGridDataSource(
        rowIds: ['r0', 'r1'],
        colIds: ['a', for (var i = 0; i < 10; i++) 'c$i', 'z'],
      );
      final controller = GridController(schema: schema, source: src);

      // Container 600 px wide; total column width ~1410 px. With the
      // embedded header the middle horizontally scrolls — no RenderFlex
      // overflow should fire.
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 600,
              height: 300,
              child: UltimateTable(
                controller: controller,
                headerBuilder: (ctx, colId) =>
                    Text(controller.schema.column(colId)?.header ?? colId),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Header text for the left-frozen, first scrollable, and right-frozen
      // columns should all be present in the widget tree.
      expect(find.text('A'), findsOneWidget);
      expect(find.text('C0'), findsOneWidget);
      expect(find.text('Z'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Resizing a column via the embedded header updates the controller width',
    (tester) async {
      final schema = GridSchema(
        columns: const [
          ColumnSpec(id: 'a', header: 'A', defaultWidth: 100),
          ColumnSpec(id: 'b', header: 'B', defaultWidth: 100),
        ],
        rows: const [RowSpec(id: 'r0')],
      );
      final src = MapGridDataSource(rowIds: ['r0'], colIds: ['a', 'b']);
      final controller = GridController(schema: schema, source: src);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 300,
              child: UltimateTable(
                controller: controller,
                headerBuilder: (ctx, colId) =>
                    Text(controller.schema.column(colId)?.header ?? colId),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(controller.widthOf('a'), 100);

      // Drag the right edge of column "A" (handle is the rightmost 8 px,
      // so we start from x = 96) by +60 pixels.
      await tester.dragFrom(const Offset(96, 10), const Offset(60, 0));
      await tester.pumpAndSettle();
      expect(controller.widthOf('a'), 160);
    },
  );
}
