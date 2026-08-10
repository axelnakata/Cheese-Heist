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

        // A WIDE BAND, not an equality. The cheese is handed back already turned to face
        // the camera, and the axis-aligned box around a rotated wedge is legitimately
        // bigger than the wedge's own longest edge — by up to sqrt(3) in the worst case,
        // and by 1.25 at the angle actually used. Pinning it tighter would mean this
        // test fails every time the presentation angle is nudged by a degree, which is
        // not what it is here to catch: the failures it guards against are a 1.19m wall
        // of cheese and a 4mm crumb, both orders of magnitude outside this.
        let longest = max(bounds.extents.x, max(bounds.extents.y, bounds.extents.z))
        #expect(longest > CheeseEntity.longestEdge * 0.8)
        #expect(longest < CheeseEntity.longestEdge * 1.8)

        // Centred on its own origin, so a caller writing `.position` puts the cheese
        // where it meant to rather than the cheese's authoring datum.
        #expect(simd_length(bounds.center) < 0.001)
    }

    /// The wedge has to present its TRIANGLE to the camera, not its length.
    ///
    /// `BillboardSystem` turns local +Z to the camera, so "we are looking at the flat
    /// face" is precisely "the local Z extent is the smallest of the three" — the
    /// thinnest axis is the one pointing at us. Authored, it was the LARGEST (1.19 of
    /// 1.19/0.88/0.48), which is why the cheese read as a lozenge.
    @Test("the cheese shows its triangular face, not its point")
    func cheeseFacesTheCameraFlatOn() {
        guard let cheese = CheeseEntity.make(),
              let bounds = ModelBounds.measure(cheese) else {
            Issue.record("the cheese did not load")
            return
        }

        #expect(bounds.extents.z < bounds.extents.x)
        #expect(bounds.extents.z < bounds.extents.y)
    }

    /// The cheese rests ON the table. Half its own height is the offset that puts it
    /// there, and it has to be a real number or the wedge sinks into the tabletop.
    @Test("the cheese knows how far to sit above its own origin")
    func cheeseRestingLiftIsHalfItsHeight() {
        guard let cheese = CheeseEntity.make(),
              let bounds = ModelBounds.measure(cheese) else {
            Issue.record("the cheese did not load")
            return
        }

        let lift = CheeseEntity.restingLift(of: cheese)
        #expect(lift > 0)
        #expect(abs(lift - bounds.extents.y / 2) < 0.0001)
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
