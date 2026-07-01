//
//  AmbientAudioStore.swift
//  SolarLenz
//
//  Ambient background music, as a small @Observable service.
//
import AVFoundation
import Observation
import os

/// Loops the bundled ambient track. Fails silently rather than crashing, and uses a playback
/// session so the track still works when the hardware silent switch is on.
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

    func play(ducked: Bool = false, allowsRecording: Bool = false) {
        do {
            if player == nil {
                guard let url = Bundle.main.url(forResource: resource, withExtension: fileExtension) else {
                    logger.error("Ambient audio resource missing: \(self.resource, privacy: .public)")
                    return
                }
                let player = try AVAudioPlayer(contentsOf: url)
                player.numberOfLoops = -1
                player.volume = 0.32
                player.prepareToPlay()
                self.player = player
            }
            player?.volume = ducked ? 0.12 : 0.32
            try activateSession(allowsRecording: allowsRecording)
            if !isPlaying {
                isPlaying = player?.play() == true
            }
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

    private func activateSession(allowsRecording: Bool) throws {
        let session = AVAudioSession.sharedInstance()
        if allowsRecording {
            try session.setCategory(.playAndRecord, mode: .measurement, options: [.mixWithOthers, .defaultToSpeaker, .allowBluetoothHFP])
        } else {
            try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
        }
        try session.setActive(true)
    }
}
