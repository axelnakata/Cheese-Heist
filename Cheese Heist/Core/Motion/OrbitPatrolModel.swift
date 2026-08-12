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

import Foundation

struct OrbitPatrolState: Equatable, Sendable {
    let angle: Double
    let isPaused: Bool
}

struct OrbitPatrolModel {
    private let radius: Double
    private let angularSpeed: Double

    private var angle: Double = 0
    private var isPaused = false

    /// Time until next pause/resume toggle.
    private var countdown: Double
    /// How long the current pause lasts (only meaningful when paused).
    private var pauseDuration: Double = 0
    /// Time spent in the current pause.
    private var pauseElapsed: Double = 0

    private var rng: RandomNumberGenerator & Sendable

    init(radius: Double, speed: Double, seed: UInt64 = 0) {
        self.radius = radius
        self.angularSpeed = speed / radius
        self.rng = SeededRNG(seed: seed)
        self.countdown = Self.nextWalkDuration(using: &rng)
    }

    mutating func advance(by dt: Double) -> OrbitPatrolState {
        guard dt > 0 else {
            return OrbitPatrolState(angle: angle, isPaused: isPaused)
        }

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
                angle += angularSpeed * step
                countdown -= step
                remaining -= step
                if countdown <= 0 {
                    isPaused = true
                    pauseDuration = Self.nextPauseDuration(using: &rng)
                    pauseElapsed = 0
                }
            }
        }

        // Wrap angle to [0, 2π).
        angle = angle.truncatingRemainder(dividingBy: .pi * 2)
        if angle < 0 { angle += .pi * 2 }

        return OrbitPatrolState(angle: angle, isPaused: isPaused)
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
