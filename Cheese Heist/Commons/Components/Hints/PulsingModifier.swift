//
//  PulsingModifier.swift
//  Cheese Heist
//
//  PRD §8.4 rule 2 — a bespoke ViewModifier belongs in Commons/Components, not inline in
//  a view. Used by TapToContinueHint and by the splash logo's breathing loop.
//

import SwiftUI

private struct PulsingModifier: ViewModifier {

    let period: Double
    let opacityRange: ClosedRange<Double>
    let scaleRange: ClosedRange<Double>

    @State private var isPulsed = false

    func body(content: Content) -> some View {
        content
            .opacity(isPulsed ? opacityRange.upperBound : opacityRange.lowerBound)
            .scaleEffect(isPulsed ? scaleRange.upperBound : scaleRange.lowerBound)
            .animation(
                .easeInOut(duration: period / 2).repeatForever(autoreverses: true),
                value: isPulsed
            )
            .onAppear { isPulsed = true }
    }
}

extension View {

    /// A continuous breathing loop.
    ///
    /// - Parameters:
    ///   - period: One full cycle, in seconds. `1` is the tap-hint rate (PRD §7.6).
    ///   - opacityRange: Faded → full.
    ///   - scaleRange: Rest → peak. `1...1.03` is the splash logo (PRD §11.1).
    func pulsing(
        period: Double = 1,
        opacityRange: ClosedRange<Double> = 0.45...1,
        scaleRange: ClosedRange<Double> = 1...1
    ) -> some View {
        modifier(
            PulsingModifier(period: period, opacityRange: opacityRange, scaleRange: scaleRange)
        )
    }
}
