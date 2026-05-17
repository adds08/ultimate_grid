# flutter_grid_package

Home of **Ultimate Table by CodeBigya** — a scalable, themable 2D
data-grid for Flutter — and the Mark 85 timesheet prototype that
motivated it.

## Why this exists

Around 2017–2020, I was a one-person stack working on a tablet app
for a construction company. The headline screen was a timesheet —
crews on one axis, cost codes on the other, hours in the middle, with
phases and projects layered behind them in a relational backend. It
was the most complex piece of UI I had built up to that point: cell
mapping across schemas, multi-cell selection, multi-value entry, a
custom on-screen keyboard, and the kind of state churn where every
edit had to ripple into totals on the right and a quantity-to-claim
band on the top. I was learning state management mid-flight; the code
ended up a fan-out of providers and a backend that nested deeper than
I'd like to admit. On the web side the same dataset was shown through
a jQuery-driven `bootstrap-table` library, with PHP, SQL, CSS, the
Flutter app, and the servers all sitting in the same week's todo list.

I shipped it. It worked. It was also a stark reminder that Flutter,
at the time, had no real grid ecosystem. `table_sticky_headers`
covered the basic sticky-header case but wasn't flexible enough for
where the timesheet was heading. When `TwoDimensional` arrived in the
Flutter SDK a couple of years later I was hopeful — but it landed as a
low-level building block, not a feature-grade grid, and the gap
between "drawable viewport" and "actual datagrid" stayed wide.

Between contract gigs over the next few years I kept the unfinished
grid in a side folder. It was too unpolished to publish — there were
always five missing pieces — and I never had the focused stretch to
finish them. With AI-assisted overhauls over the last year, I was
finally able to do the surgery the package needed: replace the
external table dependency with the canvas-paint body it has today,
keep the original mental model (rows and columns are both data, edges
freeze, totals derive), and produce something I could share without
embarrassment. The Mark 85 timesheet that started all of this still
ships as one of the examples in this repo — the same shape, hosted on
the new engine.

> Five clients later, the same package now ships under multiple production
> apps. None of them are construction-shaped.

This package is the artifact of that journey: the table I wanted in
2018, written through 2025, for everyone who's hit the same wall.

## What's in here

```
flutter_grid_package/
├── lib/                           example app
│   ├── main.dart                  unified shell (side-nav, examples)
│   ├── examples/                  one file per example in the side-nav
│   ├── widgets/                   timesheet support code
│   ├── data/  models/  state/  theme/
└── packages/
    └── ultimate_grid/            the package itself
        ├── lib/                   public API (lib/ultimate_grid.dart barrel)
        └── test/                  unit + widget tests
```

## Run the demos

A single entry point with every example in a side-nav:

```bash
flutter pub get
flutter run -t lib/main.dart
# or in Chrome
flutter run -t lib/main.dart -d chrome
```

Pick from the sidebar:

| Example | What it shows |
|---|---|
| **Budget** | Personal monthly budget tracker — categories × months, frozen budget + YTD + % used (progress bar widget), merged Q1–Q4 header strip, bottom-frozen TOTAL row, double-tap to edit |
| **Timesheet** | Mark 85 — workers × cost codes, frozen worker / hours / OT / per-diem strips, computed totals, merged QTY band, widget-overlay cells for absent + per-diem |
| **Inventory** | Minimal shape — schema + `MapGridDataSource` + `GridController` + `UltimateTable`. 60 rows. |
| **Datagrid** | Records-as-rows with the full feature wiring: search, column menu (sort / filter / pin / hide / fit), drag-resize + drag-reorder, multi-range selection, Cmd/Ctrl+C copy, async / sync toggle |
| **Spreadsheet** | 5 regions × 12 months matrix with merged-cell Q1–Q4 header groups, bottom-frozen TOTAL row, row / column / select-all helpers |
| **Stress test** | Dropdown picks 10 k / 100 k / 1 M / **5 M** rows. Demonstrates the canvas-paint body scales — only ~30 visible rows are ever painted regardless of the total row count |

On narrow viewports the sidebar collapses into a `Drawer` accessed from
the app bar.

## Run the package tests

```bash
cd packages/ultimate_grid
flutter test
```

## Project philosophy

- **Phases land as isolated git commits.** Each phase commit, taken alone, is
  a clean, working state. Bugs found while testing a later phase are folded
  back into the commit that introduced them, never left as separate "fix"
  commits on top.
- **Performance is a hard requirement.** The package must scale to millions
  of cells without jitter on low-end devices. Phase 2's widget-based body is
  a stepping stone; Phase 3 replaces it with a custom `RenderObject` for
  direct cell painting.
- **The timesheet stays untouched.** It's the visual reference for the
  default `GridTheme` and the eventual end-to-end test that the package can
  host real, dense, editable grids.

## Docs

- **[docs/USAGE.md](docs/USAGE.md)** — usage guide. The five core
  types, the 9-region freeze layout, theming, sorting / filtering /
  search, selection, editing, cell merges, async data, performance
  tips. Start here if you're using the package.
- **[docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)** — internals. How a
  frame is drawn, the canvas-paint body, single-pass derived state,
  module map, recipes for adding new cell kinds / interactions.
- **[CHANGELOG.md](CHANGELOG.md)** — per-phase history.
- **[CONTRIBUTING.md](CONTRIBUTING.md)** — PR checklist, commit
  conventions, code style.

In-app, each example has a **View source** button at the top-right
of the content area — opens the example's `.dart` file in a
selectable, copyable viewer.

## Status

| Phase | What | State |
|-------|------|-------|
| 0 | Mark 85 timesheet scaffold + input polish | Shipped |
| 1 | `ultimate_grid` headless model + controller | Shipped |
| 2 | 9-region widget grid + simple demo | Shipped |
| 3 | Custom `RenderObject` body for millions-of-cells perf | Shipped |
| 4 | Selection, merging, column/row reorder + resize | Shipped |
| 5 | Header menu, filtering, sorting, search UI | Shipped |
| 6 | Port the Mark 85 timesheet onto the package | Shipped |
| 7 | Polish — a11y, RTL, keyboard nav, benchmark suite | Shipped |
| 8 | Async data source, drag-reorder, selection helpers, feature showcase | Shipped |
| 9 | UX polish — single-tap select / double-tap edit, mobile layouts, menu fixes | Shipped |
| 10 | Repaint-on-selection fix, embedded header (3-region h-sync), no resize on frozen cols | Shipped |
| 11 | Editor select-all-on-open, preserve cell borders during edit | Shipped |
| 12 | Right-frozen attaches to middle, single vertical scrollbar | Shipped |
| 13 | Single vertical+horizontal scrollbar w/ margin, framework default suppressed | Shipped |
| 14 | Scrollbars sit at the outer edges (past frozen columns/rows) | Shipped |
| 15 | Scrollbar gutters — dedicated strip outside table, no cell overlap | Shipped |
| 16 | Column-header popup feels like a regular Material menu | Shipped |
| 17 | Unified example app — side-nav, 5 examples incl. 5 M-row stress test | Shipped |
| 18 | Budget tracker example — relatable, merged cells + progress widgets | Shipped |
| 19 | In-app source viewer, USAGE guide, README origin story | Shipped |
| 20 | Publish prep (LICENSE, package CHANGELOG, example/, pubspec metadata) + 3 audit-pass bug fixes | Shipped |
