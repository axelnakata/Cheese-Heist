//
//  Palette.swift
//  Cheese Heist
//
//  PRD §7.1 — raw colour tokens, read from the Figma `Design System` frame (603:13).
//  Nothing outside `AppColor` may reference this type: views bind to semantic tokens
//  so a brand change touches one file.
//

import SwiftUI

enum Palette {
    static let cheeseYellow = Color(hex: "#FFB800")
    static let blueprintNavy = Color(hex: "#013A71")
    static let skyBlue = Color(hex: "#3E7DCA")
    static let crustAmber = Color(hex: "#CE7A00")
    static let ink = Color(hex: "#000000")
    static let parchment = Color(hex: "#F9F2E4")
    static let pureWhite = Color(hex: "#FFFFFF")
    static let hologramCyan = Color(hex: "#00E5FF")
    static let navyGradientTop = Color(hex: "#0E3155")
    static let navyGradientBottom = Color(hex: "#1D364F")

    /// Not present in the Figma Design System frame — taken from the cutscene-guideline
    /// raster mockups. Pending design sign-off, tracked as OQ-1 (PRD §14).
    static let successGreen = Color(hex: "#4CAF50")
    static let warningRed = Color(hex: "#E53935")
}
