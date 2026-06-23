import 'package:flutter_test/flutter_test.dart';
import 'package:ultimate_grid/ultimate_grid.dart';

GridController _build() {
  final schema = GridSchema(
    columns: const [
      ColumnSpec(id: 'a', header: 'A'),
      ColumnSpec(id: 'b', header: 'B', kind: CellKind.number),
    ],
    rows: const [
      RowSpec(id: 'r1'),
      RowSpec(id: 'r2'),
      RowSpec(id: 'r3'),
    ],
  );
  final src = MapGridDataSource(rowIds: ['r1', 'r2', 'r3'], colIds: ['a', 'b']);
  src.setValue('r1', 'a', const TextCell('apple'));
  src.setValue('r1', 'b', const NumberCell(3));
  src.setValue('r2', 'a', const TextCell('banana'));
  src.setValue('r2', 'b', const NumberCell(7));
  src.setValue('r3', 'a', const TextCell('cherry'));
  src.setValue('r3', 'b', const NumberCell(12));
  return GridController(schema: schema, source: src);
}

void main() {
  group('GridClipboard.selectionAsTsv', () {
    test('serializes a single-cell selection', () {
      final c = _build();
      c.selectCell(1, 0);
      expect(GridClipboard.selectionAsTsv(c), 'banana');
    });

    test('serializes a rectangular selection as tab + newline TSV', () {
      final c = _build();
      c.selectCell(0, 0);
      c.extendSelectionTo(2, 1);
      expect(
        GridClipboard.selectionAsTsv(c),
        'apple\t3\nbanana\t7\ncherry\t12',
      );
    });

    test('empty selection produces empty string', () {
      final c = _build();
      expect(GridClipboard.selectionAsTsv(c), '');
    });

    test('multi-range selection uses the bounding rectangle', () {
      final c = _build();
      c.selectCell(0, 0);
      c.addSelectionRange(2, 1); // non-contiguous; bbox is (0..2) x (0..1)
      expect(
        GridClipboard.selectionAsTsv(c),
        'apple\t3\nbanana\t7\ncherry\t12',
      );
    });
  });
}
