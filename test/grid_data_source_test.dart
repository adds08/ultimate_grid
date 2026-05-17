import 'package:flutter_test/flutter_test.dart';
import 'package:ultimate_grid/ultimate_grid.dart';

void main() {
  group('MapGridDataSource', () {
    test('missing cells return EmptyCell singleton', () {
      final src = MapGridDataSource(rowIds: ['r1'], colIds: ['c1']);
      expect(src.valueAt('r1', 'c1'), same(EmptyCell.instance));
      expect(src.valueAt('missing', 'c1'), same(EmptyCell.instance));
    });

    test('setValue + valueAt round-trip', () {
      final src = MapGridDataSource(rowIds: ['r1'], colIds: ['c1']);
      src.setValue('r1', 'c1', const NumberCell(8));
      expect(src.valueAt('r1', 'c1'), const NumberCell(8));
    });

    test('setting EmptyCell removes the entry and prunes the row map', () {
      final src = MapGridDataSource(rowIds: ['r1'], colIds: ['c1']);
      src.setValue('r1', 'c1', const NumberCell(1));
      src.setValue('r1', 'c1', const EmptyCell());
      expect(src.valueAt('r1', 'c1'), same(EmptyCell.instance));
    });

    test('metadata is sparse and disappears when last entry removed', () {
      final src = MapGridDataSource(rowIds: ['r1'], colIds: ['c1']);
      expect(src.metadataAt('r1', 'c1'), isNull);
      src.setMetadata('r1', 'c1', 'tooltip');
      expect(src.metadataAt('r1', 'c1'), 'tooltip');
      src.setMetadata('r1', 'c1', null);
      expect(src.metadataAt('r1', 'c1'), isNull);
    });

    test('revision bumps + listeners fire on mutation', () {
      final src = MapGridDataSource(rowIds: ['r1'], colIds: ['c1']);
      final r0 = src.revision;
      var notified = 0;
      src.addListener(() => notified++);
      src.setValue('r1', 'c1', const NumberCell(1));
      expect(src.revision, r0 + 1);
      expect(notified, 1);
    });

    test('removeColumn cleans cells and metadata across rows', () {
      final src = MapGridDataSource(
        rowIds: ['r1', 'r2'],
        colIds: ['c1', 'c2'],
      );
      src.setValue('r1', 'c1', const NumberCell(1));
      src.setValue('r2', 'c1', const NumberCell(2));
      src.setMetadata('r1', 'c1', 'm1');
      src.removeColumn('c1');
      expect(src.valueAt('r1', 'c1'), same(EmptyCell.instance));
      expect(src.valueAt('r2', 'c1'), same(EmptyCell.instance));
      expect(src.metadataAt('r1', 'c1'), isNull);
    });
  });
}
