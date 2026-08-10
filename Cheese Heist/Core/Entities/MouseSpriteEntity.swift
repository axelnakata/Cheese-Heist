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

    init?(pose: MouseSprite = .talkIdle) {
        self.pose = pose

        let width = Self.height * Float(pose.aspectRatio)
        let mesh = MeshResource.generatePlane(width: width, height: Self.height)
        entity = ModelEntity(mesh: mesh, materials: [UnlitMaterial()])

        guard apply(pose) else {
            Logger.scene.error("mouse sprite \(pose.assetName, privacy: .public) is missing")
            return nil
        }
    }

    /// Swaps the pose. The three in-scene poses share a trim, so this changes only the
    /// pixels — the mouse does not shift on screen.
    func setPose(_ next: MouseSprite) {
        guard next != pose, apply(next) else { return }
        pose = next
    }

    @discardableResult
    private func apply(_ sprite: MouseSprite) -> Bool {
        guard let texture = texture(for: sprite) else { return false }

        var material = UnlitMaterial()
        material.color = .init(tint: .white, texture: .init(texture))
        // The PNG is mostly transparent canvas around the mouse; without this it draws
        // as a white card.
        material.blending = .transparent(opacity: .init(floatLiteral: 1))
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
