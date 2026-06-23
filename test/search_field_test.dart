import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ultimate_grid/ultimate_grid.dart';

void main() {
  testWidgets(
    'UltimateSearchField forwards input to controller.setSearchQuery',
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

      // The field is framework-agnostic: it uses EditableText
      // (flutter/widgets.dart), not Material's TextField.
      await tester.enterText(find.byType(EditableText), 'app');
      await tester.pump();
      expect(controller.searchQuery, 'app');
    },
  );

  testWidgets('UltimateSearchField mode toggle flips SearchMode', (
    tester,
  ) async {
    final schema = GridSchema(
      columns: const [ColumnSpec(id: 'a', header: 'A')],
      rows: const [RowSpec(id: 'r1')],
    );
    final src = MapGridDataSource(rowIds: ['r1'], colIds: ['a']);
    final controller = GridController(schema: schema, source: src);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: UltimateSearchField(controller: controller)),
      ),
    );
    await tester.pumpAndSettle();

    expect(controller.searchMode, SearchMode.highlight);
    // The toggle label carries a glyph prefix ('◈ Highlight'), so match
    // on the contained word rather than the exact string.
    await tester.tap(find.textContaining('Highlight'));
    await tester.pump();
    expect(controller.searchMode, SearchMode.filter);
  });
}
