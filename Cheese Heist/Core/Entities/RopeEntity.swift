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

    /// Below this the rope has been wound all the way in and is taken off screen rather
    /// than drawn as a speck. "No rope left" is the signal the child reads as done.
    static let minimumVisibleLength: Float = 0.002

    let entity: ModelEntity

    /// The full drop from the axle to the resting cheese, in metres. Set once at build
    /// time from the measured table height; the lift then moves the cheese UP it.
    private(set) var restingDrop: Float

    /// The gap the rope currently spans, and whether the scene wants it drawn at all.
    /// Kept apart so that winding the rope fully in and hiding the whole payload are
    /// two independent reasons for the same entity to be off, and neither undoes the
    /// other on the next frame.
    private var length: Float
    private var isShown = true

    init(restingDrop: Float) {
        self.restingDrop = restingDrop
        self.length = restingDrop
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

    /// Restretches the rope so its top stays at the axle and its bottom meets the top of
    /// the cheese. The cylinder is generated centred on its own origin, hence the
    /// halving.
    ///
    /// A fully wound rope is HIDDEN rather than drawn a millimetre long. The child is
    /// being asked to read "the cheese is up at the gear" off the picture, and a
    /// leftover speck of rope between the two says the opposite.
    func setLength(_ length: Float) {
        self.length = max(length, 0)

        if self.length > Self.minimumVisibleLength {
            entity.model?.mesh = .generateCylinder(height: self.length, radius: Self.radius)
            entity.position = simd_float3(0, -self.length / 2, 0)
        }
        refreshVisibility()
    }

    /// Whether the scene wants a rope at all, independent of how long it is.
    func setVisible(_ visible: Bool) {
        isShown = visible
        refreshVisibility()
    }

    private func refreshVisibility() {
        entity.isEnabled = isShown && length > Self.minimumVisibleLength
    }
}
