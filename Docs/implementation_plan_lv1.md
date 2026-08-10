# Cheese Heist — Level 1 Implementation Plan

Complete implementation of Level 1 (WS-4) for the Cheese Heist AR gear-ratio learning app, ported from `gear-poc` with proper MVVM architecture, 200-line file cap, and the PRD-Level1-v1.md phase machine.

## User Review Required

> [!IMPORTANT]
> **Decision D-1 (Role Colours Flipped):** Per PRD-Level1-v1 §2, `roleDriver` will be changed from amber to blue/cyan, and `roleFollower` from blue to amber/gold. This is confirmed in the Level 1 PRD.

> [!IMPORTANT]
> **No `confirmingDetection` phase.** Per D-4, twins appear immediately on lock. No confirm tap required.

> [!IMPORTANT]
> **~155 files total** — this is the cost of one-type-per-file + 200-line cap on a feature of this scope. The alternative isn't fewer files, it's failing CI.

## Proposed Changes

The implementation follows the build order from PRD-Level1-v1 §11. Each step is independently buildable and testable.

---

### Step 1: Housekeeping & Core/Gear (Pure Physics)

Prerequisite setup + the entire physics layer. No device needed — all unit-testable.

#### [EDIT] [.swiftlint.yml](file:///Users/axelnakata/Swift%20Coding/Challenge%205%20-%20AR/Cheese%20Heist/.swiftlint.yml)
- Add `ignore_comment_only_lines: true` to `file_length` (PRD-Level1 §4.1)

#### [NEW] Core/Gear/ — 13 files, ~610 lines
Pure physics, SI units, deterministic. Shared by L1/L2/L3.

| File | Purpose | Est. lines |
|---|---|---|
| `GearType.swift` | Enum: `.eightTooth`, `.twentyFourTooth`, `.fortyTooth` with teeth, pitch radius, model name | ~40 |
| `GearRole.swift` | Enum: `.driver`, `.follower` | ~15 |
| `GearPair.swift` | Model: driver + follower GearType | ~20 |
| `LevelTuning.swift` | Value type for all physics constants per level | ~35 |
| `GearRatioCalculator.swift` | Pure functions: ratio, ω_follower, τ_follower | ~40 |
| `ActuatorModel.swift` | Torque-speed curve: τ_stall × (1 − ω/ω_noLoad) | ~45 |
| `WinchModel.swift` | Rope speed, height integration, minLiftDuration clamp | ~40 |
| `LiftFeasibilityEvaluator.swift` | Can this pair lift at this tuning? | ~25 |
| `LiftSegment.swift` | `.half` (0.5) / `.full` (1.0) ceiling fraction | ~15 |
| `GearTrainState.swift` | Model: angles, height, isCranking | ~20 |
| `GearTrainSimulator.swift` | Integrates state per tick | ~80 |
| `CrankEngagement.swift` | Model: engaged/disengaged/wrongWay | ~15 |
| `LiftOutcome.swift` | Model: success/stall | ~15 |

---

### Step 2: Token Edits & New Commons Components

Design system updates + new overlay/hint components needed by Level 1.

#### [EDIT] [AppColor.swift](file:///Users/axelnakata/Swift%20Coding/Challenge%205%20-%20AR/Cheese%20Heist/Cheese%20Heist/Commons/DesignSystem/Tokens/AppColor.swift)
- Flip `roleDriver` → `skyBlue`, `roleFollower` → `crustAmber` (D-1)

