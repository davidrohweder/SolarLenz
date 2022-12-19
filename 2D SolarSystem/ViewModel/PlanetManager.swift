//
//  PlanetManager.swift
//  2D SolarSystem
//
//  Created by David Rohweder on 10/30/22.
//

import Foundation
import AVFoundation

class PlanetManager : ObservableObject {
    
    // Internal data structures
    @Published var planets: [PlanetModel]
    @Published var currentPlanet: PlanetModel
    @Published var ar_travelPlanet: String = "earth"
    
    // Instantiate IO Models
    @Published var player: AudioModel = AudioModel()
    @Published var listener: VoiceModel = VoiceModel()
    @Published var isListening: Bool = false {
        didSet {
            voiceHandler()
        }
    }
    @Published var allowAudio = true

    // view changers
    @Published var show_dim : ViewStates = .dim_two {
        didSet {
            audioHandler()
        }
    }
    @Published var show_info: Bool = false
    @Published var show_settings: Bool = false
    @Published var show_AR_commands: Bool = false
    @Published var enable_AR_directions: Bool = false
    @Published var show_help: Bool = false
    @Published var expand_AR_help: Bool = false
    
    // App persistance
    let storageManger : StorageManager<[PlanetModel]>
    
    // App Listners
    var lowPower: Bool = false
    
    init () {
        // init stored data
        planets = []
        currentPlanet = PlanetModel.standard
        
        // decode JSON data
        let filename = "planetary_data"
        storageManger = StorageManager<[PlanetModel]>(name:filename, ext: ".json")
        let _planets: [PlanetModel]? = storageManger.modelData ?? []
        
        // Correct data to program
        guard _planets != nil else {return}

        planets = _planets!.sorted { $0.id < $1.id }
        currentPlanet = planets[0]
        listener.initalize_VoiceModel(planet_names: planets.map(\.name))
        compute_all_planet_offets()
        
        // low power
        NotificationCenter.default.addObserver(self, selector: #selector(recvPowerChange), name: Notification.Name.NSProcessInfoPowerStateDidChange, object: nil)
        checkLowPower()
    }
    
}
