// CraneAlignmentTuning.swift — Cheese Heist
// Port from gear-poc: the 13 mirror-alignment constants.

struct CraneAlignmentTuning: Sendable {
    let correctionTimeConstant: Float
    let maximumDrift: Float
    let maximumTurn: Float
    let reseatDistance: Float
    let reseatAngle: Float
    let reseatUpdates: Int
    let reseatTimeConstant: Float
    let reseatDriftLimit: Float
    let reseatTurnLimit: Float
    let reseatDoneDistance: Float
    let reseatDoneAngle: Float
    let settledDistance: Float
    let settledAngle: Float

    static let standard = CraneAlignmentTuning(
        correctionTimeConstant: 1.0,
        maximumDrift: 0.02,
        maximumTurn: 6 * .pi / 180,
        reseatDistance: 0.08,
        reseatAngle: 35 * .pi / 180,
        reseatUpdates: 8,
        reseatTimeConstant: 0.22,
        reseatDriftLimit: 2.0,
        reseatTurnLimit: 8 * .pi,
        reseatDoneDistance: 0.004,
        reseatDoneAngle: 2 * .pi / 180,
        settledDistance: 1e-5,
        settledAngle: 1e-5
    )
}