#### [EDIT] [Palette.swift](file:///Users/axelnakata/Swift%20Coding/Challenge%205%20-%20AR/Cheese%20Heist/Cheese%20Heist/Commons/DesignSystem/Tokens/Palette.swift)
- Add `hologramCyan` for gear twin material
- Add navy gradient stops `navyGradientTop` (#0E3155) and `navyGradientBottom` (#1D364F)

#### [NEW] Commons/DesignSystem/Tokens/
| File | Purpose |
|---|---|
| `AppGradient.swift` | Navy vertical gradient for InstructionChip |
| `AppDuration.swift` | Standard animation durations (0.3s transition, 0.25s ease-out, etc.) |

#### [EDIT] [InstructionChip.swift](file:///Users/axelnakata/Swift%20Coding/Challenge%205%20-%20AR/Cheese%20Heist/Cheese%20Heist/Commons/Components/Chips/InstructionChip.swift)
- Use navy vertical gradient instead of flat 60% navy

#### [NEW] SpeechBubbleStyle.swift
- Add `.parchment` style variant (Level 1's bubble is `#F9F2E4` with dark text, not accent yellow)

#### [EDIT] [SpeechBubbleView.swift](file:///Users/axelnakata/Swift%20Coding/Challenge%205%20-%20AR/Cheese%20Heist/Cheese%20Heist/Commons/Components/Dialogue/SpeechBubbleView.swift)
- Support `SpeechBubbleStyle` parameter for fill/text color variants

#### [NEW] Commons/Components/Overlays/
| File | Purpose |
|---|---|
| `ScrimOverlay.swift` | Dim background at 55% opacity |
| `SpotlightHoleShape.swift` | Rounded-rect hole shape |
| `SpotlightOverlay.swift` | Dim-with-hole for tutorial beats |
| `SpotlightTarget.swift` | Model: position + size for spotlight hole |
| `LeaderLineShape.swift` | Path for gear role label leader lines |

#### [NEW] Commons/Components/Hints/
| File | Purpose |
|---|---|
| `CircularDragHintShape.swift` | Animated circular arrow hint |
| `CircularDragHint.swift` | Full hint view with animation |

#### [NEW] Commons/Components/
| File | Purpose |
|---|---|
| `ARViewContainer.swift` | UIViewRepresentable for ARView (port from gear-poc) |

#### [NEW] Commons/Extensions/
| File | Purpose |
|---|---|
| `SIMD+Convenience.swift` | Common SIMD helpers |
| `Angle+Shortest.swift` | Signed shortest-angle delta |
| `simd_quatf+SafeRotation.swift` | Safe quaternion construction |
| `Comparable+Clamped.swift` | `clamped(to:)` |
| `Entity+Lookup.swift` | Entity tree queries |

#### [NEW] Commons/Utilities/
| File | Purpose |
|---|---|
| `Logger+Categories.swift` | os.Logger categories replacing all PoC `print` |

---

### Step 3: Level 1 Phase Machine + Table Tests

The entire flow verified as a table test before a single pixel exists.

#### [NEW] Features/Gameplay/Level1/
| File | Purpose | Est. lines |
|---|---|---|
| `Level1Phase.swift` | 13-case enum matching §8 | ~30 |
| `Level1Event.swift` | All events: `.detectionViable`, `.detectionLocked`, `.tappedContinue`, etc. | ~30 |
| `Level1PhaseMachine.swift` | `next(from:on:) → Level1Phase?` — pure, total | ~80 |
| `Level1PhasePresentation.swift` | Phase → copy strings, chip text | ~60 |
| `Level1InputGate.swift` | Phase → 4 booleans (gearsTappable, joystickEnabled, pullVisible, tapAdvances) | ~45 |

---

### Step 4: App Routing & Capability Gate

#### [NEW] App/
| File | Purpose |
|---|---|
| `AppRoute.swift` | Enum: splash, surfaceScan, cutscene, blueprint, level1, level2, unsupportedDevice |
| `AppRouter.swift` | `@Observable`, owns the route, only type that mutates it |
| `AppServices.swift` | Composition root — creates ARSessionManager above AppRouter |
| `RootView.swift` | Switch over route → feature view |

#### [EDIT] [CheeseHeistApp.swift](file:///Users/axelnakata/Swift%20Coding/Challenge%205%20-%20AR/Cheese%20Heist/Cheese%20Heist/App/CheeseHeistApp.swift)
- Replace `DesignSystemGalleryView` with `RootView`
- Create `AppServices` at launch, inject into environment

#### [NEW] Core/AR/ARCapabilityChecker.swift
- §5.1 LiDAR gate: check `supportsSceneReconstruction(.mesh)` and `supportsFrameSemantics(.sceneDepth)`

#### [NEW] Features/Unsupported/UnsupportedDeviceView.swift
- Terminal screen, no "continue anyway"

---

### Step 5: ARSessionManager + ARViewContainer (Camera Live)

#### [NEW] Core/AR/
| File | Purpose |
|---|---|
| `ARSessionManager.swift` | Owns ARSession + ARView, single `session.run()` ever. Port from gear-poc |
| `ARSessionManager+Delegate.swift` | `ARSessionDelegate` conformance in its own file |
| `CapturedFrameData.swift` | Model: camera transform, intrinsics, depth maps |
| `SceneUpdateTicker.swift` | Single `SceneEvents.Update` subscription, fans out in fixed order |

---

### Step 6: Core/Vision + Depth (Detection Pipeline)

Port from gear-poc with proper decomposition.

#### [NEW] Core/Vision/ — 11 files
| File | Purpose |
|---|---|
| `GearDetector.swift` | Vision + CoreML YOLO wrapper (port) |
| `GearDetection.swift` | Model: one detection result |
| `GearDetectorError.swift` | Error types |
| `GearDetectionService.swift` | Orchestrates detection loop at 6Hz |
| `GearDetectionPhase.swift` | idle/searching/locked/timedOut/unavailable |
| `GearDetectionFailure.swift` | Why detection failed |
| `DetectedGear.swift` | Model: tooth count + world position + axis |
| `GearPairVote.swift` | Temporal voting (3 agreeing frames) |
| `GearTrackingPublisher.swift` | Dual-clock: 6Hz fast path + throttled SwiftUI path |
| `DetectionTimeoutPolicy.swift` | 12s timeout logic |
| `DetectionViabilityGate.swift` | NEW: replaces reticle with "can the model see the gears" gate |

#### [NEW] Core/Vision/Depth/ — 6 files
| File | Purpose |
|---|---|
| `GearDepthProbe.swift` | Port: reads gear distance from LiDAR depth map |
| `GearDepthSample.swift` | Model: world position + depth + sample count |
| `DepthPixelSampler.swift` | Confident depth reading within a box |
| `DepthClusterSolver.swift` | Nearest-cluster histogram logic |
| `PixelUnprojector.swift` | pixel + depth → world position |
| `CameraRayBuilder.swift` | Builds camera rays for ray-plane intersection |

---

### Step 7: Core/AR/Crane (Plane Estimation)

The crane frame solver, split from gear-poc's 669-line CranePlaneEstimator.

#### [NEW] Core/AR/Crane/ — 10 files
| File | Purpose |
|---|---|
| `CranePose.swift` | Model: origin + heading |
| `CraneFrame.swift` | Port: crane coordinate system (origin, normal, right, up) |
| `CranePlaneSolution.swift` | Model: frame + gear positions + sample count |
| `CranePlaneEstimator.swift` | Orchestration only — delegates to pure types |
| `CraneOrientationTracker.swift` | Owns `trackedNormal`, absorb/blend logic |
| `CranePlaneOffsetTracker.swift` | Owns `trackedPlaneOffset`, distance filtering |
| `CranePairCompleter.swift` | Ray-vs-sphere to find unmeasured gear |
| `ApparentSizeCheck.swift` | Box-size sanity check vs LiDAR distance |
| `HorizontalNormalSolver.swift` | Port of `CraneTriangulator.horizontalNormal` |
| `GearPlane.swift` | Ray-plane intersection |
| `GearOrdering.swift` | Tooth count → stable ordering across frames |

---

### Step 8: GearDetectionService + Viability Gate

Wire detection into the phase machine.

---

### Step 9: Core/Entities + Coordinator + Alignment Filter

The RealityKit scene graph and the mirror alignment system.

#### [NEW] Core/Entities/ — 13 files
| File | Purpose |
|---|---|
| `GearMeshFactory.swift` | Port: loads USDZ, creates gear entity |
| `GearMeshNormaliser.swift` | Port: normalise on wrapper Entity, never write model.transform |
| `GearGeometry.swift` | Tip radius, pitch radius from tooth count |
| `BillboardSystem.swift` | Port: keeps labels facing camera |
| `RopeEntity.swift` | Rope cylinder entity |
| `RopeEntity+Update.swift` | Length/position update |
| `SupportSurfaceEstimator.swift` | Port: where the table is (~90 lines) |
| `GearTwinEntityFactory.swift` | NEW: creates holographic gear twins |
| `HolographicGearMaterial.swift` | NEW: emissive material with role tinting |
| `GearHighlightRing.swift` | NEW: pulsing selection ring |
| `CheeseEntity.swift` | NEW: loads Cheese.usdc |
| `MouseSprite.swift` | Enum: talkIdle, talkStruggle, shockHappy, happy |
| `MouseSpriteEntity.swift` | NEW: 2D sprite billboard |

#### [NEW] Core/AR/Crane/
| File | Purpose |
|---|---|
| `CraneAlignmentFilter.swift` | Port: `correct(toward:)` + `smooth(deltaTime:)` with all 13 constants |
| `CraneAlignmentTuning.swift` | Value type for the 13 mirror-alignment constants |
| `CraneAnchorBuilder.swift` | Creates the single ARAnchor + AnchorEntity |

---

### Step 10: Shared Components + Level 1 Layers

UI layers composing the Level 1 screen, each previewed.

#### [NEW] Features/Gameplay/Shared/Models/
| File | Purpose |
|---|---|
| `GearRoleAssignment.swift` | `{ driver: DetectedGear, follower: DetectedGear }` |
| `SpotlightSubject.swift` | Enum: driverGear, followerGear, joystick |
| `GearScreenTarget.swift` | Screen-space position for overlay placement |

#### [NEW] Features/Gameplay/Shared/ViewModels/
| File | Purpose |
|---|---|
| `CircularDragTracker.swift` | Angular velocity from drag gesture |
| `CrankInputViewModel.swift` | Joystick + PULL → `isCranking` |
| `GearSelectionViewModel.swift` | Role assignment + PULL lock |
| `DialogueSequencer.swift` | Beat index + reveal-complete gating |

#### [NEW] Features/Gameplay/Shared/AR/
| File | Purpose |
|---|---|
| `CraneSceneProviding.swift` | Protocol for AR scene (enables mock for previews) |
| `GameplaySceneCoordinator.swift` | Owns scene graph, applies simulator output |
| `SceneLayoutFromAssignment.swift` | Pure: assignment → positions |
| `GearOverlayPlacer.swift` | Places/aligns gear twins |
| `GearRotationApplier.swift` | Applies rotation to gear entities |
| `PayloadLiftApplier.swift` | Moves cheese + rope |
| `GearScreenProjector.swift` | World → screen conversion |
| `LiftRunner.swift` | 60Hz physics loop + ceiling callback |

#### [NEW] Features/Gameplay/Shared/Components/
| File | Purpose |
|---|---|
| `CircularJoystickRingShape.swift` | Ring path |
| `CircularJoystickView.swift` | Circular drag control |
| `PullButton.swift` | "PULL" hold-to-crank |
| `GearRoleLabel.swift` | "Driver" / "Follower" pill with leader line |
| `GearRoleLabelLayer.swift` | Positions both labels |
| `GameplayDialogueLayer.swift` | Speech bubble + typewriter |
| `GearSelectionTapLayer.swift` | Tap targets over projected gear positions |
| `CraneAlignmentLayer.swift` | Scrim + illustration overlay |
| `CraneAlignmentIllustration.swift` | Hand+iPad+crane line art |
| `GearDetectingLayer.swift` | "Looking at your gears…" chip |
| `DetectionManualFallbackSheet.swift` | 3 gear type cards for manual selection |

---

### Step 11: Level 1 ViewModel + View + Wiring

#### [NEW] Features/Gameplay/Level1/
| File | Purpose |
|---|---|
| `Level1PhaseCommands.swift` | Side effects of entering a phase |
| `Level1SceneDirector.swift` | Choreography: glow, sprite, perch, spotlight |
| `Level1ViewModel.swift` | Holds phase, delegates to collaborators (~120 lines) |
| `Level1ViewModel+DetectionObserver.swift` | Translates detection events → Level1Events |
| `Level1View.swift` | ZStack of 4 layers + switch on phase (~45 lines) |
| `Level1Script.swift` | All dialogue strings + bold spans |
| `Level1Tuning.swift` | LevelTuning values for Level 1 |

#### [NEW] Features/Gameplay/Level1/Components/
| File | Purpose |
|---|---|
| `Level1HUDLayer.swift` | Chip, role labels, joystick, PULL |
| `Level1TutorialLayer.swift` | Spotlight overlays + dialogue |
| `Level1HandOverLayer.swift` | "It's your turn!" instruction |

---

### Step 12: Success Overlay + Retry

#### [NEW] Features/Result/
| File | Purpose |
|---|---|
| `SuccessOverlay.swift` | Scrim + "CHEESE SECURED!" + stars + mouse + buttons |
| `CheeseStarRow.swift` | Three cheese-star images |
| `SuccessActionsRow.swift` | Retry (bottom-left) + Next (bottom-right) buttons |

---

### Step 13: PreviewData

#### [NEW] PreviewData/
| File | Purpose |
|---|---|
| `PreviewGearPair.swift` | Dummy 8T + 24T pair |
| `MockCraneScene.swift` | Static mock for AR-dependent previews |

---

## Verification Plan

### Automated Tests
```bash
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
xcodebuild -project 'Cheese Heist.xcodeproj' -scheme 'Cheese Heist' \
  -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M5)' build
```

### Unit Tests (12 suites, ~975 lines)
- `GearRatioCalculatorTests` — all 9 pairs, sign of ω_follower, reciprocal identity
- `ActuatorModelTests` — no-load speed, stall boundary, no negative ω
- `WinchModelTests` — height monotonicity, clamp at liftHeight, minLiftDuration clamp
- `LiftFeasibilityEvaluatorTests` — every pair succeeds at Level 1 tuning
- `GearTrainSimulatorTests` — half-stop at 50%, full run
- `Level1PhaseMachineTests` — every Phase × Event pair matches §8 table
- `GearPairVoteTests` — convergence + rejection
- `CircularDragTrackerTests` — CW/CCW detection
- `SceneLayoutFromAssignmentTests` — purely data-driven
- `DepthClusterSolverTests` — nearest cluster logic
- `CranePairCompleterTests` — ray-vs-sphere with synthetic geometry
- `GearRoleAssignmentTests` — swap is involutive

### Manual Verification
- Simulator builds successfully with capability gate showing UnsupportedDeviceView
- All Xcode previews render for every component and layer
- Device testing on iPad Pro with LiDAR per PRD-Level1 §12.3
