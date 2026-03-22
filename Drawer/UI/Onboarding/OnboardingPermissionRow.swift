//
//  OnboardingPermissionRow.swift
//  Drawer
//
//  Extracted from PermissionsStepView.swift per ARCH-001 (one type per file).
//
//  Copyright © 2026 Drawer. MIT License.
//

import SwiftUI

/// A permission row for the onboarding permissions step.
///
/// Displays a permission's status, name, description, and an action button
/// to request the permission if not yet granted.
struct OnboardingPermissionRow: View {
    let permission: PermissionType
    let status: PermissionStatus
    let onRequest: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            statusIcon

            VStack(alignment: .leading, spacing: 2) {
                Text(permission.displayName)
                    .font(.headline)

                Text(permission.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            actionButton
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(nsColor: .controlBackgroundColor))
        )
    }

    @ViewBuilder
    private var statusIcon: some View {
        switch status {
        case .granted:
            Image(systemName: "checkmark.circle.fill")
                .font(.title2)
                .foregroundStyle(.green)
        case .denied, .unknown:
            Image(systemName: "circle")
                .font(.title2)
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private var actionButton: some View {
        switch status {
        case .granted:
            Text("Granted")
                .font(.caption)
                .foregroundStyle(.secondary)
        case .denied, .unknown:
            Button("Grant") {
                onRequest()
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
    }
}
