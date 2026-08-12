// RootView.swift — Cheese Heist
// PRD §9 — switch on route → feature view.

import SwiftUI

struct RootView: View {

    let services: AppServices

    var body: some View {
        Group {
            switch services.router.route {
            case .cutscene:
                CutsceneView(services: services)
            case .level1:
                Level1View(services: services)
            case .unsupportedDevice:
                UnsupportedDeviceView()
            default:
                // Placeholder for unimplemented routes.
                DesignSystemGalleryView()
            }
        }
        .providesLayoutScale()
        .onAppear { services.boot() }
    }
}
