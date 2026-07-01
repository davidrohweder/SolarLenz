//
//  PlanetScene3DView.swift
//  SolarLenz
//
//  The app's "3D" mode: an interactive SceneKit view of a planet's bundled USDZ model —
//  drag to orbit, pinch to zoom. Uses a transparent SCNView so the model floats over the
//  dark starfield (SwiftUI's SceneView forces a white backdrop). Crash-safe, with a small
//  Earth-and-moon detail.
//

import SwiftUI
import SceneKit

@available(iOS 18, *)
struct PlanetScene3DView: View {
    let planet: Planet

    @State private var scene: SCNScene?
    @State private var failed = false

    var body: some View {
        ZStack {
            if let scene {
                SceneKitContainer(scene: scene)
                    .accessibilityLabel("3D model of \(planet.displayName). Drag to rotate.")
            } else if failed {
                PlanetSprite(planet: planet, isSelected: false)
                    .scaleEffect(2.6)
                    .accessibilityLabel(planet.displayName)
            } else {
                ProgressView().tint(.white)
            }
        }
        .onAppear(perform: load)
        .onChange(of: planet.id) { _, _ in load() }
    }

    private func load() {
        guard let loaded = SCNScene(named: "\(planet.modelResourceName).usdz") else {
            scene = nil
            failed = true
            return
        }
        let spin = SCNAction.repeatForever(.rotateBy(x: 0, y: .pi * 2, z: 0, duration: 26))
        loaded.rootNode.childNodes.forEach { $0.runAction(spin) }
        if planet.name.lowercased() == "earth" { addMoon(to: loaded) }
        scene = loaded
        failed = false
    }

    private func addMoon(to earthScene: SCNScene) {
        guard let moonScene = SCNScene(named: "3d-moon.usdz") else { return }
        let moon = moonScene.rootNode.clone()
        moon.scale = SCNVector3(0.28, 0.28, 0.28)
        moon.position = SCNVector3(360, 120, 0)
        moon.runAction(SCNAction.repeatForever(.rotateBy(x: 0, y: .pi * 2, z: 0, duration: 12)))
        let orbit = SCNNode()
        orbit.addChildNode(moon)
        orbit.runAction(SCNAction.repeatForever(.rotateBy(x: 0, y: .pi * 2, z: 0, duration: 16)))
        earthScene.rootNode.addChildNode(orbit)
    }
}

/// A transparent, camera-controllable SceneKit view. The SwiftUI `SceneView` renders an
/// opaque white background; a hand-rolled `SCNView` with `backgroundColor = .clear` and
/// `isOpaque = false` lets the app's starfield show through instead.
@available(iOS 18, *)
private struct SceneKitContainer: UIViewRepresentable {
    let scene: SCNScene

    func makeUIView(context: Context) -> SCNView {
        let view = SCNView()
        view.scene = scene
        view.backgroundColor = .clear
        view.isOpaque = false
        view.allowsCameraControl = true
        view.autoenablesDefaultLighting = true
        view.antialiasingMode = .multisampling2X
        return view
    }

    func updateUIView(_ uiView: SCNView, context: Context) {
        if uiView.scene !== scene { uiView.scene = scene }
    }
}
