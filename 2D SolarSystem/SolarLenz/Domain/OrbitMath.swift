//
//  OrbitMath.swift
//  SolarLenz
//
//  Pure, deterministic orbit layout — testable and free of global mutable state.
//

import CoreGraphics
import Foundation

/// Pure helpers for laying bodies out on their orbits.
///
/// Replaces the original app's magic numbers (`radius = id * 23`, `orbitTime = id + 10`)
/// and the mutable `static var curr_angle` global with values derived from real orbital
/// data. Every function is deterministic, so the layout is unit-testable and the same
/// inputs always produce the same frame.
enum OrbitMath {

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
        guard periodDays > 0, referencePeriodDays > 0, secondsPerReferenceOrbit > 0 else {
            return phase
        }
        let speedRatio = pow(referencePeriodDays / periodDays, speedCompression)
        let orbitsPerSecond = speedRatio / secondsPerReferenceOrbit
        return phase + elapsed * orbitsPerSecond * 2 * .pi
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
}
