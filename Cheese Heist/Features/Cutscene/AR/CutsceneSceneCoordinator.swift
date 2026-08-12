//
//  CutsceneSceneCoordinator.swift
//  Cheese Heist
//
//  Owns the cutscene's one ARAnchor, the guidance ring, the cheese and the cat.
//  Nothing else adds or removes entities — the same contract `GameplaySceneCoordinator`
//  holds for Level 1.
//
//  ═══ EVERYTHING HANGS OFF ONE ANCHOR, PLACED AT THE TAP. ═══
//
//  The cheese sits at the anchor's origin and the cat orbits it. Because both are
//  children of an `ARAnchor` rather than of the camera, the child can point the iPad at
//  the ceiling, walk to the other side of the room and come back, and find the scene
//  exactly where they left it. That is the whole of AC-4, and it is bought entirely by
//  not parenting anything to the camera.
//
//  Teardown removes the anchor from BOTH the ARKit session and the RealityKit scene, and
//  unregisters the ticker handler — without that last part the cat keeps being driven
//  through the whole of Level 1.
//

import ARKit
import RealityKit
import simd
import os

@MainActor
final class CutsceneSceneCoordinator: CutsceneSceneProviding {

    let planeDetection: PlaneDetectionService

    /// Fired when the published validity changes, so the ViewModel can refresh an input
    /// gate that would otherwise still be answering the question it was asked on attach.
    var onValidityChanged: ((SurfaceValidity) -> Void)?

    private weak var arView: ARView?
    private let ticker: SceneUpdateTicker
    private var tickerHandlerID: UUID?

    private var sceneARAnchor: ARAnchor?
    private var sceneAnchorEntity: AnchorEntity?
    private var ringAnchorEntity: AnchorEntity?

    private var ring: Entity?
    private var catDriver: CatOrbitDriver?
    private var isScenePlaced = false
    private var lastPublishedValidity: SurfaceValidity = .noSurface

    // MARK: - CutsceneSceneProviding

    var isSurfaceValid: Bool { planeDetection.validity == .valid }
    var validity: SurfaceValidity { planeDetection.validity }

    // MARK: - Init

    init(arView: ARView, ticker: SceneUpdateTicker) {
        self.arView = arView
        self.ticker = ticker
        self.planeDetection = PlaneDetectionService()
        buildRing(in: arView)
        tickerHandlerID = ticker.register { [weak self] dt in self?.tick(dt) }
    }

    // MARK: - Ring

    private func buildRing(in arView: ARView) {
        let entity = SurfaceRingEntity.make()
        entity.isEnabled = false
        let anchor = AnchorEntity(world: .zero)
        anchor.addChild(entity)
        arView.scene.addAnchor(anchor)
        ring = entity
        ringAnchorEntity = anchor
    }

    func setRingVisible(_ visible: Bool) {
        ring?.isEnabled = visible && !isScenePlaced
    }

    // MARK: - Placement

    func placeScene() {
        guard !isScenePlaced, let arView, let hit = planeDetection.hitTransform else {
            Logger.cutscene.error("placeScene with no valid surface — ignored")
            return
        }
        isScenePlaced = true
        setRingVisible(false)

        let anchor = ARAnchor(name: "cutsceneScene", transform: facingTransform(at: hit, in: arView))
        arView.session.add(anchor: anchor)
        sceneARAnchor = anchor

        let entity = AnchorEntity(anchor: anchor)
        arView.scene.addAnchor(entity)
        sceneAnchorEntity = entity

        let root = Entity()
        entity.addChild(root)
        buildCheese(root: root)
        buildCat(root: root)
        Logger.cutscene.info("cutscene scene placed")
    }

    /// The hit's position, with a yaw that faces the child rather than the raycast's own.
    ///
    /// The cheese is placed once and never turns again (it is the fixed point the child
    /// navigates back to), so the one moment its facing is decided has to be the moment
    /// they are looking at it.
    private func facingTransform(at hit: simd_float4x4, in arView: ARView) -> simd_float4x4 {
        let position = simd_float3(hit.columns.3.x, hit.columns.3.y, hit.columns.3.z)
        let camera = arView.cameraTransform.translation
        let toCamera = simd_float3(camera.x - position.x, 0, camera.z - position.z)
        let yaw = simd_length(toCamera) > 0.001 ? atan2(toCamera.x, toCamera.z) : 0

        var transform = matrix_identity_float4x4
        transform = simd_float4x4(simd_quatf(angle: yaw, axis: simd_float3(0, 1, 0)))
        transform.columns.3 = simd_float4(position, 1)
        return transform
    }

    private func buildCheese(root: Entity) {
        guard let wedge = CheeseEntity.make() else { return }
        let factor = CutsceneTuning.cheeseSize / CheeseEntity.longestEdge
        wedge.holder.scale *= factor
        // Measured on the unscaled hierarchy, so the factor comes back out here.
        wedge.holder.position.y = CheeseEntity.restingLift(of: wedge.holder) * factor
        root.addChild(wedge.holder)
    }

    private func buildCat(root: Entity) {
        guard let cat = CatEntity.make() else { return }
        root.addChild(cat.holder)
        catDriver = CatOrbitDriver(cat: cat)
    }

    // MARK: - Per-frame

    private func tick(_ deltaTime: Float) {
        guard let arView else { return }

        if isScenePlaced {
            catDriver?.advance(deltaTime: deltaTime)
            return
        }

        planeDetection.update(arView: arView, deltaTime: deltaTime)

        if let hit = planeDetection.hitTransform {
            ring.map { SurfaceRingEntity.follow($0, hit: hit) }
        }
        ring?.isEnabled = planeDetection.validity == .valid

        if planeDetection.validity != lastPublishedValidity {
            lastPublishedValidity = planeDetection.validity
            onValidityChanged?(planeDetection.validity)
        }
    }

    // MARK: - Teardown

    func teardown() {
        tickerHandlerID.map { ticker.unregister($0) }
        tickerHandlerID = nil

        sceneARAnchor.map { arView?.session.remove(anchor: $0) }
        sceneAnchorEntity.map { arView?.scene.removeAnchor($0) }
        ringAnchorEntity.map { arView?.scene.removeAnchor($0) }

        sceneARAnchor = nil
        sceneAnchorEntity = nil
        ringAnchorEntity = nil
        ring = nil
        catDriver = nil
        isScenePlaced = false
        Logger.cutscene.info("cutscene scene torn down")
    }
}
