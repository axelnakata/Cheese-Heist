//
//  GIFDecoder.swift
//  Cheese Heist
//
//  Decodes a bundled GIF into a `UIImage.animatedImage`, via ImageIO rather than
//  WebKit — no JS bridge, no WKWebView lifecycle to manage for a decorative loop.
//

import ImageIO
import UIKit

enum GIFDecoder {

    private static let defaultFrameDuration = 0.1

    /// `nil` if the resource is missing or has no readable frames.
    static func animatedImage(resource name: String) -> UIImage? {
        guard let url = Bundle.main.url(forResource: name, withExtension: "gif"),
              let data = try? Data(contentsOf: url),
              let source = CGImageSourceCreateWithData(data as CFData, nil)
        else { return nil }

        let frameCount = CGImageSourceGetCount(source)
        var frames: [UIImage] = []
        var totalDuration: Double = 0

        for index in 0..<frameCount {
            guard let cgImage = CGImageSourceCreateImageAtIndex(source, index, nil) else { continue }
            totalDuration += frameDuration(source: source, index: index)
            frames.append(UIImage(cgImage: cgImage))
        }

        guard !frames.isEmpty else { return nil }
        return UIImage.animatedImage(with: frames, duration: totalDuration)
    }

    private static func frameDuration(source: CGImageSource, index: Int) -> Double {
        guard let properties = CGImageSourceCopyPropertiesAtIndex(source, index, nil) as? [CFString: Any],
              let gifProperties = properties[kCGImagePropertyGIFDictionary] as? [CFString: Any]
        else { return defaultFrameDuration }

        let unclamped = gifProperties[kCGImagePropertyGIFUnclampedDelayTime] as? Double
        let clamped = gifProperties[kCGImagePropertyGIFDelayTime] as? Double
        let duration = unclamped ?? clamped ?? defaultFrameDuration
        return duration > 0 ? duration : defaultFrameDuration
    }
}
