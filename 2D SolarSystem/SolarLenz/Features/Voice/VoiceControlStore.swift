//
//  VoiceControlStore.swift
//  SolarLenz
//
//  Speech-driven navigation, as a small @Observable service.
//
//  A ground-up rewrite of the original `VoiceModel`, which subclassed UIViewController for
//  no reason, never requested authorization, force-unwrapped its way through recognition,
//  and mutated UI state from a background callback.
//

import Speech
import AVFoundation
import Observation

/// Wraps `SFSpeechRecognizer` + `AVAudioEngine` to turn speech into `VoiceCommand`s.
///
/// Requests authorization up front, prefers on-device recognition for privacy, matches the
/// full utterance, and publishes a typed command. Every state mutation happens on the main
/// actor — including the recognition callback, which the original ran off-main.
@available(iOS 18, *)
@MainActor
@Observable
final class VoiceControlStore {

    enum Authorization: Equatable { case notDetermined, authorized, denied }

    private(set) var authorization: Authorization = .notDetermined
    private(set) var isListening = false
    private(set) var transcript = ""

    /// Planet names the parser will recognize (lowercased). Configured by the app once data loads.
    var planetNames: [String] = []
    /// Invoked on the main actor when a command is recognized.
    var onCommand: ((VoiceCommand) -> Void)?

    private let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private let audioEngine = AVAudioEngine()
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?

    // MARK: - Public control

    func toggle() {
        if isListening { stop() } else { Task { await start() } }
    }

    func start() async {
        guard !isListening else { return }
        guard recognizer?.isAvailable == true else { authorization = .denied; return }
        guard await requestSpeechAuthorization(), await requestMicrophoneAuthorization() else {
            authorization = .denied
            return
        }
        authorization = .authorized
        do { try beginRecognition() } catch { stop() }
    }

    func stop() {
        guard isListening || task != nil else { return }
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        request?.endAudio()
        task?.cancel()
        task = nil
        request = nil
        transcript = ""
        isListening = false
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    // MARK: - Recognition

    private func beginRecognition() throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.record, mode: .measurement, options: .duckOthers)
        try session.setActive(true, options: .notifyOthersOnDeactivation)

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        if recognizer?.supportsOnDeviceRecognition == true {
            request.requiresOnDeviceRecognition = true
        }
        self.request = request

        let input = audioEngine.inputNode
        input.installTap(onBus: 0, bufferSize: 1024, format: input.outputFormat(forBus: 0)) { [weak self] buffer, _ in
            self?.request?.append(buffer)
        }
        audioEngine.prepare()
        try audioEngine.start()
        isListening = true

        task = recognizer?.recognitionTask(with: request) { [weak self] result, error in
            // The callback fires on an arbitrary queue; hop to the main actor before touching state.
            Task { @MainActor [weak self] in
                guard let self else { return }
                if let result {
                    self.handle(result.bestTranscription.formattedString)
                    if result.isFinal { self.stop() }
                }
                if error != nil { self.stop() }
            }
        }
    }

    private func handle(_ transcription: String) {
        transcript = transcription
        if let command = VoiceCommand.parse(transcription, planetNames: planetNames) {
            onCommand?(command)
        }
    }

    // MARK: - Authorization

    private func requestSpeechAuthorization() async -> Bool {
        if SFSpeechRecognizer.authorizationStatus() == .authorized { return true }
        return await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status == .authorized)
            }
        }
    }

    private func requestMicrophoneAuthorization() async -> Bool {
        if AVAudioApplication.shared.recordPermission == .granted { return true }
        return await withCheckedContinuation { continuation in
            AVAudioApplication.requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }
    }
}
