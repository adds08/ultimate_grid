import 'package:meta/meta.dart';

import '../model/cell_address.dart';

/// A single selection range. Excel-style: an anchor cell + an extent cell
/// define the rectangle inclusive on both ends. Whole-row and whole-column
/// selections are encoded with the sentinels [SelectionRange.allRows] and
/// [SelectionRange.allCols].
@immutable
class SelectionRange {
  /// Sentinel meaning "every row" for [anchorRowIndex]/[extentRowIndex].
  static const int allRows = -1;

  /// Sentinel meaning "every column" for [anchorColIndex]/[extentColIndex].
  static const int allCols = -1;

  final int anchorRowIndex;
  final int anchorColIndex;
  final int extentRowIndex;
  final int extentColIndex;

  const SelectionRange({
    required this.anchorRowIndex,
    required this.anchorColIndex,
    required this.extentRowIndex,
    required this.extentColIndex,
  });

  const SelectionRange.cell(int row, int col)
    : anchorRowIndex = row,
      anchorColIndex = col,
      extentRowIndex = row,
      extentColIndex = col;

  const SelectionRange.row(int row)
    : anchorRowIndex = row,
      anchorColIndex = allCols,
      extentRowIndex = row,
      extentColIndex = allCols;

  const SelectionRange.column(int col)
    : anchorRowIndex = allRows,
      anchorColIndex = col,
      extentRowIndex = allRows,
      extentColIndex = col;

  bool get isWholeRow => anchorColIndex == allCols && extentColIndex == allCols;
  bool get isWholeColumn =>
      anchorRowIndex == allRows && extentRowIndex == allRows;

  bool contains(int rowIndex, int colIndex) {
    final rowOk =
        isWholeColumn ||
        (rowIndex >= _min(anchorRowIndex, extentRowIndex) &&
            rowIndex <= _max(anchorRowIndex, extentRowIndex));
    final colOk =
        isWholeRow ||
        (colIndex >= _min(anchorColIndex, extentColIndex) &&
            colIndex <= _max(anchorColIndex, extentColIndex));
    return rowOk && colOk;
  }

  int get topRow => _min(anchorRowIndex, extentRowIndex);
  int get bottomRow => _max(anchorRowIndex, extentRowIndex);
  int get leftCol => _min(anchorColIndex, extentColIndex);
  int get rightCol => _max(anchorColIndex, extentColIndex);

  /// Returns a copy with the extent moved to `(row, col)` — the standard
  /// shift-click / drag-extend operation. Sentinels (whole-row / whole-col)
  /// are preserved when crossed by extent.
  SelectionRange extendTo(int row, int col) {
    final newRow = anchorRowIndex == allRows ? allRows : row;
    final newCol = anchorColIndex == allCols ? allCols : col;
    return SelectionRange(
      anchorRowIndex: anchorRowIndex,
      anchorColIndex: anchorColIndex,
      extentRowIndex: newRow,
      extentColIndex: newCol,
    );
  }

  static int _min(int a, int b) => a < b ? a : b;
  static int _max(int a, int b) => a > b ? a : b;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SelectionRange &&
          other.anchorRowIndex == anchorRowIndex &&
          other.anchorColIndex == anchorColIndex &&
          other.extentRowIndex == extentRowIndex &&
          other.extentColIndex == extentColIndex;

  @override
  int get hashCode => Object.hash(
    anchorRowIndex,
    anchorColIndex,
    extentRowIndex,
    extentColIndex,
  );
}

/// A flat list of [SelectionRange]s — Excel allows non-contiguous selections
/// via cmd/ctrl click. The last range is the "active" one whose extent moves
/// under shift-arrow / shift-click / drag.
@immutable
class Selection {
  final List<SelectionRange> ranges;
  final CellAddress? focus;

  const Selection({this.ranges = const [], this.focus});

  static const Selection empty = Selection();

  bool get isEmpty => ranges.isEmpty;

  bool contains(int rowIndex, int colIndex) {
    for (final r in ranges) {
      if (r.contains(rowIndex, colIndex)) return true;
    }
    return false;
  }

  /// The active range — the last one in [ranges]. Returns null when empty.
  SelectionRange? get activeRange => ranges.isEmpty ? null : ranges.last;

  Selection copyWith({List<SelectionRange>? ranges, CellAddress? focus}) =>
      Selection(ranges: ranges ?? this.ranges, focus: focus ?? this.focus);

  /// Replace the active range's extent — Excel shift-click / drag-extend
  /// behavior. Anchor stays put; only the extent moves.
  Selection extendActiveTo({
    required int rowIndex,
    required int colIndex,
    CellAddress? focus,
  }) {
    if (ranges.isEmpty) {
      return Selection(
        ranges: [SelectionRange.cell(rowIndex, colIndex)],
        focus: focus ?? this.focus,
      );
    }
    final next = List<SelectionRange>.of(ranges);
    next[next.length - 1] = next.last.extendTo(rowIndex, colIndex);
    return Selection(ranges: next, focus: focus ?? this.focus);
  }

  /// Push a new range on top — Excel cmd/ctrl-click behavior.
  Selection addRange(SelectionRange range, {CellAddress? focus}) =>
      Selection(ranges: [...ranges, range], focus: focus ?? this.focus);
}
