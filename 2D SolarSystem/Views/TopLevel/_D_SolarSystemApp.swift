//
//  _D_SolarSystemApp.swift
//  2D SolarSystem
//
//  Created by David Rohweder on 10/30/22.
//

import SwiftUI

/// The application entry point.
///
/// The deployment target is iOS 18, so there is a single, modern experience:
/// the Observation-based `SolarLenz` app. The legacy `PlanetManager`/`ContentView`
/// tree has been retired.
@main
struct _D_SolarSystemApp: App {
    var body: some Scene {
        WindowGroup {
            SolarLenzRootView()
        }
    }
}
