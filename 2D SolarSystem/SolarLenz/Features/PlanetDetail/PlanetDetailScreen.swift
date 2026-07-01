//
//  PlanetDetailScreen.swift
//  SolarLenz
//
//  One integrated screen: a large interactive 3D model up top, the full age-bracketed NASA
//  fact sheet below (grouped, labeled, with units), and a jump into AR.
//

import SwiftUI

@available(iOS 18, *)
struct PlanetDetailScreen: View {
    @Environment(SolarSystemModel.self) private var model
    @Environment(AppRouter.self) private var router
    @AppStorage(PreferenceKey.userAge) private var userAge = 25

    var body: some View {
        Group {
            if let planet = model.selectedPlanet {
                content(for: planet)
            } else {
                // Never crash on a missing selection — the original code force-unwrapped here.
                ErrorStateView(message: "No planet is selected.") { router.send(.showSystem) }
            }
        }
    }

    private func content(for planet: Planet) -> some View {
        GeometryReader { geo in
            VStack(spacing: 0) {
                hero(for: planet, height: geo.size.height * 0.42)
                factSheet(for: planet)
            }
        }
    }

    // MARK: - 3D hero

    private func hero(for planet: Planet, height: CGFloat) -> some View {
        ZStack {
            PlanetModel3DView(planet: planet)
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            VStack {
                HStack {
                    backButton
                    Spacer()
                }
                Spacer()
                Label("Drag to rotate · pinch to zoom", systemImage: "hand.draw")
                    .font(Theme.Typography.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(Theme.Spacing.m)
        }
        .frame(height: height)
    }

    private var backButton: some View {
        Button { withAnimation(Theme.Motion.transition) { router.send(.showSystem) } } label: {
            Label("Map", systemImage: "chevron.left")
                .font(.headline)
                .padding(.horizontal, Theme.Spacing.m)
                .frame(height: 40)
        }
        .glassPill()
        .foregroundStyle(.white)
        .accessibilityLabel("Back to the map")
    }

    // MARK: - Facts

    private func factSheet(for planet: Planet) -> some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.l) {
                VStack(spacing: 2) {
                    Text(planet.displayName).font(Theme.Typography.display)
                    Text("\(AgeBracket(age: userAge).title) facts")
                        .font(Theme.Typography.caption)
                        .foregroundStyle(Theme.Palette.accent)
                }

                ForEach(PlanetFacts.sections(for: planet, bracket: AgeBracket(age: userAge))) { section in
                    factSection(section)
                }

                arButton
            }
            .padding(Theme.Spacing.l)
            .foregroundStyle(.white)
        }
    }

    private func factSection(_ section: FactSection) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s) {
            Text(section.title.uppercased())
                .font(.caption2.weight(.semibold))
                .foregroundStyle(Theme.Palette.accent)
                .tracking(0.5)
                .padding(.leading, Theme.Spacing.xs)

            VStack(spacing: 0) {
                ForEach(Array(section.rows.enumerated()), id: \.element.id) { index, row in
                    HStack(alignment: .firstTextBaseline) {
                        Text(row.label)
                            .foregroundStyle(.secondary)
                        Spacer(minLength: Theme.Spacing.m)
                        Text(row.value)
                            .fontWeight(.medium)
                            .multilineTextAlignment(.trailing)
                    }
                    .font(Theme.Typography.body)
                    .padding(.vertical, Theme.Spacing.s)

                    if index < section.rows.count - 1 {
                        Divider().overlay(.white.opacity(0.08))
                    }
                }
            }
            .padding(.horizontal, Theme.Spacing.m)
            .padding(.vertical, Theme.Spacing.xs)
            .glassCard(cornerRadius: Theme.Radius.control)
        }
    }

    private var arButton: some View {
        Button { withAnimation(Theme.Motion.transition) { router.send(.enterAR) } } label: {
            Label("View in AR", systemImage: "arkit")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
        }
        .glassPill()
        .padding(.top, Theme.Spacing.s)
        .accessibilityHint("Places the solar system in front of you using the camera")
    }
}
