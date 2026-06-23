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
  /// Builds a controller bound to a [schema] + [source]. Seeds column /
  /// row widths and freeze sides from the schema's defaults and subscribes
  /// to the source so data mutations rebuild derived state automatically.
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

  /// The schema this controller was constructed with. Read-only — build a
  /// new controller if the schema shape changes.
  final GridSchema schema;

  /// The data source this controller is bound to. The controller listens
  /// on it; cell mutations through `source.setValue` bump the controller's
  /// derived state automatically.
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

  /// Monotonic counter bumped on every mutation. Renderers can compare it
  /// across frames to decide whether their cached layout is still valid.
  int get revision => _revision;

  /// The current selection state. Mutate via [setSelection], [selectCell],
  /// [extendSelectionTo], etc. — never reassign the field directly.
  Selection get selection => _selection;

  /// Precomputed column partition (start-frozen / scrollable / end-frozen)
  /// + cumulative offsets. Rebuilt once per revision, not per frame.
  ColumnLayout get columnLayout => _columnLayout;

  /// Precomputed row partition (top-frozen / middle / bottom-frozen) +
  /// cumulative offsets. Frozen rows skip the filter / sort pipeline so
  /// they remain stable across view changes.
  RowLayout get rowLayout => _rowLayout;

  /// Output of the single-pass view pipeline (filter -> sort -> search).
  /// Contains the visible row-index list and the search-hit bitset that
  /// the body renderer uses to draw highlights.
  ViewPipelineResult get pipelineResult => _pipelineResult;

  /// Computed merge layout for the current view. Tracks which cells are
  /// occluded by a [MergeRange] anchor so the body skips them.
  MergeIndex get mergeIndex => _mergeIndex;

  /// Current visible column order. Reflects [reorderColumn] calls and
  /// hides. Read-only view — call [reorderColumn] to mutate.
  List<ColId> get columnOrder => List.unmodifiable(_columnOrder);

  /// Active sort keys in priority order (first = primary). Mutate via
  /// [setSortKeys]; pass `const []` to clear.
  List<SortKey> get sortKeys => List.unmodifiable(_sortKeys);

  /// Active filters keyed by column id. Mutate via [setFilter]; pass
  /// `null` as the predicate to clear one column.
  Map<ColId, FilterPredicate> get filters => Map.unmodifiable(_filters);

  /// Current search query string. Empty means no search active.
  String get searchQuery => _searchQuery;

  /// Whether the search query [searchMode] matches by highlight or by
  /// filter. See [SearchMode] for the two modes.
  SearchMode get searchMode => _searchMode;

  /// Columns hidden via [hideColumn]. Hidden columns disappear from
  /// layout but stay in the schema and data source.
  Set<ColId> get hiddenColumns => Set.unmodifiable(_hiddenColumns);

  /// Whether column [id] is currently hidden via [hideColumn].
  bool isColumnHidden(ColId id) => _hiddenColumns.contains(id);

  /// Effective width of column [id]. Falls back to the schema's
  /// [ColumnSpec.defaultWidth], then to 120 if no spec exists.
  double widthOf(ColId id) =>
      _columnWidths[id] ?? schema.column(id)?.defaultWidth ?? 120;

  /// Effective freeze side of column [id], or `null` if scrollable.
  FrozenSide? freezeOf(ColId id) => _columnFreezes[id];

  /// Effective pin priority of column [id] among same-side frozen
  /// columns. Lower values render closer to the outside edge.
  int freezePriorityOf(ColId id) =>
      _columnFreezePriorities[id] ??
      schema.column(id)?.defaultFreezePriority ??
      0;

  /// Effective height of row [id]. Falls back to the schema's
  /// `RowSpec.defaultHeight`, then to 44 if no spec exists.
  double heightOf(RowId id) =>
      _rowHeights[id] ?? schema.row(id)?.defaultHeight ?? 44;

  /// Effective freeze side of row [id], or `null` if scrollable.
  FrozenSide? rowFreezeOf(RowId id) => _rowFreezes[id];

  /// Effective pin priority of row [id] among same-side frozen rows.
  /// Lower values render closer to the outside edge of the strip.
  int rowFreezePriorityOf(RowId id) =>
      _rowFreezePriorities[id] ?? schema.row(id)?.defaultFreezePriority ?? 0;

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

  /// Sets the width of column [id]. Clamped up to the spec's `minWidth`
  /// (default 40). No-op if the width is unchanged.
  void setColumnWidth(ColId id, double width) {
    final spec = schema.column(id);
    final clamped = width < (spec?.minWidth ?? 40)
        ? (spec?.minWidth ?? 40)
        : width;
    if (_columnWidths[id] == clamped) return;
    _columnWidths[id] = clamped;
    _bump(rebuildLayout: true);
  }

  /// Pins column [id] to [side] (or unpins when `null`) with the given
  /// [priority] among same-side frozen columns. Lower priority renders
  /// closer to the outside edge.
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

  /// Hides column [id] from the visible layout. The schema and data
  /// source are untouched; pair with [showColumn] to restore.
  void hideColumn(ColId id) {
    if (_hiddenColumns.add(id)) {
      _bump(rebuildLayout: true);
    }
  }

  /// Re-shows column [id] previously hidden via [hideColumn].
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

  /// Sets the height of row [id] in logical pixels. No-op if unchanged.
  void setRowHeight(RowId id, double height) {
    if (_rowHeights[id] == height) return;
    _rowHeights[id] = height;
    _bump(rebuildLayout: true);
  }

  /// Pins row [id] to [side] (or unpins when `null`) with the given
  /// [priority] among same-side frozen rows.
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

  /// Replaces the current selection wholesale. No-op if [next] is the
  /// same instance as the current selection.
  void setSelection(Selection next) {
    if (identical(next, _selection)) return;
    _selection = next;
    _bump();
  }

  /// Clears the selection. Equivalent to `setSelection(Selection.empty)`.
  void clearSelection() => setSelection(Selection.empty);

  /// Set the selection to a single cell.
  void selectCell(int rowIndex, int colIndex, {CellAddress? focus}) {
    setSelection(
      Selection(
        ranges: [SelectionRange.cell(rowIndex, colIndex)],
        focus: focus ?? _selection.focus,
      ),
    );
  }

  /// Shift-click / drag-extend: move the active range's extent.
  void extendSelectionTo(int rowIndex, int colIndex, {CellAddress? focus}) {
    setSelection(
      _selection.extendActiveTo(
        rowIndex: rowIndex,
        colIndex: colIndex,
        focus: focus,
      ),
    );
  }

  /// Cmd/Ctrl-click: push a new single-cell range onto the existing list.
  void addSelectionRange(int rowIndex, int colIndex, {CellAddress? focus}) {
    setSelection(
      _selection.addRange(
        SelectionRange.cell(rowIndex, colIndex),
        focus: focus,
      ),
    );
  }

  /// Select an entire row (Excel "click on the row number" gesture).
  void selectRow(int rowIndex, {CellAddress? focus}) {
    setSelection(
      Selection(
        ranges: [SelectionRange.row(rowIndex)],
        focus: focus ?? _selection.focus,
      ),
    );
  }

  /// Select an entire column (Excel "click on the column letter" gesture).
  void selectColumn(int colIndex, {CellAddress? focus}) {
    setSelection(
      Selection(
        ranges: [SelectionRange.column(colIndex)],
        focus: focus ?? _selection.focus,
      ),
    );
  }

  /// Select every cell in the visible view.
  void selectAll() {
    final rows = pipelineResult.viewRowIndices.length;
    final cols = columnLayout.widths.length;
    if (rows == 0 || cols == 0) return;
    setSelection(
      Selection(
        ranges: [
          SelectionRange(
            anchorRowIndex: 0,
            anchorColIndex: 0,
            extentRowIndex: rows - 1,
            extentColIndex: cols - 1,
          ),
        ],
      ),
    );
  }

  // --- mutations: sort / filter / search ---

  /// Replaces the active sort keys with [keys] (first = primary). Pass
  /// `const []` to clear sorting and return to the source's natural order.
  void setSortKeys(List<SortKey> keys) {
    _sortKeys
      ..clear()
      ..addAll(keys);
    _bump(rebuildPipeline: true);
  }

  /// Sets the filter predicate for column [id], or clears it when
  /// [predicate] is `null`. Build predicates with the helpers in
  /// `Filters.*`.
  void setFilter(ColId id, FilterPredicate? predicate) {
    if (predicate == null) {
      _filters.remove(id);
    } else {
      _filters[id] = predicate;
    }
    _bump(rebuildPipeline: true);
  }

  /// Updates the global search query. Cells whose string form contains
  /// [query] are marked as hits; whether they're highlighted or filter
  /// non-matches depends on [searchMode].
  void setSearchQuery(String query) {
    if (_searchQuery == query) return;
    _searchQuery = query;
    _bump(rebuildPipeline: true);
  }

  /// Switches between [SearchMode.highlight] (keep every row, mark hits)
  /// and [SearchMode.filter] (drop rows with no hits).
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
