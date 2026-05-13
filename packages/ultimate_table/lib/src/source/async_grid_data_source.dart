import 'package:flutter/foundation.dart';

import '../model/cell_address.dart';
import '../model/cell_value.dart';
import '../model/merge.dart';
import 'grid_data_source.dart';

/// Result of a paged fetch — the cells for `rowIds[start..start+rowIds.length)`.
///
/// Rows are addressed by `RowId` (stable identity from the schema), not by
/// row index — so the data source can hand back partial results without
/// caring about reorder/sort happening on the controller side.
@immutable
class AsyncPage {
  final List<RowId> rowIds;
  final Map<RowId, Map<ColId, CellValue>> cells;
  const AsyncPage({required this.rowIds, required this.cells});
}

/// Lazy, page-cached data source backed by a caller-provided fetch function.
///
/// Designed for "API → grid" pipelines without pagination UI:
///   - The caller declares a total row count and a fixed column list up front
///     (`rowIds` / `colIds`).
///   - When the grid asks for a cell whose row hasn't been fetched yet, the
///     source kicks off [fetchRange] for that row's page and returns a
///     placeholder cell ([loadingPlaceholder], default `TextCell('…')`).
///   - When the page arrives, the cache absorbs it and the source bumps
///     [revision] so the controller re-runs derived state and the grid
///     repaints. From the caller's side it's a single async function — no
///     pagination component needed.
///
/// The cache is keyed by page index (`rowIndex ~/ pageSize`). Pages can be
/// re-fetched by calling [invalidate].
class AsyncGridDataSource extends ChangeNotifier implements GridDataSource {
  AsyncGridDataSource({
    required List<RowId> rowIds,
    required List<ColId> colIds,
    required Future<AsyncPage> Function(int startRow, int endRowExclusive)
        fetchRange,
    this.pageSize = 50,
    CellValue loadingPlaceholder = const TextCell('…'),
  })  : _rowIds = List<RowId>.of(rowIds),
        _colIds = List<ColId>.of(colIds),
        _fetchRange = fetchRange,
        _loading = loadingPlaceholder;

  final List<RowId> _rowIds;
  final List<ColId> _colIds;
  final Future<AsyncPage> Function(int, int) _fetchRange;
  final CellValue _loading;
  final int pageSize;

  /// Cells keyed by (rowId, colId). Built up as pages arrive.
  final Map<RowId, Map<ColId, CellValue>> _cells = {};

  /// Pages currently being fetched. Prevents re-fetch on every paint.
  final Set<int> _inFlight = <int>{};

  /// Pages that have completed at least once.
  final Set<int> _loaded = <int>{};

  int _revision = 0;
  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  @override
  Iterable<RowId> get rowIds => _rowIds;

  @override
  Iterable<ColId> get colIds => _colIds;

  @override
  int get revision => _revision;

  @override
  List<MergeRange> get merges => const <MergeRange>[];

  @override
  Object? metadataAt(RowId row, ColId col) => null;

  @override
  CellValue valueAt(RowId row, ColId col) {
    final cached = _cells[row]?[col];
    if (cached != null) return cached;
    // Fire-and-forget fetch for this row's page.
    final rowIdx = _rowIds.indexOf(row);
    if (rowIdx < 0) return EmptyCell.instance;
    final page = rowIdx ~/ pageSize;
    if (!_loaded.contains(page) && !_inFlight.contains(page)) {
      _kickFetch(page);
    }
    return _loading;
  }

  /// Has the page covering `rowIndex` been loaded?
  bool isRowLoaded(int rowIndex) {
    if (rowIndex < 0 || rowIndex >= _rowIds.length) return false;
    return _loaded.contains(rowIndex ~/ pageSize);
  }

  /// Hint the source to start fetching the page covering `rowIndex` (useful
  /// for prefetching just past the viewport without depending on
  /// [valueAt] side-effects).
  void prefetchRow(int rowIndex) {
    if (rowIndex < 0 || rowIndex >= _rowIds.length) return;
    final page = rowIndex ~/ pageSize;
    if (_loaded.contains(page) || _inFlight.contains(page)) return;
    _kickFetch(page);
  }

  /// Drop a previously-loaded page so the next read re-fetches.
  void invalidate({int? page}) {
    if (page == null) {
      _cells.clear();
      _loaded.clear();
      _bump();
      return;
    }
    final start = page * pageSize;
    final end = (start + pageSize).clamp(0, _rowIds.length);
    for (var i = start; i < end; i++) {
      _cells.remove(_rowIds[i]);
    }
    _loaded.remove(page);
    _bump();
  }

  void _kickFetch(int page) {
    _inFlight.add(page);
    final start = page * pageSize;
    final end = (start + pageSize).clamp(0, _rowIds.length);
    _fetchRange(start, end).then((result) {
      // Source can be swapped / disposed mid-fetch (e.g. user toggles
      // sync ↔ async). Drop the late result quietly instead of mutating
      // a disposed ChangeNotifier — `notifyListeners()` asserts.
      if (_disposed) return;
      for (final rowId in result.rowIds) {
        final inMap = result.cells[rowId];
        if (inMap != null) {
          _cells[rowId] = Map<ColId, CellValue>.of(inMap);
        }
      }
      _loaded.add(page);
      _inFlight.remove(page);
      _bump();
    }).catchError((Object _) {
      if (_disposed) return;
      // On error, allow a retry next read.
      _inFlight.remove(page);
      _bump();
    });
  }

  void _bump() {
    if (_disposed) return;
    _revision++;
    notifyListeners();
  }
}
