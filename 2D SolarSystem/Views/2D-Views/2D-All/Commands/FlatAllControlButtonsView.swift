//
//  FlatAllControlButtonsView.swift
//  2D SolarSystem
//
//  Created by David Rohweder on 11/28/22.
//

import SwiftUI

struct FlatAllControlButtonsView: View {
    let axis_size = 30.0
    @EnvironmentObject var manager: PlanetManager
    var body: some View {
        HStack {
            Spacer()
            Button(action: {
                manager.show_help.toggle()
            }) {
                Image(systemName: "questionmark.circle.fill")
                    .resizable()
                    .frame(width: axis_size, height: axis_size)
            }
            Spacer()
            AllPlanetsOptionsView()
            Spacer()
            Button (action: {
                manager.show_settings.toggle()
            }) {
                Image(systemName: "gearshape.circle.fill")
                    .resizable()
                    .frame(width: axis_size, height: axis_size)
            }
            Spacer()
        }
        .tint(.white)
    }
}

struct _DAllControlButtonsView_Previews: PreviewProvider {
    static var previews: some View {
        FlatAllControlButtonsView()
    }
}
