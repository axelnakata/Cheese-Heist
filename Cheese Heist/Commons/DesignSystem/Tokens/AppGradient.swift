// AppGradient.swift — Cheese Heist
// PRD §7 — reusable gradient definitions.

import SwiftUI

enum AppGradient {
    /// Instruction chip navy backdrop — vertical, top-dark to bottom-lighter.
    static let navyChip = LinearGradient(
        colors: [AppColor.chipGradientTop, AppColor.chipGradientBottom],
        startPoint: .top,
        endPoint: .bottom
    )
}
