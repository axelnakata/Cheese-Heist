# Product Requirements Document — **Cheese Heist**
### AR Gear-Ratio Learning App for LEGO Technic Robotics Classes (iPadOS)

| | |
|---|---|
| **Document version** | 1.0 |
| **Date** | 10 August 2026 |
| **Owner** | Axel — Tech Lead |
| **Team** | 2 developers (`dev/axel`, `dev/nay`) + design |
| **Platform** | iPadOS 18+, **iPad Pro with LiDAR only** |
| **Stack** | SwiftUI, RealityKit, ARKit, Vision + Core ML (YOLOv11), MVVM + `@Observable` |
| **Design source** | Figma `Little Einstein Board` → page `hifi` |
| **Scope of this PRD** | Design System · Splash + Cutscene · Blueprint · Level 1 |

---

## 0. Real World vs. Virtual World — the contract

This separation is the single most important framing in the product. Every feature spec below refers back to it.

| | **Real world (physical, built by the child)** | **Virtual world (rendered by the app)** |
|---|---|---|
| **Structure** | LEGO crane tower + crane arm (built from the in-app Blueprint) | — |
| **Mechanism** | LEGO Technic gears (8T / 24T / 40T), axles, bushings, 1×16 Technic beam | **Virtual gear twins** overlaid 1:1 on the detected physical gears |
| **Load** | — | Cheese (the objective and the payload mass) |
| **Actor** | — | Mouse — stands on the **driver** gear, is the actuator |
| **Antagonist** | — | Cat — wanders on a fixed radius around the cheese |
| **Transmission** | — | Rope, wound on the **follower** gear axle |
| **Surface** | Flat table / floor detected by LiDAR | AR world anchor, plane visualisation |

**Why the gears are overlaid instead of animated physically:** the physical build has no actuator. The virtual twin is what rotates on screen, so the child sees cause (their crank input on the driver) and effect (rope, cheese, speed) without any motor in the LEGO model. This is the core illusion of the product and it must never break — see §7.4 for the occlusion rules that keep it convincing.

---

## 1. Background & Problem

Gear ratio is the first genuine mechanical-advantage concept in a robotics curriculum, and it is the first place 6–10 year olds fall off. The reason is that the concept is *invisible*: turning a LEGO crank shows the child that something happens, but not **why** a small gear driving a big gear feels different from the reverse. Classroom teaching falls back on formulas (`ratio = N_follower / N_driver`), which is exactly the wrong tool for an age group that has not met division.

Two failure modes in current practice:

1. **No feedback loop.** A hand-cranked LEGO crane lifts its load either way. Without a stopwatch and a heavy enough load, the speed/torque trade-off produces no perceptible difference, so nothing is learned.
2. **Vocabulary before experience.** "Driver" and "follower" are taught as labels on a diagram before the child has ever *chosen* which gear is which and felt the consequence.

**Our response:** AR overlays a virtual, physics-accurate transmission on the child's own LEGO build. The child chooses the driver, cranks, and watches the rope and the cheese respond. The maths runs at full fidelity in the backend; the child sees only cheese moving fast or slow.

---

## 2. Target Users & Learning Objectives

### 2.1 Primary user
Children aged **6–10** in a robotics class, working with a physical LEGO Technic kit and a shared iPad Pro, supervised by an instructor.

**Assumed baseline:** can read short sentences; may not read fluently. Has no physics. Has basic counting, no division. Has used a tablet.

**Consequences for design (non-negotiable):**
- No numbers, formulas, units, or ratio notation anywhere in the child-facing UI. `5:1` never appears on screen.
- Every instruction is ≤ 12 words and paired with a visual or a character line.
- Every screen has exactly one affordance. No screen offers two things to tap.
- All comprehension is demonstrated by *doing*, never by answering a question.

### 2.2 Secondary user
The instructor: needs the build to be reproducible across a class, needs a session to fit a ~20-minute block, and needs a manual override when computer vision misfires (see §8.6).

### 2.3 Learning objectives

| ID | Objective | Level | Evidence of learning |
|---|---|---|---|
| **LO-1** | Identify that in a meshed pair, one gear is *turned* (driver) and one is *turned by* it (follower) | L1 | Child assigns the driver role and correctly predicts which gear the mouse stands on |
| **LO-2** | Observe that meshed gears turn in **opposite** directions | L1 | Child observes and can point out the direction reversal |
| **LO-3** | Understand that gear choice changes lifting **speed** vs. **strength** | L2 | Child selects a combination that succeeds where a previous one failed |

**Level 1 deliberately does not teach LO-3.** It teaches vocabulary and reversal only. This is why L1's payload is featherweight (§6.5) — *every* combination must succeed, so the child never fails at a lesson that has not been taught yet.

---

## 3. Scope

### 3.1 In scope — four workstreams

| # | Workstream | Deliverable | Figma |
|---|---|---|---|
| **WS-1** | **Design System** | Token layer (colour, typography, spacing, radius) + 5 shared components, zero hard-coded values | `Design System` (603:13) |
| **WS-2** | **Splash + Cutscene** | Splash, LiDAR gate, surface-scan guideline, 6 narrative beats | Section `Splash + Cutscene` (431:83) |
| **WS-3** | **Blueprint** | 3-step build guide with media + text, forward/back navigation | Section `Blueprint` (431:85) |
| **WS-4** | **Level 1** | Crane alignment → gear detection → virtual overlay → driver selection → crank → lift → success | Section `Level 1` (431:87) |

### 3.2 Out of scope for this PRD
Level 2 and Level 3 (physics domain in §6 is built to serve them, but no UI), fail screens, scoring/stars, multi-device sync, localisation, accessibility audit, analytics, App Store submission.

### 3.3 Explicit non-goals
- Non-LiDAR device support. The app **hard-blocks** on unsupported hardware. See §5.
- Physical gear rotation sensing. The physical gears never move during play.
- Free-form LEGO builds. The Blueprint is a contract; detection assumes the blueprint geometry.

---

## 4. Success Criteria (Level 1 release)

| ID | Criterion | Threshold |
|---|---|---|
| AC-1 | Surface detected and scene anchored | ≤ 8 s on a well-lit table |
| AC-2 | Gear pair detected and classified correctly | ≥ 90 % of attempts at the prescribed alignment distance |
| AC-3 | Virtual gear twin visually registered to the physical gear | ≤ 5 mm positional error at 40 cm |
| AC-4 | Anchored content survives the camera leaving and re-entering the scene | 100 % — cheese, cat, mouse return in place |
| AC-5 | Sustained frame rate during crank + lift | ≥ 55 fps |
| AC-6 | Child completes L1 unaided after the cutscene | ≥ 80 % of a 10-child pilot |
| AC-7 | No file in the codebase exceeds the line budget in §8.4 | 100 %, CI-enforced |

---

## 5. Hardware Requirement — LiDAR is mandatory and checked first

**Rule: every code path assumes a LiDAR scene depth stream is available. There is no non-LiDAR fallback.**

Justification — three requirements each independently force it:

1. **Fast, reliable horizontal plane detection.** Classroom tables are white, matte and low-texture. Feature-point plane detection on such surfaces is slow and unstable; LiDAR gives a plane in 1–2 s regardless of texture.
2. **Depth-correct 2D→3D projection of YOLO detections.** A YOLO bounding box is a 2D screen rectangle. Converting its centre into a world position needs a depth value at that pixel. `ARFrame.sceneDepth` gives it directly and accurately at 8 mm–class objects; feature-point raycasting does not.
3. **Occlusion.** The mouse must be able to stand *behind* a LEGO brick and the cheese must sit *on* the table plausibly. This requires `.personSegmentationWithDepth`-class occlusion driven by the scene mesh.

### 5.1 Capability gate

Checked once, at launch, before any AR view is constructed:

```
ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh)
ARWorldTrackingConfiguration.supportsFrameSemantics(.sceneDepth)
```

If either is `false` → route to `UnsupportedDeviceView`, a terminal screen. No "continue anyway" button. Shipping a degraded non-LiDAR path would double the QA surface and produce exactly the registration errors (AC-3) that make the overlay illusion collapse.

### 5.2 Session configuration (single source of truth, `ARSessionManager`)

| Setting | Value | Reason |
|---|---|---|
| `planeDetection` | `.horizontal` | Table/floor only |
| `sceneReconstruction` | `.mesh` | Occlusion + raycast target |
| `frameSemantics` | `.sceneDepth` | Depth at detection pixels |
| `environmentTexturing` | `.automatic` | Believable metal gears |
| `isCollaborationEnabled` | `false` | Single device |
| `worldAlignment` | `.gravity` | Rope must fall down |

---

## 6. Domain Model — Gear Physics

