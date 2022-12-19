//
//  PlanetModel_Color.swift
//  2D SolarSystem
//
//  Created by David Rohweder on 11/19/22.
//

import SwiftUI

// Cant codable the swiftui color without storing colors as RGB in json
extension PlanetModel {
    
    var color: Color {
        switch (self.colorName) {
        case "yellow": return Color.yellow
        case "blue": return Color.blue
        case "orange": return Color.orange
        case "gray": return Color.gray
        case "red": return Color.red
        case "brown": return Color.brown
        case "white": return Color.white
        case "indigo": return Color.indigo
        case "cyan": return Color.cyan
        default: return Color.white
            
        }
    }
    
}
