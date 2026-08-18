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
import simd
import UIKit
@testable import Cheese_Heist

@MainActor
struct BundledAssetTests {

    /// `Cheese.usdc` is a Blender scene export: a camera, two sphere lights, a dome
    /// light and a cheese authored 1.19m tall. It has to come out at table scale.
    @Test("the cheese loads and normalises to table scale")
    func cheeseIsTableScale() {
        guard let cheese = CheeseEntity.make()?.holder else {
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

    /// The wedge must not be pointing its LENGTH at the camera. Authored, it was: 1.19
    /// of 1.19/0.88/0.48 ran straight down the view axis, which is why the cheese read
    /// as a yellow lozenge with no triangle in it.
    ///
    /// A weak check by design, and it is the bounding box that makes it weak — the box
    /// around a wedge turned three ways is close to cubical, so it can tell "end-on"
    /// from "not end-on" and nothing finer. The pose itself is asserted properly, as
    /// directions rather than extents, in `CheeseOrientationTests`; this one is here to
    /// tie that quaternion to the actual mesh in the actual bundle.
    @Test("the cheese is not seen end-on down its own length")
    func cheeseIsNotEndOn() {
        guard let cheese = CheeseEntity.make()?.holder,
              let bounds = ModelBounds.measure(cheese) else {
            Issue.record("the cheese did not load")
            return
        }

        #expect(bounds.extents.z < bounds.extents.x)
    }

    /// The cheese rests ON the table. Half its own height is the offset that puts it
    /// there, and it has to be a real number or the wedge sinks into the tabletop.
    @Test("the cheese knows how far to sit above its own origin")
    func cheeseRestingLiftIsHalfItsHeight() {
        guard let cheese = CheeseEntity.make()?.holder,
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

    /// The 2D poses are dialogue and result-screen portraits, and a missing one draws a
    /// blank bubble with no failure path — see `MouseSprite`.
    @Test(arguments: MouseSprite.allCases)
    func mouseSpritesAreInTheAssetCatalogue(_ sprite: MouseSprite) {
        #expect(
            (try? TextureResource.load(named: sprite.assetName)) != nil,
            "\(sprite.assetName) is missing from Assets.xcassets"
        )
    }

    /// The success screen's three stars.
    ///
    /// `Image(_:)` has NO failure path — a name that does not resolve draws an empty
    /// view and logs once, so `Image("cheese-star")` against an imageset called
    /// `cheese_star` cost the celebration its stars and reported nothing. A string
    /// literal naming a resource is only ever verified by loading it.
    @Test("the cheese star is in the asset catalogue under the name the view asks for")
    func cheeseStarResolves() {
        #expect(
            UIImage(named: CheeseStarRow.assetName) != nil,
            "\(CheeseStarRow.assetName) is missing from Assets.xcassets"
        )
    }

    @Test("the empty cheese star is in the asset catalogue under cheese_empty")
    func cheeseEmptyResolves() {
        #expect(
            UIImage(named: "cheese_empty") != nil,
            "cheese_empty is missing from Assets.xcassets"
        )
    }

    /// `Mouse.usdz` scales to the height the perch is computed for, and comes out
    /// grounded — a caller's `.position` lands on its feet, not its skeleton's origin.
    ///
    /// Measured on the SKELETON, not `ModelBounds.measure` — the mouse is skinned, and
    /// that reads the bind pose rather than the rest pose the renderer draws. See
    /// `MouseModelEntity`'s header for the export that got this wrong.
    @Test("the mouse model builds grounded at the height the perch was computed for")
    func mouseModelBuilds() {
        guard let mouse = MouseModelEntity() else {
            Issue.record("Mouse.usdz did not build")
            return
        }

        guard let bounds = ModelBounds.measureSkeleton(mouse.entity) else {
            Issue.record("the mouse model has no skeleton in it")
            return
        }

        #expect(abs(bounds.extents.y - MouseModelEntity.height) < 0.002)
        #expect(abs(bounds.min.y) < 0.001)
    }

