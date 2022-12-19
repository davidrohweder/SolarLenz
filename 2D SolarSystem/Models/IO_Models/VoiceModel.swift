//
//  VoiceModel.swift
//  2D SolarSystem
//
//  Created by David Rohweder on 11/28/22.
//

import SwiftUI

//SOURCED FROM --> http://www.wepstech.com/voice-recognition-swift/
// Source covers hands-on core speech material; however, I modify it a lot to fit the app. Still wanted to credit the source

import UIKit
import Speech

class VoiceModel: UIViewController, SFSpeechRecognizerDelegate {
    
    // Core vars
    let audioEngine = AVAudioEngine()
    let speechReconizer : SFSpeechRecognizer? = SFSpeechRecognizer()
    let request = SFSpeechAudioBufferRecognitionRequest()
    var task : SFSpeechRecognitionTask!
    
    // Processing vars
    var command: AppCommands = .none
    var planetNames: [String] = []
    var planet_index: Int = 0
    
    func initalize_VoiceModel(planet_names: [String]) {
        self.planetNames = planet_names
    }
    
    func startSpeechRecognization(name: String){
        planet_index = planetNames.firstIndex(of: name)!
        let node = audioEngine.inputNode
        let recordingFormat = node.outputFormat(forBus: 0)
        
        node.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer, _) in
            self.request.append(buffer)
        }
        
        audioEngine.prepare()
        do {
            try audioEngine.start()
        } catch let error {
            print("Error comes here for starting the audio listner =\(error.localizedDescription)")
        }
        
        guard let myRecognization = SFSpeechRecognizer() else {
            print("Recognization is not allow on your local")
            return
        }
        
        if !myRecognization.isAvailable {
            print("Recognization is free right now, Please try again after some time.")
        }
        
        task = speechReconizer?.recognitionTask(with: request, resultHandler: { (response, error) in
            guard let response = response else {
                if error != nil {
                    print(error.debugDescription)
                }else {
                    print("Problem in giving the response")
                }
                return
            }
            
            let message = response.bestTranscription.formattedString
            print("Message : \(message)")
            
            
            var lastString: String = ""
            for segment in response.bestTranscription.segments {
                let indexTo = message.index(message.startIndex, offsetBy: segment.substringRange.location)
                lastString = String(message[indexTo...])
            }
            
            if lastString.lowercased() == "go" {
                self.command = .go_to
            } else if lastString.lowercased() == "enable" {
                self.command = .enable_ar_for
            } else if lastString.lowercased() == "show" {
                self.command = .show_info_for
            }
            
            if self.planetNames.contains(lastString.lowercased()) {
                guard let idx = self.planetNames.firstIndex(of: lastString.lowercased()) else {return}
                self.planet_index = idx
            }
            
        })
    }
    
    // return the command and which planet upon input end request
    func cancelSpeechRecognization() -> [AppCommands: String] {
        task.finish()
        task.cancel()
        task = nil
        
        request.endAudio()
        audioEngine.stop()
        //audioEngine.inputNode.removeTap(onBus: 0)
        
        if audioEngine.inputNode.numberOfInputs > 0 {
            audioEngine.inputNode.removeTap(onBus: 0)
        }
        
        let ret_command = [command: planetNames[planet_index]]
        reset_listner()
        
        return ret_command
    }
    
    func reset_listner() {
        command = .none
    }
    
}
