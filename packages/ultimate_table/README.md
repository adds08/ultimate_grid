# Ultimate Table by CodeBigya

A scalable, themable 2D data-grid package for Flutter — a free, open-source
alternative aimed at being more capable than `pluto_grid` and more ergonomic
than the built-in `TwoDimensional` widgets, while scaling to millions of
cells without jitter on low-end devices.

> **Status:** in active development. The public API surface is stable for
> Phase 3 (headless model + 9-region grid + custom `RenderObject` body).

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
import 'package:ultimate_table/ultimate_table.dart';

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

For a fuller example see `lib/demo_ultimate.dart` in the host repo (mock
inventory grid with sort, search, and freeze toggles).

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