> **Design rule: the maths is invisible to the child and exact in the code.** The child never sees a number. The simulation is SI, deterministic, and unit-tested. This section is the specification for `Core/Gear/` and is shared by Level 1, 2 and 3 — it lives in `Core`, not in `Features/Gameplay/Level1`.

### 6.1 Gear specification

LEGO Technic spur gears are **module 1.0 mm**, so pitch diameter in millimetres equals the tooth count. This gives clean, real numbers.

| Type | Teeth `N` | Pitch diameter | Pitch radius |
|---|---|---|---|
| `.eightTooth` | 8 | 8.0 mm | 4.0 mm |
| `.twentyFourTooth` | 24 | 24.0 mm | 12.0 mm |
| `.fortyTooth` | 40 | 40.0 mm | 20.0 mm |

USDZ assets for all three already exist (converted from BrickLink Studio COLLADA). They are placed in `Resources/3DModels/Gears/` and referenced through `GearType.modelName` — never by string literal at the call site.

### 6.2 Ratio and direction

```
i  =  N_follower / N_driver           (transmission ratio)

ω_follower  =  − ω_driver / i          (sign flip = direction reversal)
τ_follower  =   τ_driver · i · η       (η = mesh efficiency, 0.94 for one mesh)
```

The **minus sign is the whole of LO-2** and must never be shortcut. `GearTrain` returns a signed angular velocity; the renderer applies it verbatim.

Direction convention (fixed, single-direction only):
- **Driver rotates clockwise** when viewed from the camera side, along the gear's local −Z axis.
- **Follower therefore rotates counter-clockwise.**
- There is no reverse. Counter-clockwise crank input produces no rotation and triggers a "wrong way" nudge.

All nine ordered pairs, for reference:

| Driver → Follower | `i` | Follower turns per driver turn | Character |
|---|---|---|---|
| 8 → 8 / 24 → 24 / 40 → 40 | 1 | 1 | neutral |
| 8 → 24 | 3 | ⅓ | strong, slow |
| 8 → 40 | 5 | ⅕ | strongest, slowest |
| 24 → 40 | 5/3 | 0.6 | strong, slow |
| 24 → 8 | ⅓ | 3 | fast, weak |
| 40 → 8 | ⅕ | 5 | fastest, weakest |
| 40 → 24 | 0.6 | 5/3 | fast, weak |

### 6.3 Winch (rope drum)

The rope is wound on the bare LEGO axle carried by the follower gear.

```
r_drum  = 2.5 mm  (LEGO axle, effective winding radius)
v_rope  = |ω_follower| · r_drum          (linear rope speed, m/s)
h(t)    = ∫ v_rope dt                    (cheese height, clamped to h_max)
τ_load  = m_cheese · g · r_drum          (torque the load applies at the drum)
```

### 6.4 Actuator model — the mouse

The mouse is **not** a constant-velocity source. It is a torque source with a linear torque–speed characteristic, exactly like a DC motor or a muscle:

```
τ_driver(ω)  =  τ_stall · (1 − ω_driver / ω_noLoad)
```

Steady state is reached when driver torque equals the reflected load:

```
ω_driver  =  ω_noLoad · ( 1 − τ_load / (i · η · τ_stall) )
ω_follower = ω_driver / i
```

**Lift feasibility:** the load can be lifted iff `i · η · τ_stall > τ_load`. If the term in parentheses is ≤ 0, `ω_driver = 0` — the mouse strains and nothing moves. Level 1 is tuned so this branch is unreachable; Level 2 is tuned so it is the puzzle.

**Why a torque–speed curve rather than constant ω:** with constant angular velocity, torque is infinite and the "too weak to lift" state is impossible to express without a hard-coded special case. The curve gives strain, stall and speed-under-load for free, from one equation, and it is the same equation a real motor obeys. It is ~15 lines of code and it is what makes Level 2 buildable without rewriting Level 1.

### 6.5 Joystick input — engagement gate, not a throttle

The circular joystick controls **whether** the mouse cranks, not **how fast**.

```
isCranking = (signed angular finger displacement in the last 150 ms) > θ_threshold
             AND direction is clockwise
```

- Finger fast or slow → identical `ω_driver`.
- Finger stops → `ω_driver → 0` over a 0.25 s ease-out, rope stops, cheese holds (ratchet, no back-drive).

**Justification, and this is a pedagogy decision not a convenience one:** if crank speed mapped to rope speed, the child would have two variables affecting the outcome — their own hand and the gear ratio — and would attribute the difference to their hand. Every child believes they can crank faster. Gating rather than throttling makes the gear ratio the *only* thing that changes the result, which is the entire point of the app.

### 6.6 Level tuning

`LevelTuning` is a value type; no level hard-codes a physics constant.

| Parameter | Level 1 value | Reason |
|---|---|---|
| `payloadMass` | 0.010 kg | Featherweight — every ratio succeeds (LO-3 not yet taught) |
| `stallTorque` | 0.006 N·m | Mouse "muscle" |
| `noLoadAngularVelocity` | 12.0 rad/s | ≈ 1.9 rev/s crank |
| `meshEfficiency` | 0.94 | Single spur mesh |
| `winchRadius` | 0.0025 m | LEGO axle |
| `liftHeight` | 0.06 m | Table → crane arm tip |
| `minLiftDuration` | 1.2 s | Presentation floor (see risk R-05) |

Worked example, `i = 3` (8T driver → 24T follower): `τ_load = 0.010 · 9.81 · 0.0025 = 2.45×10⁻⁴ N·m`; `ω_driver = 12 · (1 − 2.45e-4 / (3 · 0.94 · 0.006)) = 11.8 rad/s`; `ω_follower = 3.93 rad/s`; `v_rope = 9.8 mm/s`; lift time ≈ **6.1 s**. Reverse the pair (`i = ⅓`) → ≈ **0.7 s**, clamped up to `minLiftDuration`.

> ⚠️ **Read risk R-05 (§13) before tuning.** The lift-time spread between reciprocal pairs is `i²` — 9× for an 8/24 pair, **25×** for an 8/40 pair. This is real physics and cannot be "fixed" without lying to the child. The mitigation is a Level 1 blueprint that mandates the 8T + 24T pair.

---

## 7. Design System (WS-1)

Source of truth: Figma frame **`Design System`** (node `603:13`). Values below were read from the file, not eyeballed.

**Rule: no view may contain a colour literal, a font name, a numeric font size, a corner radius, or a magic spacing number.** Every one of those is a token. A pull request containing `Color(red:green:blue:)`, `.font(.system(size:))` or `.cornerRadius(42.5)` is rejected at review.

### 7.1 Colour palette (raw tokens)

| Figma label | Hex | Token name | Notes |
|---|---|---|---|
| Main | `#FFB800` | `Palette.cheeseYellow` | Primary action / brand |
| Main | `#013A71` | `Palette.blueprintNavy` | Blueprint, instruction surfaces |
| Secondary | `#3E7DCA` | `Palette.skyBlue` | Follower-gear highlight |
| Secondary | `#CE7A00` | `Palette.crustAmber` | Driver-gear highlight, pressed states |
| Text | `#000000` | `Palette.ink` | Body on light surfaces |
| Background | `#F9F2E4` | `Palette.parchment` | App background, strokes on dark |
| — | `#FFFFFF` | `Palette.pureWhite` | Component strokes, HUD text on camera |

### 7.2 Semantic tokens (what views actually use)

Two-layer tokens. Views reference **semantic** names only; if the brand changes, one file changes.

| Semantic token | Resolves to | Used by |
|---|---|---|
| `AppColor.accent` | `cheeseYellow` | Primary button, CTA, speech bubble fill |
| `AppColor.accentStroke` | `pureWhite` @ 1.27 pt | Button borders |
| `AppColor.surfaceBackground` | `parchment` | Non-AR screen background |
| `AppColor.surfaceInstruction` | `blueprintNavy` @ 60 % | Instruction chip |
| `AppColor.surfaceBlueprint` | `blueprintNavy` | Blueprint sheet |
| `AppColor.surfaceScrim` | `ink` @ 55 % | Dim behind spotlight / success overlay |
| `AppColor.textPrimary` | `ink` | Body on parchment / on yellow |
| `AppColor.textInverted` | `parchment` | Text on navy |
| `AppColor.textOnCamera` | `pureWhite` | HUD text over the AR feed |
| `AppColor.roleDriver` | `crustAmber` | Driver gear ring + label |
| `AppColor.roleFollower` | `skyBlue` | Follower gear ring + label |
| `AppColor.stateValid` | `#4CAF50` | Surface-scan ring, valid alignment |
| `AppColor.stateInvalid` | `#E53935` | Rejected surface (the red ✗) |

`stateValid` / `stateInvalid` are **not in the Figma frame** — they appear in the cutscene-guideline mockups as raster art. Design must add them to the Design System frame before implementation. Tracked as **OQ-1**.

