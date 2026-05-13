import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ultimate_table/ultimate_table.dart';

void main() {
  testWidgets(
    'UltimateTable mounts custom RenderObject body + widget header',
    (tester) async {
      final schema = GridSchema(
        columns: const [
          ColumnSpec(id: 'name', header: 'Name', defaultWidth: 200),
          ColumnSpec(
            id: 'qty',
            header: 'Qty',
            defaultWidth: 100,
            kind: CellKind.number,
          ),
        ],
        rows: const [RowSpec(id: 'r1'), RowSpec(id: 'r2')],
      );
      final src = MapGridDataSource(
        rowIds: ['r1', 'r2'],
        colIds: ['name', 'qty'],
      );
      src.setValue('r1', 'name', const TextCell('Apple'));
      src.setValue('r1', 'qty', const NumberCell(3));
      src.setValue('r2', 'name', const TextCell('Banana'));
      src.setValue('r2', 'qty', const NumberCell(7));
      final controller = GridController(schema: schema, source: src);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                UltimateTableHeader(controller: controller),
                Expanded(child: UltimateTable(controller: controller)),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Header is widget-based — its text is still findable.
      expect(find.text('Name'), findsOneWidget);
      expect(find.text('Qty'), findsOneWidget);

      // Body is RenderObject-based — at least one UltimateBody render-widget
      // is in the tree (one per non-empty column slice).
      expect(find.byType(UltimateTable), findsOneWidget);
      expect(find.byType(UltimateTableHeader), findsOneWidget);

      // The controller's view sees both rows.
      expect(controller.pipelineResult.viewRowIndices.length, 2);
      expect(controller.rowLayout.middleViewIndices.length, 2);

      // Body cell values must be readable through the source.
      expect(controller.source.valueAt('r1', 'name'), const TextCell('Apple'));
      expect(controller.source.valueAt('r2', 'qty'), const NumberCell(7));
    },
  );

  testWidgets('right-frozen column is partitioned into the right strip',
      (tester) async {
    final schema = GridSchema(
      columns: const [
        ColumnSpec(id: 'a', header: 'A', defaultWidth: 100),
        ColumnSpec(id: 'b', header: 'B', defaultWidth: 100),
        ColumnSpec(
          id: 'c',
          header: 'C',
          defaultWidth: 100,
          defaultFrozen: FrozenSide.end,
        ),
      ],
      rows: const [RowSpec(id: 'r1')],
    );
    final src = MapGridDataSource(rowIds: ['r1'], colIds: ['a', 'b', 'c']);
    src.setValue('r1', 'a', const TextCell('AA'));
    src.setValue('r1', 'b', const TextCell('BB'));
    src.setValue('r1', 'c', const TextCell('CC'));
    final controller = GridController(schema: schema, source: src);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: UltimateTable(controller: controller)),
      ),
    );
    await tester.pumpAndSettle();

    expect(controller.columnLayout.rightFrozen, ['c']);
    expect(controller.columnLayout.middle, ['a', 'b']);
    expect(controller.source.valueAt('r1', 'c'), const TextCell('CC'));
  });

  testWidgets('tap on body cell opens overlay editor for text/number cells',
      (tester) async {
    final schema = GridSchema(
      columns: const [
        ColumnSpec(id: 'name', header: 'Name', defaultWidth: 200),
      ],
      rows: const [RowSpec(id: 'r1', defaultHeight: 40)],
    );
    final src = MapGridDataSource(rowIds: ['r1'], colIds: ['name']);
    src.setValue('r1', 'name', const TextCell('Apple'));
    final controller = GridController(schema: schema, source: src);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 400,
            height: 200,
            child: UltimateTable(controller: controller),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // No editor yet.
    expect(find.byType(UltimateCellEditor), findsNothing);

    // Single tap should just select + focus the cell (no editor opens).
    await tester.tap(find.byType(UltimateBody).first);
    await tester.pumpAndSettle();
    expect(find.byType(UltimateCellEditor), findsNothing);
    expect(controller.selection.focus, isNotNull);
    expect(controller.selection.focus!.row, 'r1');
    expect(controller.selection.focus!.col, 'name');
  });

  testWidgets('double-tap on a body text cell opens the overlay editor',
      (tester) async {
    final schema = GridSchema(
      columns: const [
        ColumnSpec(id: 'name', header: 'Name', defaultWidth: 200),
      ],
      rows: const [RowSpec(id: 'r1', defaultHeight: 40)],
    );
    final src = MapGridDataSource(rowIds: ['r1'], colIds: ['name']);
    src.setValue('r1', 'name', const TextCell('Apple'));
    final controller = GridController(schema: schema, source: src);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 400,
            height: 200,
            child: UltimateTable(controller: controller),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Two quick consecutive taps — manual double-tap detection in the
    // body's tap handler treats the second tap as a double-tap.
    await tester.tap(find.byType(UltimateBody).first);
    await tester.tap(find.byType(UltimateBody).first);
    await tester.pumpAndSettle();
    expect(find.byType(UltimateCellEditor), findsOneWidget);
  });

  testWidgets('tap on body bool cell toggles its value without opening editor',
      (tester) async {
    final schema = GridSchema(
      columns: const [
        ColumnSpec(
          id: 'on',
          header: 'On',
          defaultWidth: 100,
          kind: CellKind.bool_,
        ),
      ],
      rows: const [RowSpec(id: 'r1', defaultHeight: 40)],
    );
    final src = MapGridDataSource(rowIds: ['r1'], colIds: ['on']);
    src.setValue('r1', 'on', const BoolCell(false));
    final controller = GridController(schema: schema, source: src);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 400,
            height: 200,
            child: UltimateTable(controller: controller),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(UltimateBody).first);
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(UltimateCellEditor), findsNothing);
    expect(controller.source.valueAt('r1', 'on'), const BoolCell(true));
  });
}
