import 'package:flutter_test/flutter_test.dart';
import 'package:ultimate_grid/ultimate_grid.dart';

GridController _build() {
  final schema = GridSchema(
    columns: const [
      ColumnSpec(id: 'name', header: 'Name', defaultWidth: 200),
      ColumnSpec(
        id: 'qty',
        header: 'Qty',
        defaultWidth: 80,
        kind: CellKind.number,
      ),
      ColumnSpec(
        id: 'total',
        header: 'Total',
        defaultWidth: 80,
        defaultFrozen: FrozenSide.end,
      ),
    ],
    rows: const [
      RowSpec(id: 'r1'),
      RowSpec(id: 'r2'),
    ],
  );
  final src = MapGridDataSource(
    rowIds: ['r1', 'r2'],
    colIds: ['name', 'qty', 'total'],
  );
  return GridController(schema: schema, source: src);
}

void main() {
  group('GridController', () {
    test('initial layout honors defaultFrozen from schema', () {
      final c = _build();
      expect(c.columnLayout.middle, ['name', 'qty']);
      expect(c.columnLayout.rightFrozen, ['total']);
    });

    test('setColumnFreeze updates layout in single pass + bumps revision', () {
      final c = _build();
      final r0 = c.revision;
      c.setColumnFreeze('name', FrozenSide.start);
      expect(c.columnLayout.leftFrozen, ['name']);
      expect(c.revision, greaterThan(r0));
    });

    test('reorderColumn moves a column to a new flat index', () {
      final c = _build();
      c.reorderColumn('total', 0);
      expect(c.columnOrder.first, 'total');
    });

    test('source mutation rebuilds derived state once', () {
      final c = _build();
      final r0 = c.revision;
      (c.source as MapGridDataSource).setValue(
        'r1',
        'name',
        const TextCell('apple'),
      );
      expect(c.revision, greaterThan(r0));
    });

    test('setSelection notifies and stores selection', () {
      final c = _build();
      var notified = 0;
      c.addListener(() => notified++);
      c.setSelection(const Selection(ranges: [SelectionRange.cell(0, 0)]));
      expect(notified, 1);
      expect(c.selection.contains(0, 0), isTrue);
      expect(c.selection.contains(1, 1), isFalse);
    });
  });
}
