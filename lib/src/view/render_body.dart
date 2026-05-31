import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import '../controller/column_layout.dart';
import '../controller/grid_controller.dart';
import '../controller/row_layout.dart';
import '../model/cell_address.dart';
import '../model/cell_value.dart';
import '../model/column_spec.dart';
import '../theme/grid_theme.dart';
import 'paragraph_cache.dart';

/// Result of hit-testing a body cell — returned via the tap callback.
@immutable
class BodyCellHit {
  final int rowIndex;
  final int colIndex;
  final RowId rowId;
  final ColId colId;
  final Rect localRect;
  const BodyCellHit({
    required this.rowIndex,
    required this.colIndex,
    required this.rowId,
    required this.colId,
    required this.localRect,
  });
}

typedef BodyCellTap = void Function(BodyCellHit hit);
typedef BodyCellDrag = void Function(BodyCellHit hit);

/// Widget that owns the custom render-object body. One instance is mounted
/// per column slice (left-frozen / scrollable middle / right-frozen). Its
/// vertical scroll comes from [vController] (shared via SyncedScrollGroup).
class UltimateBody extends LeafRenderObjectWidget {
  final GridController controller;
  final GridTheme theme;
  final RowLayout rowLayout;
  final ColumnLayout columnLayout;
  final List<ColId> columnIds;
  final ScrollController vController;
  final double width;
  final ParagraphCache paragraphCache;
  final BodyCellTap? onTap;
  final BodyCellTap? onDoubleTap;
  final BodyCellDrag? onDragStart;
  final BodyCellDrag? onDragUpdate;
  final VoidCallback? onDragEnd;

  /// Cells with these (rowIndex, colId) pairs are hidden by the body —
  /// the editor widget paints them instead. Use [editingCell] for the
  /// currently-being-edited cell.
  final CellAddress? editingCell;

  /// Columns whose body cells are painted by widgets (mounted as a Stack
  /// overlay above this render object) instead of the cached-paragraph
  /// fast path. The render object skips paint for these (rowId, colId)
  /// cells so the widget overlay shows through.
  final Set<ColId> suppressedColumns;

  const UltimateBody({
    super.key,
    required this.controller,
    required this.theme,
    required this.rowLayout,
    required this.columnLayout,
    required this.columnIds,
    required this.vController,
    required this.width,
    required this.paragraphCache,
    this.onTap,
    this.onDoubleTap,
    this.onDragStart,
    this.onDragUpdate,
    this.onDragEnd,
    this.editingCell,
    this.suppressedColumns = const <ColId>{},
  });

  @override
  RenderUltimateBody createRenderObject(BuildContext context) {
    return RenderUltimateBody(
      controller: controller,
      theme: theme,
      rowLayout: rowLayout,
      columnLayout: columnLayout,
      columnIds: columnIds,
      vController: vController,
      width: width,
      paragraphCache: paragraphCache,
      onTap: onTap,
      onDoubleTap: onDoubleTap,
      onDragStart: onDragStart,
      onDragUpdate: onDragUpdate,
      onDragEnd: onDragEnd,
      editingCell: editingCell,
      suppressedColumns: suppressedColumns,
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderUltimateBody renderObject) {
    renderObject
      ..controller = controller
      ..theme = theme
      ..rowLayout = rowLayout
      ..columnLayout = columnLayout
      ..columnIds = columnIds
      ..vController = vController
      ..width = width
      ..paragraphCache = paragraphCache
      ..onTap = onTap
      ..onDoubleTap = onDoubleTap
      ..onDragStart = onDragStart
      ..onDragUpdate = onDragUpdate
      ..onDragEnd = onDragEnd
      ..editingCell = editingCell
      ..suppressedColumns = suppressedColumns;
  }
}

/// Custom render object that paints body cells directly via cached
/// [TextPainter]s. No widget tree per cell.
///
/// Layout: the render object's height is [RowLayout.middleHeight] (i.e. the
/// full scrollable content height); the host wraps us in a
/// [SingleChildScrollView] which translates the layer to the current
/// scroll position. We cull rows outside the viewport by binary-searching
/// the cumulative offset table.
class RenderUltimateBody extends RenderBox {
  RenderUltimateBody({
    required GridController controller,
    required GridTheme theme,
    required RowLayout rowLayout,
    required ColumnLayout columnLayout,
    required List<ColId> columnIds,
    required ScrollController vController,
    required double width,
    required ParagraphCache paragraphCache,
    BodyCellTap? onTap,
    BodyCellTap? onDoubleTap,
    BodyCellDrag? onDragStart,
    BodyCellDrag? onDragUpdate,
    VoidCallback? onDragEnd,
    CellAddress? editingCell,
    Set<ColId> suppressedColumns = const <ColId>{},
  })  : _controller = controller,
        _theme = theme,
        _rowLayout = rowLayout,
        _columnLayout = columnLayout,
        _columnIds = columnIds,
        _vController = vController,
        _width = width,
        _paragraphCache = paragraphCache,
        _onTap = onTap,
        _onDoubleTap = onDoubleTap,
        _onDragStart = onDragStart,
        _onDragUpdate = onDragUpdate,
        _onDragEnd = onDragEnd,
        _editingCell = editingCell,
        _suppressedColumns = suppressedColumns {
    _tapRecognizer = TapGestureRecognizer()..onTapUp = _handleTapUp;
    _panRecognizer = PanGestureRecognizer()
      ..onStart = _handlePanStart
      ..onUpdate = _handlePanUpdate
      ..onEnd = _handlePanEnd;
  }

