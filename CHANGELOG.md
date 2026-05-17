# Changelog

All notable changes to this repository are documented per phase. The repo
hosts two things side by side:

1. **The Mark 85 timesheet demo** (`lib/main.dart`) — the original prototype
   the project started from. Kept untouched while the package is built.
2. **The `ultimate_grid` package** (`packages/ultimate_grid/`) — *Ultimate
   Table by CodeBigya*, a scalable, themable 2D data-grid for Flutter.

Each phase is one isolated commit. Bugs surfaced after a phase are folded
back into that phase's commit, not added as separate fix commits, so any
phase commit on its own is a clean working state.

The repository's own version is tracked under `pubspec.yaml` (`version:`); the
package's own version is tracked under `packages/ultimate_grid/pubspec.yaml`.

## [Phase 0] — Mark 85 timesheet scaffold + input polish

Initial scaffold of the repo. A working 2D timesheet grid built on Flutter's
standard widgets, with linked horizontal/vertical scrolling, undo/redo state
management, per-worker absent toggle, per-cost-code quantity row, totals
footer, and a right strip for Hours / OT / Per Diem. This is the demo that
motivated building a generic package — and the visual reference for the
default `GridTheme`.

### Added
- `lib/main.dart` and the Mark 85 timesheet UI in `lib/widgets/grid_screen.dart`.
- `GridState` with snapshot-based undo/redo (50-frame cap) in `lib/state/grid_state.dart`.
- `lib/widgets/cells.dart` — `HourInputCell`, `NumericCell`, `LabelText`, and the `cellBox` decorator.
- Mark 85 color/spacing/typography system in `lib/theme/mark85_theme.dart`.
- Mock workers + cost codes in `lib/data/mock_data.dart`.
- Standard Flutter project scaffolding for android / ios / web.

### Input polish (folded into this commit — pre-existing baseline had no prior commit to diff against)
- `HourInputCell` selects all text on focus.
- Enter / Numpad Enter commits and moves to next focus.
- Esc cancels and restores the prior value.

## [Phase 1] — `ultimate_grid` headless model

Bootstrapped the `ultimate_grid` package — *Ultimate Table by CodeBigya* —
as a path dependency of the example app. Phase 1 ships **no rendering**: it's
the headless data model and view-state controller that subsequent phases
build on. 24 unit tests cover the contract.

### Added
- New package at `packages/ultimate_grid/` with strict-cast analyzer options.
- `CellValue` sealed hierarchy: `Empty / Number / Text / Bool / Date / Formula / Custom`. `EmptyCell.instance` is the singleton missing-cell sentinel.
- `CellAddress`, `RowId`, `ColId` (typedefs over `String`).
- `ColumnSpec` (with `CellKind`, default width, freeze + freeze-priority, sortable/filterable flags, free-form tag) and `RowSpec`.
- `GridSchema` — immutable column/row description with O(1) lookups.
- `GridDataSource` abstract interface + `MapGridDataSource` reference implementation. Sparse cell storage (`Map<RowId, Map<ColId, CellValue>>`), **lazy/sparse metadata side-channel** (only allocates if used — zero per-cell cost when off), monotonic `revision` counter.
- `InteractionPolicy<T>` abstraction with three implementations: `MapPolicy` (explicit per-cell), `PredicatePolicy` (rule-driven; includes `evenCells` helper for "only cells where row.isEven && col.isEven"), and a composition operator (`overriddenBy`). Powers per-cell styles, handlers, tooltips, badges, and conditional formatting through one shape.
- `Selection` + `SelectionRange` — Excel-style ranges including whole-row and whole-column selections via sentinel indices.
- `ColumnLayout` — precomputed 3-region column partition (left-frozen / scrollable middle / right-frozen). Supports non-contiguous frozen columns (e.g. freeze cols 1, 2, 8) ordered by pin priority. Cumulative widths/offsets stored in `Float64List`; binary-search `firstVisibleMiddle` for O(log n) viewport calcs.
- `GridController` — owns view state (column order, widths, freeze, selection, sort keys, filter predicates, search query). Single-pass derived-state rebuild on data or view revision (`_rebuildDerived` runs `ColumnLayout.compute` and `ViewPipeline.run` once per change).
- `ViewPipeline` (filter → sort → search) producing a `ViewPipelineResult` with `Int32List viewRowIndices` and a search-hit bitset. Stable multi-column sort via merged `Comparator<CellValue>` chain. Default comparators handle Number / Bool / Date / Text and treat `EmptyCell` as sort-last.

### Fixed (folded into this phase — bug originated in this phase's `view_pipeline.dart`)
- Search-hit bitset uses `Uint32List` instead of `Uint64List`. Flutter web doesn't support `Uint64List` (JavaScript has no native 64-bit integer); using a 32-bit word with `>> 5` / `& 31` bit-addressing fixes the runtime crash discovered when first running the Phase 2 demo on Chrome (`UnsupportedError: Uint64List not supported on the web`). The fix is placed in the phase that introduced the file, not as a follow-up.

## [Phase 2] — 9-region widget grid + simple demo

First visible iteration. `UltimateTable` widget composes 9 regions (top-frozen
rows × bottom-frozen rows × scrollable middle, crossed with left-frozen cols ×
right-frozen cols × scrollable middle). Headers, body, and frozen strips
share one synced-scroll mechanism. Body cells use a virtualized
`ListView.builder` for now; Phase 3 will swap that for a custom RenderObject
to hit the millions-of-cells / no-jitter target. A simple standalone demo
makes it possible to verify each future phase visually.

