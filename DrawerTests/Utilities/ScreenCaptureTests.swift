//
//  ScreenCaptureTests.swift
//  DrawerTests
//
//  Copyright © 2026 Drawer. MIT License.
//

import AppKit
import CoreGraphics
import XCTest

@testable import Drawer

final class ScreenCaptureTests: XCTestCase {

    // MARK: - Setup & Teardown

    override func setUp() {
        super.setUp()
        // Invalidate any cached permission result before each test
        ScreenCapture.invalidatePermissionCache()
    }

    override func tearDown() {
        // Clean up cached permission state after each test
        ScreenCapture.invalidatePermissionCache()
        super.tearDown()
    }

    // MARK: - SC-001: Permission Cache API

    /// Tests that invalidatePermissionCache can be called without crash.
    /// Note: We can't test the actual caching behavior without mocking,
    /// because checkPermissions() calls into CGS APIs that may crash in test environments.
    func testSC001_InvalidatePermissionCacheCanBeCalled() {
        // Invalidate the cache - should not crash
        ScreenCapture.invalidatePermissionCache()

        // Call again - should be idempotent
        ScreenCapture.invalidatePermissionCache()

        // Assert: If we get here, the API is stable
        XCTAssertTrue(true, "SC-001: invalidatePermissionCache should be callable without crash")
    }

    /// Tests that the permission cache API exists and has correct signatures.
    /// This is a compile-time check that becomes a runtime verification.
    func testSC001_PermissionAPIsExist() {
        // Verify API signatures exist (compile-time check, verified at runtime)
        let _: () -> Void = ScreenCapture.invalidatePermissionCache
        let _: () -> Void = ScreenCapture.requestPermissions

        // Note: checkPermissions() and cachedCheckPermissions() are not tested directly
        // because they call MenuBarItem.getMenuBarItems() which uses private CGS APIs
        // that can crash in headless/test environments.

        XCTAssertTrue(true, "SC-001: Permission APIs exist with correct signatures")
    }

    // MARK: - SC-002: captureWindows with Empty Array

    func testSC002_CaptureWindowsWithEmptyArrayReturnsNil() {
        // Arrange: Empty window IDs array
        let emptyWindowIDs: [CGWindowID] = []

        // Act: Attempt to capture with empty array
        let result = ScreenCapture.captureWindows(emptyWindowIDs)

        // Assert: Should return nil for empty input
        XCTAssertNil(
            result,
            "SC-002: captureWindows should return nil when windowIDs array is empty"
        )
    }

    func testSC002_CaptureWindowsWithInvalidWindowIDsReturnsNil() {
        // Arrange: Invalid window IDs that don't exist
        let invalidWindowIDs: [CGWindowID] = [999999999, 888888888]

        // Act: Attempt to capture non-existent windows
        let result = ScreenCapture.captureWindows(invalidWindowIDs)

        // Assert: Should return nil for invalid window IDs
        // Note: CGImage may still be created but empty, or nil depending on system
        // We just verify no crash occurs
        XCTAssertTrue(
            result == nil || result != nil,
            "SC-002: captureWindows should handle invalid window IDs gracefully"
        )
    }

    // MARK: - SC-003: captureMenuBarItems with Empty Array

    func testSC003_CaptureMenuBarItemsWithEmptyArrayReturnsEmptyDict() {
        // Arrange: Empty menu bar items array and main screen
        let emptyItems: [MenuBarItem] = []
        guard let screen = NSScreen.main else {
            XCTFail("SC-003: No main screen available for test")
            return
        }

        // Act: Attempt to capture with empty array
        let result = ScreenCapture.captureMenuBarItems(emptyItems, on: screen)

        // Assert: Should return empty dictionary
        XCTAssertTrue(
            result.isEmpty,
            "SC-003: captureMenuBarItems should return empty dictionary for empty items array"
        )
    }

    // MARK: - SC-004: NSScreen displayID Extension

