//
//  CheeseHeistApp.swift
//  Cheese Heist
//
//  Created by Axel Nino Nakata on 10/08/26.
//

import SwiftUI

@main
struct CheeseHeistApp: App {

    @State private var services = AppServices()

    init() {
        AppFontResolver.verifyRegisteredFonts()
    }

    var body: some Scene {
        WindowGroup {
            RootView(services: services)
        }
    }
}
