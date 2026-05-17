import 'package:flutter/widgets.dart';

import '../model/cell_address.dart';
import '../model/cell_value.dart';
import '../model/column_spec.dart';
import '../theme/grid_theme.dart';

/// Context handed to a renderer for one cell paint.
@immutable
class CellRenderContext {
  final RowId rowId;
  final ColId colId;
  final int rowIndex;
  final int colIndex;
  final ColumnSpec column;
  final GridTheme theme;
  final TextStyle textStyle;
  final TextAlign textAlign;
  final EdgeInsets padding;
  final Color background;
  final bool isSelected;
  final bool isFocused;
  final bool isSearchHit;

  const CellRenderContext({
    required this.rowId,
    required this.colId,
    required this.rowIndex,
    required this.colIndex,
    required this.column,
    required this.theme,
    required this.textStyle,
    required this.textAlign,
    required this.padding,
    required this.background,
    required this.isSelected,
    required this.isFocused,
    required this.isSearchHit,
  });
}

/// Renders one cell value as a widget. Phase 2 uses widget renderers; Phase 3
/// adds a parallel canvas-paint path for the body region.
abstract class CellRenderer {
  const CellRenderer();
  Widget build(BuildContext context, CellValue value, CellRenderContext ctx);
}

/// Picks the right renderer for a (column, value) pair. Order of resolution:
///   1. per-column override (registered by ColId)
///   2. per-CellKind default (registered by [ColumnSpec.kind])
///   3. fallback by [CellValue] runtime type
class CellRendererRegistry {
  final Map<ColId, CellRenderer> _byColumn = {};
  final Map<CellKind, CellRenderer> _byKind = {};
  final CellRenderer fallback;

  CellRendererRegistry({CellRenderer? fallback})
      : fallback = fallback ?? const _TextFallback();

  void registerColumn(ColId id, CellRenderer r) => _byColumn[id] = r;
  void registerKind(CellKind kind, CellRenderer r) => _byKind[kind] = r;

  CellRenderer resolve(ColId id, CellKind kind) =>
      _byColumn[id] ?? _byKind[kind] ?? fallback;
}

class _TextFallback extends CellRenderer {
  const _TextFallback();
  @override
  Widget build(BuildContext context, CellValue value, CellRenderContext ctx) {
    return Padding(
      padding: ctx.padding,
      child: Align(
        alignment: ctx.textAlign == TextAlign.right
            ? Alignment.centerRight
            : Alignment.centerLeft,
        child: Text(
          value is EmptyCell ? '' : value.toString(),
          style: ctx.textStyle,
          textAlign: ctx.textAlign,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}
