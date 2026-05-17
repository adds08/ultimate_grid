import 'package:flutter/foundation.dart';

import '../model/cell_address.dart';
import '../model/cell_value.dart';
import '../model/merge.dart';

/// Read-only matrix-map data source.
///
/// Coordinates are addressed by stable [RowId]/[ColId]. Missing cells return
/// [EmptyCell.instance]. Metadata is a sparse, opt-in side-channel — callers
/// that never set it pay no per-cell memory cost.
///
/// Mutations bump [revision] so controllers/views can recompute derived state
/// in a single pass.
abstract class GridDataSource implements Listenable {
  Iterable<RowId> get rowIds;
  Iterable<ColId> get colIds;

  CellValue valueAt(RowId row, ColId col);

  /// Optional invisible payload — tooltip text, custom object, anything.
  /// Returns null when the cell has no metadata. Backed by a sparse map, so
  /// "no metadata anywhere" costs zero per-cell memory.
  Object? metadataAt(RowId row, ColId col);

  /// Monotonic counter incremented on every mutation. Pair with [addListener]
  /// to drive single-pass recomputation of view state.
  int get revision;

  /// Cell merges currently declared on this source. Empty list when no
  /// merges have ever been declared — zero per-cell cost when unused.
  List<MergeRange> get merges => const <MergeRange>[];
}

/// Mutable in-memory implementation. Sparse storage for both cells and
/// metadata — only present (row, col) pairs allocate.
class MapGridDataSource extends ChangeNotifier implements GridDataSource {
  final List<RowId> _rowIds;
  final List<ColId> _colIds;
  final Map<RowId, Map<ColId, CellValue>> _cells;
  Map<RowId, Map<ColId, Object>>? _metadata; // lazily created
  List<MergeRange>? _merges; // lazily created
  int _revision = 0;

  MapGridDataSource({
    required List<RowId> rowIds,
    required List<ColId> colIds,
    Map<RowId, Map<ColId, CellValue>>? cells,
  })  : _rowIds = List<RowId>.of(rowIds),
        _colIds = List<ColId>.of(colIds),
        _cells = cells == null
            ? <RowId, Map<ColId, CellValue>>{}
            : {
                for (final entry in cells.entries)
                  entry.key: Map<ColId, CellValue>.of(entry.value),
              };

  @override
  Iterable<RowId> get rowIds => _rowIds;

  @override
  Iterable<ColId> get colIds => _colIds;

  @override
  int get revision => _revision;

  @override
  CellValue valueAt(RowId row, ColId col) =>
      _cells[row]?[col] ?? EmptyCell.instance;

  @override
  Object? metadataAt(RowId row, ColId col) => _metadata?[row]?[col];

  @override
  List<MergeRange> get merges =>
      _merges == null ? const <MergeRange>[] : List.unmodifiable(_merges!);

  // --- mutations ---

  void setValue(RowId row, ColId col, CellValue value) {
    if (value is EmptyCell) {
      final r = _cells[row];
      if (r == null) return;
      if (r.remove(col) == null) return;
      if (r.isEmpty) _cells.remove(row);
      _bump();
      return;
    }
    final r = _cells.putIfAbsent(row, () => <ColId, CellValue>{});
    if (r[col] == value) return;
    r[col] = value;
    _bump();
  }

  void setMetadata(RowId row, ColId col, Object? payload) {
    if (payload == null) {
      final meta = _metadata;
      if (meta == null) return;
      final r = meta[row];
      if (r == null) return;
      if (r.remove(col) == null) return;
      if (r.isEmpty) meta.remove(row);
      if (meta.isEmpty) _metadata = null;
      _bump();
      return;
    }
    final meta = _metadata ??= <RowId, Map<ColId, Object>>{};
    final r = meta.putIfAbsent(row, () => <ColId, Object>{});
    if (identical(r[col], payload)) return;
    r[col] = payload;
    _bump();
  }

  void addRow(RowId id) {
    if (_rowIds.contains(id)) return;
    _rowIds.add(id);
    _bump();
  }

  void removeRow(RowId id) {
    if (!_rowIds.remove(id)) return;
    _cells.remove(id);
    _metadata?.remove(id);
    if (_metadata?.isEmpty ?? false) _metadata = null;
    _bump();
  }

  void addColumn(ColId id) {
    if (_colIds.contains(id)) return;
    _colIds.add(id);
    _bump();
  }

  void removeColumn(ColId id) {
    if (!_colIds.remove(id)) return;
    for (final row in _cells.values) {
      row.remove(id);
    }
    _cells.removeWhere((_, row) => row.isEmpty);
    final meta = _metadata;
    if (meta != null) {
      for (final row in meta.values) {
        row.remove(id);
      }
      meta.removeWhere((_, row) => row.isEmpty);
      if (meta.isEmpty) _metadata = null;
    }
    _bump();
  }

  void reorderRows(List<RowId> next) {
    assert(next.length == _rowIds.length, 'reorderRows length mismatch');
    _rowIds
      ..clear()
      ..addAll(next);
    _bump();
  }

  void addMerge(MergeRange merge) {
    final list = _merges ??= <MergeRange>[];
    if (list.contains(merge)) return;
    list.add(merge);
    _bump();
  }

  void removeMerge(MergeRange merge) {
    final list = _merges;
    if (list == null) return;
    if (!list.remove(merge)) return;
    if (list.isEmpty) _merges = null;
    _bump();
  }

  void clearMerges() {
    if (_merges == null) return;
    _merges = null;
    _bump();
  }

  void reorderColumns(List<ColId> next) {
    assert(next.length == _colIds.length, 'reorderColumns length mismatch');
    _colIds
      ..clear()
      ..addAll(next);
    _bump();
  }

  void _bump() {
    _revision++;
    notifyListeners();
  }
}
