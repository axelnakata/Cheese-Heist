//
//  GearDepthProbe.swift
//  Cheese Heist
//
//  Reads how far away a gear is, straight off the LiDAR depth map. One job — turn a
//  detector box into a distance, measured rather than inferred.
//
//  WHY THIS IS SAFE, GIVEN THAT A GEAR'S CENTRE IS AN AXLE HOLE:
//
//  The hole is real, and so are the background pixels around the gear's silhouette.
//  Two things handle them without a geometric mask:
//
//  - THE BOX IS SHRUNK to its central portion (`DepthPixelSampler.boxKeepFraction`).
//    The outer edge is where LiDAR's "flying pixels" straddle gear and background and
//    report a depth halfway between the two — a reading that belongs to neither
//    surface.
//
//  - THE NEAREST CLUSTER WINS, not the median. Everything the hole sees through to is
//    further away than the gear, so it loses on distance rather than having to be
//    identified and excluded. Within a shrunk gear box the gear is, by definition, the
//    closest solid thing.
//
//  WHY THIS IS AN EASIER QUESTION THAN FITTING A PLANE TO THE BEAM:
//  A distance is a scalar and averages down; a normal is a direction, dominated by the
//  noisiest axis of a thin, hole-riddled strip, and successive fits disagreed by up to
//  112 degrees. LiDAR is excellent at "how far" and poor at "which way" on small
//  objects. This asks it only the first — the facing direction comes from the line
//  between two measured gear centres instead (`HorizontalNormalSolver`).
//

import CoreGraphics
import Foundation

enum GearDepthProbe {

    /// Depth pixels a reading must survive with.
    ///
    /// This is the honest floor on how small a gear can be measured. An 8T is 10mm
    /// across — about two depth pixels at 40cm — and will fail this, which is correct:
    /// the caller falls back to the shared plane rather than trusting two pixels.
    static let minimumSamples = 12

    /// Half-width of the band kept around the front-surface seed, in metres.
    ///
    /// A gear is a few millimetres thick and spans a little more seen at an angle. Kept
    /// tight on purpose: unlike a plane fit, there is no residual test downstream to
    /// catch anything let in here.
    static let surfaceBandMeters: Float = 0.008

    /// How far away this gear is, or nil if the frame could not say.
    ///
    /// Nil is a normal outcome — a gear too small in frame, a hand across it, a low
    /// confidence patch — and callers are expected to carry on without it rather than
    /// treat it as failure.
    static func measure(
        box: CGRect,
        centerPixel: CGPoint,
        captured: CapturedFrameData
    ) -> GearDepthSample? {

        let depths = DepthPixelSampler.confidentDepths(in: box, captured: captured)
        guard depths.count >= minimumSamples else { return nil }

        // The gear is the closest solid thing inside its own box; anything further is
        // seen THROUGH it, via the axle hole or the gaps between teeth.
        guard let seed = DepthClusterSolver.nearestCluster(
            depths: depths, minimumWeight: minimumSamples
        ) else { return nil }

        let onSurface = depths.filter { abs($0 - seed) <= surfaceBandMeters }
        guard onSurface.count >= minimumSamples,
              let depth = DepthClusterSolver.median(onSurface) else { return nil }

        guard depth > DepthPixelSampler.minimumDepth,
              depth < DepthPixelSampler.maximumDepth else { return nil }

        return GearDepthSample(
            world: PixelUnprojector.unproject(
                pixel: centerPixel, depth: depth, captured: captured
            ),
            depth: depth,
            sampleCount: onSurface.count
        )
    }
}
