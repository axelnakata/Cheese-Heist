# Cheese Heist — Claude Code guide

AR gear-ratio learning app for LEGO Technic robotics classes. iPadOS, SwiftUI + RealityKit
+ ARKit + Vision/Core ML.

Two specs, and they are layered:

- **`Docs/PRD-CheeseHeist-v1.md`** — the parent agreement: scope, physics, file layout,
  engineering conventions. Section references written bare (`§8.4`) point here.
- **`Docs/PRD-Level1-v1.md`** — the Level 1 implementation spec. Its §10 lists nine
  places where it **overrides** the parent PRD; where they disagree, Level 1 wins.
  Referenced as `L1 §6.1`.
- `Docs/implementation_plan_lv1.md` — the build order that produced the current tree.

When this file and a PRD disagree, the PRD wins. When the code and a PRD disagree,
read the header comment on the file first — the load-bearing invariants are documented
at the top of the type that owns them, usually with the bug that motivated them.

---

## Build & run

`xcode-select` on this machine points at CommandLineTools, so **everything** —
`xcodebuild` *and* `swiftlint` — needs an explicit toolchain. Without it SwiftLint dies
with `Loading sourcekitdInProc.framework … failed`.

```sh
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer

xcodebuild -project 'Cheese Heist.xcodeproj' -scheme 'Cheese Heist' \
  -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M5)' build

# The whole unit-test suite runs on the simulator — no device needed.
xcodebuild -project 'Cheese Heist.xcodeproj' -scheme 'Cheese Heist' \
  -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M5)' test

swiftlint lint --quiet    # currently clean
```

- Deployment target **iOS 18.0**, Swift 5. Installed simulator runtime is 26.3.1.
- The app is **landscape-locked, iPad-only** (`TARGETED_DEVICE_FAMILY = 2`). Both were
  done for Level 1 and the detection pipeline depends on the orientation lock — see
  invariant 5 below.
- Real AR work needs an **iPad Pro with LiDAR**. There is no non-LiDAR path (`§5`);
  `AppServices.boot()` routes to `UnsupportedDeviceView` instead. The simulator cannot
  exercise any of the AR, Vision or depth code.
- `swiftlint` is installed at `/opt/homebrew/bin/swiftlint` and runs as the first build
  phase of the app target. It is the `§8.4` size gate — see below.

## Testing

`CheeseHeistTests` is a real target using **Swift Testing** (`import Testing`,
`@Test`, `#expect`) with `@testable import Cheese_Heist` — note the underscore.
22 suites, all pure and deterministic: physics, the phase machine, the crane solver's
geometry, depth clustering, role assignment, lift running, layout.

The whole suite passes on the simulator today. Physics and phase-machine tests are a
blocking merge requirement (`§15.1`) — anything touching `Core/Gear/` or
`Level1PhaseMachine` needs a test in the same change.

## Xcode project mechanics — read before adding files

Two targets (`Cheese Heist`, `CheeseHeistTests`), and **both** use Xcode 16
file-system-synchronized root groups (`objectVersion = 77`).

- **New files under `Cheese Heist/` or `CheeseHeistTests/` join their target
  automatically.** Do not edit `project.pbxproj` to add a source file — just create it.
  (Adding a *target* still needs a hand-edit; that is how `CheeseHeistTests` got there.)
- The flip side: *every* file in those trees gets bundled, including dotfiles. Empty
  scaffold folders are held open by `.gitkeep`, listed as `membershipExceptions` in
  `PBXFileSystemSynchronizedBuildFileExceptionSet`. **If you add a `.gitkeep` to a new
  empty folder, add it to that exception list too**, or the build fails with "Multiple
  commands produce …/.gitkeep". Delete the `.gitkeep` once the folder holds a real file.
  A stale exception entry is harmless; a missing one breaks the build. (There are more
  entries in the list than `.gitkeep` files on disk — that is expected.)

**`Info.plist`** lives at the repo root, outside the synced group, and holds only
`UIAppFonts` — `GENERATE_INFOPLIST_FILE = YES` has no build-setting mapping for it.
Everything else comes from `INFOPLIST_KEY_*` settings and is merged in at build time.
Add new plist keys as `INFOPLIST_KEY_*` build settings where one exists.

## Resources — names that must not change

