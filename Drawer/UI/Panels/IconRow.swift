//
//  IconRow.swift
//  Drawer
//
//  Copyright © 2026 Drawer. MIT License.
//

import SwiftUI

/// Horizontal row of icons for a section
struct IconRow: View {
    let items: [DrawerItem]
    var onItemTap: ((DrawerItem) -> Void)?

    var body: some View {
        HStack(spacing: DrawerDesign.iconSpacing) {
            ForEach(items) { item in
                Button {
                    onItemTap?(item)
                } label: {
                    DrawerItemView(item: item)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Menu bar icon \(item.index + 1)")
                .accessibilityHint("Double tap to activate")
            }
        }
    }
}
