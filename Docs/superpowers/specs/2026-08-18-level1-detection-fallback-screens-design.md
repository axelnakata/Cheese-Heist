# Level 1 detection fallback screens — design

Source: Figma `Little Einstein Board`, node `942:107` ("Fallback screen" section,
frames `crane ga ke detect di tengah game` and `gear kurang atau lebih dari 2`).

## Purpose

Level 1 gameplay currently has no live feedback for two detector conditions that
already occur in practice:

1. During setup, the child builds with the wrong number of gears (not exactly 2).
   Today this is silent until a 12s detection timeout fires `manualFallback`.
2. Mid-game, after a crane has been locked in and gameplay has started, the crane
   goes out of camera view. `GearDetectionService.hasLostGears` already detects this
   but is completely unwired — no view or view model reads it.

This adds two fallback overlays that surface both conditions live, without
introducing new `Level1Phase` cases or touching the phase machine — consistent with
the existing invariant that "tracking is a HUD note, never a phase change"
(`Level1PhaseMachine.swift`).

## Scope

In scope:
- A "wrong gear count" overlay, shown only during setup (`.aligningCrane` /
  `.detectingGears`, i.e. pre-lock), triggered by a new live signal, dismissed by a
  manual "I fixed it!" button.
- A "crane not detected" overlay, shown only mid-game (post-lock, once tracking was
  established and then lost), fully automatic show/hide, no button.
- New artwork for both, exported from the Figma frame during implementation.

Out of scope:
- Any change to `Level1Phase`, `Level1PhaseMachine`, `Level1InputGate`, or
  `Level1PhaseCommands`.
- Any change to the existing 12s-timeout `manualFallback` phase / `DetectionManualFallbackSheet` flow — this is additive, not a replacement.
- Reworking `GearDetectionService`'s locking/vote algorithm.

## Design

### 1. Wrong gear count overlay (setup-only, manual dismiss)

**Signal:** New published property on `GearDetectionService`:
`liveGearCountIssue: GearCountIssue?` (`.tooFew`, `.tooMany(Int)`), computed inside
the existing `tick()` in `GearDetectionService+Loop.swift`, only while **not yet
locked**. Today an off-count frame silently resets the lock vote
(`+Loop.swift:47-49`); this makes that condition observable instead of silent.

Debounced ~1s (mirroring `trackingLostAfter`'s pattern for `hasLostGears`) so a
single stray frame doesn't flip the overlay on/off. Cleared the moment a good
2-gear frame returns, or on lock.

**Presentation:** `Level1View` holds local `@State private var dismissedGearCountIssue = false`,
reset to `false` whenever `liveGearCountIssue` transitions from `nil` to non-nil
(a new mismatch episode starts). The new `WrongGearCountLayer` overlay shows when
`detection.liveGearCountIssue != nil && !dismissedGearCountIssue`.

Tapping **"I fixed it!"** (`PrimaryButton`, reused) sets `dismissedGearCountIssue = true`.
If the live count is still wrong, the debounce timer raises a fresh episode shortly
after and the screen reappears automatically — giving the "manual confirmation" feel
of the button while staying driven by real detection underneath, per the "Re-check
detection" behavior confirmed with the user.

**Content:** Title text ("I need exactly 2 gears to build this crane! Let's fix that
and try again."), numbered gear-highlight illustration (new static artwork exported
from the Figma frame's `crane guidance fallback 1` + "1"/"2" labels — not a dynamic
per-detection overlay, matching the codebase's existing preference for static
illustrations over live projected geometry at this stage), `PrimaryButton("I fixed it!")`.
Full-screen `ScrimOverlay` behind it, matching `CraneAlignmentLayer`'s composition.

### 2. Crane not detected overlay (mid-game, fully automatic)

**Signal:** Wires up the already-implemented `GearDetectionService.hasLostGears`
(currently set by `+Loop.swift` but read nowhere in the app). Add
`detection.hasLostGears` to `Level1View`'s existing `.onChange` trio
(`trackingVersion`, `phase`, `isViable`) if needed for prompt re-render — but since
this overlay is driven directly by a `@Observable` property read in the view body,
no explicit `.onChange` plumbing into `observeDetection()`/`Level1ViewModel` is
required; it's a pure read.

**Presentation:** `CraneLostLayer` shows exactly when `detection.hasLostGears == true`,
hides the instant it flips back to `false`. No button, no dismiss state — fully
automatic per the user's explicit requirement ("once a gear is back in detection the
fallback screen should disappear automatically").

**Content:** Mouse character + speech bubble reading "Where did your crane go? Put
your crane back on the center of the camera!", over a camera guidance outline.
Follows `BlueprintCheckInBubble`'s pattern — a static 2D mouse image
(`Resources/Assets.xcassets` mouse imageset, e.g. `Mouse_panic1` or similar,
picked to match the Figma frame) + hand-rolled `SpeechBubbleShape` bubble — rather
than `GameplayDialogueLayer`'s AR-anchored mouse, since this screen must render
identically whether or not a live AR scene/anchor still exists once tracking is lost.

### 3. Shared structure

- Both new views live in `Features/Gameplay/Level1/` as composition-only files
  (`WrongGearCountLayer.swift`, `CraneLostLayer.swift`) — they draw nothing
  themselves, only compose `Commons/Components` pieces (`ScrimOverlay`,
  `PrimaryButton`, text via `.appText`/`AppFont`, existing mouse/bubble components),
  per the project's "Level1 doesn't draw" rule.
- Both added to `Level1View.overlays`, alongside the existing
  `CraneAlignmentLayer`/`DetectionManualFallbackSheet`/`GameplayDialogueLayer`
  layers, gated on the conditions above (not on `Level1Phase` — an *additional*
  condition layered on top of whatever phase is already showing).
- All new artwork, colors, spacing pulled from Figma node `942:107` and its two
  child frames (`942:108`, `942:117`), following the design-system rules in
  `CLAUDE.md` (`AppColor`, `AppSpacing`, `layoutScale`, no literals).

### 4. Testing

- `GearDetectionServiceTests` (or wherever `hasLostGears`/`trackingLostAfter` is
  currently tested): add coverage for `liveGearCountIssue`'s debounced
  transitions — enters `.tooFew`/`.tooMany` after the debounce window, clears
  immediately on a correct frame, never fires once locked.
- No `Level1PhaseMachine` / `Level1PhaseMachineTests` changes needed — nothing here
  touches phases or events.
- Manual verification on device (per `CLAUDE.md`, AR/Vision code can't be exercised
  in the simulator): build with wrong gear count → overlay appears, fix count + tap
  "I fixed it!" → overlay dismisses (or reappears if still wrong); lock a valid pair,
  move crane out of frame → overlay appears; move it back → overlay disappears
  automatically.

## Open questions

None outstanding — both trigger conditions, dismiss behavior, and component reuse
were confirmed with the user during brainstorming.
