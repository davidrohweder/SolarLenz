//
//  PlanetPathView.swift
//  2D SolarSystem
//
//  Created by David Rohweder on 10/30/22.
//

import SwiftUI

struct PlanetPathView: View {
    @EnvironmentObject var manager: PlanetManager
    @State var movePlanet = false
    var body: some View {
        ZStack {
            ForEach(manager.planets) { planet in
                Arc(startAngle: .degrees(35.0 - Double(planet.offsetAngle!)), endAngle: .degrees(360.0 - Double(planet.offsetAngle!)), clockwise: true)
                    .stroke(lineWidth: 1)
                    .foregroundColor(planet.color)
                    .frame(width: planet.pathRadius, height: planet.pathRadius)
                    .rotationEffect(.degrees(movePlanet ? 0 : 360))
                    .animation(Animation.linear(duration: planet.orbitTime).repeatForever(autoreverses: false))
                    .onAppear() {
                        self.movePlanet.toggle()
                    }
            }
        }
    }
}

struct PlanetPathView_Previews: PreviewProvider {
    static var previews: some View {
        PlanetPathView()
    }
}
