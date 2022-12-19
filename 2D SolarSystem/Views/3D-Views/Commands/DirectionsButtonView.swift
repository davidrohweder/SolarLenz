//
//  DirectionsButtonView.swift
//  2D SolarSystem
//
//  Created by David Rohweder on 11/28/22.
//

import SwiftUI

struct DirectionsButtonView: View {
    @EnvironmentObject var manager: PlanetManager
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        Button(action: {
            manager.currentPlanet = manager.planets.first(where: { $0.name == manager.ar_travelPlanet })!
            manager.expand_AR_help = false
            dismiss()
        }) {
            HStack {
                Text("Go to " + manager.ar_travelPlanet)
                Image(systemName: "arrow.upright.circle")
            }
        }
        .tint(.white)
    }
}

struct DirectionsButtonView_Previews: PreviewProvider {
    static var previews: some View {
        DirectionsButtonView()
    }
}
