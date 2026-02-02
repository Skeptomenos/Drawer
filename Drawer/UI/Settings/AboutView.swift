//
//  AboutView.swift
//  Drawer
//
//  Copyright © 2026 Drawer. MIT License.
//

import SwiftUI

struct AboutView: View {
    // MARK: - Constants

    private static let githubURL: URL = {
        guard let url = URL(string: "https://github.com/dwarvesf/hidden") else {
            fatalError("Invalid hardcoded GitHub URL - this is a programmer error")
        }
        return url
    }()

    // MARK: - Properties

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .frame(width: 96, height: 96)

            Text("Drawer")
                .font(.title)
                .fontWeight(.semibold)

            Text("Version \(appVersion) (\(buildNumber))")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Text("A beautiful menu bar organizer for macOS")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Spacer()

            VStack(spacing: 8) {
                Link("View on GitHub", destination: Self.githubURL)
                    .font(.callout)

                Text("Based on Hidden Bar by Dwarves Foundation")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }

            Spacer()
                .frame(height: 20)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    AboutView()
        .frame(width: 450, height: 320)
}
