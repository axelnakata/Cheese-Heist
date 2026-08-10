// UnsupportedDeviceView.swift — Cheese Heist
// PRD §5.1 — terminal screen for non-LiDAR iPads.

import SwiftUI

struct UnsupportedDeviceView: View {

    private enum Metric {
        static let iconSize: CGFloat = 80
    }

    @Environment(\.layoutScale) private var scale

    var body: some View {
        VStack(spacing: AppSpacing.l * scale) {
            Image(systemName: "lidar.ipad")
                .font(.system(size: Metric.iconSize * scale))
                .foregroundStyle(AppColor.textPrimary)

            Text("LiDAR Required")
                .appText(AppFont.title)
                .foregroundStyle(AppColor.textPrimary)

            Text("Cheese Heist needs an iPad with LiDAR.\nPlease use an iPad Pro.")
                .appText(AppFont.dialogue)
                .foregroundStyle(AppColor.textPrimary.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColor.surfaceBackground)
    }
}

#Preview {
    UnsupportedDeviceView()
        .previewBackdrop(.parchment)
}
