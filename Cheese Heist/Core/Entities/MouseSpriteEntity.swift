//
//  MouseSpriteEntity.swift
//  Cheese Heist
//
//  The mouse: a flat textured quad that always faces the camera.
//
//  A sprite rather than a model because the art IS a sprite — four rendered PNGs, not
//  a rig. Registering it with `BillboardSystem` is what stops it disappearing edge-on,
//  and swapping its texture is what makes a pose change free.
//

import RealityKit
import UIKit
import os

@MainActor
final class MouseSpriteEntity {

    /// How tall the mouse stands, in metres. Sized against the crane rather than the
    /// gear it perches on: the same mouse has to look right on an 8T and a 40T.
    static let height: Float = 0.055

    let entity: ModelEntity

    private var textures: [MouseSprite: TextureResource] = [:]
    private(set) var pose: MouseSprite

    init?(pose: MouseSprite = .happy) {
        self.pose = pose
        entity = ModelEntity(mesh: Self.quad(for: pose), materials: [UnlitMaterial()])

        guard apply(pose) else {
            Logger.scene.error("mouse sprite \(pose.assetName, privacy: .public) is missing")
            return nil
        }
    }

    /// Swaps the pose, rebuilding the quad when the new art is a different shape.
    ///
    /// The three talking poses share a trim, so between those this changes only the
    /// pixels and the mouse does not shift on screen. `happy` is trimmed on its own, so
    /// re-texturing alone would stretch it.
    func setPose(_ next: MouseSprite) {
        guard next != pose, apply(next) else { return }
        if next.aspectRatio != pose.aspectRatio {
            entity.model?.mesh = Self.quad(for: next)
        }
        pose = next
    }

    /// A plane in XY facing +Z, which is the axis `BillboardSystem` turns to the camera.
    private static func quad(for pose: MouseSprite) -> MeshResource {
        .generatePlane(width: height * Float(pose.aspectRatio), height: height)
    }

    @discardableResult
    private func apply(_ sprite: MouseSprite) -> Bool {
        guard let texture = texture(for: sprite) else { return false }

        var material = UnlitMaterial()
        material.color = .init(tint: .white, texture: .init(texture))
        // The PNG is mostly transparent canvas around the mouse; without this it draws
        // as a white card.
        material.blending = .transparent(opacity: .init(floatLiteral: 1))
        // A cutout, not a fade. The mouse's own pixels are fully opaque and the canvas
        // is fully clear, so discarding the clear ones outright keeps the sprite out of
        // the transparency sort — which is what stops it flickering behind the rope and
        // the cheese as the child walks around the crane.
        material.opacityThreshold = 0.5
        material.faceCulling = .none

        entity.model?.materials = [material]
        return true
    }

    private func texture(for sprite: MouseSprite) -> TextureResource? {
        if let cached = textures[sprite] { return cached }
        guard let loaded = try? TextureResource.load(named: sprite.assetName) else { return nil }
        textures[sprite] = loaded
        return loaded
    }
}
