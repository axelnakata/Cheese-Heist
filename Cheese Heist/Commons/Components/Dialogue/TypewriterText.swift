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

    let text: AttributedString
    var charactersPerSecond: Double = 40

    @Binding var isComplete: Bool
    
    /// Flag tambahan untuk menandai apakah cooldown 1 detik setelah teks selesai sudah terpenuhi
    @Binding var canContinue: Bool

    @State private var revealedCount = 0

    init(
        text: AttributedString,
        charactersPerSecond: Double = 40,
        isComplete: Binding<Bool>,
        canContinue: Binding<Bool> = .constant(true)
    ) {
        self.text = text
        self.charactersPerSecond = charactersPerSecond
        self._isComplete = isComplete
        self._canContinue = canContinue
    }

    var body: some View {
        Text(text)
            .hidden()
            .overlay(alignment: .topLeading) { Text(revealedText) }
            .task(id: text) {
                await reveal()
            }
            .onChange(of: text) { _, _ in
                if !isComplete {
                    revealedCount = 0
                    canContinue = false
                }
            }
            .onChange(of: isComplete) { _, complete in
                if complete {
                    revealedCount = text.characters.count
                }
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

        await MainActor.run { canContinue = false }

        if isComplete {
            revealedCount = total
            await triggerCooldown()
            return
        }

        revealedCount = 0
        let tick = Duration.seconds(1 / max(charactersPerSecond, 1))

        for _ in 0..<total {
            do {
                try await Task.sleep(for: tick)
            } catch {
                if isComplete {
                    revealedCount = total
                    await triggerCooldown()
                }
                return
            }

            if isComplete {
                revealedCount = total
                await triggerCooldown()
                return
            }

            revealedCount += 1
        }

        await MainActor.run {
            isComplete = true
        }
        
        await triggerCooldown()
    }

    /// Menambah jeda (cooldown) 1 detik sebelum memberikan izin untuk 'continue'
    private func triggerCooldown() async {
        do {
            try await Task.sleep(for: .seconds(1))
            await MainActor.run {
                canContinue = true
            }
        } catch {
            
        }
    }
}