### 7.3 Typography

Two families. **Mickies** (custom, display) and **Nunito** (custom, text). Both must be bundled and registered in `Info.plist` under `UIAppFonts`.

| Token | Family / weight | Size | Line height | Tracking | Figma |
|---|---|---|---|---|---|
| `.largeTitle` | Mickies Regular | 64 | 60 | 0.828 | `639:2` |
| `.title` | Nunito ExtraBold (800) | 36 | 40 | 0.828 | `639:9` |
| `.subtitle` | Nunito Bold (700) | 22 | 26 | 0.828 | `639:8` |
| `.body` | Nunito Regular (400) | 22 | 26 | 0.828 | `639:7` |
| `.dialogue` | Nunito Regular (400) | 24 | 26 | 0.828 | speech bubbles |

**Two inconsistencies found in the Figma file — these must be resolved, not silently absorbed:**

1. **Speech-bubble text is 24 pt, but the `body` token is 22 pt.** Two near-identical text sizes is a token smell. Either promote 24 pt to a real `.dialogue` token (documented above as the assumed resolution) or bring bubbles down to 22. **OQ-2.**
2. **Every Level 1 HUD string uses SF Pro, not Nunito** — `"Tap one of the gear to set it as a driver"` (SF Pro Bold 36), `"PULL"` (SF Pro Bold 36), `"CHEESE SECURED!"` (SF Pro Bold 62), `"Driver"` / `"Follower"` (SF Pro Regular 24). This is almost certainly leftover default styling rather than an intentional choice; a third typeface in a children's app is a regression. **The implementation will use Nunito/Mickies tokens throughout and Level 1 mockups should be updated to match. OQ-3.**
3. `"Great job!"` is `#FAC73C`, a fourth yellow not in the palette. Implementation uses `AppColor.accent`. **OQ-4.**

**Line-height handling.** SwiftUI's `lineSpacing` is additive and cannot be negative. `largeTitle` requests 60 pt leading on a 64 pt font — negative delta. Implementation clamps to `max(0, lineHeight − uiFont.lineHeight)` and accepts default leading for `largeTitle`; this is visually indistinguishable for the 1–2 line strings it is used on. Do not attempt to force it with `AttributedString` — not worth the complexity.

### 7.4 Layout scale

Every Figma frame is **1366 × 1024 pt** = iPad Pro 12.9″ points exactly. On 11″ (1194 × 834) all values must scale.

`LayoutScale` is a single environment value: `scale = geometryWidth / 1366`. Component sizes are declared at design scale and multiplied once. No view computes its own scale factor.

### 7.5 Spacing, radius, stroke tokens

| Token | Value |
|---|---|
| `AppSpacing.xs` / `s` / `m` / `l` / `xl` | 8 / 16 / 24 / 32 / 48 |
| `AppRadius.chip` | 30 |
| `AppRadius.bubble` | 42.5 |
| `AppRadius.pill` | 63.57 |
| `AppStroke.button` | 1.27 |
| `AppStroke.chip` | 1.50 |

### 7.6 Components (all live in `Commons/Components/`, none in a feature folder)

| Component | Figma | Size (design scale) | Spec |
|---|---|---|---|
| `PrimaryButton` | `639:64` | 210 × 78.14, radius `.pill` | Fill `accent`, stroke `accentStroke` 1.27, label `.title` in `pureWhite`, h-padding 19.07 |
| `LargeCTAButton` | `639:65` | 88.54 × 86.54, radius `.pill` | Same fill/stroke; icon-only, SF Symbol at 36 pt. Variants: `.next` (`arrow.right`), `.back` (`arrow.left`), `.retry` (`arrow.counterclockwise`), `.info` (`info.circle`) |
| `SpeechBubbleView` | `639:126` | height 85, radius `.bubble`, width hugs | Fill `accent`, tail bottom-left, text `.dialogue` in `textPrimary`, padding 30 h / 30 v. Must support a typewriter reveal and an optional bold span |
| `InstructionChip` | `639:142` | height 90, radius `.chip` | Fill `surfaceInstruction`, stroke `parchment` 1.5, text `.title` in `pureWhite`, padding 25 h / 30 v. Multi-line variant used by the surface-scan guideline |
| `TapToContinueHint` | `539:88`, `436:175` | — | `.body` in `textOnCamera`, 1 s pulse loop |

Each component ships with a `#Preview` covering all its variants, on both light and camera-feed backgrounds. Preview-driven development is mandatory: no component is merged without a working preview.

### 7.7 Design system file layout

```
Commons/DesignSystem/
├── Tokens/
│   ├── Palette.swift              (raw hex → Color, ~25 lines)
│   ├── AppColor.swift             (semantic aliases, ~35 lines)
│   ├── AppFont.swift              (TextStyle definitions, ~50 lines)
│   ├── AppSpacing.swift           (~15 lines)
│   ├── AppRadius.swift            (~12 lines)
│   └── AppStroke.swift            (~10 lines)
├── Extensions/
│   ├── Color+Hex.swift            (hex initialiser, ~35 lines)
│   ├── UIColor+Hex.swift          (RealityKit materials need UIColor, ~20 lines)
│   └── View+TextStyle.swift       (.appText(_:) modifier, ~30 lines)
└── Layout/
    ├── LayoutScale.swift          (~20 lines)
    └── EnvironmentValues+Layout.swift (~15 lines)
```

### 7.8 Reference implementation — hex extension

```swift
import SwiftUI

extension Color {
    /// Creates a colour from a 6- or 8-digit hex string ("#FFB800", "FFB800", "#013A7199").
    /// Invalid input resolves to `.clear` so a typo is visible in preview rather than silently black.
    init(hex: String) {
        let cleaned = hex.trimmingCharacters(in: .whitespacesAndNewlines)
                         .replacingOccurrences(of: "#", with: "")
        var raw: UInt64 = 0
        guard Scanner(string: cleaned).scanHexInt64(&raw) else {
            self = .clear
            return
        }

        let r, g, b, a: Double
        switch cleaned.count {
        case 6:
            r = Double((raw & 0xFF0000) >> 16) / 255
            g = Double((raw & 0x00FF00) >> 8)  / 255
            b = Double( raw & 0x0000FF)        / 255
            a = 1
        case 8:
            r = Double((raw & 0xFF00_0000) >> 24) / 255
            g = Double((raw & 0x00FF_0000) >> 16) / 255
            b = Double((raw & 0x0000_FF00) >> 8)  / 255
            a = Double( raw & 0x0000_00FF)        / 255
        default:
            self = .clear
            return
        }
        self.init(.sRGB, red: r, green: g, blue: b, opacity: a)
    }
}
```

```swift
// Palette.swift — raw tokens. Nothing outside AppColor may reference this type.
enum Palette {
    static let cheeseYellow  = Color(hex: "#FFB800")
    static let blueprintNavy = Color(hex: "#013A71")
    static let skyBlue       = Color(hex: "#3E7DCA")
    static let crustAmber    = Color(hex: "#CE7A00")
    static let ink           = Color(hex: "#000000")
    static let parchment     = Color(hex: "#F9F2E4")
    static let pureWhite     = Color(hex: "#FFFFFF")
    static let successGreen  = Color(hex: "#4CAF50")   // pending OQ-1
    static let warningRed    = Color(hex: "#E53935")   // pending OQ-1
}
```

```swift
// AppFont.swift — a TextStyle carries everything a label needs.
struct TextStyle {
    let fontName: String
    let size: CGFloat
    let lineHeight: CGFloat
    let tracking: CGFloat
}

enum AppFont {
    private enum Family {
        static let display     = "Mickies-Regular"
        static let regular     = "Nunito-Regular"
        static let bold        = "Nunito-Bold"
        static let extraBold   = "Nunito-ExtraBold"
    }
    private static let standardTracking: CGFloat = 0.828

    static let largeTitle = TextStyle(fontName: Family.display,   size: 64, lineHeight: 60, tracking: standardTracking)
    static let title      = TextStyle(fontName: Family.extraBold, size: 36, lineHeight: 40, tracking: standardTracking)
    static let subtitle   = TextStyle(fontName: Family.bold,      size: 22, lineHeight: 26, tracking: standardTracking)
    static let body       = TextStyle(fontName: Family.regular,   size: 22, lineHeight: 26, tracking: standardTracking)
    static let dialogue   = TextStyle(fontName: Family.regular,   size: 24, lineHeight: 26, tracking: standardTracking)
}
```

