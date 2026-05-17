# Ultimate Table — architecture & rendering pipeline

This doc explains how a frame is drawn, how state flows from `GridController`
into the render layer, and what each module owns. It's the "how it works"
companion to the public-API `README.md`. New contributors should read this
once before touching anything inside `packages/ultimate_grid/lib/src/`.

If you're looking for "how do I build a grid?" see
[`packages/ultimate_grid/README.md`](../packages/ultimate_grid/README.md).
If you're looking for "what changed in each release?" see
[`CHANGELOG.md`](../CHANGELOG.md).

---

## Module map

```
packages/ultimate_grid/lib/
├── ultimate_grid.dart                # public barrel — every type a caller
│                                      # touches is exported from here
└── src/
    ├── model/         CellValue, CellAddress, ColumnSpec, RowSpec,
    │                  GridSchema, FrozenSide, MergeRange
    ├── source/        GridDataSource (abstract) + MapGridDataSource
    │                  (reference in-memory implementation)
    ├── interaction/   InteractionPolicy: MapPolicy, PredicatePolicy,
    │                  composition. Powers per-cell style/tap/tooltip.
    ├── controller/    Selection, ColumnLayout, RowLayout, MergeIndex,
    │                  GridController, clipboard helpers
    ├── filter_sort/   ViewPipeline (filter → sort → search; one pass),
    │                  Filters helpers, SearchMode
    ├── theme/         GridTheme, ColumnStyle, RowStyle, CellStyle
    ├── cells/         CellRenderer interface + default Number/Text/
    │                  Bool/Date renderers
    └── view/          SyncedScrollGroup, ParagraphCache,
                       UltimateBody (LeafRenderObjectWidget) +
                       RenderUltimateBody (RenderBox),
                       UltimateTable + UltimateTableHeader,
                       UltimateResizableHeader, column_menu helpers,
                       UltimateSearchField
```

No `dart:io`, no `Uint64List` — both block Flutter web.

---

## Data flow

```
            user                        (taps, drags, types, shortcuts)
              │
              ▼
   ┌─────────────────────┐
   │  UltimateTable      │  builds a 3×3 region layout, owns the
   │  + body region      │  SyncedScrollGroup + the ParagraphCache
   └─────────┬───────────┘
             │ mutations: setColumnFreeze / setSortKeys / selectCell …
             ▼
   ┌─────────────────────┐
   │  GridController     │  owns view state. Listens to the data source.
   │                     │  On any change runs _rebuildDerived ONCE.
   └─────────┬───────────┘
             │ derived state, all immutable after build:
             │   columnLayout : ColumnLayout
             │   rowLayout    : RowLayout
             │   pipelineResult : ViewPipelineResult (filter→sort→search)
             │   mergeIndex   : MergeIndex
             ▼
   ┌─────────────────────┐
   │  RenderUltimateBody │  reads derived state on every paint().
   │                     │  No allocations beyond ParagraphCache misses.
   └─────────────────────┘
```

`GridController.addListener` fires once per mutation; `UltimateTable`
listens and calls `setState`, which re-runs `build()`. The derived state
has *already* been recomputed inside the controller — the build is pure
read.

`MapGridDataSource` has its own `revision` counter and its own listener
list. The controller subscribes to the source and bumps its own
`_rebuildDerived` whenever the source mutates.

### Single-pass derived state

The contract that makes scrolling on big grids cheap:

```dart
void _rebuildDerived() {                      // called at most ONCE per mutation
  _columnLayout = ColumnLayout.compute(…);    // 3-region partition + offsets
  _pipelineResult = ViewPipeline.run(…);      // filter → sort → search, one pass
  _rowLayout = RowLayout.compute(…);          // 3-region row partition + offsets
  _mergeIndex = source.merges.isEmpty
      ? MergeIndex.empty()
      : MergeIndex.compute(…);                // Uint32List occlusion bitset
}
```

