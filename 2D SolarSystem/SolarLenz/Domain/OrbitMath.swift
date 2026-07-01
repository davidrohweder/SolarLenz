//
//  OrbitMath.swift
//  SolarLenz
//
//  Pure, deterministic orbit layout — testable and free of global mutable state.
//

import CoreGraphics
import Foundation
import simd

/// Pure helpers for laying bodies out on their orbits.
///
/// Uses values derived from real orbital data. Every function is deterministic, so the layout
/// is unit-testable and the same inputs always produce the same frame.
enum OrbitMath {
    private static let twoPi = 2 * Double.pi

    /// Visual radius, in points, of a body's orbit.
    ///
    /// Uses a square-root compression of the semi-major axis: it preserves ordering and
    /// keeps the relative spacing legible without the outer planets shoving the inner
    /// ones into the Sun. Returns `minRadius` for degenerate inputs rather than crashing.
    static func orbitRadius(
        semiMajorAxis: Double,
        maxSemiMajorAxis: Double,
        minRadius: CGFloat,
        maxRadius: CGFloat
    ) -> CGFloat {
        guard maxSemiMajorAxis > 0, semiMajorAxis > 0 else { return minRadius }
        let normalized = (semiMajorAxis / maxSemiMajorAxis).squareRoot()
        return minRadius + (maxRadius - minRadius) * CGFloat(normalized)
    }

    /// Angular position, in radians, of a body at a given moment.
    ///
    /// Shorter real periods sweep faster (Mercury still laps Neptune), but the *raw* ratio of
    /// real periods spans ~680× — mapping the slowest to a watchable tempo would make the
    /// innermost bodies a blur. `speedCompression` (0…1) tames that spread: the visual speed
    /// ratio becomes `(referencePeriodDays / periodDays) ^ speedCompression`, so ordering is
    /// preserved while the fastest/slowest gap collapses to something calm and legible.
    /// `secondsPerReferenceOrbit` sets the overall tempo for the slowest (reference) orbit.
    static func angle(
        elapsed: TimeInterval,
        periodDays: Double,
        referencePeriodDays: Double,
        secondsPerReferenceOrbit: TimeInterval,
        phase: Double,
        speedCompression: Double = 1
    ) -> Double {
        meanAnomaly(
            elapsed: elapsed,
            periodDays: periodDays,
            referencePeriodDays: referencePeriodDays,
            secondsPerReferenceOrbit: secondsPerReferenceOrbit,
            phase: phase,
            speedCompression: speedCompression
        )
    }

    /// Mean anomaly, in radians, with the app's visual time compression applied.
    ///
    /// In a circular orbit this is the visual angle. In an eccentric orbit this is the input to
    /// Kepler's equation, which makes bodies speed up near perihelion and slow near aphelion.
    static func meanAnomaly(
        elapsed: TimeInterval,
        periodDays: Double,
        referencePeriodDays: Double,
        secondsPerReferenceOrbit: TimeInterval,
        phase: Double,
        speedCompression: Double = 1
    ) -> Double {
        guard periodDays > 0, referencePeriodDays > 0, secondsPerReferenceOrbit > 0 else {
            return phase
        }
        let speedRatio = pow(referencePeriodDays / periodDays, speedCompression)
        let orbitsPerSecond = speedRatio / secondsPerReferenceOrbit
        return phase + elapsed * orbitsPerSecond * twoPi
    }

    /// Solves Kepler's equation (`M = E − e·sin(E)`) for eccentric anomaly `E`.
    static func eccentricAnomaly(meanAnomaly: Double, eccentricity: Double) -> Double {
        let e = clampedEccentricity(eccentricity)
        guard e > 0 else { return normalizedAngle(meanAnomaly) }

        let m = normalizedAngle(meanAnomaly)
        var estimate = e < 0.8 || abs(m) < 1e-9 ? m : (m < 0 ? -Double.pi : Double.pi)

        for _ in 0..<8 {
            let residual = estimate - e * sin(estimate) - m
            let slope = 1 - e * cos(estimate)
            guard abs(slope) > 1e-9 else { break }
            estimate -= residual / slope
        }

        return estimate
    }

    /// True anomaly, in radians, derived from the eccentric anomaly.
    static func trueAnomaly(meanAnomaly: Double, eccentricity: Double) -> Double {
        let e = clampedEccentricity(eccentricity)
        let eccentric = eccentricAnomaly(meanAnomaly: meanAnomaly, eccentricity: e)
        return 2 * atan2(
            sqrt(1 + e) * sin(eccentric / 2),
            sqrt(1 - e) * cos(eccentric / 2)
        )
    }

