# Columns

A column is declared once as a `ColumnSpec` (static shape) and reshaped at
runtime through the `GridController` (live width, freeze, order, visibility).

## Declaring columns

```dart
const ColumnSpec(
  id: 'price',          // required — stable ColId (a String)
  header: 'Price',      // required — header label
  defaultWidth: 100,    // logical px; default 120
  minWidth: 40,         // resize floor; default 40
  kind: CellKind.number, // cell-type hint; default CellKind.text
  defaultFrozen: FrozenSide.end, // pin right; null (default) = scrollable
  defaultFreezePriority: 0, // ordering within a frozen strip
  sortable: true,       // default true
  filterable: true,     // default true
  tag: 'currency',      // optional free-form tag for custom renderers
);
```

`ColumnSpec` is immutable. Its fields are *defaults* — the controller may
override width and freeze at runtime. Live state is never written back into the
spec.

## Width

`defaultWidth` seeds the controller. At runtime:

```dart
controller.setColumnWidth('price', 140); // clamped up to spec.minWidth
controller.widthOf('price');             // effective current width
```

## Freeze / pin

`defaultFrozen` seeds the freeze side; pin/unpin at runtime:

```dart
controller.setColumnFreeze('sku', FrozenSide.start);          // pin left
controller.setColumnFreeze('total', FrozenSide.end, priority: 1); // pin right
controller.setColumnFreeze('sku', null);                      // unpin
controller.freezeOf('sku');           // FrozenSide? — current side
```

`priority` orders columns within a frozen strip — **lower renders closer to the
outside edge**. This is how non-contiguous freezes land deterministically. See
the 9-region layout in [Concepts](concepts.md).

## Reorder

Move a column to a flat index in the current visible order:

```dart
controller.reorderColumn('name', 0); // move 'name' to the front
```

For drag-to-reorder, use `UltimateResizableHeader` with `reorderable: true` —
it wraps each header cell in a `LongPressDraggable<ColId>` and calls
`reorderColumn` on drop:

```dart
UltimateResizableHeader(
  controller: controller,
  reorderable: true, // long-press a header and drag to rearrange
  onTapColumn: (cellCtx, colId) =>
      showUltimateColumnMenu(context: cellCtx, controller: controller, colId: colId),
)
```

## Hide / show

Hidden columns leave the layout but stay in the schema and data source:

```dart
controller.hideColumn('notes');
controller.showColumn('notes');
controller.isColumnHidden('notes'); // bool
controller.hiddenColumns;           // Set<ColId>
```

## Fit to text

Resize a column to the widest visible cell. The controller stays
UI-framework-agnostic, so you supply a `measure` callback (typically a
`TextPainter`):

```dart
controller.fitColumnToText(
  id: 'name',
  measure: (text) {
    final p = TextPainter(
      text: TextSpan(text: text, style: GridTheme.mark85.bodyTextStyle),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();
    final w = p.width;
    p.dispose();
    return w;
  },
  padding: 24,        // added to each measurement; default 24
  maxRowsToScan: 200, // cap the scan for large sources; default 200
);
```

The built-in column menu's "Resize to fit" action does exactly this for you —
see [Sort / filter / search](sort-filter-search.md).

## Resize handle (drag)

The header strips inside `UltimateTable` and the standalone
`UltimateResizableHeader` both expose a drag-to-resize handle on the right edge
of each non-frozen header cell. On `UltimateTable`:

```dart
UltimateTable(
  controller: controller,
  resizableHeader: true,    // default true; frozen columns never resize
  headerMinWidth: 40,       // default 40
  headerMaxWidth: 600,      // default 600
  headerBuilder: (ctx, colId) =>
      Text(controller.schema.column(colId)?.header ?? colId),
)
```

A `headerBuilder` is what mounts the header strip in the first place — without
it `UltimateTable` shows no header row. The header strip honors the 9-region
freeze layout: frozen header cells stay pinned, the middle scrolls in sync with
the body.

## Headers & alignment

The default body renderers align by `CellKind`: `CellKind.number` cells align
right (with tabular figures), everything else aligns left. To override
alignment per column, use a `ColumnStyle.textAlign` override flowing through an
`InteractionPolicy` — see [Theming](theming.md) — or a custom renderer (see
[Cells & rendering](cells-and-rendering.md)).

## See also

- [Cells & rendering](cells-and-rendering.md) — `CellKind`, renderers, alignment
- [Theming](theming.md) — per-column style overrides
- [Sort / filter / search](sort-filter-search.md) — the column menu (sort/pin/hide/fit/filter)
