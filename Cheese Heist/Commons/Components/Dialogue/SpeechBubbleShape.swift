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

/// A rounded speech bubble with a curved tail hanging from the bottom-left.
///
/// The tail is drawn *inside* `rect`: the rounded body is inset from the bottom by
/// `tailSize.height`, so the shape needs no extra layout allowance.
struct SpeechBubbleShape: Shape {

    var cornerRadius: CGFloat
    var tailSize: CGSize

    /// How far LEFT of the body the tail reaches, as a multiple of its drop. The tail
    /// is a horn hanging off the corner, not a notch in it — in the frames it clears the
    /// body's left edge by about half again its own height.
    static let bulgeRatio: CGFloat = 1.6

    /// How far the tip reaches outside the body, as a multiple of the tail's drop.
    static let tipRatio: CGFloat = 1.3

    /// The room a bubble has to leave on its leading edge for the tail to live in.
    static func bulge(forTailHeight height: CGFloat) -> CGFloat {
        height * bulgeRatio
    }

    /// Where the tail's point sits, measured from the bubble view's own leading edge.
    /// Callers aim this at whoever is talking.
    static func tipOffset(forTailHeight height: CGFloat) -> CGFloat {
        height * (bulgeRatio - tipRatio)
    }

    func path(in rect: CGRect) -> Path {
        // The body is inset by the bulge, so the tail draws INSIDE the view's own
        // bounds. A tail hanging outside them renders until the first ancestor that
        // clips, and then silently loses its point.
        let inset = Self.bulge(forTailHeight: tailSize.height)
        let body = CGRect(
            x: rect.minX + inset,
            y: rect.minY,
            width: max(0, rect.width - inset),
            height: max(0, rect.height - tailSize.height)
        )

        var path = Path(roundedRect: body, cornerRadius: cornerRadius, style: .continuous)
        path.addPath(tail(under: body))
        return path
    }

    /// A curved sweep drawn ACROSS the bottom-left corner, not a spike hung under the
    /// bottom edge.
    ///
    /// Measured off the frames: the tail leaves the body high — about a corner radius up
    /// the left edge — runs down past the corner to a point some 11pt below the body and
    /// a few points left of it, and returns along the bottom edge about a radius and a
    /// half to the right. It is small. Drawn as a wedge dangling from the straight part
    /// of the bottom edge it was three times too big and read as a separate triangle
    /// parked under the bubble; spanning the corner is what makes it grow out of it.
    private func tail(under body: CGRect) -> Path {
        let drop = tailSize.height
        let onLeftEdge = CGPoint(x: body.minX, y: max(body.minY, body.maxY - cornerRadius))
        let onBottomEdge = CGPoint(x: min(body.minX + tailSize.width, body.maxX), y: body.maxY)
        // Measured off the frames: the point lands well OUTSIDE the body's left edge as
        // well as below it, which is what makes it read as a tail pointing at the
        // speaker rather than as a corner that has sagged.
        let tip = CGPoint(x: body.minX - drop * Self.tipRatio, y: body.maxY + drop)

        // WOUND THE SAME WAY AS THE ROUNDED RECT. Two subpaths in one path are filled by
        // the nonzero rule, so a tail traversed the other way round cancels against the
        // body everywhere they overlap — which punched a triangular hole through the
        // corner and let the drop shadow show through it.
        var path = Path()
        path.move(to: onBottomEdge)
        // Trailing edge: hooks down from the bottom to the point, bowed IN so the tail
        // narrows rather than reading as a triangle.
        path.addQuadCurve(
            to: tip,
            control: CGPoint(x: body.minX + cornerRadius * 0.45, y: body.maxY + drop * 0.45)
        )
        // Leading edge: carries the tip back up into the left edge, bowed well OUT so
        // the tail is a fat horn where it leaves the bubble rather than a sliver.
        path.addQuadCurve(
            to: onLeftEdge,
            control: CGPoint(
                x: body.minX - drop * Self.bulgeRatio,
                y: body.maxY - cornerRadius * 0.35
            )
        )
        path.closeSubpath()
        return path
    }
}

#Preview {
    VStack(spacing: 24) {
        SpeechBubbleShape(cornerRadius: AppRadius.bubble, tailSize: CGSize(width: 34, height: 26))
            .fill(AppColor.surfaceBackground)
            .frame(width: 320, height: 110)

        SpeechBubbleShape(cornerRadius: AppRadius.bubble, tailSize: CGSize(width: 34, height: 26))
            .fill(AppColor.surfaceBackground)
            .frame(width: 480, height: 84)
    }
    .previewBackdrop(.parchment)
}
