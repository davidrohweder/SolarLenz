//
//  Main_Flat.swift
//  2D SolarSystem
//
//  Created by David Rohweder on 11/16/22.
//

import SwiftUI

struct Main_Flat: View {
    @EnvironmentObject var manager: PlanetManager
    @AppStorage("Constants.Preferences.isArc") var isArc : Bool = true
    var body: some View {
        ZStack {
            StarryBackgroundView()
            VStack {
                SpecialTextView(text: "SolarLenz")
                    .bold()
                    .italic()
                    .font(.title)
                Spacer()
                ZStack {
                    if !isArc {
                        PlanetCircleView()
                        
                    }
                    PlanetPathView()
                    PlanetsView()
                }
                Spacer()
                FlatAllControlButtonsView()
            }
            .sheet(isPresented: $manager.show_settings) {
                AppSettingsView()
            }
            .sheet(isPresented: $manager.show_help) {
                AppInfoView()
            }
        }
    }
}

struct Main_Flat_Previews: PreviewProvider {
    static var previews: some View {
        Main_Flat()
    }
}
