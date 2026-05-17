import 'dart:typed_data';

import 'package:meta/meta.dart';

import '../model/cell_address.dart';
import '../model/freeze.dart';

/// Precomputed, single-pass column layout.
///
/// Built once per controller revision; consulted by the renderer on every
/// frame. Holds three index lists (left frozen, scrollable, right frozen)
/// and a cumulative-offset table so the renderer can binary-search the
/// first/last visible column from a scroll offset in O(log n).
@immutable
class ColumnLayout {
  /// Column ids in left-frozen strip order (outermost-first per pin priority).
  final List<ColId> leftFrozen;

  /// Column ids in scrollable middle.
  final List<ColId> middle;

  /// Column ids in right-frozen strip order (innermost-first per pin priority).
  final List<ColId> rightFrozen;

  /// Index of every column in the full visible order (left + middle + right).
  /// O(1) lookup ColId → flat index.
  final Map<ColId, int> indexOf;

  /// Width of each column, indexed in the same order as [indexOf].
  final Float64List widths;

  /// Cumulative left edge of each column, indexed in the same order as
  /// [indexOf]. `offsets[i + 1] - offsets[i] == widths[i]`. Length =
  /// widths.length + 1; last entry = total width.
  final Float64List offsets;

  /// Width totals for the three regions.
  final double leftFrozenWidth;
  final double middleWidth;
  final double rightFrozenWidth;

  const ColumnLayout._({
    required this.leftFrozen,
    required this.middle,
    required this.rightFrozen,
    required this.indexOf,
    required this.widths,
    required this.offsets,
    required this.leftFrozenWidth,
    required this.middleWidth,
    required this.rightFrozenWidth,
  });

  /// Build a layout in a single pass.
  ///
  /// [order] is the current column order (post any user reorder).
  /// [widthOf] resolves the current width for a column id.
  /// [freezeOf] resolves the current freeze side (null = middle).
  /// [priorityOf] resolves the freeze priority — lower = outer edge of strip.
  factory ColumnLayout.compute({
    required List<ColId> order,
    required double Function(ColId) widthOf,
    required FrozenSide? Function(ColId) freezeOf,
    required int Function(ColId) priorityOf,
    bool Function(ColId)? isHidden,
  }) {
    final left = <ColId>[];
    final mid = <ColId>[];
    final right = <ColId>[];

    for (final id in order) {
      if (isHidden != null && isHidden(id)) continue;
      switch (freezeOf(id)) {
        case FrozenSide.start:
          left.add(id);
        case FrozenSide.end:
          right.add(id);
        case null:
          mid.add(id);
      }
    }

    int compareByPriorityThenOrder(ColId a, ColId b) {
      final pa = priorityOf(a);
      final pb = priorityOf(b);
      if (pa != pb) return pa.compareTo(pb);
      // Stable on original order — preserve user's reorder.
      return order.indexOf(a).compareTo(order.indexOf(b));
    }

    left.sort(compareByPriorityThenOrder);
    right.sort(compareByPriorityThenOrder);

    final total = left.length + mid.length + right.length;
    final widths = Float64List(total);
    final offsets = Float64List(total + 1);
    final indexOf = <ColId, int>{};

    var i = 0;
    var cursor = 0.0;
    var leftW = 0.0;
    var midW = 0.0;
    var rightW = 0.0;

    void emit(ColId id, void Function(double) accumulator) {
      final w = widthOf(id);
      widths[i] = w;
      offsets[i] = cursor;
      indexOf[id] = i;
      accumulator(w);
      cursor += w;
      i++;
    }

    for (final id in left) {
      emit(id, (w) => leftW += w);
    }
    for (final id in mid) {
      emit(id, (w) => midW += w);
    }
    for (final id in right) {
      emit(id, (w) => rightW += w);
    }
    offsets[total] = cursor;

    return ColumnLayout._(
      leftFrozen: List.unmodifiable(left),
      middle: List.unmodifiable(mid),
      rightFrozen: List.unmodifiable(right),
      indexOf: Map.unmodifiable(indexOf),
      widths: widths,
      offsets: offsets,
      leftFrozenWidth: leftW,
      middleWidth: midW,
      rightFrozenWidth: rightW,
    );
  }

  /// First flat index in [middle] whose right edge is > scrollOffset, or
  /// middle.length if none. O(log n) binary search.
  int firstVisibleMiddle(double scrollOffset) {
    if (middle.isEmpty) return 0;
    final firstMidIndex = indexOf[middle.first]!;
    final lastMidIndex = indexOf[middle.last]!;
    var lo = firstMidIndex;
    var hi = lastMidIndex + 1;
    final origin = offsets[firstMidIndex];
    while (lo < hi) {
      final mid = (lo + hi) >>> 1;
      final rightEdge = offsets[mid + 1] - origin;
      if (rightEdge <= scrollOffset) {
        lo = mid + 1;
      } else {
        hi = mid;
      }
    }
    return lo - firstMidIndex;
  }
}
