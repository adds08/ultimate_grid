import 'package:flutter_test/flutter_test.dart';
import 'package:ultimate_grid/ultimate_grid.dart';

void main() {
  group('Filters helpers', () {
    test('textContains is case-insensitive and ignores EmptyCell', () {
      final p = Filters.textContains('App');
      expect(p(const TextCell('Apple')), isTrue);
      expect(p(const TextCell('banana')), isFalse);
      expect(p(const EmptyCell()), isFalse);
    });

    test('oneOf matches any string representation', () {
      final p = Filters.oneOf(['1', '2']);
      expect(p(const NumberCell(1)), isTrue);
      expect(p(const NumberCell(3)), isFalse);
      expect(p(const TextCell('1')), isTrue);
    });

    test('numberRange is inclusive on both ends', () {
      final p = Filters.numberRange(min: 10, max: 20);
      expect(p(const NumberCell(9.99)), isFalse);
      expect(p(const NumberCell(10)), isTrue);
      expect(p(const NumberCell(20)), isTrue);
      expect(p(const NumberCell(20.01)), isFalse);
    });
  });

  group('GridController column hide / search mode', () {
    GridController build() {
      final schema = GridSchema(
        columns: const [
          ColumnSpec(id: 'a', header: 'A'),
          ColumnSpec(id: 'b', header: 'B'),
          ColumnSpec(id: 'c', header: 'C'),
        ],
        rows: const [
          RowSpec(id: 'r1'),
          RowSpec(id: 'r2'),
          RowSpec(id: 'r3'),
        ],
      );
      final src = MapGridDataSource(
        rowIds: ['r1', 'r2', 'r3'],
        colIds: ['a', 'b', 'c'],
      );
      src.setValue('r1', 'a', const TextCell('apple'));
      src.setValue('r2', 'a', const TextCell('banana'));
      src.setValue('r3', 'a', const TextCell('cherry'));
      return GridController(schema: schema, source: src);
    }

    test('hideColumn removes the column from layout in all regions', () {
      final c = build();
      c.hideColumn('b');
      expect(c.columnLayout.middle.contains('b'), isFalse);
      expect(c.isColumnHidden('b'), isTrue);
      expect(c.columnLayout.widths.length, 2);
    });

    test('showColumn re-adds a previously hidden column', () {
      final c = build();
      c.hideColumn('b');
      c.showColumn('b');
      expect(c.columnLayout.middle.contains('b'), isTrue);
      expect(c.isColumnHidden('b'), isFalse);
    });

    test('SearchMode.filter drops non-matching rows from the view', () {
      final c = build();
      c.setSearchMode(SearchMode.filter);
      c.setSearchQuery('app');
      expect(c.pipelineResult.viewRowIndices.length, 1);
      expect(c.pipelineResult.hasSearch, isFalse); // hits bitset unused
    });

    test('SearchMode.highlight keeps every row and marks hits', () {
      final c = build();
      c.setSearchQuery('app');
      expect(c.pipelineResult.viewRowIndices.length, 3);
      expect(c.pipelineResult.hasSearch, isTrue);
      expect(c.pipelineResult.isSearchHit(0), isTrue);
      expect(c.pipelineResult.isSearchHit(1), isFalse);
    });

    test('fitColumnToText resizes to the widest measured value + padding', () {
      final c = build();
      // measure returns 10-px per character — easy to assert above the
      // schema's minWidth (40) clamp.
      final w = c.fitColumnToText(
        id: 'a',
        measure: (text) => text.length * 10.0,
        padding: 4,
      );
      // longest visible value is "banana" (6 chars) → 60 + 4 = 64.
      expect(w, 64);
      expect(c.widthOf('a'), 64);
    });
  });
}
