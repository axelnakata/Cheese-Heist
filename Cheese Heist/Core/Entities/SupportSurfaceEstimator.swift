//
//  SupportSurfaceEstimator.swift
//  Cheese Heist
//
//  Finds the surface the crane stands on. One job — answer "how far below the gears is
//  the table?".
//
//  WHY THIS IS KEPT (PRD-Level1 §10.1 records the decision):
//  `liftHeight` is a fixed 0.06m tuning constant, so it is tempting to drop this and
//  rest the cheese at `follower.y − 0.06`. That puts the cheese either floating above
//  the baseplate or sunk into it, depending on how tall the child built their crane —
//  in the very first thing they see. Ninety lines to remove that is worth it. This sets
//  where the cheese RESTS; `tuning.liftHeight` still governs how far it travels.
//
//  WHY IT IS HARDER THAN "ASK ARKIT FOR THE FLOOR":
//  That gets burned two ways — it returns the actual room floor (far below a small
//  crane on a table, producing a rope that runs through the tabletop), or it returns
//  nothing at all because that area has not been scanned yet. Three things fix it:
//
//  1. RAY DIRECTION. Cast straight DOWN from the gear and take the NEAREST hit. The
//     tabletop is physically between the gear and the floor, so nearest-below IS the
//     table. The floor can only win if the table is missed entirely.
//  2. A PLAUSIBILITY WINDOW. A hit counts only 3cm to 1m below the gear. A room floor
//     under a table-top crane falls outside that and is rejected rather than used.
//  3. CONTINUOUS SAMPLING. Run every frame while the camera is live and keep a running
//     median, so a few bad raycasts cannot decide the answer and coverage improves on
//     its own as the child moves the iPad around.
//

import ARKit
import simd

@MainActor
final class SupportSurfaceEstimator {

    /// A surface must be at least this far below the gear to be the table and not the
    /// gear's own mounting hardware.
    static let minimumDrop: Float = 0.03

    /// …and no further than this, which is what rejects the room floor.
    ///
    /// A CRANE'S HEIGHT, NOT A ROOM'S. This was a metre, which is not a rejection at
    /// all: a crane on a desk has its gears maybe 15cm above the desk and 75cm above the
    /// carpet, and 75cm is inside a one-metre window. So the "nearest hit below" rule
    /// quietly returned the floor whenever the desk had not been meshed yet, and the
    /// rope paid out three quarters of a metre through the desk with the cheese somewhere
    /// past the bottom of the screen. 30cm is taller than any crane built from one
    /// baseplate and shorter than any table, so the two cases stop overlapping — and
    /// when nothing plausible is found the 9cm fallback is a far better wrong answer
    /// than the floor.
    static let maximumDrop: Float = 0.30

    static let sampleWindow = 40
    static let samplesForStability = 8

    /// Median world-space Y of the supporting surface. Nil until a sample lands.
    private(set) var surfaceY: Float?
    private(set) var isStable = false

    private var samples: [Float] = []

    func reset() {
        samples.removeAll()
        surfaceY = nil
        isStable = false
    }

    /// Takes one measurement of the surface below `gearPosition`. Safe to call every
    /// frame; cheap, and ignores implausible hits.
    func update(session: ARSession, below gearPosition: simd_float3) {
        guard let hit = measure(session: session, below: gearPosition) else { return }

        samples.append(hit)
        if samples.count > Self.sampleWindow {
            samples.removeFirst(samples.count - Self.sampleWindow)
        }

        let sorted = samples.sorted()
        surfaceY = sorted[sorted.count / 2]

        // Stability is judged on the middle 80% so a couple of outliers — a hand
        // passing through, a momentary bad reading — cannot hold it back.
        guard sorted.count >= Self.samplesForStability else { return }
        let trim = sorted.count / 10
        let middle = sorted[trim..<(sorted.count - trim)]
        if let low = middle.first, let high = middle.last {
            isStable = (high - low) <= 0.02
        }
    }

    /// How far the cheese should hang below `gearPosition` at rest, in metres.
    /// Falls back to a plausible tabletop drop while nothing has been measured yet.
    func restingDrop(below gearPosition: simd_float3, fallback: Float) -> Float {
        guard let surfaceY else { return fallback }
        return (gearPosition.y - surfaceY).clamped(to: Self.minimumDrop...Self.maximumDrop)
    }

    // MARK: - Measurement

    private func measure(session: ARSession, below gearPosition: simd_float3) -> Float? {
        let query = ARRaycastQuery(
            origin: gearPosition,
            direction: simd_float3(0, -1, 0),
            allowing: .estimatedPlane,
            alignment: .horizontal
        )

        // Results come back sorted nearest-first, which is exactly the "table before
        // floor" ordering this relies on.
        for result in session.raycast(query) {
            let candidate = result.worldTransform.columns.3.y
            if isPlausible(candidate, below: gearPosition) { return candidate }
        }

        return planeAnchorY(session: session, below: gearPosition)
    }

    /// Fallback: the HIGHEST detected horizontal plane under the gear — not the
    /// nearest to the camera, because with a crane on a table the table is above the
    /// floor and both may have been detected.
    private func planeAnchorY(session: ARSession, below gearPosition: simd_float3) -> Float? {
        guard let anchors = session.currentFrame?.anchors else { return nil }

        var candidates: [Float] = []
        for case let plane as ARPlaneAnchor in anchors where plane.alignment == .horizontal {
            let surface: Float = plane.transform.columns.3.y + plane.center.y
            guard isPlausible(surface, below: gearPosition),
                  covers(plane: plane, gearPosition: gearPosition) else { continue }
            candidates.append(surface)
        }
        return candidates.max()
    }

    /// Require the gear to actually be over this plane, so a nearby surface at the
    /// right height — a chair, a shelf — is not mistaken for the table.
    private func covers(plane: ARPlaneAnchor, gearPosition: simd_float3) -> Bool {
        let centre = plane.transform * simd_float4(plane.center, 1)
        let halfWidth = plane.planeExtent.width / 2
        let halfDepth = plane.planeExtent.height / 2
        return abs(gearPosition.x - centre.x) <= halfWidth + 0.05
            && abs(gearPosition.z - centre.z) <= halfDepth + 0.05
    }

    private func isPlausible(_ candidate: Float, below gearPosition: simd_float3) -> Bool {
        let drop = gearPosition.y - candidate
        return drop >= Self.minimumDrop && drop <= Self.maximumDrop
    }
}
