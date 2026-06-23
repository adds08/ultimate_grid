# Ultimate Grid — Master Initiative Prompt

> Paste this into a fresh Claude Code session **opened on the `flutter_grid_package`
> workspace** to drive the whole initiative. It is written so an agent can execute it
> phase-by-phase. Everything below is grounded in the actual repo state (scanned
> 2026-06-23), not assumptions.

---

## 0. Snapshot — what already exists (do not re-derive)

- **Package:** `ultimate_grid`, version `0.1.1`. **Already published** on pub.dev
  (publisher `codebigya.com`, verified; 160 pub points, 4 likes, ~40 downloads).
  → The pub package name is **already correct**. Do **not** rename the package.
- **GitHub repo / local folder:** `adds08/flutter_grid_package`. ← this is the only
  thing that actually needs renaming to `ultimate_grid`.
- **Branding:** "Ultimate Grid by CodeBigya".
- **Engine (lib/src):** headless model (`GridSchema` + `GridDataSource` +
  `GridController`), sealed `CellValue` (Empty/Number/Text/Bool/Date/Formula/Custom),
  9-region freeze, custom `RenderUltimateBody` canvas-paint body with a `ParagraphCache`
  LRU (scales to ~5M rows), selection + TSV clipboard, cell merges (`Uint32List` bitset,
  web-safe), single-pass `ViewPipeline` (filter→sort→search), column menu + filter dialog,
  search field, drag-resize + drag-reorder columns, async paging source, pluggable
  `CellRendererRegistry`, widget cells, `GridTheme` with per-column/row/cell overrides
  via `InteractionPolicy`. **Framework-agnostic** — depends only on `flutter/widgets.dart`
  (no Material/Cupertino in the library).
- **Tests:** 18 test files under `test/` (controller, layout, pipeline, selection,
  clipboard, merge, paragraph cache, widget, keyboard nav, benchmark, …).
- **Example app (`example/`):** a polished Flutter **web** gallery — side-nav shell,
  10 demo screens, theme dropdown (Raw / Elegant / Professional), 6 accent swatches,
  mobile-preview toggle, collapsible sidebar. **This is the seed of the landing page.**
  One screen (`self_created_example.dart`, sidebar label "Self") is a dev scratch screen.
- **Missing today:** no `.github/workflows/` (no CI → no build badge yet); no deployed
  compiled demo (no GitHub Pages); no `docs/` folder; README has no badges; no
  roadmap/limitations doc.
- **Recent churn (git log):** footer overflow, frozen-column borders, layout assertions
  — i.e. layout/freeze/footer is the area most recently touched. Regression-test there.

## 1. Goal

Turn `ultimate_grid` into a flagship, self-explaining Flutter grid package:
one canonical source of truth for all information, a badge-rich README that works
identically on **pub.dev and GitHub**, a tiered docs set (simple → advanced), and a
**bootstrap-table-style live showcase site** (built in Flutter) with copy-pasteable,
always-in-sync code samples for every feature — plus an honest roadmap and limitations
page. No information should live in two places.

## 2. Guardrails (read before touching anything)

- **Single source of truth.** All prose docs live in `docs/`. `README.md` is the entry
  point and is rendered **verbatim by both GitHub and pub.dev** — so it is the one file
  that must carry badges + a 60-second pitch + links out. The showcase site renders the
  **same** `docs/*.md` files (load as assets via `flutter_markdown`) and the **same**
  example source files — never a hand-copied second version. The pub.dev API reference is
  auto-generated from dartdoc comments; don't duplicate API prose in markdown.
- **Don't refactor working UI / engine for marginal gain.** The engine is published and
  passing. Be conservative: add docs, examples, badges, CI, rename — don't rewrite the
  render path. Fixes only for real, reproduced defects.
- **Framework-agnostic library stays framework-agnostic.** `lib/` must keep importing only
  `flutter/widgets.dart` (no Material). The example/site app may use Material freely.
- **Web-safe.** Bitsets use `Uint32List` (no `Uint64List` on web). Anything new follows suit.
- **Conventional commits**, one logical change per commit. Branch off `main`; don't push
  or publish without explicit approval.

## 3. Workstreams

Execute in order. Each has acceptance criteria. Open a TODO list and check items off.

### A. Rename `flutter_grid_package` → `ultimate_grid` (repo + folder only)
1. `gh repo rename ultimate_grid` (GitHub auto-redirects the old URL — existing clones keep
   working). Then `git remote set-url origin https://github.com/adds08/ultimate_grid.git`.
