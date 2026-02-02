//
//  QuickRefRow.swift
//  Drawer
//
//  Extracted from CompletionStepView.swift per ARCH-001 (one type per file).
//
//  Copyright © 2026 Drawer. MIT License.
//

import SwiftUI

/// A row displaying an icon and text for the quick reference section.
///
/// Used in the onboarding completion step to show keyboard shortcuts
/// and usage tips in a consistent format.
struct QuickRefRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(.secondary)
                .frame(width: 20)

            Text(text)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
}
