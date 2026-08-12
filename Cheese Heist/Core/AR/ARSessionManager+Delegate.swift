// ARSessionManager+Delegate.swift — Cheese Heist
// ARSessionDelegate conformance, separated per 200-line budget.

import ARKit

extension ARSessionManager: ARSessionDelegate {

    /// The only writer of `currentFrame`.
    ///
    /// Kept deliberately thin: this fires 60 times a second, and anything done here is
    /// done on the frame the renderer is waiting for. Detection pulls the frame it
    /// wants at its own 6 Hz rate instead.
    nonisolated func session(_ session: ARSession, didUpdate frame: ARFrame) {
        let captured = frame
        MainActor.assumeIsolated {
            self.setCurrentFrame(captured)
        }
    }
}