  GridController _controller;
  GridTheme _theme;
  RowLayout _rowLayout;
  ColumnLayout _columnLayout;
  List<ColId> _columnIds;
  ScrollController _vController;
  double _width;
  ParagraphCache _paragraphCache;
  BodyCellTap? _onTap;
  BodyCellTap? _onDoubleTap;
  BodyCellDrag? _onDragStart;
  BodyCellDrag? _onDragUpdate;
  VoidCallback? _onDragEnd;
  CellAddress? _editingCell;
  Set<ColId> _suppressedColumns;
  late TapGestureRecognizer _tapRecognizer;
  late PanGestureRecognizer _panRecognizer;
  DateTime? _lastTapTime;
  Offset? _lastTapPos;

  // Reused per paint() — avoid allocating Paint objects on every frame.
  final Paint _backgroundPaint = Paint();
  final Paint _gridLinePaint = Paint();
  final Paint _selectionFillPaint = Paint();
  final Paint _searchHitPaint = Paint();
  final Paint _focusStrokePaint = Paint()..style = PaintingStyle.stroke;

  /// Per-slice cumulative X offsets (computed from [_columnIds] +
  /// [_columnLayout.widths]). Length = columnIds.length + 1.
  Float64List _sliceOffsets = Float64List(0);

  /// Per-slice column widths.
  Float64List _sliceWidths = Float64List(0);

  /// Flat indices in [_columnLayout.indexOf] for each entry in [_columnIds],
  /// so we can answer "what's the global col index of slice-local index i?"
  Int32List _sliceFlatIndices = Int32List(0);

  bool _slicesDirty = true;

  set controller(GridController v) {
    if (identical(_controller, v)) return;
    if (attached) _controller.removeListener(_onControllerChanged);
    _controller = v;
    if (attached) _controller.addListener(_onControllerChanged);
    markNeedsPaint();
  }

  set theme(GridTheme v) {
    if (identical(_theme, v)) return;
    _theme = v;
    markNeedsPaint();
  }

  set rowLayout(RowLayout v) {
    if (identical(_rowLayout, v)) return;
    _rowLayout = v;
    markNeedsLayout();
  }

  set columnLayout(ColumnLayout v) {
    if (identical(_columnLayout, v)) return;
    _columnLayout = v;
    _slicesDirty = true;
    markNeedsLayout();
  }

  set columnIds(List<ColId> v) {
    if (identical(_columnIds, v)) return;
    _columnIds = v;
    _slicesDirty = true;
    markNeedsLayout();
  }

  set vController(ScrollController v) {
    if (identical(_vController, v)) return;
    if (attached) _vController.removeListener(_onScroll);
    _vController = v;
    if (attached) _vController.addListener(_onScroll);
    markNeedsPaint();
  }

  set width(double v) {
    if (_width == v) return;
    _width = v;
    markNeedsLayout();
  }

  set paragraphCache(ParagraphCache v) {
    if (identical(_paragraphCache, v)) return;
    _paragraphCache = v;
    markNeedsPaint();
  }

  set onTap(BodyCellTap? v) {
    _onTap = v;
  }

  set onDoubleTap(BodyCellTap? v) {
    _onDoubleTap = v;
  }

  set onDragStart(BodyCellDrag? v) {
    _onDragStart = v;
  }

  set onDragUpdate(BodyCellDrag? v) {
    _onDragUpdate = v;
  }

  set onDragEnd(VoidCallback? v) {
    _onDragEnd = v;
  }

  set editingCell(CellAddress? v) {
    if (_editingCell == v) return;
    _editingCell = v;
    markNeedsPaint();
  }

