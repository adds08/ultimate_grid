# Recipes

Advanced patterns that combine the building blocks from the earlier guides.
Each recipe is self-contained and copy-pasteable.

## 1. A custom `CellRenderer`

Render a numeric "delta" column with red/green coloring and a sign. Register it
per column so only that column uses it.

```dart
class DeltaRenderer extends CellRenderer {
  const DeltaRenderer();

  @override
  Widget build(BuildContext context, CellValue value, CellRenderContext ctx) {
    if (value is! NumberCell) {
      return Padding(padding: ctx.padding, child: const SizedBox.shrink());
    }
    final v = value.value;
    final color = v > 0
        ? const Color(0xFF16A34A)
        : v < 0
            ? const Color(0xFFDC2626)
            : ctx.theme.bodyTextStyle.color;
    final text = '${v > 0 ? '+' : ''}${v.toStringAsFixed(2)}';
    return Padding(
      padding: ctx.padding,
      child: Align(
        alignment: Alignment.centerRight,
        child: Text(text, style: ctx.textStyle.copyWith(color: color), maxLines: 1),
      ),
    );
  }
}

final registry = CellRendererRegistry();
registerDefaultRenderers(registry); // keep the defaults...
registry.registerColumn('delta', const DeltaRenderer()); // ...then override one column
UltimateTable(controller: controller, renderers: registry);
```

Remember: passing your own registry disables the auto-registration of defaults,
so call `registerDefaultRenderers(registry)` first. See
[Cells & rendering](cells-and-rendering.md).

## 2. Build your own theme preset

`GridTheme` has no `copyWith`, so a preset is just a `const GridTheme(...)` (or
a factory). A minimal, borderless slate preset:

```dart
const slate = GridTheme(
  background: Color(0xFFFFFFFF),
  headerBackground: Color(0xFFF8FAFC),
  frozenStripBackground: Color(0xFFF1F5F9),
  footerBackground: Color(0xFFF8FAFC),
  rowBanding: Color(0x06000000),
  hoverHighlight: Color(0x0F0F172A),
  selectionFill: Color(0x142563EB),
  selectionStroke: Color(0xFF2563EB),
  focusStroke: Color(0xFF2563EB),
  gridLine: Color(0xFFE2E8F0),
  thickLine: Color(0xFFCBD5E1),
  headerTextStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
  bodyTextStyle: TextStyle(fontSize: 14, color: Color(0xFF0F172A)),
  bodyNumericStyle: TextStyle(
    fontSize: 14,
    color: Color(0xFF0F172A),
    fontFeatures: [FontFeature.tabularFigures()],
  ),
  mutedTextStyle: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
  cellPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
  gridLineWidth: 1,
  thickLineWidth: 2,
  showVerticalGridLines: false, // horizontal-only rules
);

UltimateTable(controller: controller, theme: slate);
```

Swatch-style accent overrides (selection / focus / frozen tint) are best done
by minting a new preset that differs only in those colors. See the example
gallery's theme switcher for a fuller pattern, and [Theming](theming.md) for
per-cell overrides on top of a preset.

## 3. Plug a custom column-menu / filter dialog UI

`showUltimateColumnMenu` is framework-agnostic — supply `menuBuilder` and
`filterDialogBuilder` to use your own widgets (shadcn, Material, …). The menu
builder shows your popup and calls `onAction`; the filter dialog applies a
`Filters.*` predicate through the controller.

```dart
import 'package:flutter/material.dart';

Future<void> openColumnMenu(BuildContext cellCtx, ColId colId) {
  return showUltimateColumnMenu(
    context: cellCtx,
    controller: controller,
    colId: colId,
    menuBuilder: ({required context, required controller, required columnState, required onAction}) async {
      final box = context.findRenderObject() as RenderBox;
      final pos = box.localToGlobal(Offset.zero);
      final action = await showMenu<ColumnMenuAction>(
        context: context,
        position: RelativeRect.fromLTRB(pos.dx, pos.dy + box.size.height, pos.dx, 0),
        items: [
          const PopupMenuItem(value: ColumnMenuAction.sortAsc, child: Text('Sort ascending')),
          const PopupMenuItem(value: ColumnMenuAction.sortDesc, child: Text('Sort descending')),
          const PopupMenuItem(value: ColumnMenuAction.pinLeft, child: Text('Pin left')),
          const PopupMenuItem(value: ColumnMenuAction.hide, child: Text('Hide')),
          const PopupMenuItem(value: ColumnMenuAction.fit, child: Text('Resize to fit')),
          const PopupMenuItem(value: ColumnMenuAction.filter, child: Text('Filter…')),
        ],
      );
      if (action != null) onAction(action);
    },
    filterDialogBuilder: ({required context, required controller, required colId, required kind, required header}) async {
      // Pick an input by `kind`. Here: a numeric min/max for number columns.
      if (kind == CellKind.number) {
        controller.setFilter(colId, Filters.numberRange(min: 0));
      } else {
        controller.setFilter(colId, Filters.textContains('...'));
      }
    },
  );
}
```

`ColumnMenuState` (the `columnState` argument) carries `header`, `kind`,
`currentSortDirection`, `hasFilter`, and `frozenSide` so your menu can show
active indicators. See [Sort / filter / search](sort-filter-search.md).

## 4. A derived totals row

Put a totals row in the **bottom-frozen** band so it stays visible and is never
touched by filter/sort, then recompute it whenever the data changes. The totals
row is a real row in the source; freeze it to the end and listen for changes.

```dart
const totalsRowId = 'totals';

final schema = GridSchema(
  columns: const [
    ColumnSpec(id: 'item', header: 'Item', defaultFrozen: FrozenSide.start),
    ColumnSpec(id: 'qty', header: 'Qty', kind: CellKind.number),
    ColumnSpec(id: 'amount', header: 'Amount', kind: CellKind.number),
  ],
  rows: [
    for (var i = 0; i < 50; i++) RowSpec(id: 'r$i'),
    const RowSpec(id: totalsRowId, defaultFrozen: FrozenSide.end), // pinned bottom
  ],
);

void recomputeTotals(MapGridDataSource source) {
  var qty = 0.0, amount = 0.0;
  for (final rowId in source.rowIds) {
    if (rowId == totalsRowId) continue;
    final q = source.valueAt(rowId, 'qty');
    final a = source.valueAt(rowId, 'amount');
    if (q is NumberCell) qty += q.value;
    if (a is NumberCell) amount += a.value;
  }
  source.setValue(totalsRowId, 'item', const TextCell('TOTAL'));
  source.setValue(totalsRowId, 'qty', NumberCell(qty));
  source.setValue(totalsRowId, 'amount', NumberCell(amount));
}
```

Call `recomputeTotals(source)` after a batch of edits (or wrap edits so it runs
once afterward). Because the totals row is frozen to the end, it sits below the
scrollable body and survives sort/filter. The example gallery's financial sheet
uses exactly this shape plus a `MergeRange` header strip — see
[Data sources](data-sources.md).

## See also

- [Cells & rendering](cells-and-rendering.md) — the renderer registry resolution order
- [Theming](theming.md) — `GridTheme` fields and per-cell overrides
- [Sort / filter / search](sort-filter-search.md) — the column menu and `Filters.*`
