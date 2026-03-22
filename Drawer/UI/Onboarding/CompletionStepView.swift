//
//  CompletionStepView.swift
//  Drawer
//
//  Copyright © 2026 Drawer. MIT License.
//

import SwiftUI

struct CompletionStepView: View {
    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            successIcon

            VStack(spacing: 12) {
                Text("You're All Set!")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("Drawer is ready to keep your menu bar clean and organized.")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            quickReferenceSection

            Spacer()
        }
        .padding(.horizontal, 40)
    }

    private var successIcon: some View {
        ZStack {
            Circle()
                .fill(Color.green.opacity(0.15))
                .frame(width: 100, height: 100)

            Image(systemName: "checkmark.circle.fill")
                .font(.largeTitle)
                .foregroundStyle(.green)
        }
    }

    private var quickReferenceSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Reference")
                .font(.headline)

            VStack(alignment: .leading, spacing: 8) {
                QuickRefRow(icon: "arrow.left.arrow.right", text: "Click the toggle icon to show/hide icons")
                QuickRefRow(icon: "cursorarrow.click.2", text: "Right-click the toggle for more options")
                QuickRefRow(icon: "command", text: "Hold ⌘ + drag to rearrange icons")
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(nsColor: .controlBackgroundColor))
        )
    }
}

#Preview {
    CompletionStepView()
        .frame(width: 520, height: 380)
}
