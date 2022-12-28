//
//  PlanetModel_ComputedVars.swift
//  2D SolarSystem
//
//  Created by David Rohweder on 11/17/22.
//

import Foundation

//MARK: COMPUTED VARIABLES
extension PlanetModel {
    
    var radius: CGFloat {
        CGFloat(id * 23)
    }
    
    var endArcDegress: Double {
        return self.offsetAngle! - 20 < 0 ? Double(360 + offsetAngle! - 20) : Double(self.offsetAngle! - 20)
    }
    
    var initalY: CGFloat {
        1
    }
    
    var pathRadius: CGFloat {
        guard radius != 0 else {return 1.0}
        return (radius * 2) // circle w & h = offset x - center
    }
    
    var orbitTime: Double {
        Double(id) + 10.0
    }
    
    var lightyears: Double {
        self.distanceFromSun * 1.057e-13
    }
    
}
