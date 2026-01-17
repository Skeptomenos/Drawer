//
//  TutorialStepView.swift
//  Drawer
//
//  Copyright © 2026 Drawer. MIT License.
//

import SwiftUI

struct TutorialStepView: View {
    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            headerSection

            instructionsList

            tipSection

            Spacer()
        }
        .padding(.horizontal, 40)
    }

    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "hand.draw")
                .font(.system(size: 48))
                .foregroundStyle(Color.accentColor)

            Text("Arrange Your Icons")
                .font(.title)
                .fontWeight(.bold)

            Text("Use macOS built-in feature to organize your menu bar.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    private var instructionsList: some View {
        VStack(alignment: .leading, spacing: 16) {
            InstructionRow(
                step: 1,
                title: "Hold ⌘ (Command)",
                description: "Press and hold the Command key on your keyboard"
            )

            InstructionRow(
                step: 2,
                title: "Drag Menu Bar Icons",
                description: "While holding ⌘, drag any menu bar icon to reposition it"
            )

            InstructionRow(
                step: 3,
                title: "Place Before Separator",
                description: "Icons to the left of Drawer's separator will be hidden"
            )
        }
        .padding(.top, 8)
    }

    private var tipSection: some View {
        HStack(spacing: 12) {
            Image(systemName: "lightbulb.fill")
                .foregroundStyle(.yellow)

            Text("Tip: The separator icon (|) marks the boundary. Icons to its left get hidden.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.yellow.opacity(0.1))
        )
    }
}

private struct InstructionRow: View {
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

#Preview {
    TutorialStepView()
        .frame(width: 520, height: 380)
}
