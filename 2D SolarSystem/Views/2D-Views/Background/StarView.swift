//
//  StarView.swift
//  2D SolarSystem
//
//  Created by David Rohweder on 11/21/22.
//

import SwiftUI

struct StarView: View {
    let opacity: Double
    let size: Double
    var body: some View {
        Circle()
            .fill(.white)
            .frame(width: size, height: size)
            .opacity(opacity)
    }
}

struct StarView_Previews: PreviewProvider {
    static var previews: some View {
        StarView(opacity: 0.0, size: 0.0)
    }
}
