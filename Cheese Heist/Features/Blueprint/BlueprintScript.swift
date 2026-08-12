//
//  BlueprintScript.swift
//  Cheese Heist
//
//  The 3 steps' content, verbatim from the Figma frames (`blueprint 1/2/3`,
//  669:256, 671:286, 672:304). Content, not logic — adding or editing a step must not
//  require touching `BlueprintViewModel`.
//
//  Step 2 names gears by tooth count, not colour (PRD §11.4 OQ-5) — LEGO Technic gear
//  colours vary by kit and the detector classifies colour-agnostically.
//

enum BlueprintScript {

    static let steps: [BlueprintStep] = [
        BlueprintStep(
            id: 0,
            title: "Let's make the base first!",
            stepLabel: "1/3",
            media: .gif("blueprint_step_1"),
            instructions: [
                .init(
                    "Get a LEGO plate, make sure it's wide enough and stable",
                    bold: ["LEGO plate", "stable"]
                ),
                .init(
                    "Make a crane tower using any LEGO bricks and your creativity!",
                    bold: ["crane tower", "LEGO bricks"]
                ),
                .init(
                    "Your crane tower should be at least 12 blocks high",
                    bold: ["crane tower", "12 blocks high"]
                )
            ]
        ),
        BlueprintStep(
            id: 1,
            title: "Then, build the arm with gears!",
            stepLabel: "2/3",
            media: .gif("blueprint_step_2"),
            instructions: [
                .init("Get a LEGO technic brick!", bold: ["LEGO technic brick"]),
                .init(
                    """
                    Get two axles and insert one to the 8-tooth Gear, and the other to the \
                    40-tooth Gear, then insert both through the holes of the LEGO technic brick
                    """,
                    bold: ["two axles", "8-tooth Gear", "40-tooth Gear"]
                ),
                .init(
                    "Make sure the gears are linked with each other (when you move one, the other also moves)",
                    bold: ["linked"]
                ),
                .init(
                    "Secure each axle's end with a bushing, so the gears won't fall off",
                    bold: ["a bushing"]
                )
            ]
        ),
        BlueprintStep(
            id: 2,
            title: "Put it all up together!",
            stepLabel: "3/3",
            media: .gif("blueprint_step_3"),
            instructions: [
                .init(
                    "Attach the crane arm on top of the crane tower and you're all set up!",
                    bold: ["crane arm on top of", "crane tower"]
                )
            ]
        )
    ]
}
