/// Lightweight benchmark harness for ultimate_grid's headless data layer.
///
/// Run with:
///     flutter test test/benchmark_test.dart
///
/// These are intentionally short and CI-friendly — not production-grade
/// micro-benchmarks. Use them as a regression gate ("did sort suddenly
/// double in cost?") rather than a leaderboard.
library;

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ultimate_grid/ultimate_grid.dart';

void main() {
  group('ultimate_grid benchmarks (headless)', () {
    test('build controller + run pipeline over 10k rows × 20 cols', () {
      const rowCount = 10000;
      const colCount = 20;
      final schema = GridSchema(
        columns: [
          for (var c = 0; c < colCount; c++)
            ColumnSpec(
              id: 'c$c',
              header: 'C$c',
              kind: c.isEven ? CellKind.number : CellKind.text,
            ),
        ],
        rows: [for (var r = 0; r < rowCount; r++) RowSpec(id: 'r$r')],
      );
      final src = MapGridDataSource(
        rowIds: [for (var r = 0; r < rowCount; r++) 'r$r'],
        colIds: [for (var c = 0; c < colCount; c++) 'c$c'],
      );
      for (var r = 0; r < rowCount; r++) {
        for (var c = 0; c < colCount; c++) {
          if (c.isEven) {
            src.setValue('r$r', 'c$c', NumberCell((r * 13 + c) % 997));
          } else {
            src.setValue('r$r', 'c$c', TextCell('v-$r-$c'));
          }
        }
      }

      final ctl = Stopwatch()..start();
      final controller = GridController(schema: schema, source: src);
      ctl.stop();

      final sw = Stopwatch()..start();
      controller.setSortKeys([const SortKey('c0', SortDirection.descending)]);
      sw.stop();

      final ft = Stopwatch()..start();
      controller.setFilter('c2', Filters.numberRange(min: 100, max: 800));
      ft.stop();

      final search = Stopwatch()..start();
      controller.setSearchQuery('v-1');
      search.stop();

      // ignore: avoid_print
      print('[bench] controller-build=${ctl.elapsedMilliseconds}ms  '
          'sort=${sw.elapsedMilliseconds}ms  '
          'filter=${ft.elapsedMilliseconds}ms  '
          'search=${search.elapsedMilliseconds}ms  '
          '(viewRows=${controller.pipelineResult.viewRowIndices.length})');

      // Soft ceilings: should be well under these on a modern dev box.
      // CI safety margin x5 — adjust if these become flaky.
      expect(ctl.elapsedMilliseconds, lessThan(5000));
      expect(sw.elapsedMilliseconds, lessThan(5000));
      expect(ft.elapsedMilliseconds, lessThan(5000));
      expect(search.elapsedMilliseconds, lessThan(5000));
    });

    test('ParagraphCache amortizes 1000 lookups of 100 distinct strings', () {
      const distinct = 100;
      const lookups = 1000;
      final cache = ParagraphCache();
      const style = TextStyle(fontSize: 14, color: Color(0xFF000000));
      final sw = Stopwatch()..start();
      for (var i = 0; i < lookups; i++) {
        cache.acquire(
          text: 'cell-${i % distinct}',
          style: style,
          align: TextAlign.left,
          maxWidth: 120,
        );
      }
      sw.stop();
      // ignore: avoid_print
      print('[bench] ParagraphCache 1000 lookups (100 distinct) '
          '= ${sw.elapsedMilliseconds}ms; size=${cache.length}');
      expect(cache.length, distinct);
      expect(sw.elapsedMilliseconds, lessThan(2000));
    });
  });
}
