# Ultimate Grid

[![pub version](https://img.shields.io/pub/v/ultimate_grid.svg)](https://pub.dev/packages/ultimate_grid)
[![pub points](https://img.shields.io/pub/points/ultimate_grid)](https://pub.dev/packages/ultimate_grid/score)
[![pub likes](https://img.shields.io/pub/likes/ultimate_grid)](https://pub.dev/packages/ultimate_grid/score)
[![publisher](https://img.shields.io/pub/publisher/ultimate_grid)](https://pub.dev/publishers/codebigya.com)
[![CI](https://github.com/adds08/ultimate_grid/actions/workflows/ci.yml/badge.svg)](https://github.com/adds08/ultimate_grid/actions/workflows/ci.yml)
[![GitHub stars](https://img.shields.io/github/stars/adds08/ultimate_grid?style=flat&logo=github)](https://github.com/adds08/ultimate_grid/stargazers)
[![license: MIT](https://img.shields.io/github/license/adds08/ultimate_grid)](LICENSE)

**A scalable, themable 2D data-grid for Flutter** — millions of cells without
jitter, a 9-region freeze layout, cell merges, async data, Excel-style
selection, sort / filter / search, and full theming. Free, open source, and
framework-agnostic (the library depends only on `flutter/widgets.dart`).

<!-- Drop a hero capture at docs/assets/hero.gif and uncomment:
![Ultimate Grid](docs/assets/hero.gif)
-->

> ### 🔗 Links
> **[▶ Live demo & examples](https://adds08.github.io/ultimate_grid/)** ·
> **[📖 Docs](docs/README.md)** ·
> **[🧩 API reference](https://pub.dev/documentation/ultimate_grid/latest/)** ·
> **[🗺️ Roadmap & limitations](docs/STATUS.md)** ·
> **[pub.dev](https://pub.dev/packages/ultimate_grid)** ·
> **[GitHub](https://github.com/adds08/ultimate_grid)**
>
> _Live demo goes live on the first push to `main` (GitHub Pages workflow)._

## Why Ultimate Grid

- **Scales.** A custom `RenderObject` paints only the visible cell window via a
  cached `TextPainter` LRU — no widget tree per cell. Smooth at millions of rows.
- **Freezes like a spreadsheet.** 9 regions: left / right-frozen columns ×
  top / bottom-frozen rows, including non-contiguous freezes by pin priority.
- **Framework-agnostic.** Core uses only `flutter/widgets.dart` — no Material or
  Cupertino lock-in. Plug your own popup/dialog UI (shadcn, Material, …) into the
  column menu and filter dialog via builder callbacks.
- **Themable to the cell.** A `GridTheme` floor with per-column / per-row /
  per-cell overrides flowing through one `InteractionPolicy` shape.

## Install

```yaml
dependencies:
  ultimate_grid: ^0.1.1
```

```dart
import 'package:ultimate_grid/ultimate_grid.dart';
```

## Quick start

```dart
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

A fuller gallery — financial sheet with merges, 100k-row async paging, search &
filter UI, a theme switcher with three presets, office time log, budget tracker,
datagrid, spreadsheet, and a 5 M-row stress test — ships in [`example/`](example/)
and on the [live demo](https://adds08.github.io/ultimate_grid/).

## Documentation

Docs live in [`docs/`](docs/) and are the single source of truth. Start at the
[docs index](docs/README.md), then read in order:

| Guide | What it covers |
|---|---|
| [Getting started](docs/getting-started.md) | Install, the minimal grid, running the example |
| [Concepts](docs/concepts.md) | Schema vs. source vs. controller vs. view; the 9 regions |
| [Columns](docs/columns.md) | Width, freeze / pin, resize, reorder, hide, alignment, headers |
| [Cells & rendering](docs/cells-and-rendering.md) | `CellValue` kinds, default + custom renderers, widget cells |
| [Data sources](docs/data-sources.md) | `MapGridDataSource`, async paging, sparse data, merges |
| [Interaction](docs/interaction.md) | Selection, clipboard TSV, in-cell editor, keyboard nav, policies |
| [Sort / filter / search](docs/sort-filter-search.md) | Column menu, `Filters.*`, the view pipeline, search modes |
| [Theming](docs/theming.md) | `GridTheme` fields, presets, per-column / row / cell overrides |
| [Performance](docs/performance.md) | Canvas paint, paragraph cache, large-data and web notes |
| [Recipes](docs/recipes.md) | Advanced: custom renderers, totals rows, custom menu UI |

API specifics (every public symbol) are on
[pub.dev/documentation](https://pub.dev/documentation/ultimate_grid/latest/).

## Feature matrix

✅ shipped · 🚧 in progress · 🗓️ planned — full detail in [docs/STATUS.md](docs/STATUS.md).

| Capability | Status |
|---|:--:|
| Headless model (`GridSchema` / `GridDataSource` / `GridController`) | ✅ |
| 9-region freeze (non-contiguous, pin priority) | ✅ |
| Custom-paint body, no widget tree per cell (~5M rows) | ✅ |
| Cell merges (`MergeRange`) | ✅ |
| Excel-style selection + TSV clipboard copy | ✅ |
| In-cell editor (double-tap, Enter / Esc) | ✅ |
| Sort / filter / search (single-pass pipeline) | ✅ |
| Column menu + type-aware filter dialog | ✅ |
| Drag-resize + drag-reorder columns | ✅ |
| Async / paged data source | ✅ |
| Pluggable cell renderers + widget cells | ✅ |
| `GridTheme` + per-column / row / cell overrides | ✅ |
| Showcase site + tiered docs | 🚧 |
| CSV / Excel export | 🗓️ |
| Pagination widget · row grouping · frozen totals | 🗓️ |
| RTL · accessibility · column virtualization | 🗓️ |

## Constraints

- **Flutter web:** bitsets use `Uint32List` (JavaScript has no native 64-bit
  ints, so `Uint64List` isn't supported on web).
- **No widget tree per cell in the body.** Body cells are painted directly, so
  drag-to-highlight a substring inside one cell is intentionally unsupported —
  double-tap to open the in-cell editor for full text selection.

See [docs/STATUS.md](docs/STATUS.md) for the complete list of limitations and
known issues.

## Architecture map

```
src/
├── model/         CellValue, CellAddress, ColumnSpec, RowSpec, GridSchema, FrozenSide
├── source/        GridDataSource (abstract) + MapGridDataSource + AsyncGridDataSource
├── interaction/   InteractionPolicy: MapPolicy, PredicatePolicy, composition
├── controller/    Selection, ColumnLayout, RowLayout, GridController, clipboard
├── filter_sort/   ViewPipeline (filter → sort → search; one pass) + Filters
├── theme/         GridTheme, ColumnStyle, RowStyle, CellStyle
├── cells/         CellRenderer + registry; default Number/Text/Bool/Date renderers
└── view/          UltimateTable, header, render body, column menu, search field
```

<details>
<summary><strong>Why this package exists</strong> (the origin story)</summary>

Around 2017–2020, I was a one-person stack working on a tablet app for a
construction company. The headline screen was a timesheet — crews on one axis,
cost codes on the other, hours in the middle, with phases and projects layered
behind them in a relational backend. It was the most complex piece of UI I had
built up to that point: cell mapping across schemas, multi-cell selection,
multi-value entry, a custom on-screen keyboard, and the kind of state churn
where every edit had to ripple into totals on the right and a
quantity-to-claim band on the top. On the web side the same dataset was shown
through a jQuery-driven `bootstrap-table`, with PHP, SQL, CSS, the Flutter app,
and the servers all in the same week's todo list.

I shipped it. It worked. It was also a stark reminder that Flutter, at the
time, had no real grid ecosystem. `table_sticky_headers` covered the basic
sticky-header case but wasn't flexible enough. When `TwoDimensional` arrived in
the SDK a couple of years later I was hopeful — but it landed as a low-level
building block, not a feature-grade grid, and the gap between "drawable
viewport" and "actual datagrid" stayed wide.

Between contract gigs I kept the unfinished grid in a side folder. It was too
unpolished to publish — always five missing pieces. With AI-assisted overhauls
over the last year I finally did the surgery it needed: replaced the external
table dependency with the canvas-paint body it has today, kept the original
mental model (rows and columns are both data, edges freeze, totals derive), and
produced something I could share. The same time-log shape that motivated this
package ships as the **Office Time Log** demo in `example/` today, reframed for
IT projects on the new engine.

> Five clients later, the same package now ships under multiple production apps.
> None of them are construction-shaped.

This is the artifact of that journey: the grid I wanted in 2018, written
through 2026, for everyone who's hit the same wall.

</details>

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md). The hard rules inside `lib/`: web-safe
bitsets only, no widget tree per cell on the paint path, doc comments on every
public symbol.

## License

MIT — see [LICENSE](LICENSE).
