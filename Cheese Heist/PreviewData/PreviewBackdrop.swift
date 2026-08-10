//
//  PreviewBackdrop.swift
//  Cheese Heist
//
//  PRD §7.6 — every component previews on both a light surface and the camera feed.
//  There is no camera in a preview, so the AR case is a neutral dark stand-in that
//  exposes the same contrast problems a real feed would.
//

import SwiftUI

enum PreviewBackdrop {
    case parchment
    case cameraFeed

    var fill: AnyShapeStyle {
        switch self {
        case .parchment:
            AnyShapeStyle(AppColor.surfaceBackground)
        case .cameraFeed:
            AnyShapeStyle(
                LinearGradient(
                    colors: [Color(hex: "#4A4640"), Color(hex: "#232120")],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        }
    }
}

extension View {

    /// Centres a component on a preview backdrop at the 12.9" design scale.
    func previewBackdrop(_ backdrop: PreviewBackdrop) -> some View {
        frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(AppSpacing.xl)
            .background(backdrop.fill)
    }
}
