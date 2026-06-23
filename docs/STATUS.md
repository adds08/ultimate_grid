# Ultimate Grid — Status, Roadmap & Limitations

> Single source of truth for what's shipped, what's planned, and what's known-broken or
> intentionally out of scope. The README feature matrix and the showcase site's Roadmap
> page both derive from this file — do not maintain a second copy elsewhere.
>
> Last reviewed: 2026-06-23 · Package `ultimate_grid` `0.1.1`

## Legend

✅ shipped & documented · 🚧 in progress · 🗓️ planned · ⛔ intentionally out of scope

---

## Shipped ✅

### Data model & engine
- ✅ Headless model: `GridSchema` + `GridDataSource` + `GridController`
- ✅ `MapGridDataSource` (sparse cell storage) + lazy sparse metadata side-channel
- ✅ Sealed `CellValue`: Empty / Number / Text / Bool / Date / Formula / Custom
- ✅ Single-pass derived state (layout + pipeline rebuilt once per revision, not per frame)
- ✅ `AsyncGridDataSource` for paged, API-backed grids with loading placeholders

### Layout & rendering
- ✅ 9-region freeze (left/right-frozen columns × top/bottom-frozen rows), non-contiguous,
  ordered by pin priority; cumulative offsets in `Float64List`, binary-search visibility
- ✅ Custom `RenderUltimateBody` canvas paint with `ParagraphCache` LRU — no widget tree per
  cell; only the visible window paints each frame (scales to ~5M rows)
- ✅ Cell merges via `MergeRange` (anchor expands, occluded cells skipped; `Uint32List` bitset)
- ✅ Embedded 3-region header + dedicated scrollbar gutters outside the frozen edges

### Interaction
- ✅ Excel-style rectangle selection (drag); Shift-click extend; Cmd/Ctrl-click non-contiguous
- ✅ Copy selection as TSV to system clipboard (round-trips with Excel / Numbers / Sheets)
- ✅ In-cell editor (double-tap; Enter commits, Esc cancels, click-out commits; select-all on open)
- ✅ Keyboard navigation
- ✅ `InteractionPolicy<T>`: `MapPolicy`, `PredicatePolicy` (e.g. `evenCells`), composition via `overriddenBy`
- ✅ Drag-to-resize columns (8px edge handle); long-press drag-to-reorder middle columns

### Sort / filter / search
- ✅ Single-pass `ViewPipeline` (filter → sort → search)
- ✅ Column header menu (`showUltimateColumnMenu`): sort, pin, hide, fit-to-text, filter
- ✅ Filter dialog with type-appropriate inputs (Contains for text/date, Min/Max for numbers, bool)
- ✅ `Filters.*` pre-built predicates
- ✅ `UltimateSearchField` with Highlight ↔ Filter modes

### Theming & extensibility
- ✅ `GridTheme` (default `mark85`) with per-column / per-row / per-cell overrides via `InteractionPolicy`
- ✅ Horizontal / vertical grid-line toggles
- ✅ Pluggable `CellRendererRegistry`: per-column override → per-`CellKind` default → fallback
- ✅ Widget cells: `widgetColumns` + `cellWidgetBuilder` for interactive columns (other columns keep fast paint)
- ✅ Framework-agnostic core (`flutter/widgets.dart` only); menu/dialog UI pluggable via builder callbacks

---

## In progress 🚧

- 🚧 Documentation set (`docs/`) — tiered simple→advanced guides
- 🚧 Showcase / examples site (bootstrap-table-style, live + copyable source)
- 🚧 CI + GitHub Pages deploy
- ✅ Repo rename `flutter_grid_package` → `ultimate_grid` (GitHub repo + all in-repo links;
  local folder rename still optional)

---

## Planned 🗓️ (candidate features — not yet built)

- 🗓️ **Export**: CSV / Excel (`.xlsx`) export of view or selection
- 🗓️ **Pagination widget**: page-size control + pager UI as an alternative to infinite scroll
- 🗓️ **Row grouping / tree rows**: collapsible groups, aggregate header rows
- 🗓️ **Frozen totals helpers**: declarative sum/avg footer rows that track the filtered view
- 🗓️ **RTL support**: mirror freeze regions and alignment for right-to-left locales
- 🗓️ **Accessibility**: semantics nodes for the painted body (screen-reader cell reads)
- 🗓️ **Column virtualization** for ultra-wide grids (hundreds of columns)
- 🗓️ **Formula evaluation** for `FormulaCell` (currently a value type, not evaluated)
- 🗓️ **Per-column header filters** (inline filter row, à la bootstrap-table filter control)
- 🗓️ **Themed dark mode** preset + auto light/dark switching