```swift
// View+TextStyle.swift — the only place line-height maths exists.
private struct AppTextModifier: ViewModifier {
    let style: TextStyle
    @Environment(\.layoutScale) private var scale

    func body(content: Content) -> some View {
        let size = style.size * scale
        let uiFont = UIFont(name: style.fontName, size: size) ?? .systemFont(ofSize: size)
        let extraLeading = max(0, style.lineHeight * scale - uiFont.lineHeight)

        return content
            .font(.custom(style.fontName, size: size))
            .tracking(style.tracking * scale)
            .lineSpacing(extraLeading)
            .padding(.vertical, extraLeading / 2)
    }
}

extension View {
    func appText(_ style: TextStyle) -> some View { modifier(AppTextModifier(style: style)) }
}
```

---

## 8. Engineering Conventions

Extends the **Team Tech & Git Agreement** already agreed. Everything in that document stands; this section adds the rules specific to this project.

### 8.1 Inherited from the team agreement (unchanged)

**Naming** — camelCase for variables/functions/properties and enum cases; PascalCase for types and file names.

**MVVM layers**
- **Model** — pure data. Properties and, if needed, a memberwise or convenience initialiser. **No logic.** No formatting, no networking, no `@Observable`.
- **View** — SwiftUI only. Binds to its ViewModel and composes components. **No business logic.**
- **ViewModel** — presentation logic. Uses the **`@Observable` macro**, never `ObservableObject` + `@Published`. Talks to Managers/Services.
- **Manager / Service** — one manager, one job.

**Git** — `main`, `dev/axel`, `dev/nay`. Commit to your branch → PR into `main` → review by the other dev → merge.

**Commits** — `type(scope): short description` with `feat` / `fix` / `refactor` / `style` / `docs`.

**PRs** — 1 approval required. Description states what changed, how tested (device + iOS version), and includes a screen recording for anything AR-visible.

### 8.2 Additions to the commit convention

Scopes are standardised so history stays greppable:

`designSystem` · `splash` · `cutscene` · `blueprint` · `gameplay` · `level1` · `level2` · `arCore` · `vision` · `gearPhysics` · `entities` · `audio` · `app`

Two additional types for this project:

| Type | Use for | Example |
|---|---|---|
| `chore` | tooling, config, assets, dependency bumps | `chore(entities): add 24T gear usdz` |
| `test` | test-only changes | `test(gearPhysics): cover stall condition` |

### 8.3 Additional branch rule

Feature branches may be cut from a dev branch for anything expected to exceed two days: `dev/axel/level1-gear-detection`. They merge back into `dev/axel`, never directly into `main`. This keeps the two-branch PR flow intact while allowing long-running AR work to be parked.

### 8.4 File size discipline — enforced, not aspirational

This is the rule you care about most, so it is a CI gate rather than a review convention.

| Artefact | Warning | **Hard fail** |
|---|---|---|
| Any Swift file | 150 lines | **200 lines** |
| View `body` | 40 lines | **60 lines** |
| ViewModel type body | 120 lines | **160 lines** |
| Any function | 30 lines | **50 lines** |
| Type nesting depth | — | 2 |

Additional structural rules:

1. **One type per file.** No `struct` + its helper `struct` in one file. Extract, even if the helper is 12 lines.
2. **Views compose, they do not draw.** A View file contains layout containers, component invocations and bindings. The moment a View contains a `Shape`, a `Path`, a gradient definition or a bespoke `ViewModifier`, that thing moves to `Commons/Components/`.
3. **No `if`-tree in a body.** More than two branches → a `switch` over a state enum where each case returns a named subview, and each subview is its own file.
4. **ViewModel splitting.** When a ViewModel approaches 160 lines, it is not "a big screen" — it is doing two jobs. Extract the second job to a Service in `Core/`. `Level1ViewModel` is the canonical example: it holds *state and routing only*, and delegates to `GearDetectionService`, `GearSimulationDriver` and `Level1SceneCoordinator` (§10.4).
5. **Extensions for protocol conformance** live in their own file: `Level1ViewModel+GearDetectionDelegate.swift`.

**Enforcement.** `.swiftlint.yml` at repo root, run as an Xcode build phase and in the PR check:

```yaml
included: [CheeseHeist]
excluded: [CheeseHeist/Resources, "**/*.generated.swift"]

file_length:
  warning: 150
  error: 200
type_body_length:
  warning: 120
  error: 160
function_body_length:
  warning: 30
  error: 50
closure_body_length:
  warning: 25
  error: 40
cyclomatic_complexity:
  warning: 8
  error: 12
nesting:
  type_level: { warning: 2 }

opt_in_rules:
  - explicit_init
  - force_unwrapping
  - implicitly_unwrapped_optional
  - redundant_type_annotation
  - unused_import
  - vertical_parameter_alignment_on_call

disabled_rules:
  - todo
```

A PR that fails SwiftLint does not get reviewed. The fix is always to split, never to raise the limit.

### 8.5 Reusability rule (the "shared vs. level" test)

Before a file is placed under `Features/Gameplay/Level1/`, answer: **"Could Level 2 want this?"**

- **Yes, unchanged** → `Core/` (domain, AR, entities) or `Commons/` (UI).
- **Yes, with different parameters** → `Features/Gameplay/Shared/`, parameterised.
- **Genuinely no** → `Features/Gameplay/Level1/`.

Applied concretely: the joystick, the PULL button, the gear-role labels, the crane-alignment reticle, the gear-highlight ring, the success/fail overlays, the speech-bubble sequencer, the gear physics, the rope entity and the cat wander controller **all fail the test** and therefore live in `Shared` or `Core`. What is genuinely Level-1-only is: its dialogue script, its `LevelTuning` values, and its state machine's tutorial ordering.

### 8.6 Preview-driven development

Every View and every component ships with a `#Preview` backed by dummy data from `PreviewData/`. AR-dependent views take an injected protocol (`ARSceneProviding`) so previews render a static mock scene. This is not optional — a screen that cannot be previewed cannot be reviewed, and reviewing AR work by rebuilding to device every time will kill the team's velocity.

---

## 9. Project Structure

