//
//  AppInfoView.swift
//  2D SolarSystem
//
//  Created by David Rohweder on 11/28/22.
//

import SwiftUI

struct AppInfoView: View {
    var body: some View {
        VStack {
            SpecialTextView(text: "Help and Usage")
            Form {
                Section {
                    Text("Click on any of the planet images to see more information about that selected planet.")
                    Text("Click the microphone icon to enable the Voice Command feature.")
                    Text("While viewing a planet, click the camera icon to view that planet in the interactive AR mode.")
                } header: {
                    Text("General Usage")
                }
                Section {
                    Text("Say 'Go' to navigate to a specific planet.")
                    Text("Say 'Show' to show information about a planet.")
                    Text("Say 'Enable' to activate the AR feature of seing the planets.")
                    Text("After saying either of the three commands above say the planet name that you would like to view.")
                } header: {
                    Text("Voice Commands")
                }
                Section {
                    Text("Once in AR mode, in the top right the helm icon brings the planetary directions view.")
                    Text("While AR Directions are enabled you will not be able to tap planets to change your current planet.")
                    Text("The info icon next to the helm icon will display information about the current planet.")
                    Text("In the bottom left, there are left and right arrow buttons to horizontally move left or right though the planets.")
                } header: {
                    Text("AR Usage")
                }
            }
            DismissView()
        }
    }
}

struct AppInfoView_Previews: PreviewProvider {
    static var previews: some View {
        AppInfoView()
    }
}
