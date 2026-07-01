//
//  Planet+Display.swift
//  SolarLenz
//
//  UI-layer presentation for the domain `Planet` type. Keeps SwiftUI out of `Domain`.
//

import SwiftUI

extension Planet {

    /// The body's accent color, mapped from the raw `colorName` token in the data set.
    /// This lives in the design-system layer so the domain model stays free of SwiftUI.
    var displayColor: Color {
        switch colorName {
        case "yellow": .yellow
        case "blue":   .blue
        case "orange": .orange
        case "gray":   .gray
        case "red":    .red
        case "brown":  .brown
        case "white":  .white
        case "indigo": .indigo
        case "cyan":   .cyan
        default:       Theme.Palette.starlight
        }
    }

    /// Filename of the bundled 3D model used in AR (e.g. `"3d-earth"`).
    var modelResourceName: String { "3d-\(name.lowercased())" }
}
