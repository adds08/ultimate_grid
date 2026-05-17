import 'package:flutter/foundation.dart';

import '../filter_sort/filters.dart';
import '../filter_sort/view_pipeline.dart';
import '../model/cell_address.dart';
import '../model/freeze.dart';
import '../model/schema.dart';
import '../source/grid_data_source.dart';
import 'column_layout.dart';
import 'merge_index.dart';
import 'row_layout.dart';
import 'selection.dart';

/// Owns the grid's view state: column order/widths/freeze, sort, filters,
/// search, selection, focus. Mutating data goes through [GridDataSource];
/// mutating the view goes through [GridController]. Both bump revisions
/// independently so renderers only repaint what changed.
class GridController extends ChangeNotifier {
  GridController({required this.schema, required this.source}) {
    _columnOrder = [for (final c in schema.columns) c.id];
    for (final c in schema.columns) {
      if (c.defaultFrozen != null) {
        _columnFreezes[c.id] = c.defaultFrozen!;
      }
      if (c.defaultFreezePriority != 0) {
        _columnFreezePriorities[c.id] = c.defaultFreezePriority;
      }
      _columnWidths[c.id] = c.defaultWidth;
    }
    for (final r in schema.rows) {
      if (r.defaultFrozen != null) {
        _rowFreezes[r.id] = r.defaultFrozen!;
      }
      if (r.defaultFreezePriority != 0) {
        _rowFreezePriorities[r.id] = r.defaultFreezePriority;
      }
      _rowHeights[r.id] = r.defaultHeight;
    }
    source.addListener(_onSourceChanged);
    _rebuildDerived();
  }

  final GridSchema schema;
  final GridDataSource source;

  // --- raw state ---
  late List<ColId> _columnOrder;
  final Map<ColId, double> _columnWidths = {};
  final Map<ColId, FrozenSide> _columnFreezes = {};
  final Map<ColId, int> _columnFreezePriorities = {};

  final Map<RowId, double> _rowHeights = {};
  final Map<RowId, FrozenSide> _rowFreezes = {};
  final Map<RowId, int> _rowFreezePriorities = {};

  final Set<ColId> _hiddenColumns = <ColId>{};
  SearchMode _searchMode = SearchMode.highlight;

  Selection _selection = Selection.empty;

  final List<SortKey> _sortKeys = [];
  final Map<ColId, FilterPredicate> _filters = {};
  String _searchQuery = '';

  // --- derived state (single pass on data/view revision) ---
  late ColumnLayout _columnLayout;
  late RowLayout _rowLayout;
  late ViewPipelineResult _pipelineResult;
  late MergeIndex _mergeIndex;
  int _revision = 0;

  // --- accessors ---
  int get revision => _revision;
  Selection get selection => _selection;
  ColumnLayout get columnLayout => _columnLayout;
  RowLayout get rowLayout => _rowLayout;
  ViewPipelineResult get pipelineResult => _pipelineResult;
  MergeIndex get mergeIndex => _mergeIndex;

  List<ColId> get columnOrder => List.unmodifiable(_columnOrder);
  List<SortKey> get sortKeys => List.unmodifiable(_sortKeys);
  Map<ColId, FilterPredicate> get filters => Map.unmodifiable(_filters);
  String get searchQuery => _searchQuery;
  SearchMode get searchMode => _searchMode;
  Set<ColId> get hiddenColumns => Set.unmodifiable(_hiddenColumns);
  bool isColumnHidden(ColId id) => _hiddenColumns.contains(id);

  double widthOf(ColId id) =>
      _columnWidths[id] ?? schema.column(id)?.defaultWidth ?? 120;
  FrozenSide? freezeOf(ColId id) => _columnFreezes[id];
  int freezePriorityOf(ColId id) =>
      _columnFreezePriorities[id] ??
      schema.column(id)?.defaultFreezePriority ??
      0;

  double heightOf(RowId id) =>
      _rowHeights[id] ?? schema.row(id)?.defaultHeight ?? 44;
  FrozenSide? rowFreezeOf(RowId id) => _rowFreezes[id];
  int rowFreezePriorityOf(RowId id) =>
      _rowFreezePriorities[id] ??
      schema.row(id)?.defaultFreezePriority ??
      0;

