//
//  AppRouter.swift
//  SolarLenz
//
//  Observable navigation store. Replaces the ~10 loose `show_*` booleans that were
//  scattered across the old PlanetManager.
//

import Observation

/// Drives top-level navigation between the system map, a planet's detail, and AR.
///
/// Navigation changes flow through `send(_:)` (MVI); `mode` is read-only to callers so the
/// only way to move between screens is an explicit `Intent`.
@available(iOS 18, *)
@MainActor
@Observable
final class AppRouter: IntentStore {

    enum Mode: Equatable {
        case solarSystem
        case planetDetail
        case ar
    }

    /// Everything a view can ask the router to do — the single vocabulary of navigation.
    enum Intent: Equatable {
        case showSystem
        case showDetail
        case enterAR
        case presentSettings(Bool)
    }

    private(set) var mode: Mode = .solarSystem

    /// Bound directly by the settings `.sheet`; opened via `.presentSettings(true)` and
    /// closed by SwiftUI's dismissal (the one place a two-way binding is idiomatic).
    var showSettings = false

    func send(_ intent: Intent) {
        switch intent {
        case .showSystem:              mode = .solarSystem
        case .showDetail:              mode = .planetDetail
        case .enterAR:                 mode = .ar
        case .presentSettings(let on): showSettings = on
        }
    }
}
