//
//  PlanetFacts.swift
//  SolarLenz
//
//  Turns a Planet's raw fields into human-readable, grouped, age-bracketed fact sections.
//

import Foundation

struct FactRow: Identifiable, Hashable {
    let label: String
    let value: String
    let explanation: String?
    var id: String { "\(label)-\(value)" }
}

struct FactSection: Identifiable, Hashable {
    let title: String
    let rows: [FactRow]
    var id: String { title }
}

enum PlanetFacts {
    static let sourceTitle = "NASA/JPL planetary physical parameters"
    static let sourceURL = "https://ssd.jpl.nasa.gov/planets/phys_par.html"
    static let moonSourceTitle = "NASA Space Place moon counts"
    static let moonSourceURL = "https://spaceplace.nasa.gov/how-many-moons/"

    /// Grouped facts tailored to the audience: `.child` gets a friendly handful, `.teen` a
    /// solid set, `.adult` the full NASA sheet. Empty sections and missing fields are dropped.
    static func sections(for planet: Planet, bracket: AgeBracket) -> [FactSection] {
        let raw: [FactSection]
        switch bracket {
        case .child: raw = profile(planet) + child(planet) + comparisons(planet)
        case .teen:  raw = profile(planet) + teen(planet) + comparisons(planet)
        case .adult: raw = profile(planet) + adult(planet) + comparisons(planet)
        }
        return raw.filter { !$0.rows.isEmpty }
    }

    static func allSections(for planet: Planet) -> [FactSection] {
        (profile(planet) + adult(planet) + comparisons(planet)).filter { !$0.rows.isEmpty }
    }

    // MARK: - Brackets

    private static func profile(_ p: Planet) -> [FactSection] {
        [
            section("Profile", [
                ("World type", p.isStar ? "Star" : (p.hasRingSystem ? "Ringed planet" : "Planet")),
                ("Distance from Sun", p.isStar ? "Center of the system" : String(format: "%.3f AU", p.distanceInAU)),
                ("Known moons", p.isStar ? nil : "\(p.numberOfNaturalSatellites)"),
                ("Ring system", p.isStar ? nil : (p.hasRingSystem ? "Yes" : "No")),
                ("Primary data source", sourceTitle),
            ]),
        ]
    }

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

    private static func comparisons(_ p: Planet) -> [FactSection] {
        guard !p.isStar else { return [] }
        return [
            section("Compared with Earth", [
                ("Radius vs Earth", earthRatio(p.volumetricMeanRadiusKm, earth: 6_371, digits: 2)),
                ("Mass vs Earth", earthRatio(p.mass10e24Kg, earth: 5.97217, digits: 2)),
                ("Gravity vs Earth", p.surfaceGravityDisplay.flatMap { earthRatio($0, earth: 9.80665, digits: 2) }),
                ("Day vs Earth", earthRatio(abs(p.lengthOfDayHrs), earth: 24, digits: 2)),
                ("Year vs Earth", earthRatio(p.siderealOrbitPeriodDays, earth: 365.256, digits: 2)),
                ("Sunlight vs Earth", p.solarIrradianceWM2.flatMap { earthRatio($0, earth: 1361, digits: 2) }),
            ]),
        ]
    }

    // MARK: - Formatting

