import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ultimate_table/ultimate_table.dart';

void main() {
  testWidgets('UltimateSearchField forwards input to controller.setSearchQuery',
      (tester) async {
    final schema = GridSchema(
      columns: const [ColumnSpec(id: 'a', header: 'A')],
      rows: const [RowSpec(id: 'r1')],
    );
    final src = MapGridDataSource(rowIds: ['r1'], colIds: ['a']);
    src.setValue('r1', 'a', const TextCell('apple'));
    final controller = GridController(schema: schema, source: src);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: UltimateSearchField(
            controller: controller,
            showFilterToggle: false,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'app');
    await tester.pump();
    expect(controller.searchQuery, 'app');
  });

  testWidgets('UltimateSearchField mode toggle flips SearchMode',
      (tester) async {
    final schema = GridSchema(
      columns: const [ColumnSpec(id: 'a', header: 'A')],
      rows: const [RowSpec(id: 'r1')],
    );
    final src = MapGridDataSource(rowIds: ['r1'], colIds: ['a']);
    final controller = GridController(schema: schema, source: src);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: UltimateSearchField(controller: controller),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(controller.searchMode, SearchMode.highlight);
    await tester.tap(find.text('Highlight'));
    await tester.pump();
    expect(controller.searchMode, SearchMode.filter);
  });
}
