import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ultimate_grid/ultimate_grid.dart';

GridController _build() {
  final schema = GridSchema(
    columns: const [
      ColumnSpec(id: 'a', header: 'A', defaultWidth: 100),
      ColumnSpec(id: 'b', header: 'B', defaultWidth: 100),
      ColumnSpec(id: 'c', header: 'C', defaultWidth: 100),
    ],
    rows: const [
      RowSpec(id: 'r0'),
      RowSpec(id: 'r1'),
      RowSpec(id: 'r2'),
    ],
  );
  final src = MapGridDataSource(
    rowIds: ['r0', 'r1', 'r2'],
    colIds: ['a', 'b', 'c'],
  );
  return GridController(schema: schema, source: src);
}

void main() {
  testWidgets('arrow keys move selection within the table', (tester) async {
    final controller = _build();
    controller.selectCell(1, 1); // start in the middle

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 400,
            height: 200,
            child: UltimateTable(
              controller: controller,
              autofocus: true,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    expect(controller.selection.activeRange!.extentColIndex, 2);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    expect(controller.selection.activeRange!.extentRowIndex, 2);

    await tester.sendKeyEvent(LogicalKeyboardKey.home);
    await tester.pump();
    expect(controller.selection.activeRange!.extentColIndex, 0);

    await tester.sendKeyEvent(LogicalKeyboardKey.end);
    await tester.pump();
    expect(controller.selection.activeRange!.extentColIndex, 2);
  });

  testWidgets(
    'shift+arrow extends the active range instead of moving it',
    (tester) async {
      final controller = _build();
      controller.selectCell(0, 0);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 200,
              child: UltimateTable(
                controller: controller,
                autofocus: true,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await tester.pump();

      final r = controller.selection.activeRange!;
      expect(r.anchorRowIndex, 0);
      expect(r.anchorColIndex, 0);
      expect(r.extentRowIndex, 1);
      expect(r.extentColIndex, 1);
    },
  );
}
