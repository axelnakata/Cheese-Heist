# Product Requirements Document — **Cheese Heist · Level 1**
### Implementation spec for WS-4 (Level 1), iPadOS

| | |
|---|---|
| **Document version** | 1.0 |
| **Date** | 10 August 2026 |
| **Owner** | Axel — Tech Lead |
| **Branch** | `dev/axel` → PR into `main` |
| **Parent document** | `PRD-CheeseHeist-v1.md` — still the source of truth for anything not restated here |
| **Reference implementation** | `../gear-poc` (proof of concept, on-device proven) |
| **Design source** | Figma `Little Einstein Board` → section `Level 1` (`431:87`), 14 frames |
| **Status** | Approved decisions recorded in §2. Nine amendments to the parent PRD listed in §9. |

---

## 1. Context

`main` currently holds WS-1 only — the design-system token layer, five shared components, the §9 folder scaffold and the SwiftLint config. Every other folder in the parent PRD's §9 tree is empty. There is no `AppRouter`, no `Core/`, no `Features/`.

Level 1 is the first feature to be built and it carries essentially all of the product's technical risk: gear detection, depth-correct 2D→3D placement, anchor stability under a child's movement, and the gear physics that Levels 2 and 3 will inherit unchanged.

That risk is already largely retired. `gear-poc` is a working app that detects a LEGO gear pair, solves the crane pose from a single viewpoint, and holds a stable AR overlay on it. It ships a trained YOLO11n Core ML model. **Level 1 is therefore mostly a disciplined port, not new invention.** The PoC's algorithms are proven and must survive intact; what must change is its structure — three of its types are 494, 669 and 826 lines against a 200-line CI gate, and the largest is named `ViewModel` while being almost entirely ARKit.

**Definition of done:** a complete, playable Level 1 on `dev/axel`. Camera live throughout, one unbroken ARSession, a guided teaching run that pauses mid-lift to introduce the follower gear, then a free run where the child assigns the roles themselves.

---

## 2. Decisions taken

Confirmed before planning; these are settled and the rest of the document assumes them.

| # | Question | Decision |
|---|---|---|
| **D-1** | Role colours — Figma and parent PRD §7.2 disagree | **Driver = blue/cyan, Follower = amber/gold.** Figma is self-consistent across all 14 Level 1 frames: layers are named `gear besar outline blue` with the `Driver` label attached, and the bold span `driver gear` in the speech bubble renders blue. §7.2 has them exactly reversed. Flip `AppColor.roleDriver` / `AppColor.roleFollower`. |
| **D-2** | Crank input — Figma shows a joystick in play frames and a PULL button in role-selection frames, never both | **PULL commits, joystick cranks.** While PULL is visible the child may keep re-tapping gears to swap roles. Tapping PULL locks the assignment and PULL is replaced in the same corner by the joystick. |
| **D-3** | Physics model | **Parent PRD §6 SI torque–speed model**, not the PoC's grams/capacity model. `LevelTuning` value type, fully unit-tested, shared with L2/L3. |
| **D-4** | Detection confirm step | **No confirm tap.** Twins appear immediately on lock. The manual fallback is a timeout-only branch. |

---

## 3. The Level 1 flow

The AR camera is live from entry to exit. One ARSession, never paused, never re-run.

| # | Phase | What the child sees |
|---|---|---|
| 1 | `aligningCrane` | Full-screen scrim, white line-art of hands holding an iPad over a crane, title **"Put your crane on the center of the camera"**. No reticle — it is an illustration. |
| 2 | `detectingGears` | Instruction chip **"Looking at your gears…"**. YOLO runs, votes, locks. |
| 3 | `introDialogue` | Twins fade in immediately on lock. Mouse appears. **"Wow! Great job on making this crane!"** → **"Now, choosing the driver and follower gear is very important."** Tap to continue. |
| 4 | `teachingDriver` | App assigns the **small gear** as the initial driver. Spotlight over it, mouse standing on it. **"Look at the gear under my feet! This is the driver gear, it's the gear I turn to start pulling!"** |
| 5 | `teachingJoystick` | Spotlight moves to the joystick, animated circular-drag hint. |
| 6 | `guidedCrankToHalf` | Child cranks. **The lift stops at exactly 50%** of `liftHeight`. |
| 7 | `teachingFollower` | Spotlight on the follower gear and the rope. **"Now look at the gear holding the rope! This is the follower gear, it turns with the driver gear to pull up the cheese!"** |
| 8 | `guidedCrankToFull` | Child cranks the rest. Cheese reaches the top. |
| 9 | `handOver` | **"It's your turn! Tap on of the gear to set it as a driver"** |
| 10 | `selectingRoles` | Cheese has returned to the table. Both twins pulse white. Tapping either assigns driver; the other becomes follower. Label pills with leader lines. **PULL visible — roles stay changeable.** |
| 11 | `freeCrank` | PULL tapped → roles lock, joystick replaces PULL. Full lift, no interruption. |
| 12 | `succeeded` | Scrim over the frozen scene. **"CHEESE SECURED!"**, **"Great job!"**, three cheese stars, mouse holding cheese. Retry bottom-left, Next bottom-right. |

