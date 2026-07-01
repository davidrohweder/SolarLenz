//
//  ARExperienceStore.swift
//  SolarLenz
//
//  Observable state for the AR experience: the placement phase, plus which planet (if any)
//  is currently focused — flown to the foreground while the rest of the system keeps orbiting.
//

import ARKit
import Observation

@available(iOS 18, *)
@MainActor
@Observable
final class ARExperienceStore: IntentStore {

    enum Phase: Equatable {
        case unsupported     // device / Simulator can't world-track
        case placing         // bringing the fixed, large system in front of the user
        case exploring       // system is anchored and interactive
    }

    enum Intent: Equatable {
        case systemPlaced
        case focus(Int?)     // focus a planet by id, or nil to return to the system view
        case reset
    }

    private(set) var phase: Phase
    /// The focused planet id, or nil when viewing the whole system.
    private(set) var focusedID: Int?

    init(isSupported: Bool = ARWorldTrackingConfiguration.isSupported) {
        phase = isSupported ? .placing : .unsupported
    }

    func send(_ intent: Intent) {
        guard phase != .unsupported else { return }
        switch intent {
        case .systemPlaced: phase = .exploring
        case .focus(let id): focusedID = id
        case .reset:         phase = .placing; focusedID = nil
        }
    }
}
