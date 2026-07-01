//
//  PlanetFacts.swift
//  SolarLenz
//
//  Turns a Planet's raw fields into human-readable, grouped, age-bracketed fact sections.
//  Replaces the original app's raw `Text("mass10_24Kg 5.97")` dumps with labels + units,
//  while keeping the same "kids see less, adults see everything" depth.
//

import Foundation

struct FactRow: Identifiable, Hashable {
    let label: String
    let value: String
    var id: String { label }
}

struct FactSection: Identifiable, Hashable {
    let title: String
    let rows: [FactRow]
    var id: String { title }
}

enum PlanetFacts {

    /// Grouped facts tailored to the audience: `.child` gets a friendly handful, `.teen` a
    /// solid set, `.adult` the full NASA sheet. Empty sections and missing fields are dropped.
    static func sections(for planet: Planet, bracket: AgeBracket) -> [FactSection] {
        let raw: [FactSection]
        switch bracket {
        case .child: raw = child(planet)
        case .teen:  raw = teen(planet)
        case .adult: raw = adult(planet)
        }
        return raw.filter { !$0.rows.isEmpty }
    }

    // MARK: - Brackets

    private static func child(_ p: Planet) -> [FactSection] {
        [section("The basics", [
            ("How big across", km(p.volumetricMeanRadiusKm * 2)),
            ("Distance from the Sun", String(format: "%.2f AU", p.distanceInAU)),
            ("A year here lasts", p.orbitalPeriodDescription),
            ("A day here lasts", dec(p.lengthOfDayHrs, "hours", 1)),
            ("Moons", "\(p.numberOfNaturalSatellites)"),
            ("Has rings", p.hasRingSystem ? "Yes" : "No"),
            ("Temperature", temp(p.blackBodyTemperatureK)),
        ])]
    }

    private static func teen(_ p: Planet) -> [FactSection] {
        [
            section("Size & mass", [
                ("Mean radius", km(p.volumetricMeanRadiusKm)),
                ("Mass", dec(p.mass10e24Kg, "×10²⁴ kg", 2)),
                ("Density", dec(p.meanDensityKgM3, "kg/m³", 0)),
                ("Surface gravity", dec(p.surfaceGravityDisplay, "m/s²", 1)),
                ("Escape velocity", dec(p.escapeVelocityKmS, "km/s", 1)),
            ]),
            section("Orbit & spin", [
                ("Distance from Sun", String(format: "%.2f AU", p.distanceInAU)),
                ("Orbital period", p.orbitalPeriodDescription),
                ("Orbital speed", dec(p.meanOrbitalVelocityKmS, "km/s", 1)),
                ("Eccentricity", dec(p.orbitEccentricity, "", 3)),
                ("Day length", dec(p.lengthOfDayHrs, "hours", 1)),
                ("Axial tilt", dec(p.obliquityToOrbitDeg, "°", 1)),
            ]),
            section("Environment", [
                ("Mean temperature", temp(p.blackBodyTemperatureK)),
                ("Moons", "\(p.numberOfNaturalSatellites)"),
                ("Ring system", p.hasRingSystem ? "Yes" : "No"),
            ]),
        ]
    }

