//
//  SelectedPlanetView.swift
//  2D SolarSystem
//
//  Created by David Rohweder on 11/16/22.
//

import SwiftUI
import SceneKit

struct SelectedPlanetView: View {
    @EnvironmentObject var manager: PlanetManager
    @State private var background_opacity = 0.0
    @State private var frame_grow = false
    var planet: PlanetModel
    var body: some View {
        ZStack {
            StarryBackgroundView()
                .opacity(background_opacity)
            VStack {
                SpecialTextView(text: "Viewing: " + planet.name.capitalized)
                Spacer()
                Load3dPlanetView(_manager: manager)
                    .frame(width: self.frame_grow ? UIScreen.main.bounds.width : 0, height: self.frame_grow ? UIScreen.main.bounds.height / 2 : 0)
                Spacer()
                PlanetOptionsView()
            }
            .sheet(isPresented: $manager.show_info) {
                PlanetInformationView(planet: manager.currentPlanet)
            }
            .onAppear(perform: {
                withAnimation(.easeInOut(duration: 2.0)) {
                    self.background_opacity = 1.0
                    self.frame_grow.toggle()
                }
            })
            
        }
    }
}

struct SelectedPlanetView_Previews: PreviewProvider {
    static var previews: some View {
        SelectedPlanetView(planet: PlanetModel.standard)
    }
}
