//
//  ARContainerView.swift
//  SolarLenz
//
//  RealityKit AR. A big solar system fixed in front of the user: log-spaced so the inner
//  planets aren't smushed, real elliptical orbits with the Sun at a focus, each body spinning
//  on its true axial tilt. Inspect mode pulls a planet close without moving the system; follow
//  mode keeps that planet close while the rest of the system moves around its live orbit.
//

import SwiftUI
import RealityKit
import ARKit
import Combine

@available(iOS 18, *)
struct ARContainerView: UIViewRepresentable {
    let planets: [Planet]
    let focusedID: Int?
    let focusMode: ARExperienceStore.FocusMode
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
        context.coordinator.setFocus(focusedID, mode: focusMode)
    }

    static func dismantleUIView(_ uiView: ARView, coordinator: Coordinator) {
        coordinator.teardown()
    }

    // MARK: - Coordinator

    @MainActor
    final class Coordinator: NSObject, ARSessionDelegate {
        private struct Spin { var axis: SIMD3<Float>; var rate: Float }

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
        private var focusMode: ARExperienceStore.FocusMode = .inspect
        private var hasPlaced = false
        private var didBuild = false
        private var attachTime = Date()
        private var homePosition: SIMD3<Float>?

        // Layout, in metres.
        private let sunDiameter: Float = 0.40
        private let minOrbit: Float = 0.18
        private let maxOrbit: Float = 0.48
        private let placementDistance: Float = 0.58
        private let placementTimeout: TimeInterval = 3.0
        private let inspectDistance: Float = 0.32
        private let followDistance: Float = 0.36
        private let focusedDiameter: Float = 0.44
        private let secondsPerReferenceOrbit: TimeInterval = 180
        private let speedCompression: Double = 0.48
        private let visualInclinationMultiplier = 2.4
        private let ringSegments = 128

        private let referencePeriodDays: Double
        private let minSemiMajorAxis: Double
        private let maxSemiMajorAxis: Double
        private let minPhysicalRadiusKm: Double
        private let maxPhysicalRadiusKm: Double

        init(planets: [Planet], store: ARExperienceStore, onTapPlanet: @escaping (Int) -> Void) {
            self.planets = planets
            self.orbiting = planets.filter { !$0.isStar }
            self.store = store
            self.onTapPlanet = onTapPlanet
            self.referencePeriodDays = orbiting.map(\.siderealOrbitPeriodDays).max() ?? 1
            let axes = orbiting.map { max($0.semiMajorAxis10e6Km, 0.001) }
            self.minSemiMajorAxis = axes.min() ?? 1
            self.maxSemiMajorAxis = axes.max() ?? 1
            let radii = orbiting.map(\.volumetricMeanRadiusKm).filter { $0 > 0 }
            self.minPhysicalRadiusKm = radii.min() ?? 1
            self.maxPhysicalRadiusKm = radii.max() ?? 1
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

        func setFocus(_ id: Int?, mode: ARExperienceStore.FocusMode) {
            focusedID = id
            focusMode = id == nil ? .inspect : mode
        }

        // MARK: Placement

        private func placeSystemIfReady() {
            guard !hasPlaced, let arView, let frame = arView.session.currentFrame else { return }
            let normal: Bool = { if case .normal = frame.camera.trackingState { return true }; return false }()
            guard normal || Date().timeIntervalSince(attachTime) >= placementTimeout else { return }

            let center = pointInFrontOfCamera(distance: placementDistance) ?? .zero

            var m = matrix_identity_float4x4
            m.columns.3 = SIMD4<Float>(center.x, center.y, center.z, 1)
            let anchor = AnchorEntity(world: m)
            arView.scene.addAnchor(anchor)
            systemAnchor = anchor
            homePosition = center
            hasPlaced = true

            if !didBuild {
                didBuild = true
                Task { [weak self] in
                    await self?.buildSystem(on: anchor)
                    self?.pinAnchorInFront(anchor, distance: self?.placementDistance ?? 0.58)
                    self?.store.send(.systemPlaced)
                }
            } else {
                pinAnchorInFront(anchor, distance: placementDistance)
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

            // Real axial tilt and sidereal rotation, visually compressed so no body blurs or
            // freezes. High-obliquity planets read as retrograde.
            let obliquityDegrees = planet.obliquityToOrbitDeg
            let obliquity = Float(radians(obliquityDegrees))
            let tilt = simd_quatf(angle: obliquity, axis: SIMD3<Float>(0, 0, 1))
            let axis = simd_normalize(tilt.act(SIMD3<Float>(0, 1, 0)))
            let rotationHours = abs(planet.siderealRotationPeriodHrs ?? planet.lengthOfDayHrs)
            let isRetrograde = obliquityDegrees > 90
            let rate = planet.isStar
                ? 0.10
                : Float(OrbitMath.compressedRotationRate(
                    rotationPeriodHours: rotationHours,
                    secondsPerEarthDay: 10,
                    speedCompression: 0.45,
                    minimumRate: 0.04,
                    maximumRate: 1.2,
                    retrograde: isRetrograde
                ))
            spins[planet.id] = Spin(axis: axis, rate: rate)
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
            guard !planet.isStar else { return sunDiameter }
            return Float(OrbitMath.compressedDiameter(
                physicalRadius: planet.volumetricMeanRadiusKm,
                minPhysicalRadius: minPhysicalRadiusKm,
                maxPhysicalRadius: maxPhysicalRadiusKm,
                minDiameter: 0.075,
                maxDiameter: 0.30
            ))
        }

        // MARK: Orbit geometry (log spacing + real ellipse with Sun at a focus)

        private func semiMajor(for planet: Planet) -> Float {
            Float(OrbitMath.logarithmicOrbitRadius(
                semiMajorAxis: planet.semiMajorAxis10e6Km,
                minSemiMajorAxis: minSemiMajorAxis,
                maxSemiMajorAxis: maxSemiMajorAxis,
                minRadius: Double(minOrbit),
                maxRadius: Double(maxOrbit)
            ))
        }

        /// Position on the planet's Keplerian orbit, Sun at a focus, with real inclination.
        private func orbitPosition(for planet: Planet, at time: TimeInterval) -> SIMD3<Float> {
            let a = semiMajor(for: planet)
            let meanAnomaly = OrbitMath.meanAnomaly(
                elapsed: time,
                periodDays: planet.siderealOrbitPeriodDays,
                referencePeriodDays: referencePeriodDays,
                secondsPerReferenceOrbit: secondsPerReferenceOrbit,
                phase: Double(planet.id) * 0.7,
                speedCompression: speedCompression
            )
            let position = OrbitMath.keplerianPosition(
                semiMajorAxis: Double(a),
                eccentricity: planet.orbitEccentricity,
                meanAnomaly: meanAnomaly,
                inclinationRadians: visualInclination(for: planet),
                longitudeOfAscendingNode: longitudeOfAscendingNode(for: planet),
                argumentOfPerihelion: argumentOfPerihelion(for: planet)
            )
            return SIMD3<Float>(Float(position.x), Float(position.y), Float(position.z))
        }

        private func makeOrbitRing(for planet: Planet) -> Entity {
            let ring = Entity()
            let semiMajorAxis = Double(semiMajor(for: planet))
            let inclination = visualInclination(for: planet)
            let ascendingNode = longitudeOfAscendingNode(for: planet)
            let perihelion = argumentOfPerihelion(for: planet)
            let pts: [SIMD3<Float>] = (0...ringSegments).map { i in
                let anomaly = Double(i) / Double(ringSegments) * 2 * Double.pi
                let position = OrbitMath.keplerianPosition(
                    semiMajorAxis: semiMajorAxis,
                    eccentricity: planet.orbitEccentricity,
                    meanAnomaly: anomaly,
                    inclinationRadians: inclination,
                    longitudeOfAscendingNode: ascendingNode,
                    argumentOfPerihelion: perihelion
                )
                return SIMD3<Float>(Float(position.x), Float(position.y), Float(position.z))
            }
            var mat = UnlitMaterial(color: UIColor(planet.displayColor).withAlphaComponent(0.55))
            mat.blending = .transparent(opacity: .init(floatLiteral: 0.55))
            for i in 0..<ringSegments {
                let p0 = pts[i], p1 = pts[i + 1]
                let dir = p1 - p0
                let len = simd_length(dir)
                guard len > 0 else { continue }
                let seg = ModelEntity(mesh: .generateBox(width: 0.0024, height: 0.0024, depth: len), materials: [mat])
                seg.position = (p0 + p1) / 2
                seg.orientation = simd_quatf(from: SIMD3<Float>(0, 0, 1), to: dir / len)
                ring.addChild(seg)
            }
            return ring
        }

        private func radians(_ degrees: Double) -> Double {
            degrees * Double.pi / 180
        }

        private func visualInclination(for planet: Planet) -> Double {
            let degrees = min(abs(planet.orbitInclinationDeg ?? 0) * visualInclinationMultiplier, 24)
            return radians(degrees)
        }

        private func longitudeOfAscendingNode(for planet: Planet) -> Double {
            Double(planet.id) * 0.43
        }

        private func argumentOfPerihelion(for planet: Planet) -> Double {
            Double(planet.id) * 0.71
        }

        private func makeLabel(for planet: Planet) -> Entity {
            let holder = Entity()
            holder.name = "label-\(planet.id)"
            var mat = UnlitMaterial(color: .white.withAlphaComponent(0.85))
            mat.blending = .transparent(opacity: .init(floatLiteral: 0.85))
            let text = ModelEntity(mesh: .generateText(planet.displayName, extrusionDepth: 0.001,
                                                       font: .systemFont(ofSize: 0.035), alignment: .center),
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

            if store.phase == .placing {
                pinAnchorInFront(anchor, distance: placementDistance)
            } else {
                updateAnchorTracking(anchor: anchor)
            }

            for planet in planets {
                guard let container = containers[planet.id] else { continue }

                // Spin the model on its real, tilted axis.
                if let model = models[planet.id], let spin = spins[planet.id] {
                    model.orientation = simd_mul(simd_quatf(angle: spin.rate * Float(deltaTime), axis: spin.axis), model.orientation)
                }

                let localPosition: SIMD3<Float> = planet.isStar ? .zero : orbitPosition(for: planet, at: elapsed)
                let isFocused = planet.id == focusedID
                let isInspecting = isFocused && focusMode == .inspect
                container.position = localPosition

                if isInspecting, let focusWorld = focusWorldPosition(distance: inspectDistance) {
                    let current = container.position(relativeTo: nil)
                    let next = simd_mix(current, focusWorld, SIMD3<Float>(repeating: 0.22))
                    container.setPosition(next, relativeTo: nil)
                }

                let targetScale: Float
                if isFocused {
                    targetScale = focusedDiameter / max(targetDiameter[planet.id] ?? focusedDiameter, 0.0001)
                } else {
                    targetScale = 1
                }
                container.scale = simd_mix(
                    container.scale,
                    SIMD3<Float>(repeating: targetScale),
                    SIMD3<Float>(repeating: 0.16)
                )

                if let label = anchor.children.first(where: { $0.name == "label-\(planet.id)" }) {
                    let d = targetDiameter[planet.id] ?? 0.05
                    label.position = localPosition + SIMD3<Float>(0, d / 2 + 0.04, 0)
                    label.isEnabled = !isFocused   // the HUD names the focused one
                    faceCamera(label)
                }
            }
        }

        private func updateAnchorTracking(anchor: AnchorEntity) {
            guard let homePosition else { return }

            let desired: SIMD3<Float>
            if focusMode == .track,
               let focusedID,
               let planet = orbiting.first(where: { $0.id == focusedID }),
               let focusWorld = focusWorldPosition(distance: followDistance) {
                desired = focusWorld - orbitPosition(for: planet, at: elapsed)
            } else {
                desired = homePosition
            }

            let current = anchor.position(relativeTo: nil)
            let easing: Float = focusMode == .track ? 0.10 : 0.06
            let next = simd_mix(current, desired, SIMD3<Float>(repeating: easing))
            anchor.setPosition(next, relativeTo: nil)
        }

        private func pinAnchorInFront(_ anchor: AnchorEntity, distance: Float) {
            guard let center = pointInFrontOfCamera(distance: distance) else { return }
            anchor.setPosition(center, relativeTo: nil)
            homePosition = center
        }

        /// World point directly in front of the camera at the requested distance.
        private func focusWorldPosition(distance: Float) -> SIMD3<Float>? {
            pointInFrontOfCamera(distance: distance)
        }

        private func pointInFrontOfCamera(distance: Float) -> SIMD3<Float>? {
            guard let arView else { return nil }
            let t = arView.cameraTransform.matrix
            let cam = SIMD3<Float>(t.columns.3.x, t.columns.3.y, t.columns.3.z)
            var fwd = -SIMD3<Float>(t.columns.2.x, t.columns.2.y, t.columns.2.z)
            let l = simd_length(fwd); fwd = l > 0 ? fwd / l : SIMD3<Float>(0, 0, -1)
            return cam + fwd * distance
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