### Added
- `RowLayout` — mirror of `ColumnLayout` for rows: top-frozen / scrollable / bottom-frozen partitions, post-filter middle (frozen rows skip filter+sort), `Float64List` cumulative offsets, binary-search `firstVisibleMiddle`. Frozen rows in middle are excluded so freezes remain stable regardless of view ordering.
- `GridController` extended with row height/freeze state and a `rowLayout` derived property; row layout is computed in the same single-pass `_rebuildDerived` step as column layout and the view pipeline.
- `GridTheme` (default `GridTheme.mark85` from the timesheet palette) with `ColumnStyle` / `RowStyle` / `CellStyle` overrides. Resolution order: theme → column → row → cell.
- `CellRenderer` abstraction + `CellRendererRegistry`. Resolution order: per-column override → per-`CellKind` default → fallback. `CellRenderContext` carries everything a renderer needs (style, alignment, padding, selection/focus/search flags).
- Default renderers: `NumberCellRenderer` (right-aligned, configurable decimals, integer compaction), `TextCellRenderer`, `BoolCellRenderer` (Excel-style filled tickbox), `DateCellRenderer` (ISO date). `registerDefaultRenderers` installs them onto a registry by `CellKind`.
- `SyncedScrollGroup` — tiny internal multi-controller scroll syncer (no extra dependency added to the package).
- `UltimateTable` widget — composes the 9 regions, wires synced horizontal/vertical scrolling, draws selection fill + search highlight on top of cell content, virtualizes the middle via `ListView.builder`.
- `UltimateTableHeader` helper widget — header row driven by `GridController.columnLayout` for callers that don't need a custom sortable header.
- `lib/demo_ultimate.dart` — **standalone simple demo** at `flutter run -t lib/demo_ultimate.dart`. 60-row product inventory, 10 typed columns, click-header-to-sort (asc → desc → off), search box, and chip toggles for left-freezing SKU + Product and right-freezing Margin. Replaces the prior "timesheet is the only demo" friction.
- Two more test files (29 total): `row_layout_test.dart` and `ultimate_grid_widget_test.dart` (smoke tests: header rendering, cell value rendering, right-frozen column visibility).

### Changed
- `packages/ultimate_grid/lib/ultimate_grid.dart` barrel exports the new `row_layout`, `grid_theme`, `cell_renderer`, `default_renderers`, and `ultimate_grid` widget surface.

## [Phase 3] — Custom `RenderObject` body + paragraph cache + overlay editor

Replaces the Phase 2 widget-per-cell body with a single custom `RenderObject`
that paints visible cells directly via cached `TextPainter`s. The widget
API of `UltimateTable` is unchanged — the demo runs the same way, but the
body region no longer allocates a widget tree per cell.

### Added
- `RenderUltimateBody` (`packages/ultimate_grid/lib/src/view/render_body.dart`)
  — custom `RenderBox` that paints body cells directly. Binary-search culls
  rows outside the viewport using the precomputed `RowLayout.middleOffsets`;
  per-slice column offsets are precomputed once and reused.
- `ParagraphCache` — bounded LRU of laid-out `TextPainter`s keyed by
  `(text, style, align, maxWidth)`. Capacity defaults to 1024; eviction is
  the oldest entry. Web-compatible.
- `UltimateBody` `LeafRenderObjectWidget` mounted once per column slice
  (left-frozen / middle / right-frozen), exported from the barrel for tests.
- `BodyCellHit` — value returned by the body's tap callback (rowIndex,
  colIndex, rowId, colId, localRect).
- `UltimateCellEditor` — single in-place editor widget mounted via a
  `Positioned` overlay on the editing cell's slice. Enter / NumpadEnter
  commits, Esc cancels, selection-on-focus on first paint. Bool cells skip
  the editor and toggle directly on tap.
- `UltimateTable.onCellCommit` + `editable` — optional commit hook and
  master switch for the editor.
- Paint-side optimizations: `RepaintBoundary` around each body slice;
  one reused `Paint` per role (background / grid line / selection /
  search-hit / focus stroke); pre-allocated cumulative offset / width
  `Float64List` per slice.

### Changed
- `_BodyRegion` no longer uses `ListView.builder`. It wraps a single
  `UltimateBody` in a `SingleChildScrollView` and stacks the overlay editor
  on top when the editing cell belongs to that slice.
- Frozen-row strips remain widget-based (small row counts, simpler).
- The `ultimate_grid` barrel now exports `ParagraphCache`, `BodyCellHit`,
  and `UltimateBody`.

### Tests (5 added — 34 total)
- `paragraph_cache_test.dart` — identity on repeat lookup, LRU eviction,
  `clear()` empties the cache.
- `ultimate_grid_widget_test.dart` — assertions ported to the custom
  body path (controller-derived assertions for body cells; header text
  still findable as widgets). New cases: tap opens overlay editor for
  text/number cells; tap toggles a bool cell without opening the editor.

## [Phase 4] — Multi-range selection, copy/paste, cell merge, drag-reorder + resize

Selection grows to full Excel-style behavior. Cell merging lands as a
declaration on the data source plus an occlusion bitset consulted by the
custom body renderer at paint time. A dedicated resizable header widget
ships so users can widen or narrow columns by dragging the right edge.
Cmd/Ctrl+C copies the current selection to the system clipboard as TSV.

### Added
- `MergeRange` (`packages/ultimate_grid/lib/src/model/merge.dart`) —
  declarative cell merge addressed by `(anchorRow, anchorCol, rowSpan,
  colSpan)`. Stable across data revisions; references schema ids.
- `MapGridDataSource.addMerge / removeMerge / clearMerges` — sparse,
  lazily-allocated merge list. Zero per-cell cost when unused.
- `MergeIndex` (`packages/ultimate_grid/lib/src/controller/merge_index.dart`)
  — derived occlusion structure built once per controller revision. Uses
  a `Uint32List` bitset (web-safe). `anchorAt(viewRow, flatCol)` and
  `isOccluded(viewRow, flatCol)` are the two lookups consumed by paint.
  Merges whose anchor or interior row/col is currently filtered out are
  silently dropped (the merge does not draw across non-adjacent view rows).
- `GridController.mergeIndex` derived getter; `_rebuildDerived` recomputes
  the index in the same single-pass step as column/row layout + view pipe.
- `Selection.extendActiveTo`, `Selection.addRange`, `Selection.activeRange`,
  `Selection.copyWith`, `SelectionRange.extendTo` — Excel-style helpers
  for shift-extend and cmd-add semantics.
- `GridController.selectCell / extendSelectionTo / addSelectionRange` —
  the typical UI affordances on top of `Selection`.
- `GridController.reorderRow(id, toIndex)` — programmatic row reorder
  (touches the underlying `MapGridDataSource`).
