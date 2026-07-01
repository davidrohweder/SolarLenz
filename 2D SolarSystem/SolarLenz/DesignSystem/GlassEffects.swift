//
//  GlassEffects.swift
//  SolarLenz
//
//  Liquid Glass helpers with a graceful fallback for pre-iOS 26 systems.
//

import SwiftUI

extension View {

    /// Applies Liquid Glass on systems that support it, falling back to a material blur
    /// on iOS 18–25. Centralizing the availability check keeps feature code clean and
    /// means there is exactly one place to update if the fallback strategy changes.
    @ViewBuilder
    func glassCard(cornerRadius: CGFloat = Theme.Radius.card) -> some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        if #available(iOS 26, *) {
            self.glassEffect(.regular, in: shape)
        } else {
            self.background(.ultraThinMaterial, in: shape)
        }
    }

    /// A pill-shaped glass control surface, used for floating buttons and toolbars.
    @ViewBuilder
    func glassPill() -> some View {
        if #available(iOS 26, *) {
            self.glassEffect(.regular.interactive(), in: Capsule())
        } else {
            self.background(.ultraThinMaterial, in: Capsule())
        }
    }
}
