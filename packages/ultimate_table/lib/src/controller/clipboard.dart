import 'package:flutter/services.dart';

import '../model/cell_value.dart';
import 'grid_controller.dart';
import 'selection.dart';

/// Helpers for moving cell content between an [UltimateTable] and the system
/// clipboard. The default format is TSV — one row per line, tabs between
/// cells — which round-trips with Excel, Numbers, Google Sheets.
abstract final class GridClipboard {
  /// Serialize the current selection as TSV. If multiple non-contiguous
  /// ranges are selected, the bounding rectangle is used.
  static String selectionAsTsv(GridController controller) {
    final sel = controller.selection;
    if (sel.isEmpty) return '';
    var top = sel.ranges.first.topRow;
    var bottom = sel.ranges.first.bottomRow;
    var left = sel.ranges.first.leftCol;
    var right = sel.ranges.first.rightCol;
    for (final r in sel.ranges) {
      if (r.topRow < top) top = r.topRow;
      if (r.bottomRow > bottom) bottom = r.bottomRow;
      if (r.leftCol < left) left = r.leftCol;
      if (r.rightCol > right) right = r.rightCol;
    }
    if (top == SelectionRange.allRows) {
      top = 0;
      bottom = controller.pipelineResult.viewRowIndices.length - 1;
    }
    if (left == SelectionRange.allCols) {
      left = 0;
      right = controller.columnLayout.widths.length - 1;
    }
    if (bottom < top || right < left) return '';

    final view = controller.pipelineResult.viewRowIndices;
    final rowIds = controller.source.rowIds.toList(growable: false);
    final flatCols = <String>[
      ...controller.columnLayout.leftFrozen,
      ...controller.columnLayout.middle,
      ...controller.columnLayout.rightFrozen,
    ];

    final buf = StringBuffer();
    for (var v = top; v <= bottom; v++) {
      if (v < 0 || v >= view.length) continue;
      final rowId = rowIds[view[v]];
      for (var c = left; c <= right; c++) {
        if (c < 0 || c >= flatCols.length) continue;
        if (c > left) buf.write('\t');
        final cell = controller.source.valueAt(rowId, flatCols[c]);
        buf.write(_tsvEscape(_renderCell(cell)));
      }
      if (v < bottom) buf.write('\n');
    }
    return buf.toString();
  }

  /// Copy the current selection (as TSV) to the system clipboard.
  static Future<void> copySelection(GridController controller) async {
    final tsv = selectionAsTsv(controller);
    if (tsv.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: tsv));
  }

  static String _renderCell(CellValue v) {
    return switch (v) {
      EmptyCell() => '',
      TextCell(value: final s) => s,
      NumberCell(value: final n) =>
        n == n.roundToDouble() ? n.toStringAsFixed(0) : n.toString(),
      BoolCell(value: final b) => b ? 'TRUE' : 'FALSE',
      DateCell(value: final d) =>
        '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}',
      FormulaCell(:final source, :final cached) =>
        cached == null ? '=$source' : _renderCell(cached),
      CustomCell(:final payload) => payload.toString(),
    };
  }

  static String _tsvEscape(String s) {
    // TSV: replace tabs / newlines so the row/col split stays sane.
    if (!s.contains('\t') && !s.contains('\n') && !s.contains('\r')) return s;
    return s.replaceAll('\r\n', ' ').replaceAll('\n', ' ').replaceAll('\t', ' ');
  }
}
