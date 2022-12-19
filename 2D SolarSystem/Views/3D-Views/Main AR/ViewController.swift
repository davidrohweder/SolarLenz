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
    private var adjusted_origin: CGFloat // adjusted origin with current planet
    private let originZ = -4.0 // arbritarily looks nice at this z offset
    @State var sceneView = ARSCNView()
    
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
        let shrinkageScale = 0.0015 //* planet.scale // Make planets viewable and someone marginally scaled
        objectNode.scale = SCNVector3(shrinkageScale, shrinkageScale, shrinkageScale) // you would not believe how long this took me to figure out lol. The bounding box is 1000,1000,1000 but the visible scale is very very small, so the objects were so large they never appeared.
        
        // give inital starting coordinates (kind of based on 2d starting coords)
        let ar_offset =
        let zedOff: CGFloat = ar_offset + adjusted_origin
        let yOff: CGFloat = 0.0
        let xOff: CGFloat = 0.0
        objectNode.position = SCNVector3(xOff, yOff, zedOff) // galactic coordinates
        
        if planet.id == 0 || planet.id == manager.currentPlanet.id {
            return objectNode // We dont want to give the sun an orbital rotation and we dont wanna give the curent planet an orbital rotation
        }
        
        // rotate object with rel to space
        let moveCircular = generateOffsetAction(offset: abs(zedOff), time: planet.orbitTime)
        objectNode.runAction(SCNAction.repeatForever(moveCircular))
        
        return objectNode
    }
    
    func generateOffsetAction(offset: CGFloat, time: Double) -> SCNAction {
        let quarter_interval = time / 2
        
        // Since I only mod the z and x this sequences rotates the planets via each quadrant
        let leftAction = SCNAction.moveBy(x: -offset, y: 0.0, z: offset, duration: quarter_interval)
        let downAction = SCNAction.moveBy(x: offset, y: 0.0, z: offset, duration: quarter_interval)
        let rightAction = SCNAction.moveBy(x: offset, y: 0.0, z: -offset, duration: quarter_interval)
        let upAction = SCNAction.moveBy(x: -offset, y: 0.0, z: -offset, duration: quarter_interval)
        
        return SCNAction.sequence([leftAction,downAction,rightAction, upAction])
    }
    
    
    //MARK: Adjust world coordinates
    func adjust_to_current_planet() -> Void {
        adjusted_origin = (manager.currentPlanet.radius / 50) + originZ
    }
    
    //MARK: Make the world
    func makeUIView(context: Context) -> ARSCNView {
        
        
        
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
