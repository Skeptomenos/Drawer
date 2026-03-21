//
//  MockOverlayPanelController.swift
//  DrawerTests
//
//  Copyright © 2026 Drawer. MIT License.
//

import Combine
import Foundation

@testable import Drawer

/// Mock implementation of OverlayPanelController for testing.
/// Simulates overlay panel behavior without requiring actual NSPanel.
@MainActor
final class MockOverlayPanelController: ObservableObject {

    // MARK: - Published State (mirrors OverlayPanelController)

    @Published private(set) var isVisible: Bool = false

    // MARK: - Test Tracking

    var showCalled = false
    var showCallCount = 0
    var lastShownItems: [DrawerItem] = []
    var lastXPosition: CGFloat = 0

    var hideCalled = false
    var hideCallCount = 0

    var toggleCalled = false
    var toggleCallCount = 0

    var cleanupCalled = false
    var cleanupCallCount = 0

    /// Captured item tap callback for testing
    var capturedOnItemTap: ((DrawerItem) -> Void)?

    // MARK: - Properties (mirrors OverlayPanelController)

    var panelFrame: CGRect = .zero

    // MARK: - Initialization

    init() {}

    // MARK: - Methods (mirrors OverlayPanelController)

    func show(
        items: [DrawerItem],
        alignedTo xPosition: CGFloat,
        onItemTap: @escaping (DrawerItem) -> Void
    ) {
        showCalled = true
        showCallCount += 1
        lastShownItems = items
        lastXPosition = xPosition
        capturedOnItemTap = onItemTap
        isVisible = true
    }

    func hide() {
        hideCalled = true
        hideCallCount += 1
        isVisible = false
    }

    func toggle(
        items: [DrawerItem],
        alignedTo xPosition: CGFloat,
        onItemTap: @escaping (DrawerItem) -> Void
    ) {
        toggleCalled = true
        toggleCallCount += 1

        if isVisible {
            hide()
        } else {
            show(items: items, alignedTo: xPosition, onItemTap: onItemTap)
        }
    }

    func cleanup() {
        cleanupCalled = true
        cleanupCallCount += 1
        isVisible = false
        lastShownItems = []
        capturedOnItemTap = nil
    }

    // MARK: - Test Helpers

    /// Resets all tracking flags and counters
    func resetTracking() {
        showCalled = false
        showCallCount = 0
        lastShownItems = []
        lastXPosition = 0
        hideCalled = false
        hideCallCount = 0
        toggleCalled = false
        toggleCallCount = 0
        cleanupCalled = false
        cleanupCallCount = 0
    }

    /// Resets state to initial values
    func resetState() {
        isVisible = false
        panelFrame = .zero
        capturedOnItemTap = nil
    }

    /// Resets both tracking and state
    func reset() {
        resetTracking()
        resetState()
    }

    /// Force set isVisible for testing edge cases
    func setVisible(_ value: Bool) {
        isVisible = value
    }

    /// Simulates tapping an item in the overlay
    func simulateItemTap(_ item: DrawerItem) {
        capturedOnItemTap?(item)
    }
}
