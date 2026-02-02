//
//  PermissionBadge.swift
//  Drawer
//
//  Copyright © 2026 Drawer. MIT License.
//

import SwiftUI

// MARK: - PermissionBadge

struct PermissionBadge: View {
    @StateObject private var permissionManager = PermissionManager.shared

    var body: some View {
        HStack(spacing: 4) {
            if permissionManager.hasAllPermissions {
                Image(systemName: "checkmark.shield.fill")
                    .foregroundStyle(.green)
            } else {
                Image(systemName: "exclamationmark.shield.fill")
                    .foregroundStyle(.orange)
            }

            Text(permissionManager.hasAllPermissions ? "Ready" : "Setup Required")
                .font(.caption)
        }
    }
}
