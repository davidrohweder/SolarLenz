//
//  SolarSystemModel.swift
//  SolarLenz
//
//  Observable MVI store for the solar-system domain.
//

import Foundation
import Observation

/// Owns the loaded planet data and the current selection.
///
/// Deliberately small: navigation, audio, and voice live in their own stores. State changes
/// flow through `send(_:)`; stored properties are read-only to callers.
@available(iOS 18, *)
@MainActor
@Observable
final class SolarSystemModel: IntentStore {

    /// The things a view can ask the model to do.
    enum Intent: Equatable {
        case load
        case select(Planet)
    }

    private(set) var planets: [Planet] = []
    private(set) var loadError: String?
    private(set) var selectedPlanetID: Int?

    private let repository: PlanetRepository

    init(repository: PlanetRepository = PlanetRepository()) {
        self.repository = repository
        send(.load)
    }

    func send(_ intent: Intent) {
        switch intent {
        case .load:               load()
        case .select(let planet): selectedPlanetID = planet.id
        }
    }

    /// (Re)loads the bundled data set. Failures are captured as a presentable message
    /// instead of crashing — the UI shows a retry affordance.
    private func load() {
        do {
            planets = try repository.loadPlanets()
            loadError = nil
            if selectedPlanetID == nil {
                selectedPlanetID = orbitingBodies.first?.id
            }
        } catch {
            planets = []
            loadError = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }

    // MARK: - Derived views over the data

    var star: Planet? { planets.first(where: { $0.isStar }) }
    var orbitingBodies: [Planet] { planets.filter { !$0.isStar } }

    var selectedPlanet: Planet? {
        guard let id = selectedPlanetID else { return nil }
        return planets.first { $0.id == id }
    }

    /// Longest sidereal period among orbiting bodies — the reference tempo for orbits.
    var referencePeriodDays: Double {
        orbitingBodies.map(\.siderealOrbitPeriodDays).max() ?? 1
    }

    /// Largest semi-major axis — used to normalize on-screen orbit radii.
    var maxSemiMajorAxis: Double {
        orbitingBodies.map(\.semiMajorAxis10e6Km).max() ?? 1
    }

    /// Smallest semi-major axis — used for logarithmic orbit spacing in compact views.
    var minSemiMajorAxis: Double {
        orbitingBodies.map(\.semiMajorAxis10e6Km).filter { $0 > 0 }.min() ?? 1
    }
}
