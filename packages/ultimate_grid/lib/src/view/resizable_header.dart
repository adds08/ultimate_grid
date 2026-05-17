import 'package:flutter/widgets.dart';

import '../controller/grid_controller.dart';
import '../model/cell_address.dart';
import '../theme/grid_theme.dart';

/// Header row with built-in drag-to-resize and drag-to-reorder handles.
///
/// Drop in above an [UltimateTable] when you want users to be able to widen
/// or narrow columns by dragging the right edge of the header cell, or to
/// rearrange them via long-press drag.
class UltimateResizableHeader extends StatefulWidget {
  final GridController controller;
  final GridTheme theme;
  final double height;
  final double handleHitWidth;
  final double minWidth;
  final double maxWidth;

  /// Called when the user taps the header cell body (NOT the resize handle).
  /// Receives the cell's BuildContext so popup menus can anchor under the
  /// actual header cell rather than the page origin.
  final void Function(BuildContext context, ColId colId)? onTapColumn;
  final void Function(BuildContext context, ColId colId)? onLongPressColumn;

  /// Whether long-press + drag rearranges columns. Default false — opt in
  /// when you want this; long-press recognizers compete with horizontal
  /// drags so be aware it may interact with custom gesture work.
  final bool reorderable;

  /// Render each header cell. Defaults to a left-aligned bold label.
  final Widget Function(BuildContext, ColId)? headerBuilder;

  const UltimateResizableHeader({
    super.key,
    required this.controller,
    this.theme = GridTheme.mark85,
    this.height = 38,
    this.handleHitWidth = 8,
    this.minWidth = 40,
    this.maxWidth = 600,
    this.onTapColumn,
    this.onLongPressColumn,
    this.reorderable = false,
    this.headerBuilder,
  });

  @override
  State<UltimateResizableHeader> createState() =>
      _UltimateResizableHeaderState();
}

class _UltimateResizableHeaderState extends State<UltimateResizableHeader> {
  ColId? _resizingCol;
  double _startWidth = 0;
  double _startX = 0;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onCtl);
  }

  @override
  void didUpdateWidget(UltimateResizableHeader old) {
    super.didUpdateWidget(old);
    if (!identical(old.controller, widget.controller)) {
      old.controller.removeListener(_onCtl);
      widget.controller.addListener(_onCtl);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onCtl);
    super.dispose();
  }

  void _onCtl() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final cols = widget.controller.columnLayout;
    final theme = widget.theme;
    return SizedBox(
      height: widget.height,
      child: ColoredBox(
        color: theme.headerBackground,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final group in [
              cols.leftFrozen,
              cols.middle,
              cols.rightFrozen,
            ])
              ...group.map((colId) => _buildHeaderCell(colId)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCell(ColId colId) {
    final cols = widget.controller.columnLayout;
    final theme = widget.theme;
    final w = cols.widths[cols.indexOf[colId]!];
    final isFrozen = widget.controller.freezeOf(colId) != null;
    final body = SizedBox(
      width: w,
      child: Stack(
        children: [
          Positioned.fill(
            child: Builder(
              builder: (cellCtx) => GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => widget.onTapColumn?.call(cellCtx, colId),
              onLongPress: () =>
                  widget.onLongPressColumn?.call(cellCtx, colId),
              child: Container(
                alignment: Alignment.centerLeft,
                padding: theme.cellPadding,
                decoration: BoxDecoration(
                  border: Border(
                    right: BorderSide(
                      color: theme.gridLine,
                      width: theme.gridLineWidth,
                    ),
                    bottom: BorderSide(
                      color: theme.thickLine,
                      width: theme.thickLineWidth,
                    ),
                  ),
                ),
                child: widget.headerBuilder != null
                    ? widget.headerBuilder!(context, colId)
                    : Text(
                        widget.controller.schema.column(colId)?.header ?? colId,
                        style: theme.headerTextStyle,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
              ),
            ),
            ),
          ),
          // Frozen columns aren't resizable — their width is a UX promise
          // (they sit against the viewport edge) and stretching them would
          // squeeze the scrollable middle.
          if (!isFrozen)
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              width: widget.handleHitWidth,
              child: MouseRegion(
                cursor: SystemMouseCursors.resizeColumn,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onHorizontalDragStart: (d) {
                    _resizingCol = colId;
                    _startWidth = w;
                    _startX = d.globalPosition.dx;
                  },
                  onHorizontalDragUpdate: (d) {
                    if (_resizingCol != colId) return;
                    final delta = d.globalPosition.dx - _startX;
                    final next = (_startWidth + delta)
                        .clamp(widget.minWidth, widget.maxWidth)
                        .toDouble();
                    widget.controller.setColumnWidth(colId, next);
                  },
                  onHorizontalDragEnd: (_) {
                    _resizingCol = null;
                  },
                  onHorizontalDragCancel: () {
                    _resizingCol = null;
                  },
                ),
              ),
            ),
        ],
      ),
    );

    if (!widget.reorderable) return body;

    // Long-press + horizontal drag reorders the column. We swap when the
    // drag crosses the midpoint of an adjacent header cell.
    return LongPressDraggable<ColId>(
      data: colId,
      axis: Axis.horizontal,
      delay: const Duration(milliseconds: 250),
      feedback: Container(
        width: w,
        height: widget.height,
        decoration: BoxDecoration(
          color: theme.headerBackground,
          boxShadow: const [
            BoxShadow(
              color: Color(0x33000000),
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
          border: Border.all(color: theme.thickLine),
        ),
        alignment: Alignment.center,
        child: Text(
          widget.controller.schema.column(colId)?.header ?? colId,
          style: theme.headerTextStyle,
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.3, child: body),
      child: DragTarget<ColId>(
        onWillAcceptWithDetails: (d) => d.data != colId,
        onAcceptWithDetails: (d) {
          final order = widget.controller.columnOrder;
          final to = order.indexOf(colId);
          widget.controller.reorderColumn(d.data, to);
        },
        builder: (ctx, candidates, _) {
          if (candidates.isEmpty) return body;
          return Stack(
            children: [
              body,
              Positioned.fill(
                child: IgnorePointer(
                  child: Container(
                    color: theme.selectionFill,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
