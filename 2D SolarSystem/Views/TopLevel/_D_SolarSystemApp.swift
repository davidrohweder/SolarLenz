//
//  _D_SolarSystemApp.swift
//  2D SolarSystem
//
//  Created by David Rohweder on 10/30/22.
//

import SwiftUI

@main
struct _D_SolarSystemApp: App {
    @AppStorage("Constants.Preferences.AudioEnabled") var audioEnabled : Bool = true
    @AppStorage("Constants.Preferences.numStars") var numStars : Int = 2500
    @StateObject var manager: PlanetManager = PlanetManager()
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear() {
                    manager.allowAudio = audioEnabled
                    numStars = manager.numStars
                }
                .onChange(of: manager.lowPower) { _ in
                    numStars = manager.numStars
                }
                .preferredColorScheme(.dark)
                .environmentObject(manager)
        }
    }
}