2. Update every hardcoded `flutter_grid_package` reference: `pubspec.yaml`
   (`homepage` / `repository` / `issue_tracker`), `README.md`, `example/README.md`,
   `CONTRIBUTING.md`, badge URLs. Grep: `grep -rn flutter_grid_package .`
3. (Optional, do last) rename the local folder to `ultimate_grid` and re-point the
   IDE/workspace entry. Note this is a standalone workspace, not part of the monorepo.
4. **Do not** bump the pub package name — it is already `ultimate_grid` and published.
- ✅ **Done when:** `grep -rn flutter_grid_package .` returns only historical CHANGELOG
  mentions (if any), `gh repo view` shows `ultimate_grid`, and pub links resolve.

### B. Health pass + fix real issues
1. Baseline: `flutter analyze` (must be zero issues), `flutter test` (all 18 files green),
   `cd example && flutter build web` (must compile clean — catches web-only breakage).
2. Targeted regression sweep on the recently-churned areas: footer height, frozen-column
   borders, 9-region freeze under column resize + reorder, merges that survive sort/filter,
   theme switching (Raw/Elegant/Professional × accent) — exercise each demo manually.
3. Remove the `self_created_example.dart` scratch screen and its sidebar entry, OR promote
   it into a real, documented example. Don't ship "Self" in a flagship gallery.
4. Record anything found (and anything deferred) in `docs/STATUS.md` (see workstream F) —
   never leave a known defect undocumented.
- ✅ **Done when:** analyze clean, tests green, web build succeeds, scratch screen gone,
  every open defect is listed in `docs/STATUS.md` with a severity.

### C. README + badges (one file, works on pub.dev AND GitHub)
Top of `README.md`, immediately under the H1, add a badge row. Use these exact shields
(they pull **live** from pub.dev + GitHub, so stars/points/likes auto-update everywhere):

```markdown
# Ultimate Grid

[![pub version](https://img.shields.io/pub/v/ultimate_grid.svg)](https://pub.dev/packages/ultimate_grid)
[![pub points](https://img.shields.io/pub/points/ultimate_grid)](https://pub.dev/packages/ultimate_grid/score)
[![pub likes](https://img.shields.io/pub/likes/ultimate_grid)](https://pub.dev/packages/ultimate_grid/score)
[![publisher](https://img.shields.io/pub/publisher/ultimate_grid)](https://pub.dev/publishers/codebigya.com)
[![CI](https://github.com/adds08/ultimate_grid/actions/workflows/ci.yml/badge.svg)](https://github.com/adds08/ultimate_grid/actions/workflows/ci.yml)
[![GitHub stars](https://img.shields.io/github/stars/adds08/ultimate_grid?style=flat&logo=github)](https://github.com/adds08/ultimate_grid/stargazers)
[![license: MIT](https://img.shields.io/github/license/adds08/ultimate_grid)](LICENSE)
```

README structure (keep it tight — it links out, it does not contain everything):
1. H1 + badge row + one-line tagline + a hero GIF/screenshot of the grid.
2. **🔗 Links bar:** **Live demo & examples** → showcase URL · **Docs** → `docs/README.md`
   · **API reference** → pub.dev/documentation · **Roadmap** → `docs/STATUS.md`.
3. 60-second pitch (3–4 bullets: perf, freeze, framework-agnostic, theming).
4. Install snippet + 15-line "minimal grid" quick start (the one already in README is good).
5. **Feature matrix with checkmarks** (✅ shipped / 🚧 in progress / 🗓️ planned) — pulled
   from `docs/STATUS.md` so it never drifts.
6. "Why this exists" — keep but **collapse** behind a `<details>` so it doesn't bury the docs.
7. Constraints (1 short section) → link to `docs/STATUS.md` for the full list.
8. License.
- ✅ **Done when:** all badges render on both the GitHub README and the pub.dev page; every
  link resolves; the same README.md is what pub.dev shows (no separate pub README).

### D. Docs — single source of truth (`docs/`)
Create `docs/` with a master index and tiered guides (simple → advanced). Mirror the
monorepo's "docs are the source of truth" model. The showcase site renders these same files.

