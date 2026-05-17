import 'package:flutter_test/flutter_test.dart';
import 'package:ultimate_grid/ultimate_grid.dart';

MapGridDataSource _src() {
  final src = MapGridDataSource(
    rowIds: ['r1', 'r2', 'r3', 'r4'],
    colIds: ['name', 'qty'],
  );
  src.setValue('r1', 'name', const TextCell('apple'));
  src.setValue('r2', 'name', const TextCell('banana'));
  src.setValue('r3', 'name', const TextCell('cherry'));
  src.setValue('r4', 'name', const TextCell('date'));
  src.setValue('r1', 'qty', const NumberCell(3));
  src.setValue('r2', 'qty', const NumberCell(1));
  src.setValue('r3', 'qty', const NumberCell(2));
  src.setValue('r4', 'qty', const NumberCell(4));
  return src;
}

void main() {
  group('ViewPipeline', () {
    test('passthrough: indices match source row order', () {
      final src = _src();
      final r = ViewPipeline.run(
        source: src,
        sortKeys: const [],
        filters: const {},
        query: '',
      );
      expect(r.viewRowIndices, [0, 1, 2, 3]);
      expect(r.hasSearch, isFalse);
    });

    test('filter drops non-matching rows in one pass', () {
      final src = _src();
      final r = ViewPipeline.run(
        source: src,
        sortKeys: const [],
        filters: {
          'qty': (v) => v is NumberCell && v.value >= 2,
        },
        query: '',
      );
      expect(r.viewRowIndices, [0, 2, 3]); // r1 qty=3, r3 qty=2, r4 qty=4
    });

    test('sort ascending by numeric column', () {
      final src = _src();
      final r = ViewPipeline.run(
        source: src,
        sortKeys: const [SortKey('qty', SortDirection.ascending)],
        filters: const {},
        query: '',
      );
      expect(r.viewRowIndices, [1, 2, 0, 3]); // qty: 1, 2, 3, 4
    });

    test('sort descending reverses order', () {
      final src = _src();
      final r = ViewPipeline.run(
        source: src,
        sortKeys: const [SortKey('qty', SortDirection.descending)],
        filters: const {},
        query: '',
      );
      expect(r.viewRowIndices, [3, 0, 2, 1]);
    });

    test('search produces highlight bits, does not drop rows', () {
      final src = _src();
      final r = ViewPipeline.run(
        source: src,
        sortKeys: const [],
        filters: const {},
        query: 'an',
      );
      expect(r.viewRowIndices.length, 4);
      expect(r.hasSearch, isTrue);
      expect(r.isSearchHit(0), isFalse); // apple
      expect(r.isSearchHit(1), isTrue); // banana
      expect(r.isSearchHit(2), isFalse); // cherry
      expect(r.isSearchHit(3), isFalse); // date
    });

    test('filter + sort compose; sort runs after filter', () {
      final src = _src();
      final r = ViewPipeline.run(
        source: src,
        sortKeys: const [SortKey('qty', SortDirection.ascending)],
        filters: {
          'qty': (v) => v is NumberCell && v.value >= 2,
        },
        query: '',
      );
      expect(r.viewRowIndices, [2, 0, 3]); // qty 2, 3, 4
    });
  });
}
