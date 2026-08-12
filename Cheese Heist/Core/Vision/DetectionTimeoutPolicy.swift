// DetectionTimeoutPolicy.swift — Cheese Heist
// 12s timeout logic for gear detection.

import Foundation

struct DetectionTimeoutPolicy: Sendable {
    let duration: TimeInterval

    static let standard = DetectionTimeoutPolicy(duration: 12.0)

    func hasTimedOut(elapsed: TimeInterval) -> Bool {
        elapsed >= duration
    }
}
