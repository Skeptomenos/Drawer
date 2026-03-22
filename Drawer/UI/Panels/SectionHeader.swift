//
//  SectionHeader.swift
//  Drawer
//
//  Copyright © 2026 Drawer. MIT License.
//

import SwiftUI

/// Header label for a section in the drawer
struct SectionHeader: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.caption2.weight(.medium))
            .foregroundStyle(.secondary)
            .padding(.horizontal, 8)
    }
}
