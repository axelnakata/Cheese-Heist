//
//  CatOrbitDriver.swift
//  Cheese Heist
//
//  Turns `OrbitPatrolModel`'s pure output into transforms on the cat, once per frame.
//
//  Split out of `CutsceneSceneCoordinator` so the coordinator stays an owner of anchors
//  and this stays the only place the cat's transform is written — the same split as
//  `LiftRunner` against `GameplaySceneCoordinator`.
//
//  ═══ THE WALK PAUSES, IT DOES NOT RESTART. ═══
//
//  The first version called `stopAllAnimations()` on every frame of a pause and never
//  started the walk again afterwards, so the cat played its cycle once and then slid
//  round the circle with its legs frozen. Holding the `AnimationPlaybackController` and
//  pausing it means the cycle resumes mid-stride, which is also what it looks like when
//  a real animal stops to look at something and then carries on.
//
//  The heading is eased rather than assigned. Writing the tangent straight in snapped
//  the cat through 180° the instant a pause ended and read as a turntable.
//

import RealityKit
import simd

@MainActor
final class CatOrbitDriver {

    private let cat: CutsceneStage
    private var orbit: OrbitPatrolModel
    private var playback: AnimationPlaybackController?
    private var isWalking = false
    private var heading: Float

    init(cat: CutsceneStage, seed: UInt64 = 0) {
        self.cat = cat
        self.orbit = OrbitPatrolModel(
            radius: CutsceneTuning.orbitRadius,
            speed: CutsceneTuning.orbitSpeed,
            seed: seed
        )
        self.heading = 0
        place(angle: 0)
        heading = Self.travelHeading(at: 0)
        cat.catHolder.orientation = Self.yaw(heading)
        startWalking()
    }

    func advance(deltaTime: Float) {
        let state = orbit.advance(by: Double(deltaTime))
        let angle = Float(state.angle)

        place(angle: angle)
        ease(
            toward: state.isPaused ? Self.lookInwardHeading(at: angle)
                                   : Self.travelHeading(at: angle),
            deltaTime: deltaTime
        )
        setWalking(!state.isPaused)
    }

    // MARK: - Transform

    private func place(angle: Float) {
        let radius = Float(CutsceneTuning.orbitRadius)
        cat.catHolder.position = simd_float3(radius * cos(angle), 0, radius * sin(angle))
    }

    private func ease(toward target: Float, deltaTime: Float) {
        let delta = Self.shortestDelta(from: heading, to: target)
        let step = CutsceneTuning.catTurnRate * deltaTime
        heading += abs(delta) <= step ? delta : (delta < 0 ? -step : step)
        cat.catHolder.orientation = Self.yaw(heading)
    }

    // MARK: - Walk

    private func setWalking(_ walking: Bool) {
        guard walking != isWalking else { return }
        isWalking = walking
        if walking {
            if let playback, !playback.isComplete { playback.resume() } else { startWalking() }
        } else {
            playback?.pause()
        }
    }

    private func startWalking() {
        guard let walk = cat.catWalk else { return }
        playback = cat.catAnimated.playAnimation(walk)
        isWalking = true
    }

    // MARK: - Angles

    /// Heading along the direction of travel. The orbit runs anticlockwise in XZ, so the
    /// tangent at θ is (−sin θ, 0, cos θ).
    private static func travelHeading(at angle: Float) -> Float {
        atan2(-sin(angle), cos(angle)) + CutsceneTuning.catForwardYaw
    }

    /// Heading that turns the cat to face the cheese at the centre.
    private static func lookInwardHeading(at angle: Float) -> Float {
        atan2(-cos(angle), -sin(angle)) + CutsceneTuning.catForwardYaw
    }

    private static func yaw(_ angle: Float) -> simd_quatf {
        simd_quatf(angle: angle, axis: simd_float3(0, 1, 0))
    }

    /// Signed difference in (−π, π], so the cat turns the short way round.
    private static func shortestDelta(from current: Float, to target: Float) -> Float {
        var delta = (target - current).truncatingRemainder(dividingBy: 2 * .pi)
        if delta > .pi { delta -= 2 * .pi }
        if delta < -.pi { delta += 2 * .pi }
        return delta
    }
}