    /// The export's rig carries real joint motion for both halves of the idle — the
    /// breathe AND the blink, the latter on `Eyelid_L`/`Eyelid_R` joints rather than the
    /// blend shapes RealityKit never imported. `init` starts it and nothing stops it, so
    /// this flag being false is a mouse that stands frozen for the whole level.
    @Test("the mouse model starts its idle loop on build")
    func mouseModelAnimates() {
        guard let mouse = MouseModelEntity() else {
            Issue.record("Mouse.usdz did not build")
            return
        }
        #expect(mouse.canAnimate)
    }

    /// The mouse model faces front-right toward the gear and the viewer (+X, +Z).
    @Test("the mouse model faces toward the gear and viewer")
    func mouseFacesViewer() {
        guard let mouse = MouseModelEntity(),
              let nose = jointPosition(suffix: "Nose", in: mouse.entity),
              let tail = jointPosition(suffix: "Tail4", in: mouse.entity) else {
            Issue.record("Mouse.usdz did not yield a nose and a tail")
            return
        }

        // Facing right toward the gear (+X) and forward toward the viewer (+Z).
        #expect(nose.x > tail.x, "the mouse should face +X toward the gear")
        #expect(nose.z > tail.z, "the mouse should face +Z toward the camera")
    }

    /// One named joint's rest-pose position in `root`'s own space — the same walk
    /// `ModelBounds.measureSkeleton` does, stopping at a joint instead of a box.
    private func jointPosition(suffix: String, in root: Entity) -> simd_float3? {
        var queue = [(entity: root, parent: matrix_identity_float4x4)]
        while let head = queue.first {
            queue.removeFirst()
            let world = head.parent * head.entity.transform.matrix

            if let mesh = head.entity.components[ModelComponent.self]?.mesh,
               let skeleton = mesh.contents.skeletons.first(where: { _ in true }) {
                let joints = Array(skeleton.joints)
                var poses = [simd_float4x4](repeating: matrix_identity_float4x4, count: joints.count)
                for (index, joint) in joints.enumerated() {
                    let local = joint.restPoseTransform.matrix
                    poses[index] = joint.parentIndex.map { poses[$0] * local } ?? local
                }
                guard let index = joints.firstIndex(where: { $0.name.hasSuffix(suffix) }) else {
                    return nil
                }
                let point = world * poses[index].columns.3
                return simd_float3(point.x, point.y, point.z)
            }
            queue.append(contentsOf: head.entity.children.map { ($0, world) })
        }
        return nil
    }

    // MARK: - Cutscene assets

    /// The cheese half of the composite lands at table scale, on the plane.
    ///
    /// It is a rigid mesh, so `ModelBounds` is honest about it — which is the whole
    /// reason the stage's single scale is measured off the CHEESE and not off the cat.
    @Test("the cutscene cheese loads at cheeseSize and rests on the plane")
    func cutsceneCheeseIsTableScale() {
        guard let stage = CutsceneStageEntity.make(),
              let bounds = ModelBounds.measure(stage.cheese) else {
            Issue.record("meong.usdz did not yield the stage from the bundle")
            return
        }

        let longest = max(bounds.extents.x, max(bounds.extents.y, bounds.extents.z))
        #expect(abs(longest - CutsceneTuning.cheeseSize) < 0.001)
        #expect(abs(bounds.min.y) < 0.001)
    }

