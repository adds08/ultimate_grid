import 'package:flutter/foundation.dart';
import 'package:ultimate_grid/ultimate_grid.dart';

/// A `GridDataSource` that synthesises cell values on demand from the row
/// index, so it can host millions of rows without materialising every cell.
///
/// Row IDs are still stored as a real `List<String>` (the controller and
/// row layout iterate them once on rebuild), but cells are never written
/// — `valueAt(row, col)` parses the row index from `row` and calls
/// [generator] to produce the value.
///
/// Used by the stress-test example to show 5 M rows × 10 columns.
class SyntheticGridDataSource extends ChangeNotifier
    implements GridDataSource {
  SyntheticGridDataSource({
    required int rowCount,
    required List<ColId> colIds,
    required CellValue Function(int rowIndex, ColId colId) generator,
    String rowIdPrefix = 'r',
  })  : _rowIds = List<RowId>.generate(rowCount, (i) => '$rowIdPrefix$i'),
        _colIds = List<ColId>.of(colIds),
        _generator = generator,
        _prefixLen = rowIdPrefix.length;

  final List<RowId> _rowIds;
  final List<ColId> _colIds;
  final CellValue Function(int rowIndex, ColId colId) _generator;
  final int _prefixLen;

  @override
  Iterable<RowId> get rowIds => _rowIds;

  @override
  Iterable<ColId> get colIds => _colIds;

  // Data is fully synthesised on demand and never mutated, so the revision
  // is a constant. Controllers only rebuild derived state when this bumps
  // (or when their own view state changes).
  @override
  int get revision => 0;

  @override
  List<MergeRange> get merges => const <MergeRange>[];

  @override
  Object? metadataAt(RowId row, ColId col) => null;

  @override
  CellValue valueAt(RowId row, ColId col) {
    final idxStr = row.length > _prefixLen ? row.substring(_prefixLen) : row;
    final idx = int.tryParse(idxStr);
    if (idx == null) return EmptyCell.instance;
    return _generator(idx, col);
  }
}