**Retry** returns to step 1 without restarting the ARSession. **Next** is a no-op in this release.

---

## 4. Prerequisites

Two changes gate all the work below.

### 4.1 SwiftLint — allow comment-only lines

Add to `.swiftlint.yml`:

```yaml
file_length:
  warning: 150
  error: 200
  ignore_comment_only_lines: true
```

The PoC's value is disproportionately in its rationale comments — the block at `CranePlaneEstimator.swift:436` is precisely what stops a future contributor reinstating the original alignment bug. Counting those lines against a 200-line budget forces a choice between deleting the reasoning and roughly doubling the file count. Every line estimate in §8 assumes this setting.

### 4.2 Add a `CheeseHeistTests` target

The project has exactly one `PBXNativeTarget` (the app). Physics unit tests are a blocking merge requirement (parent §15.1) and there is currently nowhere to put them.

**This is the one place `project.pbxproj` must be hand-edited** — the file-system-synchronized group only covers the app target, so a new target will not appear by adding files.

---

## 5. Housekeeping and assets

### 5.1 Repository

- All work on **`dev/axel`**. PR into `main`, reviewed by Nay. Nothing pushes to `main` directly.
- **Gitignore `Docs/`.** It is currently *tracked* — it was committed during WS-1 — so this needs `git rm -r --cached Docs` alongside the `.gitignore` entry, or it stays in history and keeps updating on every commit. This document therefore becomes a local working file, not a repo artefact.
- Delete `.gitkeep` from each folder that gains a real file, **and remove its matching entry from `membershipExceptions` in `project.pbxproj`**. A stale entry is harmless; a missing one fails the build with *"Multiple commands produce …/.gitkeep"*.
- Landscape-lock the app and set `TARGETED_DEVICE_FAMILY = 2`. The detection pipeline works entirely in native landscape pixel space with no orientation transform — a rotation would silently invalidate every bounding box.

### 5.2 Mouse sprites — must be reprocessed before use

The delivered assets are **25.1 MB across four 6000 × 5000 PNGs**, of which 61–76% is empty transparent canvas. Figma renders the mouse at 216 × 180 pt (≈648 × 540 px @3x).

| File | Canvas | Opaque bbox | Size |
|---|---|---|---|
| `mouse_talk_idle.png` | 6000×5000 | 2921×3964 at (1517, 438) | 6.8 MB |
| `mouse_talk_struggle.png` | 6000×5000 | 2920×3980 at (1515, 422) | 7.3 MB |
| `mouse_shock_happy.png` | 6000×5000 | 2416×2938 at (1792, 1031) | 4.4 MB |
| `mice_happy.png` | 6000×5000 | 3121×3732 at (1351, 643) | 6.6 MB |

**Trim the three in-scene poses to a single shared bounding box** — union `(1515, 422)` size `2923 × 3980`. Trimming each independently would re-register the sprite and make the mouse visibly jump when the pose swaps. `mice_happy` is success-screen-only and can be trimmed on its own.

Downscale to ~1200 px tall. Expected result ≈1.5 MB total, down from 25.1 MB. Import into `Assets.xcassets` as image sets.

### 5.3 Assets to export from Figma

Not present in `Docs/temporary assets level 1/`:

| Node | Name | Use |
|---|---|---|
| `690:123` | `ipad guidance 1` (906×906) | Alignment illustration |
| `690:64` | `crane guidance 1` (380×365) | Alignment illustration |
| `463:173` | `cheese star-02` (274×274) | Success screen |

### 5.4 Assets to copy from `gear-poc`

| Source | Destination | Note |
|---|---|---|
| `Resources/GearDetectorModel.mlpackage` | `Resources/ML/` | **Keep this exact filename.** Naming it `GearDetector` collides with the generated Swift class — *"Multiple commands produce GearDetector.stringsdata"*. |
| `Resources/gear_8.usdz`, `gear_24.usdz`, `gear_40.usdz` | `Resources/3DModels/Gears/` | Renamed `gear_8t` / `gear_24t` / `gear_40t` to match `GearType.modelName` |
| `Docs/temporary assets level 1/Cheese.usdc` | `Resources/3DModels/Props/` | Scale/orientation unverified — see R-L3 |

