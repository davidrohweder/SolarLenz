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
    @State private var selectedFact: FactRow?
    @State private var showingAllData = false

    var body: some View {
        Group {
            if let planet = model.selectedPlanet {
                content(for: planet)
            } else {
                ErrorStateView(message: "No planet is selected.") { router.send(.showSystem) }
            }
        }
        .sheet(item: $selectedFact) { row in
            FactInfoSheet(row: row)
                .presentationDetents([.height(260), .medium])
        }
        .sheet(isPresented: $showingAllData) {
            if let planet = model.selectedPlanet {
                PlanetDataBrowserSheet(planet: planet)
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
            PlanetScene3DView(planet: planet)
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

                actionButtons(for: planet)
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
                        if row.explanation != nil {
                            Button { selectedFact = row } label: {
                                Image(systemName: "info.circle")
                                    .font(.caption)
                                    .frame(width: 24, height: 24)
                            }
                            .buttonStyle(.plain)
                            .foregroundStyle(Theme.Palette.accent)
                            .accessibilityLabel("About \(row.label)")
                            .help(row.explanation ?? "")
                        }
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

    private func actionButtons(for planet: Planet) -> some View {
        HStack(spacing: Theme.Spacing.m) {
            Button { showingAllData = true } label: {
                Label("NASA Data", systemImage: "tablecells")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
            }
            .glassPill()
            .accessibilityHint("Shows the full NASA and JPL data table for this planet")

            Button { withAnimation(Theme.Motion.transition) { router.send(.focusInAR(planet.id)) } } label: {
                Label("AR", systemImage: "arkit")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
            }
            .glassPill()
            .accessibilityHint("Places the solar system in front of you using the camera")
        }
        .padding(.top, Theme.Spacing.s)
    }
}

@available(iOS 18, *)
private struct FactInfoSheet: View {
    let row: FactRow

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: Theme.Spacing.m) {
                LabeledContent(row.label, value: row.value)
                    .font(Theme.Typography.body)

                if let explanation = row.explanation {
                    Text(explanation)
                        .font(Theme.Typography.body)
                        .foregroundStyle(.secondary)
                }

                if let url = URL(string: PlanetFacts.sourceURL(for: row)) {
                    Link(PlanetFacts.sourceTitle(for: row), destination: url)
                        .font(Theme.Typography.caption)
                }

                Spacer()
            }
            .padding(Theme.Spacing.l)
            .navigationTitle("About This Data")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

@available(iOS 18, *)
private struct PlanetDataBrowserSheet: View {
    @Environment(\.dismiss) private var dismiss
    let planet: Planet

    var body: some View {
        NavigationStack {
            List {
                ForEach(PlanetFacts.allSections(for: planet)) { section in
                    Section(section.title) {
                        ForEach(section.rows) { row in
                            VStack(alignment: .leading, spacing: 3) {
                                HStack(alignment: .firstTextBaseline) {
                                    Text(row.label)
                                        .foregroundStyle(.secondary)
                                    Spacer(minLength: Theme.Spacing.m)
                                    Text(row.value)
                                        .fontWeight(.medium)
                                        .multilineTextAlignment(.trailing)
                                }
                                if let explanation = row.explanation {
                                    Text(explanation)
                                        .font(.caption)
                                        .foregroundStyle(.tertiary)
                                }
                            }
                            .padding(.vertical, 2)
                        }
                    }
                }

                Section("Sources") {
                    if let url = URL(string: PlanetFacts.sourceURL) {
                        Link(PlanetFacts.sourceTitle, destination: url)
                    }
                    if let url = URL(string: PlanetFacts.moonSourceURL) {
                        Link(PlanetFacts.moonSourceTitle, destination: url)
                    }
                }
            }
            .navigationTitle("\(planet.displayName) Data")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}
