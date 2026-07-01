//
//  AgeBracket.swift
//  SolarLenz
//
//  A single source of truth for the app's audience tiers.
//

import Foundation

/// Audience tiers the app tailors its educational copy to.
///
/// Consolidates the brackets that were previously inlined as magic ranges in
/// `BracketInformationView` (`1..<11`, `11..<19`, default). An age of `0` is treated
/// as "not yet set" by the navigation layer, which is why `init(age:)` never produces a
/// sentinel — the onboarding decision lives with the router, not here.
enum AgeBracket: String, CaseIterable, Identifiable, Sendable {
    case child
    case teen
    case adult

    var id: String { rawValue }

    /// Buckets a concrete age into a tier, matching the original app's ranges.
    init(age: Int) {
        switch age {
        case ..<11:   self = .child
        case 11..<19: self = .teen
        default:      self = .adult
        }
    }

    /// A friendly label for the tier, suitable for headers and badges.
    var title: String {
        switch self {
        case .child: "Explorer"
        case .teen:  "Student"
        case .adult: "Astronomer"
        }
    }
}
