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
            SettingsView()
                .environmentObject(appState)
        }
    }
}
