//
//  CircularJoystickView.swift
//  Cheese Heist
//
//  The crank. A white ring with a knob the child drags round it, bottom-right, exactly
//  where PULL was — D-2: PULL commits, the joystick cranks, and the two never share the
//  screen.
//
//  It reports POINTS, not decisions. `CircularDragTracker` turns them into an angular
//  velocity and `CrankInputViewModel` into an engagement, which is why the direction
//  logic is unit-tested and this file only draws.
//
//  ═══ THE BLUE DOT IS GONE. ═══
//
//  There used to be a second, role-coloured disc parked 70° behind the knob, meant to
//  read as "the crank has come this far round". In testing children turned the wrong
//  way, and this is why: a dot has no direction in it, and two dots on a ring read as
//  a pair of things rather than as motion. `CrankDirectionGuide` replaces it with a
//  moving arrow, which can only be read one way round.
//

import SwiftUI
import UIKit

struct CircularJoystickView: View {
    
    let isEnabled: Bool
    
    /// Which of the three teaching animations `CrankDirectionGuide` should show right
    /// now, if any.
    var hint: CrankHint = .idle
    
    let onDrag: (CGPoint, CGPoint) -> Void
    let onRelease: () -> Void
    
    @Environment(\.layoutScale) private var scale
    
    /// The knob's own continuous angle. Moved only by RELATIVE motion — see
    /// `follow(_:)` — never snapped to the finger's absolute position, so it is safe
    /// to round for display without ever having jumped anywhere first.
    @State private var knobAngle: Angle = .degrees(90)
    
    /// What actually gets drawn — `knobAngle` rounded to the nearest notch. A real
    /// hand-crank ratchets over teeth, not a smooth sweep, and a knob that glides
    /// reads as a slider rather than a crank.
    @State private var notchAngle: Angle = .degrees(90)
    
    /// The finger's angle on the PREVIOUS sample, so `follow(_:)` can measure how far
    /// it just turned rather than where it currently is. Nil between touches, which is
    /// what makes a fresh touch calibrate silently instead of teleporting the knob.
    @State private var lastTouchAngle: Angle?
    
    @State private var isDragging: Bool = false
    
    private let hapticGenerator = UIImpactFeedbackGenerator(style: .rigid)
    
    private enum Metric {
        static let ring: CGFloat = 200
        static let knob: CGFloat = 62
        static let disabledOpacity: Double = 0.45
        /// Degrees per ratchet tooth. 9° read as a smooth glide with a slightly rough
        /// edge rather than a ratchet — the gap between teeth has to be wide enough
        /// that the knob visibly PAUSES between jumps rather than seeming to track the
        /// finger continuously. 24° is 15 teeth a revolution, close to a real socket
        /// wrench's click spacing.
        static let notchDegrees: Double = 24
        /// Slower and looser than a UI micro-interaction spring on purpose: enough
        /// response time to see the knob travel and enough give to overshoot a hair,
        /// so each tooth reads as a mechanical click landing rather than a value
        /// snapping instantly to place.
//        static let notchSpring: Animation = .spring(response: 0.16, dampingFraction: 0.45)
        /// Radians — the same unit `CrankRatchet.delta` returns. A hard ceiling on how
        /// far ONE touch sample may move the knob, however far the finger itself moved:
        /// about 60°, several times a realistic per-frame rotation and nowhere near a
        /// jump clear across the ring. This is what stops a fast diagonal drag from
        /// teleporting the knob to wherever the finger ends up.
        static let maxStepRadians: Double = 60 * .pi / 180
        /// How often the knob clicks back one notch while unwinding with nobody
        /// touching it.
        static let autoUnwindInterval: Duration = .milliseconds(150)
    }
    
    var body: some View {
        let size = Metric.ring * scale
        
        ZStack {
            ControlPlate(diameter: size)
            
            CircularJoystickRingShape(lineWidth: AppStroke.control * scale)
                .stroke(AppColor.textOnCamera, lineWidth: AppStroke.control * scale)
            
            CrankDirectionGuide(diameter: size, hint: hint)
            
            knob(size: size)
        }
        .frame(width: size, height: size)
        .contentShape(Circle().inset(by: -Metric.knob * scale / 2))
        .gesture(drag(in: size))
        .opacity(isEnabled ? 1 : Metric.disabledOpacity)
        .allowsHitTesting(isEnabled)
        .onAppear {
            hapticGenerator.prepare()
        }
        .task(id: hint) { await autoUnwind() }
    }
    
    /// The pale disc that sits under the finger — drawn at the snapped notch, not the
    /// raw finger position, so it clicks from tooth to tooth instead of gliding.
    private func knob(size: CGFloat) -> some View {
        Circle()
            .fill(AppColor.textOnCamera)
            .shadow(color: AppColor.controlShadow, radius: AppSpacing.xs * scale)
            .frame(width: Metric.knob * scale, height: Metric.knob * scale)
            .offset(offset(for: notchAngle, radius: size / 2))
            .animation(isDragging ? nil : .spring(response: 0.15, dampingFraction: 0.65), value: notchAngle)
    }
    
    private func offset(for angle: Angle, radius: CGFloat) -> CGSize {
        CGSize(width: cos(angle.radians) * radius, height: sin(angle.radians) * radius)
    }
    
