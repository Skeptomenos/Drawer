//
//  DrawerPanelControllerTests.swift
//  DrawerTests
//
//  Copyright © 2026 Drawer. MIT License.
//

import XCTest
@testable import Drawer

@MainActor
final class DrawerPanelControllerTests: XCTestCase {

    // MARK: - Properties

    private var sut: DrawerPanelController!

    // MARK: - Setup & Teardown

    override func setUp() async throws {
        try await super.setUp()
        sut = DrawerPanelController()
    }

    override func tearDown() async throws {
        sut?.dispose()
        sut = nil
        try await super.tearDown()
    }

    // MARK: - DPC-001: Initial isVisible is false

    func testDPC001_InitialIsVisibleIsFalse() async throws {
        // Arrange & Act - sut is already initialized in setUp

        // Assert
        XCTAssertFalse(sut.isVisible, "DPC-001: Initial state isVisible should be false")
    }

    // MARK: - DPC-002: Initial panelFrame is zero

    func testDPC002_InitialPanelFrameIsZero() async throws {
        // Arrange & Act - sut is already initialized in setUp

        // Assert
        XCTAssertEqual(sut.panelFrame, .zero, "DPC-002: Initial panelFrame should be .zero (no panel created yet)")
    }

    // MARK: - DPC-003: show() sets isVisible true

    func testDPC003_ShowSetsIsVisibleTrue() async throws {
        // Arrange
        let testView = TestContentView()
        XCTAssertFalse(sut.isVisible, "DPC-003: Precondition - isVisible should be false")

        // Act
        sut.show(content: testView)

        // Assert
        XCTAssertTrue(sut.isVisible, "DPC-003: show() should set isVisible to true")
    }

    // MARK: - DPC-004: hide() sets isVisible false

    func testDPC004_HideSetsIsVisibleFalse() async throws {
        // Arrange - Show first
        let testView = TestContentView()
        sut.show(content: testView)
        XCTAssertTrue(sut.isVisible, "DPC-004: Precondition - isVisible should be true after show")

        // Act
        sut.hide()

        // Assert
        XCTAssertFalse(sut.isVisible, "DPC-004: hide() should set isVisible to false")
    }

    // MARK: - DPC-005: toggle() from hidden shows

    func testDPC005_ToggleFromHiddenShows() async throws {
        // Arrange
        let testView = TestContentView()
        XCTAssertFalse(sut.isVisible, "DPC-005: Precondition - isVisible should be false")

        // Act
        sut.toggle(content: testView)

        // Assert
        XCTAssertTrue(sut.isVisible, "DPC-005: toggle() when hidden should show the panel")
    }

    // MARK: - DPC-006: toggle() from visible hides

    func testDPC006_ToggleFromVisibleHides() async throws {
        // Arrange - Show first
        let testView = TestContentView()
        sut.show(content: testView)
        XCTAssertTrue(sut.isVisible, "DPC-006: Precondition - isVisible should be true")

        // Act
        sut.toggle(content: testView)

        // Assert
        XCTAssertFalse(sut.isVisible, "DPC-006: toggle() when visible should hide the panel")
    }

    // MARK: - DPC-007: hide() when already hidden is safe

    func testDPC007_HideWhenAlreadyHiddenIsSafe() async throws {
        // Arrange - Ensure panel is not visible
        XCTAssertFalse(sut.isVisible, "DPC-007: Precondition - isVisible should be false")

        // Act - Call hide on already hidden panel (should not crash or throw)
        sut.hide()

        // Assert
        XCTAssertFalse(sut.isVisible, "DPC-007: hide() on already hidden panel should remain hidden")
    }

    // MARK: - DPC-008: show() twice is idempotent for visibility

    func testDPC008_ShowTwiceIsIdempotent() async throws {
        // Arrange
        let testView = TestContentView()
        sut.show(content: testView)
        XCTAssertTrue(sut.isVisible, "DPC-008: Precondition - isVisible should be true after first show")

        // Act - Show again (should be handled gracefully due to animation guard)
        sut.show(content: testView)

        // Assert - Still visible (no crash, no state corruption)
        XCTAssertTrue(sut.isVisible, "DPC-008: show() twice should keep panel visible")
    }

