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

    /// One frame of the shake.
    ///
    /// Two sines rather than one for the rotation: a slow wobble alone reads as a
    /// smooth back-and-forth rock, which is what a healthy mesh under a light load also
    /// looks like. Layering a faster, non-harmonic jitter on top breaks that regularity
    /// into something that reads as teeth grinding against a load they can't turn.
    ///
    /// A rotational wobble on a part this small reads as almost nothing from AR viewing
    /// distance — a few degrees on a 10–40mm gear is a couple of millimetres of visible
    /// travel at the rim. The position jitter is what actually sells "struggling":
    /// pushed back and forth along the beam, opposite each other, same non-harmonic sum.
    func advance(deltaTime: Float) {
        elapsed += deltaTime
        let wobble = Float(Level2Tuning.stallShakeAmplitudeRadians)
            * sin(elapsed * Float(Level2Tuning.stallShakeFrequencyHz) * 2 * .pi)
        let jitter = Float(Level2Tuning.stallShakeJitterAmplitudeRadians)
            * sin(elapsed * Float(Level2Tuning.stallShakeJitterFrequencyHz) * 2 * .pi)
        let angle = wobble + jitter

        let positionJitter = Float(Level2Tuning.stallShakePositionJitterMeters)
            * sin(elapsed * Float(Level2Tuning.stallShakeJitterFrequencyHz) * 2 * .pi)

        // Opposing on both axes — the two gears straining against each other, not
        // moving together, which is what reads as a clash rather than a shared tremor.
        driverSpin.orientation = driverBase * simd_quatf(angle: angle, axis: simd_float3(0, 0, 1))
        driverSpin.position = simd_float3(positionJitter, 0, 0)
        followerSpin.orientation = followerBase * simd_quatf(angle: -angle, axis: simd_float3(0, 0, 1))
        followerSpin.position = simd_float3(-positionJitter, 0, 0)
    }

    /// Puts both gears back exactly where the shake found them.
    func restore() {
        driverSpin.orientation = driverBase
        driverSpin.position = .zero
        followerSpin.orientation = followerBase
        followerSpin.position = .zero
    }
}
