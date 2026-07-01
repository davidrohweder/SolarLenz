//
//  ARExperienceStore.swift
//  SolarLenz
//
//  Observable state for the AR experience: the placement phase, plus which planet (if any)
//  is currently being inspected close-up or followed in its live orbit.
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

    enum FocusMode: Equatable {
        case inspect
        case track
    }

    enum Intent: Equatable {
        case systemPlaced
        case inspect(Int?)   // pull a planet close while the system stays anchored
        case track(Int?)     // follow a planet's live orbit with the system moving around it
        case releaseFocus
        case reset
    }

    private(set) var phase: Phase
    /// The focused planet id, or nil when viewing the whole system.
    private(set) var focusedID: Int?
    private(set) var focusMode: FocusMode = .inspect

    init(isSupported: Bool = ARWorldTrackingConfiguration.isSupported) {
        phase = isSupported ? .placing : .unsupported
    }

    func send(_ intent: Intent) {
        guard phase != .unsupported else { return }
        switch intent {
        case .systemPlaced: phase = .exploring
        case .inspect(let id):
            focusedID = id
            focusMode = .inspect
        case .track(let id):
            focusedID = id
            focusMode = id == nil ? .inspect : .track
        case .releaseFocus:
            focusedID = nil
            focusMode = .inspect
        case .reset:
            phase = .placing
            focusedID = nil
            focusMode = .inspect
        }
    }
}
