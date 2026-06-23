import 'dart:typed_data';

import 'package:meta/meta.dart';

import '../model/cell_address.dart';
import '../model/merge.dart';

/// Precomputed merge layout for the current view.
///
/// Built once per controller revision from the data source's [MergeRange]s
/// projected onto the post-filter / post-sort view. Renderers consult three
/// O(1) (amortized) lookups:
///  - [anchorAt] — is `(viewRow, flatCol)` an anchor cell? If so, returns
///    its `(rowSpan, colSpan)`.
///  - [isOccluded] — should this cell be skipped during paint because a
///    merge covers it?
///  - [mergeAt] — the merge containing `(viewRow, flatCol)`, if any.
///
/// Occlusion uses a `Uint32List` bitset (web-compatible).
@immutable
class MergeIndex {
  /// 1 bit per (viewRow × totalCols) cell. Bit set ⇒ occluded by some merge
  /// (anchor cells are NOT marked — they paint).
  final Uint32List _occlusion;

  /// Flat-cell index → (rowSpan, colSpan) for anchors. Packed as two
  /// Uint16 values per anchor in [_anchorSpans]; lookups go through
  /// [_anchorIndexByCell].
  final Map<int, _Span> _anchorByCell;

  final int _rowCount;
  final int _colCount;

  const MergeIndex._({
    required Uint32List occlusion,
    required Map<int, _Span> anchors,
    required int rowCount,
    required int colCount,
  }) : _occlusion = occlusion,
       _anchorByCell = anchors,
       _rowCount = rowCount,
       _colCount = colCount;

  /// Empty index (no merges).
  factory MergeIndex.empty() => MergeIndex._(
    occlusion: Uint32List(0),
    anchors: const <int, _Span>{},
    rowCount: 0,
    colCount: 0,
  );

  /// Compute from the raw merge declarations.
  ///
  /// [viewRowOfRowId] returns the view row index for a [RowId] or `-1` if
  /// the row has been filtered out. [flatColOfColId] returns the flat
  /// column index for a [ColId] or `-1` if hidden.
  factory MergeIndex.compute({
    required Iterable<MergeRange> merges,
    required int viewRowCount,
    required int totalColCount,
    required int Function(RowId) viewRowOfRowId,
    required int Function(ColId) flatColOfColId,
    required List<RowId> rowIdsInSchemaOrder,
    required List<ColId> colIdsInSchemaOrder,
  }) {
    if (merges.isEmpty || viewRowCount == 0 || totalColCount == 0) {
      return MergeIndex.empty();
    }
    final words = ((viewRowCount * totalColCount) + 31) >> 5;
    final occlusion = Uint32List(words);
    final anchors = <int, _Span>{};

    for (final m in merges) {
      final anchorView = viewRowOfRowId(m.anchorRow);
      final anchorCol = flatColOfColId(m.anchorCol);
      if (anchorView < 0 || anchorCol < 0) continue;

      // The merge area spans the next [rowSpan] schema rows in original
      // order starting from the anchor, and the next [colSpan] schema cols.
      // Stable across sort/filter is intentionally NOT supported in v1:
      // if any intermediate row has been moved by sort or filtered out, the
      // merge does not draw across non-adjacent view rows.
      final anchorRowSchemaIdx = rowIdsInSchemaOrder.indexOf(m.anchorRow);
      final anchorColSchemaIdx = colIdsInSchemaOrder.indexOf(m.anchorCol);
      if (anchorRowSchemaIdx < 0 || anchorColSchemaIdx < 0) continue;

      var ok = true;
      for (var dr = 1; dr < m.rowSpan && ok; dr++) {
        final r = anchorRowSchemaIdx + dr;
        if (r >= rowIdsInSchemaOrder.length) {
          ok = false;
          break;
        }
        final v = viewRowOfRowId(rowIdsInSchemaOrder[r]);
        if (v != anchorView + dr) {
          ok = false;
          break;
        }
      }
      for (var dc = 1; dc < m.colSpan && ok; dc++) {
        final c = anchorColSchemaIdx + dc;
        if (c >= colIdsInSchemaOrder.length) {
          ok = false;
          break;
        }
        final fc = flatColOfColId(colIdsInSchemaOrder[c]);
        if (fc != anchorCol + dc) {
          ok = false;
          break;
        }
      }
      if (!ok) continue;

      anchors[_packCellIndex(anchorView, anchorCol, totalColCount)] = _Span(
        m.rowSpan,
        m.colSpan,
      );

      for (var dr = 0; dr < m.rowSpan; dr++) {
        for (var dc = 0; dc < m.colSpan; dc++) {
          if (dr == 0 && dc == 0) continue;
          final v = anchorView + dr;
          final c = anchorCol + dc;
          final idx = v * totalColCount + c;
          occlusion[idx >> 5] |= 1 << (idx & 31);
        }
      }
    }

    return MergeIndex._(
      occlusion: occlusion,
      anchors: Map.unmodifiable(anchors),
      rowCount: viewRowCount,
      colCount: totalColCount,
    );
  }

  bool get isEmpty => _anchorByCell.isEmpty;

  bool isOccluded(int viewRow, int flatCol) {
    if (_colCount == 0 || viewRow < 0 || flatCol < 0) return false;
    if (viewRow >= _rowCount || flatCol >= _colCount) return false;
    final idx = viewRow * _colCount + flatCol;
    final word = idx >> 5;
    if (word >= _occlusion.length) return false;
    return (_occlusion[word] & (1 << (idx & 31))) != 0;
  }

  /// Returns (rowSpan, colSpan) if (viewRow, flatCol) is a merge anchor; else null.
  ({int rowSpan, int colSpan})? anchorAt(int viewRow, int flatCol) {
    final span = _anchorByCell[_packCellIndex(viewRow, flatCol, _colCount)];
    return span == null ? null : (rowSpan: span.r, colSpan: span.c);
  }

  static int _packCellIndex(int viewRow, int flatCol, int colCount) =>
      viewRow * (colCount == 0 ? 1 : colCount) + flatCol;
}

@immutable
class _Span {
  final int r;
  final int c;
  const _Span(this.r, this.c);
}
