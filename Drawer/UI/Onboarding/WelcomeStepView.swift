//
//  WelcomeStepView.swift
//  Drawer
//
//  Copyright © 2026 Drawer. MIT License.
//

import SwiftUI

struct WelcomeStepView: View {
    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            appIcon

            VStack(spacing: 12) {
                Text("Welcome to Drawer")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("A cleaner menu bar for your Mac")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 16) {
                FeatureRow(
                    icon: "eye.slash",
                    title: "Hide Menu Bar Icons",
                    description: "Keep your menu bar tidy by hiding icons you don't need to see"
                )

                FeatureRow(
                    icon: "rectangle.expand.vertical",
                    title: "Access Anytime",
                    description: "Reveal hidden icons with a click or hover"
                )

                FeatureRow(
                    icon: "hand.draw",
                    title: "Easy Organization",
                    description: "Drag icons to arrange them exactly how you want"
                )
            }
            .padding(.horizontal, 40)
            .padding(.top, 16)

            Spacer()
        }
        .padding()
    }

    private var appIcon: some View {
        Image(nsImage: NSApp.applicationIconImage)
            .resizable()
            .frame(width: 96, height: 96)
            .shadow(color: .black.opacity(0.2), radius: 8, y: 4)
    }
}

private struct FeatureRow: View {
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

#Preview {
    WelcomeStepView()
        .frame(width: 520, height: 380)
}
