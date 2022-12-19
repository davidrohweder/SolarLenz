//
//  SinglePlanetView.swift
//  2D SolarSystem
//
//  Created by David Rohweder on 10/30/22.
//

import SwiftUI

struct SinglePlanetView: View {
    @EnvironmentObject var manager: PlanetManager
    @State var movePlanet = false
    let planet: PlanetModel
    var body: some View {
        
        let tapGesture = TapGesture()
            .onEnded {
                tapRecv()
            }
        
        Image("2d-" + planet.name.lowercased())
            .resizable()
            .frame(width: 25, height: 20)
            .offset(x: planet.offsetPoint!.x, y: planet.offsetPoint!.y)
            .rotationEffect(.degrees(movePlanet ? 0 : 360))
            .animation(Animation.linear(duration: planet.orbitTime).repeatForever(autoreverses: false))
            .gesture(tapGesture)
            .onAppear() {
                self.movePlanet.toggle()
            }
    }
    
    func tapRecv() {
        manager.currentPlanet = self.planet
        manager.show_dim = .dim_two_single
    }
}

struct SinglePlanetView_Previews: PreviewProvider {
    static var previews: some View {
        SinglePlanetView(planet: PlanetModel.standard)
    }
}
