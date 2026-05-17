import 'package:flutter_test/flutter_test.dart';
import 'package:ultimate_grid/ultimate_grid.dart';

void main() {
  group('InteractionPolicy', () {
    test('MapPolicy resolves only configured cells', () {
      final p = MapPolicy<String>({
        const CellAddress('r1', 'c1'): 'A',
      });
      expect(p.at(0, 0, 'r1', 'c1'), 'A');
      expect(p.at(0, 1, 'r1', 'c2'), isNull);
    });

    test('PredicatePolicy.evenCells fires only on even row+col', () {
      final p = PredicatePolicy.evenCells<String>('hi');
      expect(p.at(0, 0, 'r0', 'c0'), 'hi');
      expect(p.at(2, 4, 'r2', 'c4'), 'hi');
      expect(p.at(1, 0, 'r1', 'c0'), isNull);
      expect(p.at(2, 3, 'r2', 'c3'), isNull);
    });

    test('overriddenBy: top wins, falls back to base', () {
      final base = PredicatePolicy<String>((r, c, _, __) => 'base');
      final top = MapPolicy<String>({
        const CellAddress('r0', 'c0'): 'top',
      });
      final composed = base.overriddenBy(top);
      expect(composed.at(0, 0, 'r0', 'c0'), 'top');
      expect(composed.at(1, 1, 'r1', 'c1'), 'base');
    });
  });
}