  /// Resize column [id] to fit the widest visible cell. Caller supplies the
  /// [measure] callback (typically backed by a `TextPainter` or paragraph
  /// cache) — the controller stays UI-framework agnostic. [padding] is
  /// added to each measurement before taking the max. Returns the chosen
  /// width.
  double fitColumnToText({
    required ColId id,
    required double Function(String text) measure,
    double padding = 24,
    int maxRowsToScan = 200,
  }) {
    final spec = schema.column(id);
    final header = spec?.header ?? id;
    var best = measure(header);
    final scanRows = source.rowIds.take(maxRowsToScan);
    for (final rowId in scanRows) {
      final value = source.valueAt(rowId, id);
      final text = value.toString();
      if (text.isEmpty) continue;
      final w = measure(text);
      if (w > best) best = w;
    }
    final width = best + padding;
    setColumnWidth(id, width);
    // setColumnWidth may clamp to the spec's minWidth — return the actual.
    return widthOf(id);
  }

  // --- mutations: columns ---
  void setColumnWidth(ColId id, double width) {
    final spec = schema.column(id);
    final clamped = width < (spec?.minWidth ?? 40) ? (spec?.minWidth ?? 40) : width;
    if (_columnWidths[id] == clamped) return;
    _columnWidths[id] = clamped;
    _bump(rebuildLayout: true);
  }

  void setColumnFreeze(ColId id, FrozenSide? side, {int priority = 0}) {
    if (side == null) {
      _columnFreezes.remove(id);
      _columnFreezePriorities.remove(id);
    } else {
      _columnFreezes[id] = side;
      _columnFreezePriorities[id] = priority;
    }
    _bump(rebuildLayout: true);
  }

  void hideColumn(ColId id) {
    if (_hiddenColumns.add(id)) {
      _bump(rebuildLayout: true);
    }
  }

  void showColumn(ColId id) {
    if (_hiddenColumns.remove(id)) {
      _bump(rebuildLayout: true);
    }
  }

  /// Move column [id] to flat index [toIndex] in the current visible order.
  void reorderColumn(ColId id, int toIndex) {
    final from = _columnOrder.indexOf(id);
    if (from < 0) return;
    final clamped = toIndex.clamp(0, _columnOrder.length - 1);
    if (from == clamped) return;
    _columnOrder.removeAt(from);
    _columnOrder.insert(clamped, id);
    _bump(rebuildLayout: true);
  }

  // --- mutations: rows ---
  void setRowHeight(RowId id, double height) {
    if (_rowHeights[id] == height) return;
    _rowHeights[id] = height;
    _bump(rebuildLayout: true);
  }

  void setRowFreeze(RowId id, FrozenSide? side, {int priority = 0}) {
    if (side == null) {
      _rowFreezes.remove(id);
      _rowFreezePriorities.remove(id);
    } else {
      _rowFreezes[id] = side;
      _rowFreezePriorities[id] = priority;
    }
    _bump(rebuildLayout: true);
  }

  /// Move row [id] to flat position [toIndex] in the underlying source.
  /// Frozen rows still freeze; the schema order changes underneath.
  void reorderRow(RowId id, int toIndex) {
    final source = this.source;
    if (source is! MapGridDataSource) return;
    final current = source.rowIds.toList(growable: true);
    final from = current.indexOf(id);
    if (from < 0) return;
    final clamped = toIndex.clamp(0, current.length - 1);
    if (from == clamped) return;
    current.removeAt(from);
    current.insert(clamped, id);
    source.reorderRows(current);
  }

  // --- mutations: selection ---
  void setSelection(Selection next) {
    if (identical(next, _selection)) return;
    _selection = next;
    _bump();
  }

  void clearSelection() => setSelection(Selection.empty);

  /// Set the selection to a single cell.
  void selectCell(int rowIndex, int colIndex, {CellAddress? focus}) {
    setSelection(Selection(
      ranges: [SelectionRange.cell(rowIndex, colIndex)],
      focus: focus ?? _selection.focus,
    ));
  }

  /// Shift-click / drag-extend: move the active range's extent.
  void extendSelectionTo(int rowIndex, int colIndex, {CellAddress? focus}) {
    setSelection(_selection.extendActiveTo(
      rowIndex: rowIndex,
      colIndex: colIndex,
      focus: focus,
    ));
  }

