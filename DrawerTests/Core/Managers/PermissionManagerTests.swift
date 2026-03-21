//
//  PermissionManagerTests.swift
//  DrawerTests
//
//  Copyright © 2026 Drawer. MIT License.
//

import XCTest

@testable import Drawer

@MainActor
final class PermissionManagerTests: XCTestCase {

    // MARK: - Properties

    private var sut: PermissionManager!

    // MARK: - Setup & Teardown

    override func setUp() async throws {
        try await super.setUp()
        sut = PermissionManager.shared
    }

    override func tearDown() async throws {
        sut = nil
        try await super.tearDown()
    }

    // MARK: - PRM-001: hasAccessibility returns correct value

    func testPRM001_HasAccessibilityReturnsCorrectValue() async throws {
        // Arrange
        let expectedValue = AXIsProcessTrusted()

        // Act
        let actualValue = sut.hasAccessibility

        // Assert
        XCTAssertEqual(
            actualValue,
            expectedValue,
            "PRM-001: hasAccessibility should match AXIsProcessTrusted()"
        )
    }

    // MARK: - PRM-002: hasScreenRecording returns correct value

    func testPRM002_HasScreenRecordingReturnsCorrectValue() async throws {
        // Arrange
        let expectedValue = CGPreflightScreenCaptureAccess()

        // Act
        let actualValue = sut.hasScreenRecording

        // Assert
        XCTAssertEqual(
            actualValue,
            expectedValue,
            "PRM-002: hasScreenRecording should match CGPreflightScreenCaptureAccess()"
        )
    }

    // MARK: - PRM-003: hasAllPermissions when both granted

    func testPRM003_HasAllPermissionsWhenBothGranted() async throws {
        // Arrange
        let hasAccessibility = AXIsProcessTrusted()
        let hasScreenRecording = CGPreflightScreenCaptureAccess()
        let expectedValue = hasAccessibility && hasScreenRecording

        // Act
        let actualValue = sut.hasAllPermissions

        // Assert
        XCTAssertEqual(
            actualValue,
            expectedValue,
            "PRM-003: hasAllPermissions should be true only when both permissions are granted"
        )

        // Additional verification: if both are granted, hasAllPermissions must be true
        if hasAccessibility && hasScreenRecording {
            XCTAssertTrue(
                actualValue,
                "PRM-003: hasAllPermissions should be true when both permissions are granted"
            )
        }
    }

    // MARK: - PRM-004: hasAllPermissions when one missing

    func testPRM004_HasAllPermissionsWhenOneMissing() async throws {
        // Arrange
        let hasAccessibility = AXIsProcessTrusted()
        let hasScreenRecording = CGPreflightScreenCaptureAccess()

        // Act
        let actualValue = sut.hasAllPermissions

        // Assert
        // Verify the logical AND behavior: if either permission is missing, hasAllPermissions must be false
        if !hasAccessibility || !hasScreenRecording {
            XCTAssertFalse(
                actualValue,
                "PRM-004: hasAllPermissions should be false when at least one permission is missing"
            )
        }

        // Verify the inverse relationship: hasAllPermissions == (hasAccessibility && hasScreenRecording)
        XCTAssertEqual(
            actualValue,
            hasAccessibility && hasScreenRecording,
            "PRM-004: hasAllPermissions should equal (hasAccessibility && hasScreenRecording)"
        )

        // Additional verification: if only one is granted, hasAllPermissions must be false
        if hasAccessibility != hasScreenRecording {
            XCTAssertFalse(
                actualValue,
                "PRM-004: hasAllPermissions should be false when permissions differ"
            )
        }
    }

    // MARK: - PRM-005: isMissingPermissions is inverse of hasAllPermissions

    func testPRM005_IsMissingPermissionsIsInverseOfHasAllPermissions() async throws {
        // Arrange
        let hasAllPermissions = sut.hasAllPermissions

        // Act
        let isMissingPermissions = sut.isMissingPermissions

        // Assert
        XCTAssertEqual(
            isMissingPermissions,
            !hasAllPermissions,
            "PRM-005: isMissingPermissions should be the inverse of hasAllPermissions"
        )

        // Additional verification: both properties should never have the same value
        XCTAssertNotEqual(
            isMissingPermissions,
            hasAllPermissions,
            "PRM-005: isMissingPermissions and hasAllPermissions should always be opposite"
        )

        // Verify the relationship holds: isMissingPermissions == !hasAllPermissions
        if hasAllPermissions {
            XCTAssertFalse(
                isMissingPermissions,
                "PRM-005: isMissingPermissions should be false when hasAllPermissions is true"
            )
        } else {
            XCTAssertTrue(
                isMissingPermissions,
                "PRM-005: isMissingPermissions should be true when hasAllPermissions is false"
            )
        }
    }

    // MARK: - PRM-006: status for accessibility

    func testPRM006_StatusForAccessibilityReturnsCorrectStatus() async throws {
        // Arrange
        // Refresh to ensure status is up-to-date
        sut.refreshAccessibilityStatus()

        let isAccessibilityGranted = AXIsProcessTrusted()
        let expectedStatus: PermissionStatus = isAccessibilityGranted ? .granted : .denied

        // Act
        let actualStatus = sut.status(for: .accessibility)

        // Assert
        XCTAssertEqual(
            actualStatus,
            expectedStatus,
            "PRM-006: status(for: .accessibility) should return \(expectedStatus) when AXIsProcessTrusted() is \(isAccessibilityGranted)"
        )

        // Additional verification: status should match the published accessibilityStatus property
        XCTAssertEqual(
            actualStatus,
            sut.accessibilityStatus,
            "PRM-006: status(for: .accessibility) should match accessibilityStatus property"
        )

        // Verify isGranted helper on the status
        XCTAssertEqual(
            actualStatus.isGranted,
            isAccessibilityGranted,
            "PRM-006: status.isGranted should match AXIsProcessTrusted()"
        )
    }

