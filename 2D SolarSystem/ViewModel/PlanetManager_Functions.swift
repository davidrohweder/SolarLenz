//
//  PlanetManager_Functions.swift
//  2D SolarSystem
//
//  Created by David Rohweder on 11/29/22.
//

import Foundation

extension PlanetManager {
        
    // offsets for arcs & planets .. not computed vars so that they dont keep getting recomputed
    func compute_all_planet_offets() {
        // need to mutate the planets
        for (index,_) in planets.enumerated() {
            planets[index].offsetAngle = getAngle()
            planets[index].offsetPoint = planet_pos_point(planet: planets[index])
        }
        
    }
    
    func getAngle() -> Int {
        return Int.random(in: 0...360)
    }
    
    func planet_pos_point(planet: PlanetModel) -> CGPoint {
        let angle = Double(planet.offsetAngle!) * (.pi / 180.0) // angle to rads
        let coord_x = planet.radius * cos(angle)
        let coord_y = planet.radius * sin(angle) * -1 // since phones down axis is pos need to invert
        
        return CGPoint(x: coord_x, y: coord_y)
        
    }
    
    func calcPlanetDistance() -> Double {
        let planet_dest = planets.first(where: { $0.name == ar_travelPlanet }) ?? planets[0]
        let distance = abs(planet_dest.distanceFromSun - currentPlanet.distanceFromSun)
        
        return distance
    }
    
}