- `GridClipboard.selectionAsTsv(controller)` +
  `GridClipboard.copySelection(controller)` — serialize the current
  selection (or its bounding rectangle when non-contiguous) as TSV that
  round-trips with Excel / Numbers / Sheets. `Tab` and newline characters
  inside cells are sanitized.
- `UltimateResizableHeader` (`packages/ultimate_grid/lib/src/view/resizable_header.dart`)
  — drop-in replacement for `UltimateTableHeader` that ships a right-edge
  drag handle per column (`SystemMouseCursors.resizeColumn`) and exposes
  `onTapColumn` / `onLongPressColumn` for downstream sort / menu UIs.
- `UltimateTable` now wraps its body in `Shortcuts` + `Actions` for
  `Cmd/Ctrl+C` → copy-selection.
- `RenderUltimateBody` grows drag callbacks (`onDragStart`, `onDragUpdate`,
  `onDragEnd`) backed by a `PanGestureRecognizer`. Drag inside the body
  starts a selection at the press point and extends as the pointer moves.
- Render body consumes `MergeIndex`: skips occluded cells, expands anchor
  cells to span their merge in both axes during paint.

### Changed
- Body region `_BodyRegion` forwards new drag callbacks to `UltimateBody`.
- Shift-click extends the active selection range; Cmd/Ctrl-click pushes a
  new range (open-editor behavior preserved when no modifier is held).

### Tests (16 added — 50 total)
- `selection_test.dart` — `extendActiveTo`, `addRange`, whole-row sentinel,
  controller `selectCell` / `extendSelectionTo` / `addSelectionRange`.
- `merge_index_test.dart` — occlusion bitset correctness, empty-merges
  identity, anchor-filtered-out drop behavior, controller `mergeIndex`
  rebuilt on `addMerge`.
- `clipboard_test.dart` — single-cell TSV, rectangular TSV, empty
  selection, multi-range selection uses bounding box.
- `resizable_header_test.dart` — drag-to-resize widens a column; tap on
  the header body fires `onTapColumn` (vs. the drag handle).

## [Phase 5] — Header menu, filter / search UI, hide & resize-to-fit

The 9-region grid grows the user-facing UI that's been waiting on data-layer
plumbing: per-column popup menu, dedicated filter inputs, a pre-built
search field, and the ability to hide columns or resize them to fit
their widest visible value.

### Added
- `Filters` helpers (`packages/ultimate_grid/lib/src/filter_sort/filters.dart`)
  — `Filters.textContains`, `Filters.oneOf`, `Filters.numberRange`,
  `Filters.where`. Returned predicates plug straight into
  `controller.setFilter`.
- `SearchMode { highlight, filter }` — when `filter`, non-matching rows
  are dropped from the view (the bitset is unused). Default stays
  `highlight`. Toggle via `controller.setSearchMode`.
- `GridController.hideColumn / showColumn / hiddenColumns /
  isColumnHidden` — hidden ids are excluded from every region of
  `ColumnLayout` (which now accepts an `isHidden` predicate).
- `GridController.fitColumnToText` — caller-supplied measurement
  callback; the controller iterates the first N rows, takes the max
  width + padding, and writes it back via `setColumnWidth`. Returns the
  post-clamp width.
- `showUltimateColumnMenu(...)` — Material popup with sort asc/desc/off,
  pin left/right/none, hide, resize-to-fit, filter, clear-filter. Opens
  at the long-press / menu-button origin.
- `showUltimateFilterDialog(...)` — column-kind-appropriate filter input
  (text Contains for text/date, Min/Max for numbers); writes the chosen
  predicate back via `setFilter`.
- `UltimateSearchField` — drop-in search input bound to
  `controller.setSearchQuery` with an optional Highlight/Filter mode
  toggle.

### Changed
- `ViewPipeline.run` accepts `searchFiltersRows`; in that mode it drops
  non-matching rows and emits no bitset.
- `ColumnLayout.compute` accepts an `isHidden` predicate.
- The barrel exports `Filters`, `SearchMode`, `showUltimateColumnMenu`,
  `showUltimateFilterDialog`, `UltimateSearchField`.

### Tests (10 added — 60 total)
- `filters_test.dart` — `textContains` case-insensitive, `oneOf` matches
  integer-formatted `NumberCell`s, `numberRange` inclusive bounds,
  `hideColumn` / `showColumn` round-trip, search-filter-vs-highlight
  modes, `fitColumnToText` returns post-clamp width.
- `search_field_test.dart` — typing forwards to `setSearchQuery`; the
  Highlight/Filter button toggles `controller.searchMode`.

## [Phase 6] — Port the Mark 85 timesheet onto the package

The original `lib/widgets/grid_screen.dart` (and its companion
`lib/widgets/cells.dart`) is deleted; the timesheet now runs entirely
on top of `UltimateTable` via the new `lib/widgets/timesheet_grid.dart`.
`GridState` is kept as the undo/redo + derived-totals model and mirrored
into a `MapGridDataSource` on every change.

### Package: cell-widget overlay (the single new package feature in Phase 6)
- `UltimateTable.widgetColumns` + `UltimateTable.cellWidgetBuilder` —
  declare a set of columns whose body cells should render via a widget
  overlay instead of the cached-paragraph fast path. The
  `RenderUltimateBody` skips paint for the declared (rowId, colId) pairs
  (`suppressedColumns`); a Stack inside the body region mounts the
  builder's widget at each cell's rect.

### Host app
- `lib/widgets/timesheet_grid.dart` builds the schema:
  - Rows: `__header` (top-frozen, priority 0) → `__qty` (top-frozen,
    priority 1) → workers (scrollable) → `__totals` (bottom-frozen). The
    quantity strip and totals footer fall out of the freeze model "for
    free" — no special widget plumbing.
  - Columns: `__worker` (left-frozen, widget-rendered) → cost codes
    (scrollable, `CellKind.number`) → `__hours` → `__ot` (right-frozen,
    `CellKind.number`) → `__perdiem` (right-frozen, widget-rendered).
