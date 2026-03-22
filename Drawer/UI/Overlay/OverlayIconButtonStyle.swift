//
//  OverlayIconButtonStyle.swift
//  Drawer
//
//  Copyright © 2026 Drawer. MIT License.
//

import SwiftUI

// MARK: - OverlayIconButtonStyle

/// Button style matching menu bar icon appearance.
/// Provides subtle hover and pressed state backgrounds.
struct OverlayIconButtonStyle: ButtonStyle {

    let isHovered: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(backgroundColor(configuration: configuration))
            )
    }

    private func backgroundColor(configuration: Configuration) -> Color {
        if configuration.isPressed {
            return Color.primary.opacity(0.15)
        } else if isHovered {
            return Color.primary.opacity(0.08)
        }
        return .clear
    }
}
