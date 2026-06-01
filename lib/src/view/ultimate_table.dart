import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../cells/cell_renderer.dart';
import '../cells/default_renderers.dart';
import '../controller/clipboard.dart';
import '../controller/column_layout.dart';
import '../controller/grid_controller.dart';
import '../controller/row_layout.dart';
import '../controller/selection.dart';
import '../model/cell_address.dart';
import '../model/cell_value.dart';
import '../model/column_spec.dart';
import '../source/grid_data_source.dart';
import '../theme/grid_theme.dart';
import 'paragraph_cache.dart';
import 'render_body.dart';
import 'sync_scroll.dart';

/// The 9-region widget grid.
///
/// Composition: 3x3 region grid. Headers and frozen strips are widget-based;
/// the body region (top-frozen × middle-cols, middle × all-cols, bottom-frozen
/// × middle-cols) paints cells directly via a custom RenderObject for
/// millions-of-cells performance (Phase 3).
///
/// The active editor floats over the focused cell as a single overlay
/// [TextField] — exactly one widget per active editor, regardless of the
/// number of cells in the body.
class UltimateTable extends StatefulWidget {
  final GridController controller;
  final GridTheme theme;
  final CellRendererRegistry? renderers;
  final Widget? emptyState;

  /// Called when a cell is committed via the overlay editor. Default behavior
  /// writes the parsed value back into the source if the source is a
  /// [MapGridDataSource]. Provide a callback to intercept (e.g. to validate).
  final void Function(RowId row, ColId col, CellValue newValue)? onCellCommit;

  /// Called when a body row is tapped. Receives the [BuildContext] of the
  /// tap location (useful for anchoring popups) and the tapped [RowId].
  /// Fired after the default selection logic runs.
  final void Function(BuildContext context, RowId rowId)? onRowTap;

  /// Called when a body row is double-tapped. If [editable] is true the
  /// overlay editor opens first; the callback fires afterwards.
  final void Function(BuildContext context, RowId rowId)? onRowDoubleTap;

  /// Whether the body should open an overlay editor on tap. Defaults to true.
  final bool editable;

  /// Whether the grid grabs keyboard focus on mount. Defaults to false so
  /// the table doesn't steal focus from a hosting `TextField`; turn on for
  /// "spreadsheet-first" screens where keyboard navigation should be live
  /// immediately.
  final bool autofocus;

  /// Column ids whose body cells should be painted by widgets (via
  /// [cellWidgetBuilder]) instead of the cached-paragraph fast path. Use
  /// this when a column needs interactive children (checkboxes, buttons,
  /// custom layouts) inside the body. Keeps the fast path for everything
  /// else — only the listed columns pay the widget-tree cost.
  final Set<ColId> widgetColumns;

  /// Builder invoked for each body cell in a column listed in
  /// [widgetColumns]. Receives the (rowId, colId) and the current
  /// [CellValue]; return the widget that should overlay the cell rect.
  final Widget Function(
    BuildContext context,
    RowId rowId,
    ColId colId,
    CellValue value,
  )? cellWidgetBuilder;

  /// Optional header strip mounted above the top-frozen rows. The strip
  /// matches the body's 3-region freeze layout — left-frozen columns stay
  /// pinned left, middle columns horizontally scroll **in sync with the
  /// body**, right-frozen columns stay pinned right. Use this instead of
  /// the standalone [UltimateTableHeader] / [UltimateResizableHeader]
  /// widgets when total column width can exceed the viewport.
  final Widget Function(BuildContext context, ColId colId)? headerBuilder;

  /// Height of the header strip. Only used when [headerBuilder] is set.
  final double headerHeight;

  /// Called when a header cell is tapped. Carries the cell's BuildContext
  /// so callers can anchor a popup menu (`showUltimateColumnMenu`) below
  /// the actual clicked cell.
  final void Function(BuildContext context, ColId colId)? onHeaderTap;

  /// Whether dragging the right edge of a header cell should resize the
  /// column. Frozen columns are not resizable regardless of this flag.
  final bool resizableHeader;

  /// Minimum / maximum width for `resizableHeader`.
  final double headerMinWidth;
  final double headerMaxWidth;

  /// Show a single vertical scrollbar on the middle body slice. The
  /// framework-default scrollbars on the frozen slices are suppressed
  /// either way so a synced scroll only paints one thumb.
  final bool showVerticalScrollbar;

  /// Show a single horizontal scrollbar on the middle body slice.
  final bool showHorizontalScrollbar;

  /// Inset of the scrollbar from the cell content when overlaying inside
  /// the body. Only meaningful when `scrollbarGutter == 0`.
  final double scrollbarPadding;

  /// Width of the dedicated gutter strip that hosts the scrollbar(s)
  /// *outside* the table content. When `> 0`, the vertical scrollbar
  /// lives in a column to the right of every frozen + scrollable region
  /// (and the horizontal scrollbar lives in a row below them). Cells
  /// never share pixels with the scrollbar. When `0`, scrollbars overlay
  /// inside the body's right-frozen / bottom-frozen slices instead.
  final double scrollbarGutter;

  /// Whether the table is in a loading state. When true, the header row
  /// remains visible and a loading indicator is shown in the body area.
  /// When false (default), the table renders normally.
  final bool isLoading;

  /// Widget shown in the body area when [isLoading] is true. Defaults to
  /// a centered pulsing dot indicator.
  final Widget? loadingWidget;

  /// Optional footer toolbar rendered below the table body (after any
  /// bottom-frozen rows). Use this for pagination controls, row counts,
  /// action buttons, or any toolbar content that should appear anchored
  /// at the bottom of the table.
  ///
  /// The footer spans the full table width and is styled with
  /// [GridTheme.footerBackground]. It does NOT scroll with the body.
  final Widget Function(BuildContext context)? footerBuilder;

  /// Height of the footer toolbar. Only used when [footerBuilder] is set.
  /// Defaults to 44.
  final double footerHeight;

  const UltimateTable({
    super.key,
    required this.controller,
    this.theme = GridTheme.mark85,
    this.renderers,
    this.emptyState,
    this.onCellCommit,
    this.onRowTap,
    this.onRowDoubleTap,
    this.editable = true,
    this.autofocus = false,
    this.widgetColumns = const <ColId>{},
    this.cellWidgetBuilder,
    this.headerBuilder,
    this.headerHeight = 40,
    this.onHeaderTap,
    this.resizableHeader = true,
    this.headerMinWidth = 40,
    this.headerMaxWidth = 600,
    this.showVerticalScrollbar = true,
    this.showHorizontalScrollbar = true,
    this.scrollbarPadding = 3,
    this.scrollbarGutter = 12,
    this.isLoading = false,
    this.loadingWidget,
    this.footerBuilder,
    this.footerHeight = 44,
  });

  @override
  State<UltimateTable> createState() => _UltimateTableState();
}

