//
//  Color+Hex.swift
//  Cheese Heist
//
//  PRD §7.7 / §7.8 — SwiftUI-facing hex initialiser.
//

import SwiftUI

extension Color {

    /// Creates a colour from a 6- or 8-digit hex string ("#FFB800", "FFB800", "#013A7199").
    ///
    /// Invalid input resolves to `.clear` so a typo is visible in preview rather than
    /// silently black. Parsing lives in `UIColor+Hex` because RealityKit needs it too.
    init(hex: String) {
        self.init(uiColor: UIColor(hex: hex))
    }
}
