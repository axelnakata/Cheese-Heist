//
//  BlueprintScript.swift
//  Cheese Heist
//
//  The 3 steps' content, verbatim from the reference build (`cheezy-dev-nay`'s
//  `LegoTutorialViewModel`), which matches the Figma frames (`blueprint 1/2/3`,
//  669:256, 671:286, 672:304). Content, not logic — adding or editing a step must not
//  require touching `BlueprintViewModel`.
//
//  Step 2 names gears by tooth count, not colour (PRD §11.4 OQ-5) — LEGO Technic gear
//  colours vary by kit and the detector classifies colour-agnostically.
//

import SwiftUI

enum BlueprintScript {

    /// The mouse's periodic mid-build check-in.
    static let checkInLine = "Still with me? Keep building!"

    static let steps: [BlueprintStep] = [
        BlueprintStep(
            id: 0,
            title: "Let’s make the base first!",
            stepLabel: "1/3",
            gifName: "blueprint_step_1",
            instructions: [
                "Get a **LEGO plate**, make sure it’s wide enough and **stable**",
                "Make a **crane tower** using any **LEGO bricks** and your creativity!",
                "Your **crane tower** should be at least **12 blocks high**"
            ]
        ),
        BlueprintStep(
            id: 1,
            title: "Then, build the arm with gears!",
            stepLabel: "2/3",
            gifName: "blueprint_step_2",
            instructions: [
                "Get a **LEGO technic brick**!",
                """
                Get **two axles** and insert one to the **8-tooth Gear,** and the other to \
                **the 40-tooth Gear,** then insert both through the holes of the LEGO technic brick
                """,
                "Make sure the gears are **linked** with each other (when you move one, the other also moves)",
                "Secure each axle’s end with **a bushing**, so the gears won’t fall off"
            ]
        ),
        BlueprintStep(
            id: 2,
            title: "Put it all up together!",
            stepLabel: "3/3",
            gifName: "blueprint_step_3",
            instructions: [
                "Attach the **crane arm on top of the crane tower** and you’re all set up!"
            ]
        )
    ]
}