class _UltimateTableState extends State<UltimateTable> {
  late final SyncedScrollGroup _hGroup;
  late final SyncedScrollGroup _vGroup;
  late final ScrollController _hHead;
  late final ScrollController _hTop;
  late final ScrollController _hMid;
  late final ScrollController _hBot;
  late final ScrollController _hBar;
  late final ScrollController _vLeft;
  late final ScrollController _vMid;
  late final ScrollController _vRight;
  late final ScrollController _vBar;
  late final CellRendererRegistry _renderers;
  late final ParagraphCache _paragraphCache;

  _EditingState? _editing;
  // Owned by the table state so the editor's current text can be read on
  // click-outside / programmatic close (without needing a GlobalKey on the
  // editor widget).
  final TextEditingController _editorCtrl = TextEditingController();
  final FocusNode _editorFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _hGroup = SyncedScrollGroup();
    _vGroup = SyncedScrollGroup();
    _hHead = _hGroup.attach();
    _hTop = _hGroup.attach();
    _hMid = _hGroup.attach();
    _hBot = _hGroup.attach();
    _hBar = _hGroup.attach();
    _vLeft = _vGroup.attach();
    _vMid = _vGroup.attach();
    _vRight = _vGroup.attach();
    _vBar = _vGroup.attach();
    _renderers = widget.renderers ?? CellRendererRegistry();
    if (widget.renderers == null) {
      registerDefaultRenderers(_renderers);
    }
    _paragraphCache = ParagraphCache();
    widget.controller.addListener(_onChange);
    _hMid.addListener(_closeEditorOnScroll);
    _vMid.addListener(_closeEditorOnScroll);
    _editorFocus.addListener(_onEditorFocusChanged);
  }

  @override
  void didUpdateWidget(covariant UltimateTable old) {
    super.didUpdateWidget(old);
    if (!identical(old.controller, widget.controller)) {
      old.controller.removeListener(_onChange);
      widget.controller.addListener(_onChange);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChange);
    _hMid.removeListener(_closeEditorOnScroll);
    _vMid.removeListener(_closeEditorOnScroll);
    _editorFocus.removeListener(_onEditorFocusChanged);
    _editorCtrl.dispose();
    _editorFocus.dispose();
    _hGroup.dispose();
    _vGroup.dispose();
    _paragraphCache.clear();
    super.dispose();
  }

  /// Editor focus loss = "click landed outside the editor's region but
  /// inside an ancestor that doesn't route the tap through our body
  /// handler" (header tap, scroll-gutter, app chrome). Commit the live
  /// text instead of dropping it.
  void _onEditorFocusChanged() {
    if (_editorFocus.hasFocus) return;
    if (_editing == null || !mounted) return;
    _commitOrCancelEditor(commit: true, text: _editorCtrl.text);
  }

  void _onChange() => setState(() {});

  void _closeEditorOnScroll() {
    if (_editing != null) {
      _commitOrCancelEditor(commit: true);
    }
  }

  void _openEditor(BodyCellHit hit, Rect rectInBodyRegion) {
    if (!widget.editable) return;
    final spec = widget.controller.schema.column(hit.colId);
    if (spec == null) return;
    final value = widget.controller.source.valueAt(hit.rowId, hit.colId);
    final initial = switch (value) {
      EmptyCell() => '',
      NumberCell(value: final v) =>
        v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(2),
      TextCell(value: final t) => t,
      DateCell(value: final d) =>
        '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}',
      _ => value.toString(),
    };
    _editorCtrl.text = initial;
    setState(() {
      _editing = _EditingState(
        address: CellAddress(hit.rowId, hit.colId),
        rect: rectInBodyRegion,
        initial: initial,
        colId: hit.colId,
      );
      widget.controller.setSelection(Selection(
        ranges: [SelectionRange.cell(hit.rowIndex, hit.colIndex)],
        focus: CellAddress(hit.rowId, hit.colId),
      ));
    });
    // Defer focus so the editor mounts first, then EditableText's caret
    // restore runs, then our select-all wins.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _editing == null) return;
      _editorFocus.requestFocus();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _editorCtrl.selection = TextSelection(
          baseOffset: 0,
          extentOffset: _editorCtrl.text.length,
        );
      });
    });
  }

  void _commitOrCancelEditor({required bool commit, String? text}) {
    final editing = _editing;
    if (editing == null) return;
    if (commit) {
      // If the caller passed an explicit text (Enter key path), use it;
      // otherwise read what the user has typed so far.
      final actual = text ?? _editorCtrl.text;
      final spec = widget.controller.schema.column(editing.colId);
      final kind = spec?.kind ?? CellKind.text;
      final parsed = _parseTo(kind, actual);
      _commitValue(editing.address.row, editing.colId, parsed);
    }
    setState(() {
      _editing = null;
    });
  }

  CellValue _parseTo(CellKind kind, String text) {
    if (text.isEmpty) return const EmptyCell();
    switch (kind) {
      case CellKind.number:
        final n = double.tryParse(text);
        return n == null ? TextCell(text) : NumberCell(n);
      case CellKind.bool_:
        final t = text.toLowerCase();
        if (t == 'true' || t == '1' || t == 'yes') return const BoolCell(true);
        if (t == 'false' || t == '0' || t == 'no') return const BoolCell(false);
        return TextCell(text);
      case CellKind.date:
        final d = DateTime.tryParse(text);
        return d == null ? TextCell(text) : DateCell(d);
      case CellKind.text:
      case CellKind.formula:
      case CellKind.custom:
        return TextCell(text);
    }
  }

  void _commitValue(RowId row, ColId col, CellValue value) {
    final cb = widget.onCellCommit;
    if (cb != null) {
      cb(row, col, value);
      return;
    }
    final source = widget.controller.source;
    if (source is MapGridDataSource) {
      source.setValue(row, col, value);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ctl = widget.controller;
    final cols = ctl.columnLayout;
    final rows = ctl.rowLayout;
    final theme = widget.theme;

    final hasNoRows = rows.middleViewIndices.isEmpty &&
        rows.topFrozen.isEmpty &&
        rows.bottomFrozen.isEmpty;

    if (hasNoRows && !widget.isLoading) {
      if (widget.headerBuilder != null) {
        return Column(
          children: [
            SizedBox(
              height: widget.headerHeight,
              child: _buildHeaderOnly(ctl, cols, theme),
            ),
            Expanded(
              child: widget.emptyState ?? const SizedBox.shrink(),
            ),
            if (widget.footerBuilder != null)
              Container(
                height: widget.footerHeight,
                decoration: BoxDecoration(
                  color: theme.footerBackground,
                  border: Border(top: BorderSide(color: theme.gridLine, width: theme.gridLineWidth)),
                ),
                child: widget.footerBuilder!(context),
              ),
          ],
        );
      }
      return widget.emptyState ?? const SizedBox.shrink();
    }

    if (hasNoRows && widget.isLoading) {
      return Column(
        children: [
          if (widget.headerBuilder != null)
            SizedBox(
              height: widget.headerHeight,
              child: _buildHeaderOnly(ctl, cols, theme),
            ),
          Expanded(
            child: Container(
              color: theme.background,
              child: widget.loadingWidget ?? const _DefaultLoadingIndicator(),
            ),
          ),
          if (widget.footerBuilder != null)
            Container(
              height: widget.footerHeight,
              decoration: BoxDecoration(
                color: theme.footerBackground,
                border: Border(top: BorderSide(color: theme.gridLine, width: theme.gridLineWidth)),
              ),
              child: widget.footerBuilder!(context),
            ),
        ],
      );
    }

    return Shortcuts(
      shortcuts: <ShortcutActivator, Intent>{
        const SingleActivator(LogicalKeyboardKey.keyC, meta: true):
            const _CopySelectionIntent(),
        const SingleActivator(LogicalKeyboardKey.keyC, control: true):
            const _CopySelectionIntent(),
        const SingleActivator(LogicalKeyboardKey.arrowLeft):
            const _NavIntent(_NavDir.left),
        const SingleActivator(LogicalKeyboardKey.arrowRight):
            const _NavIntent(_NavDir.right),
        const SingleActivator(LogicalKeyboardKey.arrowUp):
            const _NavIntent(_NavDir.up),
        const SingleActivator(LogicalKeyboardKey.arrowDown):
            const _NavIntent(_NavDir.down),
        const SingleActivator(LogicalKeyboardKey.arrowLeft, shift: true):
            const _NavIntent(_NavDir.left, extend: true),
        const SingleActivator(LogicalKeyboardKey.arrowRight, shift: true):
            const _NavIntent(_NavDir.right, extend: true),
        const SingleActivator(LogicalKeyboardKey.arrowUp, shift: true):
            const _NavIntent(_NavDir.up, extend: true),
        const SingleActivator(LogicalKeyboardKey.arrowDown, shift: true):
            const _NavIntent(_NavDir.down, extend: true),
        const SingleActivator(LogicalKeyboardKey.home):
            const _NavIntent(_NavDir.rowStart),
        const SingleActivator(LogicalKeyboardKey.end):
            const _NavIntent(_NavDir.rowEnd),
        const SingleActivator(LogicalKeyboardKey.pageUp):
            const _NavIntent(_NavDir.pageUp),
        const SingleActivator(LogicalKeyboardKey.pageDown):
            const _NavIntent(_NavDir.pageDown),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          _CopySelectionIntent: CallbackAction<_CopySelectionIntent>(
            onInvoke: (_) {
              _copySelection();
              return null;
            },
          ),
          _NavIntent: CallbackAction<_NavIntent>(
            onInvoke: (intent) {
              _handleNav(intent);
              return null;
            },
          ),
        },
        child: Semantics(
          label: 'Data grid',
          value: '${rows.middleViewIndices.length} rows, '
              '${cols.widths.length} columns',
          container: true,
          child: Focus(
            autofocus: widget.autofocus,
            child: _buildTable(ctl, cols, rows, theme),
          ),
        ),
      ),
    );
  }

  void _handleNav(_NavIntent intent) {
    final ctl = widget.controller;
    final sel = ctl.selection;
    final active = sel.activeRange;
    final rowsCount = ctl.pipelineResult.viewRowIndices.length;
    final colsCount = ctl.columnLayout.widths.length;
    if (rowsCount == 0 || colsCount == 0) return;
    var row = active?.extentRowIndex ?? 0;
    var col = active?.extentColIndex ?? 0;
    if (row < 0 || row >= rowsCount) row = 0;
    if (col < 0 || col >= colsCount) col = 0;
    switch (intent.dir) {
      case _NavDir.left:
        col = (col - 1).clamp(0, colsCount - 1);
      case _NavDir.right:
        col = (col + 1).clamp(0, colsCount - 1);
      case _NavDir.up:
        row = (row - 1).clamp(0, rowsCount - 1);
      case _NavDir.down:
        row = (row + 1).clamp(0, rowsCount - 1);
      case _NavDir.rowStart:
        col = 0;
      case _NavDir.rowEnd:
        col = colsCount - 1;
      case _NavDir.pageUp:
        row = (row - 10).clamp(0, rowsCount - 1);
      case _NavDir.pageDown:
        row = (row + 10).clamp(0, rowsCount - 1);
    }
    if (intent.extend) {
      ctl.extendSelectionTo(row, col);
    } else {
      ctl.selectCell(row, col);
    }
  }

  Widget _maybeWrapH({
    required bool enabled,
    required ScrollController controller,
    required Widget child,
  }) {
    if (!enabled || !widget.showHorizontalScrollbar) return child;
    return RawScrollbar(
      controller: controller,
      thumbVisibility: false,
      thumbColor: const Color(0x55334155),
      radius: const Radius.circular(4),
      thickness: 6,
      padding: EdgeInsets.only(bottom: widget.scrollbarPadding),
      child: child,
    );
  }

  /// Builds only the header row (for loading/empty states where the body
  /// has no rows but we still want column headers visible).
  Widget _buildHeaderOnly(
    GridController ctl,
    ColumnLayout cols,
    GridTheme theme,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final leftW = cols.leftFrozenWidth;
        final rightW = cols.rightFrozenWidth;
        final vGutter = (widget.showVerticalScrollbar &&
                widget.scrollbarGutter > 0)
            ? widget.scrollbarGutter
            : 0.0;
        return Container(
          color: theme.headerBackground,
          child: Row(
            children: [
              if (leftW > 0)
                SizedBox(
                  width: leftW,
                  child: _HeaderStrip(
                    controller: ctl,
                    theme: theme,
                    cols: cols.leftFrozen,
                    builder: widget.headerBuilder!,
                    onTap: widget.onHeaderTap,
                    resizable: false,
                    minWidth: widget.headerMinWidth,
                    maxWidth: widget.headerMaxWidth,
                  ),
                ),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const ClampingScrollPhysics(),
                  child: SizedBox(
                    width: cols.middleWidth,
                    child: _HeaderStrip(
                      controller: ctl,
                      theme: theme,
                      cols: cols.middle,
                      builder: widget.headerBuilder!,
                      onTap: widget.onHeaderTap,
                      resizable: widget.resizableHeader,
                      minWidth: widget.headerMinWidth,
                      maxWidth: widget.headerMaxWidth,
                    ),
                  ),
                ),
              ),
              if (rightW > 0)
                SizedBox(
                  width: rightW,
                  child: _HeaderStrip(
                    controller: ctl,
                    theme: theme,
                    cols: cols.rightFrozen,
                    builder: widget.headerBuilder!,
                    onTap: widget.onHeaderTap,
                    resizable: false,
                    minWidth: widget.headerMinWidth,
                    maxWidth: widget.headerMaxWidth,
                  ),
                ),
              if (vGutter > 0) SizedBox(width: vGutter),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTable(
    GridController ctl,
    ColumnLayout cols,
    RowLayout rows,
    GridTheme theme,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final viewportWidth = constraints.maxWidth;
        final viewportHeight = constraints.maxHeight;
        final leftW = cols.leftFrozenWidth;
        final rightW = cols.rightFrozenWidth;
        // Reserve dedicated gutters for the scrollbars when configured —
        // the cells then don't share pixels with the scrollbar thumb.
        final vGutter = (widget.showVerticalScrollbar &&
                widget.scrollbarGutter > 0)
            ? widget.scrollbarGutter
            : 0.0;
        final hGutter = (widget.showHorizontalScrollbar &&
                widget.scrollbarGutter > 0)
            ? widget.scrollbarGutter
            : 0.0;
        // Width / height available for the actual table content after the
        // gutters and footer are subtracted.
        final footerH = widget.footerBuilder != null ? widget.footerHeight : 0.0;
        final contentW = viewportWidth - vGutter;
        final contentH = (viewportHeight - hGutter - footerH).clamp(0.0, double.infinity);
        // Clamp the middle band to its natural width when the table is
        // narrower than the viewport — otherwise the right-frozen column
        // sits flush against the viewport edge with a big empty gap
        // between it and the last scrollable column. Match real-spreadsheet
        // behavior: frozen-right just sits next to the middle.
        final naturalMiddle = cols.middleWidth;
        final availableMiddle = (contentW - leftW - rightW).clamp(0.0, double.infinity);
        final middleW = naturalMiddle < availableMiddle
            ? naturalMiddle
            : availableMiddle;
        final double headerH =
            widget.headerBuilder != null ? widget.headerHeight : 0.0;
        final topH = rows.topFrozenHeight;
        final bottomH = rows.bottomFrozenHeight;
        final middleH = (contentH - headerH - topH - bottomH).clamp(0.0, double.infinity);
        // Should the in-body scrollbars still show? Only if no gutter.
        final inlineVBar =
            widget.showVerticalScrollbar && widget.scrollbarGutter == 0;
        final inlineHBar =
            widget.showHorizontalScrollbar && widget.scrollbarGutter == 0;

        final tableContent = ClipRect(
          child: Container(
          color: theme.background,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (widget.headerBuilder != null)
                SizedBox(
                  height: widget.headerHeight,
                  child: _RegionTriple(
                    leftWidth: leftW,
                    middleWidth: middleW,
                    rightWidth: rightW,
                    background: theme.headerBackground,
                    leftChild: _HeaderStrip(
                      controller: ctl,
                      theme: theme,
                      cols: cols.leftFrozen,
                      builder: widget.headerBuilder!,
                      onTap: widget.onHeaderTap,
                      resizable: false,
                      minWidth: widget.headerMinWidth,
                      maxWidth: widget.headerMaxWidth,
                    ),
                    middleChild: SingleChildScrollView(
                      controller: _hHead,
                      scrollDirection: Axis.horizontal,
                      physics: const ClampingScrollPhysics(),
                      child: SizedBox(
                        width: cols.middleWidth,
                        child: _HeaderStrip(
                          controller: ctl,
                          theme: theme,
                          cols: cols.middle,
                          builder: widget.headerBuilder!,
                          onTap: widget.onHeaderTap,
                          resizable: widget.resizableHeader,
                          minWidth: widget.headerMinWidth,
                          maxWidth: widget.headerMaxWidth,
                        ),
                      ),
                    ),
                    rightChild: _HeaderStrip(
                      controller: ctl,
                      theme: theme,
                      cols: cols.rightFrozen,
                      builder: widget.headerBuilder!,
                      onTap: widget.onHeaderTap,
                      resizable: false,
                      minWidth: widget.headerMinWidth,
                      maxWidth: widget.headerMaxWidth,
                    ),
                  ),
                ),
              if (topH > 0)
                SizedBox(
                  height: topH,
                  child: _RegionTriple(
                    leftWidth: leftW,
                    middleWidth: middleW,
                    rightWidth: rightW,
                    background: theme.frozenStripBackground,
                    leftChild: _FrozenRowsBand(
                      controller: ctl,
                      theme: theme,
                      renderers: _renderers,
                      rowIds: rows.topFrozen,
                      heights: rows.topFrozenHeights,
                      cols: cols.leftFrozen,
                    ),
                    middleChild: SingleChildScrollView(
                      controller: _hTop,
                      scrollDirection: Axis.horizontal,
                      physics: const ClampingScrollPhysics(),
                      child: SizedBox(
                        width: cols.middleWidth,
                        child: _FrozenRowsBand(
                          controller: ctl,
                          theme: theme,
                          renderers: _renderers,
                          rowIds: rows.topFrozen,
                          heights: rows.topFrozenHeights,
                          cols: cols.middle,
                        ),
                      ),
                    ),
                    rightChild: _FrozenRowsBand(
                      controller: ctl,
                      theme: theme,
                      renderers: _renderers,
                      rowIds: rows.topFrozen,
                      heights: rows.topFrozenHeights,
                      cols: cols.rightFrozen,
                    ),
                  ),
                ),
              SizedBox(
                height: middleH > 0 ? middleH : 0,
                child: _RegionTriple(
                  leftWidth: leftW,
                  middleWidth: middleW,
                  rightWidth: rightW,
                  background: theme.background,
                  leftChild: _BodyRegion(
                    controller: ctl,
                    theme: theme,
                    rowLayout: rows,
                    columnIds: cols.leftFrozen,
                    vController: _vLeft,
                    width: leftW,
                    paragraphCache: _paragraphCache,
                    onTap: _onBodyTap,
                    onDoubleTap: _onBodyDoubleTap,
                    onDragStart: _onBodyDragStart,
                    onDragUpdate: _onBodyDragUpdate,
                    editing: _editing,
                    editorCtrl: _editorCtrl,
                    editorFocus: _editorFocus,
                    widgetColumns: widget.widgetColumns,
                    cellWidgetBuilder: widget.cellWidgetBuilder,
                    onEditorSubmit: (String text) =>
                        _commitOrCancelEditor(commit: true, text: text),
                    onEditorCancel: () =>
                        _commitOrCancelEditor(commit: false),
                  ),
                  middleChild: _maybeWrapH(
                    enabled: inlineHBar && bottomH == 0,
                    controller: _hMid,
                    child: ScrollConfiguration(
                      behavior: ScrollConfiguration.of(context)
                          .copyWith(scrollbars: false),
                      child: SingleChildScrollView(
                        controller: _hMid,
                        scrollDirection: Axis.horizontal,
                        physics: const ClampingScrollPhysics(),
                        child: SizedBox(
                          width: cols.middleWidth,
                          child: _BodyRegion(
                            controller: ctl,
                            theme: theme,
                            rowLayout: rows,
                            columnIds: cols.middle,
                            vController: _vMid,
                            width: cols.middleWidth,
                            paragraphCache: _paragraphCache,
                            onTap: _onBodyTap,
                            onDoubleTap: _onBodyDoubleTap,
                            onDragStart: _onBodyDragStart,
                            onDragUpdate: _onBodyDragUpdate,
                            editing: _editing,
                            editorCtrl: _editorCtrl,
                            editorFocus: _editorFocus,
                            widgetColumns: widget.widgetColumns,
                            cellWidgetBuilder: widget.cellWidgetBuilder,
                            // Vertical scrollbar lives in the right-frozen
                            // slice when there is one — that's the right
                            // edge of the whole table. We only mount it
                            // here as a fallback when there's no right-
                            // frozen column.
                            showVerticalScrollbar:
                                inlineVBar && cols.rightFrozen.isEmpty,
                            scrollbarPadding: widget.scrollbarPadding,
                            onEditorSubmit: (String text) =>
                                _commitOrCancelEditor(
                                    commit: true, text: text),
                            onEditorCancel: () =>
                                _commitOrCancelEditor(commit: false),
                          ),
                        ),
                      ),
                    ),
                  ),
                  rightChild: _BodyRegion(
                    controller: ctl,
                    theme: theme,
                    rowLayout: rows,
                    columnIds: cols.rightFrozen,
                    vController: _vRight,
                    width: rightW,
                    paragraphCache: _paragraphCache,
                    onTap: _onBodyTap,
                    onDoubleTap: _onBodyDoubleTap,
                    onDragStart: _onBodyDragStart,
                    onDragUpdate: _onBodyDragUpdate,
                    editing: _editing,
                    editorCtrl: _editorCtrl,
                    editorFocus: _editorFocus,
                    widgetColumns: widget.widgetColumns,
                    cellWidgetBuilder: widget.cellWidgetBuilder,
                    // The right-frozen slice is the natural home for the
                    // inline scrollbar when the gutter is disabled.
                    showVerticalScrollbar: inlineVBar,
                    scrollbarPadding: widget.scrollbarPadding,
                    onEditorSubmit: (String text) =>
                        _commitOrCancelEditor(commit: true, text: text),
                    onEditorCancel: () =>
                        _commitOrCancelEditor(commit: false),
                  ),
                ),
              ),
              if (bottomH > 0)
                SizedBox(
                  height: bottomH,
                  child: _RegionTriple(
                    leftWidth: leftW,
                    middleWidth: middleW,
                    rightWidth: rightW,
                    background: theme.footerBackground,
                    leftChild: _FrozenRowsBand(
                      controller: ctl,
                      theme: theme,
                      renderers: _renderers,
                      rowIds: rows.bottomFrozen,
                      heights: rows.bottomFrozenHeights,
                      cols: cols.leftFrozen,
                    ),
                    middleChild: _maybeWrapH(
                      enabled: inlineHBar,
                      controller: _hBot,
                      child: ScrollConfiguration(
                        behavior: ScrollConfiguration.of(context)
                            .copyWith(scrollbars: false),
                        child: SingleChildScrollView(
                          controller: _hBot,
                          scrollDirection: Axis.horizontal,
                          physics: const ClampingScrollPhysics(),
                          child: SizedBox(
                            width: cols.middleWidth,
                            child: _FrozenRowsBand(
                              controller: ctl,
                              theme: theme,
                              renderers: _renderers,
                              rowIds: rows.bottomFrozen,
                              heights: rows.bottomFrozenHeights,
                              cols: cols.middle,
                            ),
                          ),
                        ),
                      ),
                    ),
                    rightChild: _FrozenRowsBand(
                      controller: ctl,
                      theme: theme,
                      renderers: _renderers,
                      rowIds: rows.bottomFrozen,
                      heights: rows.bottomFrozenHeights,
                      cols: cols.rightFrozen,
                    ),
                  ),
                ),
            // ── Footer toolbar ──
            if (widget.footerBuilder != null)
              Container(
                height: widget.footerHeight,
                decoration: BoxDecoration(
                  color: theme.footerBackground,
                  border: Border(
                    top: BorderSide(
                      color: theme.gridLine,
                      width: theme.gridLineWidth,
                    ),
                  ),
                ),
                child: widget.footerBuilder!(context),
              ),
            ],
          ),
        ),
        );
        if (vGutter == 0 && hGutter == 0) return tableContent;

        // Vertical scrollbar gutter — sits to the right of the entire
        // table content (past the right-frozen slice). Hosts a dummy
        // SingleChildScrollView whose content height matches the body's
        // scrollable middle; the controller (`_vBar`) is in the same
        // SyncedScrollGroup as `_vLeft / _vMid / _vRight`, so dragging
        // the thumb moves the body and scrolling the body moves the
        // thumb.
        final verticalBar = vGutter > 0
            ? SizedBox(
                width: vGutter,
                child: Column(
                  children: [
                    // Match the header + top-frozen rows above the body.
                    if (headerH > 0) SizedBox(height: headerH),
                    if (topH > 0) SizedBox(height: topH),
                    SizedBox(
                      height: middleH > 0 ? middleH : 0,
                      child: ScrollConfiguration(
                        behavior: ScrollConfiguration.of(context)
                            .copyWith(scrollbars: false),
                        child: RawScrollbar(
                          controller: _vBar,
                          thumbVisibility: false,
                          thumbColor: const Color(0x55334155),
                          radius: const Radius.circular(4),
                          thickness: 6,
                          child: SingleChildScrollView(
                            controller: _vBar,
                            physics: const ClampingScrollPhysics(),
                            child: SizedBox(
                              width: vGutter,
                              height: rows.middleHeight,
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Match the bottom-frozen rows below the body.
                    if (bottomH > 0) SizedBox(height: bottomH),
                  ],
                ),
              )
            : const SizedBox.shrink();

        // Horizontal scrollbar gutter — sits below everything, aligned
        // with the body's middle column slice.
        final horizontalBar = hGutter > 0
            ? SizedBox(
                height: hGutter,
                child: Row(
                  children: [
                    if (leftW > 0) SizedBox(width: leftW),
                    SizedBox(
                      width: availableMiddle > 0 ? availableMiddle : 0,
                      child: ScrollConfiguration(
                        behavior: ScrollConfiguration.of(context)
                            .copyWith(scrollbars: false),
                        child: RawScrollbar(
                          controller: _hBar,
                          thumbVisibility: false,
                          thumbColor: const Color(0x55334155),
                          radius: const Radius.circular(4),
                          thickness: 6,
                          child: SingleChildScrollView(
                            controller: _hBar,
                            scrollDirection: Axis.horizontal,
                            physics: const ClampingScrollPhysics(),
                            child: SizedBox(
                              height: hGutter,
                              width: cols.middleWidth,
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (rightW > 0) SizedBox(width: rightW),
                    if (vGutter > 0) SizedBox(width: vGutter),
                  ],
                ),
              )
            : const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: contentH > 0 ? contentH : 0,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: tableContent),
                  if (vGutter > 0) verticalBar,
                ],
              ),
            ),
            if (hGutter > 0) horizontalBar,
          ],
        );
      },
    );
  }

  void _onBodyTap(BodyCellHit hit) {
    // If an editor is open on a *different* cell, commit it first.
    final editing = _editing;
    if (editing != null &&
        (editing.address.row != hit.rowId ||
            editing.address.col != hit.colId)) {
      _commitOrCancelEditor(commit: true, text: null);
    }
    final modifiers = HardwareKeyboard.instance;
    final isShift = modifiers.isShiftPressed;
    final isCmd = modifiers.isMetaPressed || modifiers.isControlPressed;

    if (isShift) {
      widget.controller.extendSelectionTo(
        hit.rowIndex,
        hit.colIndex,
        focus: CellAddress(hit.rowId, hit.colId),
      );
      return;
    }
    if (isCmd) {
      widget.controller.addSelectionRange(
        hit.rowIndex,
        hit.colIndex,
        focus: CellAddress(hit.rowId, hit.colId),
      );
      return;
    }
    // Bool cells toggle on single tap — they have no text editor.
    if (widget.editable) {
      final spec = widget.controller.schema.column(hit.colId);
      if (spec?.kind == CellKind.bool_) {
        final cur = widget.controller.source.valueAt(hit.rowId, hit.colId);
        final next = cur is BoolCell ? !cur.value : true;
        _commitValue(hit.rowId, hit.colId, BoolCell(next));
        widget.controller.selectCell(
          hit.rowIndex,
          hit.colIndex,
          focus: CellAddress(hit.rowId, hit.colId),
        );
        return;
      }
    }
    // Single tap = select cell + focus (visible cell border).
    widget.controller.selectCell(
      hit.rowIndex,
      hit.colIndex,
      focus: CellAddress(hit.rowId, hit.colId),
    );
    widget.onRowTap?.call(context, hit.rowId);
  }

  void _onBodyDoubleTap(BodyCellHit hit) {
    if (widget.editable) {
      final spec = widget.controller.schema.column(hit.colId);
      if (spec?.kind != CellKind.bool_) {
        _openEditor(hit, hit.localRect);
      }
    }
    widget.onRowDoubleTap?.call(context, hit.rowId);
  }

  void _onBodyDragStart(BodyCellHit hit) {
    widget.controller.selectCell(
      hit.rowIndex,
      hit.colIndex,
      focus: CellAddress(hit.rowId, hit.colId),
    );
  }

  void _onBodyDragUpdate(BodyCellHit hit) {
    widget.controller.extendSelectionTo(
      hit.rowIndex,
      hit.colIndex,
      focus: CellAddress(hit.rowId, hit.colId),
    );
  }

  void _copySelection() {
    GridClipboard.copySelection(widget.controller);
  }
}

class _CopySelectionIntent extends Intent {
  const _CopySelectionIntent();
}

enum _NavDir {
  left,
  right,
  up,
  down,
  rowStart,
  rowEnd,
  pageUp,
  pageDown,
}

class _NavIntent extends Intent {
  final _NavDir dir;
  final bool extend;
  const _NavIntent(this.dir, {this.extend = false});
}

/// Header strip for one column slice. Mirrors `_FrozenRowsBand` in shape so
/// it slots into the 3-region freeze layout, but uses a `headerBuilder`
/// callback for cell content and offers an opt-in drag-to-resize handle on
/// the right edge of each non-frozen cell.
class _HeaderStrip extends StatefulWidget {
  final GridController controller;
  final GridTheme theme;
  final List<ColId> cols;
  final Widget Function(BuildContext, ColId) builder;
  final void Function(BuildContext, ColId)? onTap;
  final bool resizable;
  final double minWidth;
  final double maxWidth;
  static const double _handleHitWidth = 8;

  const _HeaderStrip({
    required this.controller,
    required this.theme,
    required this.cols,
    required this.builder,
    this.onTap,
    this.resizable = true,
    this.minWidth = 40,
    this.maxWidth = 600,
  });

  @override
  State<_HeaderStrip> createState() => _HeaderStripState();
}

class _HeaderStripState extends State<_HeaderStrip> {
  ColId? _resizingCol;
  double _startWidth = 0;
  double _startX = 0;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_bump);
  }

  @override
  void didUpdateWidget(_HeaderStrip old) {
    super.didUpdateWidget(old);
    if (!identical(old.controller, widget.controller)) {
      old.controller.removeListener(_bump);
      widget.controller.addListener(_bump);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_bump);
    super.dispose();
  }

  void _bump() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (widget.cols.isEmpty) return const SizedBox.shrink();
    final layout = widget.controller.columnLayout;
    final theme = widget.theme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final colId in widget.cols)
          _buildHeaderCell(colId, layout.widths[layout.indexOf[colId]!], theme),
      ],
    );
  }

  Widget _buildHeaderCell(ColId colId, double w, GridTheme theme) {
    return SizedBox(
      width: w,
      child: Stack(
        children: [
          Positioned.fill(
            child: Builder(
              builder: (cellCtx) => GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => widget.onTap?.call(cellCtx, colId),
                child: Container(
                  alignment: Alignment.centerLeft,
                  padding: theme.cellPadding,
                  decoration: BoxDecoration(
                    color: theme.headerBackground,
                    border: Border(
                      right: theme.showVerticalGridLines
                          ? BorderSide(
                              color: theme.gridLine,
                              width: theme.gridLineWidth,
                            )
                          : BorderSide.none,
                      bottom: BorderSide(
                        color: theme.thickLine,
                        width: theme.thickLineWidth,
                      ),
                    ),
                  ),
                  child: widget.builder(cellCtx, colId),
                ),
              ),
            ),
          ),
          if (widget.resizable)
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              width: _HeaderStrip._handleHitWidth,
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
  }
}

class _RegionTriple extends StatelessWidget {
  final double leftWidth;
  final double middleWidth;
  final double rightWidth;
  final Color background;
  final Widget leftChild;
  final Widget middleChild;
  final Widget rightChild;

  const _RegionTriple({
    required this.leftWidth,
    required this.middleWidth,
    required this.rightWidth,
    required this.background,
    required this.leftChild,
    required this.middleChild,
    required this.rightChild,
  });

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: background,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (leftWidth > 0) SizedBox(width: leftWidth, child: leftChild),
          SizedBox(
            width: middleWidth > 0 ? middleWidth : 0,
            child: middleChild,
          ),
          if (rightWidth > 0) SizedBox(width: rightWidth, child: rightChild),
        ],
      ),
    );
  }
}

