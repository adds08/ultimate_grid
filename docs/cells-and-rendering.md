# Cells & rendering

A cell's *value* is a `CellValue`. How it *paints* is decided by a
`CellRendererRegistry`. The two are decoupled: the same value can paint
differently per column.

## The `CellValue` family

`CellValue` is a sealed class — the renderer and clipboard switch over it
exhaustively. Every variant is `const`-constructible and value-equal.

| Variant | Holds | Example |
|---|---|---|
| `EmptyCell` | nothing — the absence of a value | `const EmptyCell()` / `EmptyCell.instance` |
| `NumberCell` | `double value` | `const NumberCell(19.99)` |
| `TextCell` | `String value` | `const TextCell('Widget A')` |
| `BoolCell` | `bool value` | `const BoolCell(true)` |
| `DateCell` | `DateTime value` | `DateCell(DateTime(2026, 6, 23))` |
| `FormulaCell` | `String source` + optional `CellValue? cached` | `const FormulaCell('A1+B1')` |
| `CustomCell` | `Object payload` | `const CustomCell(myObject)` |

Notes:

- `EmptyCell` is the canonical "missing" value. `MapGridDataSource.valueAt`
  returns `EmptyCell.instance` for any cell you never set, and writing an
  `EmptyCell` *removes* the stored cell.
- `FormulaCell` carries a source string and a last-evaluated `cached` value.
  The package ships **no formula evaluator** — renderers display `cached`
  (or the raw `source` when `cached` is null). `withCached(next)` returns a
  copy with a new cached value.
- `CustomCell` is the escape hatch when the payload **is** the visible value
  and a custom renderer will paint it. For invisible/secondary payloads prefer
  `GridDataSource.metadataAt` (sparse, zero-cost when unused) instead.
- `CellValue.raw` returns the underlying Dart value; `isEmpty` is true only for
  `EmptyCell`.

## The renderer registry

A `CellRendererRegistry` resolves the right `CellRenderer` for a
`(column, cell-kind)` pair in this order:

1. **per-column override** — registered by `ColId`
2. **per-`CellKind` default** — registered by `ColumnSpec.kind`
3. **fallback** — the registry's `fallback` renderer (a left/right-aligned
   single-line text renderer by default)

```dart
final registry = CellRendererRegistry();
registerDefaultRenderers(registry); // Number / Text / Bool / Date kinds
registry.registerColumn('status', MyStatusBadgeRenderer()); // column override
UltimateTable(controller: controller, renderers: registry);
```

If you pass `renderers: null` (the default), `UltimateTable` builds a registry
and calls `registerDefaultRenderers` for you. **If you pass your own registry,
the table does *not* auto-register the defaults** — call
`registerDefaultRenderers(registry)` yourself first, then add overrides.

`registerDefaultRenderers` installs:

- `CellKind.number` → `NumberCellRenderer` (right-aligned, `decimals: 2`,
  integers shown without a decimal point)
- `CellKind.text` → `TextCellRenderer`
- `CellKind.bool_` → `BoolCellRenderer` (a checkbox-style box)
- `CellKind.date` → `DateCellRenderer` (ISO `yyyy-MM-dd`)

(`CellKind.formula` and `CellKind.custom` fall through to the fallback unless
you register them.)

## Writing a custom renderer

Extend `CellRenderer` and return a widget. The `CellRenderContext` carries the
resolved style, alignment, padding, background, and selection/focus/search-hit
flags so your renderer matches the theme.

```dart
class StatusBadgeRenderer extends CellRenderer {
  const StatusBadgeRenderer();

  @override
  Widget build(BuildContext context, CellValue value, CellRenderContext ctx) {
    final label = value is TextCell ? value.value : '';
    final ok = label == 'Active';
    return Padding(
      padding: ctx.padding,
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: ok ? const Color(0x1410B981) : const Color(0x14EF4444),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(label, style: ctx.textStyle, maxLines: 1),
        ),
      ),
    );
  }
}
```

Register it per column (`registry.registerColumn('status', const StatusBadgeRenderer())`)
or per kind (`registry.registerKind(CellKind.custom, const StatusBadgeRenderer())`).

`CellRenderContext` fields you can rely on: `rowId`, `colId`, `rowIndex`,
`colIndex`, `column` (the `ColumnSpec`), `theme`, `textStyle`, `textAlign`,
`padding`, `background`, `isSelected`, `isFocused`, `isSearchHit`.

> Renderers used in the **scrollable middle body** are consulted by the
> custom-paint path for performance — a plain text renderer paints through the
> cached-paragraph fast path. To embed *interactive* widgets in body cells, use
> widget cells (below) rather than a renderer that returns buttons or fields.

## Widget cells

When a column needs interactive children (checkboxes, buttons, custom layouts)
inside the scrollable body, list it in `widgetColumns` and supply a
`cellWidgetBuilder`. Only the listed columns pay the widget-tree cost; every
other column keeps the fast paint path.

```dart
UltimateTable(
  controller: controller,
  widgetColumns: const {'action'},
  cellWidgetBuilder: (context, rowId, colId, value) {
    return Center(
      child: GestureDetector(
        onTap: () => doSomething(rowId),
        child: const Text('Open'),
      ),
    );
  },
)
```

The builder receives the `(rowId, colId)` and current `CellValue` and returns
the widget that overlays that cell's rect. The body skips painting those cells
so the overlay shows through, with grid lines drawn around it.

## See also

- [Columns](columns.md) — `CellKind` and per-column alignment
- [Data sources](data-sources.md) — where cell values live; `metadataAt`
- [Recipes](recipes.md) — a fuller custom-renderer walkthrough
