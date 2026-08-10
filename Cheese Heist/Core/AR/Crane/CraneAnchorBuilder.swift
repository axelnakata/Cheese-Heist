// CraneAnchorBuilder.swift — Cheese Heist
// Port from gear-poc: creates the single ARAnchor + AnchorEntity.

import ARKit
import RealityKit

struct CraneAnchorResult {
    let arAnchor: ARAnchor
    let anchorEntity: AnchorEntity
    let contentRoot: Entity
}

enum CraneAnchorBuilder {

    /// Creates the single anchor everything hangs off.
    /// Returns the ARAnchor (for cleanup), the AnchorEntity, and the contentRoot.
    static func build(frame: CraneFrame, in arView: ARView) -> CraneAnchorResult {
        let arAnchor = ARAnchor(name: "craneFrame", transform: frame.transform)
        arView.session.add(anchor: arAnchor)

        let anchorEntity = AnchorEntity(anchor: arAnchor)
        arView.scene.addAnchor(anchorEntity)

        let root = Entity()
        anchorEntity.addChild(root)

        return CraneAnchorResult(
            arAnchor: arAnchor,
            anchorEntity: anchorEntity,
            contentRoot: root
        )
    }
}
