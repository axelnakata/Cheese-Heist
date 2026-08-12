//
//  ModelBoundsTests.swift
//  CheeseHeistTests
//
//  The measurement that decides how big every loaded prop is.
//
//  It is worth its own tests because it is fed straight into a division, so an error
//  here does not stay proportional to itself: measuring a 1.2m cheese as 8.5m (the span
//  from the cheese to the Blender lamp `Cheese.usdc` ships with) does not make the
//  cheese slightly small, it makes it a 4mm crumb.
//

import Foundation
import RealityKit
import Testing
import simd
@testable import Cheese_Heist

@MainActor
struct ModelBoundsTests {

    /// A 1x1x1 box, so every expected number below is the transform and nothing else.
    private static func unitCube() -> ModelEntity {
        ModelEntity(mesh: .generateBox(size: 1), materials: [])
    }

    @Test("a lone mesh measures its own size")
    func singleMesh() {
        let bounds = ModelBounds.measure(Self.unitCube())

        #expect(bounds != nil)
        #expect(abs((bounds?.extents.x ?? 0) - 1) < 0.001)
        #expect(abs((bounds?.extents.y ?? 0) - 1) < 0.001)
    }

    /// The whole reason this type exists. A light metres away from the prop must not
    /// widen the box — `visualBounds` is the version that could.
    @Test("lights and cameras do not widen the box")
    func nonRenderableChildrenAreIgnored() {
        let root = Entity()
        root.addChild(Self.unitCube())

        let lamp = Entity()
        lamp.components.set(PointLightComponent(intensity: 1000))
        lamp.position = simd_float3(8, 8, 8)
        root.addChild(lamp)

        let camera = Entity()
        camera.components.set(PerspectiveCameraComponent())
        camera.position = simd_float3(-6, 0, 6)
        root.addChild(camera)

        let bounds = ModelBounds.measure(root)

        #expect(abs((bounds?.extents.x ?? 0) - 1) < 0.001)
        #expect(abs((bounds?.extents.z ?? 0) - 1) < 0.001)
    }

    /// `Cheese.usdc` reaches its mesh through eight nested Xforms carrying scales from
    /// 0.01 to 162, so the chain has to compose rather than only the leaf being read.
    @Test("nested transforms compose")
    func scaleAccumulatesDownTheHierarchy() {
        let outer = Entity()
        outer.transform = Transform(scale: simd_float3(repeating: 0.5))

        let inner = Entity()
        inner.transform = Transform(scale: simd_float3(repeating: 4))
        inner.addChild(Self.unitCube())
        outer.addChild(inner)

        let bounds = ModelBounds.measure(outer)

        #expect(abs((bounds?.extents.x ?? 0) - 2) < 0.001)
    }

    /// A rotated box is measured by its corners. Transforming min and max alone would
    /// return the same 1x1 box here, and every import carries a Z-up correction.
    @Test("a rotated box is measured by its corners")
    func rotationWidensTheBox() {
        let root = Entity()
        root.transform = Transform(
            rotation: simd_quatf(angle: .pi / 4, axis: simd_float3(0, 0, 1))
        )
        root.addChild(Self.unitCube())

        let bounds = ModelBounds.measure(root)

        #expect(abs((bounds?.extents.x ?? 0) - Float(2).squareRoot()) < 0.001)
    }

    /// An import that produced no mesh has no size, and the callers show no prop rather
    /// than dividing by whatever a default box would have been.
    @Test("a hierarchy with no mesh has no bounds")
    func meshlessHierarchyIsNil() {
        let root = Entity()
        root.addChild(Entity())

        #expect(ModelBounds.measure(root) == nil)
    }

    /// End to end, on the numbers the real asset has: the normaliser must bring a
    /// metre-scale export down to the size the scene asked for.
    @Test("normalising a metre-scale prop lands on the target edge")
    func normaliserRescalesAMetreScaleProp() {
        let authored = Entity()
        authored.transform = Transform(scale: simd_float3(repeating: 1.19))
        authored.addChild(Self.unitCube())

        guard let normalised = GearMeshNormaliser.normalisedProp(
            authored, targetLongestEdge: CheeseEntity.longestEdge
        ) else {
            Issue.record("a 1.19m cube has volume")
            return
        }

        let bounds = ModelBounds.measure(normalised)
        #expect(abs((bounds?.extents.x ?? 0) - CheeseEntity.longestEdge) < 0.0005)
    }

    /// The container the normaliser hands back is the caller's to position, and writing
    /// to it must not disturb the correction underneath — which is what
    /// `cheese.position = …` used to do.
    @Test("positioning a normalised prop does not undo its recentring")
    func positioningKeepsTheCorrection() {
        let authored = Entity()
        // Authored a long way off its own origin, like the cheese is.
        let cube = Self.unitCube()
        cube.position = simd_float3(0, 0, 3)
        authored.addChild(cube)

        guard let normalised = GearMeshNormaliser.normalisedProp(
            authored, targetLongestEdge: CheeseEntity.longestEdge
        ) else {
            Issue.record("a unit cube has volume")
            return
        }

        normalised.position = simd_float3(0, -0.09, 0)
        let bounds = ModelBounds.measure(normalised)

        // Centred on where it was put, not 3 units away from it.
        #expect(abs((bounds?.center.z ?? 99)) < 0.001)
        #expect(abs((bounds?.center.y ?? 0) + 0.09) < 0.001)
    }
}
