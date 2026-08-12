// GearRoleLabel.swift — Cheese Heist
// PRD-Level1 §3 — "Driver" / "Follower" pill with role colour.

import SwiftUI

struct GearRoleLabel: View {

    let role: GearRole

    @Environment(\.layoutScale) private var scale

    var body: some View {
        Text(role == .driver ? "Driver" : "Follower")
            .appText(AppFont.body)
            .foregroundStyle(AppColor.textOnCamera)
            .padding(.horizontal, AppSpacing.m * scale)
            .padding(.vertical, AppSpacing.xs * scale)
            .background(
                Capsule()
                    .fill(roleColor)
            )
    }

    private var roleColor: Color {
        role == .driver ? AppColor.roleDriver : AppColor.roleFollower
    }
}

#Preview {
    HStack(spacing: 20) {
        GearRoleLabel(role: .driver)
        GearRoleLabel(role: .follower)
    }
    .previewBackdrop(.cameraFeed)
}
