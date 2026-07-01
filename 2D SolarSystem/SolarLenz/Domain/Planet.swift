//
//  Planet.swift
//  SolarLenz
//
//  A clean, crash-free domain model for a celestial body — now decoding the full NASA
//  fact-sheet so the detail screen can show everything the original app did.
//

import Foundation

/// A celestial body in the solar system, decoded from the bundled NASA fact-sheet data.
///
/// Physical quantities keep their source units, encoded in the property names, so there is
/// never ambiguity at the call site. The source data uses different keys for terrestrial
/// bodies vs. gas giants (e.g. `surfaceGravityMS2` vs `gravityEq1BarMS2`); those variants are
/// all decoded as optionals and coalesced by the display accessors below. No force-unwraps.
struct Planet: Identifiable, Hashable, Sendable, Codable {

    /// Distance-ordered identifier from the source data. `0` is the Sun.
    let id: Int
    let name: String
    let colorName: String
    /// Relative on-screen size hint authored in the data set (roughly `0...1`).
    let scale: Double

    // MARK: - Core physical characteristics (present for every body)

    let distanceFromSun: Double          // kilometres
    let mass10e24Kg: Double
    let volumetricMeanRadiusKm: Double
    let meanDensityKgM3: Double
    let escapeVelocityKmS: Double
    let blackBodyTemperatureK: Double
    let numberOfNaturalSatellites: Int
    let hasRingSystem: Bool

    // MARK: - Core orbital elements (drive the orbit motion)

    let semiMajorAxis10e6Km: Double
    let siderealOrbitPeriodDays: Double
    let orbitEccentricity: Double
    let lengthOfDayHrs: Double
    let obliquityToOrbitDeg: Double

    // MARK: - Extended fields (optional; some are absent per body / naming varies)

    let volume10e10Km3: Double?
    let equatorialRadiusKm: Double?
    let equatorialRadius1BarLevelKm: Double?
    let polarRadiusKm: Double?
    let polarRadius1BarLevelKm: Double?
    let coreRadiusKm: Double?
    let ellipticityFlattening: Double?
    let ellipticity: Double?
    let surfaceGravityMS2: Double?
    let surfaceGravityEqMS2: Double?
    let gravityEq1BarMS2: Double?
    let surfaceAccelerationMS2: Double?
    let surfaceAccelerationEqMS2: Double?
    let accelerationEq1BarMS2: Double?
    let gMX10e6Km3S2: Double?
    let bondAlbedo: Double?
    let geometricAlbedo: Double?
    let vBandMagnitudeV10: Double?
    let solarIrradianceWM2: Double?
    let topographicRangeKm: Double?
    let momentOfInertiaIMR2: Double?
    let j2X106: Double?
    let tropicalOrbitPeriodDays: Double?
    let perihelion10e6Km: Double?
    let aphelion10e6Km: Double?
    let synodicPeriodDays: Double?
    let meanOrbitalVelocityKmS: Double?
    let maxOrbitalVelocityKmS: Double?
    let minOrbitalVelocityKmS: Double?
    let orbitInclinationDeg: Double?
    let siderealRotationPeriodHrs: Double?
    let inclinationOfEquatorDeg: Double?

    private enum CodingKeys: String, CodingKey {
        case id, name, colorName, scale
        case distanceFromSun
        case mass10e24Kg = "mass10_24Kg"
        case volumetricMeanRadiusKm
        case meanDensityKgM3
        case escapeVelocityKmS
        case blackBodyTemperatureK
        case numberOfNaturalSatellites
        case hasRingSystem = "planetaryRingSystem"
        case semiMajorAxis10e6Km = "semimajorAxis10_6Km"
        case siderealOrbitPeriodDays
        case orbitEccentricity
        case lengthOfDayHrs
        case obliquityToOrbitDeg
        case volume10e10Km3 = "volume10_10Km3"
        case equatorialRadiusKm
        case equatorialRadius1BarLevelKm
        case polarRadiusKm
        case polarRadius1BarLevelKm
        case coreRadiusKm
        case ellipticityFlattening
        case ellipticity
        case surfaceGravityMS2
        case surfaceGravityEqMS2
        case gravityEq1BarMS2
        case surfaceAccelerationMS2
        case surfaceAccelerationEqMS2
        case accelerationEq1BarMS2
        case gMX10e6Km3S2 = "gMX10_6Km3S2"
        case bondAlbedo
        case geometricAlbedo
        case vBandMagnitudeV10
        case solarIrradianceWM2
        case topographicRangeKm
        case momentOfInertiaIMR2
        case j2X106
        case tropicalOrbitPeriodDays
        case perihelion10e6Km = "perihelion10_6Km"
        case aphelion10e6Km = "aphelion10_6Km"
        case synodicPeriodDays
        case meanOrbitalVelocityKmS
        case maxOrbitalVelocityKmS
        case minOrbitalVelocityKmS
        case orbitInclinationDeg
        case siderealRotationPeriodHrs
        case inclinationOfEquatorDeg
    }
}

extension Planet {

    /// The Sun anchors the system; every other body orbits it.
    var isStar: Bool { id == 0 }

    /// A display-ready, capitalized name (e.g. `"Earth"`).
    var displayName: String { name.capitalized }

    /// Distance from the Sun expressed in astronomical units.
    var distanceInAU: Double { distanceFromSun / 1.495_978_707e8 }

    /// A short, human-readable orbital period (e.g. `"365 days"` or `"1.9 years"`).
    var orbitalPeriodDescription: String {
        guard siderealOrbitPeriodDays > 0 else { return "—" }
        if siderealOrbitPeriodDays < 365 {
            return "\(Int(siderealOrbitPeriodDays.rounded())) days"
        }
        return String(format: "%.1f years", siderealOrbitPeriodDays / 365.25)
    }

    // MARK: - Coalesced display values (bridge the terrestrial / gas-giant key variants)

    var equatorialRadiusDisplayKm: Double? { equatorialRadiusKm ?? equatorialRadius1BarLevelKm }
    var polarRadiusDisplayKm: Double? { polarRadiusKm ?? polarRadius1BarLevelKm }
    var surfaceGravityDisplay: Double? { surfaceGravityMS2 ?? surfaceGravityEqMS2 ?? gravityEq1BarMS2 }
    var surfaceAccelerationDisplay: Double? { surfaceAccelerationMS2 ?? surfaceAccelerationEqMS2 ?? accelerationEq1BarMS2 }
    var ellipticityDisplay: Double? { ellipticityFlattening ?? ellipticity }
}
