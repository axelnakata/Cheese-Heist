//
//  SpeechBubbleShape.swift
//  Cheese Heist
//
//  PRD §8.4 rule 2 — views compose, they do not draw. The bubble's Path lives here, not
//  in SpeechBubbleView.
//

import SwiftUI

/// A rounded speech bubble with a tail hanging from the bottom-left corner.
///
/// The tail is drawn *inside* `rect`: the rounded body is inset from the bottom by
/// `tailSize.height`, so the shape needs no extra layout allowance.
struct SpeechBubbleShape: Shape {

    var cornerRadius: CGFloat
    var tailSize: CGSize

    func path(in rect: CGRect) -> Path {
        let body = CGRect(
            x: rect.minX,
            y: rect.minY,
            width: rect.width,
            height: max(0, rect.height - tailSize.height)
        )

        var path = Path(roundedRect: body, cornerRadius: cornerRadius, style: .continuous)

        // Tail: a wedge dropping from just inside the bottom-left corner radius.
        let tailOrigin = body.minX + cornerRadius
        path.move(to: CGPoint(x: tailOrigin, y: body.maxY))
        path.addLine(to: CGPoint(x: tailOrigin, y: rect.maxY))
        path.addLine(to: CGPoint(x: tailOrigin + tailSize.width, y: body.maxY))
        path.closeSubpath()

        return path
    }
}

#Preview {
    SpeechBubbleShape(cornerRadius: AppRadius.bubble, tailSize: CGSize(width: 34, height: 24))
        .fill(AppColor.accent)
        .frame(width: 320, height: 109)
        .previewBackdrop(.parchment)
}
