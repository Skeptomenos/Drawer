//
//  OverlayContentView.swift
//  Drawer
//
//  Copyright © 2026 Drawer. MIT License.
//

import AppKit
import SwiftUI

// MARK: - OverlayContentView

/// Horizontal strip of hidden icons, styled like the menu bar.
/// Displays DrawerItems in a compact horizontal layout suitable for
/// rendering at menu bar level as an alternative to expand mode.
struct OverlayContentView: View {

    // MARK: - Properties

    let items: [DrawerItem]
    let onItemTap: ((DrawerItem) -> Void)?

    @State private var hoveredItemId: UUID?

    // MARK: - Body

    var body: some View {
        HStack(spacing: 0) {
            ForEach(items) { item in
                OverlayIconView(
                    item: item,
                    isHovered: hoveredItemId == item.id,
                    onTap: { onItemTap?(item) }
                )
                .onHover { isHovered in
                    hoveredItemId = isHovered ? item.id : nil
                }
            }
        }
        .padding(.horizontal, 4)
        .frame(height: NSStatusBar.system.thickness)
        .background(OverlayBackground())
    }
}

// MARK: - Preview

#if DEBUG
struct OverlayContentView_Previews: PreviewProvider {
    static var previews: some View {
        OverlayContentView(
            items: [],
            onItemTap: nil
        )
        .frame(width: 200)
    }
}
#endif
