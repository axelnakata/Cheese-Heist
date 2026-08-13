//
//  CutsceneMouseLayer.swift
//  Cheese Heist
//
//  PRD-Cutscene override C-1 — the mouse is a 2D overlay at bottom-leading, fixed in
//  screen space. Unlike Level 1, it is NOT in the AR scene: it is the narrator, so it
//  stays put and stays readable wherever the child points the iPad.
//
//  ═══ THE ANCHOR COMES FROM THE CONTAINER, NOT FROM `UIScreen`. ═══
//
//  `GameplayDialogueLayer` wants the speaker's head in the coordinate space of the layer
//  it is drawn in. The first version reached for `UIScreen.main.bounds.height` to work
//  that out, which is both deprecated and the wrong rectangle — it is the whole device
//  screen, not this view — so the bubble sat at an offset that happened to be close on
//  one geometry and wrong everywhere else. A `GeometryReader` answers the question the
//  layer is actually asking.
//
//  Numbers are measured off `Docs/cutscene frames/cutscene 2.png`, where the bubble's
//  body spans x 442…1239 and y 728…823 in the 1366 × 1024 design frame.
//

import SwiftUI

struct CutsceneMouseLayer: View {

    let beat: CutsceneBeat?
    let dialogueBeat: DialogueBeat?
    let isRevealComplete: Bool
    let onRevealComplete: () -> Void

    @Environment(\.layoutScale) private var scale

    private enum Metric {
        /// Mouse height in design points — Figma `mice happy 1`, 590 tall, bleeding off
        /// the bottom of the frame exactly as in the mockups.
        static let mouseHeight: CGFloat = 550
        static let leadingInset: CGFloat = 10
        /// Where on the mouse the bubble's tail points, as a fraction of its box.
        static let headX: CGFloat = 0.90
        static let headY: CGFloat = 0.68
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .bottomLeading) {
                if let pose = beat?.pose {
                    Image(pose.assetName)
                        .resizable()
                        .scaledToFit()
                        .frame(height: Metric.mouseHeight * scale)
                        .padding(.leading, Metric.leadingInset * scale)
                        .offset(y:150)
                        .allowsHitTesting(false)
                }

                if let dialogue = dialogueBeat {
                    GameplayDialogueLayer(
                        text: DialogueBeatText.attributed(dialogue),
                        style: .accent,
                        isRevealComplete: isRevealComplete,
                        anchor: headAnchor(in: proxy.size, pose: beat?.pose),
                        onRevealComplete: onRevealComplete
                    )
                }
            }
            .frame(width: proxy.size.width, height: proxy.size.height, alignment: .bottomLeading)
        }
    }

    /// The mouse's head, in this layer's coordinate space.
    private func headAnchor(in size: CGSize, pose: MouseSprite?) -> CGPoint? {
        guard size.height > 0 else { return nil }
        
        let height = Metric.mouseHeight * scale
        let left = Metric.leadingInset * scale
        let top = size.height - height
        
        let referenceWidth = height * 1.0
        let anchorX = left + referenceWidth * Metric.headX
        
        let currentPoseHeight = pose != nil ? height : height
        let anchorY = top + currentPoseHeight * Metric.headY + 100
        
        return CGPoint(x: anchorX, y: anchorY)
    }
}

#Preview("Beat 0 — happy, greeting") {
    CutsceneMouseLayer(
        beat: CutsceneScript.beats[0],
        dialogueBeat: CutsceneScript.beats[0].dialogue,
        isRevealComplete: true,
        onRevealComplete: {}
    )
    .previewBackdrop(.cameraFeed)
}

#Preview("Beat 3 — think, crane bolded") {
    CutsceneMouseLayer(
        beat: CutsceneScript.beats[3],
        dialogueBeat: CutsceneScript.beats[3].dialogue,
        isRevealComplete: true,
        onRevealComplete: {}
    )
    .previewBackdrop(.parchment)
}