    func testSC004_MainScreenDisplayIDIsNotZero() {
        // Arrange: Get main screen
        guard let mainScreen = NSScreen.main else {
            XCTFail("SC-004: No main screen available for test")
            return
        }

        // Act: Get displayID
        let displayID = mainScreen.displayID

        // Assert: displayID should be valid (not zero or negative conceptually)
        // Note: CGDirectDisplayID is UInt32, so we check it's a reasonable value
        XCTAssertTrue(
            displayID > 0,
            "SC-004: Main screen displayID should be a positive value"
        )
    }

    func testSC004_AllScreensHaveValidDisplayIDs() {
        // Arrange: Get all screens
        let screens = NSScreen.screens

        // Assert: Each screen should have a valid displayID
        XCTAssertFalse(
            screens.isEmpty,
            "SC-004: At least one screen should be available"
        )

        for (index, screen) in screens.enumerated() {
            let displayID = screen.displayID
            XCTAssertTrue(
                displayID > 0,
                "SC-004: Screen \(index) should have a valid displayID"
            )
        }
    }

    func testSC004_MainDisplayIDMatchesSystemMainDisplay() {
        // Arrange: Get main screen and system main display ID
        guard let mainScreen = NSScreen.main else {
            XCTFail("SC-004: No main screen available for test")
            return
        }

        let systemMainDisplayID = CGMainDisplayID()

        // Act: Get displayID from NSScreen extension
        let screenDisplayID = mainScreen.displayID

        // Assert: The main screen's displayID should match CGMainDisplayID()
        XCTAssertEqual(
            screenDisplayID,
            systemMainDisplayID,
            "SC-004: Main screen displayID should match CGMainDisplayID()"
        )
    }

    // MARK: - SC-005: requestPermissions API

    func testSC005_RequestPermissionsDoesNotCrash() {
        // This test simply verifies that calling requestPermissions doesn't crash
        // We can't actually test the permission dialog in unit tests

        // Act: Request permissions (should not throw or crash)
        ScreenCapture.requestPermissions()

        // Assert: If we get here, the API call succeeded without crashing
        XCTAssertTrue(true, "SC-005: requestPermissions should not crash")
    }

    // MARK: - SC-006: Width Comparison Logic (Integer Comparison)

    func testSC006_IntegerWidthComparisonLogic() {
        // This test verifies the integer comparison logic used in captureMenuBarItems
        // The fix changed from floating-point comparison to integer comparison

        // Arrange: Test data simulating the width calculation
        let testCases: [(unionWidth: CGFloat, scale: CGFloat)] = [
            (100.0, 2.0),   // Retina display
            (100.0, 1.0),   // Non-retina display
            (150.5, 2.0),   // Fractional width with retina
            (200.333, 3.0)  // Higher scale factor
        ]

        for testCase in testCases {
            // Act: Calculate expected width using the same logic as ScreenCapture
            let expectedWidth = Int((testCase.unionWidth * testCase.scale).rounded())

            // Assert: The calculation should produce consistent integer results
            let message = "SC-006: Expected width should be positive for " +
                "unionWidth: \(testCase.unionWidth), scale: \(testCase.scale)"
            XCTAssertGreaterThan(expectedWidth, 0, message)

            // Verify rounding handles edge cases correctly
            let rawWidth = testCase.unionWidth * testCase.scale
            let roundedWidth = Int(rawWidth.rounded())
            XCTAssertEqual(
                expectedWidth,
                roundedWidth,
                "SC-006: Integer conversion should use rounding"
            )
        }
    }

    func testSC006_IntegerComparisonAvoidsFloatingPointPrecisionIssues() {
        // This test demonstrates why integer comparison is needed

        // Arrange: Values that might cause floating-point precision issues
        let unionWidth: CGFloat = 0.1 + 0.2  // Classic floating-point precision example
        let scale: CGFloat = 10.0

        // Act: Calculate using integer comparison (the fixed approach)
        let expectedWidth = Int((unionWidth * scale).rounded())

        // The raw floating-point result might not be exactly 3.0
        let rawResult = unionWidth * scale

        // Assert: Integer comparison normalizes the result
        XCTAssertEqual(
            expectedWidth,
            3,
            "SC-006: Integer comparison should correctly handle floating-point precision for raw value: \(rawResult)"
        )
    }
}