- `_HeaderAwareNumberRenderer` / `_HeaderAwareTextRenderer` /
  `_WorkerInfoRenderer` / `_PerDiemRenderer` are `CellRenderer`s that
  special-case the synthetic `__header` / `__qty` / `__totals` rows so
  they render header labels / QTY-band styling / totals styling.
- `_WorkerInfoTile` / `_PerDiemTile` are the widget-overlay bodies for
  the two interactive columns (worker absent toggle + remove button,
  per-diem check + amount). Mounted via `cellWidgetBuilder`.
- Body cells (hours per cost code, quantity row) edit via the package's
  built-in overlay editor; Enter commits → `_onCommit` routes the new
  number into `GridState.setCell` / `GridState.setQuantity`.
- Bottom toolbar gains an `Add crew` + `Add cost code` pair of buttons
  driven by the same modal pickers as before, and an aggregated
  "Grand hours / OT / Per diem" summary.

### Removed
- `lib/widgets/grid_screen.dart` (1,005 lines).
- `lib/widgets/cells.dart` (`HourInputCell`, `NumericCell`, `LabelText`,
  `cellBox`) — replaced by the package's renderers + overlay editor.
- `linked_scroll_controller` dependency from the host `pubspec.yaml` —
  no longer needed since the package's `SyncedScrollGroup` handles all
  cross-region scroll syncing.

### Tests (1 net added — 61 total; root app moved from 1 to 2)
- `test/widget_test.dart` updated: existing "renders headline columns"
  assertion still passes (now via the schema header row), plus a new
  case that asserts the first worker (`Martinez, Carlos`) renders
  through the widget overlay and that an initial cost code header
  appears via `ColumnSpec.header`.

## [Phase 7] — Keyboard nav, Semantics, scrollbar, benchmarks, contributor docs

Polish + accessibility pass. Adds the controller-side hooks for
keyboard navigation, the first Semantics envelope around the body
region, and a CI-friendly benchmark suite that catches gross
regressions in controller-build / sort / filter / paragraph cache.

### Added
- Keyboard navigation via `Shortcuts` / `Actions` on the table:
  arrow keys (move selection), Shift+arrow (extend the active range),
  Home / End (row start / end), PageUp / PageDown (jump ±10 rows). All
  routed through `GridController.selectCell` /
  `GridController.extendSelectionTo` so the same paths used by
  drag-select are exercised.
- `Semantics(label: 'Data grid', value: '${rows} rows, ${cols} columns',
  container: true)` wraps the table so screen readers see a single
  named region. `RenderUltimateBody.describeSemanticsConfiguration`
  adds a body-region descriptor with explicit `TextDirection.ltr`.
- Body region wraps its vertical `SingleChildScrollView` in a
  `RawScrollbar` (6 px thumb, rounded). Visible on hover/scroll without
  pulling in `material`.
- `packages/ultimate_grid/test/benchmark_test.dart` — headless
  benchmark scenarios: build a 10k × 20 controller + run a full
  filter/sort/search cycle; hot-loop the paragraph cache with 100
  distinct strings × 1000 lookups. Loose timing ceilings (×5 the
  observed dev-box numbers) so CI doesn't flake.

### Docs (new for the open-source release)
- `docs/ARCHITECTURE.md` — module map, data flow, frame-paint walk,
  perf rules, recipes for adding new cell kinds / interactions / sort
  filters, dependency rationale, where-to-start reading list.
- `CONTRIBUTING.md` — pull-request checklist, commit conventions
  (one commit per phase), code style, web-compat checklist.
- Root `README.md` links both new docs and the per-phase CHANGELOG.

### Tests (3 added — 64 total)
- `keyboard_nav_test.dart` — arrows move the selection; Shift+arrow
  extends the active range without collapsing it; Home / End jump to
  row edges.
- `benchmark_test.dart` (2 cases) — controller build + pipeline timing
  on 10k × 20 source; ParagraphCache lookup loop.

### Deferred (explicitly out of Phase 7 scope)
- Full RTL support. Sentinel pieces (textDirection on Semantics) are
  in place; column layout still assumes LTR for left/right freeze
  semantics. Documented in `docs/ARCHITECTURE.md`.
- `Semantics` per cell. The current envelope is region-level; per-cell
  semantics would need a custom `SemanticsConfiguration` graph in the
  render object and is a meaningful chunk of work — flagged for a
  future phase.

## [Phase 8] — Async data source, drag-to-reorder, selection helpers, feature showcase

User feedback after manual testing surfaced that the package's features
were not actually exercised by either demo, and that two patterns
needed explicit support: async / paginated data, and a richer
spreadsheet showcase (merged cells + multi-axis selection + mobile).

### Added — package
- `AsyncGridDataSource` (`packages/ultimate_grid/lib/src/source/async_grid_data_source.dart`)
  — caller provides a `Future<AsyncPage> fetchRange(start, end)`
  callback and a `pageSize`. When the grid asks for a cell whose page
  hasn't loaded yet, the source returns a loading placeholder
  (`TextCell('…')` by default), kicks off the fetch, and bumps
  `revision` when the page arrives — no pagination UI needed. Includes
  `prefetchRow(rowIndex)` and `invalidate({page:})`.
- `UltimateResizableHeader.reorderable` — long-press + horizontal drag
  rearranges columns. Opt-in (default false). Uses `LongPressDraggable`
  + `DragTarget`; the resize handle still wins quick horizontal drags.
- `GridController.selectRow`, `selectColumn`, `selectAll` — sugar over
  `Selection` for "click on row number" / "click on column letter" /
  Cmd+A semantics.

### Added — example app
- `lib/demo_showcase.dart` — one Material app, two tabs:
  - **Datagrid** tab: 200-row inventory dataset, full feature wiring
    (search field, filter mode toggle, column popup menu via
    `showUltimateColumnMenu`, drag-to-resize, drag-to-reorder via
    `UltimateResizableHeader`, body drag-select, Cmd/Ctrl+C copy with
    a status-bar preview of what was copied, async / sync toggle that
    swaps the source between `MapGridDataSource` and
    `AsyncGridDataSource` with a mock 600 ms delay, "Show hidden"
    button surfaces hideColumn output).
  - **Spreadsheet** tab: 4 quarters × 3 months columns + 5 regions
    with two top-frozen header rows that contain merged-cell quarter
    labels (`MergeRange(anchorRow: __quarter, anchorCol: 'jan',
    colSpan: 3)` × 4). Plus a bottom-frozen TOTAL row. Per-row /
    per-column / select-all buttons exercise the new selection
    helpers.
  - Mobile-width preview switch on the AppBar clamps the layout to
    400 px so the responsiveness story is testable from desktop.