`Cheese Heist/Resources/`

| Asset | Rule |
|---|---|
| `ML/GearDetectorModel.mlpackage` | **Keep this exact name.** Xcode generates a Swift class named after the model file; naming it `GearDetector` collides with the hand-written `GearDetector` type — *"Multiple commands produce GearDetector.stringsdata"*. |
| `3DModels/Gears/gear_8.usdz`, `gear_24.usdz`, `gear_40.usdz` | Filenames must match `GearType.modelName`. |
| `3DModels/Props/Cheese.usdc` | |
| `Assets.xcassets` | `cheese_star`, `crane_guidance`, and four mouse poses. |

The YOLO11n model's class labels are `gear_8t` / `gear_24t` / `gear_40t` and must match
`names` in the training set's `data.yaml` — see the map in `GearDetector`. Note the
labels carry the `t` and the model files do not.

## Fonts — the names are not the filenames

`UIAppFonts` takes **filenames**; `UIFont(name:)` takes **PostScript names**. They differ:

| File | PostScript name |
|---|---|
| `Mickies.otf` | `MickiesRegular` — no hyphen |
| `Nunito-Regular.ttf` | `Nunito-Regular` |
| `Nunito-Bold.ttf` | `Nunito-Bold` |
| `Nunito-ExtraBold.ttf` | `Nunito-ExtraBold` |

The PRD's `§7.3` sample code says `Mickies-Regular`, which does not resolve. `AppFont.Family`
carries the verified names. A wrong name falls back to San Francisco *silently* — that is
risk R-07, so `AppFontResolver` traps in debug and `CheeseHeistApp.init` calls
`verifyRegisteredFonts()` at launch. If it fires, check the PostScript name first.

---

## Architecture

MVVM, `@Observable` (never `ObservableObject` + `@Published`).

- **Model** — pure data. No logic, no formatting, no networking.
- **View** — SwiftUI only. Binds to its ViewModel and composes components. No business logic.
- **ViewModel** — presentation logic and routing only. Talks to Managers/Services.
- **Manager / Service** — one manager, one job.

Two rules decide where a file goes:

1. **"Could Level 2 want this?"** (`§8.5`) Yes unchanged → `Core/` or `Commons/`. Yes with
   different parameters → `Features/Gameplay/Shared/`. Genuinely no → `Level1/`.
   This test was applied honestly during the Level 1 build and moved almost everything
   out: **`Shared/` owns components and mechanics; `Level1/` owns composition and
   choreography.** Nothing in `Level1/` draws anything or computes anything. What stayed
   and why is `L1 §9.1`.
2. **Views compose, they do not draw.** A `Shape`, `Path`, gradient or bespoke
   `ViewModifier` inside a View moves to `Commons/Components/`.

### Size limits — CI gate, not a convention (`§8.4`)

| Artefact | Warn | **Fail** |
|---|---|---|
| Swift file | 150 | **200** |
| View `body` | 40 | **60** |
| ViewModel type body | 120 | **160** |
| Function | 30 | **50** |
| Closure body | 25 | **40** |
| Cyclomatic complexity | 8 | **12** |
| Type nesting | 2 | — |

`file_length` has `ignore_comment_only_lines: true` (`L1 §4.1`) — the rationale comments
carry as much value as the code and must not be squeezed out by the budget. That is why
several files are 200+ raw lines and still pass.

One type per file. Protocol conformances and big extensions go in their own file
(`Level1ViewModel+DetectionObserver.swift`, `GameplaySceneCoordinator+Update.swift`).
**The fix is always to split, never to raise the limit.** A ViewModel nearing 160 lines
is doing two jobs — extract a collaborator.

---

## Design system

`Commons/DesignSystem/` — tokens, hex extensions, layout scale. `Commons/Components/` —
buttons, chips, dialogue, hints, overlays.

**No view may contain a colour literal, a font name, a numeric font size, a corner radius
or a magic spacing number.** All of those are tokens; a PR containing one is rejected.
`.swiftlint.yml` has four custom rules that fail the build on the common offenders.

- Colour: views use **`AppColor`** semantic tokens only. `Palette` is raw hex and nothing
  but `AppColor` may touch it — enforced by the `palette_outside_appcolor` rule.