> Adjust priorities with the maintainer before building. Each planned item should land with
> a live example page and a docs section in the same PR.

---

## Known limitations (by design)

- **No drag-to-highlight substring inside a body cell.** The body paints directly (no widget
  per cell) for performance. Use the double-tap in-cell editor for full text selection /
  native context menu / copy. Rectangle selection + TSV copy covers cell-range copying.
- **Web 32-bit bitsets.** JavaScript has no native 64-bit ints, so all bitsets use
  `Uint32List` (not `Uint64List`). Any new internal bitset must follow this rule.
- **Merges split by sort/filter are dropped that frame.** A `MergeRange` whose member cells
  are no longer adjacent after a sort/filter is silently not rendered (not an error).
- **No built-in virtualization across columns.** Row virtualization is automatic via the paint
  window; very wide grids (hundreds of columns) are not yet column-virtualized (see Planned).
- **`FormulaCell` is stored, not evaluated.** There is no formula engine yet.

## Known issues

> Populate during the health pass (PROMPT.md workstream B). Track each with: area, severity,
> repro, status. Recent fix history (footer overflow, frozen-column borders, layout
> assertions) means the **footer / freeze / resize / theme-switch** path warrants a focused
> regression sweep before the next release.

| Area | Severity | Repro | Status |
|------|----------|-------|--------|
| `search_field_test.dart` | low (test-only) | 2 tests asserted the pre-refactor Material API (`find.byType(TextField)`, `find.text('Highlight')`); widget is now framework-agnostic `EditableText` with glyph labels | ✅ Fixed 2026-06-23 — finders updated to `EditableText` / `textContaining` |
| `UltimateSearchField` `FocusNode()` in `build()` | low | A new `FocusNode` was constructed every `build()`, orphaned and never disposed (Flutter anti-pattern) | ✅ Fixed 2026-06-23 — hoisted to a `State` field, disposed in `dispose()` |
| `UltimateSearchField.hintText` unused | low (UX) | Public, documented param had no effect — `EditableText` renders no hint, so the placeholder never showed | ✅ Fixed 2026-06-23 — empty-state hint overlay via `ValueListenableBuilder` |
| Showcase brand bar overflow (`example/site/site_shell.dart`) | low (showcase-only) | Nav bar overflowed 32px between the 760px breakpoint and the ~810px it needs to fit | ✅ Fixed 2026-06-23 — breakpoint raised to 860px; caught by new `example/test/smoke_test.dart` |
| Showcase `CodePanel` Scrollbar (`example/site/code_panel.dart`) | low (showcase-only) | `Scrollbar(thumbVisibility: true)` had no `ScrollController` → runtime assertion when a code panel rendered | ✅ Fixed 2026-06-23 — explicit `ScrollController` per scrollbar; covered by smoke test |

## Quality improvements to consider

- **Formatter drift:** the published tree predates a Dart formatter version bump, so a
  `dart format .` now rewraps ~34 files. The CI format check is **advisory**
  (`continue-on-error`) until a deliberate repo-wide `dart format .` + commit is done; then
  flip it to a hard gate.
- **GitHub Pages must be enabled** for the live demo: repo Settings → Pages → Source =
  "GitHub Actions". Until then `https://adds08.github.io/ultimate_grid/` (linked from the
  README) will 404.
- **Hero asset:** the README references `docs/assets/hero.gif` (commented out) — add a real
  capture and uncomment.
- **Showcase site sync step:** the demo source + docs are snapshotted into `example/assets/`
  by `dart run tool/sync_assets.dart`, which must run before `flutter build web` (already
  wired into both CI workflows).
- Golden tests for the painted body across the three theme presets + freeze regions
- A documented public benchmark (extend `test/benchmark_test.dart`) with target frame budgets
- dartdoc coverage check in CI (fail if public API loses doc comments)
- Example: replace/remove the `self_created_example.dart` scratch screen
