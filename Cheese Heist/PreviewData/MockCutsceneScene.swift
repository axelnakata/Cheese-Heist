//
//  MockCutsceneScene.swift
//  Cheese Heist
//
//  A `CutsceneSceneProviding` that owns no AR. Counterpart to `MockCraneScene` — lets
//  every cutscene layer render in Previews on a Mac with no device attached.
//

@MainActor
final class MockCutsceneScene: CutsceneSceneProviding {

    var isSurfaceValid: Bool = true
    var validity: SurfaceValidity = .valid
    private(set) var isPlaced = false
    private(set) var isRingVisible = true
    private(set) var isTornDown = false

    func placeScene() { isPlaced = true }
    func setRingVisible(_ visible: Bool) { isRingVisible = visible }
    func teardown() { isTornDown = true }
}
