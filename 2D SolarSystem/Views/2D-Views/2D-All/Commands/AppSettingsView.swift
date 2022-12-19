//
//  AppSettingsView.swift
//  2D SolarSystem
//
//  Created by David Rohweder on 11/28/22.
//

import SwiftUI

struct AppSettingsView: View {
    @AppStorage("Constants.Preferences.AudioEnabled") var audioEnabled : Bool = true
    @AppStorage("Constants.Preferences.isArc") var isArc : Bool = true
    @EnvironmentObject var manager: PlanetManager
    var body: some View {
        VStack {
            SpecialTextView(text: "Settings")
            Form {
                Section {
                    AgePickerView()
                } header: {
                    Text("Age Picker Section")
                }
                Section {
                    Picker("AudioEnabledSelection", selection: $audioEnabled) {
                        Text("Disable Audio").tag(false)
                        Text("Enable Audio").tag(true)
                    }
                    .onChange(of: audioEnabled) { _ in
                        manager.allowAudio = audioEnabled
                    }
                    .pickerStyle(.segmented)
                } header: {
                    Text("Audio Enabled Selection")
                }
                Section {
                    Picker("Planet Path Options", selection: $isArc) {
                        Text("Trailing Arc").tag(true)
                        Text("Circular Path").tag(false)
                    }
                    .pickerStyle(.segmented)
                } header: {
                    Text("Planet Path Options")
                }
                Section {
                    Picker("Power Mode", selection: $manager.lowPower) {
                        Text("Low Power").tag(true)
                        Text("Regular").tag(false)
                    }
                    .pickerStyle(.segmented)
                } header: {
                    Text("Low Power Mode")
                }
            }
            DismissView()
        }
    }
}

struct AppSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        AppSettingsView()
    }
}
