//
//  OrbitCanvasView.swift
//  SolarLenz
//
//  The animated 2D orbit map. Orbits are driven by real periods via `OrbitMath` and a
//  single `TimelineView`.
//
//  Each body drags a fading comet trail so the motion reads as alive rather than a set of
//  dots sliding around thin rings.
//

import SwiftUI
import simd

@available(iOS 18, *)
struct OrbitCanvasView: View {
    @Environment(SolarSystemModel.self) private var model

    /// Called when a body is tapped.
    let onSelect: (Planet) -> Void

    /// Vertical squash that gives the flat map a gentle 3D tilt.
    private let tilt: CGFloat = 0.52

    /// Seconds for the slowest (reference) orbit to complete one visual lap.
    private let secondsPerReferenceOrbit: TimeInterval = 92

    /// Compresses the ~680× real speed spread while preserving real period ordering.
    private let speedCompression: Double = 0.42

    /// Real planetary inclinations are subtle at phone scale; this makes the orbital planes read.
    private let visualInclinationMultiplier = 2.1

    /// Comet-trail length (seconds of recent path) and how finely it's sampled.
    private let trailWindow: TimeInterval = 2.4
    private let trailSamples = 22

    var body: some View {
        TimelineView(.animation) { timeline in
            GeometryReader { geo in
                let t = timeline.date.timeIntervalSinceReferenceDate
                let topClearance: CGFloat = 76
                let bottomClearance: CGFloat = 126
                let usableHeight = max(geo.size.height - topClearance - bottomClearance, 220)
                let center = CGPoint(x: geo.size.width / 2, y: topClearance + usableHeight / 2)
                let maxRadius = max(min(geo.size.width - 76, usableHeight - 24) / 2, 120)
                let minRadius = maxRadius * 0.28

                ZStack {
                    orbitRings(center: center, minRadius: minRadius, maxRadius: maxRadius)
                    trails(center: center, minRadius: minRadius, maxRadius: maxRadius, now: t)

                    if let star = model.star {
                        SunView(isSelected: star.id == model.selectedPlanetID)
                            .position(center)
                            .onTapGesture { onSelect(star) }
                            .accessibilityElement()
                            .accessibilityLabel(star.displayName)
                            .accessibilityHint("Selects the Sun")
                            .accessibilityAddTraits(.isButton)
                    }

                    ForEach(model.orbitingBodies) { planet in
                        let r = radius(for: planet, minRadius: minRadius, maxRadius: maxRadius)
                        let point = position(for: planet, radius: r, at: t)
                        PlanetSprite(planet: planet, isSelected: planet.id == model.selectedPlanetID)
                            .position(x: center.x + point.x, y: center.y + point.y)
                            .onTapGesture { onSelect(planet) }
                            .accessibilityElement()
                            .accessibilityLabel(planet.displayName)
                            .accessibilityHint("Selects \(planet.displayName)")
                            .accessibilityAddTraits(.isButton)
                    }
                }
            }
        }
    }

    // MARK: - Shared geometry

    private func radius(for planet: Planet, minRadius: CGFloat, maxRadius: CGFloat) -> CGFloat {
        CGFloat(OrbitMath.logarithmicOrbitRadius(
            semiMajorAxis: planet.semiMajorAxis10e6Km,
            minSemiMajorAxis: model.minSemiMajorAxis,
            maxSemiMajorAxis: model.maxSemiMajorAxis,
            minRadius: Double(minRadius),
            maxRadius: Double(maxRadius)
        ))
    }

    /// Position (relative to the system centre) of a body at a given moment.
    private func position(for planet: Planet, radius: CGFloat, at t: TimeInterval) -> CGPoint {
        let meanAnomaly = OrbitMath.meanAnomaly(
            elapsed: t,
            periodDays: planet.siderealOrbitPeriodDays,
            referencePeriodDays: model.referencePeriodDays,
            secondsPerReferenceOrbit: secondsPerReferenceOrbit,
            phase: Double(planet.id) * 0.7,
            speedCompression: speedCompression
        )
        let position = OrbitMath.keplerianPosition(
            semiMajorAxis: Double(radius),
            eccentricity: planet.orbitEccentricity,
            meanAnomaly: meanAnomaly,
            inclinationRadians: visualInclination(for: planet),
            longitudeOfAscendingNode: Double(planet.id) * 0.43,
            argumentOfPerihelion: Double(planet.id) * 0.71
        )
        return project(position)
    }

    // MARK: - Layers

    private func trails(center: CGPoint, minRadius: CGFloat, maxRadius: CGFloat, now t: TimeInterval) -> some View {
        Canvas { context, _ in
            for planet in model.orbitingBodies {
                let r = radius(for: planet, minRadius: minRadius, maxRadius: maxRadius)
                var previous: CGPoint?
                for i in 0...trailSamples {
                    let frac = Double(i) / Double(trailSamples)
                    let sample = position(for: planet, radius: r, at: t - trailWindow * frac)
                    let pt = CGPoint(x: center.x + sample.x, y: center.y + sample.y)
                    if let prev = previous {
                        var segment = Path()
                        segment.move(to: prev)
                        segment.addLine(to: pt)
                        let fade = 1 - frac
                        context.stroke(
                            segment,
                            with: .color(planet.displayColor.opacity(0.6 * fade)),
                            style: StrokeStyle(lineWidth: 0.5 + 3.2 * fade, lineCap: .round)
                        )
                    }
                    previous = pt
                }
            }
        }
        .blendMode(.plusLighter)
    }

    private func orbitRings(center: CGPoint, minRadius: CGFloat, maxRadius: CGFloat) -> some View {
        Canvas { context, _ in
            for planet in model.orbitingBodies {
                let r = radius(for: planet, minRadius: minRadius, maxRadius: maxRadius)
                var path = Path()
                for i in 0...160 {
                    let anomaly = Double(i) / 160 * 2 * Double.pi
                    let position = OrbitMath.keplerianPosition(
                        semiMajorAxis: Double(r),
                        eccentricity: planet.orbitEccentricity,
                        meanAnomaly: anomaly,
                        inclinationRadians: visualInclination(for: planet),
                        longitudeOfAscendingNode: Double(planet.id) * 0.43,
                        argumentOfPerihelion: Double(planet.id) * 0.71
                    )
                    let point = project(position)
                    let screen = CGPoint(x: center.x + point.x, y: center.y + point.y)
                    if i == 0 { path.move(to: screen) } else { path.addLine(to: screen) }
                }
                context.stroke(path, with: .color(.white.opacity(0.16)), lineWidth: 1)
            }
        }
    }

    private func visualInclination(for planet: Planet) -> Double {
        let degrees = min(abs(planet.orbitInclinationDeg ?? 0) * visualInclinationMultiplier, 18)
        return degrees * Double.pi / 180
    }

    private func project(_ position: SIMD3<Double>) -> CGPoint {
        CGPoint(
            x: CGFloat(position.x),
            y: CGFloat(-position.z * Double(tilt) - position.y * 0.55)
        )
    }
}
