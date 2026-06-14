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

    var body: some Scene {
        Settings {
            // Test host guard: touching AppState.shared boots the full object
            // graph (real status items) before AppDelegate's guard can run.
            // See Drawer/Utilities/TestEnvironment.swift.
            if TestEnvironment.isRunningTests {
                EmptyView()
            } else {
                SettingsView()
                    .environment(AppState.shared)
            }
        }
    }
}
