//
//  GIFPlayerView.swift
//  Cheese Heist
//
//  A looping GIF, bundled as a resource and decoded by `GIFDecoder`. `UIImageView`
//  already loops `.animatedImage` content on its own, so this wrapper has nothing to
//  drive each frame — it hands the decoded image to UIKit once and steps aside.
//

import SwiftUI
import UIKit

struct GIFPlayerView: UIViewRepresentable {

    /// The resource name, without the `.gif` extension.
    let resourceName: String

    func makeUIView(context: Context) -> UIImageView {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.image = GIFDecoder.animatedImage(resource: resourceName)
        imageView.startAnimating()
        return imageView
    }

    func updateUIView(_ uiView: UIImageView, context: Context) {}
}

#Preview {
    GIFPlayerView(resourceName: "blueprint_step_1")
        .frame(width: 400, height: 300)
        .previewBackdrop(.parchment)
}
