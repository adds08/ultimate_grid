## What this changes

<!-- One or two sentences. What does this PR do, and why? -->

## How to verify

<!-- Steps a reviewer can run to see your change. If you added/changed
     behavior, point at the test that would have failed without your fix. -->

## Pre-merge checklist

- [ ] `cd packages/ultimate_grid && flutter analyze` — no issues.
- [ ] `cd packages/ultimate_grid && flutter test` — all green.
- [ ] Public API change → exported from `lib/ultimate_grid.dart`.
- [ ] Public API change → `///` doc comment present.
- [ ] Behavior change → test added or modified that locks the new
      behavior in.
- [ ] No `Uint64List` / `Int64List` / `dart:io` introduced under
      `packages/ultimate_grid/lib/`.
- [ ] No widget tree per cell on the body's paint path.
- [ ] `CHANGELOG.md` entry under the next-up version (or folded into
      an in-flight phase commit, per `CONTRIBUTING.md`).

## Notes for reviewers

<!-- Anything subtle, design tradeoff, follow-up you intentionally
     deferred. Empty is fine if there's nothing to flag. -->
