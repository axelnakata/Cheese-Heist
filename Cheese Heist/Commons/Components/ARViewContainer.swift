// ARViewContainer.swift — Cheese Heist
// UIViewRepresentable wrapper for RealityKit's ARView.
// Port from gear-poc. Used by all AR-based levels.

import SwiftUI
import RealityKit
import ARKit

struct ARViewContainer: UIViewRepresentable {

    let arSessionManager: ARSessionManager

    func makeUIView(context: Context) -> ARView {
        let arView = arSessionManager.setupARView()
        arView.contentMode = .scaleAspectFill
        return arView
    }

    func updateUIView(_ uiView: ARView, context: Context) {}
}
