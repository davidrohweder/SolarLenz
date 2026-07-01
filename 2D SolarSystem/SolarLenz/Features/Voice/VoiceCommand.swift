//
//  VoiceCommand.swift
//  SolarLenz
//
//  A recognized voice instruction, decoupled from the words that produced it.
//

import Foundation

/// A command the user can speak. Mapped to store intents by the app; independent of the
/// speech framework so it can be produced and tested in isolation.
enum VoiceCommand: Equatable {
    /// Focus a planet by (lowercased) name.
    case select(String)
    /// Focus a planet by name *and* open its detail ("tell me about Mars").
    case inspect(String)
    /// Enter AR and focus a planet close-up, or focus the current selection when nil.
    case focusInAR(String?)
    /// Open the detail screen for the current selection.
    case openDetail
    /// Enter the AR experience.
    case enterAR
    /// Return to the 2D map.
    case backToMap
    /// Select the next planet in distance order.
    case nextPlanet
    /// Select the previous planet in distance order.
    case previousPlanet
    /// Release AR focus and show the whole system.
    case releaseARFocus
    /// Turn ambient audio on or off.
    case setAudio(Bool)
    /// Show the voice command guide.
    case showHelp
    /// Stop continuous listening.
    case stopListening
}

struct VoiceCommandGuideSection: Identifiable, Hashable {
    let title: String
    let examples: [String]

    var id: String { title }
}

enum VoiceCommandRegistry {

    static let guideSections: [VoiceCommandGuideSection] = [
        VoiceCommandGuideSection(title: "Navigation", examples: [
            "go to Mars",
            "show Saturn",
            "view Jupiter",
            "tell me about Earth",
            "next planet",
            "previous planet",
            "back to the map",
        ]),
        VoiceCommandGuideSection(title: "AR Focus", examples: [
            "open AR",
            "focus Venus in AR",
            "show Mars in AR",
            "track Venus",
            "focus current planet",
            "release focus",
            "show whole system",
        ]),
        VoiceCommandGuideSection(title: "Audio and Mic", examples: [
            "enable audio",
            "play music",
            "mute audio",
            "stop listening",
        ]),
        VoiceCommandGuideSection(title: "Help", examples: [
            "help",
            "show commands",
            "what can I say",
        ]),
    ]

    static var contextualStrings: [String] {
        guideSections.flatMap(\.examples)
    }

    /// Parses a full transcription into a command.
    ///
    /// Pure and case-insensitive, matching against the entire utterance so natural phrases
    /// work ("go to Mars", "show me Jupiter", "back to the map").
    static func parse(_ transcript: String, planetNames: [String]) -> VoiceCommand? {
        let text = normalized(transcript)

        if containsAny(["stop listening", "turn off mic", "disable mic", "disable microphone"], in: text) {
            return .stopListening
        }
        if containsAny(["help", "commands", "show commands", "what can i say"], in: text) {
            return .showHelp
        }
        if containsAny(["enable audio", "turn on audio", "turn on sound", "play music", "enable sound"], in: text) {
            return .setAudio(true)
        }
        if containsAny(["disable audio", "turn off audio", "mute audio", "mute sound", "stop music"], in: text) {
            return .setAudio(false)
        }
        if containsAny(["release focus", "release tracking", "stop tracking", "show whole system", "whole system"], in: text) {
            return .releaseARFocus
        }
        if containsAny(["next planet", "next world", "go next"], in: text) {
            return .nextPlanet
        }
        if containsAny(["previous planet", "prev planet", "last planet", "go back one"], in: text) {
            return .previousPlanet
        }

        let wantsARFocus = containsAny(["track", "follow", "orbit with", "lock onto", "focus"], in: text)
            || containsAny(["in ar", "in augmented reality"], in: text)
        let wantsDetail = containsAny(["view", "explore", "detail", "info", "tell me", "learn", "about", "facts"], in: text)
        let wantsSelect = containsAny(["go to", "show", "select", "open", "take me to"], in: text)

        if let planet = planetNames.first(where: { containsPhrase($0, in: text) }) {
            if wantsARFocus { return .focusInAR(planet) }
            if wantsDetail { return .inspect(planet) }
            if wantsSelect { return .select(planet) }
            return .select(planet)
        }
        if wantsARFocus || containsAny(["track current planet", "follow current planet", "focus current planet"], in: text) {
            return .focusInAR(nil)
        }
        if containsAny(["augmented reality", "ar mode", "open ar", "enter ar", "camera"], in: text) || containsPhrase("ar", in: text) {
            return .enterAR
        }
        if containsAny(["map", "back to map", "back to the map", "home", "overview"], in: text) {
            return .backToMap
        }
        if wantsDetail { return .openDetail }
        return nil
    }

    private static func normalized(_ transcript: String) -> String {
        let lowered = transcript.lowercased()
        let scalars = lowered.unicodeScalars.map { scalar -> Character in
            CharacterSet.alphanumerics.contains(scalar) ? Character(scalar) : " "
        }
        return " " + String(scalars).split(separator: " ").joined(separator: " ") + " "
    }

    private static func containsAny(_ phrases: [String], in text: String) -> Bool {
        phrases.contains { containsPhrase($0, in: text) }
    }

    private static func containsPhrase(_ phrase: String, in text: String) -> Bool {
        text.contains(" \(phrase.lowercased()) ")
    }
}

extension VoiceCommand {

    static func parse(_ transcript: String, planetNames: [String]) -> VoiceCommand? {
        VoiceCommandRegistry.parse(transcript, planetNames: planetNames)
    }
}