/// A band of frozen rows. Still uses widget cells — frozen rows are few and
/// keep the editor wiring simple.
class _FrozenRowsBand extends StatelessWidget {
  final GridController controller;
  final GridTheme theme;
  final CellRendererRegistry renderers;
  final List<RowId> rowIds;
  final List<double> heights;
  final List<ColId> cols;

  const _FrozenRowsBand({
    required this.controller,
    required this.theme,
    required this.renderers,
    required this.rowIds,
    required this.heights,
    required this.cols,
  });

  @override
  Widget build(BuildContext context) {
    if (rowIds.isEmpty || cols.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < rowIds.length; i++)
          SizedBox(
            height: heights[i],
            child: _CellsRow(
              controller: controller,
              theme: theme,
              renderers: renderers,
              rowId: rowIds[i],
              rowIndex: -1, // frozen rows have no view index
              columnIds: cols,
            ),
          ),
      ],
    );
  }
}

/// Body region — one column slice. Scroll-viewport + custom render-object.
/// An overlay editor mounts on top of the focused cell when editing.
class _BodyRegion extends StatefulWidget {
  final GridController controller;
  final GridTheme theme;
  final RowLayout rowLayout;
  final List<ColId> columnIds;
  final ScrollController vController;
  final double width;
  final ParagraphCache paragraphCache;
  final void Function(BodyCellHit) onTap;
  final void Function(BodyCellHit)? onDoubleTap;
  final void Function(BodyCellHit)? onDragStart;
  final void Function(BodyCellHit)? onDragUpdate;
  final _EditingState? editing;
  final TextEditingController editorCtrl;
  final FocusNode editorFocus;
  final void Function(String text) onEditorSubmit;
  final VoidCallback onEditorCancel;
  final Set<ColId> widgetColumns;
  final Widget Function(
    BuildContext context,
    RowId rowId,
    ColId colId,
    CellValue value,
  )? cellWidgetBuilder;

