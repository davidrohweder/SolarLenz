//
//  StarryBackgroundView.swift
//  2D SolarSystem
//
//  Created by David Rohweder on 11/21/22.
//

import SwiftUI

struct StarryBackgroundView: View {
    @AppStorage("Constants.Preferences.numStars") var numStars : Int = 2500
    let maxOpacity = 1.0
    let maxSize = 4.0
    let abs_width_rad = (UIScreen.main.bounds.width / 2)
    let abs_height_rad = (UIScreen.main.bounds.height / 2)
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 0.0).fill(
                LinearGradient(gradient: Gradient(colors: [.black, .black,.indigo, .black,.black,]), startPoint: .top, endPoint: .bottom)
            )
            .ignoresSafeArea()
            ForEach(0 ..< numStars, id:\.self) { i in
                StarView(opacity: Double.random(in: 0...maxOpacity), size: Double.random(in: 0...maxSize))
                    .offset(x: Double.random(in: -abs_width_rad...abs_width_rad), y: Double.random(in: -abs_height_rad...abs_height_rad))
            }
        }
        
        
    }
}

struct StarryBackgroundView_Previews: PreviewProvider {
    static var previews: some View {
        StarryBackgroundView()
    }
}
