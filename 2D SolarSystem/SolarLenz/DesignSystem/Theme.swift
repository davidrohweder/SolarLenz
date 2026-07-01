//
//  Theme.swift
//  SolarLenz
//
//  Centralized design tokens — one source of truth for spacing, type, motion, and color.
//

import SwiftUI

/// Design tokens for SolarLenz.
///
/// Centralizing these keeps surfaces visually consistent and avoids scattered spacing,
/// type, color, and motion constants.
enum Theme {

    enum Spacing {
        static let xs: CGFloat = 4
        static let s: CGFloat = 8
        static let m: CGFloat = 16
        static let l: CGFloat = 24
        static let xl: CGFloat = 40
    }

    enum Radius {
        static let control: CGFloat = 14
        static let card: CGFloat = 24
        static let pill: CGFloat = 999
    }

    enum Motion {
        /// Energetic spring for control and selection changes. (iOS 16-safe.)
        static let interactive = Animation.spring(response: 0.4, dampingFraction: 0.82)
        /// Calm transition for mode/route changes.
        static let transition = Animation.easeInOut(duration: 0.5)
    }

    enum Palette {
        static let deepSpace = Color(red: 0.02, green: 0.02, blue: 0.06)
        static let nebula = Color(red: 0.10, green: 0.08, blue: 0.22)
        static let starlight = Color.white
        static let accent = Color(red: 0.45, green: 0.62, blue: 1.0)
    }

    enum Typography {
        static let display = Font.system(.largeTitle, design: .rounded).weight(.bold)
        static let title = Font.system(.title2, design: .rounded).weight(.semibold)
        static let body = Font.system(.body, design: .rounded)
        static let caption = Font.system(.caption, design: .rounded)
    }
}
