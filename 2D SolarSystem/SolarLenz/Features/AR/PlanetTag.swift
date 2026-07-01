//
//  PlanetTag.swift
//  SolarLenz
//
//  A RealityKit component that ties an entity back to its domain `Planet`.
//

import RealityKit

/// Marks a RealityKit entity as a planet, carrying the domain `Planet.id`.
///
/// Tap hit-testing reads this component instead of parsing node names — the original
/// SceneKit code depended on a fragile `"<name>_Cube_001"` string convention that did not
/// even match the actual USDZ prim names. With a component, the models are used verbatim.
struct PlanetTag: Component {
    let planetID: Int
}
