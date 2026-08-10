//
//  MockCraneScene.swift
//  Cheese Heist
//
//  A `CraneSceneProviding` that owns no AR at all.
//
//  This is what makes PRD §8.6 possible: every Level 1 layer renders on a Mac with no
//  device attached, because the protocol between the ViewModel and the scene carries
//  only points, ids and value types. A screen that cannot be previewed cannot be
//  reviewed.
//

import CoreGraphics
import Foundation
import simd

@MainActor
final class MockCraneScene: CraneSceneProviding {

    private(set) var placements: [GearPlacement]
    private(set) var screenTargets: [GearScreenTarget] = []

    /// Above and left of the driver gear, which is where the mouse stands.
    private(set) var mouseScreenAnchor: CGPoint? = CGPoint(x: 604, y: 250)

    /// What the last call asked for, so a preview can show the choreography without
    /// anything being drawn in 3D.
    private(set) var pose: MouseSprite = .happy
    private(set) var isRopeVisible = true
    private(set) var highlighted: Set<UUID> = []
    private(set) var lastState = GearTrainState()
    private(set) var isTornDown = false

    init(pair: GearPair = PreviewGearPair.smallAndLarge) {
        let driver = GearPlacement(
            id: UUID(), type: pair.driver, local: simd_float3(-0.012, 0, 0)
        )
        let follower = GearPlacement(
            id: UUID(), type: pair.follower, local: simd_float3(0.012, 0, 0)
        )
        placements = [driver, follower]
        apply(
            assignment: GearRoleAssignment(driverID: driver.id, followerID: follower.id),
            animated: false
        )
    }

    func apply(assignment: GearRoleAssignment, animated: Bool) {
        // Screen positions are made up but plausible for a 1366 x 1024 frame, so the
        // labels and tap targets land somewhere a reviewer can judge.
        screenTargets = placements.compactMap { placement in
            guard let role = assignment.role(of: placement.id) else { return nil }
            return GearScreenTarget(
                id: placement.id,
                role: role,
                type: placement.type,
                center: role == .driver
                    ? CGPoint(x: 640, y: 330)
                    : CGPoint(x: 762, y: 300),
                radius: CGFloat(GearGeometry.tipRadius(of: placement.type)) * 2_600
            )
        }
    }

    func apply(state: GearTrainState, ratio: Double) { lastState = state }
    func setMousePose(_ pose: MouseSprite) { self.pose = pose }
    func setRopeVisible(_ visible: Bool) { isRopeVisible = visible }
    func setHighlightedGears(_ ids: Set<UUID>) { highlighted = ids }
    func teardown() { isTornDown = true }
}