  /// Whether this slice wraps its vertical SingleChildScrollView in a
  /// RawScrollbar. The three body slices' vertical scroll positions are
  /// synced, so only one slice (the middle) should show a thumb to avoid
  /// three identical bars appearing at once on every scroll tick.
  final bool showVerticalScrollbar;

  /// Inset between the scrollbar thumb and the right edge of the slice.
  final double scrollbarPadding;

  const _BodyRegion({
    required this.controller,
    required this.theme,
    required this.rowLayout,
    required this.columnIds,
    required this.vController,
    required this.editorCtrl,
    required this.editorFocus,
    required this.width,
    required this.paragraphCache,
    required this.onTap,
    required this.onEditorSubmit,
    required this.onEditorCancel,
    this.onDoubleTap,
    this.onDragStart,
    this.onDragUpdate,
    this.editing,
    this.widgetColumns = const <ColId>{},
    this.cellWidgetBuilder,
    this.showVerticalScrollbar = false,
    this.scrollbarPadding = 3,
  });

  @override
  State<_BodyRegion> createState() => _BodyRegionState();
}

class _BodyRegionState extends State<_BodyRegion> {
  bool get _editorInThisSlice =>
      widget.editing != null && widget.columnIds.contains(widget.editing!.colId);

  /// Slice-local column indices for widget overlays, paired with their X
  /// position + width within the slice (avoids re-walking the slice every
  /// build).
  List<({ColId colId, double left, double width})> _widgetSliceCols() {
    final cols = widget.controller.columnLayout;
    final out = <({ColId colId, double left, double width})>[];
    var cursor = 0.0;
    for (final c in widget.columnIds) {
      final w = cols.widths[cols.indexOf[c]!];
      if (widget.widgetColumns.contains(c)) {
        out.add((colId: c, left: cursor, width: w));
      }
      cursor += w;
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.columnIds.isEmpty ||
        widget.rowLayout.middleViewIndices.isEmpty) {
      return const SizedBox.shrink();
    }
    final editingAddress = widget.editing?.address;
    final widgetCols = widget.widgetColumns.isEmpty
        ? const <({ColId colId, double left, double width})>[]
        : _widgetSliceCols();
    final suppressed = widgetCols.isEmpty
        ? const <ColId>{}
        : {for (final w in widgetCols) w.colId};
    final body = UltimateBody(
      controller: widget.controller,
      theme: widget.theme,
      rowLayout: widget.rowLayout,
      columnLayout: widget.controller.columnLayout,
      columnIds: widget.columnIds,
      vController: widget.vController,
      width: widget.width,
      paragraphCache: widget.paragraphCache,
      onTap: widget.onTap,
      onDoubleTap: widget.onDoubleTap,
      onDragStart: widget.onDragStart,
      onDragUpdate: widget.onDragUpdate,
      editingCell: editingAddress,
      suppressedColumns: suppressed,
    );
    final hasEditor = _editorInThisSlice;
    final overlays = widgetCols.isEmpty
        ? const <Widget>[]
        : _buildWidgetOverlays(widgetCols);
    // Suppress the framework-default scrollbar wrapped by Material's
    // ScrollBehavior — three synced SingleChildScrollViews would otherwise
    // paint three thumbs on every scroll tick.
    final scrollView = ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
      child: SingleChildScrollView(
        controller: widget.vController,
        physics: const ClampingScrollPhysics(),
        child: (overlays.isEmpty && !hasEditor)
            ? body
            : Stack(
                clipBehavior: Clip.hardEdge,
                children: [
                  body,
                  ...overlays,
                  if (hasEditor)
                    Positioned.fromRect(
                      rect: widget.editing!.rect,
                      child: _buildEditor(widget.editing!),
                    ),
                ],
              ),
      ),
    );
    return RepaintBoundary(
      child: widget.showVerticalScrollbar
          ? RawScrollbar(
              controller: widget.vController,
              thumbVisibility: false,
              thumbColor: const Color(0x55334155),
              radius: const Radius.circular(4),
              thickness: 6,
              padding: EdgeInsets.only(right: widget.scrollbarPadding),
              child: scrollView,
            )
          : scrollView,
    );
  }

  List<Widget> _buildWidgetOverlays(
    List<({ColId colId, double left, double width})> widgetCols,
  ) {
    final builder = widget.cellWidgetBuilder;
    if (builder == null) return const <Widget>[];
    final rows = widget.rowLayout;
    final rowIdsAll =
        widget.controller.source.rowIds.toList(growable: false);
    final pipeline = widget.controller.pipelineResult;
    final out = <Widget>[];
    for (var i = 0; i < rows.middleViewIndices.length; i++) {
      final viewIdx = rows.middleViewIndices[i];
      final origIdx = pipeline.viewRowIndices[viewIdx];
      final rowId = rowIdsAll[origIdx];
      final top = rows.middleOffsets[i];
      final height = rows.middleHeights[i];
      for (final wc in widgetCols) {
        final value = widget.controller.source.valueAt(rowId, wc.colId);
        final theme = widget.theme;
        out.add(Positioned(
          left: wc.left,
          top: top,
          width: wc.width,
          height: height,
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                right: theme.showVerticalGridLines
                    ? BorderSide(color: theme.gridLine, width: theme.gridLineWidth)
                    : BorderSide.none,
                bottom: theme.showHorizontalGridLines
                    ? BorderSide(color: theme.gridLine, width: theme.gridLineWidth)
                    : BorderSide.none,
              ),
            ),
            child: Builder(
              builder: (ctx) => builder(ctx, rowId, wc.colId, value),
            ),
          ),
        ));
      }
    }
    return out;
  }

  Widget _buildEditor(_EditingState ed) {
    final spec = widget.controller.schema.column(ed.colId);
    final theme = widget.theme;
    final align = spec?.kind == CellKind.number
        ? TextAlign.right
        : TextAlign.left;
    final style = spec?.kind == CellKind.number
        ? theme.bodyNumericStyle
        : theme.bodyTextStyle;
    return UltimateCellEditor(
      controller: widget.editorCtrl,
      focusNode: widget.editorFocus,
      style: style,
      align: align,
      padding: theme.cellPadding,
      background: theme.background,
      onSubmit: widget.onEditorSubmit,
      onCancel: widget.onEditorCancel,
    );
  }
}

