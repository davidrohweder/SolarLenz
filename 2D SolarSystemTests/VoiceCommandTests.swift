//
//  VoiceCommandTests.swift
//  2D SolarSystemTests
//
//  The voice parser is pure, so the whole command vocabulary is testable without audio.
//

import Testing
@testable import _D_SolarSystem

@Suite("VoiceCommand parsing")
struct VoiceCommandTests {

    private let planets = ["sun", "mercury", "venus", "earth", "mars", "jupiter", "saturn", "uranus", "neptune"]

    @Test("Naming a planet selects it")
    func selectsAPlanet() {
        #expect(VoiceCommand.parse("go to mars", planetNames: planets) == .select("mars"))
        #expect(VoiceCommand.parse("Jupiter", planetNames: planets) == .select("jupiter"))
        #expect(VoiceCommand.parse("show me the sun", planetNames: planets) == .select("sun"))
    }

    @Test("Asking for detail about a named planet inspects it")
    func inspectsWhenAskedForDetail() {
        #expect(VoiceCommand.parse("tell me about earth", planetNames: planets) == .inspect("earth"))
        #expect(VoiceCommand.parse("explore saturn", planetNames: planets) == .inspect("saturn"))
    }

    @Test("A detail request with no planet opens the current selection")
    func openDetailWithoutPlanet() {
        #expect(VoiceCommand.parse("show more info", planetNames: planets) == .openDetail)
    }

    @Test("Words about AR enter the AR experience")
    func entersAR() {
        #expect(VoiceCommand.parse("enter augmented reality", planetNames: planets) == .enterAR)
        #expect(VoiceCommand.parse("open AR", planetNames: planets) == .enterAR)
        #expect(VoiceCommand.parse("Mars is red", planetNames: planets) == .select("mars"))
    }

    @Test("Words about the map go back")
    func backToMap() {
        #expect(VoiceCommand.parse("take me back to the map", planetNames: planets) == .backToMap)
    }

    @Test("Tracking commands enter AR with an optional planet")
    func tracking() {
        #expect(VoiceCommand.parse("track venus", planetNames: planets) == .track("venus"))
        #expect(VoiceCommand.parse("follow current planet", planetNames: planets) == .track(nil))
        #expect(VoiceCommand.parse("release tracking", planetNames: planets) == .releaseTracking)
    }

    @Test("Audio commands toggle ambient sound")
    func audioCommands() {
        #expect(VoiceCommand.parse("enable audio", planetNames: planets) == .setAudio(true))
        #expect(VoiceCommand.parse("mute sound", planetNames: planets) == .setAudio(false))
    }

    @Test("Guide and mic commands are recognized")
    func utilityCommands() {
        #expect(VoiceCommand.parse("show commands", planetNames: planets) == .showHelp)
        #expect(VoiceCommand.parse("stop listening", planetNames: planets) == .stopListening)
    }

    @Test("Next and previous commands are recognized")
    func steppingCommands() {
        #expect(VoiceCommand.parse("next planet", planetNames: planets) == .nextPlanet)
        #expect(VoiceCommand.parse("previous planet", planetNames: planets) == .previousPlanet)
    }

    @Test("Unrecognized speech produces no command")
    func unrecognized() {
        #expect(VoiceCommand.parse("banana pancakes", planetNames: planets) == nil)
    }
}
