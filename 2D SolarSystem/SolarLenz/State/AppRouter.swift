//
//  AppRouter.swift
//  SolarLenz
//
//  Observable navigation store for top-level MVI routing.
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
        case trackInAR(Int?)
        case releaseARTracking
        case presentSettings(Bool)
        case presentCommandGuide(Bool)
    }

    private(set) var mode: Mode = .solarSystem
    private(set) var arTrackingPlanetID: Int?

    /// Read by the settings sheet. Views open and close it by sending `.presentSettings`.
    private(set) var showSettings = false
    private(set) var showCommandGuide = false

    func send(_ intent: Intent) {
        switch intent {
        case .showSystem:              mode = .solarSystem
        case .showDetail:              mode = .planetDetail
        case .enterAR:                 arTrackingPlanetID = nil; mode = .ar
        case .trackInAR(let id):       arTrackingPlanetID = id; mode = .ar
        case .releaseARTracking:       arTrackingPlanetID = nil; mode = .ar
        case .presentSettings(let on): showSettings = on
        case .presentCommandGuide(let on):
            showCommandGuide = on
        }
    }
}
