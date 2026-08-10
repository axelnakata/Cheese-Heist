//
//  EnvironmentValues+Layout.swift
//  Cheese Heist
//
//  PRD §7.4 — the single environment value carrying the design-to-device scale.
//

import SwiftUI

extension EnvironmentValues {

    /// Multiplier from Figma design-scale points to device points.
    ///
    /// Defaults to `1`, so a `#Preview` sized at the 12.9" design width renders at
    /// design scale without any setup. Injected for real by `.providesLayoutScale()`.
    @Entry var layoutScale: CGFloat = LayoutScale.identity
}
