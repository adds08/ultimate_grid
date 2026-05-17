# Ultimate Grid

A scalable, themable 2D data-grid package for Flutter — a free, open-source
alternative aimed at being more capable than `pluto_grid` and more ergonomic
than the built-in `TwoDimensional` widgets, while scaling to millions of
cells without jitter on low-end devices.

> **Status:** in active development. The public API surface is stable for
> Phase 3 (headless model + 9-region grid + custom `RenderObject` body).

## Why this exists

Around 2017–2020, I was a one-person stack working on a tablet app for a
construction company. The headline screen was a timesheet — crews on one
axis, cost codes on the other, hours in the middle, with phases and
projects layered behind them in a relational backend. It was the most
complex piece of UI I had built up to that point: cell mapping across
schemas, multi-cell selection, multi-value entry, a custom on-screen
keyboard, and the kind of state churn where every edit had to ripple into
totals on the right and a quantity-to-claim band on the top. I was
learning state management mid-flight; the code ended up a fan-out of
providers and a backend that nested deeper than I'd like to admit. On the
web side the same dataset was shown through a jQuery-driven
`bootstrap-table` library, with PHP, SQL, CSS, the Flutter app, and the
servers all sitting in the same week's todo list.

I shipped it. It worked. It was also a stark reminder that Flutter, at
the time, had no real grid ecosystem. `table_sticky_headers` covered the
basic sticky-header case but wasn't flexible enough for where the
timesheet was heading. When `TwoDimensional` arrived in the Flutter SDK
a couple of years later I was hopeful — but it landed as a low-level
building block, not a feature-grade grid, and the gap between "drawable
viewport" and "actual datagrid" stayed wide.

Between contract gigs over the next few years I kept the unfinished grid
in a side folder. It was too unpolished to publish — there were always
five missing pieces — and I never had the focused stretch to finish them.
With AI-assisted overhauls over the last year, I was finally able to do
the surgery the package needed: replace the external table dependency
with the canvas-paint body it has today, keep the original mental model
(rows and columns are both data, edges freeze, totals derive), and
produce something I could share without embarrassment. The same time-log
shape that motivated this package — people on one axis, work items on
the other, hours per cell, frozen edges, derived totals — ships as the
**Office Time Log** demo in `example/` today, reframed for IT-industry
projects but hosted on the new engine.

> Five clients later, the same package now ships under multiple production
> apps. None of them are construction-shaped.

This is the artifact of that journey: the grid I wanted in 2018, written
through 2026, for everyone who's hit the same wall.

## What it does today (Phase 3)

- **Matrix-map data model.** `GridDataSource` with sparse cell storage and a
  lazy, sparse metadata side-channel that costs zero per-cell memory when
  unused.
- **Sealed `CellValue` types.** `Empty / Number / Text / Bool / Date / Formula
  / Custom`. Strongly typed; renderers pattern-match.
- **Per-cell behavior, explicit or by rule.** `InteractionPolicy<T>` with
  `MapPolicy` (per-cell map) and `PredicatePolicy` (e.g.
  `PredicatePolicy.evenCells(...)` — fires only on cells where both indices
  are even). Both shapes compose with `overriddenBy`.
- **9-region freeze layout.** Left-frozen / scrollable / right-frozen columns
  × top-frozen / scrollable / bottom-frozen rows. Non-contiguous freezes
  (e.g. freeze columns 1, 2, and 8 to the left) ordered by explicit pin
  priority. All cumulative offsets in `Float64List`; binary-search
  `firstVisibleMiddle`.
- **Single-pass derived state.** `GridController` rebuilds column layout,
  row layout, and the filter/sort/search pipeline once per revision —
  not once per frame.
- **Themable.** Default `GridTheme.mark85`. Per-column / per-row / per-cell
  style overrides flow through the same `InteractionPolicy` shape.
- **Pluggable cell renderers.** `CellRendererRegistry`: per-column override →
  per-`CellKind` default → fallback. Defaults ship for number, text, bool,
  date.
- **Custom-render body.** A single `RenderUltimateBody` per column slice
  paints visible cells directly via a cached `TextPainter` LRU — no widget
  tree per cell. Bool cells render a filled tickbox; number cells are right
  aligned with tabular figures. Tap opens a single overlay `TextField` for
  edit-in-place; Enter commits, Esc cancels.
