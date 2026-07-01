//
//  ErrorStateView.swift
//  SolarLenz
//
//  Shared recoverable error state.
//

import SwiftUI

/// Shown when the bundled data fails to load. Offers a retry instead of crashing.
@available(iOS 18, *)
struct ErrorStateView: View {
    let message: String
    let retry: () -> Void

    var body: some View {
        VStack(spacing: Theme.Spacing.l) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 44, weight: .semibold))
                .foregroundStyle(.yellow)
            Text("Couldn't load the solar system")
                .font(Theme.Typography.title)
            Text(message)
                .font(Theme.Typography.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button("Try Again", action: retry)
                .buttonStyle(.borderedProminent)
        }
        .padding(Theme.Spacing.xl)
        .foregroundStyle(.white)
    }
}
