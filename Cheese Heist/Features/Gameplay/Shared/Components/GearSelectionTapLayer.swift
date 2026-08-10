//
//  GearSelectionTapLayer.swift
//  Cheese Heist
//
//  Tap targets over the projected gears, for `selectingRoles`.
//
//  A minimum touch size is enforced regardless of how big the gear reads on screen: an
//  8T gear at arm's length projects to about 20 points across, and a six-year-old
//  cannot reliably hit that. The gear stays drawn at its true size and only the
//  invisible hit area is grown.
//

import SwiftUI

struct GearSelectionTapLayer: View {

    let targets: [GearScreenTarget]
    let isEnabled: Bool
    let onTap: (UUID) -> Void

    @Environment(\.layoutScale) private var scale

    /// Apple's 44pt minimum, taken generously for small hands.
    private static let minimumTouchDiameter: CGFloat = 88

    var body: some View {
        ZStack(alignment: .topLeading) {
            ForEach(targets) { target in
                Circle()
                    .fill(.clear)
                    .contentShape(Circle())
                    .frame(width: diameter(for: target), height: diameter(for: target))
                    .position(target.center)
                    .onTapGesture { onTap(target.id) }
            }
        }
        .allowsHitTesting(isEnabled)
    }

    private func diameter(for target: GearScreenTarget) -> CGFloat {
        max(target.radius * 2, Self.minimumTouchDiameter * scale)
    }
}
