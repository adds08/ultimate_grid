# Concepts

Ultimate Grid splits a grid into four objects with sharp responsibilities.
Understanding the split is the key to everything else.

## The four objects

```dart
final schema = GridSchema(columns: [...], rows: [...]); // shape
final source = MapGridDataSource(rowIds: [...], colIds: [...]); // values
final controller = GridController(schema: schema, source: source); // view state
UltimateTable(controller: controller); // the view
```

| Object | Owns | Mutated via |
|---|---|---|
| `GridSchema` | The static shape: which columns and rows exist, their declared order, and per-column/row defaults (width, freeze, `CellKind`). Immutable. | Build a new one if the structural shape changes. |
| `GridDataSource` | The cell **values** (and optional sparse metadata + merges). | `source.setValue(rowId, colId, value)` on `MapGridDataSource`; pages on `AsyncGridDataSource`. |
| `GridController` | **Derived view state**: column order / width / freeze, row height / freeze, sort keys, filters, search query + mode, selection, focus. | `controller.setColumnWidth(...)`, `setSortKeys(...)`, `setFilter(...)`, `setSelection(...)`, etc. |
| `UltimateTable` | The **view** — the widget that paints the 9 regions, handles gestures, and hosts the in-cell editor. | Constructor parameters + callbacks. |

### Why the split

- **Data mutations and view mutations are independent.** The source and the
  controller each bump their own monotonic `revision` counter. The controller
  listens on the source, so `source.setValue(...)` automatically rebuilds the
  controller's derived state in a single pass — but a column resize doesn't
  touch the data, and an edit doesn't rebuild the column layout.
- **Stable identity.** Rows and columns are addressed by `RowId` / `ColId`
  (both `typedef`s over `String`). Sort, filter, reorder, and freeze all
  rearrange *indices*, never the underlying cells — so a `MergeRange` or a
  cell value keyed by id survives any reordering.

### Derived state lives on the controller

The controller recomputes these on each relevant revision and exposes them
read-only:

- `controller.columnLayout` — `ColumnLayout` (left-frozen / middle / right-frozen
  partition + cumulative offsets).
- `controller.rowLayout` — `RowLayout` (top-frozen / middle / bottom-frozen).
- `controller.pipelineResult` — `ViewPipelineResult` (the visible row order +
  search-hit bitset; see [Sort / filter / search](sort-filter-search.md)).
- `controller.mergeIndex` — `MergeIndex` for the current view.

You rarely build these yourself; they back the renderer and the clipboard.

## The 9-region freeze layout

`UltimateTable` is a 3×3 grid of regions. Columns partition into three strips
and rows partition into three bands:

```
                 │ left-frozen cols │  scrollable cols  │ right-frozen cols
─────────────────┼──────────────────┼───────────────────┼──────────────────
 top-frozen rows │      region      │      region        │     region
─────────────────┼──────────────────┼───────────────────┼──────────────────
 scrollable rows │      region      │   THE BODY         │     region
─────────────────┼──────────────────┼───────────────────┼──────────────────
 bottom-frozen   │      region      │      region        │     region
 rows            │                  │                    │
```

- A **column** pins with `defaultFrozen: FrozenSide.start` (left) or
  `FrozenSide.end` (right). Unfrozen columns scroll horizontally in the middle.
- A **row** pins the same way: `FrozenSide.start` pins to the **top**,
  `FrozenSide.end` to the **bottom**. Unfrozen rows scroll vertically.
- Frozen strips can be **non-contiguous** ("freeze columns 1, 2, and 8 to the
  left"). Order within a strip is by `defaultFreezePriority` — lower values
  render closer to the outside edge. Ties keep declared/reorder order.
- **Frozen rows skip the filter / sort / search pipeline**, so a frozen header
  or totals row stays put regardless of the active view. Only the scrollable
  middle band is filtered and sorted.

The scrollable middle body is the only region painted by a custom
`RenderObject` (no widget tree per cell) — that is what lets the grid scale to
millions of rows. Frozen strips use widget cells, since they are few. See
[Performance](performance.md).

`FrozenSide` semantics: in RTL, `start` is the right edge and `end` the left —
but RTL layout is not yet fully shipped (see [STATUS.md](STATUS.md)).

## See also

- [Columns](columns.md) — applying freeze, priority, width to columns
- [Data sources](data-sources.md) — the `GridDataSource` contract
- [Performance](performance.md) — why only the middle body is canvas-painted
