//
//  ARSolarSystemScreen.swift
//  SolarLenz
//
//  The AR experience: a big RealityKit solar system fixed in front of the user, with a
//  Liquid Glass HUD. Tap or step through planets to focus one in the foreground; the rest
//  keep orbiting behind it.
//

import SwiftUI

@available(iOS 18, *)
struct ARSolarSystemScreen: View {
    @Environment(SolarSystemModel.self) private var model
    @Environment(AppRouter.self) private var router
    @State private var store = ARExperienceStore()

    private var ordered: [Planet] { model.orbitingBodies }
    private var focusedPlanet: Planet? { model.planets.first { $0.id == store.focusedID } }

    var body: some View {
        ZStack {
            switch store.phase {
            case .unsupported:
                unsupportedState
            case .placing, .exploring:
                ARContainerView(planets: model.planets, focusedID: store.focusedID, store: store) { id in
                    if let planet = model.planets.first(where: { $0.id == id }) { focus(planet) }
                }
                .ignoresSafeArea()
                hud
            }
        }
        .foregroundStyle(.white)
    }

    // MARK: - Interaction

    private func focus(_ planet: Planet) {
        withAnimation(Theme.Motion.interactive) {
            store.send(.focus(planet.id))
            model.send(.select(planet))
        }
    }

    private func step(_ delta: Int) {
        guard !ordered.isEmpty else { return }
        let index: Int
        if let current = store.focusedID, let i = ordered.firstIndex(where: { $0.id == current }) {
            index = (i + delta + ordered.count) % ordered.count
        } else {
            index = 0
        }
        focus(ordered[index])
    }

    // MARK: - HUD

    private var hud: some View {
        VStack {
            HStack {
                backButton
                Spacer()
            }
            Spacer()
            bottomBar
        }
        .padding(Theme.Spacing.m)
    }

    private var backButton: some View {
        Button { withAnimation(Theme.Motion.transition) { router.send(.showSystem) } } label: {
            Label("Map", systemImage: "chevron.left")
                .font(.headline).padding(.horizontal, Theme.Spacing.m).frame(height: 40)
        }
        .glassPill()
        .accessibilityLabel("Back to the map")
    }

    @ViewBuilder
    private var bottomBar: some View {
        if store.phase == .placing {
            Label("Bringing the system in front of you…", systemImage: "sparkles")
                .font(Theme.Typography.caption)
                .padding(.horizontal, Theme.Spacing.l).frame(height: 44)
                .glassPill().transition(.opacity)
        } else if let planet = focusedPlanet {
            focusControls(planet)
                .transition(.move(edge: .bottom).combined(with: .opacity))
        } else {
            Label("Tap a planet to focus it", systemImage: "hand.tap")
                .font(Theme.Typography.caption)
                .padding(.horizontal, Theme.Spacing.l).frame(height: 44)
                .glassPill().transition(.opacity)
        }
    }

    private func focusControls(_ planet: Planet) -> some View {
        VStack(spacing: Theme.Spacing.m) {
            HStack(spacing: Theme.Spacing.l) {
                stepButton("chevron.left", label: "Previous planet") { step(-1) }
                VStack(spacing: 0) {
                    Text(planet.displayName).font(Theme.Typography.title)
                    Text("\(planet.numberOfNaturalSatellites) moons · \(planet.hasRingSystem ? "rings" : "no rings")")
                        .font(Theme.Typography.caption).foregroundStyle(.secondary)
                }
                .frame(minWidth: 160)
                .contentTransition(.opacity)
                stepButton("chevron.right", label: "Next planet") { step(1) }
            }
            .padding(.horizontal, Theme.Spacing.l).padding(.vertical, Theme.Spacing.s)
            .glassCard(cornerRadius: Theme.Radius.pill)

            HStack(spacing: Theme.Spacing.m) {
                Button { withAnimation(Theme.Motion.interactive) { store.send(.focus(nil)) } } label: {
                    Label("System", systemImage: "circle.hexagongrid")
                        .font(.subheadline).padding(.horizontal, Theme.Spacing.l).frame(height: 44)
                }
                .glassPill()

                Button { withAnimation(Theme.Motion.transition) { router.send(.showDetail) } } label: {
                    Label("Explore \(planet.displayName)", systemImage: "sparkles")
                        .font(.headline).padding(.horizontal, Theme.Spacing.l).frame(height: 44)
                }
                .glassPill()
            }
        }
    }

    private func stepButton(_ icon: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon).font(.title3).frame(width: 44, height: 44)
        }
        .glassPill()
        .accessibilityLabel(label)
    }

    // MARK: - Unsupported

    private var unsupportedState: some View {
        ZStack {
            StarFieldView()
            VStack(spacing: Theme.Spacing.l) {
                Image(systemName: "arkit").font(.system(size: 52, weight: .light)).foregroundStyle(Theme.Palette.accent)
                Text("AR needs a physical device").font(Theme.Typography.title)
                Text("World tracking isn't available here. Run SolarLenz on an iPhone or iPad to see the solar system appear right in front of you.")
                    .font(Theme.Typography.body).foregroundStyle(.secondary).multilineTextAlignment(.center)
                Button("Back to the map") { withAnimation(Theme.Motion.transition) { router.send(.showSystem) } }
                    .padding(.horizontal, Theme.Spacing.l).padding(.vertical, Theme.Spacing.s).glassPill()
            }
            .padding(Theme.Spacing.xl)
        }
    }
}
