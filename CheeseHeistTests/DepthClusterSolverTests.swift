//
//  DepthClusterSolverTests.swift
//  CheeseHeistTests
//
//  PRD §12.1 — nearest-cluster logic.
//
//  The whole reason the depth probe can point at a gear with an axle hole through the
//  middle of it: everything the hole sees through to is FURTHER away than the gear, so
//  it loses on distance rather than having to be identified and excluded.
//

import Testing
@testable import Cheese_Heist

struct DepthClusterSolverTests {

    /// `count` readings at `depth`, with a millimetre of spread so they land in one bin
    /// the way real LiDAR does.
    private func samples(at depth: Float, count: Int) -> [Float] {
        (0..<count).map { depth + Float($0 % 3) * 0.001 }
    }

    @Test("a single surface is found where it is")
    func singleSurface() {
        let found = DepthClusterSolver.nearestCluster(
            depths: samples(at: 0.40, count: 60), minimumWeight: 12
        )
        #expect(abs((found ?? 0) - 0.40) < 0.02)
    }

    /// The case this exists for. The gear is at 40cm and covers 120 pixels; the wall
    /// seen through its axle hole and between its teeth is at 90cm and covers 200. The
    /// MEDIAN would pick the wall; nearest-cluster picks the gear.
    ///
    /// The background wins only once it outnumbers the gear by roughly three to one,
    /// which is the honest limit of the 35%-of-peak threshold — and a box shrunk to its
    /// central 70% does not reach it.
    @Test("the nearest cluster wins even when the background has more pixels")
    func nearestBeatsMostPopulous() {
        let depths = samples(at: 0.40, count: 120) + samples(at: 0.90, count: 200)

        let found = DepthClusterSolver.nearestCluster(depths: depths, minimumWeight: 12)
        #expect(abs((found ?? 0) - 0.40) < 0.03)

        // …and the median really would have got it wrong.
        #expect((DepthClusterSolver.median(depths) ?? 0) > 0.8)
    }

    /// A handful of flying pixels in front of the gear must not become the answer.
    @Test("a cluster below the minimum weight is ignored")
    func sparseClustersAreIgnored() {
        let depths = samples(at: 0.20, count: 3) + samples(at: 0.50, count: 120)

        let found = DepthClusterSolver.nearestCluster(depths: depths, minimumWeight: 12)
        #expect(abs((found ?? 0) - 0.50) < 0.03)
    }

    @Test("nothing to cluster yields nothing")
    func emptyInput() {
        #expect(DepthClusterSolver.nearestCluster(depths: [], minimumWeight: 12) == nil)
        #expect(DepthClusterSolver.median([]) == nil)
    }

    @Test("the median is the middle reading")
    func median() {
        #expect(DepthClusterSolver.median([0.1, 0.2, 0.3]) == 0.2)
        #expect(DepthClusterSolver.median([0.3, 0.1, 0.2]) == 0.2)
    }
}
