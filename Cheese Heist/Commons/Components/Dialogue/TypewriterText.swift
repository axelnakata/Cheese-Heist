//
//  TypewriterText.swift
//  Cheese Heist
//
//  PRD §11.3 — dialogue reveals at 40 chars/s. Tapping during the reveal completes it
//  instantly, which the owner does by setting `isComplete`.
//
//  ═══ IT IS LAID OUT FOR THE WHOLE LINE FROM THE FIRST CHARACTER. ═══
//
//  The full text is measured and hidden, and the revealed prefix is drawn over it. The
//  obvious implementation — render the prefix and let it grow — makes the SPEECH BUBBLE
//  grow with it, since the bubble hugs its text: it starts as a small blob and inflates
//  for the length of the line, dragging its tail across the mouse's head as it goes.
//  Reserving the final size means only the letters animate.
//

import SwiftUI

struct TypewriterText: View {

    /// Attributed so bold spans come from the script file, never from view code.
    let text: AttributedString
    var charactersPerSecond: Double = 40

    /// Set to `true` from outside to finish the reveal immediately. The view sets it
    /// `true` itself when the reveal ends naturally.
    @Binding var isComplete: Bool

    @State private var revealedCount = 0

    var body: some View {
        Text(text)
            .hidden()
            .overlay(alignment: .topLeading) { Text(revealedText) }
            .task(id: text) { await reveal() }
            .onChange(of: isComplete) { _, complete in
                if complete { revealedCount = text.characters.count }
            }
    }

    private var revealedText: AttributedString {
        let total = text.characters.count
        guard revealedCount < total else { return text }
        let end = text.characters.index(text.startIndex, offsetBy: revealedCount)
        return AttributedString(text[text.startIndex..<end])
    }

    private func reveal() async {
        let total = text.characters.count

        // A caller that binds `.constant(true)` wants the line shown at once.
        guard !isComplete else {
            revealedCount = total
            return
        }

        revealedCount = 0
        let tick = Duration.seconds(1 / max(charactersPerSecond, 1))

        for _ in 0..<total {
            try? await Task.sleep(for: tick)
            guard !Task.isCancelled, !isComplete else { return }
            revealedCount += 1
        }

        isComplete = true
    }
}

#Preview {
    @Previewable @State var isComplete = false

    TypewriterText(text: PreviewDialogue.craneCompliment, isComplete: $isComplete)
        .appText(AppFont.dialogue)
        .foregroundStyle(AppColor.textPrimary)
        .frame(width: 520)
        .previewBackdrop(.parchment)
        .onTapGesture { isComplete = true }
}
