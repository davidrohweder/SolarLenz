//
//  AR_Main.swift
//  2D SolarSystem
//
//  Created by David Rohweder on 11/16/22.
//

import SwiftUI

struct AR_Main: View {
    @EnvironmentObject var manager: PlanetManager
    var body: some View {
        ZStack {
            VStack () {
                ARTopControlsView()
                Spacer()
                ViewController(_manager: manager)
                Spacer()
                ARControlsView()
            }
            .sheet(isPresented: $manager.show_AR_commands) {
                ARCommandView()
                    .presentationDetents([.height(UIScreen.main.bounds.height * 0.75 )])
            }
            .sheet(isPresented: $manager.show_info) {
                PlanetInformationView(planet: manager.currentPlanet)
            }
        }
    }
}

struct AR_Main_Previews: PreviewProvider {
    static var previews: some View {
        AR_Main()
    }
}
