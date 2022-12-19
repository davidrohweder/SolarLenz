//
//  PlanetManaer_ComputedVars.swift
//  2D SolarSystem
//
//  Created by David Rohweder on 12/2/22.
//

import Foundation


extension PlanetManager {
    
    // while they are magic numbers, they are just good performance star counts
    var numStars: Int {
        self.lowPower ? 500 : 2500 // save on power computation:: noticed when testing on my iPhone
    }

}