    // MARK: - DPC-009: dispose() clears resources

    func testDPC009_DisposeClearsResources() async throws {
        // Arrange - Show first to create panel
        let testView = TestContentView()
        sut.show(content: testView)
        XCTAssertTrue(sut.isVisible, "DPC-009: Precondition - isVisible should be true")

        // Act
        sut.dispose()

        // Assert
        XCTAssertFalse(sut.isVisible, "DPC-009: dispose() should set isVisible to false")
        XCTAssertEqual(sut.panelFrame, .zero, "DPC-009: dispose() should clear panel (panelFrame should be .zero)")
    }

    // MARK: - DPC-010: onVisibilityChanged callback fires on show

    func testDPC010_OnVisibilityChangedCallbackFiresOnShow() async throws {
        // Arrange
        let testView = TestContentView()
        var callbackFired = false
        var receivedValue: Bool?

        sut.onVisibilityChanged = { isVisible in
            callbackFired = true
            receivedValue = isVisible
        }

        // Precondition
        XCTAssertFalse(sut.isVisible, "DPC-010: Precondition - isVisible should be false")

        // Act
        sut.show(content: testView)

        // Assert
        XCTAssertTrue(callbackFired, "DPC-010: onVisibilityChanged callback should fire on show")
        XCTAssertEqual(receivedValue, true, "DPC-010: Callback should receive true when panel shows")
    }

    // MARK: - DPC-011: onVisibilityChanged callback fires on hide

    func testDPC011_OnVisibilityChangedCallbackFiresOnHide() async throws {
        // Arrange - Show first
        let testView = TestContentView()
        sut.show(content: testView)

        var callbackFired = false
        var receivedValue: Bool?

        sut.onVisibilityChanged = { isVisible in
            callbackFired = true
            receivedValue = isVisible
        }

        // Precondition
        XCTAssertTrue(sut.isVisible, "DPC-011: Precondition - isVisible should be true")

        // Act
        sut.hide()

        // Assert
        XCTAssertTrue(callbackFired, "DPC-011: onVisibilityChanged callback should fire on hide")
        XCTAssertEqual(receivedValue, false, "DPC-011: Callback should receive false when panel hides")
    }

    // MARK: - DPC-012: onVisibilityChanged does not fire if visibility unchanged

    func testDPC012_OnVisibilityChangedDoesNotFireIfUnchanged() async throws {
        // Arrange - Already hidden, hide again should not fire callback
        var callbackCount = 0

        sut.onVisibilityChanged = { _ in
            callbackCount += 1
        }

        // Precondition
        XCTAssertFalse(sut.isVisible, "DPC-012: Precondition - isVisible should be false")

        // Act - Hide when already hidden
        sut.hide()

        // Assert - Callback should not fire since visibility didn't change
        XCTAssertEqual(callbackCount, 0, "DPC-012: Callback should not fire when visibility is unchanged")
    }

    // MARK: - DPC-013: show() creates panel if nil

    func testDPC013_ShowCreatesPanelIfNil() async throws {
        // Arrange
        let testView = TestContentView()
        XCTAssertEqual(sut.panelFrame, .zero, "DPC-013: Precondition - panelFrame should be zero (no panel)")

        // Act
        sut.show(content: testView)

        // Assert - Panel should be created and have non-zero frame
        XCTAssertNotEqual(sut.panelFrame, .zero, "DPC-013: show() should create panel with non-zero frame")
    }

    // MARK: - DPC-014: show() with alignedTo positions correctly

    func testDPC014_ShowWithAlignedToPositionsCorrectly() async throws {
        // Arrange
        let testView = TestContentView()
        let alignmentX: CGFloat = 500.0

        // Act
        sut.show(content: testView, alignedTo: alignmentX)

        // Assert
        XCTAssertTrue(sut.isVisible, "DPC-014: Panel should be visible")
        XCTAssertNotEqual(sut.panelFrame, .zero, "DPC-014: Panel should have been positioned")
    }

    // MARK: - DPC-015: show() without alignedTo centers panel

