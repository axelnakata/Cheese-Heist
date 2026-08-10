// SuccessActionsRow.swift — Cheese Heist
// PRD-Level1 §3 Phase 12: Retry (bottom-left) + Next (bottom-right).

import SwiftUI

struct SuccessActionsRow: View {

    let onRetry: () -> Void
    let onNext: () -> Void

    @Environment(\.layoutScale) private var scale

    var body: some View {
        HStack {
            LargeCTAButton(icon: .retry, action: onRetry)
            Spacer()
            LargeCTAButton(icon: .next, action: onNext)
        }
        .padding(.horizontal, AppSpacing.l * scale)
    }
}
