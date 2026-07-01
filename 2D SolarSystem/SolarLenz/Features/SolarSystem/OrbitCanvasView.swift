//
//  OrbitCanvasView.swift
//  SolarLenz
//
//  The animated 2D orbit map. Orbits are driven by real periods via `OrbitMath` and a
//  single `TimelineView`, replacing the original per-view implicit `.animation()` hacks,
//  the `static var curr_angle` global, and the fake `radius = id * 23` geometry.
//
//  Each body drags a fading comet trail so the motion reads as alive rather than a set of
//  dots sliding around thin rings.
//

import SwiftUI

@available(iOS 18, *)
struct OrbitCanvasView: View {
    @Environment(SolarSystemModel.self) private var model

    /// Called when a body is tapped.
    let onSelect: (Planet) -> Void

    /// Vertical squash that gives the flat map a gentle 3D tilt.
    private let tilt: CGFloat = 0.52

    /// Seconds for the slowest (reference) orbit to complete one lap.
    private let secondsPerReferenceOrbit: TimeInterval = 52

    /// Compresses the ~680× real speed spread so inner planets glide instead of blurring.
    private let speedCompression: Double = 0.33

    /// Comet-trail length (seconds of recent path) and how finely it's sampled.
    private let trailWindow: TimeInterval = 2.4
    private let trailSamples = 22

    var body: some View {
        TimelineView(.animation) { timeline in
            GeometryReader { geo in
                let t = timeline.date.timeIntervalSinceReferenceDate
                let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
                let maxRadius = min(geo.size.width, geo.size.height) / 2 - 28
                let minRadius = maxRadius * 0.18

                ZStack {
                    orbitRings(center: center, minRadius: minRadius, maxRadius: maxRadius)
                    trails(center: center, minRadius: minRadius, maxRadius: maxRadius, now: t)

                    SunView().position(center)

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
        OrbitMath.orbitRadius(
            semiMajorAxis: planet.semiMajorAxis10e6Km,
            maxSemiMajorAxis: model.maxSemiMajorAxis,
            minRadius: minRadius,
            maxRadius: maxRadius
        )
    }

    /// Position (relative to the system centre) of a body at a given moment.
    private func position(for planet: Planet, radius: CGFloat, at t: TimeInterval) -> CGPoint {
        let angle = OrbitMath.angle(
            elapsed: t,
            periodDays: planet.siderealOrbitPeriodDays,
            referencePeriodDays: model.referencePeriodDays,
            secondsPerReferenceOrbit: secondsPerReferenceOrbit,
            phase: Double(planet.id) * 0.7,
            speedCompression: speedCompression
        )
        return OrbitMath.position(radius: radius, angle: angle, eccentricity: planet.orbitEccentricity, yScale: tilt)
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
                let ellipse = OrbitMath.orbitEllipse(radius: r, eccentricity: planet.orbitEccentricity, yScale: tilt)
                let rect = CGRect(
                    x: center.x + ellipse.focalOffset - ellipse.size.width / 2,
                    y: center.y - ellipse.size.height / 2,
                    width: ellipse.size.width,
                    height: ellipse.size.height
                )
                context.stroke(Path(ellipseIn: rect), with: .color(.white.opacity(0.16)), lineWidth: 1)
            }
        }
    }
}
