//
//  MockPermissionManager.swift
//  DrawerTests
//
//  Copyright © 2026 Drawer. MIT License.
//

import Combine
import Foundation

@testable import Drawer

/// SETUP-005: Mock implementation of PermissionManager for testing.
/// Allows tests to control permission states without requiring actual system permissions.
@MainActor
final class MockPermissionManager: ObservableObject, PermissionProviding {
    
    // MARK: - Published State (mirrors PermissionManager)
    
    @Published private(set) var accessibilityStatus: PermissionStatus = .unknown
    @Published private(set) var screenRecordingStatus: PermissionStatus = .unknown
    
    // MARK: - Configurable Permission States
    
    /// Set this to control hasAccessibility return value
    var mockHasAccessibility: Bool = true {
        didSet {
            accessibilityStatus = mockHasAccessibility ? .granted : .denied
        }
    }
    
    /// Set this to control hasScreenRecording return value
    var mockHasScreenRecording: Bool = true {
        didSet {
            screenRecordingStatus = mockHasScreenRecording ? .granted : .denied
        }
    }
    
    // MARK: - Computed Properties (mirrors PermissionManager)
    
    var hasAccessibility: Bool {
        mockHasAccessibility
    }
    
    var hasScreenRecording: Bool {
        mockHasScreenRecording
    }
    
    var hasAllPermissions: Bool {
        hasAccessibility && hasScreenRecording
    }
    
    var isMissingPermissions: Bool {
        !hasAllPermissions
    }
    
    // MARK: - Combine (mirrors PermissionManager)
    
    var permissionStatusChanged: AnyPublisher<Void, Never> {
        Publishers.Merge(
            $accessibilityStatus.map { _ in () },
            $screenRecordingStatus.map { _ in () }
        )
        .eraseToAnyPublisher()
    }
    
    // MARK: - Test Tracking
    
    var requestAccessibilityCalled = false
    var requestAccessibilityCallCount = 0
    
    var requestScreenRecordingCalled = false
    var requestScreenRecordingCallCount = 0
    
    var requestCalled = false
    var requestCallCount = 0
    var lastRequestedPermission: PermissionType?
    
    var requestAllMissingCalled = false
    var requestAllMissingCallCount = 0
    
    var refreshAllStatusesCalled = false
    var refreshAllStatusesCallCount = 0
    
    var openSystemSettingsCalled = false
    var openSystemSettingsCallCount = 0
    var lastOpenedSettingsPermission: PermissionType?
    
    var openPrivacySettingsCalled = false
    var openPrivacySettingsCallCount = 0
    
    // MARK: - Initialization
    
    init() {
        // Set initial statuses based on mock values
        accessibilityStatus = mockHasAccessibility ? .granted : .denied
        screenRecordingStatus = mockHasScreenRecording ? .granted : .denied
    }
    
    // MARK: - Methods (mirrors PermissionManager)
    
    func refreshAllStatuses() {
        refreshAllStatusesCalled = true
        refreshAllStatusesCallCount += 1
        accessibilityStatus = mockHasAccessibility ? .granted : .denied
        screenRecordingStatus = mockHasScreenRecording ? .granted : .denied
    }
    
    func refreshAccessibilityStatus() {
        accessibilityStatus = mockHasAccessibility ? .granted : .denied
    }
    
    func refreshScreenRecordingStatus() {
        screenRecordingStatus = mockHasScreenRecording ? .granted : .denied
    }
    
    func requestAccessibility() {
        requestAccessibilityCalled = true
        requestAccessibilityCallCount += 1
    }
    
    func requestScreenRecording() {
        requestScreenRecordingCalled = true
        requestScreenRecordingCallCount += 1
    }
    
    func request(_ permission: PermissionType) {
        requestCalled = true
        requestCallCount += 1
        lastRequestedPermission = permission
        
        switch permission {
        case .accessibility:
            requestAccessibility()
        case .screenRecording:
            requestScreenRecording()
        }
    }
    
    func requestAllMissing() {
        requestAllMissingCalled = true
        requestAllMissingCallCount += 1
        
        if !hasAccessibility {
            requestAccessibility()
        }
        if !hasScreenRecording {
            requestScreenRecording()
        }
    }
    
    func openSystemSettings(for permission: PermissionType) {
        openSystemSettingsCalled = true
        openSystemSettingsCallCount += 1
        lastOpenedSettingsPermission = permission
    }
    
    func openPrivacySettings() {
        openPrivacySettingsCalled = true
        openPrivacySettingsCallCount += 1
    }
    
    func status(for permission: PermissionType) -> PermissionStatus {
        switch permission {
        case .accessibility:
            return accessibilityStatus
        case .screenRecording:
            return screenRecordingStatus
        }
    }
    
    func isGranted(_ permission: PermissionType) -> Bool {
        switch permission {
        case .accessibility:
            return hasAccessibility
        case .screenRecording:
            return hasScreenRecording
        }
    }
    
    // MARK: - Test Helpers
    
    /// Resets all tracking flags and counters
    func resetTracking() {
        requestAccessibilityCalled = false
        requestAccessibilityCallCount = 0
        requestScreenRecordingCalled = false
        requestScreenRecordingCallCount = 0
        requestCalled = false
        requestCallCount = 0
        lastRequestedPermission = nil
        requestAllMissingCalled = false
        requestAllMissingCallCount = 0
        refreshAllStatusesCalled = false
        refreshAllStatusesCallCount = 0
        openSystemSettingsCalled = false
        openSystemSettingsCallCount = 0
        lastOpenedSettingsPermission = nil
        openPrivacySettingsCalled = false
        openPrivacySettingsCallCount = 0
    }
    
    /// Sets both permissions at once
    func setAllPermissions(granted: Bool) {
        mockHasAccessibility = granted
        mockHasScreenRecording = granted
    }
}
