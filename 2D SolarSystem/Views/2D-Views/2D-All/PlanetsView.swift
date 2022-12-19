//
//  PlanetsView.swift
//  2D SolarSystem
//
//  Created by David Rohweder on 10/30/22.
//

import SwiftUI

struct PlanetsView: View {
    @EnvironmentObject var manager: PlanetManager
    var body: some View {
        ZStack {
            ForEach(manager.planets) { planet in
                SinglePlanetView(planet: planet)
            }
        }
    }
}

struct PlanetsView_Previews: PreviewProvider {
    static var previews: some View {
        PlanetsView()
    }
}
