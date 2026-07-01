//
//  SolarLenzRootView.swift
//  SolarLenz
//
//  The app root. Owns the observable stores, injects them into the environment, routes
//  between onboarding / map / detail / AR, and coordinates voice + ambient audio.
//

import SwiftUI

@available(iOS 18, *)
struct SolarLenzRootView: View {
    @AppStorage(PreferenceKey.audioEnabled) private var audioEnabled = false
    @Environment(\.scenePhase) private var scenePhase

    @State private var model = SolarSystemModel()
    @State private var router = AppRouter()
    @State private var voice = VoiceControlStore()
    @State private var audio = AmbientAudioStore()

    var body: some View {
        ZStack {
            StarFieldView()

            if let error = model.loadError {
                ErrorStateView(message: error) { model.send(.load) }
            } else {
                routedContent
            }
        }
        .preferredColorScheme(.dark)
        .environment(model)
        .environment(router)
        .environment(voice)
        .onAppear {
            configure()
            updateAudio()
        }
        .onChange(of: audioEnabled) { _, _ in updateAudio() }
        .onChange(of: scenePhase) { _, _ in updateAudio() }
        .onChange(of: voice.isListening) { _, _ in updateAudio() }
    }

    /// The single source of truth for whether ambient audio should be playing: only when it's
    /// enabled, the app is foreground-active, and the mic isn't capturing. Any of those going
    /// false pauses playback (and releases the audio session), so nothing lingers when the app
    /// is backgrounded or dismissed.
    private func updateAudio() {
        let shouldPlay = audioEnabled && scenePhase == .active && !voice.isListening
        if shouldPlay { audio.play() } else { audio.pause() }
    }

    @ViewBuilder
    private var routedContent: some View {
        switch router.mode {
        case .solarSystem:
            SolarSystemScreen()
                .transition(.opacity)
        case .planetDetail:
            PlanetDetailScreen()
                .transition(.move(edge: .bottom).combined(with: .opacity))
        case .ar:
            ARSolarSystemScreen()
                .transition(.opacity)
        }
    }

    /// One-time wiring: teach the voice store the planet vocabulary, route its commands into
    /// store intents, and start ambient audio if enabled.
    private func configure() {
        let model = self.model
        let router = self.router

        voice.planetNames = model.orbitingBodies.map { $0.name.lowercased() }
        voice.onCommand = { command in
            switch command {
            case .select(let name):
                guard let planet = model.planets.first(where: { $0.name.lowercased() == name }) else { return }
                withAnimation(Theme.Motion.interactive) {
                    model.send(.select(planet))
                    router.send(.showSystem)
                }
            case .inspect(let name):
                guard let planet = model.planets.first(where: { $0.name.lowercased() == name }) else { return }
                model.send(.select(planet))
                withAnimation(Theme.Motion.transition) { router.send(.showDetail) }
            case .openDetail:
                guard model.selectedPlanet != nil else { return }
                withAnimation(Theme.Motion.transition) { router.send(.showDetail) }
            case .enterAR:
                withAnimation(Theme.Motion.transition) { router.send(.enterAR) }
            case .backToMap:
                withAnimation(Theme.Motion.transition) { router.send(.showSystem) }
            }
        }
    }
}