Renderers consult these structures with O(log n) / O(1) lookups
(`firstVisibleMiddle` does a binary search on the cumulative-offset table).
There is no per-frame multi-pass layout work.

---

## How a frame is drawn

`UltimateTable.build()` returns a `Shortcuts` → `Actions` → `Semantics`
→ `Focus` → `LayoutBuilder` tree. Inside the `LayoutBuilder`:

```
┌── Column ──────────────────────────────────────────────────────────────┐
│ ┌── if topH > 0 ─────────────────────────────────────────────────────┐ │
│ │  _RegionTriple  (top-frozen rows × 3 column slices)                │ │  ← widgets,
│ │   left = _FrozenRowsBand   mid = h-scroll(_FrozenRowsBand)   right │ │     small row
│ │                                                                    │ │     count
│ └────────────────────────────────────────────────────────────────────┘ │
│ ┌── middle-h, body ─────────────────────────────────────────────────┐  │
│ │  _RegionTriple                                                     │  │
│ │    left  = _BodyRegion(leftFrozen)   ← RawScrollbar →             │  │
│ │             SingleChildScrollView(_vLeft) → Stack:                │  │
│ │               • UltimateBody (RenderUltimateBody — paragraph paint)│  │
│ │               • widget overlays per widgetColumn × visible row     │  │
│ │               • Positioned editor (when editing a cell here)       │  │
│ │    mid   = SingleChildScrollView(_hMid, horizontal)               │  │
│ │              → SizedBox(width: cols.middleWidth)                  │  │
│ │              → _BodyRegion(middle)                                │  │
│ │    right = _BodyRegion(rightFrozen)                               │  │
│ └────────────────────────────────────────────────────────────────────┘ │
│ ┌── if bottomH > 0 ──────────────────────────────────────────────────┐ │
│ │  bottom-frozen rows × 3 column slices                              │ │
│ └────────────────────────────────────────────────────────────────────┘ │
└────────────────────────────────────────────────────────────────────────┘
```

Two `SyncedScrollGroup`s wire the regions:

- **horizontal**: `_hTop`, `_hMid`, `_hBot` — top/mid/bot scroll together.
- **vertical**: `_vLeft`, `_vMid`, `_vRight` — left/mid/right scroll together.

The middle ones are the "driver"; the others jump-to-match without
re-entering the loop (`_suppress` guard in `SyncedScrollGroup`).

### Inside `RenderUltimateBody.paint`

```dart
final scrollY = vController.position.pixels;
final viewportH = vController.position.viewportDimension;
final firstRow = rowLayout.firstVisibleMiddle(scrollY);        // O(log rows)
final lastRow  = rowLayout.firstVisibleMiddle(scrollY + viewportH);
for (var rs = firstRow; rs <= lastRow; rs++) {
  for (var cs = 0; cs < columnIds.length; cs++) {              // slice cols only
    if (mergeIndex.isOccluded(viewIdx, flatColIdx)) continue;
    if (suppressedColumns.contains(colId)) continue;           // widget paints it
    // 1. fill background (one shared Paint)
    // 2. paint search-hit / selection overlays
    // 3. paint content via ParagraphCache.acquire(text, style, align, maxWidth)
    // 4. draw right + bottom grid lines (two drawLine calls)
    // 5. draw focus stroke if this is the focused cell
  }
}
```

No widget tree is built per cell in the body. One `Paint` is reused for
each role (`_backgroundPaint`, `_gridLinePaint`, `_selectionFillPaint`,
`_searchHitPaint`, `_focusStrokePaint`). The paragraph cache is a
bounded LRU keyed by `(text, style hash, align, maxWidth quantized to 0.25
px)`. Repeated values across rows reuse one laid-out `TextPainter`.

When a column is in `widgetColumns`, the render object skips that column
(`continue`) and the body region's `Stack` mounts a `Positioned` widget
over the cell rect via `cellWidgetBuilder`. The active editor uses the
same mechanism (one `Positioned.fromRect` at the editing cell).

---

## Memory + perf rules

These are baked into the design; please read them before refactoring.

