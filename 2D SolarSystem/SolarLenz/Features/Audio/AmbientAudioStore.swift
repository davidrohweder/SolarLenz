//
//  AmbientAudioStore.swift
//  SolarLenz
//
//  Ambient background music, as a small @Observable service.
//
//  Replaces the original `AudioModel`, which force-unwrapped the bundle path, called
//  `fatalError` on any playback failure, and set a global `.playAndRecord` session just to
//  loop music (fighting the speech recognizer for the audio session).
//

import AVFoundation
import Observation
import os

/// Loops the bundled ambient track. Fails silently rather than crashing, and uses the
/// `.ambient` session category so it mixes politely and yields cleanly to voice capture.
@available(iOS 18, *)
@MainActor
@Observable
final class AmbientAudioStore {

    private(set) var isPlaying = false

    private var player: AVAudioPlayer?
    private let resource: String
    private let fileExtension: String
    private let logger = Logger(subsystem: "edu.psu.djr6005.SolarLenz", category: "AmbientAudio")

    init(resource: String = "solar-audio", fileExtension: String = "m4a") {
        self.resource = resource
        self.fileExtension = fileExtension
    }

    func play() {
        guard !isPlaying else { return }
        do {
            if player == nil {
                guard let url = Bundle.main.url(forResource: resource, withExtension: fileExtension) else {
                    logger.error("Ambient audio resource missing: \(self.resource, privacy: .public)")
                    return
                }
                let player = try AVAudioPlayer(contentsOf: url)
                player.numberOfLoops = -1
                player.volume = 0.4
                player.prepareToPlay()
                self.player = player
            }
            try activateSession()
            player?.play()
            isPlaying = true
        } catch {
            // Degrade silently — no audio is acceptable; a crash is not.
            logger.error("Ambient audio failed to start: \(error.localizedDescription, privacy: .public)")
            isPlaying = false
        }
    }

    /// Pauses playback and releases the audio session so nothing lingers when the app is
    /// backgrounded, on the onboarding screen, or while the mic is capturing. `play()`
    /// re-activates the session and resumes.
    func pause() {
        guard isPlaying || player?.isPlaying == true else { return }
        player?.pause()
        isPlaying = false
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    private func activateSession() throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.ambient, options: [])
        try session.setActive(true)
    }
}
