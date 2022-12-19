//
//  ARCommandView.swift
//  2D SolarSystem
//
//  Created by David Rohweder on 11/28/22.
//

import SwiftUI

struct ARCommandView: View {
    var body: some View {
        VStack {
            SpecialTextView(text: "Welcome to the AR Command Center")
            Spacer()
            SmallOptionsARView()
            Spacer()
            DismissView()
        }
    }
}

struct ARCommandView_Previews: PreviewProvider {
    static var previews: some View {
        ARCommandView()
    }
}