- `lib/main.dart` is unchanged — the new entry point is launched with
  `flutter run -t lib/demo_showcase.dart`.

### Tests (6 added — 70 total)
- `async_grid_data_source_test.dart` — placeholder before fetch, real
  cells after, no duplicate fetches per page, `prefetchRow` exercises
  the page without a `valueAt` side-effect, `invalidate(page:)`
  re-fetches.
- Same file — `selectRow` / `selectColumn` / `selectAll` correctness
  via sentinel ranges.

### Notes
- `reorderable: true` makes a `LongPressDraggable` wrap each header
  cell; in a test harness this can subtract some pixels from a quick
  horizontal drag's measured distance via gesture-arena contention.
  The package's existing resize tests therefore use the default
  (`reorderable: false`); the showcase opts in.

## [Phase 9] — Interaction polish from first round of manual testing

User feedback after running the Phase-8 showcase surfaced several UX
issues that needed addressing before this is something an open-source
audience would actually use:

> "the selection still looks like a textinput, and the cell borders for
> selection is not showing up, i think for text based cell double click
> is better option … resizing the header column works for anything
> below that, but not for that … in first image when i click the 3
> button menu of column the menu list should come below that 3 button
> right as an overlay, and it also looks super ugly. … last column when
> freezed is right aligned but not the header … mobile width is super
> ugly … lots of overflows!"

### Changed — package
- **Single-tap selects; double-tap edits.** The body tap recognizer no
  longer opens the overlay editor on the first tap; it sets the cell
  selection + focus instead. A second tap within ~300 ms × ~20 px is
  treated as a double-tap and opens the editor. Bool cells continue to
  toggle on single tap. Manual double-tap detection (in
  `RenderUltimateBody._handleTapUp`) avoids the gesture-arena
  contention that comes with `DoubleTapGestureRecognizer` + `Tap` +
  `Pan` recognizers on the same target.
- **Focus border is now 2 px** with a 1-px inner deflate so a selected
  cell is unambiguous even without a fill.
- **`UltimateTable.autofocus: bool` (default false)** so keyboard
  navigation can be live immediately on "spreadsheet-first" screens
  (and so tests can request focus without having to tap first).
- **`UltimateResizableHeader` rebuilds on controller revision**
  (`controller.addListener` in `initState`), so dragging the right
  edge of a header now resizes both the header cell and every body
  cell below it in lockstep.
- **`onTapColumn` / `onLongPressColumn` callbacks now receive the
  header cell's `BuildContext`** (`(BuildContext, ColId)`), so
  `showUltimateColumnMenu` anchors below the cell that was clicked
  rather than the screen origin.
- **Column popup menu restyled** — icon + label rows, 36 px tall, 8 px
  rounded border, white background, 8-px elevation. Active states tint
  the icon + label in the theme's primary orange and show a check
  mark. The clear-filter action is tinted red.
- **Whole-column selection highlights the frozen-row header cells**
  too. `_CellsRow` now detects when the selection has a
  `isWholeColumn` range and applies the selection fill even on
  rowIndex=-1 (frozen) cells, so spreadsheet-style "click on column"
  feedback is consistent across the header / qty / totals strips.

### Changed — showcase demo
- All toolbars and status bars use `Wrap` (with `runSpacing`) instead of
  unbounded `Row`s, so they reflow cleanly on narrow viewports
  (`Mobile` switch on the app bar clamps to 400 px wide).
- Datagrid header uses `_HeaderLabel` with right-aligned text +
  trailing sort/filter/kebab icons for number columns.
- Spreadsheet's row / column / all / clear buttons are now a single
  `Wrap`.

### Bug fix
- Middle-slice `_BodyRegion` was missing `onDoubleTap`,
  `onDragStart`, `onDragUpdate`, `widgetColumns`, and
  `cellWidgetBuilder` — only the left and right slices got the new
  parameters in Phase 6 / 8. Fixed; double-tap to edit and widget
  overlays now work in the middle (scrollable) region too.

### Tests (1 added — 71 total)
- `ultimate_grid_widget_test.dart` — split the single-cell-tap test
  into a "single-tap selects + focuses" assertion and a separate
  "double-tap opens editor" assertion. Bool-toggle test bumped past
  the double-tap timeout. Keyboard nav tests use
  `UltimateTable(autofocus: true)` instead of manual focus juggling.

## [Phase 10] — Critical bugfixes from second-round manual testing

After running the Phase-9 showcase the user reported four real bugs:
the single-tap focus border never painted, the resizable header
overflowed the viewport (and could grow without bound + resize frozen
columns), the editor stayed "stuck" on a cell after clicking
elsewhere, and `_HeaderLabel` overflowed on narrow columns.

### Fixed
- **`RenderUltimateBody` now subscribes to the controller in
  `attach`.** The `controller` setter previously had
  `if (identical(_controller, v)) return;` which short-circuited the
  repaint when `selectCell()` mutated the *same* controller instance —
  the body never knew selection/focus had changed. Now the render
  object listens directly to `controller.notifyListeners` and calls
  `markNeedsPaint`. Single-tap focus border paints immediately.
- **Editor commits + closes on tap outside.** `_onBodyTap` checks if
  the editing cell differs from the hit cell and calls
  `_commitOrCancelEditor(commit: true)` first. Clicking a different
  cell no longer leaves the editor stuck open on the previous cell.

