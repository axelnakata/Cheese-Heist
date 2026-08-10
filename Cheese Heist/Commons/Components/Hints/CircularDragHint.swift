// CircularDragHint.swift — Cheese Heist
// Pulsing circular arrow hint for the crank tutorial.

import SwiftUI

struct CircularDragHint: View {

    @State private var progress: CGFloat = 0

    var body: some View {
        CircularDragHintShape(progress: progress)
            .stroke(AppColor.textOnCamera, style: StrokeStyle(lineWidth: 4, lineCap: .round))
            .frame(width: 80, height: 80)
            .onAppear {
                withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                    progress = 1
                }
            }
    }
}

#Preview {
    CircularDragHint()
        .previewBackdrop(.cameraFeed)
}
