//
//  ARCoordinator.swift
//  2D SolarSystem
//
//  Created by David Rohweder on 11/28/22.
//

import Foundation
import UIKit

class ARCoordinator: NSObject, UIGestureRecognizerDelegate {
    var ar_main: ViewController
    
    init(_self: ViewController) {
        ar_main = _self
    }
    
    @objc func selectPlanet(recognizer:UITapGestureRecognizer) {
        if recognizer.state == .ended {
            let location: CGPoint = recognizer.location(in: ar_main.sceneView)
            let hits = ar_main.sceneView.hitTest(location, options: nil)
            if !hits.isEmpty {
                for hit in hits {
                    let tappedNode = hit.node
                    figureOutNextMove(hit_name: tappedNode.name!)
                }
            }
        }
        
    }
    
    // if directions enabled then simply prompt the direction sheet and update trav planet
    func figureOutNextMove(hit_name: String) {
        let real_name = extractRealPlanetName(hit_name: hit_name)
        guard real_name != "" else {return} // bad op dont do anything with it
        
        if ar_main.manager.enable_AR_directions {
            ar_main.manager.ar_travelPlanet = real_name
            ar_main.manager.show_AR_commands.toggle()
        } else {
            setCurrentPlanet(real_name: real_name)
        }
        
    }
    
    // format ex sun_Cube_001 --> [0] == sun
    func extractRealPlanetName(hit_name: String) -> String {
        guard hit_name != "" else {return ""}
        let components = hit_name.components(separatedBy: "_")
        return components[0]
    }
    
    // func change current planet
    func setCurrentPlanet(real_name: String) {
        ar_main.manager.currentPlanet = ar_main.manager.planets.first(where: { $0.name == real_name }) ?? ar_main.manager.planets[0]
    }
    
}
