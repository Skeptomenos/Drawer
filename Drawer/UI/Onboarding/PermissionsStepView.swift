//
//  PermissionsStepView.swift
//  Drawer
//
//  Copyright © 2026 Drawer. MIT License.
//

import SwiftUI

struct PermissionsStepView: View {
    @StateObject private var permissionManager = PermissionManager.shared
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            headerSection
            
            permissionsList
            
            if permissionManager.hasAllPermissions {
                allGrantedBadge
            }
            
            Spacer()
        }
        .padding(.horizontal, 40)
    }
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "lock.shield")
                .font(.system(size: 48))
                .foregroundStyle(Color.accentColor)
            
            Text("Permissions Required")
                .font(.title)
                .fontWeight(.bold)
            
            Text("Drawer needs these permissions to capture and interact with hidden menu bar icons.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
    
    private var permissionsList: some View {
        VStack(spacing: 12) {
            ForEach(PermissionType.allCases) { permission in
                OnboardingPermissionRow(
                    permission: permission,
                    status: permissionManager.status(for: permission),
                    onRequest: { permissionManager.request(permission) }
                )
            }
        }
        .padding(.top, 8)
    }
    
    private var allGrantedBadge: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
            Text("All permissions granted!")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.top, 8)
    }
}

private struct OnboardingPermissionRow: View {
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

#Preview {
    PermissionsStepView()
        .frame(width: 520, height: 380)
}
