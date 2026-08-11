//
//  ControlPlate.swift
//  Cheese Heist
//
//  A soft dark disc that goes behind an on-camera control.
//
//  ═══ WHY A CONTROL OVER A CAMERA FEED NEEDS ONE. ═══
//
//  The crank is a white ring with a white knob, which is legible over a desk, a carpet
//  or a LEGO baseplate — and invisible over a sheet of paper or a pale tabletop. A
//  classroom desk is a pale tabletop. No choice of stroke colour fixes this, because the
//  background is a photograph of an arbitrary room and every colour is somewhere in it.
//
//  So the control brings its own surroundings. Everything drawn on top then contrasts by
//  construction rather than by luck. Blurred at the edge rather than cut off, so it
//  reads as a shadow the control is casting instead of a grey coin stuck to the screen.
//

import SwiftUI

struct ControlPlate: View {

    /// The control's own diameter.
    let diameter: CGFloat

    /// How far past the control the plate spreads, as a fraction of its diameter.
    /// Proportional rather than a fixed number of points, so the plate needs no
    /// `layoutScale` of its own and cannot drift from the control it sits behind.
    static let bleedRatio: CGFloat = 0.17

    private var bleed: CGFloat { diameter * Self.bleedRatio }

    var body: some View {
        Circle()
            .fill(AppColor.controlBackdrop)
            .frame(width: diameter, height: diameter)
            .padding(-bleed)
            .blur(radius: bleed / 2)
            .allowsHitTesting(false)
    }
}

#Preview("Over a pale desk — the case that broke") {
    ZStack {
        ControlPlate(diameter: 200)
        Circle()
            .strokeBorder(AppColor.textOnCamera, lineWidth: AppStroke.control)
            .frame(width: 200, height: 200)
    }
    .previewBackdrop(.parchment)
}