    /// The cat comes out cat-shaped, cat-sized and NEAR THE ANCHOR.
    ///
    /// Every number here is one the cutscene shipped wrong, and none of them is reachable
    /// from a pure test — they only exist once the real rig is loaded from the real
    /// bundle. The cat is skinned, so `ModelBounds` reads its bind-pose box (extents
    /// 1.795 × 5.765 × 3.706, parked at (0, 113.7, 190.0)) rather than the rest pose the
    /// renderer draws. Normalising against that box divided by the wrong size AND shoved
    /// the cat about seven metres from the anchor, which on device read as "the cat is
    /// tiny like a mosquito". So this measures the SKELETON, which is what renders.
    @Test("the cat is cat-shaped, cat-sized, grounded, and at the anchor")
    func catIsCatShapedAndAtTheAnchor() {
        guard let stage = CutsceneStageEntity.make() else {
            Issue.record("the stage did not load")
            return
        }
        guard let box = ModelBounds.measureSkeleton(stage.catHolder) else {
            Issue.record("the cat has no skeleton in it")
            return
        }

        // Sized by the RCP-authored cat:cheese ratio, not by a target of its own. A wide
        // band: joints sit inside the silhouette, so paws, ears and tail all fall outside
        // this box. It is here to separate "a cat" from "a mosquito" and "a sofa".
        let longest = max(box.extents.x, max(box.extents.y, box.extents.z))
        #expect(longest > CutsceneTuning.cheeseSize)
        #expect(longest < CutsceneTuning.cheeseSize * 3)

        // Upright: a cat is longer than it is tall and taller than it is wide. Dropping
        // the stage's up-axis correction swaps the first two and stands it on its tail.
        #expect(box.extents.z > box.extents.y)
        #expect(box.extents.y > box.extents.x)

        // Feet on the plane, and — the mosquito bug — actually AT the anchor rather than
        // across the room. The orbit has not run yet, so the holder is still at the
        // origin and the whole cat has to be within arm's reach of it.
        #expect(abs(box.min.y) < 0.01)
        #expect(simd_length(box.center) < 0.5)
    }

    /// The walk clip has to be a finite take.
    ///
    /// Read from `tooncat`, `meong.usdz` exposes three animations all named "default
    /// subtree animation": two 0.833 s bakes and one of duration `inf` — Reality Composer
    /// Pro's AnimationLibrary entry with `looping = 1`. Nothing about the name separates
    /// them, so duration is the only discriminator, and "the longest take" picks the one
    /// that never ends. Which entity the search lands on decides whether the hazard is
    /// even in scope, so this asserts the outcome rather than the mechanism.
    @Test("the cat's walk clip is a finite take, not the infinite library entry")
    func catWalkClipIsFinite() {
        guard let stage = CutsceneStageEntity.make() else {
            Issue.record("the stage did not load")
            return
        }

        guard let take = CutsceneStageEntity.walkTake(from: stage.catAnimated) else {
            Issue.record("the cat exposed no finite take")
            return
        }
        #expect(take.definition.duration.isFinite)
        #expect(stage.catWalk != nil)
    }

    @Test("blueprint_scroll resolves in the asset catalogue")
    func blueprintScrollResolves() {
        #expect(
            UIImage(named: "blueprint_scroll") != nil,
            "blueprint_scroll is missing from Assets.xcassets"
        )
    }

    @Test("position_guideline resolves in the asset catalogue")
    func positionGuidelineResolves() {
        #expect(
            UIImage(named: "position_guideline") != nil,
            "position_guideline is missing from Assets.xcassets"
        )
    }

    @Test("blueprint_glow resolves in the asset catalogue")
    func blueprintGlowResolves() {
        #expect(
            UIImage(named: "blueprint_glow") != nil,
            "blueprint_glow is missing from Assets.xcassets"
        )
    }

    // MARK: - Splash & Blueprint assets

    @Test("splash and blueprint imagesets resolve in the asset catalogue", arguments: [
        "bg_kitchen", "logo_title", "mouse_hole", "splash_mouse",
        "gear_big", "gear_small", "blueprint_bg"
    ])
    func splashAndBlueprintImagesResolve(_ name: String) {
        #expect(UIImage(named: name) != nil, "\(name) is missing from Assets.xcassets")
    }

    @Test("blueprint step GIFs are bundled", arguments: [
        "blueprint_step_1", "blueprint_step_2", "blueprint_step_3"
    ])
    func blueprintStepGIFsAreBundled(_ name: String) {
        #expect(
            Bundle.main.url(forResource: name, withExtension: "gif") != nil,
            "\(name).gif is missing from Resources/Media/BlueprintSteps/"
        )
    }

    @Test("each blueprint step points at a distinct GIF")
    func blueprintStepsUseDistinctGIFs() {
        let gifNames = BlueprintScript.steps.map(\.gifName)
        #expect(Set(gifNames).count == gifNames.count, "two blueprint steps share a GIF")
    }
}

