//
//  AudioModel.swift
//  2D SolarSystem
//
//  Created by David Rohweder on 11/23/22.
//

import AVFoundation

class AudioModel {
    
    static let audioName = "solar-audio.m4a"
    var player: AVAudioPlayer?
    
    func startPlayer (track: String) {
        let path = Bundle.main.path(forResource: AudioModel.audioName, ofType: nil)!
        let url = URL(fileURLWithPath: path)
        
        // needed for actual iPhone execution, sets local session
        sharedSession()
        
        do {
            player = try AVAudioPlayer(contentsOf: url)
            player?.numberOfLoops = -1 // -1 is an infinite loop run occurances
            player?.setVolume(0.75, fadeDuration: 20.0) // dont want the volume too loud
            player?.play()
        } catch {
            fatalError("Err: Audio file not found somehow..?")
        }
        
    }
    
    func sharedSession() {
        let audioSession = AVAudioSession.sharedInstance()
        
        do {
            try audioSession.setCategory(.playAndRecord, options: .defaultToSpeaker)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch let err {
            print("ERROR \(err.localizedDescription)")
        }
    }
    
    func stopPlayer() {
        player?.stop()
    }
}