```
CheeseHeist/
├── App/
│   ├── CheeseHeistApp.swift
│   ├── AppRoute.swift                        // enum: splash, cutscene, blueprint, level1, level2
│   ├── AppRouter.swift                       // @Observable, owns navigation path
│   └── RootView.swift                        // switch over route → feature view
│
├── Commons/
│   ├── DesignSystem/                         // see §7.7 for full breakdown
│   │   ├── Tokens/                           // Palette, AppColor, AppFont, AppSpacing, AppRadius, AppStroke
│   │   ├── Extensions/                       // Color+Hex, UIColor+Hex, View+TextStyle
│   │   └── Layout/                           // LayoutScale, EnvironmentValues+Layout
│   ├── Components/
│   │   ├── Buttons/
│   │   │   ├── PrimaryButton.swift
│   │   │   ├── LargeCTAButton.swift
│   │   │   └── LargeCTAButtonIcon.swift      // enum of variants
│   │   ├── Dialogue/
│   │   │   ├── SpeechBubbleView.swift
│   │   │   ├── SpeechBubbleShape.swift       // the Path lives here, not in the View
│   │   │   └── TypewriterText.swift
│   │   ├── Chips/
│   │   │   └── InstructionChip.swift
│   │   ├── Hints/
│   │   │   ├── TapToContinueHint.swift
│   │   │   └── PulsingModifier.swift
│   │   └── Overlays/
│   │       ├── ScrimOverlay.swift
│   │       └── SpotlightOverlay.swift        // dim-with-hole, used by tutorial beats
│   ├── Extensions/
│   │   ├── SIMD+Convenience.swift
│   │   ├── Entity+Lookup.swift
│   │   └── Comparable+Clamped.swift
│   └── Utilities/
│       ├── Debouncer.swift
│       └── Logger+Categories.swift
│
├── Core/
│   ├── AR/
│   │   ├── ARCapabilityChecker.swift          // §5.1 LiDAR gate
│   │   ├── ARSessionManager.swift             // owns ARSession + configuration
│   │   ├── ARSessionManager+Delegate.swift
│   │   ├── PlaneDetectionService.swift        // horizontal plane discovery + validity
│   │   ├── SceneDepthProvider.swift           // depth sampling at a screen point
│   │   ├── WorldAnchorRegistry.swift          // named anchors, survives camera loss (AC-4)
│   │   ├── OcclusionConfigurator.swift        // mesh occlusion + gear-twin exemption
│   │   └── ARRaycastService.swift
│   ├── Vision/
│   │   ├── GearDetector.swift                 // Vision + Core ML YOLOv11 wrapper
│   │   ├── GearDetectorConfiguration.swift
│   │   ├── RawGearObservation.swift           // model
│   │   ├── DetectionStabiliser.swift          // multi-frame voting
│   │   ├── DetectionToWorldMapper.swift       // bbox + depth → world transform
│   │   └── GearDetectionService.swift         // orchestrates the three above
│   ├── Gear/
│   │   ├── GearType.swift                     // model: teeth, pitch radius, asset name
│   │   ├── GearRole.swift                     // model: driver | follower
│   │   ├── GearPair.swift                     // model
│   │   ├── GearRatioCalculator.swift          // pure functions
│   │   ├── ActuatorModel.swift                // torque–speed curve
│   │   ├── WinchModel.swift                   // rope kinematics
│   │   ├── LiftFeasibilityEvaluator.swift
│   │   ├── GearTrainSimulator.swift           // integrates state per tick
│   │   ├── GearTrainState.swift               // model
│   │   └── LevelTuning.swift                  // model
│   ├── Entities/
│   │   ├── EntityFactory.swift                // protocol
│   │   ├── GearEntityFactory.swift
│   │   ├── GearHighlightRing.swift
│   │   ├── RopeEntity.swift
│   │   ├── RopeEntity+Update.swift
│   │   ├── CheeseEntity.swift
│   │   ├── MouseEntity.swift
│   │   ├── MouseAnimationController.swift
│   │   ├── CatEntity.swift
│   │   ├── CatWanderController.swift           // radius wander, §11.3
│   │   └── AnimationClipCatalog.swift
│   ├── Audio/
│   │   ├── AudioManager.swift
│   │   └── SoundEffect.swift
│   └── Persistence/
│       ├── PersistenceManager.swift
│       └── ProgressRecord.swift
│
├── Features/
│   ├── Splash/
│   │   ├── SplashModel.swift
│   │   ├── SplashView.swift
│   │   ├── SplashViewModel.swift
│   │   └── Components/
│   │       └── SplashLogoView.swift
│   ├── Cutscene/
│   │   ├── CutsceneModel.swift                // CutsceneBeat
│   │   ├── CutsceneScript.swift               // static data, the 6 beats
│   │   ├── CutsceneView.swift
│   │   ├── CutsceneViewModel.swift
│   │   ├── SurfaceScan/
│   │   │   ├── SurfaceScanModel.swift
│   │   │   ├── SurfaceScanView.swift
│   │   │   ├── SurfaceScanViewModel.swift
│   │   │   └── Components/
│   │   │       ├── SurfaceRingView.swift
│   │   │       ├── RecommendedPositionStrip.swift
│   │   │       └── SurfaceRejectedBadge.swift
│   │   └── Components/
│   │       ├── CutsceneStageView.swift        // RealityView host
│   │       ├── CutsceneDialogueLayer.swift
│   │       └── CutsceneCharacterLayer.swift
│   ├── Blueprint/
│   │   ├── BlueprintModel.swift               // BlueprintStep
│   │   ├── BlueprintScript.swift              // the 3 steps' content
│   │   ├── BlueprintView.swift
│   │   ├── BlueprintViewModel.swift
│   │   └── Components/
│   │       ├── BlueprintSheetView.swift
│   │       ├── BlueprintStepNumber.swift
│   │       ├── BlueprintMediaView.swift       // image now, video later
│   │       └── BlueprintInstructionList.swift
│   ├── Gameplay/
│   │   ├── Shared/
│   │   │   ├── Models/
│   │   │   │   ├── GameplayPhase.swift
│   │   │   │   ├── GearRoleAssignment.swift
│   │   │   │   └── LiftOutcome.swift
│   │   │   ├── ViewModels/
│   │   │   │   ├── CrankInputViewModel.swift
│   │   │   │   └── GearSelectionViewModel.swift
│   │   │   ├── AR/
│   │   │   │   ├── GameplaySceneCoordinator.swift
│   │   │   │   ├── GearOverlayPlacer.swift
│   │   │   │   ├── GearRotationDriver.swift
│   │   │   │   └── PayloadLiftDriver.swift
│   │   │   └── Components/
│   │   │       ├── CircularJoystickView.swift
│   │   │       ├── CircularJoystickShape.swift
│   │   │       ├── PullButton.swift
│   │   │       ├── GearRoleLabel.swift
│   │   │       ├── CraneAlignmentReticle.swift
│   │   │       ├── DetectionConfirmBar.swift
│   │   │       └── GameplayDialogueLayer.swift
│   │   ├── Level1/
│   │   │   ├── Level1Model.swift
│   │   │   ├── Level1View.swift
│   │   │   ├── Level1ViewModel.swift
│   │   │   ├── Level1Phase.swift              // the state machine
│   │   │   ├── Level1Script.swift             // dialogue only
│   │   │   ├── Level1Tuning.swift             // LevelTuning values only
│   │   │   └── Components/
│   │   │       ├── Level1HUDLayer.swift
│   │   │       └── Level1TutorialLayer.swift
│   │   └── Level2/                            // scaffolded, empty for now
│   ├── Result/
│   │   ├── ResultModel.swift
│   │   ├── SuccessView.swift
│   │   ├── ResultViewModel.swift
│   │   └── Components/
│   │       ├── CheeseStarRow.swift
│   │       └── ResultActionsRow.swift
│   └── Unsupported/
│       └── UnsupportedDeviceView.swift
│
├── PreviewData/
│   ├── PreviewGearPair.swift
│   ├── PreviewCutsceneScript.swift
│   └── MockARSceneProvider.swift
│
└── Resources/
    ├── Assets.xcassets
    ├── Fonts/                                 // Mickies, Nunito (Regular/Bold/ExtraBold)
    ├── ML/GearDetector.mlpackage
    ├── Audio/
    └── 3DModels/
        ├── Gears/  (gear_8t.usdz, gear_24t.usdz, gear_40t.usdz)
        ├── Characters/  (mouse.usdz, cat.usdz)
        └── Props/  (cheese.usdz, rope segment)
```

**Note the two things deliberately *not* under `Level1`:** the joystick + PULL button + role labels + alignment reticle (Shared/Components) and all physics (Core/Gear). Level 2 will reuse both verbatim; only `Level2Script.swift` and `Level2Tuning.swift` will differ, plus a fail-condition branch in its own phase enum.

---

## 10. Navigation & State Machines

### 10.1 App-level route

```swift
enum AppRoute: Hashable {
    case splash
    case surfaceScan
    case cutscene
    case blueprint
    case level1
    case level2
    case unsupportedDevice
}
```

`AppRouter` is `@Observable`, injected through the environment, and is the only type that mutates the route. No View calls another View's initialiser directly.

### 10.2 Full flow

```
launch
  └─ ARCapabilityChecker
       ├─ no LiDAR ──────────────────► UnsupportedDeviceView (terminal)
       └─ LiDAR OK
            └─ Splash  ("Tap to play")
                 └─ SurfaceScan  (recommended-position strip + green ring)
                      └─ tap ring ► world anchor placed
                           └─ Cutscene beats 1…6
                                └─ tap blueprint scroll
                                     └─ Blueprint steps 1 → 2 → 3
                                          └─ Level 1
                                               ├─ alignment
                                               ├─ gear detection
                                               ├─ overlay + confirm
                                               ├─ tutorial dialogue
                                               ├─ driver selection
                                               ├─ crank + lift
                                               └─ Success ► (retry | next)
```

### 10.3 Level 1 phase machine

```swift
enum Level1Phase: Equatable {
    case aligningCrane          // reticle, "Put your crane on the center of the camera"
    case detectingGears         // YOLO running, stabiliser voting
    case confirmingDetection    // twins shown, confirm / re-detect
    case introDialogue          // "Wow! Great job on making this crane!"
    case teachingDriver         // spotlight + "Look at the gear under my feet!"
    case selectingDriver        // "Tap one of the gear to set it as a driver"
    case teachingFollower       // "Now look at the gear holding the rope!"
    case readyToCrank           // joystick + PULL enabled
    case cranking               // simulation running
    case succeeded
}
```

Transitions are one-way except `confirmingDetection → detectingGears` (re-detect) and `selectingDriver ⇄ readyToCrank` (the child may re-tap the other gear to swap roles before cranking). There is **no fail state in Level 1** — see §2.3.

### 10.4 Level 1 ownership split (how the 160-line ViewModel cap is met)

| Type | Responsibility | Est. lines |
|---|---|---|
| `Level1ViewModel` | Holds `Level1Phase`, exposes intent methods (`didTapGear`, `didStartCrank`, …), routes to services. **No physics, no ARKit, no Vision.** | ~120 |
| `GearDetectionService` (Core) | Runs detector → stabiliser → world mapper, publishes a `GearPair` | ~90 |
| `GearTrainSimulator` (Core) | Integrates the physics per tick | ~80 |
| `GameplaySceneCoordinator` (Shared) | Owns the RealityKit scene graph, applies simulator output to entities | ~140 |
| `GearOverlayPlacer` (Shared) | Places/aligns the gear twins | ~70 |
| `CrankInputViewModel` (Shared) | Joystick angular-delta → `isCranking` | ~70 |

`Level1View`'s `body` is a `ZStack` of at most four layers — `RealityView`, `Level1HUDLayer`, `GameplayDialogueLayer`, `Level1TutorialLayer` — plus a `switch` on `phase`. It should be under 45 lines.

