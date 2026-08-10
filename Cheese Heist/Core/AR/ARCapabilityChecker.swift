// ARCapabilityChecker.swift — Cheese Heist
// PRD §5.1 — LiDAR gate. iPad Pro mandatory, no non-LiDAR fallback.

import ARKit

enum ARCapabilityChecker {

    /// True when LiDAR scene depth and mesh reconstruction are available.
    static var isLiDARAvailable: Bool {
        ARWorldTrackingConfiguration.supportsFrameSemantics(.sceneDepth)
            && ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh)
    }
}
