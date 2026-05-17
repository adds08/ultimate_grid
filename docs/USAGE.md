# Ultimate Table — Usage guide

This is the long-form how-to. If you want the architecture story
(how the pieces fit together internally), read
[`ARCHITECTURE.md`](ARCHITECTURE.md). If you want a clickable demo,
run the example app and tap through the side-nav.

Audience: a Flutter developer who has a sheet-shaped piece of data
and wants to render it without writing a custom RenderObject.

---

## Install

The package isn't on pub.dev yet. While that's still the case, use it
as a path dependency:

```yaml
dependencies:
  ultimate_grid:
    path: ../ultimate_grid          # or wherever you keep it
```

Then `flutter pub get`.

## The four core types

Everything you'll touch sits behind these four:

| Type | Owns | When you touch it |
|---|---|---|
| `GridSchema` | column + row declarations | once, at startup |
| `GridDataSource` | the actual cell values | mutate when data changes |
| `GridController` | view state (sort, filter, search, freezes, selection) | mutate when user interacts |
| `UltimateTable` | the widget | rebuild when the controller fires |

```dart
final schema = GridSchema(
  columns: const [
    ColumnSpec(id: 'name', header: 'Name'),
    ColumnSpec(id: 'qty', header: 'Qty', kind: CellKind.number),
  ],
  rows: const [RowSpec(id: 'r1'), RowSpec(id: 'r2')],
);

final source = MapGridDataSource(
  rowIds: ['r1', 'r2'],
  colIds: ['name', 'qty'],
)
  ..setValue('r1', 'name', const TextCell('Apple'))
  ..setValue('r1', 'qty',  const NumberCell(3))
  ..setValue('r2', 'name', const TextCell('Banana'))
  ..setValue('r2', 'qty',  const NumberCell(7));

final controller = GridController(schema: schema, source: source);

// In your widget tree:
UltimateTable(controller: controller);
```

That's the whole thing. Everything below is "how do I add X to that
shape."

---

## CellValue — what a cell can hold

`CellValue` is a sealed class. The whole universe of cell content is
these seven types:

| Type | Holds | Renders as (default) |
|---|---|---|
| `EmptyCell` | nothing (the missing-cell sentinel) | blank |
| `NumberCell(double)` | a numeric value | right-aligned, tabular figures, integer-compacted |
| `TextCell(String)` | a string | left-aligned text with ellipsis |
| `BoolCell(bool)` | a flag | centered tickbox (filled orange when true) |
| `DateCell(DateTime)` | a date | left-aligned `YYYY-MM-DD` |
| `FormulaCell(source, cached)` | a formula source + last-computed value | renders `cached` if set, else `=source` |
| `CustomCell(Object payload)` | anything else | `payload.toString()` (override via a renderer) |

You pattern-match on these inside any custom renderer:

```dart
String formatForDisplay(CellValue v) => switch (v) {
  EmptyCell()                 => '',
  TextCell(:final value)      => value,
  NumberCell(:final value)    => value.toStringAsFixed(2),
  BoolCell(:final value)      => value ? 'yes' : 'no',
  DateCell(:final value)      => '${value.year}-${value.month}-${value.day}',
  FormulaCell(:final source)  => '=$source',
  CustomCell(:final payload)  => payload.toString(),
};
```

`EmptyCell.instance` is a const singleton; reusing it costs no memory.