    // MARK: - PRM-007: status for screenRecording

    func testPRM007_StatusForScreenRecordingReturnsCorrectStatus() async throws {
        // Arrange
        // Refresh to ensure status is up-to-date
        sut.refreshScreenRecordingStatus()

        let isScreenRecordingGranted = CGPreflightScreenCaptureAccess()
        let expectedStatus: PermissionStatus = isScreenRecordingGranted ? .granted : .denied

        // Act
        let actualStatus = sut.status(for: .screenRecording)

        // Assert
        XCTAssertEqual(
            actualStatus,
            expectedStatus,
            "PRM-007: status(for: .screenRecording) should return \(expectedStatus) when CGPreflightScreenCaptureAccess() is \(isScreenRecordingGranted)"
        )

        // Additional verification: status should match the published screenRecordingStatus property
        XCTAssertEqual(
            actualStatus,
            sut.screenRecordingStatus,
            "PRM-007: status(for: .screenRecording) should match screenRecordingStatus property"
        )

        // Verify isGranted helper on the status
        XCTAssertEqual(
            actualStatus.isGranted,
            isScreenRecordingGranted,
            "PRM-007: status.isGranted should match CGPreflightScreenCaptureAccess()"
        )
    }

    // MARK: - PRM-008: isGranted accessibility

    func testPRM008_IsGrantedAccessibilityWorks() async throws {
        // Arrange
        let expectedValue = AXIsProcessTrusted()

        // Act
        let actualValue = sut.isGranted(.accessibility)

        // Assert
        XCTAssertEqual(
            actualValue,
            expectedValue,
            "PRM-008: isGranted(.accessibility) should match AXIsProcessTrusted()"
        )

        // Additional verification: isGranted should match hasAccessibility property
        XCTAssertEqual(
            actualValue,
            sut.hasAccessibility,
            "PRM-008: isGranted(.accessibility) should match hasAccessibility property"
        )

        // Verify consistency with status(for:).isGranted
        XCTAssertEqual(
            actualValue,
            sut.status(for: .accessibility).isGranted,
            "PRM-008: isGranted(.accessibility) should be consistent with status(for: .accessibility).isGranted"
        )
    }

    // MARK: - PRM-009: isGranted screenRecording

    func testPRM009_IsGrantedScreenRecordingWorks() async throws {
        // Arrange
        let expectedValue = CGPreflightScreenCaptureAccess()

        // Act
        let actualValue = sut.isGranted(.screenRecording)

        // Assert
        XCTAssertEqual(
            actualValue,
            expectedValue,
            "PRM-009: isGranted(.screenRecording) should match CGPreflightScreenCaptureAccess()"
        )

        // Additional verification: isGranted should match hasScreenRecording property
        XCTAssertEqual(
            actualValue,
            sut.hasScreenRecording,
            "PRM-009: isGranted(.screenRecording) should match hasScreenRecording property"
        )

        // Verify consistency with status(for:).isGranted
        XCTAssertEqual(
            actualValue,
            sut.status(for: .screenRecording).isGranted,
            "PRM-009: isGranted(.screenRecording) should be consistent with status(for: .screenRecording).isGranted"
        )
    }

    // MARK: - PRM-010: refreshAccessibilityStatus updates status property

    func testPRM010_RefreshAccessibilityStatusUpdatesProperty() async throws {
        // Arrange
        let expectedGranted = AXIsProcessTrusted()
        let expectedStatus: PermissionStatus = expectedGranted ? .granted : .denied

        // Act
        sut.refreshAccessibilityStatus()

        // Assert
        XCTAssertEqual(
            sut.accessibilityStatus,
            expectedStatus,
            "PRM-010: accessibilityStatus should reflect AXIsProcessTrusted() after refresh"
        )
        XCTAssertNotEqual(
            sut.accessibilityStatus,
            .unknown,
            "PRM-010: accessibilityStatus should not be .unknown after refresh"
        )
    }

    // MARK: - PRM-011: refreshAllStatuses updates state

    func testPRM011_RefreshAllStatusesUpdatesState() async throws {
        // Arrange
        let expectedAccessibilityGranted = AXIsProcessTrusted()
        let expectedScreenRecordingGranted = CGPreflightScreenCaptureAccess()
        let expectedAccessibilityStatus: PermissionStatus = expectedAccessibilityGranted ? .granted : .denied
        let expectedScreenRecordingStatus: PermissionStatus = expectedScreenRecordingGranted ? .granted : .denied

        // Act
        sut.refreshAllStatuses()

        // Assert - Verify final state matches system permission state
        XCTAssertEqual(
            sut.accessibilityStatus,
            expectedAccessibilityStatus,
            "PRM-011: accessibilityStatus should reflect current AXIsProcessTrusted() value after refresh"
        )

        XCTAssertEqual(
            sut.screenRecordingStatus,
            expectedScreenRecordingStatus,
            "PRM-011: screenRecordingStatus should reflect current CGPreflightScreenCaptureAccess() value after refresh"
        )

        // Verify the status values are not .unknown after refresh
        XCTAssertNotEqual(
            sut.accessibilityStatus,
            .unknown,
            "PRM-011: accessibilityStatus should not be .unknown after refreshAllStatuses()"
        )

        XCTAssertNotEqual(
            sut.screenRecordingStatus,
            .unknown,
            "PRM-011: screenRecordingStatus should not be .unknown after refreshAllStatuses()"
        )
    }
}
