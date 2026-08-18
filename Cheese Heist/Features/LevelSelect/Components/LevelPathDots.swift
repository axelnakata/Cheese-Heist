//
//  LevelPathDots.swift
//  Cheese Heist
//
//  Figma "Vector 14" (1031:142) — the dotted line connecting path stops. Drawn rather
//  than imported: the export is one fixed curve, and a path that has to reach an
//  arbitrary, still-growing number of future levels needs to be computed from wherever
//  those stops actually land, not traced from a five-stop mockup.
//

import SwiftUI

struct LevelPathDots: Shape {

    let points: [CGPoint]

    func path(in rect: CGRect) -> Path {
        var path = Path()
        guard points.count > 1 else { return path }

        path.move(to: points[0])
        for index in 1..<points.count {
            let previous = points[index - 1]
            let current = points[index]
            let midpoint = CGPoint(x: (previous.x + current.x) / 2, y: (previous.y + current.y) / 2)
            path.addQuadCurve(to: midpoint, control: previous)
            path.addQuadCurve(to: current, control: midpoint)
        }
        return path
    }
}

extension LevelPathDots {

    /// A round-capped, near-zero-length dash draws a string of dots rather than lines.
    static let strokeStyle = StrokeStyle(lineWidth: 8, lineCap: .round, dash: [0.01, 26])
}
