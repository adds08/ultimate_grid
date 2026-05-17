import 'package:meta/meta.dart';

import 'cell_address.dart';

/// A rectangular cell merge. The cell at `(anchorRow, anchorCol)` paints
/// over the full `rowSpan × colSpan` area; all other cells inside the
/// rectangle are occluded.
///
/// Merges reference cells by **schema id** rather than view index — they
/// remain stable across sort/filter/reorder. If a merge's anchor or any
/// occluded cell is currently filtered out, the merge is silently dropped
/// (render layer treats the cells as normal).
@immutable
class MergeRange {
  final RowId anchorRow;
  final ColId anchorCol;
  final int rowSpan;
  final int colSpan;

  const MergeRange({
    required this.anchorRow,
    required this.anchorCol,
    required this.rowSpan,
    required this.colSpan,
  })  : assert(rowSpan >= 1, 'rowSpan must be >= 1'),
        assert(colSpan >= 1, 'colSpan must be >= 1');

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MergeRange &&
          other.anchorRow == anchorRow &&
          other.anchorCol == anchorCol &&
          other.rowSpan == rowSpan &&
          other.colSpan == colSpan;

  @override
  int get hashCode => Object.hash(anchorRow, anchorCol, rowSpan, colSpan);

  @override
  String toString() =>
      'MergeRange($anchorRow,$anchorCol × $rowSpan x $colSpan)';
}