- **Role colours are `roleDriver` = sky blue, `roleFollower` = crust amber.** The parent
  PRD `§7.2` has them reversed; Figma is self-consistent across all 14 Level 1 frames and
  decision `L1 D-1` flipped the tokens. Do not "fix" them back.
- Type: `.appText(AppFont.title)`. `View+TextStyle.swift` is the only place line-height
  maths exists — `lineSpacing` is additive and cannot be negative, so `largeTitle` clamps
  to 0 and takes default leading. Do not reach for `AttributedString` to force it.
- Geometry: `AppSpacing` / `AppRadius` / `AppStroke`; motion: `AppDuration`; fills:
  `AppGradient`. A component's own Figma dimensions (`210 × 78.14`) go in a
  `private enum Metric` in that component's file.
- **Scale:** every Figma frame is 1366 × 1024 pt. Read `@Environment(\.layoutScale)` and
  multiply once. **No view computes its own scale factor** — `.providesLayoutScale()` is
  applied at the app root and nowhere else.
- Every component ships a `#Preview` on both `.parchment` and `.cameraFeed`
  (`PreviewBackdrop`). Preview-driven development is mandatory (`§8.6`): a screen that
  cannot be previewed cannot be reviewed. AR-dependent views take `any CraneSceneProviding`
  so `PreviewData/MockCraneScene` can stand in.

---

## The Level 1 spine

Level 1 is built and playable. Read `L1 §6` before touching any of it; this is the shape.

**`AppServices` is the composition root** (`App/AppServices.swift`). It owns
`ARSessionManager`, `GearDetectionService`, `AppRouter` and `SceneUpdateTicker`, and it
is created *above* the router so the AR session outlives every route change.

**Two clocks, and separating them is the point:**

- **Fast path, ~6 Hz** — `detection.onTrackingUpdate` builds the scene on the first
  locked pair, then only feeds later measurements to `CraneAlignmentFilter.correct`,
  which *sets a target and nothing else*. Bypasses Observation entirely.
- **Render clock, 60 Hz** — `SceneUpdateTicker` fans out in a fixed order that must not
  be reordered: `smoothAlignment` → `LiftRunner.advance` → `refreshProjection`.
  Alignment first so physics writes into an already-corrected frame; projection last so
  the SwiftUI overlay reads the same frame it draws.
- A slow 2 Hz `@Observable` path drives the HUD, translated to events by
  `Level1ViewModel+DetectionObserver`.

**Ownership:** `GameplaySceneCoordinator` owns the single `ARAnchor`, its `AnchorEntity`
and every entity handle — nothing else adds or removes entities. Its lifetime is **one
attempt**, not one session: retry calls `teardown()` and a fresh coordinator is built on
the next lock.

**The phase machine** is `Level1PhaseMachine.next(from:on:) -> Level1Phase?` — pure,
total, returns `nil` for "ignore this event in this phase". `Level1ViewModel.handle` is
the whole machine in five lines: consult it, apply the payload, set the phase, refresh
the input gate, run `Level1PhaseCommands`. The 13 phases and the full transition table are `L1 §8`.
`Level1InputGate.of(phase)` answers every "is this interactive" question so no view ever
asks what phase it is in.

### Invariants — each one is a bug that was already found and fixed

1. **`session.run` is called exactly once per process.** Never paused, never re-run,
   across alignment, detection, both runs, success and retry. A second `run` re-origins
   the world and silently detaches the crane from the scene sitting on it. There is a
   `#if DEBUG` trap in `ARSessionManager`.
2. **`Level1ViewModel` never imports ARKit, RealityKit, Vision or simd.** Everything
   crossing into it is a `CGPoint`, `Double`, `UUID` or a `Models/` type;
   `GearScreenProjector` does the world→screen conversion. This is also what makes it
   previewable.
3. **An event the machine rejects has no effects either.** The payload is applied *after*
   the machine accepts. Detection republishes `.detectionLocked` several times a second
   for the whole level; applying its payload first re-seeded the roles continuously and
   made the child's gear choice impossible to keep.
4. **Detection never reaches physics.** Tooth counts are read once, at lock, into a
   `GearPair`. An improving pose estimate must never alter a run in progress.
5. **No orientation transform anywhere in the vision path.** The app is landscape-locked
   and everything works in the camera's native landscape pixel space. Introducing a
   `CGImagePropertyOrientation` is the exact bug class the PoC avoided.
