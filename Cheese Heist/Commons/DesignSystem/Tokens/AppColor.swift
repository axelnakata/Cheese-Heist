//
//  AppColor.swift
//  Cheese Heist
//
//  PRD §7.2 — semantic colour tokens. Views reference these names only, never `Palette`
//  and never a literal.
//

import SwiftUI

enum AppColor {

    // MARK: - Action

    /// Primary button, CTA, speech-bubble fill.
    static let accent = Palette.cheeseYellow
    /// Button borders, stroked at `AppStroke.button`.
    static let accentStroke = Palette.pureWhite
    /// Pressed state for accented controls.
    static let accentPressed = Palette.crustAmber
    /// Label on an accent-filled control. §7.2 maps text-on-yellow to `textPrimary`, but
    /// the button spec in §7.6 is explicitly white; this token holds that distinction
    /// instead of letting a view reach into `Palette`.
    static let textOnAccent = Palette.pureWhite

    // MARK: - Surfaces

    /// Non-AR screen background.
    static let surfaceBackground = Palette.parchment
    /// Instruction chip over the camera feed.
    static let surfaceInstruction = Palette.blueprintNavy.opacity(0.6)
    /// Blueprint sheet.
    static let surfaceBlueprint = Palette.blueprintNavy
    /// Dim behind a spotlight or a success overlay.
    static let surfaceScrim = Palette.ink.opacity(0.55)
    /// Under the speech bubble. It floats over a live camera feed of a real room, and
    /// without a shadow it reads as a hole cut in the picture rather than a card on it.
    static let bubbleShadow = Palette.ink.opacity(0.28)
    /// Stroke around the instruction chip, at `AppStroke.chip`.
    static let strokeChip = Palette.parchment
    /// Instruction chip navy gradient, top stop.
    static let chipGradientTop = Palette.navyGradientTop
    /// Instruction chip navy gradient, bottom stop.
    static let chipGradientBottom = Palette.navyGradientBottom

    // MARK: - Text

    /// Body on parchment or on yellow.
    static let textPrimary = Palette.ink
    /// Text on navy.
    static let textInverted = Palette.parchment
    /// HUD text over the AR feed.
    static let textOnCamera = Palette.pureWhite

    // MARK: - Gear roles (PRD-Level1 D-1: driver = blue, follower = amber)

    /// Driver gear ring + label.
    static let roleDriver = Palette.skyBlue
    /// Follower gear ring + label.
    static let roleFollower = Palette.crustAmber

    // MARK: - AR overlays

    /// Behind an on-camera control, so it is legible over ANY camera feed.
    ///
    /// The crank is white on white the moment the child points the iPad at a pale desk,
    /// and no choice of stroke colour fixes that — the background is a photograph of an
    /// arbitrary room. A dark plate underneath makes the surroundings the app's to
    /// choose, and the white on top then contrasts by construction.
    static let controlBackdrop = Palette.ink.opacity(0.42)

    /// Under the crank's knob, for the same reason at a smaller scale.
    static let controlShadow = Palette.ink.opacity(0.5)

    /// Holographic gear twin material.
    static let hologram = Palette.hologramCyan

    // MARK: - State

    /// Surface-scan ring, valid alignment.
    static let stateValid = Palette.successGreen
    /// Rejected surface.
    static let stateInvalid = Palette.warningRed
    /// Mid-way state — neither valid nor rejected outright (e.g. the countdown timer's
    /// 2★ zone, a bar's middle segment). Same hex as `accent`, its own semantic name
    /// because the two mean different things, same as `crustAmber` backing both
    /// `accentPressed` and `roleFollower`.
    static let stateCaution = Palette.cheeseYellow

    /// The surface-scan ring's bright face, as it lies on the detected plane.
    static let surfaceRing = Palette.ringGreen
    /// The ring's darker outer edge, which is what gives it thickness.
    static let surfaceRingEdge = Palette.ringGreenDeep

    /// The invalid-surface ✗'s bright face, as it lies on the detected plane.
    static let surfaceInvalidMark = Palette.invalidMarkRed
    /// The ✗'s darker bevelled underside — same trick as `surfaceRingEdge`.
    static let surfaceInvalidMarkEdge = Palette.invalidMarkRedDeep

    // MARK: - Result micro-interactions

    /// The success burst's sparks — cheese-gold, the same colour the child just won.
    static let celebrationSpark = Palette.cheeseYellow
}
