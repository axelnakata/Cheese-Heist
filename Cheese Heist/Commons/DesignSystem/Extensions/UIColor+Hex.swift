//
//  UIColor+Hex.swift
//  Cheese Heist
//
//  PRD §7.7 — RealityKit materials take UIColor, so the hex parse lives here and
//  Color+Hex delegates to it. One parser, two surfaces.
//

import UIKit

extension UIColor {

    /// Creates a colour from a 6- or 8-digit hex string ("#FFB800", "FFB800", "#013A7199").
    ///
    /// Invalid input resolves to `.clear` so a typo shows up as a missing colour in the
    /// preview rather than silently rendering black.
    convenience init(hex: String) {
        let cleaned = hex
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "#", with: "")

        var raw: UInt64 = 0
        let isHex = cleaned.allSatisfy(\.isHexDigit)
        guard isHex, Scanner(string: cleaned).scanHexInt64(&raw) else {
            self.init(white: 0, alpha: 0)
            return
        }

        switch cleaned.count {
        case 6:
            self.init(
                red: CGFloat((raw & 0xFF0000) >> 16) / 255,
                green: CGFloat((raw & 0x00FF00) >> 8) / 255,
                blue: CGFloat(raw & 0x0000FF) / 255,
                alpha: 1
            )
        case 8:
            self.init(
                red: CGFloat((raw & 0xFF00_0000) >> 24) / 255,
                green: CGFloat((raw & 0x00FF_0000) >> 16) / 255,
                blue: CGFloat((raw & 0x0000_FF00) >> 8) / 255,
                alpha: CGFloat(raw & 0x0000_00FF) / 255
            )
        default:
            self.init(white: 0, alpha: 0)
        }
    }
}
