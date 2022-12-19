//
//  SmallOptionsARView.swift
//  2D SolarSystem
//
//  Created by David Rohweder on 11/28/22.
//

import SwiftUI

struct SmallOptionsARView: View {
    @EnvironmentObject var manager: PlanetManager
    let axis_size = 30.0
    var body: some View {
        Form {
            Section {
                Picker("DirectionsEnabled", selection: $manager.enable_AR_directions) {
                    Text("Disable Directions").tag(false)
                    Text("Enable Directions").tag(true)
                }
                .pickerStyle(.segmented)
            } header: {
                Text("Enable AR Directions")
            }
            if manager.enable_AR_directions {
                Section {
                    Button(action: {
                        manager.expand_AR_help.toggle()
                    }) {
                        Text(manager.expand_AR_help ? "Show Less" : "Show More")
                    }
                    if manager.expand_AR_help {
                        Text("When AR directions are enabled tapping planets will prompt directions rather than changing planets.")
                        Text("To only change the current AR planet on taps you will need to disable AR directions.")
                    }
                } header: {
                    HStack {
                        Text("Usage Notes")
                        Image(systemName: "info.circle.fill")
                    }
                }
                Section {
                    PlanetTravelMenuView()
                    Text("Travel Distance is: \(manager.calcPlanetDistance(), specifier: "%.3f") lighyears.")
                    DirectionsButtonView()
                } header: {
                    HStack {
                        Text("Planets To Travel To")
                        Image(systemName: "paperplane.circle.fill")
                    }
                    .tint(.white)
                }
            }
        }
    }
}

struct SmallOptionsARView_Previews: PreviewProvider {
    static var previews: some View {
        SmallOptionsARView()
    }
}
