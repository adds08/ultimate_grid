# Contributing

Thanks for considering a contribution to **Ultimate Table by CodeBigya**.
This repo is the home of the package and a real-world example app (the
Mark 85 timesheet). Both move together.

If you're new here, read **`docs/ARCHITECTURE.md`** first — it explains
how the data flow, the 9-region freeze layout, the paragraph-cached
custom render object, and the phase-per-commit policy work.

## What we welcome

- Bug reports with a minimal repro (a failing test is gold).
- New features that fit the design rules (zero per-cell cost when off,
  no widget tree per body cell, web-compatible). Discuss large changes
  in an issue first — the package's surface is small on purpose.
- Documentation, examples, theming presets.
- Tests filling gaps in the existing suite.

## What we'd rather avoid

- Hard dependencies on `material` from inside `packages/ultimate_grid/lib/src/`
  (we only build on `widgets` + `services` + `painting`). One file
  (`column_menu.dart`) is a deliberate `material` exception; everything
  else should stay `widgets`-only.
- Per-cell allocations on the hot paint path.
- `Uint64List` / `Int64List` — they crash on Flutter web.
- API additions without a test and a CHANGELOG entry.

## Local setup

```bash
git clone <repo>
cd flutter_grid_package
flutter pub get                                  # host app
cd packages/ultimate_grid && flutter pub get    # package
```

You'll need Flutter ≥ 3.24 and Dart ≥ 3.9. Both are pinned in the
relevant `pubspec.yaml`s.

## Run

```bash
# Host repo: side-nav app with every example (timesheet, budget, datagrid,
# spreadsheet, stress test).
flutter run -t lib/main.dart
flutter run -t lib/main.dart -d chrome    # web

# Package's own example gallery (the four demos shipped with the package
# on pub.dev: inventory, financial sheet, async paging, search & filters,
# plus a theme switcher and mobile-preview toggle).
cd packages/ultimate_grid/example
flutter run -d chrome
```

## Test + lint

Always run the package tests + analyzer before opening a PR:

```bash
cd packages/ultimate_grid
flutter analyze    # must report "No issues found"
flutter test       # must be all green
```

The root app also has a small widget test:

```bash
cd ../..
flutter analyze && flutter test
```

## Commit style

We commit **one commit per phase**. The repo's per-phase commits stand
on their own — bug fixes for code introduced in phase N go into phase N,
not as a separate "fix" commit on top.

For day-to-day PR work this means: if you fix a bug that lives in an
older phase commit, the convention is to call it out in the PR
description; the reviewer decides whether to fold or to ship as a
regular bug-fix commit. Most one-off fixes ship as their own commit
with a clear "fix: …" subject.

Commit subject convention:

- `Phase N — title` — a new phase landing.
- `fix: …` — a regular bug fix on top of the latest phase.
- `docs: …` — README / docs.
- `refactor: …` / `chore: …` — internal-only.

Use HEREDOC commits for multi-paragraph messages so the body formats
cleanly. Subject line should fit on one screen — push detail into the
body.

## Pull-request checklist

- [ ] `flutter analyze` clean (package + host app).
- [ ] `flutter test` green (package + host app).
- [ ] If you added a public type to the package, it's exported from
      `packages/ultimate_grid/lib/ultimate_grid.dart`.
- [ ] If you changed behavior, there's a new test (or a modified one)
      that would have failed before your change.
- [ ] `CHANGELOG.md` has an entry under the current phase's `Added /
      Changed / Fixed` section, **OR** the PR is folded into an in-flight
      phase commit.
- [ ] No `Uint64List`, no `dart:io` inside `packages/ultimate_grid/lib/`.
- [ ] If the change touches paint, you've confirmed the demo still runs
      cleanly on Chrome with no console errors.

## File layout reminders

- `packages/ultimate_grid/lib/` — the publishable package.
- `lib/` — example app (timesheet + simple demo).
- `docs/` — architecture + design notes (this folder is for humans,
  not generated docs).

## Code style

- Dart formatter defaults (`dart format .`). No special config.
- Doc comments on every public class, method, getter, setter, field. If
  the name is self-explanatory ("`backgroundColor`"), one line is fine.
  If it has a non-obvious invariant ("`offsets[i+1] - offsets[i] ==
  widths[i]`"), say so.
- `@immutable` on value types.
- Sealed classes for closed unions (`CellValue`).
- No emojis in code or docs unless the user explicitly asks.

## License

This project is **MIT-licensed** — see [packages/ultimate_grid/LICENSE](packages/ultimate_grid/LICENSE).
By contributing you agree your contribution is released under the same
MIT license.

## Code of conduct

Be kind. Disagree on the technical merits, not the person. CodeBigya
maintainers reserve the right to remove comments / PRs / users that
don't follow this.
