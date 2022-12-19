//
//  PlanetCircleView.swift
//  2D SolarSystem
//
//  Created by David Rohweder on 11/29/22.
//

import SwiftUI

struct PlanetCircleView: View {
    @EnvironmentObject var manager: PlanetManager
    var body: some View {
        ZStack {
            ForEach(manager.planets) { planet in
                Circle()
                    .stroke()
                    .frame(width: planet.pathRadius, height: planet.pathRadius)
                    .foregroundColor(planet.color)
            }
        }
    }
}

struct PlanetCircleView_Previews: PreviewProvider {
    static var previews: some View {
        PlanetCircleView()
    }
}