---

## 11. Feature Specifications

### 11.1 Splash — WS-2
**Figma:** `splash screen` (526:58)

| | |
|---|---|
| **Layout** | Full-bleed kitchen background image, centred `Cheese Heist` logo, `"Tap to play"` below in `.largeTitle` / `textOnCamera` |
| **Behaviour** | Whole screen is the tap target. Logo does a gentle 1.0 → 1.03 breathing loop. `"Tap to play"` pulses at 1 Hz |
| **On tap** | Ambient loop starts, route → `surfaceScan` with a 0.4 s cross-fade |
| **Precondition** | Never reached on a non-LiDAR device; the capability gate runs before `RootView` renders |

`SplashViewModel` owns only the animation phase and the tap handler. `SplashModel` is a single struct holding the logo asset name and tagline — kept as a model rather than a literal so the Level-2 build can reskin without touching the View.

---

### 11.2 Surface Scan / AR Guideline — WS-2
**Figma:** `cutscene guidelines` (522:91) and `cutscene guidelines - Fall Back` (522:208)

This is the AR positioning tutorial. It runs before any narrative content because everything after it is anchored.

**Composition (three layers over the camera feed):**

1. **Recommended-position strip** (top centre) — an `InstructionChip` containing four small illustrations of iPad-over-table positions with ✓ / ✗ marks. Static art; the chip is the shared component.
2. **Detected-plane ring** — a `SurfaceRingView` drawn in AR on the discovered horizontal plane. `AppColor.stateValid` (green) when a plane meeting the validity test is found; the fall-back frame shows a large red ✗ (`AppColor.stateInvalid`) over the feed when it is not.
3. **Instruction chip** (bottom centre) — two lines: `"Find a flat surface."` / `"Tap on the green circle to start!"`. Falls back to `"Look for a flat surface!"` in the rejected state.

**Plane validity test** (`PlaneDetectionService`):

| Check | Threshold | Why |
|---|---|---|
| Alignment | `.horizontal` | The crane must stand |
| Extent | ≥ 0.40 m × 0.40 m | Crane footprint + cat wander radius + cheese |
| Distance from camera | 0.25 m – 1.20 m | Below 0.25 m the gears leave frame; above 1.2 m an 8 T gear is too few pixels for detection |
| Depth confidence | mean ≥ `.medium` over the ring footprint | Reject glass, gloss and dark surfaces |

**On tap of the ring:** a `WorldAnchorRegistry` entry named `sceneRoot` is created at the tap point. **Every subsequent virtual object in the entire session is a child of `sceneRoot`.** This is the mechanism that satisfies AC-4 — the child can point the iPad at the ceiling and come back, and the cheese, cat and mouse are exactly where they were, because they were never camera-relative.

---

### 11.3 Cutscene — WS-2
**Figma:** `cutscene 1` … `cutscene 6` (522:59, 522:150, 522:258, 659:266, 659:284, 667:76)

Six narrative beats, all rendered in AR on `sceneRoot`. The child taps to advance; there is no auto-advance and no skip in v1.

**Scene contents by beat:**

| # | Node | Content | Dialogue |
|---|---|---|---|
| 1 | 522:59 | Cheese placed (static). Cat begins wandering. No mouse yet. | — (establishing beat, tap to continue) |
| 2 | 522:150 | Mouse appears (happy) | "Hi there! I'm super hungry… let's find something yummy to eat!" |
| 3 | 522:258 | Mouse reacts (shock-happy) | "Oh, look! Is that a cheese right there?!" |
| 4 | 659:266 | Mouse worried; cat emphasised | "But, wait! That cat over there doesn't look friendly…" |
| 5 | 659:284 | Mouse thinking | "What if we build something to help us? Like a crane!" |
| 6 | 667:76 | Blueprint scroll appears in a spotlight, gear-wheel halo | "Click this blueprint to help me build one!" |

Beat 6's blueprint scroll is the only tappable object; the rest of the screen does not advance. This is the transition into WS-3.

**Object placement rules — this is a spec, not a suggestion:**

- **Cheese: static.** Placed once at `sceneRoot` origin + offset, never moves during the cutscene. It is the spatial anchor the child's attention returns to.
- **Cat: always moving.** `CatWanderController` drives a continuous patrol on a circle of radius **0.18 m** centred on the cheese, at 0.04 m/s, with a randomised pause of 0.5–1.5 s every 2–4 s and a look-toward-cheese turn during the pause. The cat is never idle for more than 1.5 s — a frozen cat reads as a bug and destroys the threat premise.
- **Mouse: overlay, camera-facing.** The mouse is a foreground actor drawn near the lower-left; it is anchored to `sceneRoot` but billboarded so it always faces the camera.
- **Persistence:** all three are children of `sceneRoot`. Panning away and back restores them exactly. `CatWanderController` continues to integrate while off-camera so the cat has plausibly moved on return — a cat that resumes from the exact same spot signals a paused world.

**Dialogue rendering:** `SpeechBubbleView` with typewriter reveal at 40 chars/s, bottom-anchored to the speaking character, with a bold span capability (beat 5 bolds "crane!", beat 6 bolds "this blueprint"). Tapping during the reveal completes it instantly; tapping after it advances.

`CutsceneScript.swift` holds all six beats as static data. `CutsceneViewModel` holds only `currentBeatIndex` and the reveal state. Adding a beat must not require touching the ViewModel.

---

### 11.4 Blueprint — WS-3
**Figma:** `blueprint 1 / 2 / 3` (669:256, 671:286, 672:304)

A full-screen, non-AR interstitial. Wooden background, a navy blueprint sheet with a grid, a title in `.largeTitle` / `parchment`, a large step numeral, illustrative media on the left, and a numbered instruction list on the right.

| Step | Title | Instructions | Media |
|---|---|---|---|
| **1** | "Let's make the base first!" | Get a **LEGO plate**, make sure it's wide enough and **stable** · Make a **crane tower** using any **LEGO bricks** and your creativity! · Your **crane tower** should be at least **12 blocks high** | LEGO baseplate render |
| **2** | "Then, build the arm with gears!" | Get a **LEGO technic beam**! · Get an **axle** and insert it to the **red gear**, then through a hole of the LEGO technic brick · Get **another axle** and insert it to the **grey gear**, then through a hole **next to the first one** · Make sure the gears **interlocked** | Parts strip (1× beam, 1× large gear, 2× axle, 1×/2× bushings) + assembled arm |
| **3** | "Put it all up together!" | Attach the crane arm **on top of** the crane tower and you're all set up! | Completed crane render |

**Navigation:** `LargeCTAButton(.next)` bottom-right on all steps; `LargeCTAButton(.back)` top-left on steps 2 and 3. Step 3's next button routes to Level 1.

**Component notes:**
- `BlueprintMediaView` takes an enum `BlueprintMedia { case image(String), video(String) }`. v1 ships `.image` only; the video path is stubbed so swapping in build-along clips later is a data change, not a code change.
- `BlueprintInstructionList` renders `[AttributedString]` so bold spans come from the script file, not from view code.
- `BlueprintScript.swift` is the single source of the three steps.

**Content criticism that needs resolving before build:**
- Step 2 identifies gears by **colour** ("red gear", "grey gear"). LEGO Technic gear colours vary by kit and era, and the detector classifies by **tooth count**, colour-agnostically. Copy should read "the **big gear**" / "the **small gear**" or name the tooth counts with a picture. **OQ-5.**
- Step 2's parts strip shows quantities (1×, 1×, 2×, 1×, 2×) but the instruction text never references them. Either drop the quantity badges or add a parts checklist line. **OQ-6.**
- The blueprint does not currently constrain **which two gears** the child uses. Level 1's physics tuning depends on it — see risk R-05. **OQ-7, highest priority.**

---

### 11.5 Level 1 — WS-4
**Figma:** section `Level 1` (431:87)

Level 1's only teaching goal is LO-1 and LO-2: *driver vs. follower*, and *they turn opposite ways*. It is deliberately unfailable.

#### 11.5.1 Phase — `aligningCrane`
**Figma:** `lv. 1 (guide)` (690:51)

Camera feed, dark scrim, a hand-and-iPad illustration and a crane silhouette, with `"Put your crane on the center of the camera"` in `.largeTitle` / `textOnCamera` at the top.

`CraneAlignmentReticle` draws a target rectangle at the screen centre. The phase advances automatically when, for 1.0 continuous second:
- a horizontal plane is inside the reticle,
- the plane centre is 0.30–0.60 m from the camera,
- device angular velocity < 0.15 rad/s (the iPad is being held still).

