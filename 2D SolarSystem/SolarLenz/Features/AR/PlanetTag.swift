//
//  PlanetTag.swift
//  SolarLenz
//
//  A RealityKit component that ties an entity back to its domain `Planet`.
//

import RealityKit

/// Marks a RealityKit entity as a planet, carrying the domain `Planet.id`.
///
/// Tap hit-testing reads this component instead of parsing model node names, so the USDZ
/// assets can be used verbatim.
struct PlanetTag: Component {
    let planetID: Int
}
