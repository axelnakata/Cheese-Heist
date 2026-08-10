//
//  RopeEntity.swift
//  Cheese Heist
//
//  The line from the follower gear's axle down to the cheese.
//
//  It hangs along the crane frame's local -Y, which gravity guarantees is world down:
//  the frame's up IS world up (see `CraneFrame`), so the rope needs no re-derivation
//  in world space and cannot lean when the child walks around.
//

import RealityKit
import SwiftUI
import UIKit

@MainActor
final class RopeEntity {

    /// Half a real string's thickness would be honest and invisible. At the 40cm the
    /// child holds the iPad at, 0.6mm subtends about two pixels — a dark hairline over a
    /// dark table, which is why the rope read as missing rather than as thin. 1.5mm is
    /// still a rope and is still there when they lean back.
    static let radius: Float = 0.0015

    let entity: ModelEntity

    /// The full drop from the axle to the resting cheese, in metres. Set once at build
    /// time from the measured table height; the lift then moves the cheese UP it.
    private(set) var restingDrop: Float

    init(restingDrop: Float) {
        self.restingDrop = restingDrop
        self.entity = ModelEntity(
            mesh: .generateCylinder(height: max(restingDrop, 0.001), radius: Self.radius),
            materials: [UnlitMaterial(color: UIColor(AppColor.textPrimary))]
        )
        setLength(restingDrop)
    }

    /// Updates where the table is. The cheese's resting height is a scene fact that
    /// improves as ARKit maps the surface, so it is re-measured rather than fixed at
    /// build time.
    ///
    /// Returns whether the table actually moved — by more than a millimetre, which is
    /// what stops the caller regenerating a cylinder mesh sixty times a second over
    /// float noise. It stores the number and draws nothing: only the caller knows how
    /// far the lift has already travelled up it.
    @discardableResult
    func setRestingDrop(_ drop: Float) -> Bool {
        guard abs(drop - restingDrop) > 0.001 else { return false }
        restingDrop = drop
        return true
    }

    /// Restretches the rope so its top stays at the axle and its bottom follows the
    /// cheese. The cylinder is generated centred on its own origin, hence the halving.
    func setLength(_ length: Float) {
        let clamped = max(length, 0.001)
        entity.model?.mesh = .generateCylinder(height: clamped, radius: Self.radius)
        entity.position = simd_float3(0, -clamped / 2, 0)
    }
}