```
docs/
├── README.md                 # master index + reading order
├── getting-started.md        # install, minimal grid, run the example
├── concepts.md               # schema vs source vs controller vs view; the 9 regions
├── columns.md                # width, freeze/pin, resize, reorder, hide, alignment, headers
├── cells-and-rendering.md    # CellValue kinds, default renderers, custom registry, widget cells
├── data-sources.md           # MapGridDataSource, AsyncGridDataSource paging, sparse data, merges
├── interaction.md            # selection, clipboard TSV, in-cell editor, keyboard nav, policies
├── sort-filter-search.md     # column menu, Filters.*, ViewPipeline, search highlight/filter
├── theming.md                # GridTheme fields, mark85, presets, per-col/row/cell overrides, accent
├── performance.md            # canvas paint, ParagraphCache, 5M-row stress notes, web caveats
├── recipes.md                # advanced: build-your-own renderer, totals row, custom column menu UI
└── STATUS.md                 # limitations, known issues, roadmap (checkmarks) — see F
```
Each guide goes **simple → advanced**: a "smallest working example" up top, then options,
then edge cases. Cross-link with relative links. API specifics defer to dartdoc/pub.
- ✅ **Done when:** `docs/README.md` links every guide in a sensible reading order; no
  `.md` docs exist in `lib/` or `example/` except thin pointers; each guide opens with a
  runnable minimal snippet.

### E. The showcase site (bootstrap-table-style) — see §4 for the full spec
Evolve `example/` into the showcase, or add a sibling `site/` app that depends on the
local package. Recommendation: **evolve `example/`** (pub.dev wants a working `example/`,
and the gallery/theme-switcher already exist). Add routing, a landing/hero page, docs
pages (rendered from `docs/*.md`), and the live-example-with-copyable-code pattern.
- ✅ **Done when:** §4 acceptance criteria are met and the site is deployed (workstream G).

### F. Roadmap + limitations (`docs/STATUS.md`)
A single living file that the README feature-matrix and the site Roadmap page both read
from. Sections: **Shipped ✅**, **In progress 🚧**, **Planned 🗓️**, **Known limitations**,
**Known issues** (from workstream B). A starter version has been written — keep it current.
- ✅ **Done when:** every feature claim in README/site traces back to a row here.

### G. CI + deploy (unlocks the build badge + the live demo link)
1. `.github/workflows/ci.yml`: on push/PR → `flutter analyze`, `flutter test`,
   `dart format --set-exit-if-changed`, `dart pub publish --dry-run`, and
   `cd example && flutter build web`.
2. `.github/workflows/pages.yml`: on push to `main` → build the showcase web app
   (`flutter build web --base-href /ultimate_grid/`) and deploy to GitHub Pages.
   Later, when the custom domain is ready, add a `CNAME` and switch `--base-href /`.
3. Put the resolved Pages URL into the README links bar and `homepage`-adjacent docs.
- ✅ **Done when:** the CI badge is green, Pages serves the showcase, README links to it.

---

## 4. Landing / showcase site spec (the bootstrap-table reference, detailed)

**Reference behavior to replicate** (from `bootstrap-table.com` + `examples.bootstrap-table.com`):
a marketing **home** (hero, feature highlights, install, big "View Examples" CTA), a
**docs** section (Getting Started → Usage → Options/Columns/Methods/Events API), and an
**examples** site where a left nav lists categorized examples and **each example page shows
a short description, a live working table, and the exact copy-pasteable source** for it.
We map that 1:1 onto a single Flutter web app.

### 4.1 Tech & structure
- **One Flutter web app** (the evolved `example/`) using `go_router` so every page/example
  has a **shareable deep link** (e.g. `/examples/columns/freeze`) — bootstrap-table does this.
- **`docs/*.md` rendered in-app** via `flutter_markdown` (loaded from `rootBundle`), so the
  site's docs == the repo's docs. Declare `docs/` and the example source files as assets in
  `example/pubspec.yaml`.
