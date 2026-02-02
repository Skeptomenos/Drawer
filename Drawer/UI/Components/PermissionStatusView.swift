//
//  PermissionStatusView.swift
//  Drawer
//
//  Copyright © 2026 Drawer. MIT License.
//

import SwiftUI

// MARK: - PermissionStatusView

struct PermissionStatusView: View {
    @State private var permissionManager = PermissionManager.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Permissions")
                .font(.headline)

            Text("Drawer needs these permissions to show and interact with hidden menu bar icons.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            VStack(spacing: 12) {
                ForEach(PermissionType.allCases) { permission in
                    PermissionRow(
                        permission: permission,
                        status: permissionManager.status(for: permission),
                        onRequest: { permissionManager.request(permission) },
                        onOpenSettings: { permissionManager.openSystemSettings(for: permission) }
                    )
                }
            }
            .padding(.top, 8)

            if permissionManager.hasAllPermissions {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    Text("All permissions granted")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 8)
            }
        }
        .padding()
        .frame(minWidth: 350)
    }
}

// MARK: - Preview

#Preview("Permission Status") {
    PermissionStatusView()
}

#Preview("Permission Badge") {
    PermissionBadge()
        .padding()
}
