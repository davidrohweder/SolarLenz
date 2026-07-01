//
//  SeededGenerator.swift
//  SolarLenz
//
//  A tiny deterministic RNG so generated visuals (e.g. the starfield) are stable
//  across redraws.
//

/// A deterministic linear-congruential random number generator.
///
/// Seeding it with a fixed value produces the same sequence every launch, which keeps
/// procedural visuals stable and makes them testable.
struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        // Avoid a zero state, which would collapse the generator.
        state = seed == 0 ? 0x9E3779B97F4A7C15 : seed
    }

    mutating func next() -> UInt64 {
        state = state &* 6364136223846793005 &+ 1442695040888963407
        return state
    }
}