- **Excel-style selection.** Drag inside the body to draw a rectangle;
  Shift-click extends; Cmd/Ctrl-click pushes a non-contiguous range.
  `Cmd/Ctrl+C` copies the bounding rectangle as TSV to the system clipboard
  (round-trips with Excel / Numbers / Sheets). This is the package's
  "web-like text copy" story — drag-to-highlight a substring inside a
  cell would need a widget tree per cell, so it's intentionally not
  supported in the body's fast paint path. Double-tap a cell to enter
  the editor, where the `TextField` itself supports full text
  selection / native context menu / copy.
- **Cell merges.** Declare a `MergeRange` on the data source; the body
  renderer skips occluded cells and expands the anchor to span the merge.
  Merges that get split by sort / filter are silently dropped that frame.
- **Drag-to-resize columns.** `UltimateResizableHeader` ships an 8-px
  right-edge handle per column with a `resizeColumn` mouse cursor.
- **Header menu + filter UI.** `showUltimateColumnMenu(...)` opens a
  Material popup with sort, pin, hide, resize-to-fit, filter actions;
  `showUltimateFilterDialog` ships type-appropriate inputs
  (Contains for text/date, Min/Max for numbers). `Filters.*` are
  pre-built predicates.
- **Search field.** `UltimateSearchField` is a drop-in input; toggle
  Highlight ↔ Filter mode to either mark matches or drop non-matches.
- **Widget cells for interactive columns.** Pass `widgetColumns` +
  `cellWidgetBuilder` to `UltimateTable` to render specific columns'
  body cells as widgets instead of fast paragraph paint — useful when a
  column needs checkboxes, buttons, or custom layouts. Other columns
  keep the fast path.

## Quick start

```dart
import 'package:ultimate_grid/ultimate_grid.dart';

final schema = GridSchema(
  columns: const [
    ColumnSpec(id: 'sku', header: 'SKU', defaultWidth: 110,
        defaultFrozen: FrozenSide.start),
    ColumnSpec(id: 'name', header: 'Product', defaultWidth: 220),
    ColumnSpec(id: 'price', header: 'Price', defaultWidth: 100,
        kind: CellKind.number),
  ],
  rows: [for (var i = 0; i < 100; i++) RowSpec(id: 'r$i')],
);

final source = MapGridDataSource(
  rowIds: [for (final r in schema.rows) r.id],
  colIds: [for (final c in schema.columns) c.id],
);
source.setValue('r0', 'sku',   const TextCell('SKU-0001'));
source.setValue('r0', 'name',  const TextCell('Widget A'));
source.setValue('r0', 'price', const NumberCell(19.99));

final controller = GridController(schema: schema, source: source);

// In your widget tree:
UltimateTable(controller: controller);
```

For a fuller gallery — financial sheet with merges, 100k-row async paging,
search & filter UI, theme switcher with three presets, office time log,
budget tracker, datagrid, spreadsheet, and a 5 M-row stress test — see the
`example/` directory.

## Constraints

- **Flutter web:** uses `Uint32List` for bitsets (JavaScript has no native
  64-bit ints, so `Uint64List` isn't supported on web). Anything you add
  internally must follow the same rule.
- **No widget tree per cell in the body region.** Body cells are painted
  directly by `RenderUltimateBody` via a paragraph LRU cache. The public
  widget API is unchanged; the body region simply hosts a single
  render-object widget per column slice plus one overlay editor widget.

## Architecture map

```
src/
├── model/         CellValue, CellAddress, ColumnSpec, RowSpec, GridSchema, FrozenSide
├── source/        GridDataSource (abstract) + MapGridDataSource
├── interaction/   InteractionPolicy: MapPolicy, PredicatePolicy, composition
├── controller/    Selection, ColumnLayout, RowLayout, GridController
├── filter_sort/   ViewPipeline (filter → sort → search; one pass)
├── theme/         GridTheme, ColumnStyle, RowStyle, CellStyle
├── cells/         CellRenderer + registry; default Number/Text/Bool/Date renderers
└── view/          SyncedScrollGroup, UltimateTable, UltimateTableHeader
```

## License

MIT — see [LICENSE](LICENSE).
