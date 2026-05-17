import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ultimate_grid/ultimate_grid.dart';

GridController _build({int rows = 3, int cols = 3}) {
  final schema = GridSchema(
    columns: [
      for (var i = 0; i < cols; i++)
        ColumnSpec(
          id: String.fromCharCode(97 + i),
          header: String.fromCharCode(65 + i),
          defaultWidth: 100,
        ),
    ],
    rows: [for (var i = 0; i < rows; i++) RowSpec(id: 'r$i')],
  );
  final src = MapGridDataSource(
    rowIds: [for (var i = 0; i < rows; i++) 'r$i'],
    colIds: [for (var i = 0; i < cols; i++) String.fromCharCode(97 + i)],
  );
  return GridController(schema: schema, source: src);
}

Future<void> _mount(WidgetTester tester, GridController controller) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 400,
          height: 200,
          child: UltimateTable(controller: controller, autofocus: true),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('arrow keys move selection within the table', (tester) async {
    final controller = _build();
    controller.selectCell(1, 1);
    await _mount(tester, controller);

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
      await _mount(tester, controller);

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

  testWidgets('pageDown / pageUp move the extent vertically by more than 1',
      (tester) async {
    final controller = _build(rows: 100, cols: 3);
    controller.selectCell(0, 0);
    await _mount(tester, controller);

    await tester.sendKeyEvent(LogicalKeyboardKey.pageDown);
    await tester.pump();
    final afterDown = controller.selection.activeRange!.extentRowIndex;
    expect(afterDown, greaterThan(1),
        reason: 'pageDown should move more than a single row');

    await tester.sendKeyEvent(LogicalKeyboardKey.pageUp);
    await tester.pump();
    final afterUp = controller.selection.activeRange!.extentRowIndex;
    expect(afterUp, lessThan(afterDown),
        reason: 'pageUp should move back upward');
  });

  testWidgets('escape inside the in-cell editor closes it without committing',
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

    await tester.tap(find.byType(UltimateBody).first);
    await tester.tap(find.byType(UltimateBody).first);
    await tester.pumpAndSettle();
    expect(find.byType(UltimateCellEditor), findsOneWidget);

    final field = find.descendant(
      of: find.byType(UltimateCellEditor),
      matching: find.byType(EditableText),
    );
    await tester.enterText(field, 'Banana');
    await tester.pump();

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();

    expect(find.byType(UltimateCellEditor), findsNothing,
        reason: 'Escape should close the editor');
    expect(controller.source.valueAt('r1', 'name'), const TextCell('Apple'),
        reason: 'Escape should not commit the edited text');
  });

  testWidgets('enter inside the in-cell editor commits the new value',
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

    await tester.tap(find.byType(UltimateBody).first);
    await tester.tap(find.byType(UltimateBody).first);
    await tester.pumpAndSettle();
    expect(find.byType(UltimateCellEditor), findsOneWidget);

    final field = find.descendant(
      of: find.byType(UltimateCellEditor),
      matching: find.byType(EditableText),
    );
    await tester.enterText(field, 'Cherry');
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();

    expect(find.byType(UltimateCellEditor), findsNothing,
        reason: 'Enter should close the editor');
    expect(controller.source.valueAt('r1', 'name'), const TextCell('Cherry'),
        reason: 'Enter should commit the edited text');
  });

  testWidgets('cmd+C copies the active selection to the system clipboard',
      (tester) async {
    final schema = GridSchema(
      columns: const [
        ColumnSpec(id: 'a', header: 'A'),
        ColumnSpec(id: 'b', header: 'B'),
      ],
      rows: const [RowSpec(id: 'r1'), RowSpec(id: 'r2')],
    );
    final src = MapGridDataSource(rowIds: ['r1', 'r2'], colIds: ['a', 'b']);
    src.setValue('r1', 'a', const TextCell('hello'));
    src.setValue('r1', 'b', const TextCell('world'));
    src.setValue('r2', 'a', const TextCell('foo'));
    src.setValue('r2', 'b', const TextCell('bar'));
    final controller = GridController(schema: schema, source: src);
    controller.selectCell(0, 0);
    controller.extendSelectionTo(1, 1);

    String? captured;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') {
        captured = (call.arguments as Map)['text'] as String?;
      }
      return null;
    });
    addTearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null);
    });

    await _mount(tester, controller);

    await tester.sendKeyDownEvent(LogicalKeyboardKey.metaLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyC);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.metaLeft);
    await tester.pump();

    expect(captured, 'hello\tworld\nfoo\tbar');
  });
}