  set suppressedColumns(Set<ColId> v) {
    if (identical(_suppressedColumns, v)) return;
    _suppressedColumns = v;
    markNeedsPaint();
  }

  void _onScroll() => markNeedsPaint();

  void _rebuildSlices() {
    final n = _columnIds.length;
    _sliceWidths = Float64List(n);
    _sliceOffsets = Float64List(n + 1);
    _sliceFlatIndices = Int32List(n);
    var cursor = 0.0;
    for (var i = 0; i < n; i++) {
      final flat = _columnLayout.indexOf[_columnIds[i]] ?? 0;
      final w = _columnLayout.widths[flat];
      _sliceWidths[i] = w;
      _sliceOffsets[i] = cursor;
      _sliceFlatIndices[i] = flat;
      cursor += w;
    }
    _sliceOffsets[n] = cursor;
    _slicesDirty = false;
  }

  /// Binary-search first column index whose right edge > x.
  int _firstVisibleCol(double x) {
    if (_columnIds.isEmpty) return 0;
    var lo = 0;
    var hi = _columnIds.length;
    while (lo < hi) {
      final mid = (lo + hi) >>> 1;
      if (_sliceOffsets[mid + 1] <= x) {
        lo = mid + 1;
      } else {
        hi = mid;
      }
    }
    return lo;
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _vController.addListener(_onScroll);
    _controller.addListener(_onControllerChanged);
  }

  @override
  void detach() {
    _controller.removeListener(_onControllerChanged);
    _vController.removeListener(_onScroll);
    _tapRecognizer.dispose();
    _panRecognizer.dispose();
    super.detach();
  }

  /// Selection / focus / pipeline mutate the *same* controller instance, so
  /// the `controller` setter's identity check would skip the repaint. We
  /// subscribe to the controller directly and `markNeedsPaint` on any
  /// notify — selection clicks become visible immediately.
  void _onControllerChanged() => markNeedsPaint();

  @override
  void describeSemanticsConfiguration(SemanticsConfiguration config) {
    super.describeSemanticsConfiguration(config);
    config
      ..isSemanticBoundary = true
      ..textDirection = TextDirection.ltr
      ..label = 'Body region with '
          '${_rowLayout.middleViewIndices.length} rows and '
          '${_columnIds.length} columns';
  }

  @override
  bool hitTestSelf(Offset position) => true;

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      false;

  @override
  void handleEvent(PointerEvent event, covariant BoxHitTestEntry entry) {
    if (event is PointerDownEvent) {
      _tapRecognizer.addPointer(event);
      _panRecognizer.addPointer(event);
    }
  }

  BodyCellHit? _hitAt(Offset local) {
    if (_slicesDirty) _rebuildSlices();
    final rowSlot = _rowLayout.firstVisibleMiddle(local.dy);
    if (rowSlot < 0 || rowSlot >= _rowLayout.middleViewIndices.length) {
      return null;
    }
    final colSlot = _firstVisibleCol(local.dx);
    if (colSlot < 0 || colSlot >= _columnIds.length) return null;
    final rowTop = _rowLayout.middleOffsets[rowSlot];
    final rowHeight = _rowLayout.middleHeights[rowSlot];
    final colLeft = _sliceOffsets[colSlot];
    final colWidth = _sliceWidths[colSlot];
    final rect = Rect.fromLTWH(colLeft, rowTop, colWidth, rowHeight);
    final viewIdx = _rowLayout.middleViewIndices[rowSlot];
    final origRowIdx = _controller.pipelineResult.viewRowIndices[viewIdx];
    final rowId =
        _controller.source.rowIds.toList(growable: false)[origRowIdx];
    final colId = _columnIds[colSlot];
    return BodyCellHit(
      rowIndex: viewIdx,
      colIndex: _sliceFlatIndices[colSlot],
      rowId: rowId,
      colId: colId,
      localRect: rect,
    );
  }

  /// Tap recognizer fires on every tap-up. We track the previous tap's time
  /// and position; if this tap is within 300 ms and ~20 px of the previous,
  /// we treat it as a double-tap (and skip the single-tap callback to avoid
  /// firing both on the same gesture sequence).
  void _handleTapUp(TapUpDetails details) {
    final hit = _hitAt(details.localPosition);
    if (hit == null) {
      _lastTapTime = null;
      _lastTapPos = null;
      return;
    }
    final now = DateTime.now();
    final lastTime = _lastTapTime;
    final lastPos = _lastTapPos;
    final isDouble = lastTime != null &&
        lastPos != null &&
        now.difference(lastTime).inMilliseconds < 300 &&
        (details.localPosition - lastPos).distance < 20;
    if (isDouble) {
      _lastTapTime = null;
      _lastTapPos = null;
      _onDoubleTap?.call(hit);
    } else {
      _lastTapTime = now;
      _lastTapPos = details.localPosition;
      _onTap?.call(hit);
    }
  }

