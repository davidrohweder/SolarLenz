//
//  PlanetDataTests.swift
//  2D SolarSystemTests
//
//  Codable key-mapping and repository loading — the layer that decides what every user sees.
//

import Testing
import Foundation
@testable import _D_SolarSystem

/// Anchors `Bundle(for:)` to the test bundle so the shipped catalog can be loaded.
private final class BundleToken {}

@Suite("Planet data")
struct PlanetDataTests {

    @Test("Decodes the NASA fact-sheet keys (units, ring flag, optional gravity)")
    func codableKeyMapping() throws {
        let json = Data("""
        [{
          "id": 3, "name": "earth", "colorName": "blue", "scale": 0.3,
          "distanceFromSun": 149600000.0, "mass10_24Kg": 5.9724,
          "volumetricMeanRadiusKm": 6371, "meanDensityKgM3": 5514,
          "escapeVelocityKmS": 11.19, "surfaceGravityMS2": 9.8,
          "blackBodyTemperatureK": 254, "numberOfNaturalSatellites": 1,
          "planetaryRingSystem": false, "semimajorAxis10_6Km": 149.6,
          "siderealOrbitPeriodDays": 365.256, "orbitEccentricity": 0.0167,
          "lengthOfDayHrs": 24, "obliquityToOrbitDeg": 23.44
        }]
        """.utf8)
        let earth = try #require(try JSONDecoder().decode([Planet].self, from: json).first)
        #expect(earth.name == "earth")
        #expect(earth.displayName == "Earth")
        #expect(earth.mass10e24Kg == 5.9724)
        #expect(earth.semiMajorAxis10e6Km == 149.6)
        #expect(earth.hasRingSystem == false)
        #expect(earth.surfaceGravityMS2 == 9.8)
        #expect(earth.isStar == false)
    }

    @Test("surfaceGravityMS2 decodes as nil when the source omits it")
    func optionalGravity() throws {
        let json = Data("""
        [{ "id": 5, "name": "jupiter", "colorName": "brown", "scale": 0.8,
           "distanceFromSun": 778600000.0, "mass10_24Kg": 1898.19,
           "volumetricMeanRadiusKm": 69911, "meanDensityKgM3": 1326,
           "escapeVelocityKmS": 59.5, "blackBodyTemperatureK": 109.9,
           "numberOfNaturalSatellites": 67, "planetaryRingSystem": true,
           "semimajorAxis10_6Km": 778.57, "siderealOrbitPeriodDays": 4332.589,
           "orbitEccentricity": 0.0489, "lengthOfDayHrs": 9.9259, "obliquityToOrbitDeg": 3.13 }]
        """.utf8)
        let jupiter = try #require(try JSONDecoder().decode([Planet].self, from: json).first)
        #expect(jupiter.surfaceGravityMS2 == nil)
        #expect(jupiter.hasRingSystem == true)
    }

    @Test("Earth's derived distance in AU is ~1.0")
    func derivedDistanceAU() throws {
        let json = Data("""
        [{ "id": 3, "name": "earth", "colorName": "blue", "scale": 0.3,
           "distanceFromSun": 149600000.0, "mass10_24Kg": 5.9724,
           "volumetricMeanRadiusKm": 6371, "meanDensityKgM3": 5514,
           "escapeVelocityKmS": 11.19, "surfaceGravityMS2": 9.8,
           "blackBodyTemperatureK": 254, "numberOfNaturalSatellites": 1,
           "planetaryRingSystem": false, "semimajorAxis10_6Km": 149.6,
           "siderealOrbitPeriodDays": 365.256, "orbitEccentricity": 0.0167,
           "lengthOfDayHrs": 24, "obliquityToOrbitDeg": 23.44 }]
        """.utf8)
        let earth = try #require(try JSONDecoder().decode([Planet].self, from: json).first)
        #expect(abs(earth.distanceInAU - 1.0) < 0.01)
    }

    @Test("The shipped catalog loads, is Sun-first, and is ordered by id")
    func shippedCatalogLoads() throws {
        let planets = try PlanetRepository(bundle: Bundle(for: BundleToken.self)).loadPlanets()
        #expect(planets.count == 9)
        #expect(planets.first?.isStar == true)
        #expect(planets.map(\.id) == planets.map(\.id).sorted())
        #expect(planets.contains { $0.name == "earth" })
    }

    @Test("A missing resource throws a typed, presentable error instead of crashing")
    func missingResourceThrows() {
        #expect(throws: PlanetDataError.self) {
            try PlanetRepository(resourceName: "definitely_missing_file").loadPlanets()
        }
    }
}
