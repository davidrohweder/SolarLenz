//
//  VoiceCommand.swift
//  SolarLenz
//
//  A recognized voice instruction, decoupled from the words that produced it.
//

/// A command the user can speak. Mapped to store intents by the app; independent of the
/// speech framework so it can be produced and tested in isolation.
enum VoiceCommand: Equatable {
    /// Focus a planet by (lowercased) name.
    case select(String)
    /// Focus a planet by name *and* open its detail ("tell me about Mars").
    case inspect(String)
    /// Open the detail screen for the current selection.
    case openDetail
    /// Enter the AR experience.
    case enterAR
    /// Return to the 2D map.
    case backToMap
}

extension VoiceCommand {

    /// Parses a full transcription into a command.
    ///
    /// Pure and case-insensitive, matching against the entire utterance so natural phrases
    /// work ("go to Mars", "show me Jupiter", "back to the map"). The original code only
    /// inspected the *last* spoken word, so word order had to be exact.
    static func parse(_ transcript: String, planetNames: [String]) -> VoiceCommand? {
        let text = transcript.lowercased()
        let wantsDetail = ["explore", "detail", "info", "tell me", "learn", "about"].contains { text.contains($0) }

        if let planet = planetNames.first(where: { text.contains($0) }) {
            return wantsDetail ? .inspect(planet) : .select(planet)
        }
        if ["augmented", "reality", "ar mode", "camera"].contains(where: { text.contains($0) }) {
            return .enterAR
        }
        if ["map", "back", "solar system", "overview"].contains(where: { text.contains($0) }) {
            return .backToMap
        }
        if wantsDetail { return .openDetail }
        return nil
    }
}
