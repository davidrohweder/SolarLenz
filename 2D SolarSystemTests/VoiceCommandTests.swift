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

    private let planets = ["mercury", "venus", "earth", "mars", "jupiter", "saturn", "uranus", "neptune"]

    @Test("Naming a planet selects it")
    func selectsAPlanet() {
        #expect(VoiceCommand.parse("go to mars", planetNames: planets) == .select("mars"))
        #expect(VoiceCommand.parse("Jupiter", planetNames: planets) == .select("jupiter"))
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
    }

    @Test("Words about the map go back")
    func backToMap() {
        #expect(VoiceCommand.parse("take me back to the map", planetNames: planets) == .backToMap)
    }

    @Test("Unrecognized speech produces no command")
    func unrecognized() {
        #expect(VoiceCommand.parse("banana pancakes", planetNames: planets) == nil)
    }
}
