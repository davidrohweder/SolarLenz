//
//  BracketInformationView.swift
//  2D SolarSystem
//
//  Created by David Rohweder on 11/26/22.
//

import SwiftUI

struct BracketInformationView: View {
    let planet: PlanetModel
    @AppStorage("Constants.Preferences.UserAge") var userAge : Int = 0
    var body: some View {
        switch (userAge) {
        case 1..<11:
            Zero_Ten_View(planet: planet)
        case 11..<19:
            Eleven_Eighteen_View()
        default:
            Adult_View()
        }
    }
}

struct BracketInformationView_Previews: PreviewProvider {
    static var previews: some View {
        BracketInformationView(planet: PlanetModel.standard)
    }
}