    private static func adult(_ p: Planet) -> [FactSection] {
        [
            section("Size & shape", [
                ("Mean radius", km(p.volumetricMeanRadiusKm)),
                ("Equatorial radius", km(p.equatorialRadiusDisplayKm)),
                ("Polar radius", km(p.polarRadiusDisplayKm)),
                ("Core radius", km(p.coreRadiusKm)),
                ("Ellipticity", dec(p.ellipticityDisplay, "", 5)),
                ("Volume", dec(p.volume10e10Km3, "×10¹⁰ km³", 2)),
            ]),
            section("Mass & gravity", [
                ("Mass", dec(p.mass10e24Kg, "×10²⁴ kg", 4)),
                ("Mean density", dec(p.meanDensityKgM3, "kg/m³", 0)),
                ("Surface gravity", dec(p.surfaceGravityDisplay, "m/s²", 2)),
                ("Surface acceleration", dec(p.surfaceAccelerationDisplay, "m/s²", 2)),
                ("Escape velocity", dec(p.escapeVelocityKmS, "km/s", 2)),
                ("GM", dec(p.gMX10e6Km3S2, "×10⁶ km³/s²", 4)),
                ("Moment of inertia", dec(p.momentOfInertiaIMR2, "", 3)),
            ]),
            section("Orbit", [
                ("Distance from Sun", String(format: "%.3f AU", p.distanceInAU)),
                ("Semi-major axis", dec(p.semiMajorAxis10e6Km, "×10⁶ km", 2)),
                ("Perihelion", dec(p.perihelion10e6Km, "×10⁶ km", 2)),
                ("Aphelion", dec(p.aphelion10e6Km, "×10⁶ km", 2)),
                ("Sidereal period", dec(p.siderealOrbitPeriodDays, "days", 1)),
                ("Tropical period", dec(p.tropicalOrbitPeriodDays, "days", 1)),
                ("Synodic period", dec(p.synodicPeriodDays, "days", 1)),
                ("Eccentricity", dec(p.orbitEccentricity, "", 4)),
                ("Inclination", dec(p.orbitInclinationDeg, "°", 2)),
                ("Mean orbital velocity", dec(p.meanOrbitalVelocityKmS, "km/s", 2)),
                ("Max orbital velocity", dec(p.maxOrbitalVelocityKmS, "km/s", 2)),
                ("Min orbital velocity", dec(p.minOrbitalVelocityKmS, "km/s", 2)),
            ]),
            section("Rotation & day", [
                ("Sidereal rotation", dec(p.siderealRotationPeriodHrs, "hrs", 2)),
                ("Length of day", dec(p.lengthOfDayHrs, "hrs", 2)),
                ("Obliquity to orbit", dec(p.obliquityToOrbitDeg, "°", 2)),
                ("Equator inclination", dec(p.inclinationOfEquatorDeg, "°", 2)),
            ]),
            section("Light & heat", [
                ("Black-body temp", temp(p.blackBodyTemperatureK)),
                ("Bond albedo", dec(p.bondAlbedo, "", 3)),
                ("Geometric albedo", dec(p.geometricAlbedo, "", 3)),
                ("Solar irradiance", dec(p.solarIrradianceWM2, "W/m²", 1)),
                ("V-band magnitude", dec(p.vBandMagnitudeV10, "", 2)),
                ("J₂", dec(p.j2X106, "×10⁻⁶", 2)),
                ("Topographic range", km(p.topographicRangeKm)),
            ]),
            section("Satellites & rings", [
                ("Natural satellites", "\(p.numberOfNaturalSatellites)"),
                ("Ring system", p.hasRingSystem ? "Yes" : "No"),
            ]),
        ]
    }

    // MARK: - Formatting

    private static func section(_ title: String, _ items: [(String, String?)]) -> FactSection {
        FactSection(title: title, rows: items.compactMap { label, value in
            value.map { FactRow(label: label, value: $0) }
        })
    }

    private static let grouped: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.maximumFractionDigits = 0
        return f
    }()

    /// Kilometres with thousands separators, dropping non-positive/absent values.
    private static func km(_ value: Double?) -> String? {
        guard let value, value > 0 else { return nil }
        let number = grouped.string(from: NSNumber(value: value)) ?? "\(Int(value))"
        return "\(number) km"
    }

    /// A fixed-decimal value with a unit, dropping absent values. `unit` may be empty.
    private static func dec(_ value: Double?, _ unit: String, _ digits: Int) -> String? {
        guard let value else { return nil }
        let number = String(format: "%.\(digits)f", value)
        return unit.isEmpty ? number : "\(number) \(unit)"
    }

    private static func temp(_ kelvin: Double) -> String? {
        guard kelvin > 0 else { return nil }
        return "\(Int(kelvin.rounded())) K"
    }
}
