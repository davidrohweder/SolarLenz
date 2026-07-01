//
//  ARContainerView.swift
//  SolarLenz
//
//  RealityKit AR. A big solar system fixed ~1.2 m in front of the user: log-spaced so the
//  inner planets aren't smushed, real elliptical orbits with the Sun at a focus, each body
//  spinning on its true axial tilt. Continuous, bright orbit rings. Tapping (or prev/next)
//  focuses a planet — it flies to just in front of you and rotates for inspection while the
//  rest of the system keeps orbiting realistically behind it.
//

import SwiftUI
import RealityKit
import ARKit
import Combine

@available(iOS 18, *)
struct ARContainerView: UIViewRepresentable {
    let planets: [Planet]
    let focusedID: Int?
    let store: ARExperienceStore
    let onTapPlanet: (Int) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(planets: planets, store: store, onTapPlanet: onTapPlanet)
    }

    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero, cameraMode: .ar, automaticallyConfigureSession: false)
        context.coordinator.attach(to: arView)
        return arView
    }

    func updateUIView(_ uiView: ARView, context: Context) {
        context.coordinator.setFocus(focusedID)
    }

    static func dismantleUIView(_ uiView: ARView, coordinator: Coordinator) {
        coordinator.teardown()
    }

    // MARK: - Coordinator

    @MainActor
    final class Coordinator: NSObject, ARSessionDelegate {
        private struct Spin { var tilt: simd_quatf; var axis: SIMD3<Float>; var rate: Float }

        private let planets: [Planet]
        private let orbiting: [Planet]
        private let store: ARExperienceStore
        private let onTapPlanet: (Int) -> Void

        private weak var arView: ARView?
        private var systemAnchor: AnchorEntity?
        private var containers: [Int: Entity] = [:]
        private var models: [Int: Entity] = [:]
        private var targetDiameter: [Int: Float] = [:]
        private var spins: [Int: Spin] = [:]

        private var updateSubscription: Cancellable?
        private var elapsed: TimeInterval = 0
        private var focusedID: Int?
        private var hasPlaced = false
        private var didBuild = false
        private var attachTime = Date()

        // Layout, in metres.
        private let sunDiameter: Float = 0.14
        private let minOrbit: Float = 0.22
        private let maxOrbit: Float = 0.90
        private let placementDistance: Float = 1.2
        private let placementTimeout: TimeInterval = 3.0
        private let focusDistance: Float = 0.5
        private let focusDiameter: Float = 0.22
        private let secondsPerReferenceOrbit: TimeInterval = 60
        private let speedCompression: Double = 0.4
        private let ringSegments = 64

        private let referencePeriodDays: Double
        private let minLogA: Double
        private let maxLogA: Double

        init(planets: [Planet], store: ARExperienceStore, onTapPlanet: @escaping (Int) -> Void) {
            self.planets = planets
            self.orbiting = planets.filter { !$0.isStar }
            self.store = store
            self.onTapPlanet = onTapPlanet
            self.referencePeriodDays = orbiting.map(\.siderealOrbitPeriodDays).max() ?? 1
            let axes = orbiting.map { max($0.semiMajorAxis10e6Km, 0.001) }
            self.minLogA = axes.map(log).min() ?? 0
            self.maxLogA = axes.map(log).max() ?? 1
        }

        func attach(to arView: ARView) {
            self.arView = arView
            attachTime = Date()
            guard ARWorldTrackingConfiguration.isSupported else { return }
            PlanetTag.registerComponent()

            let config = ARWorldTrackingConfiguration()
            config.planeDetection = []
            config.environmentTexturing = .automatic
            arView.session.delegate = self
            arView.session.run(config, options: [.resetTracking, .removeExistingAnchors])
            arView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleTap(_:))))

            updateSubscription = arView.scene.subscribe(to: SceneEvents.Update.self) { [weak self] event in
                self?.step(deltaTime: event.deltaTime)
            }
        }

        func teardown() {
            updateSubscription?.cancel()
            updateSubscription = nil
            arView?.session.pause()
        }

        func setFocus(_ id: Int?) { focusedID = id }

        // MARK: Placement

        private func placeSystemIfReady() {
            guard !hasPlaced, let arView, let frame = arView.session.currentFrame else { return }
            let normal: Bool = { if case .normal = frame.camera.trackingState { return true }; return false }()
            guard normal || Date().timeIntervalSince(attachTime) >= placementTimeout else { return }

            let t = frame.camera.transform
            let cam = SIMD3<Float>(t.columns.3.x, t.columns.3.y, t.columns.3.z)
            var fwd = -SIMD3<Float>(t.columns.2.x, t.columns.2.y, t.columns.2.z)
            let l = simd_length(fwd); fwd = l > 0 ? fwd / l : SIMD3<Float>(0, 0, -1)
            let center = cam + fwd * placementDistance

            var m = matrix_identity_float4x4
            m.columns.3 = SIMD4<Float>(center.x, center.y, center.z, 1)
            let anchor = AnchorEntity(world: m)
            arView.scene.addAnchor(anchor)
            systemAnchor = anchor
            hasPlaced = true

            if !didBuild {
                didBuild = true
                Task { [weak self] in
                    await self?.buildSystem(on: anchor)
                    self?.store.send(.systemPlaced)
                }
            } else {
                store.send(.systemPlaced)
            }
        }

        // MARK: Build

        private func buildSystem(on anchor: AnchorEntity) async {
            for planet in planets {
                let (container, model) = await makeBody(for: planet)
                containers[planet.id] = container
                models[planet.id] = model
                anchor.addChild(container)
                anchor.addChild(makeLabel(for: planet))
                if !planet.isStar {
                    anchor.addChild(makeOrbitRing(for: planet))
                }
            }
        }

        private func makeBody(for planet: Planet) async -> (Entity, Entity) {
            let diameter = diameter(for: planet)
            targetDiameter[planet.id] = diameter

            let model: Entity
            if let loaded = try? await Entity(named: planet.modelResourceName) {
                normalize(loaded, toDiameter: diameter)
                model = loaded
            } else {
                model = ModelEntity(mesh: .generateSphere(radius: diameter / 2),
                                    materials: [SimpleMaterial(color: UIColor(planet.displayColor), isMetallic: false)])
            }

            // Real axial tilt: obliquity to orbit, spinning around that tilted pole. Spin rate
            // scales with the (inverse) length of day, so Jupiter whirls and Venus barely moves.
            let obliquity = Float((planet.obliquityToOrbitDeg) * .pi / 180)
            let tilt = simd_quatf(angle: obliquity, axis: SIMD3<Float>(0, 0, 1))
            let axis = simd_normalize(tilt.act(SIMD3<Float>(0, 1, 0)))
            let day = max(planet.lengthOfDayHrs, 1)
            let rate = planet.isStar ? 0.12 : Float(min(max(24.0 / day, 0.05), 1.2))
            spins[planet.id] = Spin(tilt: tilt, axis: axis, rate: rate)
            model.orientation = tilt

            let container = Entity()
            container.addChild(model)
            container.components.set(PlanetTag(planetID: planet.id))
            container.components.set(InputTargetComponent())
            container.components.set(CollisionComponent(shapes: [.generateSphere(radius: max(diameter * 0.9, 0.045))]))
            return (container, model)
        }

        private func normalize(_ entity: Entity, toDiameter target: Float) {
            let e = entity.visualBounds(relativeTo: nil).extents
            let largest = max(e.x, max(e.y, e.z))
            entity.scale = SIMD3<Float>(repeating: largest > 0 ? target / largest : 1)
        }

        private func diameter(for planet: Planet) -> Float {
            planet.isStar ? sunDiameter : 0.05 + Float(planet.scale) * 0.09
        }

        // MARK: Orbit geometry (log spacing + real ellipse with Sun at a focus)

        private func semiMajor(for planet: Planet) -> Float {
            guard maxLogA > minLogA else { return minOrbit }
            let t = (log(max(planet.semiMajorAxis10e6Km, 0.001)) - minLogA) / (maxLogA - minLogA)
            return minOrbit + (maxOrbit - minOrbit) * Float(t)
        }

        /// Position on the planet's elliptical orbit in the anchor's X–Z plane, Sun at a focus.
        private func orbitPosition(for planet: Planet, at time: TimeInterval) -> SIMD3<Float> {
            let a = semiMajor(for: planet)
            let e = Float(min(max(planet.orbitEccentricity, 0), 0.6))
            let c = a * e                                   // focus offset
            let b = a * (1 - e * e).squareRoot()            // semi-minor
            let theta = OrbitMath.angle(elapsed: time,
                                        periodDays: planet.siderealOrbitPeriodDays,
                                        referencePeriodDays: referencePeriodDays,
                                        secondsPerReferenceOrbit: secondsPerReferenceOrbit,
                                        phase: Double(planet.id) * 0.7,
                                        speedCompression: speedCompression)
            return SIMD3<Float>(c + a * cos(Float(theta)), 0, b * sin(Float(theta)))
        }

        private func makeOrbitRing(for planet: Planet) -> Entity {
            let ring = Entity()
            let a = semiMajor(for: planet)
            let e = Float(min(max(planet.orbitEccentricity, 0), 0.6))
            let c = a * e, b = a * (1 - e * e).squareRoot()
            let pts: [SIMD3<Float>] = (0...ringSegments).map { i in
                let th = Float(i) / Float(ringSegments) * 2 * .pi
                return SIMD3<Float>(c + a * cos(th), 0, b * sin(th))
            }
            var mat = UnlitMaterial(color: UIColor(planet.displayColor).withAlphaComponent(0.55))
            mat.blending = .transparent(opacity: .init(floatLiteral: 0.55))
            for i in 0..<ringSegments {
                let p0 = pts[i], p1 = pts[i + 1]
                let dir = p1 - p0
                let len = simd_length(dir)
                guard len > 0 else { continue }
                let seg = ModelEntity(mesh: .generateBox(width: 0.0018, height: 0.0018, depth: len), materials: [mat])
                seg.position = (p0 + p1) / 2
                seg.orientation = simd_quatf(from: SIMD3<Float>(0, 0, 1), to: dir / len)
                ring.addChild(seg)
            }
            return ring
        }

        private func makeLabel(for planet: Planet) -> Entity {
            let holder = Entity()
            holder.name = "label-\(planet.id)"
            var mat = UnlitMaterial(color: .white.withAlphaComponent(0.85))
            mat.blending = .transparent(opacity: .init(floatLiteral: 0.85))
            let text = ModelEntity(mesh: .generateText(planet.displayName, extrusionDepth: 0.001,
                                                       font: .systemFont(ofSize: 0.03), alignment: .center),
                                   materials: [mat])
            let w = text.visualBounds(relativeTo: text).extents.x
            text.position = SIMD3<Float>(-w / 2, 0, 0)
            holder.addChild(text)
            return holder
        }

        // MARK: Per-frame

        private func step(deltaTime: TimeInterval) {
            placeSystemIfReady()
            guard hasPlaced, let anchor = systemAnchor else { return }
            elapsed += deltaTime

            let cameraFocus = focusWorldPosition()

            for planet in planets {
                guard let container = containers[planet.id] else { continue }

                // Spin the model on its real, tilted axis.
                if let model = models[planet.id], let spin = spins[planet.id] {
                    model.orientation = simd_mul(simd_quatf(angle: spin.rate * Float(deltaTime), axis: spin.axis), model.orientation)
                }

                if planet.id == focusedID, let target = cameraFocus {
                    // Focus mode: fly the planet to just in front of the camera and hold it there,
                    // large, while everything else keeps orbiting behind it.
                    let scale = focusDiameter / max(targetDiameter[planet.id] ?? focusDiameter, 0.0001)
                    let current = container.position(relativeTo: nil)
                    let next = simd_mix(current, target, SIMD3<Float>(repeating: 0.16))
                    container.setPosition(next, relativeTo: nil)
                    container.scale = simd_mix(container.scale, SIMD3<Float>(repeating: scale), SIMD3<Float>(repeating: 0.16))
                } else {
                    if container.scale.x != 1 {
                        container.scale = simd_mix(container.scale, SIMD3<Float>(repeating: 1), SIMD3<Float>(repeating: 0.2))
                    }
                    container.position = planet.isStar ? .zero : orbitPosition(for: planet, at: elapsed)
                }

                if let label = anchor.children.first(where: { $0.name == "label-\(planet.id)" }) {
                    let d = targetDiameter[planet.id] ?? 0.05
                    label.setPosition(container.position(relativeTo: nil) + SIMD3<Float>(0, d / 2 + 0.03, 0), relativeTo: nil)
                    label.isEnabled = (planet.id != focusedID)   // the HUD names the focused one
                    faceCamera(label)
                }
            }
        }

        /// World point ~`focusDistance` m directly in front of the camera.
        private func focusWorldPosition() -> SIMD3<Float>? {
            guard let arView else { return nil }
            let t = arView.cameraTransform.matrix
            let cam = SIMD3<Float>(t.columns.3.x, t.columns.3.y, t.columns.3.z)
            var fwd = -SIMD3<Float>(t.columns.2.x, t.columns.2.y, t.columns.2.z)
            let l = simd_length(fwd); fwd = l > 0 ? fwd / l : SIMD3<Float>(0, 0, -1)
            return cam + fwd * focusDistance
        }

        private func faceCamera(_ entity: Entity) {
            guard let arView else { return }
            let cam = arView.cameraTransform.translation
            let p = entity.position(relativeTo: nil)
            entity.orientation = simd_quatf(angle: atan2(cam.x - p.x, cam.z - p.z), axis: SIMD3<Float>(0, 1, 0))
        }

        // MARK: Tap

        @objc private func handleTap(_ sender: UITapGestureRecognizer) {
            guard let arView, let hit = arView.entity(at: sender.location(in: arView)) else { return }
            var node: Entity? = hit
            while let current = node {
                if let tag = current.components[PlanetTag.self] {
                    onTapPlanet(tag.planetID)
                    return
                }
                node = current.parent
            }
        }
    }
}
