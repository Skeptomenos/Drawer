//
//  MockPermissionManagerTests.swift
//  DrawerTests
//
//  Copyright © 2026 Drawer. MIT License.
//

import XCTest

@testable import Drawer

final class MockPermissionManagerTests: XCTestCase {

    @MainActor
    func testSETUP005_MockPermissionManagerCanBeInstantiated() {
        let mock = MockPermissionManager()

        XCTAssertTrue(mock.hasAccessibility)
        XCTAssertTrue(mock.hasScreenRecording)
        XCTAssertTrue(mock.hasAllPermissions)
        XCTAssertFalse(mock.isMissingPermissions)
        XCTAssertEqual(mock.accessibilityStatus, .granted)
        XCTAssertEqual(mock.screenRecordingStatus, .granted)
    }

    @MainActor
    func testMockPermissionManagerDeniedState() {
        let mock = MockPermissionManager()

        mock.mockHasAccessibility = false
        mock.mockHasScreenRecording = false

        XCTAssertFalse(mock.hasAccessibility)
        XCTAssertFalse(mock.hasScreenRecording)
        XCTAssertFalse(mock.hasAllPermissions)
        XCTAssertTrue(mock.isMissingPermissions)
        XCTAssertEqual(mock.accessibilityStatus, .denied)
        XCTAssertEqual(mock.screenRecordingStatus, .denied)
    }

    @MainActor
    func testMockPermissionManagerPartialPermissions() {
        let mock = MockPermissionManager()

        mock.mockHasAccessibility = true
        mock.mockHasScreenRecording = false

        XCTAssertTrue(mock.hasAccessibility)
        XCTAssertFalse(mock.hasScreenRecording)
        XCTAssertFalse(mock.hasAllPermissions)
        XCTAssertTrue(mock.isMissingPermissions)
    }

    @MainActor
    func testMockPermissionManagerRequestTracking() {
        let mock = MockPermissionManager()

        mock.requestAccessibility()

        XCTAssertTrue(mock.requestAccessibilityCalled)
        XCTAssertEqual(mock.requestAccessibilityCallCount, 1)

        mock.requestScreenRecording()

        XCTAssertTrue(mock.requestScreenRecordingCalled)
        XCTAssertEqual(mock.requestScreenRecordingCallCount, 1)
    }

    @MainActor
    func testMockPermissionManagerRequestByType() {
        let mock = MockPermissionManager()

        mock.request(.accessibility)

        XCTAssertTrue(mock.requestCalled)
        XCTAssertEqual(mock.lastRequestedPermission, .accessibility)
        XCTAssertTrue(mock.requestAccessibilityCalled)

        mock.request(.screenRecording)

        XCTAssertEqual(mock.requestCallCount, 2)
        XCTAssertEqual(mock.lastRequestedPermission, .screenRecording)
        XCTAssertTrue(mock.requestScreenRecordingCalled)
    }

    @MainActor
    func testMockPermissionManagerStatusForPermission() {
        let mock = MockPermissionManager()

        XCTAssertEqual(mock.status(for: .accessibility), .granted)
        XCTAssertEqual(mock.status(for: .screenRecording), .granted)

        mock.mockHasAccessibility = false

        XCTAssertEqual(mock.status(for: .accessibility), .denied)
        XCTAssertEqual(mock.status(for: .screenRecording), .granted)
    }

    @MainActor
    func testMockPermissionManagerIsGranted() {
        let mock = MockPermissionManager()

        XCTAssertTrue(mock.isGranted(.accessibility))
        XCTAssertTrue(mock.isGranted(.screenRecording))

        mock.mockHasScreenRecording = false

        XCTAssertTrue(mock.isGranted(.accessibility))
        XCTAssertFalse(mock.isGranted(.screenRecording))
    }

    @MainActor
    func testMockPermissionManagerResetTracking() {
        let mock = MockPermissionManager()

        mock.requestAccessibility()
        mock.requestScreenRecording()
        mock.openSystemSettings(for: .accessibility)

        XCTAssertTrue(mock.requestAccessibilityCalled)
        XCTAssertTrue(mock.requestScreenRecordingCalled)
        XCTAssertTrue(mock.openSystemSettingsCalled)

        mock.resetTracking()

        XCTAssertFalse(mock.requestAccessibilityCalled)
        XCTAssertEqual(mock.requestAccessibilityCallCount, 0)
        XCTAssertFalse(mock.requestScreenRecordingCalled)
        XCTAssertEqual(mock.requestScreenRecordingCallCount, 0)
        XCTAssertFalse(mock.openSystemSettingsCalled)
        XCTAssertNil(mock.lastOpenedSettingsPermission)
    }

    @MainActor
    func testMockPermissionManagerSetAllPermissions() {
        let mock = MockPermissionManager()

        mock.setAllPermissions(granted: false)

        XCTAssertFalse(mock.hasAccessibility)
        XCTAssertFalse(mock.hasScreenRecording)
        XCTAssertFalse(mock.hasAllPermissions)

        mock.setAllPermissions(granted: true)

        XCTAssertTrue(mock.hasAccessibility)
        XCTAssertTrue(mock.hasScreenRecording)
        XCTAssertTrue(mock.hasAllPermissions)
    }
}