class _CellsRow extends StatelessWidget {
  final GridController controller;
  final GridTheme theme;
  final CellRendererRegistry renderers;
  final RowId rowId;
  final int rowIndex;
  final List<ColId> columnIds;

  const _CellsRow({
    required this.controller,
    required this.theme,
    required this.renderers,
    required this.rowId,
    required this.rowIndex,
    required this.columnIds,
  });

  @override
  Widget build(BuildContext context) {
    final schema = controller.schema;
    final cols = controller.columnLayout;
    final selection = controller.selection;
    final pipeline = controller.pipelineResult;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final colId in columnIds)
          _CellBox(
            colId: colId,
            width: cols.widths[cols.indexOf[colId]!],
            theme: theme,
            child: Builder(
              builder: (innerContext) {
                final spec = schema.column(colId);
                if (spec == null) return const SizedBox.shrink();
                final value = controller.source.valueAt(rowId, colId);
                final colIndex = cols.indexOf[colId]!;
                // Frozen-row cells use rowIndex = -1. Whole-column selection
                // ranges still apply (their row sentinel is allRows), so we
                // can detect them by passing a body-row index of 0 and only
                // accepting matches where the range is whole-column.
                final isSelected = rowIndex >= 0
                    ? selection.contains(rowIndex, colIndex)
                    : selection.ranges.any(
                        (r) => r.isWholeColumn && r.contains(0, colIndex),
                      );
                final isSearchHit =
                    rowIndex >= 0 && pipeline.isSearchHit(rowIndex);
                final renderer = renderers.resolve(colId, spec.kind);
                final base = spec.kind == CellKind.number
                    ? theme.bodyNumericStyle
                    : theme.bodyTextStyle;
                final ctx = CellRenderContext(
                  rowId: rowId,
                  colId: colId,
                  rowIndex: rowIndex,
                  colIndex: colIndex,
                  column: spec,
                  theme: theme,
                  textStyle: base,
                  textAlign: spec.kind == CellKind.number
                      ? TextAlign.right
                      : TextAlign.left,
                  padding: theme.cellPadding,
                  background: theme.background,
                  isSelected: isSelected,
                  isFocused: false,
                  isSearchHit: isSearchHit,
                );
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    if (isSelected)
                      Positioned.fill(
                        child: ColoredBox(color: theme.selectionFill),
                      ),
                    if (isSearchHit)
                      const Positioned.fill(
                        child: ColoredBox(color: Color(0x33FBBF24)),
                      ),
                    renderer.build(innerContext, value, ctx),
                  ],
                );
              },
            ),
          ),
      ],
    );
  }
}

