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
    private let billboards = BillboardSystem()
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
        buildStage(root: root)
        buildLighting(root: root)
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

    /// Both props, out of one file, at one scale.
    ///
    /// The cheese is not built through `CheeseEntity` here. Level 1's cheese is a
    /// billboarded sprite-like prop whose `presentation` rotation is designed for that
    /// pairing, and the cutscene — which does not billboard — had to fight it with a
    /// hand-picked quarter-turn to stop the wedge standing on its side. `meong.usdz`
    /// already contains a cheese posed next to the cat by hand in Reality Composer Pro,
    /// so taking it from there is both fewer moving parts and the pose the designer
    /// actually approved.
    private func buildStage(root: Entity) {
        guard let stage = CutsceneStageEntity.make() else { return }
        root.addChild(stage.cheese)
        root.addChild(stage.catHolder)
        catDriver = CatOrbitDriver(cat: stage)
    }

    /// Key and fill lights so the cat and cheese are not rendered in whatever gloom the
    /// room happens to be in — the same rig Level 1 uses (see `SceneLightingRig`).
    ///
    /// ═══ AND IT HAS TO BE BILLBOARDED, WHICH IS WHAT WAS MISSING. ═══
    ///
    /// The rig is two `DirectionalLight`s aimed off its own local axes, so parenting it
    /// to a fixed anchor and walking round the scene puts the child behind both of them —
    /// the cheese and the cat go dull, which is exactly the "unlit assets" this rig exists
    /// to prevent. Level 1 registers it with `BillboardSystem` for that reason
    /// (`GameplaySceneCoordinator.buildLighting`); the cutscene did not, and the cutscene
    /// is the screen where the child is *expected* to walk around the props.
    private func buildLighting(root: Entity) {
        let rig = SceneLightingRig.make()
        root.addChild(rig)
        billboards.register(rig)
        arView?.environment.lighting.intensityExponent = SceneLightingRig.environmentBoost
    }

    // MARK: - Per-frame

    private func tick(_ deltaTime: Float) {
        guard let arView else { return }

        if isScenePlaced {
            catDriver?.advance(deltaTime: deltaTime)
            // Last, for the same reason Level 1 runs billboards last: it re-aims the
            // lighting rig against the frame everything else was just written into.
            billboards.update(cameraTransform: arView.cameraTransform.matrix)
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
        billboards.removeAll()
        catDriver = nil
        isScenePlaced = false
        Logger.cutscene.info("cutscene scene torn down")
    }
}
