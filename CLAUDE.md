# Cheese Heist — Claude Code guide

AR gear-ratio learning app for LEGO Technic robotics classes. iPadOS, SwiftUI + RealityKit
+ ARKit + Vision/Core ML.

**`Docs/PRD-CheeseHeist-v1.md` is the single source of truth.** It is the team agreement:
scope, physics, file layout, engineering conventions, open questions. Read the relevant
section before writing code, and when this file and the PRD disagree, the PRD wins.

Section references below (`§7.2`) point into that PRD.

---

## Build & run

`xcode-select` on this machine points at CommandLineTools, so `xcodebuild` needs an
explicit toolchain:

```sh
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer

xcodebuild -project 'Cheese Heist.xcodeproj' -scheme 'Cheese Heist' \
  -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M5)' build
```

- Deployment target **iOS 18.0**. Installed simulator runtime is 26.3.1.
- Real AR work needs an **iPad Pro with LiDAR** — there is no non-LiDAR path (§5), and
  the simulator cannot exercise any of it.
- `swiftlint` is **not installed**. The build phase warns and continues; install it with
  `brew install swiftlint` to get the §8.4 gate for real.

## Xcode project mechanics — read before adding files

The target uses an **Xcode 16 file-system-synchronized root group** (`objectVersion = 77`).

- **New files under `Cheese Heist/` join the target automatically.** Do not edit
  `project.pbxproj` to add a source file — just create it.
- The flip side: *every* file in that tree gets bundled, including dotfiles. The empty
  scaffold folders are held open by `.gitkeep`, and those 34 files are listed as
  `membershipExceptions` in `PBXFileSystemSynchronizedBuildFileExceptionSet`. **If you
  add a `.gitkeep` to a new empty folder, add it to that exception list too**, or the
  build fails with "Multiple commands produce …/.gitkeep".
- Delete a folder's `.gitkeep` once it holds a real file, and drop its exception entry.

**`Info.plist`** lives at the repo root, outside the synced group, and holds only
`UIAppFonts` — `GENERATE_INFOPLIST_FILE = YES` has no build-setting mapping for it.
Everything else still comes from `INFOPLIST_KEY_*` settings and is merged in at build
time. Add new plist keys as `INFOPLIST_KEY_*` build settings where one exists.

## Fonts — the names are not the filenames

`UIAppFonts` takes **filenames**; `UIFont(name:)` takes **PostScript names**. They differ:

| File | PostScript name |
|---|---|
| `Mickies.otf` | `MickiesRegular` — no hyphen |
| `Nunito-Regular.ttf` | `Nunito-Regular` |
| `Nunito-Bold.ttf` | `Nunito-Bold` |
| `Nunito-ExtraBold.ttf` | `Nunito-ExtraBold` |

The PRD's §7.3 sample code says `Mickies-Regular`, which does not resolve. `AppFont.Family`
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

Full directory layout is §9. The two rules that decide where a file goes:

1. **"Could Level 2 want this?"** (§8.5) Yes unchanged → `Core/` or `Commons/`. Yes with
   different parameters → `Features/Gameplay/Shared/`. Genuinely no → `Level1/`.
   The joystick, PULL button, role labels, reticle, highlight ring, overlays, physics,
   rope entity and cat controller all fail this test and belong in `Shared`/`Core`.
2. **Views compose, they do not draw.** A `Shape`, `Path`, gradient or bespoke
   `ViewModifier` inside a View moves to `Commons/Components/`.

### Size limits — CI gate, not a convention (§8.4)

| Artefact | Warn | **Fail** |
|---|---|---|
| Swift file | 150 | **200** |
| View `body` | 40 | **60** |
| ViewModel type body | 120 | **160** |
| Function | 30 | **50** |
| Type nesting | — | 2 |

One type per file. Protocol conformances go in their own file
(`Level1ViewModel+GearDetectionDelegate.swift`). **The fix is always to split, never to
raise the limit.** A ViewModel nearing 160 lines is doing two jobs — extract a Service.

---

## Design system (WS-1, on `main`)

`Commons/DesignSystem/` — tokens, hex extensions, layout scale. `Commons/Components/` —
the five shared components.

**No view may contain a colour literal, a font name, a numeric font size, a corner radius
or a magic spacing number.** All of those are tokens; a PR containing one is rejected.
`.swiftlint.yml` has custom rules for the common offenders.

- Colour: views use **`AppColor`** semantic tokens only. `Palette` is raw hex and nothing
  but `AppColor` may touch it.
- Type: `.appText(AppFont.title)`. `View+TextStyle.swift` is the only place line-height
  maths exists — `lineSpacing` is additive and cannot be negative, so `largeTitle` clamps
  to 0 and takes default leading. Do not reach for `AttributedString` to force it.
- Geometry: `AppSpacing` / `AppRadius` / `AppStroke`. A component's own Figma dimensions
  (`210 × 78.14`) go in a `private enum Metric` in that component's file.
- **Scale:** every Figma frame is 1366 × 1024 pt. Read `@Environment(\.layoutScale)` and
  multiply once. **No view computes its own scale factor** — `.providesLayoutScale()` is
  applied at the app root and nowhere else.
- Every component ships a `#Preview` on both `.parchment` and `.cameraFeed`
  (`PreviewBackdrop`). Preview-driven development is mandatory (§8.6): a screen that
  cannot be previewed cannot be reviewed. AR-dependent views take an injected protocol so
  previews render a mock scene.

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

---

## Current state

`main` holds WS-1 only: the token layer, the five components, the folder scaffold and the
SwiftLint config. `App/CheeseHeistApp.swift` temporarily roots at `DesignSystemGalleryView`
so a device build proves the fonts registered — **WS-2 replaces this with `RootView` +
`AppRouter`**, and the LiDAR capability gate (§5.1) must run before `RootView` renders.

Everything else in §9 is an empty folder. Not yet built: `AppRoute`/`AppRouter`/`RootView`,
all of `Core/`, and all of `Features/`.

Two project settings still to change when WS-2 starts: the app is **not** landscape-locked
and `TARGETED_DEVICE_FAMILY` is still `1,2` (iPhone + iPad). The PRD wants landscape-locked
iPad-only — §12.2 depends on the orientation lock.

### Open questions that block code

`OQ-7` (**which gear pair the Level 1 blueprint mandates** — physics-tuning blocker, see
risk R-05) and `OQ-3` (Level 1 HUD is SF Pro in the mockups; implementation uses
Nunito/Mickies). Full list in §14. Resolutions already assumed in code: `OQ-1` added
`successGreen`/`warningRed` to `Palette`, `OQ-2` promoted `.dialogue` to a real token,
`OQ-4` uses `AppColor.accent` for "Great job!".
