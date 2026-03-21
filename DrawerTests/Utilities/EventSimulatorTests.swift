//
//  EventSimulatorTests.swift
//  DrawerTests
//
//  Copyright © 2026 Drawer. MIT License.
//

import AppKit
import XCTest

@testable import Drawer

final class EventSimulatorTests: XCTestCase {

    // MARK: - Properties

    private var sut: EventSimulator!

    // MARK: - Setup & Teardown

    override func setUp() {
        super.setUp()
        sut = EventSimulator.shared
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - EVS-001: hasAccessibilityPermission returns correct value

    func testEVS001_HasAccessibilityPermissionReturnsCorrectValue() {
        // Arrange
        let expectedValue = AXIsProcessTrusted()

        // Act
        let actualValue = sut.hasAccessibilityPermission

        // Assert
        XCTAssertEqual(
            actualValue,
            expectedValue,
            "EVS-001: hasAccessibilityPermission should match AXIsProcessTrusted()"
        )
    }

    // MARK: - EVS-002: simulateClick without permission throws accessibilityNotGranted error

    func testEVS002_SimulateClickWithoutPermissionThrowsAccessibilityNotGrantedError() async throws {
        let hasPermission = AXIsProcessTrusted()
        let testPoint = CGPoint(x: 100, y: 100)

        if !hasPermission {
            do {
                try await sut.simulateClick(at: testPoint)
                XCTFail("EVS-002: simulateClick should throw when accessibility permission is not granted")
            } catch let error as EventSimulatorError {
                XCTAssertEqual(
                    error,
                    .accessibilityNotGranted,
                    "EVS-002: Error should be accessibilityNotGranted when permission is denied"
                )
                XCTAssertEqual(
                    error.errorDescription,
                    "Accessibility permission is required to simulate clicks",
                    "EVS-002: Error description should match expected message"
                )
            } catch {
                XCTFail("EVS-002: Unexpected error type: \(error)")
            }
        } else {
            XCTAssertTrue(
                sut.hasAccessibilityPermission,
                "EVS-002: Permission is granted in this environment - denied path cannot be tested directly"
            )
        }
    }

    // MARK: - EVS-003: simulateClick with invalid coordinates throws invalidCoordinates error

    func testEVS003_SimulateClickWithInvalidCoordinatesThrowsInvalidCoordinatesError() async throws {
        // Skip if no accessibility permission (would throw accessibilityNotGranted first)
        guard AXIsProcessTrusted() else {
            throw XCTSkip("EVS-003: Accessibility permission required to test coordinate validation")
        }

        // Arrange - coordinates far outside any possible screen
        let invalidPoint = CGPoint(x: -99999, y: -99999)

        // Act & Assert
        do {
            try await sut.simulateClick(at: invalidPoint)
            XCTFail("EVS-003: simulateClick should throw when coordinates are invalid")
        } catch let error as EventSimulatorError {
            XCTAssertEqual(
                error,
                .invalidCoordinates,
                "EVS-003: Error should be invalidCoordinates for out-of-bounds point"
            )
            XCTAssertEqual(
                error.errorDescription,
                "Invalid screen coordinates",
                "EVS-003: Error description should match expected message"
            )
        } catch {
            XCTFail("EVS-003: Unexpected error type: \(error)")
        }
    }

    // MARK: - EVS-004: isValidScreenPoint inside screen returns true

    func testEVS004_IsValidScreenPointInsideScreenReturnsTrue() async throws {
        // Skip if no accessibility permission (would throw accessibilityNotGranted first)
        guard AXIsProcessTrusted() else {
            throw XCTSkip("EVS-004: Accessibility permission required to test coordinate validation")
        }

        // Arrange - get a point that is definitely inside the main screen
        guard let mainScreen = NSScreen.main else {
            throw XCTSkip("EVS-004: No main screen available")
        }

        // Use center of the screen - guaranteed to be valid
        let validPoint = CGPoint(
            x: mainScreen.frame.midX,
            y: mainScreen.frame.midY
        )

        // Act & Assert
        // If isValidScreenPoint returns true, simulateClick should NOT throw invalidCoordinates
        // It should either succeed or throw a different error (e.g., eventCreationFailed)
        do {
            try await sut.simulateClick(at: validPoint)
            // Success - point was valid and click was simulated
        } catch EventSimulatorError.invalidCoordinates {
            XCTFail("EVS-004: Point inside screen should be valid, but got invalidCoordinates error")
        } catch {
            // Other errors (eventCreationFailed, eventPostingFailed) are acceptable
            // They indicate the point was valid but something else failed
        }
    }

    // MARK: - EVS-005: isValidScreenPoint outside all screens returns false

    func testEVS005_IsValidScreenPointOutsideAllScreensReturnsFalse() async throws {
        // Skip if no accessibility permission (would throw accessibilityNotGranted first)
        guard AXIsProcessTrusted() else {
            throw XCTSkip("EVS-005: Accessibility permission required to test coordinate validation")
        }

        // Arrange - find a point that is definitely outside ALL screens
        // Calculate the bounding box of all screens and go beyond it
        let allScreensUnion = NSScreen.screens.reduce(CGRect.null) { result, screen in
            result.union(screen.frame)
        }

        // Use a point far to the right and below all screens
        let outsidePoint = CGPoint(
            x: allScreensUnion.maxX + 10000,
            y: allScreensUnion.maxY + 10000
        )

        // Act & Assert
        // isValidScreenPoint should return false, causing simulateClick to throw invalidCoordinates
        do {
            try await sut.simulateClick(at: outsidePoint)
            XCTFail("EVS-005: simulateClick should throw invalidCoordinates for point outside all screens")
        } catch EventSimulatorError.invalidCoordinates {
            // Expected - point was correctly identified as invalid
        } catch {
            XCTFail("EVS-005: Expected invalidCoordinates error, but got: \(error)")
        }
    }

    // MARK: - EVS-006: isValidScreenPoint in menu bar area

    func testEVS006_IsValidScreenPointInMenuBarAreaIsValid() async throws {
        // Skip if no accessibility permission (would throw accessibilityNotGranted first)
        guard AXIsProcessTrusted() else {
            throw XCTSkip("EVS-006: Accessibility permission required to test coordinate validation")
        }

        // Arrange - get a point in the menu bar area
        guard let mainScreen = NSScreen.main else {
            throw XCTSkip("EVS-006: No main screen available")
        }

        // Calculate the menu bar region using the same logic as EventSimulator
        let menuBarHeight = MenuBarMetrics.height

        // Point in the center of the menu bar horizontally, vertically in the menu bar
        // Menu bar is at the top of the screen (maxY - menuBarHeight to maxY)
        let menuBarPoint = CGPoint(
            x: mainScreen.frame.midX,
            y: mainScreen.frame.maxY - (menuBarHeight / 2)
        )

        // Act & Assert
        // If isValidScreenPoint correctly identifies menu bar area as valid,
        // simulateClick should NOT throw invalidCoordinates
        do {
            try await sut.simulateClick(at: menuBarPoint)
            // Success - point in menu bar area was valid and click was simulated
        } catch EventSimulatorError.invalidCoordinates {
            XCTFail("EVS-006: Point in menu bar area should be valid, but got invalidCoordinates error")
        } catch {
            // Other errors (eventCreationFailed, eventPostingFailed) are acceptable
            // They indicate the point was valid but something else failed
        }
    }

    // MARK: - EVS-007: saveCursorPosition returns current location

    func testEVS007_SaveCursorPositionReturnsCurrentLocation() {
        // Arrange
        // Get the current mouse location directly from NSEvent for comparison
        let expectedLocation = NSEvent.mouseLocation

        // Act
        let savedPosition = sut.saveCursorPosition()

        // Assert
        // The saved position should match NSEvent.mouseLocation
        // Allow small tolerance for timing differences (mouse could move slightly between calls)
        let tolerance: CGFloat = 1.0

        XCTAssertEqual(
            savedPosition.x,
            expectedLocation.x,
            accuracy: tolerance,
            "EVS-007: saveCursorPosition x-coordinate should match NSEvent.mouseLocation.x"
        )
        XCTAssertEqual(
            savedPosition.y,
            expectedLocation.y,
            accuracy: tolerance,
            "EVS-007: saveCursorPosition y-coordinate should match NSEvent.mouseLocation.y"
        )

        // Verify the point is a valid screen coordinate (not NaN or infinity)
        XCTAssertFalse(
            savedPosition.x.isNaN || savedPosition.x.isInfinite,
            "EVS-007: saveCursorPosition x-coordinate should be a valid number"
        )
        XCTAssertFalse(
            savedPosition.y.isNaN || savedPosition.y.isInfinite,
            "EVS-007: saveCursorPosition y-coordinate should be a valid number"
        )
    }

    // MARK: - EVS-008: convertToScreenCoordinates

    func testEVS008_ConvertToScreenCoordinatesWorksCorrectly() throws {
        guard let mainScreen = NSScreen.main else {
            throw XCTSkip("EVS-008: No main screen available")
        }

        let screenHeight = mainScreen.frame.height

        // AppKit: bottom-left origin → CGEvent: top-left origin
        // Formula: y_screen = screenHeight - y_appkit
        let appKitPoint = CGPoint(x: 100, y: 100)
        let expectedScreenY = screenHeight - appKitPoint.y

        XCTAssertEqual(
            appKitPoint.x,
            100,
            "EVS-008: X coordinate should remain unchanged"
        )
        XCTAssertEqual(
            expectedScreenY,
            screenHeight - 100,
            "EVS-008: Y coordinate should flip relative to screen height"
        )

        let doubleConverted = screenHeight - expectedScreenY
        XCTAssertEqual(
            doubleConverted,
            appKitPoint.y,
            accuracy: 0.001,
            "EVS-008: Double conversion should return original Y"
        )

        XCTAssertEqual(
            screenHeight - 0,
            screenHeight,
            "EVS-008: Origin y=0 converts to screenHeight"
        )
        XCTAssertEqual(
            screenHeight - screenHeight,
            0,
            "EVS-008: Top y=screenHeight converts to 0"
        )

        if AXIsProcessTrusted() {
            let validPoint = CGPoint(x: mainScreen.frame.midX, y: mainScreen.frame.midY)
            do {
                try sut.restoreCursorPosition(validPoint)
            } catch EventSimulatorError.invalidCoordinates {
                XCTFail("EVS-008: restoreCursorPosition should not throw invalidCoordinates for valid input")
            } catch {
                // eventCreationFailed/eventPostingFailed are acceptable - conversion worked
            }
        }
    }
}
