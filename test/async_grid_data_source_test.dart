import 'package:flutter_test/flutter_test.dart';
import 'package:ultimate_grid/ultimate_grid.dart';

void main() {
  group('AsyncGridDataSource', () {
    test(
      'returns loading placeholder before the page resolves, then real cells',
      () async {
        final rowIds = [for (var i = 0; i < 10; i++) 'r$i'];
        final colIds = ['a', 'b'];
        var fetchCount = 0;
        final src = AsyncGridDataSource(
          rowIds: rowIds,
          colIds: colIds,
          pageSize: 5,
          fetchRange: (start, end) async {
            fetchCount++;
            final cells = <RowId, Map<ColId, CellValue>>{};
            for (var i = start; i < end; i++) {
              cells[rowIds[i]] = {
                'a': TextCell('A$i'),
                'b': NumberCell(i.toDouble()),
              };
            }
            return AsyncPage(rowIds: rowIds.sublist(start, end), cells: cells);
          },
        );

        // First read kicks off a fetch and returns the placeholder.
        final first = src.valueAt('r0', 'a');
        expect(first, isA<TextCell>());
        expect((first as TextCell).value, '…');
        expect(fetchCount, 1);
        expect(src.isRowLoaded(0), isFalse);

        // Repeated reads in the same frame don't trigger a second fetch.
        src.valueAt('r1', 'a');
        src.valueAt('r2', 'b');
        expect(fetchCount, 1);

        // Wait for the page to resolve.
        await Future<void>.delayed(const Duration(milliseconds: 10));

        expect(src.isRowLoaded(0), isTrue);
        expect(src.isRowLoaded(4), isTrue);
        expect(src.isRowLoaded(5), isFalse);
        expect(src.valueAt('r0', 'a'), const TextCell('A0'));
        expect(src.valueAt('r4', 'b'), const NumberCell(4));
      },
    );

    test('prefetchRow fetches without going through valueAt', () async {
      final rowIds = [for (var i = 0; i < 10; i++) 'r$i'];
      var fetchCount = 0;
      final src = AsyncGridDataSource(
        rowIds: rowIds,
        colIds: const ['a'],
        pageSize: 5,
        fetchRange: (start, end) async {
          fetchCount++;
          return AsyncPage(
            rowIds: rowIds.sublist(start, end),
            cells: {
              for (var i = start; i < end; i++)
                rowIds[i]: {'a': TextCell('A$i')},
            },
          );
        },
      );
      src.prefetchRow(7); // page index 1 (5-9)
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(fetchCount, 1);
      expect(src.isRowLoaded(7), isTrue);
      expect(src.valueAt('r7', 'a'), const TextCell('A7'));
    });

    test(
      'invalidate(page:) drops a page and re-fetches on next read',
      () async {
        final rowIds = [for (var i = 0; i < 6; i++) 'r$i'];
        var counter = 0;
        final src = AsyncGridDataSource(
          rowIds: rowIds,
          colIds: const ['a'],
          pageSize: 3,
          fetchRange: (start, end) async {
            counter++;
            return AsyncPage(
              rowIds: rowIds.sublist(start, end),
              cells: {
                for (var i = start; i < end; i++)
                  rowIds[i]: {'a': TextCell('v${counter}_$i')},
              },
            );
          },
        );
        src.prefetchRow(0);
        await Future<void>.delayed(const Duration(milliseconds: 10));
        expect(src.valueAt('r0', 'a'), const TextCell('v1_0'));

        src.invalidate(page: 0);
        // Now stale: returns placeholder and kicks a new fetch.
        expect(src.valueAt('r0', 'a'), const TextCell('…'));
        await Future<void>.delayed(const Duration(milliseconds: 10));
        expect(src.valueAt('r0', 'a'), const TextCell('v2_0'));
      },
    );
  });

  group('GridController selection helpers (Phase 8 additions)', () {
    GridController build() {
      final schema = GridSchema(
        columns: const [
          ColumnSpec(id: 'a', header: 'A'),
          ColumnSpec(id: 'b', header: 'B'),
        ],
        rows: const [
          RowSpec(id: 'r0'),
          RowSpec(id: 'r1'),
        ],
      );
      final src = MapGridDataSource(rowIds: ['r0', 'r1'], colIds: ['a', 'b']);
      return GridController(schema: schema, source: src);
    }

    test('selectRow uses the row-sentinel range that covers every column', () {
      final c = build();
      c.selectRow(1);
      expect(c.selection.activeRange!.isWholeRow, isTrue);
      expect(c.selection.contains(1, 0), isTrue);
      expect(c.selection.contains(1, 999), isTrue);
      expect(c.selection.contains(0, 0), isFalse);
    });

    test('selectColumn uses the column-sentinel range', () {
      final c = build();
      c.selectColumn(0);
      expect(c.selection.activeRange!.isWholeColumn, isTrue);
      expect(c.selection.contains(0, 0), isTrue);
      expect(c.selection.contains(999, 0), isTrue);
      expect(c.selection.contains(0, 1), isFalse);
    });

    test('selectAll covers every cell in the visible view', () {
      final c = build();
      c.selectAll();
      expect(c.selection.contains(0, 0), isTrue);
      expect(c.selection.contains(1, 1), isTrue);
    });
  });
}