    /// ═══ THE KNOB NOW FOLLOWS BOTH WAYS — BUT NEVER TELEPORTS. ═══
    ///
    /// It used to only ever move clockwise, because a backward turn did nothing to the
    /// crane and a control that would not move read as the crank refusing. Backward
    /// turns have a real effect now — the rope falls — so the knob has to be able to
    /// show that happening, both when the finger is actively turning it the wrong way
    /// and when the crane is unwinding on its own (see `autoUnwind`).
    ///
    /// `CircularDragTracker` still sees the raw points and still classifies direction
    /// independently — this view only draws what the physics already decided.
    private func drag(in size: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                isDragging = true
                let centre = CGPoint(x: size / 2, y: size / 2)
                let touch = Angle(radians: atan2(
                    value.location.y - centre.y, value.location.x - centre.x
                ))
                follow(touch)
                onDrag(value.location, centre)
            }
            .onEnded { _ in
                isDragging = false
                lastTouchAngle = nil
                AudioManager.shared.stopSFX(.gear1)
                AudioManager.shared.stopSFX(.gear2)
                onRelease()
            }
    }
    
    /// Moves the knob by however far the finger ITSELF rotated since the last sample —
    /// never to the finger's absolute position. Two things fall out of that for free:
    ///
    /// - Grabbing the ring somewhere else never teleports the knob there. The first
    ///   sample of a new touch only records where the finger is; it takes a SECOND
    ///   sample to produce a delta, so the knob stays exactly where it was until the
    ///   finger actually turns from there.
    /// - A violent flick across the ring can only ever advance the knob by
    ///   `Metric.maxStepRadians` in one sample, however far the finger itself moved.
//    private func follow(_ touch: Angle) {
//        defer { lastTouchAngle = touch }
//        guard let lastTouchAngle else { return }
//        
//        let delta = CrankRatchet.delta(from: lastTouchAngle, to: touch)
//        guard abs(delta) > CrankRatchet.deadband else { return }
//        
//        let clamped = min(max(delta, -Metric.maxStepRadians), Metric.maxStepRadians)
//        knobAngle = Angle(radians: knobAngle.radians + clamped)
//        snapToNotch()
//    }
    
    private func follow(_ touch: Angle) {
        guard let previousTouch = lastTouchAngle else {
            lastTouchAngle = touch
            return
        }
        
        let delta = CrankRatchet.delta(from: previousTouch, to: touch)
        lastTouchAngle = touch
        
        guard abs(delta) > CrankRatchet.deadband else { return }
        
        let clamped = min(max(delta, -Metric.maxStepRadians), Metric.maxStepRadians)
        knobAngle = Angle(radians: knobAngle.radians + clamped)
        snapToNotch()
    }
    
    /// While nobody is touching the ring and the crane is unwinding — released mid-lift,
    /// or the wrong-way turn that started it has itself ended — the knob still has to
    /// spin backward to show the rope paying back out. `.task(id:)` cancels this the
    /// moment `hint` stops being `.falling`, whether that is because the cheese reached
    /// the table or because a finger landed on the ring again.
    private func autoUnwind() async {
        guard hint == .falling else { return }
        while !Task.isCancelled {
            try? await Task.sleep(for: Metric.autoUnwindInterval)
            guard !Task.isCancelled else { return }
            stepBack()
        }
    }
    
    private func stepBack() {
        knobAngle = Angle(degrees: knobAngle.degrees - Metric.notchDegrees)
        snapToNotch()
    }
    
    /// Rounds the continuous knob angle to the nearest ratchet tooth, in EITHER
    /// direction. The click the child feels is this discrete jump firing — not the
    /// drag, which is still perfectly smooth underneath.
    private func snapToNotch() {
        let step = Metric.notchDegrees
        let next = Angle(degrees: (knobAngle.degrees / step).rounded() * step)
        guard next != notchAngle else { return }
        
        var deltaDegrees = next.degrees - notchAngle.degrees
        while deltaDegrees > 180 { deltaDegrees -= 360 }
        while deltaDegrees < -180 { deltaDegrees += 360 }
        
        DispatchQueue.main.async {
            if deltaDegrees > 0 {
                AudioManager.shared.playSFX(.gear1)
            } else {
                AudioManager.shared.playSFX(.gear2)
            }
        }
        
        notchAngle = next
        
        hapticGenerator.impactOccurred()
        hapticGenerator.prepare()
    }
}

#Preview("Idle") {
    CircularJoystickView(isEnabled: true, onDrag: { _, _ in }, onRelease: {})
        .previewBackdrop(.cameraFeed)
}

#Preview("Cranking") {
    CircularJoystickView(
        isEnabled: true, hint: .none, onDrag: { _, _ in }, onRelease: {}
    )
    .previewBackdrop(.cameraFeed)
}

#Preview("Wrong way") {
    CircularJoystickView(
        isEnabled: true, hint: .wrongWay, onDrag: { _, _ in }, onRelease: {}
    )
    .previewBackdrop(.cameraFeed)
}

#Preview("Falling") {
    CircularJoystickView(
        isEnabled: true, hint: .falling, onDrag: { _, _ in }, onRelease: {}
    )
    .previewBackdrop(.cameraFeed)
}

#Preview("Over a white desk") {
    CircularJoystickView(isEnabled: true, onDrag: { _, _ in }, onRelease: {})
        .previewBackdrop(.parchment)
}
