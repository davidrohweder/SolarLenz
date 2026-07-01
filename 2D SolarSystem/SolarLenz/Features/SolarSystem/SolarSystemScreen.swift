//
//  SolarSystemScreen.swift
//  SolarLenz
//
//  The main 2D map: title, animated orbits, and a floating Liquid Glass control bar.
//

import SwiftUI

@available(iOS 18, *)
struct SolarSystemScreen: View {
    @Environment(SolarSystemModel.self) private var model
    @Environment(AppRouter.self) private var router
    @Environment(VoiceControlStore.self) private var voice

    var body: some View {
        @Bindable var router = router

        VStack(spacing: 0) {
            header
            OrbitCanvasView { planet in
                withAnimation(Theme.Motion.interactive) { model.send(.select(planet)) }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            if voice.isListening { listeningIndicator }
            controlBar
        }
        .sheet(isPresented: $router.showSettings) { SettingsSheet() }
    }

    private var listeningIndicator: some View {
        Label(voice.transcript.isEmpty ? "Listening… try “go to Mars”" : voice.transcript,
              systemImage: "waveform")
            .font(Theme.Typography.caption)
            .foregroundStyle(.white)
            .padding(.horizontal, Theme.Spacing.m)
            .frame(height: 36)
            .glassPill()
            .padding(.bottom, Theme.Spacing.s)
            .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    private var header: some View {
        VStack(spacing: 2) {
            Text("SolarLenz").font(Theme.Typography.display)
            Text("Tap a planet to explore")
                .font(Theme.Typography.caption)
                .foregroundStyle(.secondary)
        }
        .foregroundStyle(.white)
        .padding(.top, Theme.Spacing.s)
    }

    private var controlBar: some View {
        HStack(spacing: Theme.Spacing.m) {
            iconButton(systemImage: "arkit", label: "AR") { router.send(.enterAR) }

            if let planet = model.selectedPlanet {
                Button { router.send(.showDetail) } label: {
                    Label("Explore \(planet.displayName)", systemImage: "sparkles")
                        .font(.headline)
                        .padding(.horizontal, Theme.Spacing.l)
                        .frame(height: 44)
                }
                .glassPill()
                .transition(.scale.combined(with: .opacity))
            }

            micButton

            iconButton(systemImage: "gearshape", label: "Settings") { router.send(.presentSettings(true)) }
        }
        .foregroundStyle(.white)
        .padding(.bottom, Theme.Spacing.l)
        .animation(Theme.Motion.interactive, value: model.selectedPlanetID)
        .animation(Theme.Motion.interactive, value: voice.isListening)
    }

    /// Toggles voice control. Turns accent-colored and pulses while listening.
    private var micButton: some View {
        Button { voice.toggle() } label: {
            Image(systemName: voice.isListening ? "mic.fill" : "mic")
                .font(.title3)
                .foregroundStyle(voice.isListening ? Theme.Palette.accent : .white)
                .frame(width: 44, height: 44)
        }
        .glassPill()
        .accessibilityLabel(voice.isListening ? "Stop voice control" : "Start voice control")
    }

    private func iconButton(systemImage: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.title3)
                .frame(width: 44, height: 44)
        }
        .glassPill()
        .accessibilityLabel(label)
    }
}

/// A minimal, self-contained settings sheet. Reads the same `@AppStorage` keys the rest
/// of the app uses, so preferences stay consistent without the old god-object.
@available(iOS 18, *)
struct SettingsSheet: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage(PreferenceKey.audioEnabled) private var audioEnabled = false
    @AppStorage(PreferenceKey.userAge) private var userAge = 25

    var body: some View {
        NavigationStack {
            Form {
                Section("Audio") {
                    Toggle("Ambient sound", isOn: $audioEnabled)
                }
                Section("Personalization") {
                    Picker("Your age", selection: $userAge) {
                        ForEach(4...99, id: \.self) { Text("\($0) years").tag($0) }
                    }
                    LabeledContent("Facts tailored for", value: AgeBracket(age: userAge).title)
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

@available(iOS 18, *)
#Preview("Solar System Map") {
    ZStack {
        StarFieldView()
        SolarSystemScreen()
    }
    .environment(SolarSystemModel())
    .environment(AppRouter())
}
