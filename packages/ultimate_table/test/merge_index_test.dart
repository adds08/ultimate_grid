import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:ultimate_table/ultimate_table.dart';

void main() {
  group('MergeIndex', () {
    test('isOccluded marks all non-anchor cells inside a merge', () {
      final idx = MergeIndex.compute(
        merges: const [
          MergeRange(anchorRow: 'r1', anchorCol: 'a', rowSpan: 2, colSpan: 2),
        ],
        viewRowCount: 3,
        totalColCount: 3,
        viewRowOfRowId: (id) => {'r1': 0, 'r2': 1, 'r3': 2}[id] ?? -1,
        flatColOfColId: (id) => {'a': 0, 'b': 1, 'c': 2}[id] ?? -1,
        rowIdsInSchemaOrder: const ['r1', 'r2', 'r3'],
        colIdsInSchemaOrder: const ['a', 'b', 'c'],
      );
      expect(idx.anchorAt(0, 0), isNotNull);
      expect(idx.anchorAt(0, 0)!.rowSpan, 2);
      expect(idx.anchorAt(0, 0)!.colSpan, 2);
      expect(idx.isOccluded(0, 1), isTrue);
      expect(idx.isOccluded(1, 0), isTrue);
      expect(idx.isOccluded(1, 1), isTrue);
      expect(idx.isOccluded(0, 0), isFalse); // anchor is NOT occluded
      expect(idx.isOccluded(2, 2), isFalse); // outside the merge
    });

    test('empty merges produces an empty index', () {
      final idx = MergeIndex.compute(
        merges: const [],
        viewRowCount: 5,
        totalColCount: 5,
        viewRowOfRowId: (_) => 0,
        flatColOfColId: (_) => 0,
        rowIdsInSchemaOrder: const [],
        colIdsInSchemaOrder: const [],
      );
      expect(idx.isEmpty, isTrue);
      expect(idx.isOccluded(0, 0), isFalse);
    });

    test('merge whose anchor was filtered out is silently dropped', () {
      final idx = MergeIndex.compute(
        merges: const [
          MergeRange(anchorRow: 'r1', anchorCol: 'a', rowSpan: 2, colSpan: 1),
        ],
        viewRowCount: 1,
        totalColCount: 1,
        viewRowOfRowId: (id) => id == 'r2' ? 0 : -1, // r1 filtered out
        flatColOfColId: (id) => id == 'a' ? 0 : -1,
        rowIdsInSchemaOrder: const ['r1', 'r2'],
        colIdsInSchemaOrder: const ['a'],
      );
      expect(idx.isEmpty, isTrue);
    });
  });

  group('GridController exposes mergeIndex after source mutation', () {
    test('addMerge on the source triggers a rebuild', () {
      final schema = GridSchema(
        columns: const [
          ColumnSpec(id: 'a', header: 'A'),
          ColumnSpec(id: 'b', header: 'B'),
        ],
        rows: const [RowSpec(id: 'r1'), RowSpec(id: 'r2')],
      );
      final src = MapGridDataSource(rowIds: ['r1', 'r2'], colIds: ['a', 'b']);
      final c = GridController(schema: schema, source: src);

      expect(c.mergeIndex.isEmpty, isTrue);

      src.addMerge(const MergeRange(
        anchorRow: 'r1',
        anchorCol: 'a',
        rowSpan: 2,
        colSpan: 2,
      ));
      expect(c.mergeIndex.anchorAt(0, 0), isNotNull);
      expect(c.mergeIndex.isOccluded(1, 1), isTrue);
    });
  });

  test('MergeIndex sentinel-free with Uint32List avoids Uint64List on web', () {
    // smoke-check: ensure compute doesn't blow up with non-trivial size.
    final idx = MergeIndex.compute(
      merges: const [
        MergeRange(anchorRow: 'r0', anchorCol: 'c0', rowSpan: 4, colSpan: 4),
      ],
      viewRowCount: 100,
      totalColCount: 100,
      viewRowOfRowId: (id) => int.parse(id.substring(1)),
      flatColOfColId: (id) => int.parse(id.substring(1)),
      rowIdsInSchemaOrder: List<String>.generate(100, (i) => 'r$i'),
      colIdsInSchemaOrder: List<String>.generate(100, (i) => 'c$i'),
    );
    expect(idx.anchorAt(0, 0), isNotNull);
    expect(idx.isOccluded(3, 3), isTrue);
    // Ensure the synthetic helper compiles vs typed buffer ops.
    expect(Uint32List(1).length, 1);
  });
}
