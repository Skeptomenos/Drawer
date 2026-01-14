//
//  PermissionStatusView.swift
//  Drawer
//
//  Copyright © 2026 Drawer. MIT License.
//

import SwiftUI

// MARK: - PermissionStatusView

struct PermissionStatusView: View {
    @StateObject private var permissionManager = PermissionManager.shared
    
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

// MARK: - Compact Permission Badge

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

// MARK: - Preview

#Preview("Permission Status") {
    PermissionStatusView()
}

#Preview("Permission Badge") {
    PermissionBadge()
        .padding()
}