- **`CodePanel` widget** = the core reusable piece: a syntax-highlighted, scrollable code
  box with a **Copy** button and a filename caption. Use `flutter_highlight` (or
  `re_highlight`) for Dart highlighting. **Critical:** `CodePanel` loads the snippet from
  the **actual example `.dart` file** via `rootBundle.loadString(...)` (optionally between
  `// #docregion name` / `// #enddocregion` markers, like Flutter's own docs). This means
  **the code shown is the code that's running** — zero drift, zero redundant copies. This
  directly satisfies "every information tracked from the same place."
- **Responsive:** reuse the existing mobile-preview + collapsible-sidebar machinery.
- **Theme switcher** already exists — surface it on every live example so visitors can flip
  Raw/Elegant/Professional + accent and watch the live grid restyle (great theming demo).

### 4.2 Information architecture (top nav)
`Home` · `Docs` · `Examples` · `API` (→ pub.dev/documentation) · `Roadmap` · GitHub / pub.dev icons.

#### Home (hero)
- Big title "Ultimate Grid", tagline, the **same badge row** as the README (use shields
  images), a looping hero capture of a large grid scrolling + freeze + selection.
- 3–4 headline stat/benefit chips: "5M rows", "9-region freeze", "Zero-widget-per-cell paint",
  "Framework-agnostic".
- Primary CTAs: **View Examples**, **Get Started**, **pub.dev**, **GitHub** (star button).
- A feature-highlight grid of cards (icon + name + one line), each linking to its example.
- Install block (`CodePanel` with the pubspec line) + the minimal-grid snippet.

#### Docs (rendered from `docs/*.md`)
Left nav mirrors the `docs/` file list (§3-D). Right pane renders the markdown. A "next/prev"
footer enforces the simple→advanced reading order.

#### Examples (the bootstrap-table examples clone — the centerpiece)
Left nav, **categorized**, each leaf = one example page (`description → live table → CodePanel`):

- **Getting Started:** Minimal grid · Schema + data source + controller · Embedding in a page.
- **Columns:** Freeze / pin (start & end, non-contiguous) · Resize (drag handle) · Reorder
  (long-press drag) · Hide / show · Width & alignment · Custom header.
- **Cells & Rendering:** Cell kinds (Number/Text/Bool/Date) · Default renderers · Custom
  renderer via `CellRendererRegistry` · **Widget cells** (checkboxes/buttons in a column) ·
  Number/date formatting.
- **Data:** `MapGridDataSource` · **Async paging** (100k rows, on-demand, latency slider) ·
  Large/sparse data · **Cell merges** (`MergeRange`, quarter headers).
- **Interaction:** Rectangle selection · Shift / Cmd-Ctrl extend & non-contiguous ·
  **Copy as TSV** (paste into Excel/Sheets live) · In-cell editor (double-tap, Enter/Esc) ·
  Keyboard navigation · `InteractionPolicy` (per-cell behavior, `PredicatePolicy`).
- **Sort / Filter / Search:** Column menu (`showUltimateColumnMenu`) · `Filters.*` predicates ·
  Filter dialog per column kind · `UltimateSearchField` Highlight ↔ Filter.
- **Theming:** `GridTheme.mark85` · Three presets · Per-column / per-row / per-cell overrides ·
  Grid-line toggles · Accent swatches · "Build your own theme".
- **Real-world demos** (the existing screens, reframed): Inventory · Financial sheet ·
  Office Time Log · Budget tracker · Datagrid · Spreadsheet · **Stress test (up to 5M rows)**.
- **🗓️ Planned** (greyed, with 🗓️ badge, no live demo — shows the roadmap in-context):
  CSV/Excel export · pagination widget · row grouping / tree rows · frozen totals helpers ·
  RTL · screen-reader accessibility · column virtualization for ultra-wide grids.

Each example page layout (top → bottom): **breadcrumb + title**, **1–2 sentence description**,
**"What this shows" bullets**, **live interactive grid**, **`CodePanel`** (the real source,
copy button), **"See also" links** to related examples/docs.

#### Roadmap
Render `docs/STATUS.md` (or a checkmark table built from it): Shipped ✅ / In progress 🚧 /
Planned 🗓️, plus Known limitations & issues. Same data as the README matrix — one source.

### 4.3 Acceptance criteria for the site
- ✅ Every shipped feature in `docs/STATUS.md` has at least one live example page.
- ✅ Every example page's `CodePanel` is loaded from the real running source (no inline string
  duplicates). Changing the demo changes the shown code automatically.
- ✅ Deep links work (`/examples/...`), back/forward navigation works, mobile layout works.
- ✅ Docs pages render the actual `docs/*.md` files.
- ✅ Deployed to GitHub Pages; README + pub.dev link to it; ready to swap to a custom domain.

---

## 5. Roadmap (mirror of `docs/STATUS.md` — keep in sync)

Maintain the authoritative list in `docs/STATUS.md`. README + site read from it.

## 6. Definition of done (whole initiative)

- [ ] Repo + folder renamed to `ultimate_grid`; all links updated; pub package untouched.
- [ ] `flutter analyze` clean, all tests green, `example` web build green, scratch screen gone.
- [ ] README has the live badge row + links bar + feature matrix; renders identically on
      pub.dev and GitHub.
- [ ] `docs/` is the single source of truth; tiered simple→advanced; no stray `.md` in lib/example.
- [ ] Showcase site live on GitHub Pages: home + docs + categorized examples (each with live
      grid + copyable real source) + roadmap; deep-linkable; mobile-friendly.
- [ ] CI workflow green (analyze/test/format/publish-dry-run/web-build); Pages deploy workflow.
- [ ] `docs/STATUS.md` lists every shipped feature, limitation, known issue, and planned item;
      README matrix + site roadmap both derive from it.
- [ ] A patch version bump + CHANGELOG entry; publish only on explicit approval.
