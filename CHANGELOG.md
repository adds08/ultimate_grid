# Changelog

## 0.2.0 — Documentation, live showcase & search-field fixes

> **No breaking changes.** The public API is identical to 0.1.x — existing code
> compiles and behaves the same. The only behavior change is that
> `UltimateSearchField`'s `hintText` now actually renders (it was previously a
> no-op). No types, parameters, or exports were removed or renamed.

### Added

- **Full documentation set** under [`docs/`](docs/) — the single source of
  truth: getting started, concepts, columns, cells & rendering, data sources,
  interaction, sort/filter/search, theming, performance, recipes, plus a
  status/roadmap. Linked from the README and rendered in the live demo.
- **Live showcase site** (the `example/` app), modelled on bootstrap-table:
  deep-linkable routes, a hero/home, categorized live examples — each with
  copy-pasteable source loaded from the actual running demo files — in-app docs,
  and a roadmap page. Deployed to GitHub Pages.
- **README badges** (pub version / points / likes / publisher, CI, stars,
  license), a links bar, and a shipped/planned feature matrix.

### Fixed

- `UltimateSearchField` constructed a new `FocusNode` inside `build()` on every
  rebuild — orphaned and never disposed. It is now a `State` field disposed in
  `dispose()`.
- `UltimateSearchField.hintText` was a documented but unused parameter; the
  placeholder now renders when the field is empty.

### Repository

- The GitHub repository was renamed `flutter_grid_package` → `ultimate_grid`
  (old URLs redirect automatically). The **pub package name is unchanged**.
- Added GitHub Actions: CI (analyze / test / format / publish dry-run / web
  build) and a Pages deploy for the showcase.

## 0.1.1 — Docs polish

- README H1 now reads "Ultimate Grid" (was `ultimate_grid`) so the
  pub.dev page surfaces a product title rather than the snake-case
  package id.
- Restored the "Why this exists" origin section so the GitHub README
  carries the package's history, lightly reframed to point at the
  Office Time Log demo instead of the prior timesheet prototype.

No code changes; the API surface is identical to 0.1.0.

## 0.1.0 — Initial release

First public release of `ultimate_grid` — a scalable, themable 2D
data-grid for Flutter.

### Highlights

- **Headless model.** `GridSchema` + `GridDataSource` + `GridController`.
  Sparse cell storage, sealed `CellValue` hierarchy (Empty / Number / Text
  / Bool / Date / Formula / Custom), lazy metadata side-channel.
- **9-region freeze layout.** Left- / right-frozen columns × top- /
  bottom-frozen rows, with non-contiguous freeze support ordered by pin
  priority.
- **Custom RenderObject body.** `RenderUltimateBody` paints visible
  cells directly via a `ParagraphCache` LRU — no widget tree per cell.
  Scales to 5 M rows with only the visible window painted each frame.
- **Selection.** Drag-to-select rectangles inside the body; Shift-click
  extends; Cmd/Ctrl-click adds non-contiguous ranges; `Cmd/Ctrl+C`
  copies to clipboard as TSV (round-trips with Excel / Sheets).
- **Cell merges.** `MergeRange` on the data source; renderer occludes
  non-anchor cells via a `Uint32List` bitset (web-safe).
- **Sort / filter / search.** Single-pass `ViewPipeline`; column-header
  menu with sort, pin, hide, filter, fit-to-text; `UltimateSearchField`
  with Highlight / Filter modes.
- **Drag-resize + drag-reorder columns.** 8-px right-edge handle on
  every column header; long-press drag to reorder middle columns
  (frozen columns are pinned in place).
- **Async data source.** `AsyncGridDataSource` for paged API-backed
  grids with loading placeholders.
- **Themable.** Default `GridTheme.mark85`; per-column / per-row /
  per-cell style overrides via `InteractionPolicy`.
- **Pluggable cell renderers.** `CellRendererRegistry` with per-column
  override → per-`CellKind` default → fallback.
- **Widget cells.** Pass `widgetColumns` + `cellWidgetBuilder` to
  render specific columns as widgets while other columns keep the
  fast paint path.
- **Embedded header + scrollbars.** Three-region horizontal header
  syncs with body; dedicated scrollbar gutters that sit outside the
  table edge, past frozen columns / rows.
- **In-cell editor.** Double-tap to edit; Enter commits, Esc cancels,
  click-outside commits the live text. Select-all on open. Cell
  borders preserved during edit.

### Constraints

- Flutter web uses `Uint32List` for bitsets (no `Uint64List` on web).
- Body cells render via direct paint, not widgets — drag-to-highlight
  substring inside a single cell is intentionally not supported. The
  in-cell editor (double-tap) gives full text-selection / native
  context menu.
