//
//  GearDetector.swift
//  Cheese Heist
//
//  Runs the YOLO11n Core ML model over ARKit frames to find gears and their tooth
//  counts. One job — turn a camera frame into gear detections. It does not touch the
//  AR session, compute world positions, or decide when detection is "done".
//
//  PREPROCESSING CONTRACT — must match the model's training pipeline exactly:
//      ARKit capturedImage 1920x1440 -> centre-crop 1440x1440 -> model at 960
//  The model was trained on that exact representation. Feeding it a full 4:3 frame
//  (or a differently-sized crop) silently degrades accuracy, because every object
//  arrives at a scale the model never saw. `GearDetection.imageRect` is reported back
//  in the ORIGINAL full-frame pixel space so callers can unproject without knowing
//  the crop existed.
//
//  No orientation transform anywhere in this file. The app is landscape-locked
//  (PRD-Level1 §5.1) and everything downstream works in the camera's native landscape
//  pixel space; introducing a `CGImagePropertyOrientation` here is exactly the bug
//  class the PoC avoided.
//
//  The model is exported with NMS baked in, so Vision hands back final boxes.
//

import CoreML
import CoreGraphics
import Foundation
import Vision

/// Wraps the Core ML gear detector. Create once and reuse — compiling the model is
/// expensive and must not happen per frame.
final class GearDetector: @unchecked Sendable {

    /// Class order must match `names` in the training set's data.yaml.
    private static let toothCountForClass: [String: Int] = [
        "gear_8t": 8,
        "gear_24t": 24,
        "gear_40t": 40
    ]

    /// Detections below this are discarded before the caller ever sees them.
    static let minimumConfidence: Float = 0.45

    private let model: VNCoreMLModel

    init() throws {
        // Xcode compiles a bundled .mlpackage into a .mlmodelc at build time.
        //
        // The file is GearDetectorModel, NOT GearDetector: Xcode generates a Swift
        // class named after the model file, and a name matching this class collides
        // with it ("Multiple commands produce GearDetector.stringsdata").
        guard let url = Bundle.main.url(forResource: "GearDetectorModel", withExtension: "mlmodelc")
                ?? Bundle.main.url(forResource: "GearDetectorModel", withExtension: "mlpackage") else {
            throw GearDetectorError.modelNotFound
        }

        do {
            let configuration = MLModelConfiguration()
            configuration.computeUnits = .all      // let Core ML use the Neural Engine
            let mlModel = try MLModel(contentsOf: url, configuration: configuration)
            self.model = try VNCoreMLModel(for: mlModel)
        } catch {
            throw GearDetectorError.modelLoadFailed(error.localizedDescription)
        }
    }

    /// Runs detection on one captured frame.
    ///
    /// - Parameter pixelBuffer: `ARFrame.capturedImage`, in the camera's native
    ///   landscape orientation.
    /// - Returns: Detections with boxes in the original frame's pixel space.
    func detect(in pixelBuffer: CVPixelBuffer) throws -> [GearDetection] {
        let sourceWidth = CVPixelBufferGetWidth(pixelBuffer)
        let sourceHeight = CVPixelBufferGetHeight(pixelBuffer)
        let side = min(sourceWidth, sourceHeight)
        let xOffset = (sourceWidth - side) / 2
        let yOffset = (sourceHeight - side) / 2

        let request = VNCoreMLRequest(model: model)
        // The crop is already square and matches the model's aspect ratio, so
        // scaleFill introduces no distortion.
        request.imageCropAndScaleOption = .scaleFill
        request.regionOfInterest = Self.regionOfInterest(
            width: sourceWidth, height: sourceHeight, side: side,
            xOffset: xOffset, yOffset: yOffset
        )

        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
        try handler.perform([request])

        guard let observations = request.results as? [VNRecognizedObjectObservation] else {
            return []
        }

        return observations.compactMap { observation in
            guard let top = observation.labels.first,
                  let teeth = Self.toothCountForClass[top.identifier],
                  top.confidence >= Self.minimumConfidence else { return nil }

            return GearDetection(
                toothCount: teeth,
                confidence: top.confidence,
                imageRect: Self.imageRect(
                    from: observation.boundingBox,
                    cropOrigin: CGPoint(x: xOffset, y: yOffset),
                    cropSide: side
                )
            )
        }
    }

    // MARK: - Coordinate Conversion

    /// The square centre-crop, as Vision wants it: normalised, BOTTOM-LEFT origin.
    /// The crop is full-height, so y spans 0...1 and only x is inset.
    static func regionOfInterest(
        width: Int, height: Int, side: Int, xOffset: Int, yOffset: Int
    ) -> CGRect {
        CGRect(
            x: CGFloat(xOffset) / CGFloat(width),
            y: CGFloat(yOffset) / CGFloat(height),
            width: CGFloat(side) / CGFloat(width),
            height: CGFloat(side) / CGFloat(height)
        )
    }

    /// Converts a Vision box (normalised to the region of interest, bottom-left
    /// origin) into original-frame pixel coordinates with a top-left origin.
    static func imageRect(
        from boundingBox: CGRect,
        cropOrigin: CGPoint,
        cropSide: Int
    ) -> CGRect {
        let side = CGFloat(cropSide)

        // Normalised -> crop pixels, flipping y for the top-left convention.
        let xInCrop = boundingBox.minX * side
        let yInCrop = (1 - boundingBox.maxY) * side

        return CGRect(
            x: xInCrop + cropOrigin.x,
            y: yInCrop + cropOrigin.y,
            width: boundingBox.width * side,
            height: boundingBox.height * side
        )
    }
}
