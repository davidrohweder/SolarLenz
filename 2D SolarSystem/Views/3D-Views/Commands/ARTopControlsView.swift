//
//  ARTopControlsView.swift
//  2D SolarSystem
//
//  Created by David Rohweder on 11/28/22.
//

import SwiftUI

struct ARTopControlsView: View {
    @EnvironmentObject var manager: PlanetManager
    let axis_size = 30.0
    var body: some View {
        HStack {
            Spacer(minLength: UIScreen.main.bounds.width / 1.5)
            Button(action: {
                manager.show_info.toggle()
            }) {
                Image(systemName: "info.circle.fill")
                    .resizable()
                    .frame(width: 30.0, height: 30.0)
            }
            Spacer()
            Button(action: {
                manager.show_AR_commands.toggle()
            }) {
                Image(systemName: "helm")
                    .resizable()
                    .frame(width: axis_size, height: axis_size)
                    .offset(x: -10.0)

            }
        }
        .tint(.white)
    }
}

struct ARTopControlsView_Previews: PreviewProvider {
    static var previews: some View {
        ARTopControlsView()
    }
}
