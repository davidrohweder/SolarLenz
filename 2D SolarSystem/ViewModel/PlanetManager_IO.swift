//
//  PlanetManager_IO.swift
//  2D SolarSystem
//
//  Created by David Rohweder on 11/28/22.
//

import Foundation

extension PlanetManager {
    
    func audioHandler() {
        
        if !allowAudio {
            return
        }
        
        if self.isListening {
            player.stopPlayer()
            return
        }
        
        if show_dim == .dim_two_single {
            player.startPlayer(track: AudioModel.audioName)
        } else {
            player.player?.stop()
        }
    }
    
    func voiceHandler() {
        if self.isListening {
            audioHandler()
            startListening()
        } else {
            stopListening()
            audioHandler()
        }
    }
    
    func startListening() {
        listener.startSpeechRecognization(name: currentPlanet.name)
    }
    
    func stopListening() {
        let completed_command: [AppCommands: String] = listener.cancelSpeechRecognization()
        
        for (key, value) in completed_command {
            let _planets = planets.filter { $0.name == value }
            currentPlanet = _planets[0]
            
            switch(key) {
            case .go_to:
                if show_dim == .dim_two {
                    show_dim = .dim_two_single
                }
            case .enable_ar_for:
                show_dim = .dim_three
            case .show_info_for:
                if show_dim == .dim_two {
                    show_dim = .dim_two_single // def if on 2d all view
                }
                show_info.toggle()
            default:
                print("Unknown Command...")
            }
        }
        
    }
    
}
