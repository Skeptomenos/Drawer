//
//  OverlayIconView.swift
//  Drawer
//
//  Copyright © 2026 Drawer. MIT License.
//

import AppKit
import SwiftUI

// MARK: - OverlayIconView

/// Individual icon in the overlay panel.
/// Displays a captured menu bar icon with hover and press states.
struct OverlayIconView: View {

    // MARK: - Constants

    /// Default backing scale factor when NSScreen.main is unavailable (Retina default)
    private static let defaultBackingScaleFactor: CGFloat = 2.0

    // MARK: - Properties

    let item: DrawerItem
    let isHovered: Bool
    let onTap: () -> Void

    // MARK: - Body

    var body: some View {
        Button(action: onTap) {
            Image(decorative: item.image, scale: NSScreen.main?.backingScaleFactor ?? Self.defaultBackingScaleFactor)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 18, height: 18)
        }
        .buttonStyle(OverlayIconButtonStyle(isHovered: isHovered))
        .frame(width: 24, height: 22)
    }
}
