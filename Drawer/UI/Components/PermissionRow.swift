//
//  PermissionRow.swift
//  Drawer
//
//  Copyright © 2026 Drawer. MIT License.
//

import SwiftUI

// MARK: - PermissionRow

struct PermissionRow: View {
    let permission: PermissionType
    let status: PermissionStatus
    let onRequest: () -> Void
    let onOpenSettings: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            statusIcon

            VStack(alignment: .leading, spacing: 2) {
                Text(permission.displayName)
                    .font(.body)

                Text(permission.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            actionButton
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
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
        case .denied:
            Image(systemName: "xmark.circle.fill")
                .font(.title2)
                .foregroundStyle(.red)
        case .unknown:
            Image(systemName: "questionmark.circle.fill")
                .font(.title2)
                .foregroundStyle(.orange)
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
            Menu {
                Button("Request Permission") {
                    onRequest()
                }
                Button("Open System Settings") {
                    onOpenSettings()
                }
            } label: {
                Text("Grant")
                    .font(.caption.weight(.medium))
            }
            .menuStyle(.borderlessButton)
            .fixedSize()
        }
    }
}
