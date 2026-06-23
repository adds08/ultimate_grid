# ultimate_grid — showcase site

A bootstrap-table-style showcase for `ultimate_grid`, built as a Flutter web
app: a marketing **Home**, a **Docs** section (renders the repo `docs/*.md`),
an **Examples** gallery (live grids + their exact copy-pasteable source), and a
**Roadmap** (`docs/STATUS.md`). Every page is deep-linkable via `go_router`.

## Routes

| Route | Page |
|---|---|
| `/` | Home — hero, badges, benefit chips, CTAs, feature cards, install |
| `/examples` | Gallery overview (categorized left nav) |
| `/examples/:id` | A single example — description, "what this shows", live grid, source |
| `/docs` | Docs index (first available guide) |
| `/docs/:page` | A single doc page rendered from `docs/<page>.md` |
| `/roadmap` | `docs/STATUS.md` |

## Build / run

The Docs renderer and the CodePanels load the **real** repo docs and the
**real** demo source files via `rootBundle`. A small script snapshots them into
`assets/` so they ship as web assets (and so the code shown == the code that
compiled). Run it before building:

```bash
cd example
dart run tool/sync_assets.dart          # snapshot docs + screen sources into assets/
flutter run -d chrome                    # or:
flutter build web --base-href /ultimate_grid/
```

`assets/source/` and `assets/docs/` are generated (git-ignored); the single
authored copies live in `example/lib/screens/` and the repo `docs/` folder.

## CodePanel — zero code drift

`lib/site/code_panel.dart` shows Dart/YAML source in a syntax-highlighted,
copy-to-clipboard box. It loads the snippet from the actual `.dart` asset via
`rootBundle.loadString(...)`, optionally extracting the lines between
`// #docregion <name>` and `// #enddocregion <name>` markers. Because the shown
source is the same file that compiled into the running demo, the example code
can never drift from what's executing.

## Theme switcher & mobile preview

Each live example page carries a toolbar (Raw / Elegant / Professional preset
dropdown + accent swatches + a mobile-preview toggle). Choices are held in a
shared controller (`lib/site/grid_theme_controller.dart`) so they persist while
browsing, and the live grid re-keys to rebuild with the new `GridTheme`.
Presets live in `lib/screens/_themes.dart`.