    func testDPC015_ShowWithoutAlignedToCentersPanel() async throws {
        // Arrange
        let testView = TestContentView()

        // Act
        sut.show(content: testView)

        // Assert
        XCTAssertTrue(sut.isVisible, "DPC-015: Panel should be visible")
        XCTAssertNotEqual(sut.panelFrame, .zero, "DPC-015: Panel should have been positioned")
    }

    // MARK: - DPC-016: updateContent updates existing panel

    func testDPC016_UpdateContentUpdatesExistingPanel() async throws {
        // Arrange - Show first
        let testView = TestContentView()
        sut.show(content: testView)
        XCTAssertTrue(sut.isVisible, "DPC-016: Precondition - panel should be visible")

        let originalFrame = sut.panelFrame

        // Act - Update content (should not change frame, just content)
        let newView = TestContentView()
        sut.updateContent(newView)

        // Assert - Panel should still be visible with same frame
        XCTAssertTrue(sut.isVisible, "DPC-016: Panel should remain visible after content update")
        XCTAssertEqual(sut.panelFrame, originalFrame, "DPC-016: Frame should not change on content update")
    }

    // MARK: - DPC-017: updateWidth changes panel width

    func testDPC017_UpdateWidthChangesPanelWidth() async throws {
        // Arrange - Show first
        let testView = TestContentView()
        sut.show(content: testView)
        XCTAssertTrue(sut.isVisible, "DPC-017: Precondition - panel should be visible")

        // Act
        let newWidth: CGFloat = 350.0
        sut.updateWidth(newWidth)

        // Assert
        XCTAssertEqual(sut.panelFrame.width, newWidth, "DPC-017: Panel width should be updated")
    }

    // MARK: - DPC-018: panelFrame reflects actual panel position

    func testDPC018_PanelFrameReflectsActualPanelPosition() async throws {
        // Arrange
        let testView = TestContentView()

        // Act
        sut.show(content: testView)

        // Assert
        let frame = sut.panelFrame
        XCTAssertGreaterThan(frame.width, 0, "DPC-018: Panel width should be positive")
        XCTAssertGreaterThan(frame.height, 0, "DPC-018: Panel height should be positive")
    }

    // MARK: - DPC-019: Multiple toggle cycles work correctly with animation delays

    func testDPC019_MultipleToggleCyclesWorkCorrectly() async throws {
        // Arrange
        let testView = TestContentView()
        let animationDelay: UInt64 = 300_000_000 // 300ms - accounts for animation duration

        // Act & Assert - Toggle with delays to allow animations to complete
        XCTAssertFalse(sut.isVisible, "DPC-019: Initially hidden")

        sut.toggle(content: testView)
        XCTAssertTrue(sut.isVisible, "DPC-019: After first toggle - visible")

        try await Task.sleep(nanoseconds: animationDelay)

        sut.toggle(content: testView)
        XCTAssertFalse(sut.isVisible, "DPC-019: After second toggle - hidden")

        try await Task.sleep(nanoseconds: animationDelay)

        sut.toggle(content: testView)
        XCTAssertTrue(sut.isVisible, "DPC-019: After third toggle - visible")

        try await Task.sleep(nanoseconds: animationDelay)

        sut.toggle(content: testView)
        XCTAssertFalse(sut.isVisible, "DPC-019: After fourth toggle - hidden")
    }

    // MARK: - DPC-020: dispose() can be called multiple times safely

    func testDPC020_DisposeCanBeCalledMultipleTimesSafely() async throws {
        // Arrange - Show first
        let testView = TestContentView()
        sut.show(content: testView)

        // Act - Call dispose multiple times (should not crash)
        sut.dispose()
        sut.dispose()
        sut.dispose()

        // Assert
        XCTAssertFalse(sut.isVisible, "DPC-020: After multiple dispose() calls, panel should be hidden")
        XCTAssertEqual(sut.panelFrame, .zero, "DPC-020: Panel frame should be zero after dispose")
    }
}

// MARK: - Test Helpers

import SwiftUI

/// Simple test view for DrawerPanelController tests.
private struct TestContentView: View {
    var body: some View {
        Text("Test Content")
            .frame(width: 200, height: 36)
    }
}