Do **not** copy: `DatasetCaptureManager`, `DatasetCaptureView`, `CraneTriangulator` (only its ~25-line `horizontalNormal` is live), `DepthUnprojector` (superseded), `GearAxisEstimator.planeNormal` / `symmetricEigen` (dead), the `ml/` training pipeline, or `UIFileSharingEnabled`.

---

## 6. Architecture

### 6.1 Ownership

**`ARSessionManager`** is created by `AppServices` at launch, *above* `AppRouter`. It memoizes one `ARView` and calls `session.run` **exactly once per process**. Add a `#if DEBUG` assertion enforcing that — it is the invariant most likely to be broken accidentally later, and breaking it silently invalidates every world anchor.

**`GameplaySceneCoordinator`** owns the single `ARAnchor`, its `AnchorEntity`, the identity `contentRoot`, and every entity handle. Nothing else adds or removes entities. Its lifetime is **one attempt**, not one session: retry calls `teardown()` (remove the `ARAnchor` from the session, clear scene anchors) and a fresh coordinator is built on the next lock. This is how retry and the one-session invariant coexist.

**`SceneUpdateTicker`** owns the single `SceneEvents.Update` subscription and fans it out in a fixed order:

1. `CraneAlignmentFilter.smooth(deltaTime:)` — alignment first, so physics writes into an already-corrected frame
2. `LiftRunner.advance(deltaTime:)`
3. `GearScreenProjector.refresh()`
4. `BillboardSystem` — projection last, so the SwiftUI overlay reads the same frame it draws

### 6.2 Two detection paths, kept separate

Preserved from the PoC exactly:

- **Fast path (6 Hz, every update)** — the `onTrackingUpdate` closure feeds `CraneAlignmentFilter.correct(toward:)`. Bypasses Observation entirely; the filter needs every measurement it can get to have something to interpolate against.
- **Slow path (2 Hz, every 3rd tick)** — `@Observable` properties drive the SwiftUI HUD, and `Level1ViewModel+DetectionObserver` translates them into `Level1Event`s.

**Detection never reaches physics.** Tooth counts are read once, at lock, into a `GearPair`. An improving pose estimate must never alter a run already in progress.

### 6.3 The ViewModel discipline

`Level1ViewModel` **never imports ARKit, RealityKit, Vision or simd.** Every value crossing into it is a `CGPoint`, `Double`, `UUID`, or a type from `Features/…/Models`. `GearScreenProjector` performs the world→screen conversion so the ViewModel only ever handles points.

It stays under the 160-line cap by holding one `Level1Phase` and delegating to seven collaborators, with every method 3–8 lines:

| Collaborator | Owns |
|---|---|
| `Level1PhaseMachine` | The transition table. Pure, stateless. |
| `Level1PhaseCommands` | Side effects of *entering* a phase — keeps `handle` to one line of effect. |
| `Level1PhasePresentation` / `Level1InputGate` | Phase → copy, and phase → what is interactive. Both pure. |
| `Level1SceneDirector` | Choreography: glow state, mouse sprite and perch, rope visibility, spotlight world anchor. |
| `DialogueSequencer` | Beat index and reveal-complete gating. The ViewModel never counts beats. |
| `GearSelectionViewModel` | Role assignment and the PULL lock. |
| `CrankInputViewModel` | Joystick / PULL → `isCranking`. |
| `LiftRunner` | The 60 Hz physics loop and the ceiling callback. |

`handle(_ event:)` is the whole machine:

```
guard let next = Level1PhaseMachine.next(from: phase, on: event) else { return }
phase = next
Level1PhaseCommands.apply(next, to: director, runner, detection, coordinator)
```

### 6.4 Input gating

`Level1InputGate.of(phase)` returns four booleans — `gearsTappable`, `joystickEnabled`, `pullVisible`, `tapAdvances`. `Level1View` passes it down. No view asks "what phase are we in", which would put the phase switch in three places.

### 6.5 Mirror alignment — port verbatim

The behaviour where the virtual scene continuously and smoothly re-seats itself onto the physical crane. **Port `correct` / `smooth` from `gear-poc/Features/Gameplay/Stage2/ARSimulationViewModel.swift:417–530` unchanged, constants included.** These values were reached by trial and error on device; treat them as measured, not chosen.

**Two clocks, and separating them is the entire point.** `correct(toward:)` runs at the detector's 6 Hz and only *sets a target*. `smooth(deltaTime:)` runs every render and *does the moving*. An earlier version stepped the scene once per measurement, which meant ~6 discrete jumps a second of a millimetre or two each — fast enough to stay aligned, far too slow to read as motion. It looked like the gears twitching.

