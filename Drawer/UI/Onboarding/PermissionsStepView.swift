//
//  PermissionsStepView.swift
//  Drawer
//
//  Copyright © 2026 Drawer. MIT License.
//

import SwiftUI

struct PermissionsStepView: View {
    @State private var permissionManager = PermissionManager.shared

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
                .font(.largeTitle)
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

#Preview {
    PermissionsStepView()
        .frame(width: 520, height: 380)
}
