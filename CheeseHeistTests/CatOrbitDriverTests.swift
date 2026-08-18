//
//  CatOrbitDriverTests.swift
//  CheeseHeistTests
//
//  The driver's placement maths, on a hand-built stage rather than the real asset.
//
//  `CutsceneStage` is four plain entities, so none of this needs `meong.usdz`, a device
//  or a skeleton — the asset itself is covered by `BundledAssetTests`. What is covered
//  here is what Level 2 added: a per-instance radius, and a `centre` the owner moves
//  every frame to keep the cat's feet on a table whose height is still being measured.
//

import Testing
import RealityKit
import simd
@testable import Cheese_Heist

@MainActor
private func makeStage() -> CutsceneStage {
    CutsceneStage(cheese: Entity(), catHolder: Entity(), catAnimated: Entity(), catWalk: nil)
}

@MainActor
@Suite("CatOrbitDriver")
struct CatOrbitDriverTests {

    @Test("Starts on the circle at its own radius, not the cutscene's")
    func startsAtGivenRadius() {
        let stage = makeStage()
        _ = CatOrbitDriver(cat: stage, radius: 0.2, speed: 0.1)

        // Angle 0 is (radius, 0, 0).
        #expect(abs(stage.catHolder.position.x - 0.2) < 0.0001)
        #expect(abs(stage.catHolder.position.y) < 0.0001)
        #expect(abs(stage.catHolder.position.z) < 0.0001)
    }

    @Test("The centre offsets the whole circle, so the cat can walk on the table")
    func centreOffsetsTheCircle() {
        let stage = makeStage()
        let driver = CatOrbitDriver(cat: stage, radius: 0.2, speed: 0.1)

        driver.centre = simd_float3(0, -0.09, 0)
        driver.advance(deltaTime: 1.0 / 60.0)

        #expect(abs(stage.catHolder.position.y + 0.09) < 0.0001)
        // Still on the circle, one frame in, measured in the plane of the walk.
        let offset = stage.catHolder.position - driver.centre
        #expect(abs(simd_length(simd_float3(offset.x, 0, offset.z)) - 0.2) < 0.0001)
    }

    @Test("Walks the whole way round without leaving the circle")
    func staysOnTheCircle() {
        let stage = makeStage()
        let driver = CatOrbitDriver(cat: stage, radius: 0.2, speed: 0.1)
        driver.centre = simd_float3(0, -0.09, 0)

        // 20 seconds at 60Hz — more than one lap at this radius and speed, so it covers
        // the angle wrap and several of the orbit model's pause/resume toggles.
        var sawSomewhereElse = false
        for _ in 0..<1200 {
            driver.advance(deltaTime: 1.0 / 60.0)
            let offset = stage.catHolder.position - driver.centre
            #expect(abs(simd_length(simd_float3(offset.x, 0, offset.z)) - 0.2) < 0.0001)
            #expect(abs(offset.y) < 0.0001)
            if abs(stage.catHolder.position.x - 0.2) > 0.01 { sawSomewhereElse = true }
        }
        // A cat that never moved would satisfy every assertion above.
        #expect(sawSomewhereElse)
    }
}
