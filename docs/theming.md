# Theming

A `GridTheme` is the visual **floor** — global defaults for every region. On
top of it, per-column / per-row / per-cell overrides flow through an
`InteractionPolicy`. Cell wins over row wins over column wins over theme.

## `GridTheme`

Pass a theme to `UltimateTable`. The default is `GridTheme.mark85` (the
orange-and-cream preset).

```dart
UltimateTable(controller: controller, theme: GridTheme.mark85);
```

`GridTheme` is immutable and `const`-constructible — all fields are required
except the two grid-line toggles. The full field set:

**Colors**

| Field | Role |
|---|---|
| `background` | Body / cell fill |
| `headerBackground` | Header row strip |
| `frozenStripBackground` | Top-frozen / pinned strip tint |
| `footerBackground` | Bottom-frozen / footer strip |
| `rowBanding` | Alternating row tint (transparent disables) |
| `hoverHighlight` | Hover tint |
| `selectionFill` | Fill of selected cells |
| `selectionStroke` | Selection rectangle border |
| `focusStroke` | Focused-cell border |
| `gridLine` | Thin grid lines between cells |
| `thickLine` | Heavier divider (e.g. under the header) |

**Text styles**

| Field | Role |
|---|---|
| `headerTextStyle` | Header labels |
| `bodyTextStyle` | Default body text |
| `bodyNumericStyle` | `CellKind.number` cells (tabular figures) |
| `mutedTextStyle` | Secondary / muted text |

**Metrics & toggles**

| Field | Role |
|---|---|
| `cellPadding` | `EdgeInsets` inside each cell |
| `gridLineWidth` | Thin line stroke width |
| `thickLineWidth` | Thick line stroke width |
| `showHorizontalGridLines` | Draw lines between rows (default `true`) |
| `showVerticalGridLines` | Draw lines between columns (default `true`) |

Turn off grid lines on a preset by setting the toggles:

```dart
const minimal = GridTheme.mark85; // copy fields and flip in a new const ...
```

`GridTheme` has no `copyWith`; build a new `const GridTheme(...)` (or your own
preset factory) when you need a variation. See [Recipes](recipes.md) for a
full preset example.

## Per-column / row / cell overrides

Three style holders layer on top of the theme:

```dart
class ColumnStyle { Color? background; TextStyle? textStyle; TextAlign? textAlign; }
class RowStyle    { Color? background; TextStyle? textStyle; }                 // no textAlign
class CellStyle   { Color? background; TextStyle? textStyle; TextAlign? textAlign; }
```

They are resolved through the same `InteractionPolicy<T>` shape used for
interaction (see [Interaction](interaction.md)) — a `MapPolicy` for explicit
addresses, a `PredicatePolicy` for rules, composed with `overriddenBy`. The
precedence when a cell is painted:

```
CellStyle  →  RowStyle  →  ColumnStyle  →  GridTheme
   (highest)                                  (floor)
```

A concrete cell-level override via `PredicatePolicy`:

```dart
final overdue = PredicatePolicy<CellStyle>((r, c, rowId, colId) {
  return colId == 'due' && isOverdue(rowId)
      ? const CellStyle(
          background: Color(0x14EF4444),
          textStyle: TextStyle(color: Color(0xFFB91C1C)),
        )
      : null;
});
```

Compose multiple policies — the topmost non-null result wins:

```dart
final styles = columnDefaults
    .overriddenBy(rowBanding)
    .overriddenBy(overdue);
```

## Grid lines

`showHorizontalGridLines` / `showVerticalGridLines` toggle the thin lines
globally; the header keeps its `thickLine` bottom divider regardless. Set
`gridLine` to a transparent color (or the toggles to `false`) for a borderless
look.

## See also

- [Interaction](interaction.md) — the `InteractionPolicy` shape these overrides reuse
- [Cells & rendering](cells-and-rendering.md) — `CellRenderContext` carries the resolved style
- [Recipes](recipes.md) — building a full theme preset
