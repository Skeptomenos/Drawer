//
//  PermissionManager.swift
//  Drawer
//
//  Copyright © 2026 Drawer. MIT License.
//

import AppKit
import Foundation
import os.log

// MARK: - PermissionProviding Protocol

@MainActor
protocol PermissionProviding {
    var hasAccessibility: Bool { get }
    var hasScreenRecording: Bool { get }
    var hasAllPermissions: Bool { get }
    var isMissingPermissions: Bool { get }
}

// MARK: - PermissionType

/// Types of system permissions required by Drawer
enum PermissionType: String, CaseIterable, Identifiable {
    case accessibility
    case screenRecording

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .accessibility:
            return "Accessibility"
        case .screenRecording:
            return "Screen Recording"
        }
    }

    var description: String {
        switch self {
        case .accessibility:
            return "Required to simulate clicks on hidden menu bar icons"
        case .screenRecording:
            return "Required to capture images of hidden menu bar icons"
        }
    }

    var systemSettingsURL: URL? {
        switch self {
        case .accessibility:
            return URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")
        case .screenRecording:
            return URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture")
        }
    }
}

// MARK: - PermissionStatus

/// Status of a system permission
enum PermissionStatus: Equatable {
    case granted
    case denied
    case unknown

    var isGranted: Bool { self == .granted }
}

// MARK: - PermissionManager

@MainActor
@Observable
final class PermissionManager: PermissionProviding {

    // MARK: - Singleton

    static let shared = PermissionManager()

    // MARK: - Callbacks

    @ObservationIgnored var onPermissionStatusChanged: (() -> Void)?

    // MARK: - Logger

    @ObservationIgnored private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.drawer", category: "Permissions")

    // MARK: - Published State

    private(set) var accessibilityStatus: PermissionStatus = .unknown {
        didSet {
            if oldValue != accessibilityStatus {
                onPermissionStatusChanged?()
            }
        }
    }

    private(set) var screenRecordingStatus: PermissionStatus = .unknown {
        didSet {
            if oldValue != screenRecordingStatus {
                onPermissionStatusChanged?()
            }
        }
    }

    // MARK: - Computed Properties

    /// Whether Accessibility permission is granted
    var hasAccessibility: Bool {
        AXIsProcessTrusted()
    }

    /// Whether Screen Recording permission is granted
    /// Uses CGPreflightScreenCaptureAccess which doesn't prompt the user
    var hasScreenRecording: Bool {
        CGPreflightScreenCaptureAccess()
    }

    /// Whether all required permissions are granted
    var hasAllPermissions: Bool {
        hasAccessibility && hasScreenRecording
    }

    /// Whether any permission is missing
    var isMissingPermissions: Bool {
        !hasAllPermissions
    }



    // MARK: - Initialization

    private init() {
        refreshAllStatuses()
        setupPolling()

        #if DEBUG
        logger.debug("=== PERMISSION MANAGER INIT (B1.2) ===")
        logger.debug("hasScreenRecording: \(self.hasScreenRecording)")
        logger.debug("hasAccessibility: \(self.hasAccessibility)")
        logger.debug("hasAllPermissions: \(self.hasAllPermissions)")
        logger.debug("=== END PERMISSION DEBUG ===")
        #endif
    }

    // MARK: - Status Refresh

    /// Refreshes the cached status of all system permissions.
    ///
    /// Queries the system for current Accessibility and Screen Recording permission states
    /// and updates the corresponding status properties. Triggers `onPermissionStatusChanged`
    /// callback if any status changed.
    func refreshAllStatuses() {
        refreshAccessibilityStatus()
        refreshScreenRecordingStatus()
    }

    /// Refreshes the cached Accessibility permission status.
    ///
    /// Queries `AXIsProcessTrusted()` and updates `accessibilityStatus`.
    /// Triggers `onPermissionStatusChanged` if status changed.
    func refreshAccessibilityStatus() {
        let isGranted = AXIsProcessTrusted()
        accessibilityStatus = isGranted ? .granted : .denied
        logger.debug("Accessibility permission: \(isGranted ? "granted" : "denied")")
    }

