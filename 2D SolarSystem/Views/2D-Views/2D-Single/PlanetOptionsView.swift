//
//  PlanetOptionsView.swift
//  2D SolarSystem
//
//  Created by David Rohweder on 11/21/22.
//

import SwiftUI

struct PlanetOptionsView: View {
    let axis_size = 30.0
    @EnvironmentObject var manager: PlanetManager
    var body: some View {
        HStack {
            Spacer()
            Button(action: {
                manager.show_info.toggle()
            }) {
                Image(systemName: "info.circle.fill")
                    .resizable()
                    .frame(width: axis_size, height: axis_size)
            }
            Spacer()
            Button(action: {
                manager.show_dim = .dim_three
            }) {
                Image(systemName: "camera.circle.fill")
                    .resizable()
                    .frame(width: axis_size, height: axis_size)
            }
            Spacer()
            AllPlanetsOptionsView()
            Spacer()
            Button(action: {
                manager.show_dim = .dim_two
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

struct PlanetOptionsView_Previews: PreviewProvider {
    static var previews: some View {
        PlanetOptionsView()
    }
}
