//
//  GearScreenTarget.swift
//  Cheese Heist
//
//  Where a gear is on screen, right now.
//
//  This is the whole reason `Level1ViewModel` never imports ARKit or RealityKit:
//  `GearScreenProjector` does the world-to-screen conversion and everything above it
//  handles points, radii and ids.
//

import CoreGraphics
import Foundation

struct GearScreenTarget: Equatable, Sendable, Identifiable {
    let id: UUID
    let role: GearRole
    let type: GearType

    /// Centre in view coordinates.
    let center: CGPoint

    /// On-screen radius of the gear's tips, in points. Derived by projecting a second
    /// point one tip-radius away, so it shrinks correctly with distance.
    let radius: CGFloat
}
