# Vitrify App — TODO

_Last reviewed: 2026-06-12_

> Feature-level plans live in [ROADMAP.md](ROADMAP.md) — this file tracks bugs,
> chores, and verification tasks.

## High priority

- [ ] **Test social sign-in on a real device** — the `vitrify://` scheme is now
  registered in `AndroidManifest.xml` and `Info.plist`, but the flow hasn't been
  exercised on Android/iOS hardware yet.
- [ ] **Test Facebook sign-in end-to-end** (Google is verified; Facebook is not).
- [ ] **Write real content for `assets/knowledge/glaze_fundamentals.md`** — still a
  "coming soon" placeholder; the Learn tab articles are hardcoded in
  `library_screen.dart`.
- [ ] **More test coverage** — `test/umf_calculator_test.dart` and
  `test/models_test.dart` exist now (22 tests). Still untested: mix gram-weight
  math in `mixes_repository.dart` (needs the repo decoupled from `ApiClient` or
  the math extracted), schedule segment validation, revision state logic.

## Medium priority

- [ ] **Regenerate `.g.dart` files with build_runner** (Flutter/Dart ARE on PATH in
  the dev shell despite what CLAUDE.md says) — or plan the Riverpod 3 migration;
  the hand-written files use `*Ref` types that are removed in 3.0.
- [ ] **Offline phase 2: write outbox** — reads now work offline (Tier 2);
  queued/replayed mutations need a design first (conflict story vs. the
  revision system).

## Low priority / cleanup

- [ ] Remaining `flutter analyze` style infos: `curly_braces_in_flow_control_structures`,
  `unnecessary_underscores`, `use_null_aware_elements` (~15 spots, mechanical fixes).
- [ ] Materials CDN URL in `materials_repository.dart` must be re-verified after any
  infra redeploy (and `assets/materials/v1.json` re-uploaded if the bucket was
  recreated).
- [ ] Backfill `displayName` on pre-2026-06-12 recipes/schedules (one-off script),
  or just let it fill in lazily as items are saved.

## Resolved (2026-06-12 sessions)

- [x] `isOwner` compile errors in both detail screens — `_isOwner` getter added.
- [x] Mobile OAuth callback — `vitrify://` registered in AndroidManifest
  (VIEW/BROWSABLE intent-filter + https `<queries>` entry) and Info.plist
  (`CFBundleURLTypes`).
- [x] Feed pagination — backend returns `nextCursor`; `FeedPage` model,
  cursor-aware repository, and infinite scroll in `feed_screen.dart`.
- [x] Schedule revision delete parity — `deleteRevision` in schedules repository,
  delete icon + confirm dialog in the schedule revision history sheet.
- [x] Flutter API deprecations — `value:`→`initialValue:` (×7),
  `RadioGroup` migration in settings, `onReorder`→`onReorderItem` (×2, manual
  index adjustment removed per new semantics).
- [x] `dart:html` → `package:web` (`web_storage_web.dart`, `web_utils_web.dart`;
  `web: ^1.1.0` added).
- [x] Unit tests added for UMF calculator, zone detection, suggestions, and
  model JSON parsing (PascalCase/camelCase compat); boilerplate widget_test removed.
- [x] `assets/knowledge/glaze_fundamentals.md` — verified it exists.
- [x] `_isEditingLatest` warnings — annotated with `// ignore: unused_element`
  and an explanatory comment (kept deliberately per CLAUDE.md).
- [x] Backend persists `tileName` — confirmed.
