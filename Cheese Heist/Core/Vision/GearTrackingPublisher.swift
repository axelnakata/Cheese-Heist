//
//  GearTrackingPublisher.swift
//  Cheese Heist
//
//  TWO CLOCKS, KEPT SEPARATE (PRD-Level1 §6.2).
//
//  - FAST PATH, every update (~6 Hz): `onTrackingUpdate` fires unconditionally. This is
//    the path the AR scene listens on, and it deliberately bypasses Observation — the
//    alignment filter wants every measurement it can get so its easing has something to
//    interpolate against.
//
//  - SLOW PATH, every third update (~2 Hz): `shouldRefreshObservableState` gates the
//    `@Observable` properties that drive the SwiftUI HUD, which wants as few updates as
//    possible and does not care that a marker moved by a pixel.
//
//  It also carries gear ids across updates. Minting a fresh id every time the estimate
//  improves would silently clear a driver the child had already chosen.
//

import Foundation
import simd

final class GearTrackingPublisher {

    /// How often the observable properties are refreshed, in ticks.
    static let statePublishInterval = 3

    /// Called on EVERY tracking update, ahead of the throttled observable state.
    var onTrackingUpdate: ((CraneFrame, [DetectedGear]) -> Void)?

    private var counter = 0

    func reset() {
        counter = 0
    }

    /// Turns one solution into gears, fires the fast path, and says whether the caller
    /// should also refresh its observable state this tick.
    func publish(
        solution: CranePlaneSolution,
        detections: [GearDetection],
        previous: [DetectedGear],
        force: Bool
    ) -> [DetectedGear]? {
        let updated = merge(solution: solution, detections: detections, previous: previous)
        onTrackingUpdate?(solution.frame, updated)

        counter += 1
        guard force || counter % Self.statePublishInterval == 0 else { return nil }
        return updated
    }

    /// Pairs each ordered detection with its solved world position, reusing the id of
    /// the gear with the same tooth count from the previous update.
    private func merge(
        solution: CranePlaneSolution,
        detections: [GearDetection],
        previous: [DetectedGear]
    ) -> [DetectedGear] {
        let ordered = GearOrdering.ordered(detections)

        return zip(ordered, solution.gearPositions).compactMap { detection, position in
            guard let type = GearType(rawValue: detection.toothCount) else { return nil }
            return DetectedGear(
                id: previous.first { $0.toothCount == detection.toothCount }?.id ?? UUID(),
                type: type,
                confidence: detection.confidence,
                worldPosition: position,
                // Both gears turn on the beam's normal — parallel axes, one number.
                axis: solution.frame.normal
            )
        }
    }
}
