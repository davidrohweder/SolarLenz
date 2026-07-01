//
//  StarFieldView.swift
//  SolarLenz
//
//  A single-Canvas starfield with subtle twinkle, layered over soft nebula clouds for
//  depth. Replaces the original approach of rendering up to 2,500 individual `Star`
//  SwiftUI views — a large performance win, and far less flat.
//

import SwiftUI

@available(iOS 18, *)
struct StarFieldView: View {

    private struct Star {
        var x: CGFloat
        var y: CGFloat
        var radius: CGFloat
        var baseOpacity: Double
        var twinkleSpeed: Double
        var phase: Double
        var tint: Color
    }

    let starCount: Int
    @State private var stars: [Star] = []

    init(starCount: Int = 340) { self.starCount = starCount }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Theme.Palette.deepSpace, Theme.Palette.nebula, Theme.Palette.deepSpace],
                startPoint: .top,
                endPoint: .bottom
            )

            nebula

            TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
                Canvas { context, size in
                    let t = timeline.date.timeIntervalSinceReferenceDate
                    for star in stars {
                        let twinkle = 0.45 + 0.55 * sin(t * star.twinkleSpeed + star.phase)
                        let rect = CGRect(
                            x: star.x * size.width,
                            y: star.y * size.height,
                            width: star.radius,
                            height: star.radius
                        )
                        context.fill(
                            Path(ellipseIn: rect),
                            with: .color(star.tint.opacity(star.baseOpacity * twinkle))
                        )
                    }
                }
                .blendMode(.plusLighter)
            }
        }
        .ignoresSafeArea()
        .onAppear {
            if stars.isEmpty { stars = Self.generate(count: starCount) }
        }
    }

    /// Soft, static colored clouds that give the black field some depth.
    private var nebula: some View {
        GeometryReader { geo in
            ZStack {
                blob(.indigo, at: CGPoint(x: 0.22, y: 0.30), fraction: 0.85, in: geo.size)
                blob(.purple, at: CGPoint(x: 0.82, y: 0.68), fraction: 0.70, in: geo.size)
                blob(Theme.Palette.accent, at: CGPoint(x: 0.60, y: 0.12), fraction: 0.55, in: geo.size)
            }
        }
        .ignoresSafeArea()
    }

    private func blob(_ color: Color, at rel: CGPoint, fraction: CGFloat, in size: CGSize) -> some View {
        let d = size.width * fraction
        return Circle()
            .fill(RadialGradient(colors: [color.opacity(0.28), .clear], center: .center, startRadius: 0, endRadius: d / 2))
            .frame(width: d, height: d)
            .position(x: rel.x * size.width, y: rel.y * size.height)
            .blur(radius: 50)
            .blendMode(.plusLighter)
    }

    /// Deterministic generation so the field is stable across redraws and launches.
    private static func generate(count: Int) -> [Star] {
        var rng = SeededGenerator(seed: 0xC0FFEE)
        let tints: [Color] = [.white, .white, .white, .white, Color(red: 0.7, green: 0.8, blue: 1.0), Color(red: 1.0, green: 0.9, blue: 0.75)]
        return (0..<count).map { _ in
            let bright = Double.random(in: 0...1, using: &rng) > 0.9   // a few hero stars
            return Star(
                x: .random(in: 0...1, using: &rng),
                y: .random(in: 0...1, using: &rng),
                radius: bright ? .random(in: 2.2...3.4, using: &rng) : .random(in: 0.6...2.0, using: &rng),
                baseOpacity: bright ? .random(in: 0.8...1.0, using: &rng) : .random(in: 0.2...0.85, using: &rng),
                twinkleSpeed: .random(in: 0.4...2.6, using: &rng),
                phase: .random(in: 0...(2 * .pi), using: &rng),
                tint: tints[Int(rng.next() % UInt64(tints.count))]
            )
        }
    }
}
