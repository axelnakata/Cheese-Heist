//
//  ResultEffectDriver.swift
//  Cheese Heist
//
//  The result screen's micro-interaction: a short particle burst over the crane when a
//  level ends, celebrating a success or cushioning a fail.
//
//  Built on RealityKit's OWN particle presets rather than a bundled asset — there is no
//  cheese-confetti or smoke-puff art to source, and `ParticleEmitterComponent` already
//  ships a `sparks` and an `impact` preset (iOS 18+, this app's floor). Retinting and
//  re-timing those is a few lines; a custom mesh/texture pipeline would not be.
//

import RealityKit
import SwiftUI
import simd

@MainActor
enum ResultEffectDriver {

    /// How long the burst entity is kept around before being removed, in seconds.
    /// Generous relative to the ~0.2s birth window so every spawned particle has
    /// finished its own fall/fade before the entity disappears out from under it.
    private static let lifetime: TimeInterval = 2.5

    /// Attaches a one-shot burst to `root` at `position` and lets it clean itself up.
    static func play(_ kind: ResultEffectKind, at position: simd_float3, on root: Entity) {
        let emitter = Entity()
        emitter.position = position
        root.addChild(emitter)
        emitter.components.set(component(for: kind))

        DispatchQueue.main.asyncAfter(deadline: .now() + lifetime) { [weak emitter] in
            emitter?.removeFromParent()
        }
    }

    private static func component(for kind: ResultEffectKind) -> ParticleEmitterComponent {
        switch kind {
        case .success(let starCount): return successBurst(starCount: starCount)
        case .fail: return failPuff()
        }
    }

    /// A short, upward shower of cheese-gold sparks — celebratory, not a fireworks show.
    /// Scales gently with the star count so a bare 1-star clear still reads as a win.
    private static func successBurst(starCount: Int) -> ParticleEmitterComponent {
        var particles = ParticleEmitterComponent.Presets.sparks
        particles.timing = .once(emit: .init(duration: 0.2))
        particles.mainEmitter.birthRate = Float(60 * max(1, min(starCount, 3)))

        let spark = UIColor(AppColor.celebrationSpark)
        particles.mainEmitter.color = .evolving(
            start: .single(spark),
            end: .single(spark.withAlphaComponent(0))
        )
        return particles
    }

    /// A soft grey puff — the opposite gesture from `successBurst`. One look for both
    /// fail reasons (too weak / out of time); the overlay's title carries which.
    private static func failPuff() -> ParticleEmitterComponent {
        var particles = ParticleEmitterComponent.Presets.impact
        particles.timing = .once(emit: .init(duration: 0.15))
        particles.mainEmitter.birthRate = 45
        particles.speed = 0.15

        let smoke = UIColor(AppColor.failSmoke)
        particles.mainEmitter.color = .evolving(
            start: .single(smoke.withAlphaComponent(0.75)),
            end: .single(smoke.withAlphaComponent(0))
        )
        return particles
    }
}
