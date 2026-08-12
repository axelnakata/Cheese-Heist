// SceneUpdateTicker.swift — Cheese Heist
// Single SceneEvents.Update subscription, fans out in fixed order.
//
// `register` returns a UUID, and `unregister` removes the handler — so the cutscene's
// per-frame handler stops firing during Level 1. Additive; Level 1's existing call
// site is unaffected.

import RealityKit
import Combine
import Foundation

final class SceneUpdateTicker {

    typealias Handler = (Float) -> Void

    private var subscription: (any Cancellable)?
    private var handlers: [(id: UUID, handler: Handler)] = []

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

    @discardableResult
    func register(_ handler: @escaping Handler) -> UUID {
        let id = UUID()
        handlers.append((id: id, handler: handler))
        return id
    }

    func unregister(_ id: UUID) {
        handlers.removeAll { $0.id == id }
    }

    private func tick(deltaTime: Float) {
        let dt = min(max(deltaTime, 0), 0.1)
        for entry in handlers {
            entry.handler(dt)
        }
    }
}
