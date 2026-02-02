//
//  OverlayBackground.swift
//  Drawer
//
//  Copyright © 2026 Drawer. MIT License.
//

import SwiftUI

// MARK: - OverlayBackground

/// Menu bar style background using NSVisualEffectView.
/// Provides the translucent material effect matching macOS menu bar.
struct OverlayBackground: View {

    var body: some View {
        OverlayVisualEffectView(material: .menu, blendingMode: .behindWindow)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color.white.opacity(0.2), lineWidth: 0.5)
            )
            .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}
