//
//  DepthClusterSolver.swift
//  Cheese Heist
//
//  Turns a bag of depth readings into the one that describes the gear's front
//  surface. Pure statistics over `[Float]` — no pixel buffers, no ARKit — which is
//  what makes the subtlest decision in the depth pipeline unit-testable.
//

import Foundation

enum DepthClusterSolver {

    /// Nearest depth carrying a meaningful share of the samples, by 1cm histogram.
    ///
    /// Nearest rather than most-populous: what is being looked for is the front
    /// surface, and a background seen through the gear's own axle hole can easily
    /// contribute more pixels than the gear does. Everything the hole sees through to
    /// is FURTHER away than the gear, so it loses on distance rather than having to be
    /// identified and excluded.
    ///
    /// Bins are compared after smoothing over their neighbours, because a surface seen
    /// at an angle spreads its pixels across several bins while a flat-on background
    /// piles them into one. Comparing raw bins would systematically favour the
    /// background — the opposite of what this is for.
    static func nearestCluster(depths: [Float], minimumWeight: Int) -> Float? {
        guard let low = depths.min(), let high = depths.max() else { return nil }
        let binSize: Float = 0.01
        let binCount = max(1, Int((high - low) / binSize) + 1)

        var histogram = [Int](repeating: 0, count: binCount)
        for depth in depths {
            histogram[min(binCount - 1, Int((depth - low) / binSize))] += 1
        }

        let smoothed = (0..<binCount).map { index -> Int in
            let lower = max(0, index - 2)
            let upper = min(binCount - 1, index + 2)
            return histogram[lower...upper].reduce(0, +)
        }

        guard let peak = smoothed.max(), peak > 0 else { return nil }
        let threshold = max(minimumWeight, Int(Float(peak) * 0.35))

        for (index, count) in smoothed.enumerated() where count >= threshold {
            return low + (Float(index) + 0.5) * binSize
        }
        return nil
    }

    /// Upper median. Callers have already discarded everything off the front surface,
    /// so this only has to be robust to a handful of stragglers.
    static func median(_ values: [Float]) -> Float? {
        guard !values.isEmpty else { return nil }
        let sorted = values.sorted()
        return sorted[sorted.count / 2]
    }
}
