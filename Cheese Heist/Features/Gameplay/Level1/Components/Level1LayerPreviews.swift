//
//  Level1LayerPreviews.swift
//  Cheese Heist
//
//  Every Level 1 layer, rendered against `MockCraneScene` on both backdrops.
//
//  PRD §8.6 — preview-driven development is mandatory, and the layers are the part of
//  this feature that can be reviewed without an iPad in the room. They live in one file
//  because a `#Preview` per phase in each layer's own file would triple the number of
//  previews Xcode compiles on every keystroke.
//

#if DEBUG
import SwiftUI

private struct Level1LayerHarness: View {
    let phase: Level1Phase

    @State private var scene = MockCraneScene()
    @State private var beatIndex = 0

    var body: some View {
        ZStack {
            if Level1PhasePresentation.showsAlignmentIllustration(phase) {
                CraneAlignmentLayer(title: Level1Script.alignment)
            }

            GearSelectionTapLayer(
                targets: scene.screenTargets,
                isEnabled: Level1InputGate.of(phase).gearsTappable,
                onTap: { _ in }
            )

            Level1HUDLayer(
                chip: Level1PhasePresentation.chip(for: phase),
                targets: scene.screenTargets,
                gate: .of(phase),
                showsRoleLabels: Level1PhasePresentation.showsRoleLabels(phase),
                onDrag: { _, _ in },
                onRelease: {}
            )

            Level1TutorialLayer(
                showsJoystickHint: Level1PhasePresentation.showsJoystickHint(phase),
                beat: Level1PhasePresentation.beats(for: phase).first,
                isRevealComplete: true,
                mouseAnchor: scene.mouseScreenAnchor,
                onRevealComplete: {}
            )
        }
    }
}

#Preview("1 · aligningCrane") {
    Level1LayerHarness(phase: .aligningCrane).previewBackdrop(.cameraFeed)
}

#Preview("2 · detectingGears") {
    Level1LayerHarness(phase: .detectingGears).previewBackdrop(.cameraFeed)
}

#Preview("3 · selectingRoles") {
    Level1LayerHarness(phase: .selectingRoles).previewBackdrop(.cameraFeed)
}

#Preview("3 · selectingRoles — parchment") {
    Level1LayerHarness(phase: .selectingRoles).previewBackdrop(.parchment)
}

#Preview("4 · rolesChosen") {
    Level1LayerHarness(phase: .rolesChosen).previewBackdrop(.cameraFeed)
}

#Preview("5 · freeCrank") {
    Level1LayerHarness(phase: .freeCrank).previewBackdrop(.cameraFeed)
}
#endif