    /// Refreshes the cached Screen Recording permission status.
    ///
    /// Queries `CGPreflightScreenCaptureAccess()` (does not prompt user) and updates `screenRecordingStatus`.
    /// Triggers `onPermissionStatusChanged` if status changed.
    func refreshScreenRecordingStatus() {
        let isGranted = CGPreflightScreenCaptureAccess()
        screenRecordingStatus = isGranted ? .granted : .denied
        logger.debug("Screen Recording permission: \(isGranted ? "granted" : "denied")")
    }

    // MARK: - Permission Requests

    /// Requests Accessibility permission.
    /// Calls AXIsProcessTrustedWithOptions to register the app in System Settings,
    /// then opens the Accessibility pane for the user to enable it.
    func requestAccessibility() {
        logger.info("Requesting Accessibility permission")

        if AXIsProcessTrusted() {
            logger.debug("Accessibility already granted")
            refreshAccessibilityStatus()
            return
        }

        // This registers the app in the Accessibility list (even if prompt doesn't show)
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue(): true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)

        // Also open System Settings so user can toggle it on
        openSystemSettings(for: .accessibility)

        Task {
            try? await Task.sleep(for: .seconds(1))
            refreshAccessibilityStatus()
        }
    }

    /// Requests Screen Recording permission by prompting the user.
    /// Opens System Settings to the Screen Recording pane.
    ///
    /// - Note: Uses `CGRequestScreenCaptureAccess()` which triggers the system prompt.
    func requestScreenRecording() {
        logger.info("Requesting Screen Recording permission")

        // This will show the system prompt asking user to grant permission
        CGRequestScreenCaptureAccess()

        // Refresh status after a short delay to allow user interaction
        Task {
            try? await Task.sleep(for: .seconds(1))
            refreshScreenRecordingStatus()
        }
    }

    /// Requests a specific permission from the user.
    ///
    /// Triggers the appropriate system prompt or opens System Settings for the given permission type.
    /// The status is refreshed asynchronously after a short delay to allow for user interaction.
    ///
    /// - Parameter permission: The type of permission to request (`.accessibility` or `.screenRecording`)
    func request(_ permission: PermissionType) {
        switch permission {
        case .accessibility:
            requestAccessibility()
        case .screenRecording:
            requestScreenRecording()
        }
    }

    /// Requests all missing permissions
    func requestAllMissing() {
        if !hasAccessibility {
            requestAccessibility()
        }
        if !hasScreenRecording {
            requestScreenRecording()
        }
    }

    // MARK: - System Settings Navigation

    /// Opens System Settings to the appropriate privacy pane for the given permission
    func openSystemSettings(for permission: PermissionType) {
        guard let url = permission.systemSettingsURL else {
            logger.error("No System Settings URL for permission: \(permission.rawValue)")
            return
        }

        logger.info("Opening System Settings for: \(permission.rawValue)")
        NSWorkspace.shared.open(url)
    }

    /// Opens System Settings to the Privacy & Security pane
    func openPrivacySettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security") {
            NSWorkspace.shared.open(url)
        }
    }

    // MARK: - Polling

    @ObservationIgnored private var pollingTask: Task<Void, Never>?

    /// Sets up periodic polling to detect permission changes.
    /// This is necessary because there's no notification for TCC changes.
    /// Polling stops automatically once all permissions are granted.
    private func setupPolling() {
        pollingTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(2))
                guard let self = self, !Task.isCancelled else { break }
                self.refreshAllStatuses()

                if self.hasAllPermissions {
                    self.logger.debug("All permissions granted, stopping polling")
                    break
                }
            }
        }
    }

    func cleanup() {
        pollingTask?.cancel()
    }

    // MARK: - Status Helpers

    /// Returns the status for a specific permission type
    func status(for permission: PermissionType) -> PermissionStatus {
        switch permission {
        case .accessibility:
            return accessibilityStatus
        case .screenRecording:
            return screenRecordingStatus
        }
    }

    /// Returns whether a specific permission is granted
    func isGranted(_ permission: PermissionType) -> Bool {
        switch permission {
        case .accessibility:
            return hasAccessibility
        case .screenRecording:
            return hasScreenRecording
        }
    }
}