| Rule | Reason |
|---|---|
| No `Uint64List` anywhere — use `Uint32List` (`>> 5` / `& 31` bit math). | Flutter web has no native 64-bit ints; `Uint64List` crashes on Chrome. |
| Per-cell behavior (style, tap, tooltip…) is an `InteractionPolicy<T>?` whose "off" state is `null`. Never allocate a per-cell object up front. | Targets millions-of-cells data sets. A `Map<CellAddress, …>` of size 0 is fine. A `List<…>` of size rowCount × colCount is not. |
| Body cells render via paragraph paint by default. Widget cells are opt-in via `widgetColumns` and only legitimate for columns that *need* a widget (checkboxes, custom layouts). | Widget-per-cell allocation is the single biggest cost in scrolling. |
| Derived state rebuilds at most once per source/view revision. Renderers read the precomputed structures. | Multi-pass per-frame layout work doesn't scale. |
| `Paint` / `Rect` / `TextPainter` are reused across cells in one paint. Allocations on the hot path are not OK. | Same. |

---

## How to add a feature — recipes

### A new public knob on the table (e.g. "row banding")

1. Add the state to `GridController` (`_rowBandingEnabled`) + a setter that
   calls `_bump()` (with `rebuildLayout: true` only if it affects layout —
   most cosmetics just need a notify).
2. Expose a getter.
3. Wire the renderer (likely `RenderUltimateBody.paint`) to consult it.
4. Add a test under `packages/ultimate_grid/test/` matching an existing
   shape (see `selection_test.dart` for controller-state tests).
5. Update the package barrel only if you exposed new types.

### A new cell kind (e.g. "image cell")

1. Add a new `final class ImageCell extends CellValue` with `raw`, `==`,
   `hashCode`, `toString` (look at `NumberCell` as the template).
2. Add `CellKind.image` to `ColumnSpec.CellKind`.
3. Add a default renderer in `cells/default_renderers.dart` and register
   it in `registerDefaultRenderers`.
4. Optionally: extend `RenderUltimateBody._paintCellContent` and
   `_textForCell` with the new kind so the fast path paints it natively.
   If you don't, callers can still use it via `widgetColumns`.

### A new sort/filter shape

Add a static helper to `Filters` (see `Filters.numberRange` as the model).
Filters are just `bool Function(CellValue)` — keep them stateless.

### A new interaction (e.g. "right-click context menu")

1. Add a callback parameter to `UltimateTable` (typed
   `void Function(BodyCellHit)`).
2. Plumb it through `_BodyRegion` → `UltimateBody` → `RenderUltimateBody`.
3. In the render object, attach a new gesture recognizer in the
   constructor (mirror `_tapRecognizer` / `_panRecognizer`). Dispose it
   in `detach()`.
4. Wire it in `handleEvent` (each recognizer gets `addPointer(event)` on
   `PointerDownEvent`).

---

## Phase-isolated commits — the contributor rule

Every release lands as **one commit per phase** with the `Phase N — title`
heading in the commit message + a corresponding `## [Phase N] — title`
section in `CHANGELOG.md`. Bug fixes for code introduced in phase N are
folded back into the phase N commit, never added as a "fix" commit on
top — so every phase commit, checked out alone, is a clean working state
(`flutter analyze && flutter test` both green).

If you spot a bug in earlier-phase code while building phase N+1: fix it,
then either (a) amend the in-progress phase commit, or (b) if the in-flight
phase is already pushed, ask reviewers whether to roll back and fold.

---

## Tests

`packages/ultimate_grid/test/` is split by feature:

- `grid_data_source_test.dart` — sparse cells + metadata, revision bump
- `grid_controller_test.dart` — initial layout, freeze, reorder, source
  mutation rebuild, selection
- `column_layout_test.dart` / `row_layout_test.dart` — partition,
  cumulative offsets, `firstVisibleMiddle` binary search