The distance window exists for the detector, not for aesthetics: an 8 T gear is 8 mm across. At 0.6 m on the 1920×1440 capture it is roughly 30 px wide — near the floor of what the model can classify reliably. Beyond 0.6 m, classification accuracy collapses. Enforcing the window here is much cheaper than handling a bad detection later.

#### 11.5.2 Phase — `detectingGears`

See §12 for the full pipeline. UI is a scanning shimmer over the reticle and an `InstructionChip` reading `"Looking at your gears…"`. Timeout at 6 s → `DetectionConfirmBar` with a manual-selection fallback (§12.5).

#### 11.5.3 Phase — `confirmingDetection`
**Figma:** `lv. 1 (1)` (431:88)

The two virtual gear twins fade in over the physical gears with a `GearHighlightRing` each. Mouse appears on the crane. `SpeechBubbleView`: **"Wow! Great job on making this crane!"** `TapToContinueHint` at the bottom.

`DetectionConfirmBar` offers a discreet "not my gears?" affordance for the instructor, which returns to `detectingGears` with manual override enabled.

#### 11.5.4 Phase — `introDialogue`
**Figma:** `lv. 1 (2)` (436:113)

**"Now, choosing the driver and follower gear is very important."** Tap to continue.

#### 11.5.5 Phase — `teachingDriver`
**Figma:** `lv. 1 (3)` (436:155)

`SpotlightOverlay` dims everything except a hole over the small gear; the mouse is standing on it. Bubble: **"Look at the gear under my feet! This is the driver gear, it's the gear I turn to start pulling!"** A `CircularJoystickView` is visible but disabled, so the child sees the control they are about to be given.

#### 11.5.6 Phase — `teachingFollower`
**Figma:** `lv. 1 (5)` (441:227)

Spotlight moves to the other gear, which carries the rope down to the cheese. Bubble: **"Now look at the gear holding the rope! This is the follower gear, it turns with the driver gear to pull up the cheese!"**

#### 11.5.7 Phase — `selectingDriver`
**Figma:** `lv. 1 (7)` (441:251), `lv. 1 (8)` (457:62), `lv. 1 (9)` (441:264)

Header chip: **"Tap one of the gear to set it as a driver"**. Both gear twins pulse with a white outline ring. Tapping either one assigns it `GearRole.driver`; the other becomes `.follower` automatically.

**On assignment, the whole scene re-lays-out as a pure function of `GearRoleAssignment`:**

| Object | Position |
|---|---|
| Mouse | Standing on the **driver** gear |
| Rope | Anchored to the **follower** gear's axle, hanging down |
| Cheese | At the free end of the rope |
| `GearRoleLabel("Driver")` | Leader-line to the driver gear, `AppColor.roleDriver` |
| `GearRoleLabel("Follower")` | Leader-line to the follower gear, `AppColor.roleFollower` |
| Highlight rings | Driver ring `roleDriver`, follower ring `roleFollower` |

The child may re-tap the other gear at any point before cranking; everything above swaps with a 0.3 s animated transition. This swap is the primary interaction that teaches LO-1 — seeing the mouse and the rope physically trade places is what makes the roles concrete, so the transition must be animated and legible, never a snap.

**Implementation note:** `GearRoleAssignment` is a model struct `{ driver: DetectedGear, follower: DetectedGear }`. `GameplaySceneCoordinator` derives every transform from it. There must be no branch anywhere that reads "if the small gear is the driver then…" — the scene layout is data-driven or it will rot the moment Level 2 adds a third gear.

#### 11.5.8 Phase — `readyToCrank` / `cranking`
**Figma:** `lv. 1 (10)` (441:277), `lv. 1 (11)` (458:87)

**Controls:**
- `CircularJoystickView`, bottom-left. Circular drag. Clockwise engages; counter-clockwise shows a brief "wrong way" arrow hint and does not engage.
- `PullButton` ("PULL"), bottom-right. In Level 1 it is a redundant, always-available alternative to the joystick for children who cannot manage the circular gesture — hold to crank. **Both** map to the same `isCranking` boolean.

**Per-frame loop (60 Hz), driven by `GearTrainSimulator`:**

```
1. isCranking ← CrankInputViewModel
2. ω_driver   ← ActuatorModel.angularVelocity(ratio:tuning:load:)   [0 if !isCranking]
3. ω_follower ← −ω_driver / i
4. driverAngle   += ω_driver   · dt          (clockwise)
5. followerAngle += ω_follower · dt          (counter-clockwise)
6. v_rope   ← |ω_follower| · r_drum
7. height   ← min(height + v_rope·dt, liftHeight)
8. apply: gear twin orientations, rope length, cheese Y, mouse crank animation speed
9. if height == liftHeight → phase = .succeeded
```

**Visual consequences that must be visible and are non-negotiable:**
- The two gear twins visibly rotate in **opposite** directions (LO-2).
- The teeth **mesh** — tooth pitch alignment must be maintained, so the follower's phase is derived from the driver's angle, not integrated independently, to avoid drift.
- Releasing input stops the rope within 0.25 s and the cheese **holds** its height. No back-drive, no drop. A dropping cheese would introduce a failure the child was not warned about.
- Mouse cranking animation plays at a rate proportional to `ω_driver` so the mouse visibly strains at high ratios.

#### 11.5.9 Phase — `succeeded`
**Figma:** `Success Screen 1` (476:292)

Scrim over the frozen AR scene. `"CHEESE SECURED!"` in `.largeTitle`, `"Great job!"` in `.subtitle` / `accent`, three cheese-stars, celebrating mouse holding the cheese. Two `LargeCTAButton`s: `.retry` (bottom-left) and `.next` (bottom-right).

**Level 1 always awards three stars.** There is no scoring dimension yet — stars become meaningful in Level 2, where time and success both vary. Showing a variable star count in L1 would imply a performance judgement on a skill that has not been taught. Confirm with design. **OQ-8.**

---

## 12. Gear Detection Pipeline

### 12.1 Model
A pre-trained YOLOv11 model on LEGO Technic gears, exported to Core ML as `GearDetector.mlpackage`. Classes: `gear_8t`, `gear_24t`, `gear_40t`.

**Runtime:** `MLComputeUnits.all`. The model is loaded once, lazily, on entry to `aligningCrane` — not at launch, which would add ~400 ms to cold start for a screen the child will not reach for two minutes.

### 12.2 Input frame selection
Detection does **not** run every frame. It runs on demand:

- Trigger: entry to `detectingGears`.
- Source: `ARFrame.capturedImage` (1920×1440 YCbCr), **not** a downscaled render target — 8 T gears need every pixel.
- Rate: 5 Hz for up to 6 s, or until the stabiliser converges.
- Orientation: fixed by `CVPixelBuffer` + `CGImagePropertyOrientation` from the interface orientation. The app is landscape-locked, which removes an entire class of bug here.

Continuous per-frame inference is explicitly rejected: it costs ~30 % of the frame budget, competes with RealityKit for the Neural Engine and GPU, and the crane does not move once aligned. Detect once, lock, and stop.

### 12.3 Stabilisation
`DetectionStabiliser` accumulates observations across frames and emits a result only when:

- ≥ 12 observations collected,
- exactly **2** gear instances survive spatial clustering (IoU-based, 0.5 threshold),
- each cluster's modal class has ≥ 70 % of that cluster's votes,
- each cluster's mean confidence ≥ 0.60.

Anything else → keep sampling → timeout → manual fallback. Emitting a wrong pair is far worse than asking for help: a wrong pair means the child is taught the concept with the wrong numbers.

### 12.4 2D → 3D mapping
`DetectionToWorldMapper`:

1. Take the bounding-box centre in normalised image space.
2. Convert to view space via `ARFrame.displayTransform(for:viewportSize:)`.
3. Sample `ARFrame.sceneDepth.depthMap` at that point using a 5×5 median to reject depth noise at object edges. Reject the sample if `confidenceMap` is `.low`.
4. Unproject to camera space with the frame's intrinsics; transform to world space with `camera.transform`.
5. Derive the gear's **rotation axis** from the crane arm's plane normal, not from the detection — a bounding box carries no orientation. The arm's axles are horizontal and parallel to the beam, so the axis is taken from the `sceneRoot` frame's local X, refined by the mesh normal at the gear position.
6. Snap the pair so the centre-to-centre distance equals the theoretical mesh distance `(r_driver + r_follower)`, correcting the shorter of the two estimates. Two meshed gears have a known separation; using it removes most of the residual error and is the main lever for hitting AC-3.

### 12.5 Manual fallback (required, not optional)
On timeout, `DetectionConfirmBar` presents the three gear types as large tappable cards and asks the instructor to pick the two on the crane. The rest of Level 1 is identical from that point. Shipping without this means one bad lighting condition ends the lesson for the whole class.

### 12.6 Overlay & occlusion
Virtual twins are placed at the mapped transforms, then:

