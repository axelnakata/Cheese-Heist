//
//  BundledAssetTests.swift
//  CheeseHeistTests
//
//  Loads the REAL assets out of the REAL bundle and checks they come out the size the
//  scene expects.
//
//  Every other test in this target is pure. These are not, deliberately: the two ways
//  the scene has actually failed on device were a missing asset name and an asset that
//  loaded and measured wrong, and neither is reachable by a test that builds its own
//  entities. A `#Preview` cannot cover it either — none of this renders without a
//  session. This is the only place the bundle itself is under test.
//

import Foundation
import RealityKit
import Testing
@testable import Cheese_Heist

@MainActor
struct BundledAssetTests {

    /// `Cheese.usdc` is a Blender scene export: a camera, two sphere lights, a dome
    /// light and a cheese authored 1.19m tall. It has to come out at table scale.
    @Test("the cheese loads and normalises to table scale")
    func cheeseIsTableScale() {
        guard let cheese = CheeseEntity.make() else {
            Issue.record("Cheese.usdc did not load out of the bundle")
            return
        }

        guard let bounds = ModelBounds.measure(cheese) else {
            Issue.record("the loaded cheese has no mesh in it")
            return
        }

        let longest = max(bounds.extents.x, max(bounds.extents.y, bounds.extents.z))
        #expect(abs(longest - CheeseEntity.longestEdge) < 0.001)

        // Centred on its own origin, so a caller writing `.position` puts the cheese
        // where it meant to rather than the cheese's authoring datum.
        #expect(simd_length(bounds.center) < 0.001)
    }

    /// Each gear has to measure LEGO's module-1 tip diameter, because the whole lesson
    /// is that the two gears are different sizes.
    @Test(arguments: GearType.allCases)
    func gearsMeasureTheirLegoDiameter(_ type: GearType) {
        guard let gear = GearMeshFactory.entity(for: type) else {
            Issue.record("\(type.modelName) did not load out of the bundle")
            return
        }

        guard let bounds = ModelBounds.measure(gear) else {
            Issue.record("\(type.modelName) has no mesh in it")
            return
        }

        // The disc lies in XY with its axle along Z, so the diameter is the wider of
        // the two planar extents and Z is the thickness.
        let diameter = max(bounds.extents.x, bounds.extents.y)
        #expect(abs(diameter - GearGeometry.tipDiameter(teeth: type.teeth)) < 0.001)
        #expect(bounds.extents.z < diameter)
    }

    /// The mouse is a texture, not a model, and a missing one makes `MouseSpriteEntity`
    /// fail its initialiser — which reads on device as the mouse simply not being there.
    @Test(arguments: MouseSprite.allCases)
    func mouseSpritesAreInTheAssetCatalogue(_ sprite: MouseSprite) {
        #expect(
            (try? TextureResource.load(named: sprite.assetName)) != nil,
            "\(sprite.assetName) is missing from Assets.xcassets"
        )
    }

    @Test("the mouse sprite builds at the height the perch was computed for")
    func mouseSpriteBuilds() {
        guard let mouse = MouseSpriteEntity() else {
            Issue.record("the mouse sprite did not build")
            return
        }

        #expect(mouse.pose == .happy)

        let bounds = ModelBounds.measure(mouse.entity)
        #expect(abs((bounds?.extents.y ?? 0) - MouseSpriteEntity.height) < 0.001)
    }
}
