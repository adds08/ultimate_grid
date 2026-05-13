import 'package:flutter_test/flutter_test.dart';
import 'package:ultimate_table/ultimate_table.dart';

void main() {
  group('ColumnLayout', () {
    test('non-contiguous left freeze: cols 1,2,8 land in left strip in priority order', () {
      final order = ['c1', 'c2', 'c3', 'c4', 'c5', 'c6', 'c7', 'c8', 'c9'];
      final frozen = {
        'c1': FrozenSide.start,
        'c2': FrozenSide.start,
        'c8': FrozenSide.start,
      };
      final priority = {'c1': 0, 'c2': 1, 'c8': 2};

      final layout = ColumnLayout.compute(
        order: order,
        widthOf: (_) => 100,
        freezeOf: (id) => frozen[id],
        priorityOf: (id) => priority[id] ?? 0,
      );

      expect(layout.leftFrozen, ['c1', 'c2', 'c8']);
      expect(layout.middle, ['c3', 'c4', 'c5', 'c6', 'c7', 'c9']);
      expect(layout.rightFrozen, isEmpty);
      expect(layout.leftFrozenWidth, 300);
      expect(layout.middleWidth, 600);
    });

    test('right freeze respects priority', () {
      final order = ['a', 'b', 'c', 'd'];
      final frozen = {'a': FrozenSide.end, 'c': FrozenSide.end};
      final priority = {'a': 5, 'c': 1};
      final layout = ColumnLayout.compute(
        order: order,
        widthOf: (_) => 50,
        freezeOf: (id) => frozen[id],
        priorityOf: (id) => priority[id] ?? 0,
      );
      expect(layout.rightFrozen, ['c', 'a']);
      expect(layout.middle, ['b', 'd']);
    });

    test('offsets are cumulative and total matches sum of widths', () {
      final layout = ColumnLayout.compute(
        order: ['a', 'b', 'c'],
        widthOf: (id) => id == 'b' ? 200 : 100,
        freezeOf: (_) => null,
        priorityOf: (_) => 0,
      );
      expect(layout.offsets[0], 0);
      expect(layout.offsets[1], 100);
      expect(layout.offsets[2], 300);
      expect(layout.offsets[3], 400);
      expect(layout.middleWidth, 400);
    });

    test('firstVisibleMiddle finds first column whose right edge exceeds offset', () {
      final layout = ColumnLayout.compute(
        order: ['a', 'b', 'c', 'd', 'e'],
        widthOf: (_) => 100,
        freezeOf: (_) => null,
        priorityOf: (_) => 0,
      );
      expect(layout.firstVisibleMiddle(0), 0);
      expect(layout.firstVisibleMiddle(50), 0);
      expect(layout.firstVisibleMiddle(100), 1);
      expect(layout.firstVisibleMiddle(150), 1);
      expect(layout.firstVisibleMiddle(250), 2);
    });
  });
}
