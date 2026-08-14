//
//  GearShakeDriver.swift
//  Cheese Heist
//
//  Writes a small oscillating jitter on top of the two gear twins' frozen spin
//  orientation while a stalled combo strains against a load it can't lift.
//
//  Split out of `GameplaySceneCoordinator` so the coordinator stays an owner of anchors
//  and this stays the only place the shake's transform is written — the same split as
//  `LiftRunner` against `GameplaySceneCoordinator` (and `CatOrbitDriver` against the
//  cutscene coordinator).
//
//  The base orientation is captured ONCE, on entry — `apply(state:ratio:)` stops being
//  called the instant the phase leaves `.cranking` (its `LiftSegment` goes nil), so the
//  gears are already frozen wherever the last cranking frame left them. The jitter is
//  composed on top of that frozen base every frame, never replacing it, so restoring on
//  exit is exact.
//

import RealityKit
import simd

@MainActor
final class GearShakeDriver {

    private let driverSpin: Entity
    private let followerSpin: Entity
    private let driverBase: simd_quatf
    private let followerBase: simd_quatf
    private var elapsed: Float = 0

    init(driverSpin: Entity, followerSpin: Entity) {
        self.driverSpin = driverSpin
        self.followerSpin = followerSpin
        self.driverBase = driverSpin.orientation
        self.followerBase = followerSpin.orientation
    }

    /// One frame of the shake. Not too dramatic — a small wobble, not a spin.
    func advance(deltaTime: Float) {
        elapsed += deltaTime
        let angle = Float(Level2Tuning.stallShakeAmplitudeRadians)
            * sin(elapsed * Float(Level2Tuning.stallShakeFrequencyHz) * 2 * .pi)

        // Opposing wobble — the two gears straining against each other, not spinning
        // together, which is what reads as a clash rather than a shared tremor.
        driverSpin.orientation = driverBase * simd_quatf(angle: angle, axis: simd_float3(0, 0, 1))
        followerSpin.orientation = followerBase * simd_quatf(angle: -angle, axis: simd_float3(0, 0, 1))
    }

    /// Puts both gears back exactly where the shake found them.
    func restore() {
        driverSpin.orientation = driverBase
        followerSpin.orientation = followerBase
    }
}
