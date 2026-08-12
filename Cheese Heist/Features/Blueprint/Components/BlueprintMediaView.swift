//
//  BlueprintMediaView.swift
//  Cheese Heist
//
//  The illustrative media on the left of a blueprint step (PRD §11.4). `.video` renders
//  nothing yet — it exists so a future build-along clip is a `BlueprintScript` edit, not
//  a `BlueprintMediaView` one.
//

import SwiftUI

struct BlueprintMediaView: View {

    let media: BlueprintMedia

    var body: some View {
        content
            .aspectRatio(contentMode: .fit)
    }

    @ViewBuilder
    private var content: some View {
        switch media {
        case .image(let name):
            Image(name).resizable().scaledToFit()
        case .gif(let name):
            GIFPlayerView(resourceName: name)
        case .video:
            Color.clear
        }
    }
}

#Preview {
    BlueprintMediaView(media: .gif("blueprint_step_2"))
        .frame(width: 340, height: 260)
        .previewBackdrop(.cameraFeed)
}
