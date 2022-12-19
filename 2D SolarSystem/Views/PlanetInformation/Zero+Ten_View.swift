//
//  Zero+Ten_View.swift
//  2D SolarSystem
//
//  Created by David Rohweder on 11/26/22.
//

import SwiftUI

struct Zero_Ten_View: View {
    @EnvironmentObject var manager: PlanetManager
    let planet: PlanetModel
    var body: some View {
        VStack {
            Group {
                Text("distanceFromSun \(manager.currentPlanet.distanceFromSun)")
                Text("mass10_24Kg \(manager.currentPlanet.mass10_24Kg)")
                Text("volume10_10Km3 \(manager.currentPlanet.volume10_10Km3)")
                if manager.currentPlanet.equatorialRadius1BarLevelKm != nil {
                    Text("equatorialRadius1BarLevelKm \(manager.currentPlanet.equatorialRadius1BarLevelKm!)")
                }
                if manager.currentPlanet.polarRadiusKm != nil {
                    Text("polarRadius1BarLevelKm \(manager.currentPlanet.polarRadiusKm!)")
                }
                if manager.currentPlanet.polarRadius1BarLevelKm != nil{
                    Text("polarRadius1BarLevelKm \(manager.currentPlanet.polarRadius1BarLevelKm!)")
                }
                Text("volumetricMeanRadiusKm \(manager.currentPlanet.volumetricMeanRadiusKm)")
                if manager.currentPlanet.ellipticityFlattening != nil {
                    Text("ellipticityFlattening \(manager.currentPlanet.ellipticityFlattening!)")
                }
                Text("meanDensityKgM3 \(manager.currentPlanet.meanDensityKgM3)")
                if manager.currentPlanet.gravityEq1BarMS2 != nil {
                    Text("gravityEq1BarMS2 \(manager.currentPlanet.gravityEq1BarMS2!)")
                }
            }
            Group {
                Text("numberOfNaturalSatellites \(manager.currentPlanet.numberOfNaturalSatellites)")
                Text("planetaryRingSystem " + String(manager.currentPlanet.planetaryRingSystem))
            }
        }
    }
}

struct Zero_Ten_View_Previews: PreviewProvider {
    static var previews: some View {
        Zero_Ten_View(planet: PlanetModel.standard)
    }
}
