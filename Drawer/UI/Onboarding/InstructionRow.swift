//
//  InstructionRow.swift
//  Drawer
//
//  Extracted from TutorialStepView.swift per ARCH-001 (one type per file).
//
//  Copyright © 2026 Drawer. MIT License.
//

import SwiftUI

/// A numbered instruction row for the tutorial step.
///
/// Displays a step number in a colored circle followed by a title
/// and description. Used to guide users through the icon arrangement process.
struct InstructionRow: View {
    let step: Int
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Text("\(step)")
                .font(.headline)
                .foregroundStyle(.white)
                .frame(width: 28, height: 28)
                .background(Circle().fill(Color.accentColor))

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
