//
//  DepthPixelSampler.swift
//  Cheese Heist
//
//  Reads every confident depth value inside a detector box. The only type in the
//  depth pipeline that touches raw pixel buffers; everything downstream of it works
//  on a plain `[Float]`.
//

import ARKit
import CoreGraphics
import Foundation

/// An inclusive rectangle of depth-buffer pixel indices.
struct PixelBounds: Equatable, Sendable {
    let minX: Int
    let maxX: Int
    let minY: Int
    let maxY: Int
}

enum DepthPixelSampler {

    /// Fraction of the detector's box kept, centred.
    ///
    /// The discarded border is where a depth pixel covers both gear and background and
    /// reports the average of the two — a value describing no surface that exists. The
    /// detector's boxes are also not perfectly tight, so some of that border is simply
    /// not gear.
    static let boxKeepFraction: CGFloat = 0.7

    /// Readings must be at least this confident — `.medium`. LiDAR returns a depth for
    /// almost every pixel, but a good fraction are guesses: around edges, on dark or
    /// shiny surfaces, and anywhere the return was weak.
    static let minimumConfidence: UInt8 = 1

    /// Sanity bounds — a child holding an iPad.
    static let minimumDepth: Float = 0.08
    static let maximumDepth: Float = 3.0

    /// Every confident depth reading inside the shrunk box.
    static func confidentDepths(in box: CGRect, captured: CapturedFrameData) -> [Float] {
        let depthMap = captured.depthMap
        let width = CVPixelBufferGetWidth(depthMap)
        let height = CVPixelBufferGetHeight(depthMap)
        guard width > 0, height > 0,
              let bounds = pixelBounds(
                  box: box, depthWidth: width, depthHeight: height,
                  imageSize: captured.imagePixelSize
              ) else { return [] }

        CVPixelBufferLockBaseAddress(depthMap, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(depthMap, .readOnly) }
        guard let depthBase = CVPixelBufferGetBaseAddress(depthMap) else { return [] }

        // Confidence is one byte per pixel at the same resolution. Anything that is not
        // exactly that shape is ignored rather than indexed into.
        let confidenceMap = captured.confidenceMap.flatMap {
            CVPixelBufferGetWidth($0) == width && CVPixelBufferGetHeight($0) == height ? $0 : nil
        }
        if let confidenceMap { CVPixelBufferLockBaseAddress(confidenceMap, .readOnly) }
        defer {
            if let confidenceMap { CVPixelBufferUnlockBaseAddress(confidenceMap, .readOnly) }
        }

        return collect(
            depths: depthBase.assumingMemoryBound(to: Float32.self),
            depthStride: CVPixelBufferGetBytesPerRow(depthMap) / MemoryLayout<Float32>.size,
            confidence: confidenceMap.flatMap(CVPixelBufferGetBaseAddress)?
                .assumingMemoryBound(to: UInt8.self),
            confidenceStride: confidenceMap.map(CVPixelBufferGetBytesPerRow) ?? 0,
            bounds: bounds
        )
    }

    /// Walks the locked buffers and keeps the readings that are both confident and
    /// physically plausible.
    private static func collect(
        depths: UnsafeMutablePointer<Float32>,
        depthStride: Int,
        confidence: UnsafeMutablePointer<UInt8>?,
        confidenceStride: Int,
        bounds: PixelBounds
    ) -> [Float] {
        var values: [Float] = []
        values.reserveCapacity(
            (bounds.maxX - bounds.minX + 1) * (bounds.maxY - bounds.minY + 1)
        )

        for py in bounds.minY...bounds.maxY {
            for px in bounds.minX...bounds.maxX {
                if let confidence,
                   confidence[py * confidenceStride + px] < minimumConfidence { continue }

                let depth = depths[py * depthStride + px]
                if depth > minimumDepth, depth < maximumDepth, depth.isFinite {
                    values.append(depth)
                }
            }
        }
        return values
    }

    /// The shrunk box, mapped into depth-buffer pixel indices.
    ///
    /// Depth and capture buffers share an orientation and a field of view, so image
    /// space maps to depth space by a straight proportional scale.
    private static func pixelBounds(
        box: CGRect, depthWidth: Int, depthHeight: Int, imageSize: CGSize
    ) -> PixelBounds? {
        guard imageSize.width > 0, imageSize.height > 0 else { return nil }

        let inset = (1 - boxKeepFraction) / 2
        let core = box.insetBy(dx: box.width * inset, dy: box.height * inset)
        guard !core.isEmpty else { return nil }

        let scaleX = CGFloat(depthWidth) / imageSize.width
        let scaleY = CGFloat(depthHeight) / imageSize.height

        // Outward rounding, so a gear smaller than one depth pixel still yields the
        // pixel it sits on rather than an empty range. Whether that is enough is then
        // decided by `GearDepthProbe.minimumSamples`, where the answer is visible.
        let bounds = PixelBounds(
            minX: max(0, Int((core.minX * scaleX).rounded(.down))),
            maxX: min(depthWidth - 1, Int((core.maxX * scaleX).rounded(.up))),
            minY: max(0, Int((core.minY * scaleY).rounded(.down))),
            maxY: min(depthHeight - 1, Int((core.maxY * scaleY).rounded(.up)))
        )
        guard bounds.maxX >= bounds.minX, bounds.maxY >= bounds.minY else { return nil }
        return bounds
    }
}
