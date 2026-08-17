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

    var canAdvance: Bool = true

    @Environment(\.layoutScale) private var scale

    private enum Metric {
        static let mouseHeight: CGFloat = 400
        static let leadingInset: CGFloat = 10
        
        // Kordinat offset tetap untuk Speech Bubble agar posisinya seragam
        static let bubbleX: CGFloat = 400
        static let bubbleY: CGFloat = -100
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .bottomLeading) {
                // 1. Karakter Tikus
                if let pose = beat?.pose {
                    Image(pose.assetName)
                        .resizable()
                        .scaledToFit()
                        .frame(height: Metric.mouseHeight * scale)
                        .padding(.leading, Metric.leadingInset * scale)
                        .offset(x: 100 * scale, y: -50 * scale)
                        .allowsHitTesting(false)
                }

                // 2. Speech Bubble (Posisi Tetap untuk Semua Beat)
                if let dialogue = dialogueBeat {
                    VStack(alignment: .leading, spacing: 10 * scale) {
                        // 1. Speech Bubble Utama
                        SpeechBubbleView(
                            text: DialogueBeatText.attributed(dialogue),
                            style: .parchment,
                            isRevealComplete: .init(
                                get: { isRevealComplete },
                                set: { if $0 { onRevealComplete() } }
                            )
                        )
                        
                        // 2. Tampilkan Hint "tap to continue" Jika Teks Selesai Disajikan & canAdvance True
                            TapToContinueHint(title: "tap to continue")
                                .padding(.leading, 50 * scale)
                                .opacity((isRevealComplete && canAdvance) ? 1 : 0)
                    }
                    .offset(x: Metric.bubbleX * scale, y: Metric.bubbleY * scale)
                }
            }
            .frame(width: proxy.size.width, height: proxy.size.height, alignment: .bottomLeading)
        }
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