class _CellBox extends StatelessWidget {
  final ColId colId;
  final double width;
  final Widget child;
  final GridTheme theme;
  const _CellBox({
    required this.colId,
    required this.width,
    required this.child,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(color: theme.gridLine, width: theme.gridLineWidth),
          bottom: BorderSide(color: theme.gridLine, width: theme.gridLineWidth),
        ),
      ),
      child: child,
    );
  }
}

/// Renders the schema's header row. Use as a "top-frozen" companion or place
/// directly above an UltimateTable when no schema-frozen header is needed.
class UltimateTableHeader extends StatelessWidget {
  final GridController controller;
  final GridTheme theme;
  final double height;

  const UltimateTableHeader({
    super.key,
    required this.controller,
    this.theme = GridTheme.mark85,
    this.height = 36,
  });

  @override
  Widget build(BuildContext context) {
    final cols = controller.columnLayout;
    final schema = controller.schema;
    return SizedBox(
      height: height,
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
              ...group.map(
                (colId) => Container(
                  width: cols.widths[cols.indexOf[colId]!],
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
                  child: Text(
                    schema.column(colId)?.header ?? colId,
                    style: theme.headerTextStyle,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _EditingState {
  final CellAddress address;
  final Rect rect;
  final String initial;
  final ColId colId;
  const _EditingState({
    required this.address,
    required this.rect,
    required this.initial,
    required this.colId,
  });
}

/// Internal overlay editor wrapper.
@visibleForTesting
class UltimateCellEditor extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final TextStyle style;
  final TextAlign align;
  final void Function(String text) onSubmit;
  final VoidCallback onCancel;
  final EdgeInsets padding;
  final Color background;

  const UltimateCellEditor({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.style,
    required this.align,
    required this.onSubmit,
    required this.onCancel,
    required this.padding,
    required this.background,
  });

  @override
  Widget build(BuildContext context) {
    // Transparent background — the body renderer already paints the cell
    // fill + grid lines underneath us. Filling here would cover the
    // right/bottom borders of the cell.
    return Padding(
      padding: padding,
      child: Focus(
        onKeyEvent: (node, event) {
          if (event is! KeyDownEvent) return KeyEventResult.ignored;
          if (event.logicalKey == LogicalKeyboardKey.escape) {
            onCancel();
            return KeyEventResult.handled;
          }
          if (event.logicalKey == LogicalKeyboardKey.enter ||
              event.logicalKey == LogicalKeyboardKey.numpadEnter) {
            onSubmit(controller.text);
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: EditableText(
          controller: controller,
          focusNode: focusNode,
          style: style,
          textAlign: align,
          cursorColor: const Color(0xFFEA580C),
          backgroundCursorColor: const Color(0xFF94A3B8),
          selectionColor: const Color(0x33EA580C),
          maxLines: 1,
          onSubmitted: onSubmit,
        ),
      ),
    );
  }
}

/// A simple pulsing-dot loading indicator that uses no Material/Cupertino
/// dependencies — only `flutter/widgets.dart`.
class _DefaultLoadingIndicator extends StatefulWidget {
  const _DefaultLoadingIndicator();

  @override
  State<_DefaultLoadingIndicator> createState() =>
      _DefaultLoadingIndicatorState();
}

class _DefaultLoadingIndicatorState extends State<_DefaultLoadingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, _) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(3, (i) {
              final delay = i * 0.2;
              final t = ((_ctrl.value - delay) % 1.0).clamp(0.0, 1.0);
              // Ease in-out pulse: 0→1→0
              final opacity = (1.0 - (2.0 * t - 1.0).abs()).clamp(0.3, 1.0);
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: Opacity(
                  opacity: opacity,
                  child: const DecoratedBox(
                    decoration: BoxDecoration(
                      color: Color(0xFF94A3B8),
                      shape: BoxShape.circle,
                    ),
                    child: SizedBox(width: 8, height: 8),
                  ),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}
