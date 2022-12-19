//
//  Load3dPlanetView.swift
//  2D SolarSystem
//
//  Created by David Rohweder on 11/16/22.
//

import SwiftUI
import SceneKit

struct Load3dPlanetView: UIViewRepresentable {
    @ObservedObject var manager: PlanetManager
    @State var view = SCNView()
    
    typealias UIViewType = SCNView
    typealias Context = UIViewRepresentableContext<Load3dPlanetView>
    
    init(_manager: PlanetManager) {
        manager = _manager
    }
    
    func makeUIView(context: Context) -> UIViewType {
        view.backgroundColor = UIColor.clear // need to clear bc there is a white box around the scenes background
        view.allowsCameraControl = true
        view.autoenablesDefaultLighting = true
        
        return view
    }
    
    // update is needed for redrawing 2d-single views when already in the 2d-single view frame
    func updateUIView(_ uiView: UIViewType, context: Context) {
        let planet_path = "3d-" + manager.currentPlanet.name.lowercased() + PlanetModel.dim_three_ext
        let new_scene = SCNScene(named: planet_path)
        let nodeName = manager.currentPlanet.name.lowercased() + "_" + PlanetModel.graph_name
        let objectNode: SCNNode = new_scene!.rootNode.childNode(withName: nodeName, recursively: true)!
        objectNode.runAction(SCNAction.repeatForever(SCNAction.rotateBy(x: 1, y: 1, z: 0, duration: 10.0))) // give the scene node a slight rotational effect
        
        if hasSpecialCase() {
            new_scene?.rootNode.addChildNode(handleSpecialCase(parent: objectNode))
        }
        
        new_scene?.rootNode.addChildNode(objectNode)
        
        view.scene = new_scene
    }
    
    func hasSpecialCase() -> Bool {
        return manager.currentPlanet.name.lowercased() == "earth" ? true : false
    }
    
    // moon node given earth_Cube_001 child nodes so when hit it makes earth current
    func handleSpecialCase(parent: SCNNode) -> SCNNode {
        let planet_path = "3d-moon" + PlanetModel.dim_three_ext
        let new_scene = SCNScene(named: planet_path)
        let nodeName = "earth_" + PlanetModel.graph_name
        let objectNode: SCNNode = new_scene!.rootNode.childNode(withName: nodeName, recursively: true)!
        
        objectNode.runAction(SCNAction.repeatForever(SCNAction.rotateBy(x: 1, y: 0, z: 0, duration: 10.0)))
        objectNode.scale = SCNVector3(0.25,0.25,0.25)
        objectNode.position = SCNVector3(-250, 400,-250)
        
        
        // rotate moon with rel to space
        let moveCircular = generateOffsetAction(offset: 500)
        objectNode.runAction(SCNAction.repeatForever(moveCircular))
        
        return objectNode
    }
    
    func generateOffsetAction(offset: CGFloat) -> SCNAction {
        let quarter_interval = 10.0 / 2
        
        // Since I only mod the z and x this sequences rotates the planets via each quadrant
        let leftAction = SCNAction.moveBy(x: -offset, y: -100.0, z: offset, duration: quarter_interval)
        let downAction = SCNAction.moveBy(x: offset, y: -100.0, z: offset, duration: quarter_interval)
        let rightAction = SCNAction.moveBy(x: 2 * offset, y: 0.0, z: -offset, duration: quarter_interval * 2)
        let upAction = SCNAction.moveBy(x: -2 * offset, y: 200.0, z: -offset, duration: quarter_interval * 2)
        
        return SCNAction.sequence([leftAction,downAction,rightAction, upAction])
    }
    
}
