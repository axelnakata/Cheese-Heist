//
//  OrbitPatrolModel.swift
//  Cheese Heist
//
//  PRD-Cutscene §7.5 — a cat walking in a circle, pausing to look at the cheese.
//
//  PURE, DETERMINISTIC (seeded) — unit tested. The pause cadence is randomised but
//  reproducible via a seed, so tests get the same sequence every run.
//
//  Angular velocity is `speed / radius`, so retuning the radius keeps the cat's ground
//  speed honest. Pause cadence per §6.3: 0.5–1.5 s every 2–4 s. The cat is never idle
//  for more than 1.5 s — a frozen cat reads as a bug and destroys the threat premise.
//
//  ═══ AN OPTIONAL `arc` TURNS THE LAP INTO A PATROL. ═══
//
//  The cutscene's cat has the cheese to itself and walks the whole circle. Level 2's has a
//  crane in the middle of its circle, and on the far half of the lap the cat is BEHIND that
//  crane — drawn over the beam, the gears and the mouse, twenty centimetres further from
//  the camera and so appearing to float above them (see `toFix/IMG_0113.PNG`). Nothing is
//  actually intersecting; it just reads as a pile of props.
//
//  So an arc-bounded model walks to a bound, PAUSES, reverses, and walks back — a sentry's
//  patrol rather than a lap. The pause at the turn is the point: the driver eases the cat's
//  heading rather than snapping it, and the tangent flips by a full 180° at a reversal, so
//  turning while still walking would slide the cat backwards for the better part of a
//  second. Stopping first means it walks up to the end of its beat, looks at the crane,
//  turns on the spot and sets off the other way.
//
//  `arc == nil` is the full circle, unchanged, and is what the cutscene passes.
//

import Foundation

struct OrbitPatrolState: Equatable, Sendable {
    let angle: Double
    let isPaused: Bool

    /// Which way round the cat is currently walking: +1 anticlockwise, −1 clockwise.
    /// Always +1 without an `arc`. The driver needs it because the tangent it points the
    /// cat along is the reverse one on the way back.
    let direction: Double
}

struct OrbitPatrolModel {
    private let radius: Double
    private let angularSpeed: Double

    /// The angles the cat is allowed to occupy, or nil for the whole circle.
    private let arc: ClosedRange<Double>?

    private var angle: Double = 0
    private var direction: Double = 1
    private var isPaused = false

    /// Time until next pause/resume toggle.
    private var countdown: Double
    /// How long the current pause lasts (only meaningful when paused).
    private var pauseDuration: Double = 0
    /// Time spent in the current pause.
    private var pauseElapsed: Double = 0

    private var rng: RandomNumberGenerator & Sendable

    init(radius: Double, speed: Double, arc: ClosedRange<Double>? = nil, seed: UInt64 = 0) {
        self.radius = radius
        self.angularSpeed = speed / radius
        self.arc = arc
        self.angle = arc?.lowerBound ?? 0
        self.rng = SeededRNG(seed: seed)
        self.countdown = Self.nextWalkDuration(using: &rng)
    }

    mutating func advance(by dt: Double) -> OrbitPatrolState {
        guard dt > 0 else { return state }

        var remaining = dt

        while remaining > 0 {
            if isPaused {
                let step = min(remaining, pauseDuration - pauseElapsed)
                pauseElapsed += step
                remaining -= step
                if pauseElapsed >= pauseDuration {
                    isPaused = false
                    countdown = Self.nextWalkDuration(using: &rng)
                }
            } else {
                let step = min(remaining, countdown)
                angle += angularSpeed * step * direction
                countdown -= step
                remaining -= step
                if countdown <= 0 || turnedAtBound() {
                    isPaused = true
                    pauseDuration = Self.nextPauseDuration(using: &rng)
                    pauseElapsed = 0
                }
            }
        }

        // Wrap angle to [0, 2π) — but only on the full circle. An arc is kept inside its
        // own bounds by `turnedAtBound`, and wrapping one that reaches below zero would
        // teleport the cat to the other end of its beat.
        if arc == nil {
            angle = angle.truncatingRemainder(dividingBy: .pi * 2)
            if angle < 0 { angle += .pi * 2 }
        }

        return state
    }

    private var state: OrbitPatrolState {
        OrbitPatrolState(angle: angle, isPaused: isPaused, direction: direction)
    }

    /// Clamps to the bound the cat has just walked into and turns it round. False — and no
    /// pause — on the full circle, which has no bounds to reach.
    private mutating func turnedAtBound() -> Bool {
        guard let arc, !arc.contains(angle) else { return false }
        angle = min(max(angle, arc.lowerBound), arc.upperBound)
        direction = -direction
        return true
    }

    // MARK: - Randomised cadence

    /// Walk for 2–4 seconds before pausing.
    private static func nextWalkDuration(
        using rng: inout some RandomNumberGenerator
    ) -> Double {
        Double.random(in: 2.0...4.0, using: &rng)
    }

    /// Pause for 0.5–1.5 seconds — never idle > 1.5 s.
    private static func nextPauseDuration(
        using rng: inout some RandomNumberGenerator
    ) -> Double {
        Double.random(in: 0.5...1.5, using: &rng)
    }
}

// MARK: - Seeded RNG

/// A simple seeded random number generator for deterministic tests.
private struct SeededRNG: RandomNumberGenerator, Sendable {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed
    }

    mutating func next() -> UInt64 {
        // SplitMix64
        state &+= 0x9e37_79b9_7f4a_7c15
        var result = state
        result = (result ^ (result >> 30)) &* 0xbf58_476d_1ce4_e5b9
        result = (result ^ (result >> 27)) &* 0x94d0_49bb_1331_11eb
        return result ^ (result >> 31)
    }
}
