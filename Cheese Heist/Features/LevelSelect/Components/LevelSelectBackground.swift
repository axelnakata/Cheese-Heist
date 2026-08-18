//
//  LevelSelectBackground.swift
//  Cheese Heist
//
//  Figma 1021:153 / 1021:219 — the toy-room floor photo, full-bleed, with the frame's
//  own 20% black scrim so the path and buttons read on top of it.
//

import SwiftUI

struct LevelSelectBackground: View {

    var body: some View {
        Image("level_select_bg")
            .resizable()
            .aspectRatio(contentMode: .fill)
            .overlay(Color.black.opacity(0.2))
            .ignoresSafeArea()
    }
}

#Preview {
    LevelSelectBackground()
}