`MapGridDataSource.setValue(row, col, EmptyCell())` removes the entry
entirely (the row's inner map is pruned). The storage is **sparse** —
unset cells cost nothing.

---

## GridSchema — declaring columns and rows

```dart
GridSchema(
  columns: [
    ColumnSpec(
      id: 'sku',
      header: 'SKU',
      defaultWidth: 110,
      defaultFrozen: FrozenSide.start,         // pin left
      defaultFreezePriority: 0,                // order within the strip
      kind: CellKind.text,                     // type hint for renderers
      sortable: true,                          // shown in sort menu
      filterable: true,                        // shown in filter menu
    ),
    // ...
  ],
  rows: [
    RowSpec(id: 'r1', defaultHeight: 44),
    RowSpec(id: '__totals', defaultFrozen: FrozenSide.end), // bottom-frozen
  ],
);
```

Things worth knowing:

- `id` is just a `String`. Stable identity across reorder/sort/filter.
- `defaultWidth` / `defaultHeight` are read on first build; users can
  resize via `GridController.setColumnWidth` / `setRowHeight`.
- `defaultFrozen` lifts the row or column into one of the four frozen
  strips. `null` means "scrollable middle".
- `defaultFreezePriority` orders multiple frozen items inside the same
  strip. Lower = closer to the outer edge. So you can freeze cols 1,
  2, and 8 to the left and they'll render in priority order, not in
  declaration order.

`GridSchema` is `@immutable`. To change the schema, build a new one
and dispose the old controller.

---

## GridDataSource — where the values live

Abstract base. Two implementations ship out of the box:

### `MapGridDataSource`

In-memory, sparse, mutable. Use this when the data fits in RAM.

```dart
final source = MapGridDataSource(rowIds: [...], colIds: [...]);
source.setValue('r1', 'name', const TextCell('Apple'));
source.addRow('r5');                  // grows the row list
source.removeColumn('legacy');        // removes a column + its cells
source.addMerge(MergeRange(           // cell merges live on the source
  anchorRow: '__hdr',
  anchorCol: 'jan',
  rowSpan: 1,
  colSpan: 3,
));
source.setMetadata('r1', 'name', anyObject); // sparse side-channel
```

Every mutation bumps `source.revision` and emits a `notifyListeners()`.

### `AsyncGridDataSource`

Lazy, page-cached. Use when data lives behind an API.

```dart
final source = AsyncGridDataSource(
  rowIds: List.generate(1000, (i) => 'r$i'),
  colIds: ['name', 'price'],
  pageSize: 50,
  fetchRange: (start, end) async {
    final rows = await api.fetchRows(start: start, end: end);
    return AsyncPage(
      rowIds: rows.map((r) => r.id).toList(),
      cells: { for (final r in rows) r.id: r.toCellMap() },
    );
  },
);
```

Unfetched cells return a configurable placeholder (default
`TextCell('…')`). The first read of a row triggers its page fetch in
the background; when the page arrives, `revision` bumps and the grid
re-paints with the real values.

### Writing your own

`GridDataSource implements Listenable`. The five members you must
provide are: `rowIds`, `colIds`, `revision`, `valueAt`, `metadataAt`.
The example app's `SyntheticGridDataSource` (used by the 5 M-row
stress test) shows a minimal custom implementation that synthesises
values on demand.

---

## GridController — view state and derived layout

This is the object you'll pass to most other widgets. It owns:

- **Column state**: current order, widths, freeze sides, freeze
  priorities, hidden set.
- **Row state**: current heights, freeze sides, freeze priorities.
- **View pipeline**: sort keys, filters, search query, search mode.
- **Selection**: list of `SelectionRange`s + focused cell.
- **Derived structures** (recomputed in one pass on every mutation):
  `columnLayout`, `rowLayout`, `pipelineResult`, `mergeIndex`.

```dart
final controller = GridController(schema: schema, source: source);

// Mutate view state through the controller:
controller.setColumnFreeze('total', FrozenSide.end, priority: 0);
controller.setColumnWidth('name', 220);
controller.reorderColumn('total', 1);
controller.hideColumn('legacy');
controller.setSortKeys([SortKey('price', SortDirection.descending)]);
controller.setFilter('category', Filters.textContains('cable'));
controller.setSearchQuery('apple');
controller.setSearchMode(SearchMode.filter);     // or .highlight
controller.selectCell(2, 3);
controller.extendSelectionTo(5, 6);              // shift-extend
controller.selectRow(0);                          // whole row
controller.selectColumn(2);                       // whole column
controller.selectAll();
```

Subscribe like any other `ChangeNotifier`:

```dart
controller.addListener(() => setState(() {}));
```

The package's own widgets do this; you only need it when you want to
react in your own code (e.g. a status bar showing the selection).

---

## UltimateTable — the widget

The minimum:

```dart
UltimateTable(controller: controller);
```

Common knobs:

```dart
UltimateTable(
  controller: controller,

  // Editor + commit
  editable: true,                                  // default
  onCellCommit: (row, col, newValue) {
    // Defaults: writes back into MapGridDataSource if that's the source.
    // Override to validate / route through your own state.
  },

  // Header strip (recommended — handles 3-region h-sync + resize)
  headerBuilder: (ctx, colId) => MyHeaderCell(colId: colId),
  headerHeight: 40,
  onHeaderTap: (cellCtx, colId) => showUltimateColumnMenu(
    context: cellCtx,
    controller: controller,
    colId: colId,
  ),
  resizableHeader: true,
  headerMinWidth: 40,
  headerMaxWidth: 600,

  // Scrollbars
  showVerticalScrollbar: true,
  showHorizontalScrollbar: true,
  scrollbarGutter: 12,        // 0 = overlay inside the body
  scrollbarPadding: 3,

  // Widget overlay cells (interactive cells in the body)
  widgetColumns: const {'category', 'percent'},
  cellWidgetBuilder: (ctx, rowId, colId, value) =>
      MyInteractiveCell(rowId: rowId, colId: colId, value: value),

  // Keyboard nav
  autofocus: false,

  // Renderers (custom per-column / per-kind)
  renderers: myRendererRegistry,
);
```

