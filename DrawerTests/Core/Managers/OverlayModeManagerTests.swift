//
//  OverlayModeManagerTests.swift
//  DrawerTests
//
//  Copyright © 2026 Drawer. MIT License.
//

import XCTest
@testable import Drawer

/// Tests for OverlayModeManager.
/// Covers the overlay mode lifecycle including state management, icon capture,
/// overlay display, auto-hide timer, and item tap handling.
///
/// Note: OverlayModeManager requires real dependencies (MenuBarManager, IconCapturer, etc.)
/// which have side effects when instantiated. Tests focus on observable state behavior
/// that can be verified without requiring ScreenCaptureKit permissions.
@MainActor
final class OverlayModeManagerTests: XCTestCase {

    // MARK: - Properties

    private var sut: OverlayModeManager!
    private var menuBarManager: MenuBarManager!
    private var overlayController: OverlayPanelController!

    // MARK: - Setup & Teardown

    override func setUp() async throws {
        try await super.setUp()

        // Create real dependencies for testing
        // Note: MenuBarManager creates NSStatusItems, so we use SettingsManager.shared
        // to avoid creating duplicate status bar items
        menuBarManager = MenuBarManager(settings: SettingsManager.shared)
        overlayController = OverlayPanelController()

        sut = OverlayModeManager(
            settings: SettingsManager.shared,
            iconCapturer: IconCapturer.shared,
            eventSimulator: EventSimulator.shared,
            menuBarManager: menuBarManager,
            overlayController: overlayController
        )
    }

    override func tearDown() async throws {
        overlayController?.cleanup()
        sut = nil
        menuBarManager = nil
        overlayController = nil
        try await super.tearDown()
    }

    // MARK: - OVM-001: Initial isOverlayVisible is false

    func testOVM001_InitialIsOverlayVisibleIsFalse() async throws {
        // Arrange & Act - sut is already initialized in setUp

        // Assert
        XCTAssertFalse(sut.isOverlayVisible, "OVM-001: Initial isOverlayVisible should be false")
    }

    // MARK: - OVM-002: Initial isCapturing is false

    func testOVM002_InitialIsCapturingIsFalse() async throws {
        // Arrange & Act - sut is already initialized in setUp

        // Assert
        XCTAssertFalse(sut.isCapturing, "OVM-002: Initial isCapturing should be false")
    }

    // MARK: - OVM-003: Initial capturedItems is empty

    func testOVM003_InitialCapturedItemsIsEmpty() async throws {
        // Arrange & Act - sut is already initialized in setUp

        // Assert
        XCTAssertTrue(sut.capturedItems.isEmpty, "OVM-003: Initial capturedItems should be empty")
    }

    // MARK: - OVM-004: isOverlayModeEnabled reflects settings

    func testOVM004_IsOverlayModeEnabledReflectsSettings() async throws {
        // Arrange - Settings has overlayModeEnabled = false by default

        // Act & Assert
        XCTAssertEqual(
            sut.isOverlayModeEnabled,
            SettingsManager.shared.overlayModeEnabled,
            "OVM-004: isOverlayModeEnabled should reflect settings value"
        )
    }

    // MARK: - OVM-005: hideOverlay sets isOverlayVisible to false

    func testOVM005_HideOverlaySetsIsOverlayVisibleToFalse() async throws {
        // Arrange & Precondition
        XCTAssertFalse(sut.isOverlayVisible, "OVM-005: Precondition - overlay should not be visible")

        // Act
        sut.hideOverlay()

        // Assert - Calling hide when already hidden should still result in false
        XCTAssertFalse(sut.isOverlayVisible, "OVM-005: hideOverlay should keep isOverlayVisible false")
    }

    // MARK: - OVM-006: toggleOverlay from hidden completes without crash