    private static func section(_ title: String, _ items: [(String, String?)]) -> FactSection {
        FactSection(title: title, rows: items.compactMap { label, value in
            value.map { FactRow(label: label, value: $0, explanation: explanation(for: label)) }
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

    private static func earthRatio(_ value: Double, earth: Double, digits: Int) -> String? {
        guard value > 0, earth > 0 else { return nil }
        let ratio = value / earth
        return String(format: "%.\(digits)f× Earth", ratio)
    }

    static func sourceTitle(for row: FactRow) -> String {
        usesMoonSource(row.label) ? moonSourceTitle : sourceTitle
    }

    static func sourceURL(for row: FactRow) -> String {
        usesMoonSource(row.label) ? moonSourceURL : sourceURL
    }

    private static func usesMoonSource(_ label: String) -> Bool {
        ["Known moons", "Moons", "Natural satellites", "Ring system"].contains(label)
    }

    private static func explanation(for label: String) -> String? {
        switch label {
        case "World type":
            return "A plain-language grouping for the body being shown."
        case "Distance from Sun":
            return "Astronomical units compare the body's average orbital distance with Earth's average distance from the Sun."
        case "Known moons", "Moons", "Natural satellites":
            return "Confirmed natural satellites listed for the planet."
        case "Ring system":
            return "Whether the planet has a known ring system."
        case "Primary data source":
            return "The physical and orbital values shown here are sourced from NASA/JPL planetary data."
        case "How big across":
            return "The body's mean diameter, computed from its mean radius."
        case "Mean radius":
            return "The average radius of the body, useful when a planet is not a perfect sphere."
        case "Equatorial radius":
            return "Radius measured around the equator; fast-spinning planets bulge here."
        case "Polar radius":
            return "Radius measured from pole to pole."
        case "Core radius":
            return "Estimated radius of the central core where available."
        case "Ellipticity":
            return "How much the body is flattened compared with a perfect sphere."
        case "Volume":
            return "Total space occupied by the body."
        case "Mass":
            return "How much matter the body contains."
        case "Mean density":
            return "Mass divided by volume; this hints at rocky, icy, or gaseous composition."
        case "Surface gravity":
            return "The gravitational pull at the visible surface or one-bar level."
        case "Surface acceleration":
            return "Effective acceleration at the surface, including rotation effects when available."
        case "Escape velocity":
            return "Speed needed to leave the body's gravity without more propulsion."
        case "GM":
            return "Standard gravitational parameter, used for precise orbit calculations."
        case "Moment of inertia":
            return "A clue to how mass is distributed inside the body."
        case "Semi-major axis":
            return "Half the long axis of the orbit; a standard way to describe average orbital size."
        case "Perihelion":
            return "Closest point to the Sun in the body's orbit."
        case "Aphelion":
            return "Farthest point from the Sun in the body's orbit."
        case "Orbital period", "A year here lasts", "Sidereal period":
            return "Time required to complete one orbit relative to the fixed stars."
        case "Tropical period":
            return "Orbit period measured from season to season."
        case "Synodic period":
            return "Time between similar alignments as seen from Earth."
        case "Eccentricity":
            return "How stretched the orbit is; zero is a circle."
        case "Inclination":
            return "Tilt of the orbital plane compared with Earth's orbital plane."
        case "Orbital speed", "Mean orbital velocity":
            return "Average speed along the orbit."
        case "Max orbital velocity":
            return "Fastest orbital speed, usually near perihelion."
        case "Min orbital velocity":
            return "Slowest orbital speed, usually near aphelion."
        case "Sidereal rotation":
            return "Time for one spin relative to the fixed stars."
        case "Day length", "A day here lasts", "Length of day":
            return "Time from one noon to the next, which can differ from the spin period."
        case "Axial tilt", "Obliquity to orbit":
            return "Tilt of the body's spin axis relative to its orbit."
        case "Equator inclination":
            return "Tilt of the equator relative to the orbital plane."
        case "Temperature", "Mean temperature", "Black-body temp":
            return "Estimated temperature from absorbed sunlight, before local atmosphere effects."
        case "Bond albedo":
            return "Fraction of all incoming sunlight reflected back to space."
        case "Geometric albedo":
            return "Brightness compared with a perfectly reflecting disk."
        case "Solar irradiance":
            return "Sunlight power received per square meter at this orbit."
        case "V-band magnitude":
            return "Visible-light brightness in the astronomical V band."
        case "J₂":
            return "How much the gravity field differs from a perfect sphere."
        case "Topographic range":
            return "Difference between high and low terrain where known."
        case "Radius vs Earth", "Mass vs Earth", "Gravity vs Earth", "Day vs Earth", "Year vs Earth", "Sunlight vs Earth":
            return "A comparison that makes the raw value easier to interpret."
        default:
            return nil
        }
    }
}
