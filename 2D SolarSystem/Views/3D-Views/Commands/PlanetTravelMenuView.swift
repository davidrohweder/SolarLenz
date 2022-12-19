//
//  PlanetTravelMenuView.swift
//  2D SolarSystem
//
//  Created by David Rohweder on 11/28/22.
//

import SwiftUI

struct PlanetTravelMenuView: View {
    @EnvironmentObject var manager: PlanetManager
    var body: some View {
        Picker ("Travel To:", selection: $manager.ar_travelPlanet) {
            ForEach(manager.planets) { planet in
                Text(planet.name.capitalized).tag(planet.name)
            }
        }
    }
}

struct PlanetTravelMenuView_Previews: PreviewProvider {
    static var previews: some View {
        PlanetTravelMenuView()
    }
}
