//
//  PlanetManager_LowPower.swift
//  2D SolarSystem
//
//  Created by David Rohweder on 12/2/22.
//

import Foundation

extension PlanetManager {
    
    func checkLowPower() {
        self.lowPower = ProcessInfo.processInfo.isLowPowerModeEnabled
    }
    
    @objc func recvPowerChange(_ notification: Notification) {
        self.lowPower = ProcessInfo.processInfo.isLowPowerModeEnabled
    }
    
}
