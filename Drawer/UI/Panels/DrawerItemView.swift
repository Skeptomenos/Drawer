//
//  DrawerItemView.swift
//  Drawer
//
//  Copyright © 2026 Drawer. MIT License.
//

import SwiftUI

/// Renders a single drawer item (captured icon)
struct DrawerItemView: View {

    let item: DrawerItem

    @State private var isHovered: Bool = false

    var body: some View {
        Image(decorative: item.image, scale: NSScreen.main?.backingScaleFactor ?? 2.0)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: DrawerDesign.iconSize, height: DrawerDesign.iconSize)
            .scaleEffect(isHovered ? 1.1 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.6), value: isHovered)
            .onHover { hovering in
                isHovered = hovering
            }
            .contentShape(Rectangle())
            .accessibilityLabel("Menu bar icon \(item.index + 1)")
            .accessibilityHint("Double tap to activate")
    }
}
