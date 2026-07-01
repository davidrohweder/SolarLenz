//
//  PreferenceKey.swift
//  SolarLenz
//
//  Centralized @AppStorage keys, so a typo can't silently desync a preference.
//

import Foundation

/// The string keys backing the app's `@AppStorage`-persisted preferences.
///
/// These literals (`"Constants.Preferences.UserAge"`, …) were previously hand-typed in
/// several views; a single mismatch would quietly split one preference into two. Routing
/// every access through these constants makes the compiler the source of truth.
enum PreferenceKey {
    /// The user's age; drives the educational `AgeBracket`. `0` means "not yet set".
    static let userAge = "Constants.Preferences.UserAge"
    /// Whether ambient audio playback is enabled.
    static let audioEnabled = "Constants.Preferences.AudioEnabled"
}
