//
//  VoiceControlStore.swift
//  SolarLenz
//
//  Speech-driven navigation, as a small @Observable service.
//
import Speech
import AVFoundation
import Observation

/// Wraps `SFSpeechRecognizer` + `AVAudioEngine` to turn speech into `VoiceCommand`s.
///
/// Requests authorization up front, keeps recognition running continuously, matches partial
/// transcripts in real time, and publishes typed commands. Every state mutation happens on
/// the main actor, including the recognition callback.
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
    private var shouldListen = false
    private var isRestarting = false
    private var lastCommandKey: String?
    private var lastCommandTime: Date = .distantPast
    private let commandCooldown: TimeInterval = 1.15

    // MARK: - Public control

    func toggle() {
        if shouldListen { stop() } else { Task { await start() } }
    }

    func start() async {
        guard !shouldListen else { return }
        guard recognizer?.isAvailable == true else { authorization = .denied; return }
        guard await requestSpeechAuthorization(), await requestMicrophoneAuthorization() else {
            authorization = .denied
            return
        }
        authorization = .authorized
        shouldListen = true
        transcript = ""
        do { try beginRecognition() } catch { stop() }
    }

    func stop() {
        guard shouldListen || isListening || task != nil else { return }
        shouldListen = false
        isRestarting = false
        stopRecognition(clearTranscript: true, deactivateSession: true)
    }

    // MARK: - Recognition lifecycle

    private func stopRecognition(clearTranscript: Bool, deactivateSession: Bool) {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        request?.endAudio()
        task?.cancel()
        task = nil
        request = nil
        if clearTranscript { transcript = "" }
        isListening = false
        if deactivateSession {
            try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        }
    }

    private func restartRecognition() {
        guard shouldListen, !isRestarting else { return }
        isRestarting = true
        stopRecognition(clearTranscript: false, deactivateSession: false)
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 250_000_000)
            guard self.shouldListen else {
                self.isRestarting = false
                return
            }
            do {
                try self.beginRecognition()
            } catch {
                self.shouldListen = false
                self.stopRecognition(clearTranscript: true, deactivateSession: true)
            }
            self.isRestarting = false
        }
    }

    // MARK: - Recognition

    private func beginRecognition() throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playAndRecord, mode: .measurement, options: [.duckOthers, .defaultToSpeaker, .allowBluetoothHFP])
        try session.setActive(true, options: .notifyOthersOnDeactivation)

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        request.taskHint = .search
        request.contextualStrings = planetNames + VoiceCommandRegistry.contextualStrings
        self.request = request

        let input = audioEngine.inputNode
        input.removeTap(onBus: 0)
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
                    if result.isFinal { self.restartRecognition() }
                }
                if error != nil, self.shouldListen {
                    self.restartRecognition()
                } else if error != nil {
                    self.stopRecognition(clearTranscript: true, deactivateSession: true)
                }
            }
        }
    }

    private func handle(_ transcription: String) {
        transcript = transcription
        guard let command = VoiceCommand.parse(transcription, planetNames: planetNames),
              shouldAccept(command) else {
            return
        }
        onCommand?(command)
        if command == .stopListening {
            stop()
        } else {
            transcript = ""
            restartRecognition()
        }
    }

    private func shouldAccept(_ command: VoiceCommand) -> Bool {
        let key = String(describing: command)
        let now = Date()
        defer {
            lastCommandKey = key
            lastCommandTime = now
        }
        guard key != lastCommandKey || now.timeIntervalSince(lastCommandTime) > commandCooldown else {
            return false
        }
        return true
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