| Constant | Value | |
|---|---|---|
| `correctionTimeConstant` | `1.0` | exponential ease, normal operation |
| `maximumDrift` | `0.02` m/s | translation rate limit |
| `maximumTurn` | `6° /s` | heading rate limit |
| `reseatDistance` | `0.08` m | "the crane itself moved" threshold |
| `reseatAngle` | `35°` | ditto, rotational |
| `reseatUpdates` | `8` | consecutive out-of-tolerance updates before re-seating |
| `reseatTimeConstant` | `0.22` | fast ease while re-seating |
| `reseatDriftLimit` | `2.0` m/s | effectively uncapped |
| `reseatTurnLimit` | `8π` rad/s | effectively uncapped |
| `reseatDoneDistance` | `0.004` m | exit re-seat (loose — the target is a live 6 Hz estimate) |
| `reseatDoneAngle` | `2°` | ditto |
| `settledDistance` | `1e-5` m | below this, do nothing at all |
| `settledAngle` | `1e-5` rad | ditto |
| `dt` clamp | `0…0.1` s | a dropped frame must not licence one huge step |

```
gain = 1 − exp(−dt / timeConstant)
renderedOrigin  += (offset / distance) · min(distance · gain, driftLimit · dt)
renderedHeading += sign(turn) · min(|turn| · gain, turnLimit · dt)
```

Five rules that are load-bearing. Each one is a bug that was already found and fixed:

1. **Convert the measurement into the anchor's local space once, in `correct`, and never revisit it.** `measuredLocal = pose(of: anchorWorld.inverse × measured.transform)`. A target held in world coordinates has to be re-applied every frame to animate, and re-applying a world pose pins the scene to raw world space — ARKit's drift correction gets multiplied in and divided straight back out. Held in anchor space, the target is a fixed local offset the anchor carries.
2. **When settled, leave the transform untouched** — do not rewrite it with the same numbers. This is the state it is in almost all the time, and it is what lets ARKit's own answer reach the screen unmodified.
3. **Skip the measurement entirely unless `trackingState == .normal`.** A reading taken while ARKit is re-fitting its map is not evidence about where the crane is; folding it in fights relocalisation instead of surviving it.
4. **Both limits are per-second, multiplied by the frame's own `dt`** — motion is identical at 60 or 120 fps.
5. **Heading steps the short way round** (`shortestAngle`), so crossing due north does not swing the scene half a turn.

**Geometry only.** Rope length, the physics run and the gear offsets inside the frame are deliberately untouched — only the frame itself is corrected. The gear offsets are fixed LEGO geometry measured once.

`CraneAlignmentTuning` holds the 13 constants as a value type; `CraneAlignmentFilter` holds `targetOrigin/Heading`, `renderedOrigin/Heading`, `reseating` and `reseatStreak`, and nothing else.

---

## 7. Physics

Implements parent PRD §6 verbatim. Pure, deterministic, SI, no device dependency.

```
i = N_follower / N_driver
τ_load     = m_cheese · g · r_drum
ω_driver   = ω_noLoad · (1 − τ_load / (i · η · τ_stall))      clamped at 0
ω_follower = −ω_driver / i                                     the sign flip IS lesson LO-2
v_rope     = |ω_follower| · r_drum
h(t)       = ∫ v_rope dt                                       clamped to the segment ceiling
```

Level 1 tuning: `payloadMass 0.010 kg`, `stallTorque 0.006 N·m`, `noLoadAngularVelocity 12.0 rad/s`, `meshEfficiency 0.94`, `winchRadius 0.0025 m`, `liftHeight 0.06 m`, `minLiftDuration 1.2 s`.

Two rules that are easy to get wrong:

- **The follower's angle is derived from the driver's**, `−driverAngle / i`, never integrated independently. Independent integration accumulates float drift and the teeth visibly unmesh.
- **`minLiftDuration` clamps rope speed, never the ratio or the sign.** Applied inside `WinchModel` as `v ≤ liftHeight / minLiftDuration`, evaluated once against the *full* height so no per-segment special case exists.

### 7.1 Where "stop at 50%" lives

**In `LiftSegment`, a value type in `Core/Gear/`, and nowhere else.**

```
LiftSegment { ceilingFraction: Double }     .half = 0.5    .full = 1.0
```

`GearTrainSimulator` clamps height to `liftHeight × segment.ceilingFraction`. `Core/` has no concept of guided versus free and contains no phase-shaped branch. `Level1Phase.liftSegment` maps `guidedCrankToHalf → .half`, `guidedCrankToFull` and `freeCrank → .full`, `nil` otherwise; `LiftRunner` idles on `nil`.

**The free run is the identical code path as the guided run**, differing only in the `Double` it was handed.

The cheese reset is a *scene* concern, not a physics branch: `LiftRunner.reset()` fires on entry to `selectingRoles` — not `freeCrank` — so the cheese drops back to the table while the child is still choosing roles, and the free run starts from zero.

---

## 8. Phase machine