### Added — package
- **`UltimateTable.headerBuilder`** + `headerHeight` + `onHeaderTap` +
  `resizableHeader` + `headerMinWidth` + `headerMaxWidth`. When
  `headerBuilder` is non-null the table mounts an internal header
  strip that uses the **same 3-region freeze layout as the body**:
  left-frozen columns stay pinned left, middle columns h-scroll in
  sync with the body (via a new `_hHead` controller joined to the
  table's horizontal `SyncedScrollGroup`), right-frozen columns stay
  pinned right. Kills the flat-`Row`-overflow problem that the
  standalone `UltimateTableHeader` / `UltimateResizableHeader` widgets
  had when total column width exceeded the viewport.
- **`_HeaderStrip`** — internal widget that renders one column slice
  of the header. Each cell uses `Builder` so its `BuildContext` is
  the cell's own context (so `showUltimateColumnMenu(context:
  cellCtx, …)` anchors correctly). Cells in the middle slice show a
  drag-resize handle on the right edge; frozen-slice cells do not.
  Resize is clamped between `headerMinWidth` and `headerMaxWidth`
  (defaults 40 / 600 px).

### Changed
- `UltimateResizableHeader` — frozen columns no longer show the
  resize handle; resize is clamped to `minWidth..maxWidth` (defaults
  40 / 600 px instead of the previous hard-coded 2000 px ceiling).
- Showcase demo's Datagrid tab uses `UltimateTable.headerBuilder` +
  `onHeaderTap` instead of the standalone `UltimateResizableHeader`,
  so the header scrolls horizontally in sync with the body and a wide
  table no longer overflows on desktop OR mobile-width preview.
- `_HeaderLabel` row uses `Expanded(child: ellipsisLabel)` +
  shrunk-down icons (13 px) so the kebab + sort icon never push the
  label off the cell on narrow columns.

### Tests (2 added — 73 total)
- `embedded_header_test.dart` — total column width far exceeds the
  viewport; `headerBuilder` mounts a synced header without any
  `RenderFlex` overflow exception. Dragging the right edge of a
  middle-slice header cell updates `controller.widthOf`.

## [Phase 11] — Editor polish

### Fixed
- **Select-all on edit-open.** `_UltimateCellEditorState` previously
  set `_ctrl.selection = TextSelection(0, length)` inside its
  post-frame callback, *before* `EditableText`'s own focus handler
  restored its caret to the end of the text. Net effect: user had to
  manually clear the field. Fix: subscribe to `FocusNode` changes;
  when focus is gained, defer one more frame (so `EditableText`'s
  caret-restore runs first) then overwrite with the select-all
  selection. Double-tapping a cell now highlights the existing value;
  typing replaces it.
- **Cell borders no longer disappear during edit.** The editor used
  to wrap its child in `Container(color: theme.background)`, which
  painted an opaque white rectangle over the body's grid-line strokes
  (the right + bottom borders are drawn 0.5 px inside the cell rect
  so a solid fill covers them). Fix: replace the `Container` with a
  bare `Padding`. The body already paints the cell's white fill +
  grid lines underneath; the editor only needs to draw text + cursor
  + selection on top.
- **Selection highlight inside the editor uses the theme orange**
  (`Color(0x33EA580C)`) so a multi-character selection is visible
  against the white cell fill.

### Docs
- Package README: documented that "drag to highlight text inside a
  cell" is intentionally not supported in the fast-paint body, and
  pointed users at Cmd/Ctrl+C for cell-level TSV copy + double-tap
  for in-editor text selection.

## [Phase 12] — Right-frozen attachment, one scrollbar instead of three

### Fixed
- **Right-frozen column no longer sits with a big empty gap before
  it.** When the table is narrower than the viewport, the previous
  layout pinned the right-frozen column flush against the viewport
  edge (`middleW = viewportWidth - leftW - rightW`), leaving empty
  space between the last middle column and the right-frozen strip.
  Fix: clamp `middleW` to `min(naturalMiddleWidth, available)`. When
  the table fits, all three regions sit shoulder-to-shoulder; the
  empty space goes past the right-frozen column (the table is left-
  aligned in its container, matching Excel's behavior).
- **One vertical scrollbar instead of three.** The body's three
  slices (left-frozen, middle, right-frozen) each wrapped their
  vertical `SingleChildScrollView` in a `RawScrollbar`. Their
  vController positions are synced via `SyncedScrollGroup`, so every
  scroll tick lit up three thumbs simultaneously. Fix: added
  `_BodyRegion.showVerticalScrollbar` (default false); the middle
  slice opts in, the frozen slices don't. Net visual: a single
  scrollbar at the right edge of the middle region.

## [Phase 13] — Single scrollbar (vertical + horizontal) with margin, no shadows

User found that Phase-12's "one scrollbar" still painted three thumbs
on every scroll tick. Root cause was the framework default — Material's
`ScrollBehavior` wraps every `SingleChildScrollView` in a Scrollbar
automatically on desktop / web, so removing our explicit `RawScrollbar`
on the frozen slices wasn't enough; Flutter was still mounting two
more for us. The three thumbs landed on top of each other at the
slice boundaries (the "shadow" the user saw).

### Added
- **`UltimateTable.showVerticalScrollbar`** (default `true`),
  **`UltimateTable.showHorizontalScrollbar`** (default `true`),
  **`UltimateTable.scrollbarPadding`** (default 3 px). Callers can
  toggle either bar off, or widen the inset so the thumb sits further
  inside the table.

### Fixed
- **Framework-default scrollbars suppressed on every body slice.**
  Each body slice's `SingleChildScrollView` now sits inside a
  `ScrollConfiguration(behavior: …copyWith(scrollbars: false), …)`,
  so Material's `ScrollBehavior` no longer mounts an automatic
  Scrollbar for it. Combined with `_BodyRegion.showVerticalScrollbar`
  being opt-in, the net effect is exactly one vertical thumb (on the
  middle slice).
- **One horizontal scrollbar** wraps the middle slice's horizontal
  `SingleChildScrollView` via a new `_wrapHorizontalScrollbar`
  helper. Suppressed elsewhere via the same `ScrollConfiguration`.
- **Scrollbar inset from cell content.** Vertical bar:
  `EdgeInsets.only(right: scrollbarPadding)`. Horizontal bar:
  `EdgeInsets.only(bottom: scrollbarPadding)`. So the thumb sits
  inside the table without overlapping the rightmost / bottommost
  cell text.

## [Phase 14] — Scrollbars sit at the outer edges of the table

User feedback: "scroll bar should come at the right most column and
not the any other column". Phase 13 mounted the vertical scrollbar
on the *middle* body slice, so it appeared at the right edge of the
middle slice — to the left of the right-frozen column. The user
expects it past the right-frozen column, at the absolute right edge
of the table (Excel / Sheets behaviour).

### Changed
- **Vertical scrollbar moved to the right-frozen body slice** when
  one exists; falls back to the middle slice when there is no
  right-frozen column. The three vertical scroll controllers are
  already synced via `SyncedScrollGroup`, so the thumb at the right
  slice represents the full body's scroll position.
- **Horizontal scrollbar moved to the bottom-frozen row strip**
  when one exists; falls back to the middle row when there is no
  bottom-frozen row. The bottom strip's framework-default scrollbar
  is suppressed via the same `ScrollConfiguration` override used
  elsewhere.

## [Phase 15] — Scrollbar gutters: scrollbar sits *outside* the table content

User: "how do i place the scroll bar outside of the table without
it overlapping with last column cell". Phase 14 mounted the
scrollbar inside the right-frozen body slice with a 3 px inset, so
it still painted on top of the rightmost cell's right padding. The
expected behaviour is a dedicated gutter strip outside the table,
like Excel's scrollbar gutter.

### Added
- **`UltimateTable.scrollbarGutter`** (default `12` px). When `> 0`
  the table reserves a fixed-width column to the right of every
  region (header / top-frozen / body / bottom-frozen) for the
  vertical scrollbar, and a fixed-height row below them for the
  horizontal scrollbar. Cell content never shares pixels with the
  scrollbar. When `0`, scrollbars fall back to the Phase-14 inline
  overlay behaviour.
- Two new sync-group controllers `_vBar` / `_hBar` (joined to the
  same `SyncedScrollGroup`s as the body's scroll controllers). Each
  gutter hosts a dummy `SingleChildScrollView` with content sized to
  `rows.middleHeight` / `cols.middleWidth`; `RawScrollbar` wraps the
  dummy. Dragging the thumb scrolls the body; scrolling the body
  moves the thumb.

### Changed
- `_buildTable` is now a `Column([SizedBox([Row(table + vertical
  gutter)]), horizontal gutter])`. The legacy inline scrollbar
  wrappings on the right-frozen body slice and the bottom-frozen
  middle strip stay in place but are gated behind
  `widget.scrollbarGutter == 0` so the two paths don't both mount a
  thumb.

## [Phase 16] — Column-header popup feels like a regular Material menu

User: "why doesn't the overlay feel as smooth as a regular popup?"
The column menu was a cramped, custom-styled `showMenu`: items at
height 36 (below `kMinInteractiveDimension`), tiny 4 px dividers, a
manual orange border on the `RoundedRectangleBorder`, and a hand-
rolled "active" check icon next to the label. Net effect: it looked
right but the touch target + spacing + theming didn't match what a
user expects from a Material popup.

### Changed
- `_row` simplified: removed `height: 36` and `padding: 12` overrides;
  items now use Material defaults (`kMinInteractiveDimension = 48`).
  Icon bumped to 18 px, label to 14 px. Layout is a simple
  `Row(Icon, SizedBox(width:12), Expanded(Text), Icon(check)?)` —
  closer to a stock `ListTile`.
- `PopupMenuDivider`s use the default height (16 px) instead of 4 px,
  giving the sections proper visual separation.
- `showMenu` no longer overrides `elevation` / `color` / `shape` —
  the active `PopupMenuTheme` from the app theme wins. Apps with a
  dark theme / custom radius will see the menu inherit it.
- Anchor rect computed via `RelativeRect.fromRect` from the cell's
  global rect (instead of a hand-built `LTRB` with collapsed bottom),
  so the menu animation lands smoothly under the tapped header cell
  with the same shape `PopupMenuButton` uses internally.

## [Phase 17] — Unified example app + 5 M-row stress test

User feedback: scattered entry points (`lib/main.dart`,
`lib/demo_ultimate.dart`, `lib/demo_showcase.dart`) made the demos
hard to find and to compare. Plus we never proved the scaling story
beyond the 10 k × 20 benchmark.

### Added — example app
- **`SyntheticGridDataSource`** (`lib/examples/synthetic_data_source.dart`)
  — `GridDataSource` that synthesises cell values on demand from the
  row index. Lets the stress test host 5 M rows without materialising
  any cells (only the row-ID list).
- **`StressTestExample`** (`lib/examples/stress_test_example.dart`)
  — dropdown picks 10 k / 100 k / 1 M / 5 M rows. Reports the
  controller build time. The visible window is always ~30 rows (canvas
  paint) so scroll smoothness is independent of total row count.
- **`InventoryExample`** (`lib/examples/inventory_example.dart`)
  — the minimum-viable shape from the old `demo_ultimate.dart`.
- **`DatagridExample`** (`lib/examples/datagrid_example.dart`)
  — extracted from the showcase's Datagrid tab: search, full column
  menu, drag-resize, drag-reorder, multi-range body select, Cmd+C
  copy, async / sync toggle.
- **`SpreadsheetExample`** (`lib/examples/spreadsheet_example.dart`)
  — extracted from the showcase's Spreadsheet tab: 5 regions × 12
  months with merged-cell Q1–Q4 header groups + bottom-frozen TOTAL
  row.
- **`TimesheetExample`** — wraps the existing Mark 85 `TimesheetGrid`.
- **`lib/examples/shared.dart`** — `HelpBanner` and `HeaderLabel`
  helpers reused across examples.
- **`lib/examples/examples.dart`** — list of `ExampleEntry` records
  (label, subtitle, icon, builder) the shell iterates.

### Added — unified shell (`lib/main.dart`)
- **Side-nav with collapsible drawer for narrow viewports.** Above
  760 px the shell shows a 240-px sidebar with the example list +
  icon + subtitle for each entry. Below 760 px the sidebar collapses
  into a `Drawer` accessible from the app bar.
- Selecting an example swaps the content via a `KeyedSubtree(key:
  ValueKey(selected))` so each example mounts cleanly.

### Removed
- `lib/demo_ultimate.dart` (folded into Inventory example).
- `lib/demo_showcase.dart` (folded into Datagrid + Spreadsheet
  examples; the mobile-width preview switch lives in the OS resize
  / browser dev tools now).

### Tests
- `test/widget_test.dart` updated: asserts the unified app shows the
  sidebar with every example label on desktop; asserts the timesheet
  example (mounted directly) still renders headline columns + initial
  crew via the widget overlay.

73 package tests + 2 root tests pass.

## [Phase 19] — In-app source viewer, USAGE guide, origin story

User asked for two things — an in-app way to see the exact source
backing each example, and a README that explains *why* this package
exists.

### Added — example app
- **`SourceViewer`** (`lib/examples/source_viewer.dart`) — full-screen
  dialog that loads a `.dart` file from `rootBundle`, renders it with
  line numbers in a monospaced, selectable view, and offers a "Copy
  all" button.
- **`_ExampleTopBar`** in the shell — thin strip above each example
  showing its icon + label + subtitle + "View source" action.
- Example `.dart` files are now declared as Flutter assets in
  `pubspec.yaml` so the viewer can load them at runtime via
  `DefaultAssetBundle.loadString`.
- `ExampleEntry.sourceAsset` — the asset path each sidebar entry
  points at.

### Added — docs
- **`docs/USAGE.md`** — long-form usage guide. Covers the five core
  types (`GridSchema`, `GridDataSource`, `GridController`,
  `CellValue`, `UltimateTable`), the 9-region freeze layout, fast-
  path vs widget-overlay rendering, theming, sorting / filtering /
  search, selection, editing, cell merges, async data, performance
  tips, and a cheat-sheet of common questions. Audience: a Flutter
  developer with sheet-shaped data who wants to render it without
  writing a custom RenderObject.

### Changed — root README
- Added a "Why this exists" section with the origin story — building
  a tablet timesheet for a construction company during 2017–2020,
  the messy multi-stack maintenance, hoping for a real Flutter grid
  ecosystem, finally finishing the package with AI-assisted
  overhauls. Kept honest, no marketing tone.
- Added a "Docs" section that points at `USAGE.md`, `ARCHITECTURE.md`,
  `CHANGELOG.md`, and `CONTRIBUTING.md` so newcomers know where to
  go for each kind of question.

### Build hygiene
- `analysis_options.yaml` excludes `build/**` — Flutter's build
  pipeline copies the asset `.dart` files into
  `build/unit_test_assets/`, where their relative imports stop
  resolving and the analyzer would otherwise flag them as broken.

73 package tests + 2 root tests pass.

## [Phase 18] — Budget tracker example

The Mark 85 timesheet is the package's original use-case but the
construction-billing context is niche. Added a more relatable
example — a personal monthly budget tracker — and made it the
default landing example so visitors see something they recognise.

### Added
- **`BudgetExample`** (`lib/examples/budget_example.dart`) — 14
  expense categories × 12 months, frozen left (category + budget),
  frozen right (YTD spend + % used progress bar), 2 frozen top rows
  (merged Q1–Q4 quarter labels + month header strip), 1 frozen
  bottom (TOTAL row). Double-tap a monthly cell to edit; totals
  + % update on commit via a source listener.
- Custom `_CategoryCell` widget (icon chip + name) for the category
  column, and `_PercentBar` widget (LinearProgressIndicator with
  conditional colour + over-budget warning icon) for the % used
  column — exercised via `widgetColumns` + `cellWidgetBuilder`.
- Quarter merges via `MergeRange(anchorCol: months[q*3], colSpan: 3)`.
- Budget moved to the top of the sidebar.

### Tests
- `test/widget_test.dart` adds an assertion that the Budget label
  appears in the sidebar (loosened to `findsAtLeast(1)` since the
  active example also has a "Budget" column header).

73 package tests + 2 root tests pass.

## [Phase 20] — Publish prep + audit-pass bug fixes

The package was feature-complete after Phase 19 but had never been
through a publish-prep pass. Three real bugs surfaced during the
audit and got folded into this phase.

### Fixed — `packages/ultimate_grid/`
- **`headerH` type mismatch** in `view/ultimate_grid.dart`. The
  conditional yielded `int` when no header was set and `double` when
  one was, leaving the result as `num` which then mixed badly with
  the layout arithmetic. Tightened to an explicit `double`.
- **`AsyncGridDataSource` dispose race.** When the user toggled
  sync ↔ async in the Datagrid demo, an in-flight page fetch could
  resolve after the source was disposed, triggering
  `FlutterError: AsyncGridDataSource was used after being disposed`
  from the `notifyListeners()` assert. Added a `_disposed` flag,
  overrode `dispose()` to set it, and gated `_bump()` plus both the
  `.then` and `.catchError` paths in `_kickFetch` on it.
- **Editor losing typed text on click-outside.** The in-cell editor
  owned its own `TextEditingController`, so when the user clicked a
  different cell (or anywhere outside the editor's region) the
  editor was torn down before the parent could read the live text —
  only the Enter-key path saved. Hoisted the controller + focus node
  to `_UltimateTableState`, made `UltimateCellEditor` a
  `StatelessWidget` that takes them externally, and wired a
  focus-loss listener that commits whatever text is currently in
  the buffer.

### Added — publish prep
- **`LICENSE`** under `packages/ultimate_grid/` — MIT.
- **`CHANGELOG.md`** under `packages/ultimate_grid/` — package-
  level history (separate from this repo-level changelog).
- **`example/`** under `packages/ultimate_grid/` — minimal
  60-row inventory grid that pub.dev surfaces as the runnable
  example for the package page.
- **`pubspec.yaml`** under `packages/ultimate_grid/` —
  description tightened, `publish_to: 'none'` removed,
  `topics:` added (`grid`, `table`, `datagrid`, `spreadsheet`,
  `timesheet`). `homepage` / `repository` / `issue_tracker` are
  stubbed as TODOs pending the real URLs.

### Verification
- `flutter analyze` — clean.
- 73 package tests + 2 root tests pass.
- `flutter pub publish --dry-run` — 58 KB archive, 0 errors,
  2 deferred warnings (uncommitted changes; missing URLs).
