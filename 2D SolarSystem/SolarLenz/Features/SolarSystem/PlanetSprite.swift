//
//  PlanetSprite.swift
//  SolarLenz
//
//  Stylized vector planet + sun. Resolution-independent, no missing-asset risk, and it
//  conveys ring systems, a soft glow, and selection state.
//

import SwiftUI

@available(iOS 18, *)
struct PlanetSprite: View {
    let planet: Planet
    let isSelected: Bool

    /// Diameter derived from the authored `scale` (roughly 14...46 pt).
    private var diameter: CGFloat { 14 + CGFloat(planet.scale) * 30 }

    var body: some View {
        ZStack {
            // Soft luminous halo so bodies glow against the dark field.
            Circle()
                .fill(planet.displayColor)
                .frame(width: diameter * 1.7, height: diameter * 1.7)
                .blur(radius: diameter * 0.35)
                .opacity(isSelected ? 0.75 : 0.5)
                .blendMode(.plusLighter)

            if planet.hasRingSystem {
                Ellipse()
                    .strokeBorder(planet.displayColor.opacity(0.85), lineWidth: 2)
                    .frame(width: diameter * 2.0, height: diameter * 0.74)
                    .rotationEffect(.degrees(-18))
                    .shadow(color: planet.displayColor.opacity(0.5), radius: 3)
            }

            Circle()
                .fill(
                    RadialGradient(
                        colors: [planet.displayColor.opacity(0.95), planet.displayColor.opacity(0.4)],
                        center: .topLeading,
                        startRadius: 0,
                        endRadius: diameter
                    )
                )
                .frame(width: diameter, height: diameter)
                .overlay(Circle().strokeBorder(.white.opacity(0.3), lineWidth: 0.5))
                .shadow(color: planet.displayColor.opacity(0.8), radius: isSelected ? 12 : 6)

            if isSelected {
                Circle()
                    .strokeBorder(.white.opacity(0.9), lineWidth: 1.5)
                    .frame(width: diameter + 14, height: diameter + 14)
            }
        }
        .overlay(alignment: .top) {
            if isSelected {
                Text(planet.displayName)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .glassPill()
                    .fixedSize()
                    .offset(y: -(diameter / 2) - 22)
            }
        }
        .animation(Theme.Motion.interactive, value: isSelected)
        // Keep a comfortable tap target even for the smallest bodies.
        .contentShape(Circle().size(width: max(diameter, 40), height: max(diameter, 40)))
    }
}

@available(iOS 18, *)
struct SunView: View {
    private let coreDiameter: CGFloat = 52

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            let pulse = 1 + 0.05 * sin(t * 1.6)

            ZStack {
                // Outer corona — a large, soft, breathing glow.
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [.orange.opacity(0.55), .orange.opacity(0.12), .clear],
                            center: .center, startRadius: 2, endRadius: 95
                        )
                    )
                    .frame(width: 200, height: 200)
                    .scaleEffect(pulse)
                    .blur(radius: 6)
                    .blendMode(.plusLighter)

                // Slowly rotating rays.
                rays(time: t)
                    .frame(width: 200, height: 200)
                    .blendMode(.plusLighter)

                // Bright core.
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [.white, .yellow, .orange],
                            center: .center, startRadius: 1, endRadius: coreDiameter * 0.6
                        )
                    )
                    .frame(width: coreDiameter * pulse, height: coreDiameter * pulse)
                    .shadow(color: .orange.opacity(0.9), radius: 26)
            }
        }
        .frame(width: 200, height: 200)
        .accessibilityHidden(true)
    }

    private func rays(time t: TimeInterval) -> some View {
        Canvas { context, size in
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let rayCount = 12
            let inner = coreDiameter * 0.55
            for i in 0..<rayCount {
                let base = Double(i) / Double(rayCount) * 2 * .pi + t * 0.12
                let length = 30 + 10 * sin(t * 1.3 + Double(i))
                let outer = inner + length
                var path = Path()
                path.move(to: CGPoint(x: center.x + inner * cos(base), y: center.y + inner * sin(base)))
                path.addLine(to: CGPoint(x: center.x + outer * cos(base), y: center.y + outer * sin(base)))
                context.stroke(path, with: .color(.orange.opacity(0.35)), style: StrokeStyle(lineWidth: 2, lineCap: .round))
            }
        }
    }
}
