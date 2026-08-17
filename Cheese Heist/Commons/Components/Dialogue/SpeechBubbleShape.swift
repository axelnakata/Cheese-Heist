//
//  SpeechBubbleShape.swift
//  Cheese Heist
//
//  PRD §8.4 rule 2 — views compose, they do not draw. The bubble's Path lives here, not
//  in SpeechBubbleView.
//
//  Traced off the Level 1 frames rather than guessed: the body is a 30pt-radius rounded
//  rectangle (measured against the rendered edge profile — it is NOT a capsule, which is
//  what a radius of half the height would have made it), and the tail is a curved
//  teardrop, not the straight wedge this used to draw. The old wedge met the body at two
//  hard corners and read as a separate triangle parked underneath the bubble; the curves
//  below are what make it grow out of the body instead.
//

import SwiftUI

/// A rounded speech bubble with a seamless curved horizontal tail on the left side.
struct SpeechBubbleShape: Shape {

    var cornerRadius: CGFloat
    var tailSize: CGSize

    static func tipOffset(forTailHeight height: CGFloat) -> CGFloat { 0 }
    static func bulge(forTailHeight height: CGFloat) -> CGFloat { height }

    func path(in rect: CGRect) -> Path {
        let tailWidth = tailSize.width
        let body = CGRect(
            x: rect.minX + tailWidth,
            y: rect.minY,
            width: max(0, rect.width - tailWidth),
            height: rect.height
        )

        let centerY = body.midY
        let tailHeight = tailSize.height
        let radius = min(cornerRadius, body.height / 2)

        let topAnchorY = centerY - tailHeight * 0.35
        let bottomAnchorY = centerY + tailHeight * 0.25
        let tip = CGPoint(x: body.minX - tailWidth, y: centerY - tailHeight * 0.5)

        var path = Path()

        // 1. Mulai dari sudut kiri atas badan (sebelum lengkungan kiri)
        path.move(to: CGPoint(x: body.minX + radius, y: body.minY))

        // 2. Sudut kanan atas, kanan bawah, dan kiri bawah
        path.addLine(to: CGPoint(x: body.maxX - radius, y: body.minY))
        path.addArc(
            center: CGPoint(x: body.maxX - radius, y: body.minY + radius),
            radius: radius,
            startAngle: .degrees(-90),
            endAngle: .degrees(0),
            clockwise: false
        )
        
        path.addLine(to: CGPoint(x: body.maxX, y: body.maxY - radius))
        path.addArc(
            center: CGPoint(x: body.maxX - radius, y: body.maxY - radius),
            radius: radius,
            startAngle: .degrees(0),
            endAngle: .degrees(90),
            clockwise: false
        )

        path.addLine(to: CGPoint(x: body.minX + radius, y: body.maxY))
        path.addArc(
            center: CGPoint(x: body.minX + radius, y: body.maxY - radius),
            radius: radius,
            startAngle: .degrees(90),
            endAngle: .degrees(180),
            clockwise: false
        )

        path.addLine(to: CGPoint(x: body.minX, y: bottomAnchorY))

        path.addQuadCurve(
            to: tip,
            control: CGPoint(x: body.minX - tailWidth * 0.5, y: centerY + tailHeight * 0.1)
        )
        path.addQuadCurve(
            to: CGPoint(x: body.minX, y: topAnchorY),
            control: CGPoint(x: body.minX - tailWidth * 0.3, y: centerY - tailHeight * 0.1)
        )

        path.addLine(to: CGPoint(x: body.minX, y: body.minY + radius))
        path.addArc(
            center: CGPoint(x: body.minX + radius, y: body.minY + radius),
            radius: radius,
            startAngle: .degrees(180),
            endAngle: .degrees(270),
            clockwise: false
        )

        path.closeSubpath()
        return path
    }
}
