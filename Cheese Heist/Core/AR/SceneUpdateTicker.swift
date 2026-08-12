// SceneUpdateTicker.swift — Cheese Heist
// Single SceneEvents.Update subscription, fans out in fixed order.

import RealityKit
import Combine

final class SceneUpdateTicker {

    typealias Handler = (Float) -> Void

    private var subscription: (any Cancellable)?
    private var handlers: [Handler] = []

    func start(in arView: ARView) {
        subscription = arView.scene.subscribe(to: SceneEvents.Update.self) { [weak self] event in
            MainActor.assumeIsolated {
                self?.tick(deltaTime: Float(event.deltaTime))
            }
        }
    }

    func stop() {
        subscription = nil
    }

    func register(_ handler: @escaping Handler) {
        handlers.append(handler)
    }

    private func tick(deltaTime: Float) {
        let dt = min(max(deltaTime, 0), 0.1)
        for handler in handlers {
            handler(dt)
        }
    }
}
