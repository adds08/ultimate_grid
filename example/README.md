# ultimate_grid — example gallery

A side-nav shell lists each demo. The top bar carries a theme dropdown,
a row of accent-color swatches, and a mobile-preview toggle so the same
gallery doubles as a comparison tool: switch theme/accent without
leaving the screen and the active demo rebuilds with the new
`GridTheme` immediately.

## Demos

1. **Inventory** — schema + `MapGridDataSource` + `GridController` +
   `UltimateTable`. The smallest runnable shape, with SKU frozen left
   and Margin % frozen right.
2. **Financial sheet** — quarter header strip merged across months via
   `MergeRange`; top + bottom-frozen header / totals rows; left-frozen
   region column; right-frozen `TOTAL` column.
3. **Async paging (100k rows)** — `AsyncGridDataSource` fetching pages
   of 50 on demand with a simulated network latency. Scroll fast to see
   "Loading…" placeholders flash before pages resolve. Drop-down
   adjusts the simulated latency.
4. **Search & filters** — `UltimateSearchField` in Highlight ↔ Filter
   mode + the per-column popup menu (`showUltimateColumnMenu`) with
   sort / filter / pin / hide / fit. Filter dialog picks the right
   input for the column kind: Contains for text/date, Min/Max for
   numbers, true/false for bool.

## Theme switcher

The top-bar dropdown swaps between three `GridTheme` presets (see
`lib/screens/_themes.dart`):

- **Raw** — bare grayscale palette. The package surface with all
  decoration stripped — useful as a "what does it look like before I
  customize?" baseline.
- **Elegant** — the orange-and-cream Mark 85 look. Mirrors the
  package's [`GridTheme.mark85`] default.
- **Professional** — slate / blue corporate palette with tabular
  numeric weight and a brand-blue selection accent.

The six swatches next to the dropdown override the accent of the
active preset — selection stroke, focus stroke, and the soft
frozen-strip tint. Click a swatch once to apply, click again to clear.
Custom accent + preset combinations let you spin up "Professional + green"
or "Elegant + purple" without touching code.

## Mobile preview

The phone icon in the top bar forces the layout into compact mode (sidebar
becomes a drawer, body content is framed in a 380-pixel-wide card with a
subtle shadow). Useful for sanity-checking how a demo reads on a phone
without resizing the browser window.

## Sidebar

Collapse the sidebar to an icon-only rail via the hamburger button in
its header. The selected demo stays highlighted and tooltips reveal the
full label on hover.

```bash
cd example
flutter run
```

For the broader gallery (timesheets, budgets, 5M-row stress test) see
the host repo at
[`flutter_grid_package`](https://github.com/adds08/flutter_grid_package).
