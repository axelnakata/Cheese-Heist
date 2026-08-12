//
//  CrankArrowShape.swift
//  Cheese Heist
//
//  A curved arrow lying on a circle, pointing the way the crank turns.
//
//  ═══ WHY AN ARROW AND NOT A DOT. ═══
//
//  The joystick used to show a blue disc parked beside the white knob, and classroom
//  testing turned up children cranking backwards. That is not surprising: a dot has no
//  direction in it. Whichever way it was meant to be read, half the room read it the
//  other way, and turning the wrong way does nothing at all — so the child gets no
//  feedback either, just a crane that will not lift.
//
//  A head and a tail can only be read one way round. It is FILLED rather than stroked
//  because a stroked path outlines the arrowhead instead of filling it, and a hollow
//  triangle at 20 points over a camera feed is a smudge.
//

import SwiftUI

/// An arc with an arrowhead at its leading end, drawn clockwise on screen.
///
/// `lead` is in TURNS rather than radians or degrees so that animating it from 0 to 1
/// is exactly one revolution and repeats seamlessly.
struct CrankArrowShape: Shape {

    /// Where the head is, in turns clockwise from twelve o'clock.
    var lead: CGFloat

    /// How much of the circle the tail covers, in turns.
    var sweep: CGFloat = 0.22

    /// Band thickness and head size, in points.
    var thickness: CGFloat = 7
    var headSpread: CGFloat = 22

    var animatableData: CGFloat {
        get { lead }
        set { lead = newValue }
    }

    func path(in rect: CGRect) -> Path {
        let centre = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2 - headSpread / 2
        guard radius > 0 else { return Path() }

        let head = angle(lead)
        let tail = angle(lead - sweep)
        // The head is a fixed number of POINTS long, converted to the angle that covers
        // it — so the arrowhead stays the same shape whatever size the ring is.
        let tip = angle(lead) + Angle.radians(Double(headSpread / radius))

        var path = Path()
        path.addArc(center: centre, radius: radius + thickness / 2,
                    startAngle: tail, endAngle: head, clockwise: false)
        path.addLine(to: point(centre, head, radius + headSpread / 2))
        path.addLine(to: point(centre, tip, radius))
        path.addLine(to: point(centre, head, radius - headSpread / 2))
        path.addLine(to: point(centre, head, radius - thickness / 2))
        path.addArc(center: centre, radius: radius - thickness / 2,
                    startAngle: head, endAngle: tail, clockwise: true)
        path.closeSubpath()
        return path
    }

    /// Turns to an angle. Screen y grows downward, so increasing angles run CLOCKWISE —
    /// the same convention `CircularDragTracker` reads the finger in.
    private func angle(_ turns: CGFloat) -> Angle {
        .degrees(Double(turns) * 360 - 90)
    }

    private func point(_ centre: CGPoint, _ angle: Angle, _ radius: CGFloat) -> CGPoint {
        CGPoint(
            x: centre.x + cos(angle.radians) * radius,
            y: centre.y + sin(angle.radians) * radius
        )
    }
}

#Preview {
    CrankArrowShape(lead: 0.3)
        .fill(AppColor.accent)
        .frame(width: 200, height: 200)
        .previewBackdrop(.cameraFeed)
}
