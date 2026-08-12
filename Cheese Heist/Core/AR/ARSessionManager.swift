//
//  ARSessionManager.swift
//  Cheese Heist
//
//  Owns the one `ARSession` and the one `ARView`.
//
//  ═══ `session.run` IS CALLED EXACTLY ONCE PER PROCESS. ═══
//
//  Never paused, never re-run — through alignment, detection, the guided run, the free
//  run, the success screen and retry. Every world anchor in the app is expressed in the
//  coordinate frame that first `run` established; a second one re-origins the world and
//  silently detaches the crane from the scene sitting on it. That failure looks like
//  drift rather than like a crash, which is why the `#if DEBUG` trap below exists and
//  why device test 6 puts a breakpoint on it (risk R-L5).
//

import ARKit
import Observation
import RealityKit
import os

@MainActor
@Observable
final class ARSessionManager: NSObject {

    /// Created once and shared across every screen.
    private(set) var arView: ARView?

    /// Latest frame from the session delegate.
    @ObservationIgnored private(set) var currentFrame: ARFrame?

    private(set) var isRunning = false

    var session: ARSession? { arView?.session }

    /// How many times `run` has been called. Only ever 0 or 1.
    @ObservationIgnored private var runCount = 0

    // MARK: - Setup

    /// Creates and memoizes the ARView.
    func setupARView() -> ARView {
        if let existing = arView { return existing }

        let view = ARView(frame: .zero)
        view.automaticallyConfigureSession = false
        view.session.delegate = self
        arView = view
        return view
    }

    func startSession() {
        guard let arView else { return }
        guard !isRunning else { return }

        runCount += 1
        #if DEBUG
        assert(runCount == 1, """
            session.run called \(runCount) times. It must run exactly once per process \
            (PRD-Level1 §6.1) — a second run re-origins the world and detaches every \
            anchor from the scene it is carrying.
            """)
        #endif

        let configuration = ARWorldTrackingConfiguration()

        // LiDAR depth — required for the 2D→3D unprojection the whole overlay rests on.
        if ARWorldTrackingConfiguration.supportsFrameSemantics(.sceneDepth) {
            configuration.frameSemantics.insert(.sceneDepth)
        }
        if ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh) {
            configuration.sceneReconstruction = .mesh
        }
        // Horizontal planes are how `SupportSurfaceEstimator` finds the table.
        configuration.planeDetection = [.horizontal]

        arView.session.run(configuration, options: [])
        isRunning = true
        Logger.arSession.info("session started — it will not be paused or restarted")
    }

    /// Projects a world position into on-screen view coordinates.
    func project(_ worldPosition: simd_float3) -> CGPoint? {
        arView?.project(worldPosition)
    }

    func setCurrentFrame(_ frame: ARFrame) {
        currentFrame = frame
    }

    // MARK: - Frame capture

    /// Snapshots the measurement data from a SPECIFIC frame. The session keeps running;
    /// nothing here freezes or copies the camera image.
    ///
    /// Automatic detection needs a specific frame rather than `currentFrame`: the boxes
    /// come from whichever frame the model ran on, so the depth map and camera transform
    /// must come from that same frame. Pulling `currentFrame` again would pair boxes
    /// from frame F with depth from a later frame.
    ///
    /// Returns nil if depth is missing — this is a LiDAR-only flow.
    func captureData(from frame: ARFrame) -> CapturedFrameData? {
        guard let depth = frame.sceneDepth else { return nil }

        // Straight off the capture buffer: no decode, no colour conversion. This runs
        // several times a second, so it has to stay close to free.
        return CapturedFrameData(
            cameraTransform: frame.camera.transform,
            cameraIntrinsics: frame.camera.intrinsics,
            depthMap: depth.depthMap,
            confidenceMap: depth.confidenceMap,
            imagePixelSize: CGSize(
                width: CVPixelBufferGetWidth(frame.capturedImage),
                height: CVPixelBufferGetHeight(frame.capturedImage)
            )
        )
    }
}
