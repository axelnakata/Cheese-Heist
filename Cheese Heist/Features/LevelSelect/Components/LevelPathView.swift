//
//  LevelPathView.swift
//  Cheese Heist
//
//  Figma "scrollable" (1031:137) — the path overflows its own frame even with just six
//  stops, so the frame is built to scroll. Stop centres zigzag the way the mockup's do;
//  see `position(for:)`.
//

import SwiftUI

struct LevelPathView: View {

    let stops: [LevelSelectStop]
    let stopShadowOpacity: Double
    let platformShadowOpacity: Double
    var onSelectStop: ((LevelSelectStop) -> Void)?

    init(
        stops: [LevelSelectStop],
        stopShadowOpacity: Double = 0.10,
        platformShadowOpacity: Double = 0.10,
        onSelectStop: ((LevelSelectStop) -> Void)? = nil
    ) {
        self.stops = stops
        self.stopShadowOpacity = stopShadowOpacity
        self.platformShadowOpacity = platformShadowOpacity
        self.onSelectStop = onSelectStop
    }

    @Environment(\.layoutScale) private var scale

    private enum Metric {
        static let startX: CGFloat = 155
        static let spacingX: CGFloat = 290
        static let midY: CGFloat = 450
        static let amplitude: CGFloat = 105
        static let canvasHeight: CGFloat = 900
        static let trailingInset: CGFloat = 200
        static let tapRadius: CGFloat = 90
    }

    private var canvasWidth: CGFloat {
        Metric.startX + CGFloat(stops.count - 1) * Metric.spacingX + Metric.trailingInset
    }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            ZStack(alignment: .topLeading) {
                LevelPathDots(points: stops.map { scaledPosition(for: $0) })
                    .stroke(AppColor.textOnAccent, style: LevelPathDots.strokeStyle)
                    .opacity(0.85)

                ForEach(stops) { stop in
                    LevelPathStopView(kind: stop.kind, platformShadowOpacity: platformShadowOpacity)
                        .contentShape(Circle())
                        .onTapGesture {
                            onSelectStop?(stop)
                        }
                        .position(scaledPosition(for: stop))
                }
            }
            .frame(width: canvasWidth * scale, height: Metric.canvasHeight * scale)
        }
        .frame(height: Metric.canvasHeight * scale)
    }

    /// Design-scale centre for a stop, before `layoutScale` is applied.
    private func position(for stop: LevelSelectStop) -> CGPoint {
        let index = stops.firstIndex(where: { $0.id == stop.id }) ?? 0
        let x = Metric.startX + CGFloat(index) * Metric.spacingX
        let y = Metric.midY + (index.isMultiple(of: 2) ? -Metric.amplitude : Metric.amplitude)
        return CGPoint(x: x, y: y)
    }

    private func scaledPosition(for stop: LevelSelectStop) -> CGPoint {
        let point = position(for: stop)
        return CGPoint(x: point.x * scale, y: point.y * scale)
    }
}

#Preview {
    LevelPathView(stops: LevelSelectPath.stops)
        .previewBackdrop(.parchment)
}
