# Sort, filter & search

Sorting, filtering, and searching are all derived state on the controller,
computed by a single-pass `ViewPipeline`. The frozen header/totals rows are
never touched — only the scrollable middle band is reordered.

## The view pipeline

`ViewPipeline.run` runs three steps in one pass — **filter → sort → search** —
and produces a `ViewPipelineResult`:

- `viewRowIndices` (`Int32List`) — the visible row order: indices into the
  source's row list, post-filter and post-sort.
- `searchHits` (`Uint32List`) — a bitset marking which view rows matched the
  search (used only in highlight mode; see below).

You don't call the pipeline yourself — you drive it through the controller, and
read the result via `controller.pipelineResult`.

### Sort

```dart
controller.setSortKeys([
  const SortKey('amount', SortDirection.descending), // primary
  const SortKey('name', SortDirection.ascending),    // tiebreak
]);
controller.setSortKeys(const []); // clear → source's natural order
```

The default comparator is type-aware (`NumberCell` numerically, `DateCell`
chronologically, `BoolCell`, then string fallback; `EmptyCell` sorts last).
Pass a custom `comparator:` on a `SortKey` to override. Sorting is stable.

### Filter

A `FilterPredicate` is `bool Function(CellValue value)`. Set one per column;
multiple columns AND together.

```dart
controller.setFilter('name', Filters.textContains('widget'));
controller.setFilter('amount', Filters.numberRange(min: 100));
controller.setFilter('name', null); // clear this column's filter
```

Built-in predicate builders in `Filters.*`:

- `Filters.textContains(needle)` — case-insensitive substring on the cell's
  string form (empty cells never match).
- `Filters.oneOf(values)` — display-string membership; integer `NumberCell`s
  match both `"3"` and `"3.0"`; `EmptyCell` matches `""`.
- `Filters.numberRange(min: , max: )` — inclusive bounds on a `NumberCell`;
  either bound may be `null` to leave that side open.
- `Filters.where((CellValue v) => ...)` — wrap any free-form predicate.

## The column menu

`showUltimateColumnMenu` is the framework-agnostic entry point for per-column
actions. With no builders it shows a minimal painted overlay (no Material
dependency) offering **sort asc/desc/off, pin left/right/none, hide, resize to
fit, filter, clear filter**:

```dart
UltimateTable(
  controller: controller,
  headerBuilder: (ctx, colId) => Text(controller.schema.column(colId)?.header ?? colId),
  onHeaderTap: (cellCtx, colId) => showUltimateColumnMenu(
    context: cellCtx, // the cell's context anchors the popup under it
    controller: controller,
    colId: colId,
  ),
)
```

### Plugging in your own UI

To use your own framework's popup/dialog (shadcn, Material, …), pass the
builder callbacks. Both receive everything they need and apply changes through
the controller:

```dart
showUltimateColumnMenu(
  context: cellCtx,
  controller: controller,
  colId: colId,
  menuBuilder: ({
    required context,
    required controller,
    required columnState, // ColumnMenuState: header, kind, sort dir, hasFilter, frozenSide
    required onAction,    // call with a ColumnMenuAction
  }) async {
    // show your menu, then e.g.:
    onAction(ColumnMenuAction.sortAsc);
  },
  filterDialogBuilder: ({
    required context,
    required controller,
    required colId,
    required kind,   // CellKind — pick the right input
    required header,
  }) async {
    // show your dialog, then e.g.:
    controller.setFilter(colId, Filters.numberRange(min: 0, max: 100));
  },
);
```

`ColumnMenuAction.filter` invokes `filterDialogBuilder` (nothing happens if you
don't provide one). You can also drive actions directly without showing a menu
via `applyColumnMenuAction(context, controller, colId, action)`, and read the
current state via `getColumnMenuState(controller, colId)`.

## Search

`UltimateSearchField` is a pre-built input wired to the controller. It has two
modes via `SearchMode`:

- **`SearchMode.highlight`** (default) — every row stays; matches are marked in
  the search-hit bitset and painted with a highlight tint.
- **`SearchMode.filter`** — rows with no match are dropped from the view.

```dart
UltimateSearchField(
  controller: controller,
  hintText: 'Search…',     // default
  showFilterToggle: true,  // default — shows a Highlight ↔ Filter toggle
)
```

Or drive it directly:

```dart
controller.setSearchQuery('widget');
controller.setSearchMode(SearchMode.filter);
```

Search matches a case-insensitive substring against every column's string form.

## See also

- [Concepts](concepts.md) — derived state and the revision model
- [Interaction](interaction.md) — selection and the in-cell editor
- [Recipes](recipes.md) — a custom column menu / filter dialog walkthrough
