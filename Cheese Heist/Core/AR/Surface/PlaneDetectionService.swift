//
//  PlaneDetectionService.swift
//  Cheese Heist
//
//  PRD-Cutscene §7.3 — publishes whether the middle of the screen is pointing at enough
//  flat surface to stage the cutscene on. `PlaneGeometryProbe` does the ARKit work; this
//  type is state and hysteresis, and nothing else.
//
//  ═══ IT DEBOUNCES, AND IT SAMPLES SLOWER THAN IT TICKS. ═══
//
//  Raycasting every frame at 60 Hz is both wasteful and jittery: a single bad sample at
//  the edge of a plane would flip the ring red for one frame. So the probe runs at
//  `sampleInterval` and a change of verdict has to survive `stabilitySamples` agreeing
//  reads before it is published. The ring is a promise, and a promise that flickers is
//  worse than no promise.
//

import ARKit
import RealityKit
import Observation
import simd
import os

@MainActor
@Observable
final class PlaneDetectionService {

    private(set) var validity: SurfaceValidity = .noSurface

    /// The world transform to anchor the scene at. Non-nil only while `validity` is
    /// `.valid`, so a caller cannot place the scene on a surface we just rejected.
    private(set) var hitTransform: simd_float4x4?

    /// The same raycast, published on every sample regardless of validity — including
    /// `.tooSmall`/`.tooClose`/`.tooFar`. `hitTransform` above stays gated to `.valid`
    /// because callers use it to decide whether it is safe to place the scene; but that
    /// gate also meant the on-screen ring/mark stopped moving the instant a surface
    /// turned invalid, freezing at its last valid spot — or at the world origin if there
    /// had never been one — instead of following wherever the camera is now pointing.
    /// This is what the invalid mark should `follow()`.
    private(set) var latestHitTransform: simd_float4x4?

    @ObservationIgnored private var pending: SurfaceValidity = .noSurface
    @ObservationIgnored private var pendingCount = 0
    @ObservationIgnored private var latestHit: simd_float4x4?
    @ObservationIgnored private var sinceLastSample: Float = 0

    @ObservationIgnored private let stabilitySamples: Int
    @ObservationIgnored private let sampleInterval: Float

    init(
        stabilitySamples: Int = CutsceneTuning.surfaceStabilitySamples,
        sampleInterval: Float = CutsceneTuning.surfaceSampleInterval
    ) {
        self.stabilitySamples = stabilitySamples
        self.sampleInterval = sampleInterval
    }

    /// Called from the scene ticker every frame; only probes every `sampleInterval`.
    func update(arView: ARView, deltaTime: Float) {
        sinceLastSample += deltaTime
        guard sinceLastSample >= sampleInterval else { return }
        sinceLastSample = 0

        guard let probe = PlaneGeometryProbe.probe(arView: arView) else {
            ingest(.noSurface, hit: nil)
            return
        }

        // A hit with no plane anchor behind it is an estimated plane: real geometry, but
        // nothing we can measure an extent against yet. That is "not yet", not "too
        // small" — reporting it as `.tooSmall` sent the child hunting for another table.
        guard let clearance = probe.clearance else {
            ingest(.noSurface, hit: nil)
            return
        }

        let raw = SurfaceValidationRules.evaluate(
            clearance: clearance, distance: probe.distance
        )
        logSample(raw, clearance: clearance, distance: probe.distance)
        ingest(raw, hit: probe.worldTransform)
    }

    func reset() {
        validity = .noSurface
        hitTransform = nil
        latestHitTransform = nil
        pending = .noSurface
        pendingCount = 0
        latestHit = nil
        sinceLastSample = 0
    }

    // MARK: - Hysteresis

    private func ingest(_ raw: SurfaceValidity, hit: simd_float4x4?) {
        if raw == pending {
            pendingCount += 1
        } else {
            pending = raw
            pendingCount = 1
        }
        latestHit = hit
        latestHitTransform = hit

        if pendingCount >= stabilitySamples, validity != pending {
            validity = pending
            let settled = pending
            Logger.cutscene.info("surface → \(String(describing: settled), privacy: .public)")
        }

        hitTransform = validity == .valid ? latestHit : nil
    }

    // MARK: - Diagnostics

    /// Every rejected sample, logged with the numbers behind it.
    ///
    /// None of this is visible on the simulator — the whole vision path needs a device —
    /// so when the ring refuses to turn green the only way to tell "no plane" from
    /// "plane, but you are standing too far back" is to have written the figures down.
    private func logSample(_ raw: SurfaceValidity, clearance: Float, distance: Float) {
        guard raw != .valid else { return }
        Logger.cutscene.debug("""
            surface rejected: \(String(describing: raw), privacy: .public) \
            clearance=\(clearance, format: .fixed(precision: 3))m \
            (need \(SurfaceValidationRules.requiredRadius, format: .fixed(precision: 3))m) \
            distance=\(distance, format: .fixed(precision: 3))m
            """)
    }
}
