//
//  AllPlanetsOptionsView.swift
//  2D SolarSystem
//
//  Created by David Rohweder on 11/28/22.
//

import SwiftUI

struct AllPlanetsOptionsView: View {
    let axis_size = 30.0
    @EnvironmentObject var manager: PlanetManager
    var body: some View {
        HStack {
            Button(action: {
                manager.isListening.toggle()
            }) {
                manager.isListening ? Image(systemName: "mic.circle.fill").resizable().frame(width: axis_size, height: axis_size) : Image(systemName: "mic.slash.circle.fill").resizable().frame(width: axis_size, height: axis_size)
            }
        }
        .tint(.white)
    }
}

struct AllPlanetsOptionsView_Previews: PreviewProvider {
    static var previews: some View {
        AllPlanetsOptionsView()
    }
}
