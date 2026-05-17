import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:ultimate_grid/ultimate_grid.dart';

void main() {
  group('RowLayout', () {
    test('frozen rows split into top/bottom strips by side, view excludes them', () {
      final layout = RowLayout.compute(
        allRowIdsInSchemaOrder: ['r1', 'r2', 'r3', 'r4', 'r5'],
        viewRowIndices: Int32List.fromList([0, 1, 2, 3, 4]),
        heightOf: (_) => 30,
        freezeOf: (id) {
          if (id == 'r1') return FrozenSide.start;
          if (id == 'r5') return FrozenSide.end;
          return null;
        },
        priorityOf: (_) => 0,
      );
      expect(layout.topFrozen, ['r1']);
      expect(layout.bottomFrozen, ['r5']);
      expect(layout.middleViewIndices.length, 3);
      expect(layout.middleHeight, 90);
      expect(layout.topFrozenHeight, 30);
      expect(layout.bottomFrozenHeight, 30);
    });

    test('firstVisibleMiddle scans cumulative offsets', () {
      final layout = RowLayout.compute(
        allRowIdsInSchemaOrder: ['r1', 'r2', 'r3', 'r4'],
        viewRowIndices: Int32List.fromList([0, 1, 2, 3]),
        heightOf: (_) => 50,
        freezeOf: (_) => null,
        priorityOf: (_) => 0,
      );
      expect(layout.firstVisibleMiddle(0), 0);
      expect(layout.firstVisibleMiddle(49), 0);
      expect(layout.firstVisibleMiddle(50), 1);
      expect(layout.firstVisibleMiddle(120), 2);
    });

    test('post-filter view: only rows in the view appear in middle', () {
      // 5 rows in schema; view contains only [0, 2, 4] (filter dropped r2, r4).
      final layout = RowLayout.compute(
        allRowIdsInSchemaOrder: ['r1', 'r2', 'r3', 'r4', 'r5'],
        viewRowIndices: Int32List.fromList([0, 2, 4]),
        heightOf: (_) => 20,
        freezeOf: (_) => null,
        priorityOf: (_) => 0,
      );
      expect(layout.middleViewIndices.length, 3);
      expect(layout.middleHeight, 60);
    });
  });
}