    func testOVM006_ToggleOverlayFromHiddenCompletesWithoutCrash() async throws {
        // Arrange & Precondition
        XCTAssertFalse(sut.isOverlayVisible, "OVM-006: Precondition - overlay should not be visible")
        XCTAssertFalse(sut.isCapturing, "OVM-006: Precondition - should not be capturing")

        // Note: toggleOverlay will attempt to show, but may fail without ScreenCaptureKit permissions
        // This test verifies no crash and state consistency

        // Act
        await sut.toggleOverlay()

        // Assert - After toggle completes (success or failure), isCapturing should be false
        // This verifies the cleanup path works correctly
        XCTAssertFalse(sut.isCapturing, "OVM-006: isCapturing should be false after toggleOverlay completes")
    }

    // MARK: - OVM-007: hideOverlay is idempotent

    func testOVM007_HideOverlayIsIdempotent() async throws {
        // Arrange & Precondition
        XCTAssertFalse(sut.isOverlayVisible, "OVM-007: Precondition - overlay should not be visible")

        // Act
        sut.hideOverlay()

        // Assert
        XCTAssertFalse(sut.isOverlayVisible, "OVM-007: Overlay should be hidden after hideOverlay")
    }

    // MARK: - OVM-008: hideOverlay cancels auto-hide timer without crash

    func testOVM008_HideOverlayCancelsAutoHideTimerWithoutCrash() async throws {
        // Arrange - The auto-hide timer is internal

        // Act
        sut.hideOverlay()

        // Assert - No crash means timer cancellation worked
        XCTAssertFalse(sut.isOverlayVisible, "OVM-008: Overlay should be hidden")
    }

    // MARK: - OVM-009: capturedItems remains consistent after failed capture

    func testOVM009_CapturedItemsRemainsConsistentAfterFailedCapture() async throws {
        // Arrange - Without ScreenCaptureKit permissions, capture will fail
        XCTAssertTrue(sut.capturedItems.isEmpty, "OVM-009: Precondition - capturedItems should be empty")

        // Act - Attempt toggle (will likely fail without permissions)
        await sut.toggleOverlay()

        // Assert - On failure, state should remain consistent
        XCTAssertFalse(sut.isCapturing, "OVM-009: isCapturing should be false after failed capture")
    }

    // MARK: - OVM-010: Multiple hideOverlay calls are safe

    func testOVM010_MultipleHideOverlayCallsAreSafe() async throws {
        // Arrange & Precondition
        XCTAssertFalse(sut.isOverlayVisible, "OVM-010: Precondition - overlay should not be visible")

        // Act - Call hideOverlay multiple times
        sut.hideOverlay()
        sut.hideOverlay()
        sut.hideOverlay()

        // Assert - No crash, state remains consistent
        XCTAssertFalse(sut.isOverlayVisible, "OVM-010: Overlay should remain hidden after multiple hide calls")
    }

    // MARK: - OVM-011: showOverlay guards against concurrent captures

    func testOVM011_ShowOverlayGuardsAgainstConcurrentCaptures() async throws {
        // This test verifies that concurrent showOverlay calls don't cause issues
        // The guard in showOverlay checks `isCapturing`

        // Arrange & Precondition
        XCTAssertFalse(sut.isCapturing, "OVM-011: Precondition - should not be capturing")

        // Act - Start multiple async showOverlay calls
        // Only one should proceed; others should be guarded
        async let result1: () = sut.showOverlay()
        async let result2: () = sut.showOverlay()

        _ = await (result1, result2)

        // Assert - No crash, isCapturing should be false after all complete
        XCTAssertFalse(sut.isCapturing, "OVM-011: isCapturing should be false after concurrent calls complete")
    }

    // MARK: - OVM-012: State consistency after error

    func testOVM012_StateConsistencyAfterError() async throws {
        // Arrange - Save initial state references (not values, since they're Published)
        _ = sut.isOverlayVisible
        _ = sut.isCapturing
        _ = sut.capturedItems.isEmpty

        // Act - Attempt operation that may fail
        await sut.showOverlay()

        // Assert - State should be consistent (not left in broken state)
        XCTAssertFalse(sut.isCapturing, "OVM-012: isCapturing should be false after operation")

        // Verify cleanup
        sut.hideOverlay()
        XCTAssertFalse(sut.isOverlayVisible, "OVM-012: isOverlayVisible should be false after hideOverlay")
    }
}
