//
//  PlanetRepository.swift
//  SolarLenz
//
//  Loads the bundled planetary data set without ever force-unwrapping or printing.
//

import Foundation
import os

/// Errors surfaced while loading the bundled planetary data set.
enum PlanetDataError: LocalizedError {
    case resourceMissing(name: String)
    case decodingFailed(underlying: Error)

    var errorDescription: String? {
        switch self {
        case .resourceMissing(let name):
            "Couldn't find \"\(name)\" in the app bundle."
        case .decodingFailed(let error):
            "The planetary data couldn't be read: \(error.localizedDescription)"
        }
    }
}

/// Loads the immutable planetary data set shipped in the app bundle.
///
/// This never force-unwraps, never prints, and surfaces typed errors so callers can react
/// instead of crashing. The data set is read-only content, so there is no save path; user
/// preferences live elsewhere, such as `@AppStorage`.
struct PlanetRepository {

    private let bundle: Bundle
    private let resourceName: String
    private let logger = Logger(subsystem: "edu.psu.djr6005.SolarLenz", category: "PlanetRepository")

    init(bundle: Bundle = .main, resourceName: String = "planetary_data") {
        self.bundle = bundle
        self.resourceName = resourceName
    }

    /// Loads every body, ordered from the Sun outward.
    func loadPlanets() throws -> [Planet] {
        guard let url = bundle.url(forResource: resourceName, withExtension: "json") else {
            logger.error("Planetary data resource missing: \(self.resourceName, privacy: .public)")
            throw PlanetDataError.resourceMissing(name: resourceName)
        }

        do {
            let data = try Data(contentsOf: url)
            let planets = try JSONDecoder().decode([Planet].self, from: data)
            return planets.sorted { $0.id < $1.id }
        } catch {
            logger.error("Failed to decode planetary data: \(error.localizedDescription, privacy: .public)")
            throw PlanetDataError.decodingFailed(underlying: error)
        }
    }
}
