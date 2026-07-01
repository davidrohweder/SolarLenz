//
//  IntentStore.swift
//  SolarLenz
//
//  The MVI backbone: a store renders State and receives Intents through a single reducer.
//

/// A unidirectional store.
///
/// Views read the store's observable state and express every change as an `Intent` handed
/// to `send(_:)`. `send` is the *only* place state mutates, so the data flow is easy to
/// reason about and to test: given a state and an intent, the next state is deterministic.
///
/// This is the "Intent → reducer → State" half of MVI; SwiftUI's `@Observable` provides the
/// "State → View" half. Each feature owns a small conforming store (`SolarSystemModel`,
/// `AppRouter`, `VoiceControlStore`, …) rather than one god object.
@MainActor
protocol IntentStore: AnyObject {
    associatedtype Intent
    func send(_ intent: Intent)
}