```
aligningCrane · detectingGears · manualFallback · introDialogue
teachingDriver · teachingJoystick · guidedCrankToHalf
teachingFollower · guidedCrankToFull · handOver
selectingRoles · freeCrank · succeeded
```

`confirmingDetection` from parent §10.3 is removed (D-4). `manualFallback` replaces it as a timeout-only branch. `selectingDriver` splits into `handOver` (instruction beat) and `selectingRoles` (interaction).

| From | Event | To | Entry effect |
|---|---|---|---|
| — | `onAppear` | `aligningCrane` | `startSession()` once ever; `detection.start()` |
| `aligningCrane` | `.detectionViable` | `detectingGears` | chip → "Looking at your gears…" |
| `detectingGears` | `.detectionLocked(gears)` | `introDialogue` | build scene, small gear = initial driver; beats 1–2 |
| `detectingGears` | `.detectionTimedOut` | `manualFallback` | present sheet; detector keeps tracking |
| `manualFallback` | `.manualPairChosen` | `introDialogue` | same build |
| `introDialogue` | `.tappedContinue` | next beat, or `teachingDriver` | sequencer owns the index |
| `teachingDriver` | `.tappedContinue` | `teachingJoystick` | spotlight → driver; mouse `talkIdle` perched |
| `teachingJoystick` | `.tappedContinue` | `guidedCrankToHalf` | spotlight → joystick; drag hint on |
| `guidedCrankToHalf` | `.liftReachedCeiling` | `teachingFollower` | joystick off; spotlight → follower + rope; mouse `talkStruggle` |
| `teachingFollower` | `.tappedContinue` | `guidedCrankToFull` | joystick on |
| `guidedCrankToFull` | `.liftReachedCeiling` | `handOver` | joystick hidden; mouse `shockHappy` |
| `handOver` | `.tappedContinue` | `selectingRoles` | **`runner.reset()`**; twins pulse white; PULL visible |
| `selectingRoles` | `.tappedGear(id)` | `selectingRoles` | reassign + animated relayout, 0.3 s |
| `selectingRoles` | `.tappedPull` | `freeCrank` | lock assignment; PULL → joystick |
| `freeCrank` | `.liftReachedCeiling` | `succeeded` | freeze scene; present success overlay |
| `succeeded` | `.tappedRetry` | `aligningCrane` | `teardown()`, `detection.reset()`, **never `session.pause()`** |
| `succeeded` | `.tappedNext` | `succeeded` | no-op |
| any | `.trackingLost` / `.trackingRegained` | unchanged | HUD note only, never a phase change |

`Level1PhaseMachine.next(from:on:) -> Level1Phase?` is pure and total, returning `nil` for "ignore this event in this phase". It is the highest-value test surface in the feature — the entire flow is verifiable as a table test before a single pixel exists.

---

## 9. Files

`[PORT]` = adapted from `gear-poc` · `[NEW]` = written fresh · `[EDIT]` = change to a file already on `main`.

### `Core/Gear/` — pure physics (13 files, ~610 lines, all `[NEW]`)

`GearType` · `GearRole` · `GearPair` · `LevelTuning` · `GearRatioCalculator` · `ActuatorModel` · `WinchModel` · `LiftFeasibilityEvaluator` · `LiftSegment` · `GearTrainState` · `GearTrainSimulator` · `CrankEngagement` · `LiftOutcome`

### `Core/AR/` (9 files, ~585) and `Core/AR/Crane/` (10 files, ~720)

`ARCapabilityChecker` `[NEW]` · `ARSessionManager` + `+Delegate` · `CapturedFrameData` · `SceneUpdateTicker` · `CranePose` · `CraneAnchorBuilder` · `CraneAlignmentFilter` · `CraneAlignmentTuning` — `[PORT]`

The crane solver splits on its **two pieces of cross-frame state** — `CraneOrientationTracker` owns `trackedNormal`, `CranePlaneOffsetTracker` owns `trackedPlaneOffset`. Everything else falls out pure and testable: `CraneFrame` · `CranePlaneSolution` · `CranePlaneEstimator` (orchestration only) · `CranePairCompleter` · `ApparentSizeCheck` · `HorizontalNormalSolver` · `GearPlane` · `GearOrdering`.

> **The one non-obvious cut.** `completePair`'s ray-vs-sphere has two mirror-image roots, disambiguated by `trackedNormal`. Pass `preferredNormal` as a *parameter* rather than holding a reference back to the orientation tracker. The completer stays a pure type and the subtlest maths in the whole port becomes unit-testable with synthetic geometry.

### `Core/Vision/` (11 files, ~750) and `Core/Vision/Depth/` (6 files, ~415)