Defaults match what you probably want for a "datagrid that scrolls
like Google Sheets" — gutter scrollbars, header strip with menu hook,
editable cells, single-tap select + double-tap edit.

---

## The 9-region freeze layout

Conceptually:

```
              left-frozen  scrollable middle  right-frozen
            ┌──────────┬──────────────────────┬──────────┐
header strip│          │  (h-syncs with body) │          │
            ├──────────┼──────────────────────┼──────────┤
top-frozen  │          │  (h-syncs with body) │          │
rows        │          │                      │          │
            ├──────────┼──────────────────────┼──────────┤
body        │  v-syncs │  v-syncs + h-syncs   │  v-syncs │
            │          │                      │          │
            ├──────────┼──────────────────────┼──────────┤
bottom-     │          │  (h-syncs with body) │          │
frozen rows │          │                      │          │
            └──────────┴──────────────────────┴──────────┘
```

Two `SyncedScrollGroup`s wire all of this up internally — one
horizontal (header / top-frozen / body-middle / bottom-frozen /
scrollbar-gutter), one vertical (body-left / body-middle / body-right
/ scrollbar-gutter). When the user scrolls any one, all the synced
controllers jump-to-match without re-entering the loop.

You don't construct any of this. You just declare which columns and
rows are frozen via `ColumnSpec.defaultFrozen` and
`RowSpec.defaultFrozen`, and the table assembles the regions.

---

## Rendering: fast path vs. widget overlay

The body region paints visible cells on a canvas via a custom
`RenderObject` — no widget tree per cell. That's where the
millions-of-cells scrolling story comes from.

Default body cells render as text via the registered renderers. To
make a column behave like a widget cell (checkbox, button, custom
layout, anything interactive), opt that column out:

```dart
UltimateTable(
  controller: controller,
  widgetColumns: const {'category', 'percent'},
  cellWidgetBuilder: (ctx, rowId, colId, value) {
    if (colId == 'category') return CategoryChip(rowId: rowId);
    if (colId == 'percent')  return PercentBar(value: value);
    return const SizedBox.shrink();
  },
);
```

The render object skips paint for `(rowId, colId)` pairs in
`widgetColumns`. The body region mounts a `Stack` with `Positioned`
widgets at the correct cell rects on top. You pay the widget cost only
for the columns that actually need it.

Frozen-row strips (top / bottom) always render as widgets through the
`CellRendererRegistry`. They're a small fixed number of rows so the
widget cost is negligible.

---

## CellRenderer + the registry

For columns that stay on the fast path, you can still customise how
each `CellKind` paints by registering renderers:

```dart
final registry = CellRendererRegistry()
  ..registerKind(CellKind.number, NumberCellRenderer(decimals: 4))
  ..registerKind(CellKind.bool_, const BoolCellRenderer())
  ..registerColumn('price', const CurrencyCellRenderer());
```

Resolution order: per-column override → per-`CellKind` default →
fallback.

`registerDefaultRenderers(registry)` installs the standard set
(Number, Text, Bool, Date). Pass the registry to `UltimateTable` via
the `renderers:` constructor parameter. If you don't pass one, the
default set is registered automatically.

