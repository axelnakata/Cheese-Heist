//
//  CranePlaneSolution.swift
//  Cheese Heist
//
//  Everything the estimator concluded from the frame it was just given.
//

import simd

struct CranePlaneSolution: Sendable {
    let frame: CraneFrame

    /// World positions in `GearOrdering.ordered(_:)` order.
    let gearPositions: [simd_float3]

    /// Depth probes accepted so far this session.
    let sampleCount: Int

    /// Measured gear separation over LEGO's known separation, when both gears could be
    /// probed. Near 1.0 means an independent measurement landed on a number it was
    /// never given. Nil when only one gear was big enough to measure.
    let separationAgreement: Float?
}
