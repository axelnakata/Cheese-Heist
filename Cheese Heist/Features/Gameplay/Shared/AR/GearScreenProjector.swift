//
//  GearScreenProjector.swift
//  Cheese Heist
//
//  World -> screen, for everything the SwiftUI overlay draws over a gear: the tap
//  targets, the role label leader lines, and the spotlight holes.
//
//  THIS IS THE TYPE THAT KEEPS `Level1ViewModel` FREE OF ARKit. It is the only place
//  the conversion happens, so nothing above it ever handles a `simd_float3`.
//
//  The radius is PROJECTED rather than computed from a distance, by projecting a second
//  point one tip-radius to the side and measuring the gap on screen. A gear seen from
//  40cm and one seen from 15cm need different-sized tap targets, and the projection
//  already knows the difference.
//

import ARKit
import CoreGraphics
import RealityKit
import simd

@MainActor
final class GearScreenProjector {

    private weak var arView: ARView?

    init(arView: ARView) {
        self.arView = arView
    }

    /// Where each gear is on screen this frame. Gears behind the camera or off-screen
    /// are dropped, so an empty result means "nothing to draw", not "an error".
    func targets(
        for placements: [GearPlacement],
        assignment: GearRoleAssignment?,
        root: Entity?
    ) -> [GearScreenTarget] {
        guard let arView, let root else { return [] }

        return placements.compactMap { placement in
            guard let role = assignment?.role(of: placement.id) else { return nil }

            let world = root.convert(position: placement.local, to: nil)
            guard let centre = arView.project(world) else { return nil }

            return GearScreenTarget(
                id: placement.id,
                role: role,
                type: placement.type,
                center: centre,
                radius: projectedRadius(
                    of: placement, world: world, centre: centre, root: root, in: arView
                )
            )
        }
    }

    /// The gear's tip radius, measured on screen.
    ///
    /// Offset along the crane's local +X, which is along the beam and therefore
    /// perpendicular to the view when the child is facing the crane — the direction in
    /// which the gear is widest on screen.
    private func projectedRadius(
        of placement: GearPlacement,
        world: simd_float3,
        centre: CGPoint,
        root: Entity,
        in arView: ARView
    ) -> CGFloat {
        let edgeLocal = placement.local + simd_float3(GearGeometry.tipRadius(of: placement.type), 0, 0)
        let edgeWorld = root.convert(position: edgeLocal, to: nil)

        guard let edge = arView.project(edgeWorld) else { return 0 }
        return hypot(edge.x - centre.x, edge.y - centre.y)
    }
}
