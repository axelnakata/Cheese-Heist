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
    /// Stroke around the instruction chip, at `AppStroke.chip`.
    static let strokeChip = Palette.parchment

    // MARK: - Text

    /// Body on parchment or on yellow.
    static let textPrimary = Palette.ink
    /// Text on navy.
    static let textInverted = Palette.parchment
    /// HUD text over the AR feed.
    static let textOnCamera = Palette.pureWhite

    // MARK: - Gear roles

    /// Driver gear ring + label.
    static let roleDriver = Palette.crustAmber
    /// Follower gear ring + label.
    static let roleFollower = Palette.skyBlue

    // MARK: - State

    /// Surface-scan ring, valid alignment.
    static let stateValid = Palette.successGreen
    /// Rejected surface.
    static let stateInvalid = Palette.warningRed
}