  void _handlePanStart(DragStartDetails details) {
    final cb = _onDragStart;
    if (cb == null) return;
    final hit = _hitAt(details.localPosition);
    if (hit != null) cb(hit);
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    final cb = _onDragUpdate;
    if (cb == null) return;
    final hit = _hitAt(details.localPosition);
    if (hit != null) cb(hit);
  }

  void _handlePanEnd(DragEndDetails details) {
    _onDragEnd?.call();
  }

  @override
  bool get sizedByParent => false;

  @override
  void performLayout() {
    if (_slicesDirty) _rebuildSlices();
    final w = _width.isFinite ? _width : constraints.maxWidth;
    final h = _rowLayout.middleHeight;
    size = constraints.constrain(Size(w, h));
  }

  @override
  double computeMinIntrinsicWidth(double height) => _width;
  @override
  double computeMaxIntrinsicWidth(double height) => _width;
  @override
  double computeMinIntrinsicHeight(double width) => _rowLayout.middleHeight;
  @override
  double computeMaxIntrinsicHeight(double width) => _rowLayout.middleHeight;

  @override
  void paint(PaintingContext context, Offset offset) {
    if (_columnIds.isEmpty || _rowLayout.middleViewIndices.isEmpty) return;
    if (_slicesDirty) _rebuildSlices();

    final canvas = context.canvas;
    final position = _vController.hasClients ? _vController.position : null;
    // When unattached (e.g. before first scroll layout), paint the whole
    // visible portion of the size to be safe — the host clips us anyway.
    final scrollY = position?.pixels ?? 0.0;
    final viewportH =
        position?.viewportDimension ?? size.height.clamp(0.0, double.infinity);

    final firstRow = _rowLayout.firstVisibleMiddle(scrollY);
    var lastRow = _rowLayout.firstVisibleMiddle(scrollY + viewportH);
    if (lastRow < _rowLayout.middleViewIndices.length) lastRow += 1;

    const firstCol = 0;
    final lastCol = _columnIds.length;

    _backgroundPaint.color = _theme.background;
    _gridLinePaint
      ..color = _theme.gridLine
      ..strokeWidth = _theme.gridLineWidth
      ..style = PaintingStyle.stroke;
    _selectionFillPaint.color = _theme.selectionFill;
    _searchHitPaint.color = const Color(0x33FBBF24);
    _focusStrokePaint
      ..color = _theme.focusStroke
      ..strokeWidth = 2.0;

    final selection = _controller.selection;
    final pipeline = _controller.pipelineResult;
    final source = _controller.source;
    final schema = _controller.schema;
    final mergeIndex = _controller.mergeIndex;
    final rowIdsAll = source.rowIds.toList(growable: false);

    for (var rs = firstRow; rs < lastRow; rs++) {
      final rowTop = _rowLayout.middleOffsets[rs];
      final rowH = _rowLayout.middleHeights[rs];
      final viewIdx = _rowLayout.middleViewIndices[rs];
      final origIdx = pipeline.viewRowIndices[viewIdx];
      final rowId = rowIdsAll[origIdx];
      final searchHit = pipeline.isSearchHit(viewIdx);

      for (var cs = firstCol; cs < lastCol; cs++) {
        final colId = _columnIds[cs];
        final colLeft = _sliceOffsets[cs];
        var colW = _sliceWidths[cs];
        var rowHActive = rowH;
        final flatColIdx = _sliceFlatIndices[cs];

        // Merge handling: skip occluded cells; expand anchor cells.
        if (mergeIndex.isOccluded(viewIdx, flatColIdx)) {
          continue;
        }
        if (_suppressedColumns.contains(colId)) {
          // Widget overlay paints this cell on top — skip render entirely.
          continue;
        }
        final anchor = mergeIndex.anchorAt(viewIdx, flatColIdx);
        if (anchor != null) {
          // Sum extra widths within this slice.
          for (var dc = 1;
              dc < anchor.colSpan && (cs + dc) < _columnIds.length;
              dc++) {
            colW += _sliceWidths[cs + dc];
          }
          // Sum extra heights below in the same view (frozen rows excluded).
          for (var dr = 1;
              dr < anchor.rowSpan && (rs + dr) < _rowLayout.middleHeights.length;
              dr++) {
            rowHActive += _rowLayout.middleHeights[rs + dr];
          }
        }
        final cellRect = Rect.fromLTWH(
          offset.dx + colLeft,
          offset.dy + rowTop,
          colW,
          rowHActive,
        );
        final isSelected = selection.contains(viewIdx, flatColIdx);
        final isFocused = selection.focus != null &&
            selection.focus!.row == rowId &&
            selection.focus!.col == colId;
        final isEditing = _editingCell != null &&
            _editingCell!.row == rowId &&
            _editingCell!.col == colId;

        // Background.
        canvas.drawRect(cellRect, _backgroundPaint);
        if (searchHit) canvas.drawRect(cellRect, _searchHitPaint);
        if (isSelected) canvas.drawRect(cellRect, _selectionFillPaint);

        // Content — skip if editor is painting on top.
        if (!isEditing) {
          final value = source.valueAt(rowId, colId);
          final spec = schema.column(colId);
          _paintCellContent(
            canvas: canvas,
            rect: cellRect,
            value: value,
            kind: spec?.kind ?? CellKind.text,
          );
        }

        // Grid lines: right + bottom (Path-free, plain drawLine).
        if (_theme.showVerticalGridLines) {
          canvas.drawLine(
            Offset(cellRect.right - 0.5, cellRect.top),
            Offset(cellRect.right - 0.5, cellRect.bottom),
            _gridLinePaint,
          );
        }
        if (_theme.showHorizontalGridLines) {
          canvas.drawLine(
            Offset(cellRect.left, cellRect.bottom - 0.5),
            Offset(cellRect.right, cellRect.bottom - 0.5),
            _gridLinePaint,
          );
        }

        if (isFocused && !isEditing) {
          canvas.drawRect(
            cellRect.deflate(1.0),
            _focusStrokePaint,
          );
        }
      }
    }
  }

