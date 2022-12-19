//
//  SetUserAgeView.swift
//  2D SolarSystem
//
//  Created by David Rohweder on 11/26/22.
//

import SwiftUI

struct SetUserAgeView: View {
    @EnvironmentObject var manager: PlanetManager
    var body: some View {
        ZStack {
            StarryBackgroundView()
            VStack {
                SpecialTextView(text: "Please Enter Your Age")
                Spacer()
                AgePickerView()
                Spacer()
            }
        }
    }
}

struct SetUserAgeView_Previews: PreviewProvider {
    static var previews: some View {
        SetUserAgeView()
    }
}
