// DetectionTimeoutPolicy.swift — Cheese Heist
// 12s timeout logic for gear detection.

import Foundation

struct DetectionTimeoutPolicy: Sendable {
    let duration: TimeInterval

    static let standard = DetectionTimeoutPolicy(duration: 12.0)

    /// Never times out. Level 1 has no manual-fallback screen to hand off to — the
    /// live setup/crane-lost overlays are the whole of its feedback, so the search
    /// just keeps going instead of giving up and stopping the poller.
    static let disabled = DetectionTimeoutPolicy(duration: .infinity)

    func hasTimedOut(elapsed: TimeInterval) -> Bool {
        elapsed >= duration
    }
}
