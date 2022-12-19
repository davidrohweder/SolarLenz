//
//  PlanetInformationView.swift
//  2D SolarSystem
//
//  Created by David Rohweder on 11/16/22.
//

import SwiftUI

struct PlanetInformationView: View {
    let planet: PlanetModel
    var body: some View {
        ScrollView(.vertical) {
            VStack {
                SpecialTextView(text: planet.name.capitalized)
                Spacer(minLength: 100)
                BracketInformationView(planet: planet)
                Spacer(minLength: 100)
                DismissView()
            }
        }
    }
}

struct PlanetInformationView_Previews: PreviewProvider {
    static var previews: some View {
        PlanetInformationView(planet: PlanetModel.standard)
    }
}
