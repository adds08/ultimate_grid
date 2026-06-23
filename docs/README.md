# Ultimate Grid — Documentation

This folder is the single source of truth for Ultimate Grid's prose docs.
Each guide opens with the simplest working snippet and builds toward the
advanced cases.

**Reading order: simple → advanced.** Start at the top and work down. Each
guide stands alone, but the order below introduces concepts in the order you
need them.

| # | Guide | What it covers |
|---|---|---|
| 1 | [Getting started](getting-started.md) | Install, import, the minimal runnable grid, running the example |
| 2 | [Concepts](concepts.md) | The mental model — schema vs. source vs. controller vs. view; the 9-region freeze layout |
| 3 | [Columns](columns.md) | `ColumnSpec` fields, width, freeze/pin, resize, reorder, hide/show, fit-to-text, alignment |
| 4 | [Cells & rendering](cells-and-rendering.md) | The `CellValue` family, the renderer registry, custom renderers, widget cells |
| 5 | [Data sources](data-sources.md) | `MapGridDataSource`, `AsyncGridDataSource` paging, sparse data, merges |
| 6 | [Interaction](interaction.md) | Selection, clipboard TSV, the in-cell editor, keyboard nav, `InteractionPolicy` |
| 7 | [Sort / filter / search](sort-filter-search.md) | The view pipeline, column menu, `Filters.*`, search modes |
| 8 | [Theming](theming.md) | `GridTheme` fields, presets, per-column / row / cell overrides |
| 9 | [Performance](performance.md) | Canvas paint, the paragraph cache, scaling to millions of rows, the web caveat |
| 10 | [Recipes](recipes.md) | Advanced patterns — custom renderers, theme presets, custom menu UI, totals rows |

## External references

- **Repo README** — [`../README.md`](../README.md) (overview, feature matrix, install)
- **Live demo & gallery** — <https://adds08.github.io/ultimate_grid/>
- **API reference** (every public symbol) — <https://pub.dev/documentation/ultimate_grid/latest/>
- **Roadmap & known limitations** — [STATUS.md](STATUS.md)

When a topic touches API-level minutiae, this set defers to the
[pub.dev API reference](https://pub.dev/documentation/ultimate_grid/latest/)
rather than duplicating every symbol.