  void _paintCellContent({
    required Canvas canvas,
    required Rect rect,
    required CellValue value,
    required CellKind kind,
  }) {
    if (value is EmptyCell) return;
    // Bool cells get a tiny filled tickbox in the middle.
    if (value is BoolCell) {
      const boxSize = 14.0;
      final cx = rect.left + rect.width / 2;
      final cy = rect.top + rect.height / 2;
      final box = Rect.fromCenter(
        center: Offset(cx, cy),
        width: boxSize,
        height: boxSize,
      );
      final fill = Paint()
        ..color = value.value ? _theme.selectionStroke : _theme.background;
      final stroke = Paint()
        ..color = _theme.thickLine
        ..strokeWidth = 1.2
        ..style = PaintingStyle.stroke;
      canvas.drawRRect(
        RRect.fromRectAndRadius(box, const Radius.circular(2)),
        fill,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(box, const Radius.circular(2)),
        stroke,
      );
      if (value.value) {
        final painter = _paragraphCache.acquire(
          text: '✓',
          style: const TextStyle(
            fontSize: 10,
            color: Color(0xFFFFFFFF),
            fontWeight: FontWeight.w700,
          ),
          align: TextAlign.center,
          maxWidth: boxSize,
        );
        painter.paint(
          canvas,
          Offset(box.left, cy - painter.height / 2),
        );
      }
      return;
    }

    final text = _textForCell(value, kind);
    final pad = _theme.cellPadding;
    final innerLeft = rect.left + pad.left;
    final innerTop = rect.top + pad.top;
    final innerW = rect.width - pad.left - pad.right;
    final innerH = rect.height - pad.top - pad.bottom;
    if (innerW <= 0 || innerH <= 0) return;
    final align = kind == CellKind.number ? TextAlign.right : TextAlign.left;
    final style =
        kind == CellKind.number ? _theme.bodyNumericStyle : _theme.bodyTextStyle;
    final painter = _paragraphCache.acquire(
      text: text,
      style: style,
      align: align,
      maxWidth: innerW,
    );
    final y = innerTop + (innerH - painter.height) / 2;
    final x = align == TextAlign.right
        ? innerLeft + innerW - painter.width
        : innerLeft;
    painter.paint(canvas, Offset(x, y));
  }

  String _textForCell(CellValue value, CellKind kind) {
    switch (value) {
      case EmptyCell():
        return '';
      case NumberCell(value: final v):
        if (v == v.roundToDouble()) return v.toStringAsFixed(0);
        return v.toStringAsFixed(2);
      case TextCell(value: final t):
        return t;
      case BoolCell():
        return ''; // handled above
      case DateCell(value: final d):
        String two(int n) => n.toString().padLeft(2, '0');
        return '${d.year}-${two(d.month)}-${two(d.day)}';
      case FormulaCell(:final source, :final cached):
        return cached == null ? '=$source' : _textForCell(cached, kind);
      case CustomCell(:final payload):
        return payload.toString();
    }
  }
}
