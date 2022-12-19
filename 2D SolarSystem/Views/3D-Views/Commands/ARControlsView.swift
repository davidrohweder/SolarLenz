//
//  ARControlsView.swift
//  2D SolarSystem
//
//  Created by David Rohweder on 11/26/22.
//

import SwiftUI

struct ARControlsView: View {
    let axis_size = 30.0
    @EnvironmentObject var manager: PlanetManager
    var body: some View {
        HStack {
            Spacer()
            Button(action: {
                if manager.currentPlanet.id - 1 < 0 {
                    manager.currentPlanet = manager.planets[manager.planets.count - 1]
                } else {
                    manager.currentPlanet = manager.planets[manager.currentPlanet.id - 1]
                }
            }) {
                Image(systemName: "arrowshape.turn.up.left.circle.fill")
                    .resizable()
                    .frame(width: axis_size, height: axis_size)
            }
            Spacer()
            Button(action: {
                if manager.currentPlanet.id + 1 > manager.planets.count - 1 {
                    manager.currentPlanet = manager.planets[0]
                } else {
                    manager.currentPlanet = manager.planets[manager.currentPlanet.id + 1]
                }
            }) {
                Image(systemName: "arrowshape.turn.up.right.circle.fill")
                    .resizable()
                    .frame(width: axis_size, height: axis_size)
            }
            Spacer()
            AllPlanetsOptionsView()
            Spacer()
            Button(action: {
                manager.show_dim = .dim_two_single
            }) {
                Image(systemName: "x.circle.fill")
                    .resizable()
                    .frame(width: axis_size, height: axis_size)
            }
            Spacer()
        }
        .tint(.white)
    }
}

struct ARControlsView_Previews: PreviewProvider {
    static var previews: some View {
        ARControlsView()
    }
}