- Offset **+2 mm toward the camera** along the view vector. Coplanar placement z-fights with the LiDAR mesh and makes the twin flicker.
- Gear twin entities are **exempted from scene-mesh occlusion**; every other virtual object (mouse, cat, cheese, rope) is fully occluded by the mesh. Without the exemption the physical gear occludes its own twin and the illusion dies; without occlusion on everything else, the cat floats through the table.
- Twin material: `PhysicallyBasedMaterial` with environment texturing, tinted to `roleDriver` / `roleFollower` at 35 % blend so the role reads at a glance without hiding the gear's teeth.

---

## 13. Risks

| ID | Risk | Impact | Mitigation |
|---|---|---|---|
| **R-01** | 8 T gear too small to classify at working distance | Detection fails, Level 1 unplayable | Distance window enforced at alignment (§11.5.1); high-res capture; manual fallback (§12.5); pilot the distance window on device in week 1 |
| **R-02** | Gear axis cannot be derived from a 2D box | Twin renders at the wrong orientation, illusion breaks | Derive from crane-arm plane normal + mesh separation snap (§12.4). **Validate this on device before committing to the overlay approach — it is the single biggest technical unknown in the project** |
| **R-03** | Overlay flicker / z-fighting with physical gear | Looks broken | +2 mm camera-ward offset + occlusion exemption (§12.6) |
| **R-04** | Anchored objects drift over a long session | Cat walks off the table | Anchor to a single `sceneRoot` ARAnchor; re-localise on `.limited(.relocalizing)`; cap session length |
| **R-05** | **Lift-time spread between reciprocal ratios is `i²`** — 9× for 8/24, **25×** for 8/40. Fast combination finishes in under a second; slow combination takes 15–20 s | Level 1 feels either instant or interminable depending on the child's choice | **Mandate the 8 T + 24 T pair in the Blueprint for Level 1** (OQ-7). Apply `minLiftDuration` = 1.2 s as a presentation floor. Do **not** compress the ratio — the ratio *is* the lesson, and Level 2 depends on it being honest |
| **R-06** | Circular joystick gesture too hard for a 6-year-old | Child cannot start | `PullButton` as an equal-status alternative from the first frame, not a hidden accessibility option |
| **R-07** | Custom fonts (Mickies) missing a glyph or a weight | Silent fallback to system font | Verify glyph coverage for all script strings in week 1; add a debug assertion that fails loudly when `UIFont(name:)` returns nil |
| **R-08** | Frame-rate collapse from Vision + RealityKit contention | Below AC-5 | Detection is on-demand and terminates (§12.2); profile with Instruments before the tutorial phases are built |
| **R-09** | Two developers editing the RealityKit scene graph | Merge conflicts in the coordinator | `GameplaySceneCoordinator` is small and owned by one developer per sprint; entity factories are independently ownable |

---

## 14. Open Questions

| ID | Question | Blocks | Owner |
|---|---|---|---|
| **OQ-1** | Success-green and error-red are used in mockups but are not in the Design System frame. Add them as tokens? | WS-1 | Design |
| **OQ-2** | Speech bubbles are 24 pt vs. a 22 pt `body` token. Promote a `.dialogue` token, or normalise to 22? | WS-1 | Design |
| **OQ-3** | All Level 1 HUD text is SF Pro, not Nunito/Mickies. Confirm this is unintentional and update mockups | WS-1, WS-4 | Design |
| **OQ-4** | `"Great job!"` uses `#FAC73C`, a fourth yellow. Normalise to `#FFB800`? | WS-1 | Design |
| **OQ-5** | Blueprint step 2 names gears by colour ("red gear", "grey gear"); detector is colour-agnostic and kit colours vary. Rewrite as big/small? | WS-3 | Product |
| **OQ-6** | Blueprint step 2's parts-quantity badges are not referenced in the instruction text | WS-3 | Design |
| **OQ-7** | **Which exact gear pair does the Level 1 blueprint mandate?** Recommendation: **8 T + 24 T**. This is a physics-tuning blocker, not a content preference — see R-05 | WS-3, WS-4 | Product + Tech |
| **OQ-8** | Level 1 always awards three stars. Confirm, or define a scoring dimension | WS-4 | Product |
| **OQ-9** | Blueprint media: static images in v1 with video later, or video from the start? Affects `BlueprintMediaView` and asset budget | WS-3 | Product |
| **OQ-10** | Is there any audio design (SFX, VO, music) for v1? The Figma drafts mention "Snap!", "Click-clack!", "BOOM!" sounds on blueprint steps | WS-2, WS-3 | Design |
| **OQ-11** | Does the mouse dialogue need voice-over? Target age includes non-fluent readers, which makes VO close to a functional requirement rather than polish | All | Product |
| **OQ-12** | Session recovery: if the app backgrounds mid-Level-1, resume at the current phase or restart from alignment? | WS-4 | Tech |

---

## 15. Testing

### 15.1 Unit tests (required, blocking merge)

`Core/Gear/` is pure and deterministic and is therefore fully unit-testable with no simulator. This is the highest-value test surface in the project.

| Suite | Cases |
|---|---|
| `GearRatioCalculatorTests` | All 9 ordered pairs; ratio and sign of `ω_follower`; reciprocal identity `i(a,b) · i(b,a) == 1` |
| `ActuatorModelTests` | No-load speed; speed under load; stall boundary (`i·η·τ_stall == τ_load`); no negative angular velocity |
| `WinchModelTests` | Height integration monotonicity; clamp at `liftHeight`; zero input → zero velocity |
| `LiftFeasibilityEvaluatorTests` | Every pair succeeds at Level 1 tuning (guards LO-1's unfailability) |
| `DetectionStabiliserTests` | Convergence with clean input; rejection of 1 or 3 clusters; rejection below confidence floor; timeout |
| `GearRoleAssignmentTests` | Swap is involutive; entity placement derives purely from the assignment |

### 15.2 Device tests (manual, on iPad Pro, recorded per the PR convention)

| ID | Test |
|---|---|
| DT-1 | Plane found ≤ 8 s on white matte table, wood table, dark table (AC-1) |
| DT-2 | 20 detection attempts across 3 lighting conditions → ≥ 18 correct (AC-2) |
| DT-3 | Twin registration measured against a ruler at 40 cm (AC-3) |
| DT-4 | Pan to ceiling for 10 s, return → all objects in place (AC-4) |
| DT-5 | Instruments frame-rate capture through a full crank + lift (AC-5) |
| DT-6 | Role swap: tap gear A, then gear B, confirm mouse/rope/cheese/labels all move |
| DT-7 | Manual fallback reachable and completes a full Level 1 |
| DT-8 | Both 11″ and 12.9″ iPad Pro — layout scale correctness |

### 15.3 Pilot
Ten children, ages 6–10, with one instructor, using their own builds. Measure completion without adult help (AC-6) and record where they hesitate. Run this after Level 1 is functional and **before** Level 2 is designed — Level 2's difficulty curve should be set by what this pilot shows, not by assumption.

---

## 16. Delivery Order

| Sprint | Deliverable | Rationale |
|---|---|---|
| **S1** | WS-1 Design System complete + SwiftLint gate + `Core/Gear` with full unit tests | Both are pure, parallelisable, unblock everything, and need no device |
| **S2** | **R-02 spike:** prove gear-axis derivation and overlay registration on device | This is the project's biggest unknown. If it fails, the interaction design changes, and it is far cheaper to learn that in week 2 than week 8 |
| **S3** | WS-2 Splash + Surface Scan + Cutscene | Establishes `sceneRoot`, anchoring and the entity factories that Level 1 reuses |
| **S4** | WS-3 Blueprint | Self-contained, non-AR, low risk; good parallel work while S2/S3 AR work is in flight |
| **S5** | WS-4 Level 1: alignment → detection → overlay → confirm | The detection pipeline, hardened by the S2 spike |
| **S6** | WS-4 Level 1: roles, crank, lift, success | Depends on S1 physics and S5 detection |
| **S7** | Device tests, pilot, hardening | — |

Suggested ownership given two developers: one takes the AR/Vision spine (S2, S3 scene, S5), the other takes design system, blueprint, physics and HUD (S1, S4, S6 UI). They converge in S6.

---

## 17. Glossary

| Term | Meaning |
|---|---|
| **Driver** | The gear that is turned by the actuator (the mouse). Rotates clockwise |
| **Follower** | The gear turned by the driver. Rotates counter-clockwise. Carries the rope drum |
| **Ratio `i`** | `N_follower / N_driver` |
| **Gear twin** | The virtual gear rendered over a detected physical gear |
| **`sceneRoot`** | The single world anchor every virtual object descends from |
| **Beat** | One tap-advanced unit of cutscene dialogue |
| **Presentation floor** | `minLiftDuration` — the minimum on-screen lift time, applied for legibility only |
