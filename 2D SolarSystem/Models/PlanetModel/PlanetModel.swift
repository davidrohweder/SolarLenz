//
//  PlanetModel.swift
//  2D SolarSystem
//
//  Created by David Rohweder on 10/30/22.
//

import Foundation
import SwiftUI

struct PlanetModel: Identifiable, Codable {
    
    var id: Int
    var scale: Double
    var name: String
    var colorName: String
    var distanceFromSun: Double
    var mass10_24Kg: Double
    var volume10_10Km3: Double
    var equatorialRadiusKm: Double? //optional
    var equatorialRadius1BarLevelKm: Double? // optional
    var polarRadius1BarLevelKm: Double? // optional
    var polarRadiusKm: Double? // optional
    var volumetricMeanRadiusKm: Double
    var coreRadiusKm: Double? // optional
    var ellipticityFlattening: Double? // optional
    var meanDensityKgM3: Double
    var gravityEq1BarMS2: Double? // optional
    var accelerationEq1BarMS2: Double? // optional
    var surfaceGravityMS2: Double? // optional
    var surfaceAccelerationMS2: Double? // optional
    var escapeVelocityKmS: Double
    var gMX10_6Km3S2: Double
    var bondAlbedo: Double
    var geometricAlbedo: Double
    var vBandMagnitudeV10: Double
    var solarIrradianceWM2: Double
    var blackBodyTemperatureK: Double
    var topographicRangeKm: Double? // optional
    var momentOfInertiaIMR2: Double? // optional
    var j2X106: Double
    var numberOfNaturalSatellites: Int
    var planetaryRingSystem: Bool
    var semimajorAxis10_6Km: Double
    var siderealOrbitPeriodDays: Double
    var tropicalOrbitPeriodDays: Double
    var perihelion10_6Km: Double
    var aphelion10_6Km: Double
    var synodicPeriodDays: Double? // optional 
    var meanOrbitalVelocityKmS: Double
    var maxOrbitalVelocityKmS: Double
    var minOrbitalVelocityKmS: Double
    var orbitInclinationDeg: Double
    var orbitEccentricity: Double
    var siderealRotationPeriodHrs: Double
    var lengthOfDayHrs: Double
    var obliquityToOrbitDeg: Double
    var inclinationOfEquatorDeg: Double? // optional
    
    
    //MARK: STATICS AND CONSTANTS FOR PLANET MODEL
    var offsetPoint: CGPoint?
    var offsetAngle: Int?
    static let dim_three_ext: String = ".usdz"
    static let graph_name: String = "Cube_001"
    static var standard = PlanetModel(id: 0, scale: 0.0, name: "", colorName: "white", distanceFromSun: 0.0, mass10_24Kg: 0.0, volume10_10Km3: 0.0, equatorialRadiusKm: 0.0, polarRadiusKm: 0.0, volumetricMeanRadiusKm: 0.0, coreRadiusKm: 0.0, ellipticityFlattening: 0.0, meanDensityKgM3: 0.0, surfaceGravityMS2: 0.0, surfaceAccelerationMS2: 0.0, escapeVelocityKmS: 0.0, gMX10_6Km3S2: 0.0, bondAlbedo: 0.0, geometricAlbedo: 0.0, vBandMagnitudeV10: 0.0, solarIrradianceWM2: 0.0, blackBodyTemperatureK: 0.0, topographicRangeKm: 0.0, momentOfInertiaIMR2: 0.0, j2X106: 0.0, numberOfNaturalSatellites: 0, planetaryRingSystem: false, semimajorAxis10_6Km: 0.0, siderealOrbitPeriodDays: 0.0, tropicalOrbitPeriodDays: 0.0, perihelion10_6Km: 0.0, aphelion10_6Km: 0.0, synodicPeriodDays: 0.0, meanOrbitalVelocityKmS: 0.0, maxOrbitalVelocityKmS: 0.0, minOrbitalVelocityKmS: 0.0, orbitInclinationDeg: 0.0, orbitEccentricity: 0.0, siderealRotationPeriodHrs: 0.0, lengthOfDayHrs: 0.0, obliquityToOrbitDeg: 0.0, inclinationOfEquatorDeg: 0.0)
    
}
