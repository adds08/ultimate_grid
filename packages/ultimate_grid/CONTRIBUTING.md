# Contributing to ultimate_grid

Thanks for considering a contribution.

This package is part of the
[flutter_grid_package](https://github.com/adds08/flutter_grid_package)
monorepo. The full contributor guide — local setup, PR checklist, commit
conventions, design rules, code style — lives at the repo root:

**→ [CONTRIBUTING.md](https://github.com/adds08/flutter_grid_package/blob/main/CONTRIBUTING.md)**

## TL;DR for package changes

```bash
cd packages/ultimate_grid
flutter pub get
flutter analyze       # must report "No issues found"
flutter test          # must be all green (77 tests at 0.1.0)
```

Then run the example app to eyeball your change:

```bash
cd example
flutter run -d chrome
```

## Hard rules inside `lib/`

- No `Uint64List` / `Int64List` — they crash on Flutter web. Use
  `Uint32List` for all bitsets.
- No widget tree per cell on the body's paint path. Cells render via
  `RenderUltimateBody`'s `ParagraphCache`; widgets are reserved for
  headers, frozen strips, the column menu, and the single active
  editor overlay.
- No per-cell allocations on the hot paint path.
- No `dart:io` imports — keep the package web-safe.
- Every public symbol gets a `///` doc comment. Pana doc-coverage is
  part of the package's pub.dev score, and the comments surface as IDE
  hover hints for consumers.

## Where to add things

| Adding… | Goes in… |
|---|---|
| A new `CellValue` subtype | `lib/src/model/cell_value.dart` (sealed family) |
| A new `FilterPredicate` helper | `lib/src/filter_sort/filters.dart` |
| A new cell renderer | `lib/src/cells/default_renderers.dart` + register |
| A theme preset | propose it; the package keeps one default + composability via `InteractionPolicy` |
| A new public type | also export from `lib/ultimate_grid.dart` (barrel) |
| A test | `test/` — one feature per file, matching the existing pattern |

## Reporting bugs

[Open an issue](https://github.com/adds08/flutter_grid_package/issues)
with:

- Flutter version (`flutter --version`).
- Target platform (web / macOS / iOS / Android / Windows / Linux).
- A minimal repro — ideally a failing test in the package's `test/`
  directory.

## License

MIT — see [LICENSE](LICENSE). Contributions are released under the same
license.
