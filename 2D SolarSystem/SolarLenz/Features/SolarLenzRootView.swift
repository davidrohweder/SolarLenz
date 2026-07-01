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
        .sheet(isPresented: commandGuideBinding) {
            VoiceCommandGuideSheet(isListening: voice.isListening) {
                voice.toggle()
            }
        }
        .onAppear {
            configure()
            updateAudio()
        }
        .onChange(of: audioEnabled) { _, _ in updateAudio() }
        .onChange(of: scenePhase) { _, _ in updateAudio() }
        .onChange(of: voice.isListening) { _, _ in updateAudio() }
    }

    private var commandGuideBinding: Binding<Bool> {
        Binding(
            get: { router.showCommandGuide },
            set: { router.send(.presentCommandGuide($0)) }
        )
    }

    /// The single source of truth for whether ambient audio should be playing.
    private func updateAudio() {
        let shouldPlay = audioEnabled && scenePhase == .active
        if shouldPlay {
            audio.play(ducked: voice.isListening, allowsRecording: voice.isListening)
        } else {
            audio.pause()
        }
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

        voice.planetNames = model.planets.map { $0.name.lowercased() }
        voice.onCommand = { command in
            handleVoiceCommand(command, model: model, router: router)
        }
    }

    private func handleVoiceCommand(_ command: VoiceCommand, model: SolarSystemModel, router: AppRouter) {
        switch command {
        case .select(let name):
            guard let planet = findPlanet(named: name, in: model) else { return }
            withAnimation(Theme.Motion.interactive) {
                model.send(.select(planet))
                router.send(.showSystem)
            }
        case .inspect(let name):
            guard let planet = findPlanet(named: name, in: model) else { return }
            model.send(.select(planet))
            withAnimation(Theme.Motion.transition) { router.send(.showDetail) }
        case .focusInAR(let name):
            let planet = name.flatMap { findPlanet(named: $0, in: model) } ?? model.selectedPlanet ?? model.orbitingBodies.first
            guard let planet else { return }
            model.send(.select(planet))
            withAnimation(Theme.Motion.transition) { router.send(.focusInAR(planet.id)) }
        case .openDetail:
            guard model.selectedPlanet != nil else { return }
            withAnimation(Theme.Motion.transition) { router.send(.showDetail) }
        case .enterAR:
            withAnimation(Theme.Motion.transition) { router.send(.enterAR) }
        case .backToMap:
            withAnimation(Theme.Motion.transition) { router.send(.showSystem) }
        case .nextPlanet:
            selectRelativePlanet(1, model: model, router: router)
        case .previousPlanet:
            selectRelativePlanet(-1, model: model, router: router)
        case .releaseARFocus:
            withAnimation(Theme.Motion.interactive) { router.send(.releaseARFocus) }
        case .setAudio(let enabled):
            audioEnabled = enabled
            updateAudio()
        case .showHelp:
            router.send(.presentCommandGuide(true))
        case .stopListening:
            break
        }
    }

    private func findPlanet(named name: String, in model: SolarSystemModel) -> Planet? {
        model.planets.first { $0.name.lowercased() == name.lowercased() }
    }

    private func selectRelativePlanet(_ delta: Int, model: SolarSystemModel, router: AppRouter) {
        let bodies = model.orbitingBodies
        guard !bodies.isEmpty else { return }
        let current = model.selectedPlanetID.flatMap { id in bodies.firstIndex { $0.id == id } } ?? 0
        let next = (current + delta + bodies.count) % bodies.count
        let planet = bodies[next]
        withAnimation(Theme.Motion.interactive) {
            model.send(.select(planet))
            if router.mode == .ar {
                router.send(.focusInAR(planet.id))
            }
        }
    }
}

@available(iOS 18, *)
private struct VoiceCommandGuideSheet: View {
    @Environment(\.dismiss) private var dismiss
    let isListening: Bool
    let toggleListening: () -> Void

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Button {
                        toggleListening()
                    } label: {
                        Label(isListening ? "Stop Listening" : "Start Listening", systemImage: isListening ? "mic.fill" : "mic")
                    }
                }

                ForEach(VoiceCommandRegistry.guideSections) { section in
                    Section(section.title) {
                        ForEach(section.examples, id: \.self) { example in
                            Text(example)
                        }
                    }
                }
            }
            .navigationTitle("Voice Commands")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}
