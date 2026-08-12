//
//  CutsceneSceneProviding.swift
//  Cheese Heist
//
//  The cutscene ViewModel's view onto the AR scene, same idea as `CraneSceneProviding`.
//  Everything here is a point, a bool, or a value type — the ViewModel never imports
//  ARKit or RealityKit.
//

@MainActor
protocol CutsceneSceneProviding: AnyObject {
    var isSurfaceValid: Bool { get }
    var validity: SurfaceValidity { get }

    func placeScene()
    func setRingVisible(_ visible: Bool)
    func teardown()
}
