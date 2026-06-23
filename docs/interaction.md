# Interaction

`UltimateTable` ships Excel-style selection, clipboard copy, an in-cell editor,
and keyboard navigation out of the box. Per-cell behaviors and styles flow
through one shape: `InteractionPolicy`.

## Selection

Selection is rectangle-based and supports non-contiguous ranges, mirroring a
spreadsheet:

- **Drag** — press and drag in the body to rubber-band a rectangle.
- **Shift-click** — extends the active range's extent to the clicked cell.
- **Cmd/Ctrl-click** — pushes a new single-cell range onto the selection
  (non-contiguous).

The view drives the controller's selection API for you; you can also call it
directly:

```dart
controller.selectCell(rowIndex, colIndex);
controller.extendSelectionTo(rowIndex, colIndex); // shift / drag
controller.addSelectionRange(rowIndex, colIndex); // cmd/ctrl-click
controller.selectRow(rowIndex);
controller.selectColumn(colIndex);
controller.selectAll();
controller.clearSelection();
controller.selection; // Selection — { ranges: List<SelectionRange>, focus }
```

Indices here are **view indices** (post filter/sort), not schema indices. A
`SelectionRange` is an anchor + extent rectangle, inclusive on both ends;
whole-row / whole-column selections use the `SelectionRange.allRows` /
`allCols` sentinels.

## Clipboard copy (TSV)

`Cmd/Ctrl+C` copies the current selection to the system clipboard as TSV — one
row per line, tabs between cells — which round-trips with Excel, Numbers, and
Google Sheets. Non-contiguous selections copy their bounding rectangle.

You can trigger it programmatically:

```dart
await GridClipboard.copySelection(controller); // writes to the OS clipboard
final tsv = GridClipboard.selectionAsTsv(controller); // just the string
```

## In-cell editor

**Double-tap** a body cell to open the overlay editor (a single floating
`EditableText`, regardless of grid size):

- **Enter** (or numpad Enter) commits.
- **Esc** cancels.
- Clicking another cell or scrolling commits the in-progress text.

On commit, the typed text is parsed against the column's `CellKind`
(`number` → `NumberCell`, `bool_` → `BoolCell`, `date` → `DateCell`, otherwise
`TextCell`; empty text → `EmptyCell`). The default behavior writes the parsed
value back into the source **when the source is a `MapGridDataSource`**.
Intercept it to validate or route elsewhere:

```dart
UltimateTable(
  controller: controller,
  editable: true, // default; set false to disable the editor entirely
  onCellCommit: (row, col, newValue) {
    if (isValid(newValue)) source.setValue(row, col, newValue);
  },
)
```

`bool_` columns toggle on a **single tap** (no text editor). The body cannot
drag-highlight a substring inside one painted cell — double-tap into the editor
for full text selection. Related callbacks: `onRowTap`, `onRowDoubleTap`,
`onHeaderTap`.

## Keyboard navigation

When the grid has focus (`autofocus: true`, or after a click), these activators
move/extend the active cell:

- **Arrows** — move; **Shift+Arrows** — extend the selection.
- **Home / End** — jump to the first / last column in the row.
- **PageUp / PageDown** — move 10 rows.
- **Cmd/Ctrl+C** — copy (above).

`autofocus` defaults to `false` so the grid doesn't steal focus from a hosting
`TextField`; set it true for spreadsheet-first screens.

## `InteractionPolicy<T>`

One tiny shape powers per-cell attributes — styles, conditional formatting, and
more. The contract: return `T` when a cell has the attribute, `null` otherwise.

```dart
abstract class InteractionPolicy<T extends Object> {
  T? at(int rowIndex, int colIndex, RowId row, ColId col);
  InteractionPolicy<T> overriddenBy(InteractionPolicy<T> other);
}
```

Two implementations + composition:

- **`MapPolicy<T>(entries)`** — explicit, address-keyed. Memory is
  `O(#entries)`, not `O(#cells)`.

  ```dart
  final highlights = MapPolicy<CellStyle>({
    const CellAddress('r0', 'price'): const CellStyle(background: Color(0x22FF0000)),
  });
  ```

- **`PredicatePolicy<T>(rule)`** — rule-driven, evaluated lazily at paint/hit
  time, so it holds **zero per-cell state** even across millions of cells.

  ```dart
  final negatives = PredicatePolicy<CellStyle>((r, c, rowId, colId) {
    return colId == 'amount' && isNegative(rowId)
        ? const CellStyle(textStyle: TextStyle(color: Color(0xFFEF4444)))
        : null;
  });

  // Convenience: every cell where both indices are even.
  final banding = PredicatePolicy.evenCells<CellStyle>(
    const CellStyle(background: Color(0x08000000)),
  );
  ```

- **Composition** — `base.overriddenBy(top)`: when both resolve a value, `top`
  wins.

  ```dart
  final policy = banding.overriddenBy(negatives).overriddenBy(highlights);
  ```

This is the same shape used for per-cell style overrides in
[Theming](theming.md) (cell wins over row wins over column wins over theme).

## See also

- [Theming](theming.md) — `CellStyle` / `RowStyle` / `ColumnStyle` overrides
- [Sort / filter / search](sort-filter-search.md) — search highlight vs. filter
- [Cells & rendering](cells-and-rendering.md) — widget cells for interactive children
