// Angle+Shortest.swift — Cheese Heist
// Signed shortest-angle delta in (-π, π].

import Foundation

enum AngleHelper {
    /// Signed shortest angle from `from` to `to`, in radians.
    static func shortestDelta(from: Float, to: Float) -> Float {
        var delta = to - from
        while delta > .pi { delta -= 2 * .pi }
        while delta < -.pi { delta += 2 * .pi }
        return delta
    }
}
