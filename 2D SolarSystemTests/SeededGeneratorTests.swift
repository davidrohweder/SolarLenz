//
//  SeededGeneratorTests.swift
//  2D SolarSystemTests
//

import Testing
@testable import _D_SolarSystem

@Suite("SeededGenerator")
struct SeededGeneratorTests {

    @Test("The same seed produces the same sequence (stable starfield)")
    func deterministic() {
        var a = SeededGenerator(seed: 42)
        var b = SeededGenerator(seed: 42)
        let seqA = (0..<5).map { _ in a.next() }
        let seqB = (0..<5).map { _ in b.next() }
        #expect(seqA == seqB)
    }

    @Test("Different seeds diverge")
    func differentSeeds() {
        var a = SeededGenerator(seed: 1)
        var b = SeededGenerator(seed: 2)
        #expect(a.next() != b.next())
    }

    @Test("A zero seed does not collapse the generator")
    func zeroSeed() {
        var g = SeededGenerator(seed: 0)
        let values = Set((0..<8).map { _ in g.next() })
        #expect(values.count > 1)
    }
}