(Custom renderers are mostly relevant in **frozen-row strips** because
the body region's canvas paint has its own hand-rolled text painter.
Phase 4+ will expose a `direct-paint` extension to renderers; today
it's widget-only.)

---

## Theming

Single source of truth is `GridTheme`:

```dart
UltimateTable(
  controller: controller,
  theme: GridTheme.mark85,   // default — the Mark 85 timesheet palette
);
```

`GridTheme` carries everything: backgrounds (regular / header /
frozen-strip / footer), selection fill + stroke, focus stroke, grid +
thick line colours/widths, text styles (header / body / numeric /
muted), cell padding.

Finer overrides are available via `ColumnStyle`, `RowStyle`, and
`CellStyle`, applied through an `InteractionPolicy`:

```dart
final banding = PredicatePolicy<Color>(
  (row, col, _, __) => row.isOdd ? const Color(0x080F172A) : null,
);
final overspendHighlight = MapPolicy<CellStyle>({
  CellAddress('rent', 'jul'): const CellStyle(
    background: Color(0xFFFEE2E2),
  ),
});
```

The off state for any policy is `null` — costs nothing. That's the
rule that keeps "millions of cells with optional per-cell styling"
realistic on memory.

---

## Filtering, sorting, search

All on the controller. Filter helpers in `Filters`:

```dart
controller.setFilter('category', Filters.textContains('cable'));
controller.setFilter('price', Filters.numberRange(min: 10, max: 500));
controller.setFilter('status', Filters.oneOf(['active', 'paused']));
controller.setFilter('any', null);     // clear
```

A filter is just a `bool Function(CellValue)`. Roll your own:

```dart
controller.setFilter('name', Filters.where((v) =>
  v is TextCell && v.value.length > 5));
```

Sort:

```dart
controller.setSortKeys([
  SortKey('price', SortDirection.descending),
  SortKey('name',  SortDirection.ascending),  // tie-breaker
]);
controller.setSortKeys(const []);   // clear
```

Search:

```dart
controller.setSearchQuery('apple');
controller.setSearchMode(SearchMode.filter);     // drop non-matches
controller.setSearchMode(SearchMode.highlight);  // mark only (default)
```

The pipeline is **single pass** — filter then sort then search, all
in one walk of the row list, on every controller revision. The
`ViewPipelineResult` is what the renderer consults.

The drop-in `UltimateSearchField` widget wires a text input + a mode
toggle for you, but you can build your own input that just calls
`controller.setSearchQuery`.

---

## Selection

Excel-style. The controller exposes everything:

```dart
controller.selectCell(rowIdx, colIdx);
controller.extendSelectionTo(rowIdx, colIdx);   // shift-extend last range
controller.addSelectionRange(rowIdx, colIdx);   // cmd-add new range
controller.selectRow(rowIdx);
controller.selectColumn(colIdx);
controller.selectAll();
controller.clearSelection();
```

The body widget already wires these into:

- Single tap → `selectCell`
- Shift-tap → `extendSelectionTo`
- Cmd/Ctrl-tap → `addSelectionRange`
- Drag → `selectCell` on press + `extendSelectionTo` on update
- Arrow / Home / End / PageUp / PageDown → directional moves
- Shift+arrow → extend
- Cmd/Ctrl+C → copy bounding rectangle as TSV (via `GridClipboard`)

For copy-to-clipboard from your own button:

```dart
import 'package:ultimate_grid/ultimate_grid.dart';

await GridClipboard.copySelection(controller);
// or get the TSV without writing to the clipboard:
final tsv = GridClipboard.selectionAsTsv(controller);
```

---

## Editing

Double-tap a cell → in-place `EditableText` overlay. Enter commits,
Esc cancels, clicking another cell commits and moves the editor.

You receive committed values through `onCellCommit`:

```dart
UltimateTable(
  controller: controller,
  onCellCommit: (rowId, colId, newValue) {
    // newValue is a parsed CellValue (number columns → NumberCell, etc.)
    // Default behaviour writes back into the MapGridDataSource.
    // Override to validate or route through your own state container.
    if (newValue is NumberCell && newValue.value < 0) return;
    myStore.update(rowId, colId, newValue);
  },
);
```

For bool cells, single-tap toggles the value (no editor). For
columns marked in `widgetColumns`, your `cellWidgetBuilder` is in
charge of editing — the framework doesn't open the text editor for
those.

---

## Cell merges

A `MergeRange` lives on the data source:

```dart
source.addMerge(MergeRange(
  anchorRow: '__quarter_header',
  anchorCol: 'jan',
  rowSpan: 1,
  colSpan: 3,                  // spans Jan + Feb + Mar
));
```

The anchor cell paints over the full `rowSpan × colSpan` area; the
other cells in the rectangle are occluded. The controller builds a
`MergeIndex` (a `Uint32List` bitset, web-safe) every revision, and the
render body consults it in O(1) per visible cell.

Merges that get split by sort / filter (e.g. you sort the rows and
the anchor ends up adjacent to a non-merged row) are silently dropped
that frame. This keeps the bitset always consistent with the visible
view.

---

## Column menu (sort / filter / pin / hide / fit)

Drop-in popup that operates on a column:

```dart
UltimateTable(
  controller: controller,
  headerBuilder: (ctx, colId) => MyHeaderCell(colId: colId),
  onHeaderTap: (cellCtx, colId) => showUltimateColumnMenu(
    context: cellCtx,
    controller: controller,
    colId: colId,
  ),
);
```

The menu inherits your app's `PopupMenuTheme`, so the elevation /
shape / colour come from `MaterialApp.theme`. Items: sort asc / desc /
clear, pin left / right / unpin, hide, resize-to-fit, filter, clear
filter. The filter action opens a kind-appropriate dialog
(text-contains or number-range) via `showUltimateFilterDialog`.

---

## Scrollbars

```dart
UltimateTable(
  showVerticalScrollbar: true,        // default
  showHorizontalScrollbar: true,      // default
  scrollbarGutter: 12,                // dedicated strip outside cells
  scrollbarPadding: 3,                // inset inside the gutter
);
```

When `scrollbarGutter > 0` the scrollbars sit in dedicated strips
outside the cell area (the Excel / Sheets shape). When `0`, they
overlay inside the rightmost / bottommost frozen slice instead.

Framework-default scrollbars on every body slice are suppressed via
`ScrollConfiguration` — you only ever see one vertical and one
horizontal thumb.

---

## Headers — three options

1. **`UltimateTable.headerBuilder`** — the recommended approach. The
   table renders the header itself with the same 3-region freeze
   layout as the body, h-syncs the middle with the body, and gives
   you drag-to-resize on every non-frozen column.

2. **`UltimateResizableHeader`** — standalone widget if you want to
   place the header somewhere other than inside `UltimateTable`. Use
   when you need full control of the header's parent layout. (You
   pay the cost of doing the h-sync yourself.)

