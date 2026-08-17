//
//  ResultEffectDriver.swift
//  Cheese Heist
//
//  The success screen's micro-interaction: a short "golden sparkle burst" over the
//  crane when the cheese is secured. No fail counterpart — a stall or a timeout is
//  carried by the fail SFX and the result overlay alone.
//
//  BUILT ENTIRELY BY HAND, NOT FROM `ParticleEmitterComponent.Presets`. The presets
//  looked like the lazy choice, but their internals are opaque — no visible way to
//  know whether a preset's visual weight comes from `mainEmitter` or from a
//  `spawnedEmitter` chain, or whether it lights itself against the scene the way this
//  app's dimmed AR lighting (`SceneLightingRig`) expects. Overriding a couple of fields
//  on top of one produced nothing on screen. Every field below is explicit instead, so
//  there is nothing hidden left to get in the way.
//
//  `isLightingEnabled = false` is the one field most likely to have been the actual
//  bug: a preset that IS lit renders however dim this app's AR key/fill lights happen
//  to be, which is tuned low so the gear twins don't blow out (`SceneLightingRig`).
//  Unlit sparks draw at their own colour regardless of scene light — closer to the
//  "glowing" spec than anything a real light could guarantee.
//

import RealityKit
import SwiftUI
import simd

@MainActor
enum ResultEffectDriver {

    /// How long the burst entity is kept around before being removed, in seconds.
    /// Generous relative to the emission window and each particle's own life span, so
    /// every spawned particle has finished fading before the entity disappears.
    private static let lifetime: TimeInterval = 2.0

    /// Attaches a one-shot gold-spark burst to `root` at `position` and lets it clean
    /// itself up. `starCount` (1–3) only scales how much of it plays.
    static func play(starCount: Int, at position: simd_float3, on root: Entity) {
        let emitter = Entity()
        emitter.position = position
        root.addChild(emitter)
        emitter.components.set(component(starCount: starCount))

        DispatchQueue.main.asyncAfter(deadline: .now() + lifetime) { [weak emitter] in
            emitter?.removeFromParent()
        }
    }

    /// A radial shower of small gold particles: born inside a short window, launched
    /// outward from a point, arcing down under a gentle acceleration as they fade —
    /// "shoot out quickly, arc downward, fade to transparent."
    private static func component(starCount: Int) -> ParticleEmitterComponent {
        var particles = ParticleEmitterComponent()
        particles.isEmitting = true

        // A point source that launches particles outward in every direction, rather
        // than RealityKit's default forward-facing jet.
        particles.emitterShape = .sphere
        particles.emitterShapeSize = SIMD3(repeating: 0.004)
        particles.birthLocation = .volume
        particles.birthDirection = .normal
        particles.speed = 0.22
        particles.speedVariation = 0.12

        // A burst, not a fountain: everything is born inside a quarter-second and
        // nothing more spawns once that window closes.
        particles.timing = .once(emit: .init(duration: 0.25))

        var spark = ParticleEmitterComponent.ParticleEmitter()
        spark.birthRate = Float(90 * max(1, min(starCount, 3)))
        spark.size = 0.006
        spark.sizeVariation = 0.002
        spark.lifeSpan = 0.6
        spark.lifeSpanVariation = 0.2
        spark.spreadingAngle = .pi
        spark.acceleration = SIMD3(0, -0.5, 0)
        spark.isLightingEnabled = false
        spark.blendMode = .additive
        spark.opacityCurve = .easeFadeOut

        let colour = UIColor(AppColor.celebrationSpark)
        spark.color = .evolving(start: .single(colour), end: .single(colour.withAlphaComponent(0)))

        particles.mainEmitter = spark
        return particles
    }
}
