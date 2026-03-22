//
//  FeatureRow.swift
//  Drawer
//
//  Extracted from WelcomeStepView.swift per ARCH-001 (one type per file).
//
//  Copyright © 2026 Drawer. MIT License.
//

import SwiftUI

/// A feature highlight row for the welcome step.
///
/// Displays an icon, title, and description to showcase a key feature
/// of the Drawer application during onboarding.
struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(Color.accentColor)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)

                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