`GearDetector` · `GearDetection` · `GearDetectorError` · `GearDetectionService` · `GearDetectionPhase` · `GearDetectionFailure` · `DetectedGear` · `GearPairVote` · `GearTrackingPublisher` · `DetectionTimeoutPolicy` — `[PORT]`; `DetectionViabilityGate` `[NEW]`

Depth: `GearDepthProbe` · `GearDepthSample` · `DepthPixelSampler` · `DepthClusterSolver` · `PixelUnprojector` · `CameraRayBuilder` — `[PORT]`

### `Core/Entities/` (13 files, ~940)

`GearMeshFactory` · `GearMeshNormaliser` · `GearGeometry` · `BillboardSystem` · `RopeEntity` + `+Update` · `SupportSurfaceEstimator` — `[PORT]`
`GearTwinEntityFactory` · `HolographicGearMaterial` · `GearHighlightRing` · `CheeseEntity` · `MouseSprite` · `MouseSpriteEntity` — `[NEW]`

> `GearMeshNormaliser` must **normalise on a wrapper Entity and never write `model.transform`**. Writing the model's own transform destroys the importer's USD `upAxis="Z"` correction and lays every gear flat on the table.

### `Commons/` (21 files, ~830)

Token edits — flip role colours in `AppColor` (D-1), add `hologramCyan` and the chip-navy gradient stops to `Palette`, new `AppGradient` and `AppDuration`.
`SpeechBubbleStyle` `[NEW]` + `SpeechBubbleView` `[EDIT]` — Level 1's bubble is parchment `#F9F2E4` with dark text, not accent yellow.
`InstructionChip` `[EDIT]` — navy vertical gradient `#0E3155 → #1D364F`.
Overlays: `ScrimOverlay` · `SpotlightHoleShape` · `SpotlightOverlay` · `SpotlightTarget` · `LeaderLineShape`
Hints: `CircularDragHintShape` · `CircularDragHint`
`ARViewContainer` `[PORT]`
Extensions: `SIMD+Convenience` · `Angle+Shortest` · `simd_quatf+SafeRotation` · `Comparable+Clamped` · `Entity+Lookup`
`Logger+Categories` — replaces every PoC `print`, and buys back ~120 lines across the ported files

### `Features/Gameplay/Shared/` (26 files, ~2000)

Models: `GearRoleAssignment` · `SpotlightSubject` · `GearScreenTarget`
ViewModels: `CircularDragTracker` · `CrankInputViewModel` · `GearSelectionViewModel` · `DialogueSequencer`
AR: `CraneSceneProviding` · `GameplaySceneCoordinator` · `SceneLayoutFromAssignment` · `GearOverlayPlacer` · `GearRotationApplier` · `PayloadLiftApplier` · `GearScreenProjector` · `LiftRunner`
Components: `CircularJoystickRingShape` · `CircularJoystickView` · `PullButton` · `GearRoleLabel` · `GearRoleLabelLayer` · `GameplayDialogueLayer` · `GearSelectionTapLayer` · `CraneAlignmentLayer` · `CraneAlignmentIllustration` · `GearDetectingLayer` · `DetectionManualFallbackSheet`

> `SceneLayoutFromAssignment` is pure — assignment in, crane-local positions out. It is what guarantees no `if the small gear is the driver` branch exists anywhere in the codebase.

### `Features/Gameplay/Level1/` (15 files, ~1200)

`Level1Phase` · `Level1Event` · `Level1PhaseMachine` · `Level1PhasePresentation` · `Level1InputGate` · `Level1PhaseCommands` · `Level1SceneDirector` · `Level1ViewModel` · `+DetectionObserver` · `Level1View` · `Level1Script` · `Level1Tuning` · `Components/{Level1HUDLayer, Level1TutorialLayer, Level1HandOverLayer}`

### `Features/Result/` (7) · `Features/Unsupported/` (1) · `App/` (5) · `PreviewData/` (4)

Success is an **overlay inside `Level1View`, not a route** — the AR scene must stay live and frozen behind it.
`App/`: `AppRoute` · `AppRouter` · `AppServices` (composition root) · `RootView` · `CheeseHeistApp` `[EDIT]`

### Tests (12 suites, ~975)

`GearRatioCalculator` · `ActuatorModel` · `WinchModel` · `LiftFeasibilityEvaluator` · `GearTrainSimulator` · `Level1PhaseMachine` · `GearPairVote` · `CircularDragTracker` · `SceneLayoutFromAssignment` · `DepthClusterSolver` · `CranePairCompleter` · `GearRoleAssignment`

### Total ≈ 155 files

That is what one-type-per-file plus a 200-line cap costs on a feature of this scope. The alternative is not fewer files — it is failing CI.

### 9.1 What stays in `Level1/`, and why

