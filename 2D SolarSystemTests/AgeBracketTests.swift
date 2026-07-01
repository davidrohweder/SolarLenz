//
//  AgeBracketTests.swift
//  2D SolarSystemTests
//

import Testing
@testable import _D_SolarSystem

@Suite("AgeBracket")
struct AgeBracketTests {

    @Test("Ages bucket into the same ranges as the original app")
    func buckets() {
        #expect(AgeBracket(age: 4) == .child)
        #expect(AgeBracket(age: 10) == .child)
        #expect(AgeBracket(age: 11) == .teen)
        #expect(AgeBracket(age: 18) == .teen)
        #expect(AgeBracket(age: 19) == .adult)
        #expect(AgeBracket(age: 40) == .adult)
    }

    @Test("Titles are stable and audience-appropriate")
    func titles() {
        #expect(AgeBracket.child.title == "Explorer")
        #expect(AgeBracket.teen.title == "Student")
        #expect(AgeBracket.adult.title == "Astronomer")
    }
}
