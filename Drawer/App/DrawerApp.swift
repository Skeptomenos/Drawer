//
//  DrawerApp.swift
//  Drawer
//
//  Copyright © 2026 Drawer. MIT License.
//

import SwiftUI

@main
struct DrawerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var appState = AppState()
    
    var body: some Scene {
        Settings {
            SettingsPlaceholderView()
                .environmentObject(appState)
        }
    }
}

// MARK: - Placeholder Views

struct SettingsPlaceholderView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "gearshape.2")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            
            Text("Drawer Settings")
                .font(.title2)
            
            Text("Settings UI coming in Phase 3")
                .foregroundStyle(.secondary)
        }
        .frame(width: 400, height: 300)
        .padding()
    }
}
