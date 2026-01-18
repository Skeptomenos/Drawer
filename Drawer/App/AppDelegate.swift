//
//  AppDelegate.swift
//  Drawer
//
//  Copyright © 2026 Drawer. MIT License.
//

import AppKit
import os.log
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {

    // MARK: - Properties

    static var shared: AppDelegate?

    private var onboardingWindow: NSWindow?
    private var settingsWindow: NSWindow?

    /// Holds the position restorer instance during restoration
    private var iconPositionRestorer: IconPositionRestorer?

    private let logger = Logger(subsystem: "com.drawer.app", category: "AppDelegate")

    // MARK: - Lifecycle

    func applicationDidFinishLaunching(_ notification: Notification) {
        AppDelegate.shared = self

        _ = AppState.shared

        showOnboardingIfNeeded()
        setupIconPositionRestoration()
    }

    // MARK: - Icon Position Restoration

    /// Sets up asynchronous icon position restoration after app launch.
    /// Waits 2 seconds to let the menu bar stabilize before restoring positions.
    private func setupIconPositionRestoration() {
        // Skip restoration if no saved positions exist
        guard !SettingsManager.shared.savedIconPositions.isEmpty else {
            logger.info("No saved icon positions to restore")
            return
        }

        iconPositionRestorer = IconPositionRestorer.shared

        // Restore positions asynchronously (non-blocking)
        Task { [weak self] in
            // Wait 2 seconds for menu bar to stabilize after app launch
            try? await Task.sleep(for: .seconds(2))

            self?.logger.info("Starting icon position restoration")
            await self?.iconPositionRestorer?.restorePositions()
            self?.logger.info("Icon position restoration complete")
        }
    }

    func openSettings() {
        if let window = settingsWindow {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let settingsView = SettingsView()
            .environmentObject(AppState.shared)

        let hostingView = NSHostingView(rootView: settingsView)
        hostingView.frame = NSRect(x: 0, y: 0, width: 450, height: 320)

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 450, height: 320),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "Drawer Settings"
        window.contentView = hostingView
        window.center()
        window.makeKeyAndOrderFront(nil)
        window.isReleasedWhenClosed = false

        self.settingsWindow = window
        NSApp.activate(ignoringOtherApps: true)
    }

    private func showOnboardingIfNeeded() {
        guard !SettingsManager.shared.hasCompletedOnboarding else { return }

        let onboardingView = OnboardingView(onComplete: { [weak self] in
            self?.closeOnboarding()
            SettingsManager.shared.hasCompletedOnboarding = true
        })

        let hostingView = NSHostingView(rootView: onboardingView)
        hostingView.frame = NSRect(x: 0, y: 0, width: 520, height: 480)

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 520, height: 480),
            styleMask: [.titled, .closable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.isMovableByWindowBackground = true
        window.contentView = hostingView
        window.center()
        window.makeKeyAndOrderFront(nil)

        self.onboardingWindow = window
    }

    private func closeOnboarding() {
        onboardingWindow?.close()
        onboardingWindow = nil
    }
}
