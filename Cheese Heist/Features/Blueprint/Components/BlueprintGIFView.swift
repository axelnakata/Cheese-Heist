//
//  BlueprintGIFView.swift
//  Cheese Heist
//
//  Plays a bundled GIF via a transparent, non-scrolling `WKWebView` — ported from the
//  reference build (`cheezy-dev-nay`'s `GIFImageView`). `updateUIView` reloads the HTML
//  on every `gifName` change; a plain `UIImageView.animatedImage` assigned once in
//  `makeUIView` misses exactly this, which is why every blueprint step showed the first
//  step's clip.
//

import SwiftUI
import WebKit

struct BlueprintGIFView: UIViewRepresentable {

    let gifName: String

        func makeUIView(context: Context) -> UIImageView {
            let imageView = UIImageView()
            imageView.contentMode = .scaleAspectFit
            imageView.clipsToBounds = true
            return imageView
        }

        func updateUIView(_ uiView: UIImageView, context: Context) {
            guard let url = Bundle.main.url(forResource: gifName, withExtension: "gif"),
                  let data = try? Data(contentsOf: url),
                  let source = CGImageSourceCreateWithData(data as CFData, nil) else {
                return
            }

            var images: [UIImage] = []
            var totalDuration: Double = 0
            let count = CGImageSourceGetCount(source)

            for i in 0..<count {
                if let cgImage = CGImageSourceCreateImageAtIndex(source, i, nil) {
                    images.append(UIImage(cgImage: cgImage))

                    // Ambil durasi per frame
                    let frameProperties = CGImageSourceCopyPropertiesAtIndex(source, i, nil) as? [String: Any]
                    let gifProperties = frameProperties?[kCGImagePropertyGIFDictionary as String] as? [String: Any]
                    let frameDuration = gifProperties?[kCGImagePropertyGIFUnclampedDelayTime as String] as? Double
                        ?? gifProperties?[kCGImagePropertyGIFDelayTime as String] as? Double
                        ?? 0.1

                    totalDuration += frameDuration
                }
            }
            
            uiView.animationImages = images
            uiView.animationDuration = totalDuration
            uiView.animationRepeatCount = 0 
            uiView.startAnimating()
        }
    }

#Preview {
    BlueprintGIFView(gifName: "blueprint_step_1")
        .frame(width: 400, height: 300)
        .previewBackdrop(.parchment)
}