Applying the parent PRD's §8.5 test — *"Could Level 2 want this?"* — honestly moved most candidates out. Every component, the entire crane and detection spine, all physics, and even the alignment and detection *layers* went to `Shared/` or `Core/` (Level 2 aligns a crane too; only the copy differs, so copy is a parameter).

What genuinely remains:

| File | Why Level 2 cannot use it |
|---|---|
| `Level1Phase` / `Event` / `PhaseMachine` | Level 2 has a **fail state** — §6.4 tunes it so stall is the puzzle — and a different beat order. Structurally different, not parameterisable. A shared protocol over exactly two cases is a generalisation to build when L2 exists, not before. |
| `Presentation` / `InputGate` / `Commands` | Pure functions *over `Level1Phase`*. They cannot outlive their input type. |
| `Level1SceneDirector` | The teaching choreography — mouse on the driver, spotlight to the joystick, stop at half. The choreography *is* the lesson, and the lesson is what changes per level. |
| `Level1Script` / `Level1Tuning` | Content and values. The *type* `LevelTuning` lives in `Core/Gear/`. |
| `Level1ViewModel` / `Level1View` / the three layers | Composition. |

**The line: `Shared/` owns components and mechanics; `Level1/` owns composition and choreography.** Nothing in `Level1/` draws anything or computes anything.

---

## 10. Amendments to `PRD-CheeseHeist-v1.md`

Places where the PoC's proven behaviour or a confirmed decision beats the written spec. Each should be edited in the parent document.

| § | Parent PRD says | Do instead | Why |
|---|---|---|---|
| §7.2 | `roleDriver` amber, `roleFollower` blue | Flip them | D-1. Do it before anything references the tokens, or the inversion becomes silent. |
| §7.6 | Speech bubble fill = `accent` | Add a `.parchment` style variant | Level 1's bubble is `#F9F2E4` with dark text and a role-coloured bold span. |
| §10.4 | `Level1View` hosts a `RealityView` | `ARViewContainer` over `ARView` | `RealityView` cannot expose raw `ARFrame` / `sceneDepth` / camera intrinsics. Non-negotiable. |
| §11.5.1 | Reticle + plane/distance/stillness gate | Illustration overlay + `DetectionViabilityGate` | Replaces ~150 lines with ~55 and gates on what actually matters — can the model see the gears — rather than a proxy. Drops `PlaneDetectionService` and `CraneAlignmentReticle`. |
| §12.2 | Detect once, lock, and stop | Keep tracking, re-solve every update at 6 Hz | The child's most useful viewpoints arrive *after* the lock. The cost concern is handled by 6 Hz plus the 60 Hz anchor doing the real work. |
| §12.2 | `CGImagePropertyOrientation` from interface orientation | No orientation transform; native landscape throughout | Introducing an orientation enum is exactly the bug class the PoC avoided. Landscape-lock for other reasons. |
| §12.3 | 12 observations, IoU clustering, 70% modal, 0.60 confidence floor | PoC vote: 3 agreeing sorted tooth-count pairs **plus a usable geometric solution** | Proven on device, locks in under 2 s. Requiring a usable solve is strictly stronger than a confidence floor. |
| §12.4 step 6 | Snap centre-to-centre to the theoretical mesh distance | **Do not snap** | The PoC identifies this as the original alignment bug: using a 24 mm ruler to correct a 300 mm measurement amplified bounding-box noise roughly 12×. |
| §12.6 | PBR twins tinted 35% | Emissive holographic material | Confirmed art direction. **Keep** the +2 mm camera-ward offset and the occlusion exemption — both are anti-flicker measures independent of material choice. |

### 10.1 One deliberate departure from the sub-plan

The commissioned design recommended dropping `CraneBaseEstimator` entirely, on the grounds that `liftHeight` is a fixed 0.06 m tuning constant. **I am keeping a simplified `SupportSurfaceEstimator` (~90 lines).**

Without it there is no way to know where the table is, so the cheese would rest at `follower.y − 0.06` and either float above the baseplate or sink into it, depending on how tall the child built the crane. The estimator sets the cheese's *resting* position; `tuning.liftHeight` still governs how far it travels. Ninety lines to remove a visible artefact in the very first thing the child sees is worth it.

---

## 11. Build order

Steps 1–4 and most of step 10 need no iPad and form a clean parallel workstream — they also happen to cover the two areas most at risk of silent rot, physics correctness and phase completeness.

