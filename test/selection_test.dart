import 'package:flutter_test/flutter_test.dart';
import 'package:ultimate_grid/ultimate_grid.dart';

void main() {
  group('Selection', () {
    test('extendActiveTo moves the extent of the last range', () {
      var sel = const Selection(ranges: [SelectionRange.cell(0, 0)]);
      sel = sel.extendActiveTo(rowIndex: 3, colIndex: 4);
      final active = sel.activeRange!;
      expect(active.anchorRowIndex, 0);
      expect(active.anchorColIndex, 0);
      expect(active.extentRowIndex, 3);
      expect(active.extentColIndex, 4);
      expect(sel.contains(0, 0), isTrue);
      expect(sel.contains(2, 2), isTrue);
      expect(sel.contains(3, 4), isTrue);
      expect(sel.contains(4, 4), isFalse);
    });

    test('addRange appends a non-contiguous range (cmd-click)', () {
      var sel = const Selection(ranges: [SelectionRange.cell(0, 0)]);
      sel = sel.addRange(const SelectionRange.cell(5, 5));
      expect(sel.ranges.length, 2);
      expect(sel.contains(0, 0), isTrue);
      expect(sel.contains(5, 5), isTrue);
      expect(sel.contains(2, 2), isFalse);
    });

    test('SelectionRange.row whole-row sentinel covers any column', () {
      const r = SelectionRange.row(7);
      expect(r.contains(7, 0), isTrue);
      expect(r.contains(7, 999), isTrue);
      expect(r.contains(8, 0), isFalse);
    });
  });

  group('GridController selection helpers', () {
    GridController build() {
      final schema = GridSchema(
        columns: const [
          ColumnSpec(id: 'a', header: 'A'),
          ColumnSpec(id: 'b', header: 'B'),
        ],
        rows: const [
          RowSpec(id: 'r1'),
          RowSpec(id: 'r2'),
        ],
      );
      final src = MapGridDataSource(rowIds: ['r1', 'r2'], colIds: ['a', 'b']);
      return GridController(schema: schema, source: src);
    }

    test('selectCell + extendSelectionTo moves only the active range', () {
      final c = build();
      c.selectCell(0, 0);
      c.extendSelectionTo(1, 1);
      expect(c.selection.ranges.length, 1);
      expect(c.selection.contains(0, 0), isTrue);
      expect(c.selection.contains(1, 1), isTrue);
    });

    test('addSelectionRange pushes a new range', () {
      final c = build();
      c.selectCell(0, 0);
      c.addSelectionRange(1, 1);
      expect(c.selection.ranges.length, 2);
    });
  });
}