    /// A 3D Keplerian position with the Sun at a focus and the orbital plane inclined in space.
    ///
    /// The app data does not include longitude of ascending node or argument of perihelion, so
    /// callers can supply deterministic visual offsets without changing the physical ellipse.
    static func keplerianPosition(
        semiMajorAxis: Double,
        eccentricity: Double,
        meanAnomaly: Double,
        inclinationRadians: Double = 0,
        longitudeOfAscendingNode: Double = 0,
        argumentOfPerihelion: Double = 0
    ) -> SIMD3<Double> {
        guard semiMajorAxis > 0 else { return .zero }

        let e = clampedEccentricity(eccentricity)
        let eccentric = eccentricAnomaly(meanAnomaly: meanAnomaly, eccentricity: e)
        return keplerianPosition(
            semiMajorAxis: semiMajorAxis,
            eccentricity: e,
            eccentricAnomaly: eccentric,
            inclinationRadians: inclinationRadians,
            longitudeOfAscendingNode: longitudeOfAscendingNode,
            argumentOfPerihelion: argumentOfPerihelion
        )
    }

    /// A 3D Keplerian ellipse sample from eccentric anomaly `E`.
    ///
    /// Orbit rings use this direct form so their geometry is a clean ellipse instead of a
    /// time-sampled trail. Moving bodies should use the mean-anomaly overload above so their
    /// visual speed still accelerates near perihelion and slows near aphelion.
    static func keplerianPosition(
        semiMajorAxis: Double,
        eccentricity: Double,
        eccentricAnomaly: Double,
        inclinationRadians: Double = 0,
        longitudeOfAscendingNode: Double = 0,
        argumentOfPerihelion: Double = 0
    ) -> SIMD3<Double> {
        guard semiMajorAxis > 0 else { return .zero }

        let e = clampedEccentricity(eccentricity)
        let semiMinorAxis = semiMajorAxis * sqrt(1 - e * e)

        let orbitalX = semiMajorAxis * (cos(eccentricAnomaly) - e)
        let orbitalZ = semiMinorAxis * sin(eccentricAnomaly)
        let perihelionRotated = rotateXZ(
            SIMD3<Double>(orbitalX, 0, orbitalZ),
            by: argumentOfPerihelion
        )

        let sinInclination = sin(inclinationRadians)
        let cosInclination = cos(inclinationRadians)
        let inclined = SIMD3<Double>(
            perihelionRotated.x,
            perihelionRotated.z * sinInclination,
            perihelionRotated.z * cosInclination
        )

        return rotateXZ(inclined, by: longitudeOfAscendingNode)
    }

    /// Logarithmic orbit spacing for compact AR/2D views that still preserve distance ordering.
    static func logarithmicOrbitRadius(
        semiMajorAxis: Double,
        minSemiMajorAxis: Double,
        maxSemiMajorAxis: Double,
        minRadius: Double,
        maxRadius: Double
    ) -> Double {
        guard semiMajorAxis > 0,
              minSemiMajorAxis > 0,
              maxSemiMajorAxis > minSemiMajorAxis,
              maxRadius > minRadius else {
            return minRadius
        }

        let normalized = (log(semiMajorAxis) - log(minSemiMajorAxis)) / (log(maxSemiMajorAxis) - log(minSemiMajorAxis))
        return minRadius + (maxRadius - minRadius) * min(max(normalized, 0), 1)
    }

    /// Power-compressed orbit spacing for compact AR views.
    ///
    /// This keeps Mercury at `minRadius` and Neptune at `maxRadius`, while preserving the
    /// non-uniform real spacing better than pure logarithmic spacing. Exponents below `1`
    /// make inner planets separable without pretending the outer planets are evenly spaced.
    static func compressedOrbitRadius(
        semiMajorAxis: Double,
        minSemiMajorAxis: Double,
        maxSemiMajorAxis: Double,
        minRadius: Double,
        maxRadius: Double,
        exponent: Double
    ) -> Double {
        guard semiMajorAxis > 0,
              minSemiMajorAxis > 0,
              maxSemiMajorAxis > minSemiMajorAxis,
              maxRadius > minRadius,
              exponent > 0 else {
            return minRadius
        }

        let normalized = (semiMajorAxis - minSemiMajorAxis) / (maxSemiMajorAxis - minSemiMajorAxis)
        let compressed = pow(min(max(normalized, 0), 1), exponent)
        return minRadius + (maxRadius - minRadius) * compressed
    }