  /// Cmd/Ctrl-click: push a new single-cell range onto the existing list.
  void addSelectionRange(int rowIndex, int colIndex, {CellAddress? focus}) {
    setSelection(_selection.addRange(
      SelectionRange.cell(rowIndex, colIndex),
      focus: focus,
    ));
  }

  /// Select an entire row (Excel "click on the row number" gesture).
  void selectRow(int rowIndex, {CellAddress? focus}) {
    setSelection(Selection(
      ranges: [SelectionRange.row(rowIndex)],
      focus: focus ?? _selection.focus,
    ));
  }

  /// Select an entire column (Excel "click on the column letter" gesture).
  void selectColumn(int colIndex, {CellAddress? focus}) {
    setSelection(Selection(
      ranges: [SelectionRange.column(colIndex)],
      focus: focus ?? _selection.focus,
    ));
  }

  /// Select every cell in the visible view.
  void selectAll() {
    final rows = pipelineResult.viewRowIndices.length;
    final cols = columnLayout.widths.length;
    if (rows == 0 || cols == 0) return;
    setSelection(Selection(
      ranges: [
        SelectionRange(
          anchorRowIndex: 0,
          anchorColIndex: 0,
          extentRowIndex: rows - 1,
          extentColIndex: cols - 1,
        ),
      ],
    ));
  }

  // --- mutations: sort / filter / search ---
  void setSortKeys(List<SortKey> keys) {
    _sortKeys
      ..clear()
      ..addAll(keys);
    _bump(rebuildPipeline: true);
  }

  void setFilter(ColId id, FilterPredicate? predicate) {
    if (predicate == null) {
      _filters.remove(id);
    } else {
      _filters[id] = predicate;
    }
    _bump(rebuildPipeline: true);
  }

  void setSearchQuery(String query) {
    if (_searchQuery == query) return;
    _searchQuery = query;
    _bump(rebuildPipeline: true);
  }

  void setSearchMode(SearchMode mode) {
    if (_searchMode == mode) return;
    _searchMode = mode;
    _bump(rebuildPipeline: true);
  }

  // --- internals ---
  void _onSourceChanged() {
    _bump(rebuildLayout: true, rebuildPipeline: true);
  }

  void _rebuildDerived() {
    _columnLayout = ColumnLayout.compute(
      order: _columnOrder,
      widthOf: widthOf,
      freezeOf: freezeOf,
      priorityOf: freezePriorityOf,
      isHidden: _hiddenColumns.isEmpty ? null : _hiddenColumns.contains,
    );
    _pipelineResult = ViewPipeline.run(
      source: source,
      sortKeys: _sortKeys,
      filters: _filters,
      query: _searchQuery,
      searchFiltersRows: _searchMode == SearchMode.filter,
    );
    final rowIdsSchema = source.rowIds.toList(growable: false);
    _rowLayout = RowLayout.compute(
      allRowIdsInSchemaOrder: rowIdsSchema,
      viewRowIndices: _pipelineResult.viewRowIndices,
      heightOf: heightOf,
      freezeOf: rowFreezeOf,
      priorityOf: rowFreezePriorityOf,
    );
    final colIdsSchema = source.colIds.toList(growable: false);
    if (source.merges.isEmpty) {
      _mergeIndex = MergeIndex.empty();
    } else {
      // viewRow lookup: invert pipelineResult.viewRowIndices (small in
      // practice, but rebuilt here once per revision).
      final viewOfRow = <RowId, int>{};
      for (var i = 0; i < _pipelineResult.viewRowIndices.length; i++) {
        viewOfRow[rowIdsSchema[_pipelineResult.viewRowIndices[i]]] = i;
      }
      _mergeIndex = MergeIndex.compute(
        merges: source.merges,
        viewRowCount: _pipelineResult.viewRowIndices.length,
        totalColCount: _columnLayout.widths.length,
        viewRowOfRowId: (id) => viewOfRow[id] ?? -1,
        flatColOfColId: (id) => _columnLayout.indexOf[id] ?? -1,
        rowIdsInSchemaOrder: rowIdsSchema,
        colIdsInSchemaOrder: colIdsSchema,
      );
    }
  }

  void _bump({bool rebuildLayout = false, bool rebuildPipeline = false}) {
    if (rebuildLayout || rebuildPipeline) {
      _rebuildDerived();
    }
    _revision++;
    notifyListeners();
  }

  @override
  void dispose() {
    source.removeListener(_onSourceChanged);
    super.dispose();
  }
}
