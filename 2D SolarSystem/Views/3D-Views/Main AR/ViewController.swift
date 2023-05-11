//
//  ViewController.swift
//  Solar System
//
//  Created by David Rohweder on 10/25/22.
//

import SwiftUI
import ARKit
import SceneKit
import UIKit

struct ViewController: UIViewRepresentable {
    @ObservedObject var manager: PlanetManager
    private let originZ = -4.0 // offset of current planet
    @State var sceneView = ARSCNView()
    static var curr_angle = 0.0
    private let planet_diff = -2.0
    
    init(_manager: PlanetManager) {
        manager = _manager
    }
    
    //MARK: Helper Functions
    func generatePlanet(planet: PlanetModel) -> SCNNode {
        let planetName: String = "3d-" + planet.name
        let scene = SCNScene(named: planetName + PlanetModel.dim_three_ext)
        let nodeName = planet.name.lowercased() + "_" + PlanetModel.graph_name
        let objectNode = scene!.rootNode.childNode(withName: nodeName, recursively: true)!
        
        // for hit identification purposes
        objectNode.name = planet.name
        
        // rotate object without rel to space
        objectNode.runAction(SCNAction.repeatForever(SCNAction.rotateBy(x: 1, y: 1, z: 0, duration: 10.0)))
        
        // shrink model to rel size
        var shrinkageScale = 0.0015
        if planet.id != manager.currentPlanet.id {
            shrinkageScale *= planet.scale // Make planets viewable and some marginally scaled
        }
        
        objectNode.scale = SCNVector3(shrinkageScale, shrinkageScale, shrinkageScale) // you would not believe how long this took me to figure out lol. The bounding box is 1000,1000,1000 but the visible scale is very very small, so the objects were so large they never appeared.
        
        // give inital starting coordinates
        let planet_offset = planet_start(planet: planet) + originZ
        var zedOff: CGFloat = planet_offset
        let yOff: CGFloat = 0.0
        var xOff: CGFloat = 0.0
        
        var pos_unitCircle = false
        if planet.id >= manager.currentPlanet.id {
            zedOff += abs(current_adjusted)
        } else {
            pos_unitCircle = true
            zedOff += abs(originZ) + abs(current_adjusted)
        }
        
        let radius = zedOff // pre-random-coordinate radius off origin || needed for radius of calculating moving paths
        
        // Do not want to give the sun a random pos give it one on the axis
        if planet.id != 0 && planet.id != manager.currentPlanet.id {
            let converted_point = random_Z_X(radius: radius)
            zedOff = converted_point.y
            
            if pos_unitCircle {
                zedOff = abs(zedOff)
            }
            
            xOff = converted_point.x
        }
                
        objectNode.position = SCNVector3(xOff, yOff, zedOff) // galactic coordinates
        
        if planet.id == 0 || planet.id == manager.currentPlanet.id {
            return objectNode // We dont want to give the sun an orbital rotation and we dont want to give the curent planet an orbital rotation
        }
        
        // rotate object with rel to space
        let moveCircular = generateOffsetAction(radius: radius, pos: pos_unitCircle, time: planet.orbitTime)
        objectNode.runAction(SCNAction.repeatForever(moveCircular))
        
        return objectNode
    }
    
    func random_Z_X(radius: CGFloat) -> CGPoint {
        let deg_angle = manager.getAngle()
        let angle = Double(deg_angle) * (.pi / 180.0)
        var point: CGPoint = CGPoint()
        
        point.x = radius * cos(angle)
        point.y = radius * sin(angle)
        ViewController.curr_angle = angle
        
        return point
    }
    
    // Array of sequences mimicing a circular orbit
    func generateOffsetAction(radius: CGFloat, pos: Bool, time: Double) -> SCNAction {
        let per_action_time = time / 1.25
        var mod_angle = CGFloat(ViewController.curr_angle)
        var sequences: [SCNAction] = []
        
        for _ in 0..<360 {
            mod_angle = mod_angle > 360 ? 0 : mod_angle + 1
            
            var nextZ = sin(mod_angle) * radius
            let nextX = cos(mod_angle) * radius
            
            if pos {
                nextZ = abs(nextZ)
            }
            
            let vector = SCNVector3(nextX, 0.0, nextZ)
            let action = SCNAction.move(to: vector, duration: per_action_time)
            
            sequences.append(action)
        }
        
        return SCNAction.sequence(sequences)
    }
    
    func planet_start(planet: PlanetModel) -> CGFloat {
        CGFloat(planet.id) * planet_diff
    }
    
    var current_adjusted: CGFloat {
        CGFloat(manager.currentPlanet.id) * planet_diff
    }
    
    //MARK: Make the world
    func makeUIView(context: Context) -> ARSCNView {
               
        //TODO: Change AR background color -> Transitions or UIColor on camera image..
        
        for planet in manager.planets {
            //TODO: dispatch queue to make the process faster...
            sceneView.scene.rootNode.addChildNode(generatePlanet(planet: planet))
        }
        
        // tap planet gesture
        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(context.coordinator.selectPlanet(recognizer:)))
        tapGesture.delegate = context.coordinator
        sceneView.addGestureRecognizer(tapGesture)

        let configuration = ARWorldTrackingConfiguration()
        sceneView.session.run(configuration)
        
        return sceneView
    }
    
    //MARK: Gesture Coordinator
    // need objc selector but struct cant use objc bc it is a class based, so need class coordinator for gesture
    func makeCoordinator() -> ARCoordinator {
            return ARCoordinator(_self: self)
        }
    
    //MARK: Update World
    func updateUIView(_ ar_sceneView: ARSCNView, context: Context) {
        sceneView.scene.rootNode.enumerateChildNodes { (node, stop) in
            node.enumerateChildNodes { (node, stop) in
                node.removeFromParentNode() // without inner-remove-enumerate then the nodes are left as textureless objects still in circulation
            }
        }
        
        let _ = makeUIView(context: context)
    }
    
}
