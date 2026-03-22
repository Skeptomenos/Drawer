//
//  LaunchAtLoginManager.swift
//  Drawer
//
//  Copyright © 2026 Drawer. MIT License.
//

import AppKit
import Foundation
import os.log
import ServiceManagement

// MARK: - LaunchAtLoginManager

@MainActor
@Observable
final class LaunchAtLoginManager {

    // MARK: - Singleton

    static let shared = LaunchAtLoginManager()

    // MARK: - Logger

    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.drawer", category: "LaunchAtLogin")

    // MARK: - Observable State

    private(set) var isEnabled: Bool = false
    private(set) var lastError: String?

    // MARK: - Initialization

    private init() {
        refreshStatus()
    }

    // MARK: - Public API

    /// Enables or disables launch at login
    /// - Parameter enabled: Whether to enable launch at login
    func setEnabled(_ enabled: Bool) {
        lastError = nil

        do {
            if enabled {
                try SMAppService.mainApp.register()
                logger.info("Successfully registered for launch at login")
            } else {
                try SMAppService.mainApp.unregister()
                logger.info("Successfully unregistered from launch at login")
            }
            refreshStatus()
        } catch {
            lastError = error.localizedDescription
            logger.error("Launch at login error: \(error.localizedDescription)")
            refreshStatus()
        }
    }

    /// Refreshes the current status from the system
    func refreshStatus() {
        let status = SMAppService.mainApp.status
        isEnabled = (status == .enabled)

        switch status {
        case .enabled:
            logger.debug("Launch at login status: enabled")
        case .notRegistered:
            logger.debug("Launch at login status: not registered")
        case .requiresApproval:
            logger.debug("Launch at login status: requires approval")
        case .notFound:
            logger.debug("Launch at login status: not found")
        @unknown default:
            logger.debug("Launch at login status: unknown")
        }
    }

    /// Opens System Settings to the Login Items section for manual management
    func openSystemSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.LoginItems-Settings.extension") {
            NSWorkspace.shared.open(url)
        }
    }
}