3. **`UltimateTableHeader`** — minimal flat-Row header. Useful for
   small grids where total column width never exceeds the viewport.
   No resize, no menu, no h-sync. Avoid for production grids.

---

## Performance tips

- Prefer `widgetColumns` for *one or two* interactive columns. Don't
  flag every column as widget — that defeats the canvas-paint path.
- Don't allocate per-cell objects up front. Use `PredicatePolicy` or
  `MapPolicy` for per-cell styles / handlers / tooltips. Their off
  state is `null` and costs nothing.
- Reuse `CellRenderer` instances. They're `const`-constructible.
- Use `AsyncGridDataSource` for paginated / server-side data; the
  body never paints rows it hasn't been told about.
- Profile-mode is what matters. Debug-mode shows the worst case
  because of Flutter's debug-paint and assertion overhead.

The `benchmark_test.dart` test (in `packages/ultimate_grid/test/`)
exercises the headless pipeline and the paragraph cache at moderate
scale. Run with `flutter test test/benchmark_test.dart` — it prints
controller-build / sort / filter / search times to stdout.

---

## Where to look in the example app

| Want to see | Open |
|---|---|
| Minimum-viable shape | `Inventory` tab → `lib/examples/inventory_example.dart` |
| Full feature wiring | `Datagrid` tab → `lib/examples/datagrid_example.dart` |
| Merged cells, frozen rows + cols | `Spreadsheet` tab → `lib/examples/spreadsheet_example.dart` |
| Widget overlay cells, computed derived columns | `Budget` tab → `lib/examples/budget_example.dart` |
| 5 M rows | `Stress test` tab → `lib/examples/stress_test_example.dart` |
| A real-world consumer (originating story) | `Timesheet` tab → `lib/widgets/timesheet_grid.dart` |

The in-app **View source** button (top-right of each example) opens
the active example's `.dart` file with line numbers and a "Copy all"
button — fastest way to grab a working starting point.

---

## When to use what (cheat sheet)

| Question | Answer |
|---|---|
| Where do I put my cells? | `MapGridDataSource` (in-memory) or `AsyncGridDataSource` (paged), or write a custom one |
| How do I make column N frozen? | `ColumnSpec.defaultFrozen: FrozenSide.start` or `.end`, plus `defaultFreezePriority` if you have multiple |
| How do I sort? | `controller.setSortKeys([SortKey('colId', direction)])` |
| How do I filter? | `controller.setFilter('colId', predicate)` — see `Filters.*` |
| How do I search? | `controller.setSearchQuery(text)` + optional `setSearchMode` |
| How do I copy what's selected? | `GridClipboard.copySelection(controller)`, or just press Cmd/Ctrl+C |
| How do I add a checkbox cell? | Mark the column in `widgetColumns` + return a widget from `cellWidgetBuilder` |
| How do I derive a "total" column? | Subscribe to `source.addListener`, recompute, write derived values back into the source |
| How do I add a "row total" / "col total" row? | Frozen row + custom renderer / widget cell + derive in a source listener |
| How do I theme it? | `GridTheme.mark85` default, or build your own `GridTheme(...)` and pass via `theme:` |

That's the lot. Anything not here is either in
[`ARCHITECTURE.md`](ARCHITECTURE.md) (internals) or
[`CHANGELOG.md`](../CHANGELOG.md) (the per-phase history).