    /// Compresses real radii into tappable visual diameters while preserving physical ordering.
    ///
    /// Uses a power curve against the largest radius rather than a pure logarithm. That keeps
    /// Jupiter and Saturn visibly dominant while still preventing the terrestrial planets from
    /// becoming too small to tap.
    static func compressedDiameter(
        physicalRadius: Double,
        minPhysicalRadius: Double,
        maxPhysicalRadius: Double,
        minDiameter: Double,
        maxDiameter: Double
    ) -> Double {
        guard physicalRadius > 0,
              minPhysicalRadius > 0,
              maxPhysicalRadius > minPhysicalRadius,
              maxDiameter > minDiameter else {
            return minDiameter
        }

        let scaled = maxDiameter * pow(physicalRadius / maxPhysicalRadius, 0.45)
        return min(max(scaled, minDiameter), maxDiameter)
    }

    /// Visual angular spin rate, in radians per second, from a sidereal rotation period.
    static func compressedRotationRate(
        rotationPeriodHours: Double,
        secondsPerEarthDay: TimeInterval,
        speedCompression: Double,
        minimumRate: Double,
        maximumRate: Double,
        retrograde: Bool = false
    ) -> Double {
        guard rotationPeriodHours > 0, secondsPerEarthDay > 0 else { return 0 }
        let earthDayHours = 23.9345
        let speedRatio = pow(earthDayHours / rotationPeriodHours, speedCompression)
        let unsigned = min(max(twoPi * speedRatio / secondsPerEarthDay, minimumRate), maximumRate)
        return retrograde ? -unsigned : unsigned
    }

    /// Point on an elliptical orbit for a given angle, with the Sun at a **focus**.
    ///
    /// The ellipse's centre is offset from the focus by `c = a·e` along +x, so the body
    /// traces a true focus-anchored ellipse (Kepler's first law) rather than one centred on
    /// the Sun. `radius` is the semi-major axis `a`; the semi-minor axis is `b = a·√(1−e²)`.
    /// `yScale` flattens the ellipse for a pseudo-3D tilt, and the y axis is inverted because
    /// screen space grows downward. `eccentricity` is clamped so garbage data can't break layout.
    static func position(
        radius: CGFloat,
        angle: Double,
        eccentricity: Double = 0,
        yScale: CGFloat = 1
    ) -> CGPoint {
        let ellipse = orbitEllipse(radius: radius, eccentricity: eccentricity, yScale: yScale)
        return CGPoint(
            x: ellipse.focalOffset + radius * CGFloat(cos(angle)),
            y: -(ellipse.size.height / 2) * CGFloat(sin(angle))
        )
    }

    /// The on-screen ellipse a body traces: how far its centre sits from the Sun (`focalOffset`)
    /// and its full tilted width/height. The drawn orbit ring uses this so the ring and the
    /// body coincide exactly — previously the ring was a plain squashed circle while the body
    /// followed a `√(1−e²)`-compressed path, leaving eccentric planets floating off their ring.
    static func orbitEllipse(
        radius: CGFloat,
        eccentricity: Double = 0,
        yScale: CGFloat = 1
    ) -> (focalOffset: CGFloat, size: CGSize) {
        let e = min(max(eccentricity, 0), 0.95)
        let focalOffset = radius * CGFloat(e)                        // c = a·e
        let semiMinor = radius * CGFloat((1 - e * e).squareRoot())   // b = a·√(1−e²)
        return (focalOffset, CGSize(width: radius * 2, height: semiMinor * yScale * 2))
    }

    private static func clampedEccentricity(_ eccentricity: Double) -> Double {
        min(max(eccentricity, 0), 0.95)
    }

    private static func normalizedAngle(_ angle: Double) -> Double {
        var normalized = angle.truncatingRemainder(dividingBy: twoPi)
        if normalized > .pi {
            normalized -= twoPi
        } else if normalized < -.pi {
            normalized += twoPi
        }
        return normalized
    }

    private static func rotateXZ(_ point: SIMD3<Double>, by angle: Double) -> SIMD3<Double> {
        let cosine = cos(angle)
        let sine = sin(angle)
        return SIMD3<Double>(
            point.x * cosine - point.z * sine,
            point.y,
            point.x * sine + point.z * cosine
        )
    }
}