6. **The detector's preprocessing contract is fixed:** ARKit `capturedImage` 1920×1440 →
   centre-crop 1440×1440 → model at 960. The model was trained on that representation;
   a different crop silently degrades accuracy rather than failing.
7. **Do not snap gear centres to the theoretical mesh distance.** Using a 24 mm ruler to
   correct a 300 mm measurement amplified bounding-box noise ~12×. This overrides `§12.4`.
8. **The follower's angle is derived from the driver's** (`−driverAngle / i`), never
   integrated independently — independent integration drifts and the teeth visibly unmesh.
   The sign flip *is* lesson LO-2.
9. **`minLiftDuration` clamps rope speed**, inside `WinchModel`, evaluated once against
   the full height. Never the ratio, never the sign, no per-segment special case.
10. **"Stop at 50%" lives only in `LiftSegment`.** `Core/` has no concept of guided vs
    free and contains no phase-shaped branch. The free run is the identical code path
    handed a different `Double`.
11. **`GearMeshNormaliser` normalises on a wrapper Entity, never `model.transform`.**
    Writing the model's own transform destroys the importer's USD `upAxis="Z"` correction
    and lays every gear flat on the table.
12. **Mirror-alignment constants in `CraneAlignmentTuning` were measured on device, not
    chosen.** Treat them as data. `correct` converts into anchor-local space once; when
    settled the transform is left untouched; measurements are skipped unless
    `trackingState == .normal`; both limits are per-second × the frame's own `dt`; heading
    steps the short way round.

---

## Git

Branches: `main`, `dev/axel`, `dev/nay`. Commit to your branch → PR into `main` → review
by the other dev → merge. Long-running work may cut `dev/axel/level1-gear-detection` from
a dev branch; it merges back into `dev/axel`, never into `main`.

Commits: `type(scope): short description`

- Types: `feat` `fix` `refactor` `style` `docs` `chore` `test`
- Scopes: `designSystem` `splash` `cutscene` `blueprint` `gameplay` `level1` `level2`
  `arCore` `vision` `gearPhysics` `entities` `audio` `app`

PRs need 1 approval, a note on what changed and how it was tested (device + iOS version),
and a screen recording for anything AR-visible.

`Docs/` is still **tracked**, contrary to `L1 §5.1` which asked for it to be untracked.
It carries large screenshot folders that churn; be deliberate about what you stage there.

---

## Current state

`dev/axel` holds a complete, playable Level 1: 165 source files, 22 test suites, ~9.7k
lines. `Core/` (AR, Crane, Vision, Depth, Entities, Gear) and
`Features/Gameplay/{Level1,Shared}` plus `Features/Result` and `Features/Unsupported`
are all built. Last commit: `fix: 3d gears asset and dynamic bubble chat size`.

There is **substantial uncommitted work in the tree** — a device-feedback polish pass
against the screenshots in `Docs/`: scene lighting (`SceneLightingRig`), gear twin
shading, cheese placement and orientation, a crank ratchet, crank direction guidance,
and success-screen layout. New untracked files come with new tests
(`CrankRatchetTests`, `CheeseOrientationTests`, `LiftRunnerTests`,
`Level1RoleSelectionTests`). Check `git status` before assuming a file is on a branch.

Not built: `Splash`, `Cutscene`, `Blueprint`, `Level2`, `Core/Audio`,
`Core/Persistence`. `AppRouter` has routes for them; `RootView` falls through to
`DesignSystemGalleryView` for anything unimplemented. Success is an **overlay inside
`Level1View`, not a route** — routing away would tear down the frozen AR scene that is
the reward.

### Open questions

`OQ-3` (Level 1 HUD is SF Pro in the mockups; implementation uses Nunito/Mickies) is
still open. `OQ-7` (which gear pair the blueprint mandates) is resolved in practice —
`Level1Tuning` ships the `L1 §7` values and the level detects whichever of 8T/24T/40T
the child built with. Full list in `§14`. Resolutions already assumed in code: `OQ-1`
added `successGreen`/`warningRed` to `Palette`, `OQ-2` promoted `.dialogue` to a real
token, `OQ-4` uses `AppColor.accent` for "Great job!".
