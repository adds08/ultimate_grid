import 'dart:typed_data';

import 'package:meta/meta.dart';

import '../model/cell_address.dart';
import '../model/freeze.dart';

/// Precomputed row layout. Mirrors [ColumnLayout]: three partitions
/// (top-frozen, scrollable middle, bottom-frozen) with cumulative offsets
/// for O(log n) "first visible row" lookups.
///
/// NOTE: the middle partition tracks **view row indices** (post filter/sort)
/// rather than schema RowIds, because filtering and sorting are applied to
/// the scrollable region only. Frozen rows are addressed by RowId since they
/// should remain stable regardless of view ordering.
@immutable
class RowLayout {
  /// RowIds in top-frozen strip order.
  final List<RowId> topFrozen;

  /// View indices (into ViewPipelineResult.viewRowIndices) for the middle.
  final Int32List middleViewIndices;

  /// RowIds in bottom-frozen strip order.
  final List<RowId> bottomFrozen;

  /// Height of each row in the middle strip.
  final Float64List middleHeights;

  /// Cumulative top edge of each middle row. Length = middleHeights.length + 1.
  final Float64List middleOffsets;

  final Float64List topFrozenHeights;
  final Float64List bottomFrozenHeights;

  final double topFrozenHeight;
  final double middleHeight;
  final double bottomFrozenHeight;

  const RowLayout._({
    required this.topFrozen,
    required this.middleViewIndices,
    required this.bottomFrozen,
    required this.middleHeights,
    required this.middleOffsets,
    required this.topFrozenHeights,
    required this.bottomFrozenHeights,
    required this.topFrozenHeight,
    required this.middleHeight,
    required this.bottomFrozenHeight,
  });

  factory RowLayout.compute({
    required List<RowId> allRowIdsInSchemaOrder,
    required Int32List viewRowIndices,
    required double Function(RowId) heightOf,
    required FrozenSide? Function(RowId) freezeOf,
    required int Function(RowId) priorityOf,
  }) {
    // Partition frozen vs free using schema order (so top/bottom strips
    // ignore filter/sort — they're stable).
    final top = <RowId>[];
    final bottom = <RowId>[];
    final frozenSet = <RowId>{};
    for (final id in allRowIdsInSchemaOrder) {
      switch (freezeOf(id)) {
        case FrozenSide.start:
          top.add(id);
          frozenSet.add(id);
        case FrozenSide.end:
          bottom.add(id);
          frozenSet.add(id);
        case null:
          break;
      }
    }

    int compareByPriority(RowId a, RowId b) {
      final pa = priorityOf(a);
      final pb = priorityOf(b);
      if (pa != pb) return pa.compareTo(pb);
      return allRowIdsInSchemaOrder
          .indexOf(a)
          .compareTo(allRowIdsInSchemaOrder.indexOf(b));
    }

    top.sort(compareByPriority);
    bottom.sort(compareByPriority);

    // Middle: only view rows that aren't frozen.
    final filteredMid = <int>[];
    for (var i = 0; i < viewRowIndices.length; i++) {
      final rowId = allRowIdsInSchemaOrder[viewRowIndices[i]];
      if (!frozenSet.contains(rowId)) {
        filteredMid.add(i);
      }
    }

    final middleView = Int32List(filteredMid.length);
    final middleHeights = Float64List(filteredMid.length);
    final middleOffsets = Float64List(filteredMid.length + 1);
    var cursor = 0.0;
    for (var i = 0; i < filteredMid.length; i++) {
      final viewIdx = filteredMid[i];
      final rowId = allRowIdsInSchemaOrder[viewRowIndices[viewIdx]];
      final h = heightOf(rowId);
      middleView[i] = viewIdx;
      middleHeights[i] = h;
      middleOffsets[i] = cursor;
      cursor += h;
    }
    middleOffsets[filteredMid.length] = cursor;
    final midTotal = cursor;

    final topHeights = Float64List(top.length);
    var topTotal = 0.0;
    for (var i = 0; i < top.length; i++) {
      final h = heightOf(top[i]);
      topHeights[i] = h;
      topTotal += h;
    }

    final bottomHeights = Float64List(bottom.length);
    var bottomTotal = 0.0;
    for (var i = 0; i < bottom.length; i++) {
      final h = heightOf(bottom[i]);
      bottomHeights[i] = h;
      bottomTotal += h;
    }

    return RowLayout._(
      topFrozen: List.unmodifiable(top),
      middleViewIndices: middleView,
      bottomFrozen: List.unmodifiable(bottom),
      middleHeights: middleHeights,
      middleOffsets: middleOffsets,
      topFrozenHeights: topHeights,
      bottomFrozenHeights: bottomHeights,
      topFrozenHeight: topTotal,
      middleHeight: midTotal,
      bottomFrozenHeight: bottomTotal,
    );
  }

  /// First middle row whose bottom edge > scrollOffset (binary search).
  int firstVisibleMiddle(double scrollOffset) {
    if (middleViewIndices.isEmpty) return 0;
    var lo = 0;
    var hi = middleViewIndices.length;
    while (lo < hi) {
      final mid = (lo + hi) >>> 1;
      if (middleOffsets[mid + 1] <= scrollOffset) {
        lo = mid + 1;
      } else {
        hi = mid;
      }
    }
    return lo;
  }
}