| # | Land | Verifiable without a device? |
|---|---|---|
| 1 | Housekeeping, test target, all of `Core/Gear/`, physics tests | **Yes** — `xcodebuild test`. Assert the parent PRD's worked example: 8→24 lifts in 6.1 s |
| 2 | Token edits, `SpeechBubbleStyle`, `AppGradient`, new `Commons/Components` with previews | **Yes** — Xcode previews |
| 3 | `Level1Phase` / `Event` / `PhaseMachine` / `Presentation` / `InputGate` + table tests | **Yes** — the whole flow tested before any pixel exists |
| 4 | `App/` routing, capability gate, `UnsupportedDeviceView` | **Yes** — the simulator correctly shows the unsupported screen |
| 5 | `ARSessionManager` + `ARViewContainer`; `Level1View` shows camera only | Device |
| 6 | `Core/Vision/` + `Depth/` | Partly — five pure types unit-tested |
| 7 | `Core/AR/Crane/` | Partly — four pure types unit-tested |
| 8 | `GearDetectionService` + viability gate. Target: lock under 2 s | Device |
| 9 | `Core/Entities/`, coordinator, alignment filter, ticker — **the R-02 spike**, already de-risked by the PoC | Partly — filter maths tested with synthetic pose sequences |
| 10 | Shared components and Level 1 layers, phase by phase, each previewed against `MockCraneScene` | **Yes**, for the layers |
| 11 | `CrankInputViewModel` + `LiftRunner` + guided and free lift | Partly |
| 12 | Success overlay + retry | Device |

---

## 12. Verification

### 12.1 Unit — blocking

`xcodebuild test`. All nine ordered gear pairs for ratio and sign · reciprocal identity `i(a,b) · i(b,a) == 1` · stall boundary · height monotonicity and clamp · `minLiftDuration` clamps speed but never ratio or sign · `LiftSegment.half` stops at exactly 50% · `GearRoleAssignment.swapped()` is involutive · `SceneLayoutFromAssignment` derives purely from the assignment · every `Level1Phase` × `Level1Event` pair produces the §8 table's result.

### 12.2 Preview

Every component and every Level 1 layer renders on both `.parchment` and `.cameraFeed`, against `MockCraneScene`, on a Mac with no device attached.

### 12.3 On device — iPad Pro with LiDAR

These cannot be faked in a simulator.

| # | Test |
|---|---|
| 1 | Gear pair locks in ≤2 s at ~40 cm; twins register on the physical gears within ~5 mm (AC-2, AC-3) |
| 2 | Pan to the ceiling for 10 s and return — cheese, mouse and twins are exactly where they were (AC-4) |
| 3 | Guided run stops at exactly half height; follower dialogue fires; second crank completes |
| 4 | Role swap — tap gear A then gear B: mouse, rope, cheese and both labels all move, animated, never a snap |
| 5 | PULL locks the choice and is replaced by the joystick |
| 6 | **Retry returns to alignment with a breakpoint on `session.run` never firing a second time** |
| 7 | Instruments: ≥55 fps through a full crank and lift (AC-5) |
| 8 | Both 11″ and 12.9″ — `layoutScale` correctness |

---

## 13. Risks

| ID | Risk | Mitigation |
|---|---|---|
| **R-L1** | Porting "cleans up" the parts that matter — the wrapper-Entity normalisation, and the five mirror-alignment rules in §6.5 | These are the entire alignment fix, each one a bug already found and fixed on device. Port with comments intact; §4.1 exists so the comments survive the line budget. Re-tuning §6.5's constants is a device-verified change, not a code-review one. |
| **R-L2** | R-02 from the parent PRD — deriving the gear axis from a 2D box | Already solved: the crane frame's local +Z *is* the gear axis, so meshes drop in with identity rotation. Faithful porting is the mitigation. |
| **R-L3** | `Cheese.usdc` scale, up-axis and origin are unverified until it loads in RealityKit | Generalise `GearMeshNormaliser` to the cheese rather than hand-tuning a scale constant — it already solves exactly this class of problem. |
| **R-L4** | The 25 MB of mouse PNGs ship unprocessed, or get trimmed independently | §5.2. Independent trims re-register the sprite and the mouse jumps on every pose change. |
| **R-L5** | A second `session.run` is introduced later, silently invalidating world anchors | `#if DEBUG` assertion in `startSession()`; device test 6. |

---

## 14. Open questions

| ID | Question | Blocks |
|---|---|---|
| **OQ-L1** | Parent **OQ-7** is still open — which gear pair does the Level 1 blueprint mandate? Level 1 is unfailable at 0.010 kg so nothing is blocked today, but the `i²` lift-time spread means an 8+40 build gives a **25×** swing between the child's two role choices. Worth settling before the pilot. | Pilot |
| **OQ-L2** | Does `Next` on the success screen route to Level 2 later, or return to a level menu that does not yet exist? | Level 2 |
| **OQ-L3** | Is the emissive holographic twin legible against a bright classroom table, or does it wash out? Needs a device check in step 9. | WS-4 polish |
| **OQ-L4** | No audio is specified for Level 1 (parent OQ-10). The crank in particular feels inert without a tick. | WS-4 polish |
