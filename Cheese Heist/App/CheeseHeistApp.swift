//
//  CheeseHeistApp.swift
//  Cheese Heist
//
//  Created by Axel Nino Nakata on 10/08/26.
//

import SwiftUI

@main
struct CheeseHeistApp: App {

    init() {
        AppFontResolver.verifyRegisteredFonts()
    }

    var body: some Scene {
        WindowGroup {
            // TODO: WS-2 replaces this with RootView(), driven by AppRouter.
            // The capability gate (PRD §5.1) runs before RootView renders.
            DesignSystemGalleryView()
                .providesLayoutScale()
        }
    }
}