- `view_pipeline_test.dart` — filter / sort / search ordering
- `interaction_policy_test.dart` — `MapPolicy`, `PredicatePolicy.evenCells`,
  composition
- `merge_index_test.dart` — occlusion bitset, anchor lookup,
  filtered-out anchors drop silently
- `selection_test.dart` — `extendActiveTo`, `addRange`,
  controller selection helpers
- `clipboard_test.dart` — TSV serialisation incl. multi-range bbox
- `filters_test.dart` — `Filters.*`, `hideColumn`, `SearchMode.filter`,
  `fitColumnToText`
- `paragraph_cache_test.dart` — LRU identity + eviction
- `ultimate_grid_widget_test.dart` — body mounts, frozen-column
  partitioning, editor open, bool toggle
- `search_field_test.dart` — typing + mode toggle
- `resizable_header_test.dart` — drag widens column, tap fires callback
- `keyboard_nav_test.dart` — arrow / Home / End / shift-arrow
- `benchmark_test.dart` — 10k×20 controller build + pipeline cycle;
  paragraph cache hot loop. Loose timing ceilings; meant to flag 10×
  regressions, not to assert nanoseconds.

Run all with:

```bash
cd packages/ultimate_grid
flutter analyze && flutter test
```

`flutter analyze` must report **No issues found**; the suite must be all
green before any phase commit.

---

## Web compatibility checklist

Before merging anything that touches `lib/src/`:

- [ ] No `Uint64List`, `Int64List`. Use `Uint32List`/`Int32List`.
- [ ] No `dart:io`. Use `dart:typed_data`, `dart:ui`, `package:flutter/*`.
- [ ] No platform-channel calls in `lib/`.
- [ ] `flutter build web -t lib/demo_ultimate.dart --release` succeeds
      from the host app.

---

## Dependencies

### Package (`packages/ultimate_grid`)

| Package | Why we depend on it |
|---|---|
| `flutter` (SDK) | `dart:ui`, `RenderBox`, `Widgets`, gestures, services. |
| `meta` ^1.10.0 | `@immutable`, `@visibleForTesting` annotations only. |
| `flutter_test` (dev) | Test harness. |
| `flutter_lints` ^5.0.0 (dev) | Lints. |

Deliberate non-dependencies (kept out so the package stays small):

- **No `material` import inside `lib/src/`** — uses `widgets` only.
  `column_menu.dart` (which IS material — it uses `showMenu`,
  `AlertDialog`) is the documented exception; callers can ignore it.
- **No `linked_scroll_controller`** — replaced by the internal
  `SyncedScrollGroup`.
- **No `provider` / state-management lib** — the controller is a plain
  `ChangeNotifier`; callers wire it however they want.

### Host app (`pubspec.yaml`)

| Package | Why |
|---|---|
| `flutter` (SDK) | Material app shell, demo UI. |
| `cupertino_icons` ^1.0.8 | Icon set used by the timesheet toolbar. |
| `ultimate_grid` (path:) | The package under test. |

---

## Where to start reading the code

1. [`packages/ultimate_grid/lib/ultimate_grid.dart`](../packages/ultimate_grid/lib/ultimate_grid.dart)
   — the public surface.
2. [`packages/ultimate_grid/lib/src/controller/grid_controller.dart`](../packages/ultimate_grid/lib/src/controller/grid_controller.dart)
   — `_rebuildDerived` is the heart of the data flow.
3. [`packages/ultimate_grid/lib/src/view/ultimate_grid.dart`](../packages/ultimate_grid/lib/src/view/ultimate_grid.dart)
   — the `LayoutBuilder` that becomes the 3×3 region tree.
4. [`packages/ultimate_grid/lib/src/view/render_body.dart`](../packages/ultimate_grid/lib/src/view/render_body.dart)
   — the custom render object that paints body cells.
5. [`lib/widgets/timesheet_grid.dart`](../lib/widgets/timesheet_grid.dart)
   — a real-world consumer (worker rows + cost-code columns + frozen
   header/qty/totals rows + widget-overlay columns).
