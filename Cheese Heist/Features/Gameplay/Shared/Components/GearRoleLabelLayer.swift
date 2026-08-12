//
//  GearRoleLabelLayer.swift
//  Cheese Heist
//
//  The "Driver" and "Follower" pills, each on a leader line back to the gear it names.
//
//  Positions come from `GearScreenTarget`, which is re-projected every frame, so the
//  labels track the real gears as the child moves rather than sitting at fixed screen
//  positions that happen to line up from one angle.
//
//  ═══ THE PILLS ARE PLACED AGAINST EACH OTHER, NOT AGAINST THEIR OWN GEAR. ═══
//
//  Each pill used to hang a fixed 54pt to one side of its own gear, which is a guess
//  about how far apart the gears are on screen — and on the 8T + 40T pair, seen from
//  where a child actually stands, they are not far apart at all. The two pills landed on
//  top of each other with their leader lines crossing, so the one thing the labels exist
//  to say — WHICH gear is the driver — was the one thing they could not say.
//
//  So the spread is measured from the PAIR: the pills go outboard of the leftmost and
//  rightmost gear, on a shared baseline, with a long horizontal run back in to each
//  gear. Two pills at opposite ends of the pair cannot collide however close the gears
//  get, and the horizontal run is what buys the gap between the two words.
//
//  Sides are chosen by screen position rather than by role, so the leaders never cross.
//  A tap that swaps the roles therefore swaps the two pills' words and colours in place,
//  which reads as the label moving to the other gear — see `Level1ViewModel.tapGear`.
//

import SwiftUI

struct GearRoleLabelLayer: View {

    let targets: [GearScreenTarget]

    @Environment(\.layoutScale) private var scale

    private enum Metric {
        /// How far below the lowest gear rim the shared baseline sits.
        static let drop: CGFloat = 118
        /// How far outboard of the pair the pill centre sits. Long, and mostly
        /// horizontal, which is the space between the two words.
        static let spread: CGFloat = 168
        /// Keeps a pill on screen when the crane is framed near an edge. Half of the
        /// widest pill ("Follower") plus a margin.
        static let edgeInset: CGFloat = 96
        /// The dot that marks which gear a leader belongs to.
        static let originDot: CGFloat = 14
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .topLeading) {
                ForEach(targets) { target in
                    leader(for: target, in: proxy.size)
                }
            }
        }
        .allowsHitTesting(false)
    }

    @ViewBuilder
    private func leader(for target: GearScreenTarget, in size: CGSize) -> some View {
        let start = leaderStart(for: target)
        let anchor = pillAnchor(for: target, in: size)

        LeaderLineShape(from: start, to: anchor)
            .stroke(colour(for: target.role), lineWidth: AppStroke.chip * scale)

        Circle()
            .fill(colour(for: target.role))
            .frame(width: Metric.originDot * scale, height: Metric.originDot * scale)
            .position(start)

        GearRoleLabel(role: target.role)
            .position(anchor)
    }

    /// The line leaves the gear's rim, not its centre, so it never draws across the
    /// twin it is pointing at.
    private func leaderStart(for target: GearScreenTarget) -> CGPoint {
        CGPoint(x: target.center.x, y: target.center.y + target.radius)
    }

    /// Outboard of the whole pair, on the baseline both pills share.
    private func pillAnchor(for target: GearScreenTarget, in size: CGSize) -> CGPoint {
        let inset = Metric.edgeInset * scale
        let x = isLeftmost(target)
            ? leftEdge - Metric.spread * scale
            : rightEdge + Metric.spread * scale

        return CGPoint(x: x.clamped(to: inset...max(inset, size.width - inset)), y: baseline)
    }

    /// Whichever gear is further left takes the left-hand pill. Ties break on id so the
    /// two pills can never choose the same side.
    private func isLeftmost(_ target: GearScreenTarget) -> Bool {
        guard let other = targets.first(where: { $0.id != target.id }) else { return true }
        guard target.center.x != other.center.x else {
            return target.id.uuidString < other.id.uuidString
        }
        return target.center.x < other.center.x
    }

    /// One height for both pills, below every gear in the pair — so a crane seen at an
    /// angle, with one gear higher than the other, still gets two level labels.
    private var baseline: CGFloat {
        let lowest = targets.map { $0.center.y + $0.radius }.max() ?? 0
        return lowest + Metric.drop * scale
    }

    private var leftEdge: CGFloat {
        targets.map { $0.center.x - $0.radius }.min() ?? 0
    }

    private var rightEdge: CGFloat {
        targets.map { $0.center.x + $0.radius }.max() ?? 0
    }

    private func colour(for role: GearRole) -> Color {
        role == .driver ? AppColor.roleDriver : AppColor.roleFollower
    }
}
